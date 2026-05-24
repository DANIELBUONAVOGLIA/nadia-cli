#!/bin/bash
# /opt/AGENTE/healthcheck.sh v2 — agora cobre NADIA + SECRETARY
set -u
LOG=/var/log/nadia_healthcheck.log
OUTBOX=/opt/AGENTE-bot/outbox

[ -f /opt/AGENTE-bot/.env ] && { set -a; source /opt/AGENTE-bot/.env; set +a; }
TG_CHAT_ID="${ADMIN_CHAT_ID:-${TG_CHAT_ID:-YOUR_TELEGRAM_CHAT_ID}}"
BOT_TOKEN="${BOT_TOKEN:-${TELEGRAM_BOT_TOKEN:-}}"

mkdir -p "$OUTBOX"
exec >> "$LOG" 2>&1
echo "=== $(date '+%Y-%m-%d %H:%M:%S UTC') ==="
issues=()

# --- NADIA ---
if [ -f /home/agente/.env_oauth ]; then
  source /home/agente/.env_oauth 2>/dev/null || true
  if [ -n "${CLAUDE_CODE_OAUTH_EXPIRES_AT:-}" ]; then
    hours_left=$(( (CLAUDE_CODE_OAUTH_EXPIRES_AT - $(date +%s%3N)) / 1000 / 3600 ))
    if [ "$hours_left" -lt 0 ]; then
      issues+=("NADIA: Token OAuth EXPIROU há $((-hours_left))h. Abra Claude Desktop no Mac.")
    elif [ "$hours_left" -lt 24 ]; then
      issues+=("NADIA: Token OAuth expira em ${hours_left}h. Abra Claude Desktop no Mac.")
    fi
  fi
else
  issues+=("NADIA: /home/agente/.env_oauth não existe")
fi

tmux has-session -t nadia_cli 2>/dev/null || issues+=("NADIA: tmux nadia_cli morto")
systemctl is-active --quiet nadia_cli-bot.service || issues+=("NADIA: Service nadia_cli-bot parado")

if [ -f /opt/AGENTE/.env_cloudflare ]; then
  source /opt/AGENTE/.env_cloudflare 2>/dev/null || true
  http=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 10 \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    https://api.cloudflare.com/client/v4/user/tokens/verify 2>/dev/null || echo "000")
  [ "$http" != "200" ] && issues+=("NADIA: Token Cloudflare inválido (HTTP $http)")
fi

if [ -f /home/agente/.env_oauth ]; then
  hours_old=$(( ($(date +%s) - $(stat -c %Y /home/agente/.env_oauth)) / 3600 ))
  [ "$hours_old" -gt 12 ] && issues+=("NADIA: Token sem update há ${hours_old}h (Mac sync travado?)")
fi

# --- SECRETARY ---
tmux has-session -t secretary_cli 2>/dev/null || issues+=("SECRETARY: tmux secretary_cli morto")
systemctl is-active --quiet secretary-telegram-bot.service || issues+=("SECRETARY: Service secretary-telegram-bot parado")

SECRETARY_TOKENS=/home/agente/.config/google-calendar-mcp/tokens.json
if [ -f "$SECRETARY_TOKENS" ]; then
  expiry_ms=$(python3 -c "import json; print(json.load(open('$SECRETARY_TOKENS'))['normal'].get('expiry_date',0))" 2>/dev/null || echo 0)
  if [ "$expiry_ms" -gt 0 ]; then
    mins_left=$(( (expiry_ms - $(date +%s%3N)) / 60000 ))
    if [ "$mins_left" -lt -60 ]; then
      issues+=("SECRETARY: Token Google expirou há $((-mins_left))min — refresh quebrou")
    fi
  fi
else
  issues+=("SECRETARY: tokens.json do Google não existe")
fi

# --- COMUM ---
disk_pct=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
[ "$disk_pct" -gt 85 ] && issues+=("Disco em ${disk_pct}%")
mem_pct=$(free | awk '/^Mem:/ {printf "%d", $3*100/$2}')
[ "$mem_pct" -gt 90 ] && issues+=("Memória em ${mem_pct}%")

# --- Reporte ---
if [ ${#issues[@]} -eq 0 ]; then echo "✅ OK"; exit 0; fi
echo "⚠️  ${#issues[@]} alerta(s):"
printf '  - %s\n' "${issues[@]}"
msg="🚨 Healthcheck — ${#issues[@]} alerta(s):"
for i in "${issues[@]}"; do msg+=$'\n''• '"$i"; done

if [ -n "$BOT_TOKEN" ]; then
  curl -sS --max-time 10 "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TG_CHAT_ID}" --data-urlencode "text=${msg}" > /dev/null \
    && echo "  → Telegram direto ok" || echo "  ❌ Telegram falhou"
fi

TS=$(date +%s%N)
python3 -c "
import json
msg = '''$msg'''
with open('$OUTBOX/${TS}.json', 'w') as f:
    json.dump({'chat_id': int('$TG_CHAT_ID'), 'text': msg}, f, ensure_ascii=False)
" 2>/dev/null && chown agente:agente "$OUTBOX/${TS}.json" 2>/dev/null && echo "  → outbox ok" || true
