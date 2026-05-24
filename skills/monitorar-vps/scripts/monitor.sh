#!/bin/bash
# monitorar-vps — vigia infra NADIA/Secretary e alerta User via Telegram.
# Roda via cron a cada 5min.

set -u

ENV_FILE=/opt/AGENTE/.env
SECRETARY_ENV=/opt/SECRETARY-bot/.env
STATE_FILE=/tmp/nadia_monitor_state.json
ALERT_LOG=/var/log/nadia_monitor_alerts.log
PAUSE_FILE=/tmp/monitor_pause
THROTTLE_MIN=30

# Carrega config (em ordem: AGENTE .env, SECRETARY bot .env)
load_env_var() {
  local key="$1"
  for f in "$ENV_FILE" "$SECRETARY_ENV"; do
    if [ -f "$f" ]; then
      val=$(grep -E "^${key}=" "$f" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'")
      if [ -n "$val" ]; then
        echo "$val"
        return
      fi
    fi
  done
}

# Pause check
if [ -f "$PAUSE_FILE" ]; then
  echo "[$(date)] PAUSED via $PAUSE_FILE"
  exit 0
fi

# === COLETA STATUS ===

ts=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
ALERTS=()
RECOVERIES=()

# 1) NADIA tmux + processo
if ! tmux has-session -t nadia_cli 2>/dev/null; then
  ALERTS+=("❌ NADIA: tmux session 'nadia_cli' não existe")
  # Recovery automático
  if tmux new -d -s nadia_cli "su - agente -s /bin/bash -c '/opt/AGENTE/start_claude.sh'" 2>/dev/null; then
    RECOVERIES+=("✅ NADIA: tmux recriado")
  fi
else
  if ! pgrep -f "claude --model claude-opus-4-7" >/dev/null; then
    ALERTS+=("❌ NADIA: tmux existe mas claude --model opus-4-7 não está rodando")
  fi
fi

# 2) Secretary tmux + processo
if ! tmux has-session -t secretary_cli 2>/dev/null; then
  ALERTS+=("❌ SECRETARY: tmux session 'secretary_cli' não existe")
  if tmux new -d -s secretary_cli "su - agente -s /bin/bash -c '/opt/SECRETARY/start_claude.sh'" 2>/dev/null; then
    RECOVERIES+=("✅ SECRETARY: tmux recriado")
  fi
fi

# 3) Bots Telegram
for service in secretary-telegram-bot.service nadia_cli-bot.service; do
  if systemctl is-active --quiet "$service" 2>/dev/null; then
    : # OK
  elif systemctl list-units --all 2>/dev/null | grep -q "$service"; then
    ALERTS+=("❌ Bot: $service não está ativo")
    if systemctl restart "$service" 2>/dev/null; then
      RECOVERIES+=("✅ $service: restartado")
    fi
  fi
done

# 4) Recursos
disk_pct=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
if [ -n "$disk_pct" ] && [ "$disk_pct" -gt 80 ]; then
  ALERTS+=("⚠️ Disco em ${disk_pct}% (threshold 80%)")
  # Recovery: limpa /tmp velho
  find /tmp -type f -atime +7 -delete 2>/dev/null && RECOVERIES+=("✅ /tmp limpo de arquivos > 7 dias")
fi

mem_free_mb=$(free -m | awk '/^Mem:/ {print $7}')
if [ -n "$mem_free_mb" ] && [ "$mem_free_mb" -lt 500 ]; then
  ALERTS+=("⚠️ Memória disponível baixa: ${mem_free_mb}MB (threshold 500MB)")
fi

# 5) Token OAuth — verifica expiração
oauth_env=/home/agente/.env_oauth
if [ -f "$oauth_env" ]; then
  expires=$(grep "CLAUDE_CODE_OAUTH_EXPIRES_AT" "$oauth_env" 2>/dev/null | cut -d= -f2 | tr -d '"')
  if [ -n "$expires" ]; then
    now_ts=$(date +%s)
    # expires pode estar em ms ou segundos — normalizar
    if [ ${#expires} -gt 11 ]; then
      expires=$((expires / 1000))
    fi
    diff=$((expires - now_ts))
    if [ "$diff" -lt 86400 ] && [ "$diff" -gt 0 ]; then
      hours=$((diff / 3600))
      ALERTS+=("⚠️ OAuth Token expira em ${hours}h")
    elif [ "$diff" -le 0 ]; then
      ALERTS+=("❌ OAuth Token EXPIROU há $((-diff / 3600))h — refresh urgente")
    fi
  fi
fi

# 6) Conectividade
if ! curl -sS --max-time 5 -o /dev/null -w "%{http_code}" "https://api.anthropic.com" 2>/dev/null | grep -qE "^(200|301|302|401|403)$"; then
  ALERTS+=("❌ api.anthropic.com inalcançável")
fi

# 7) Outbox queue stuck check
for outbox in /opt/AGENTE-bot/outbox /opt/SECRETARY-bot/outbox; do
  if [ -d "$outbox" ]; then
    stuck=$(find "$outbox" -name "*.json" -mmin +5 2>/dev/null | wc -l)
    if [ "$stuck" -gt 0 ]; then
      ALERTS+=("⚠️ $outbox: $stuck mensagens travadas > 5min")
    fi
  fi
done

# === ESTADO ATUAL ===
{
  echo "{"
  echo "  \"checked_at\": \"$ts\","
  echo "  \"alerts_count\": ${#ALERTS[@]},"
  echo "  \"recoveries_count\": ${#RECOVERIES[@]},"
  echo "  \"alerts\": ["
  for i in "${!ALERTS[@]}"; do
    sep=$([ $i -lt $((${#ALERTS[@]} - 1)) ] && echo "," || echo "")
    printf "    \"%s\"%s\n" "${ALERTS[$i]}" "$sep"
  done
  echo "  ],"
  echo "  \"recoveries\": ["
  for i in "${!RECOVERIES[@]}"; do
    sep=$([ $i -lt $((${#RECOVERIES[@]} - 1)) ] && echo "," || echo "")
    printf "    \"%s\"%s\n" "${RECOVERIES[$i]}" "$sep"
  done
  echo "  ],"
  echo "  \"disk_pct\": ${disk_pct:-null},"
  echo "  \"mem_free_mb\": ${mem_free_mb:-null}"
  echo "}"
} > "$STATE_FILE"

# === ALERTAS ===

if [ ${#ALERTS[@]} -eq 0 ]; then
  echo "[$ts] ✅ tudo OK"
  exit 0
fi

# Throttle: hash de alerts → cache
alerts_hash=$(printf '%s\n' "${ALERTS[@]}" | sort | md5sum | cut -c1-12)
throttle_cache=/tmp/monitor_throttle_${alerts_hash}
if [ -f "$throttle_cache" ]; then
  last_alert=$(stat -c %Y "$throttle_cache")
  now=$(date +%s)
  if [ $((now - last_alert)) -lt $((THROTTLE_MIN * 60)) ]; then
    echo "[$ts] alerta throttled (hash $alerts_hash)"
    exit 0
  fi
fi
touch "$throttle_cache"

# Monta mensagem Telegram
msg="🚨 *Secretary aqui — alerta saúde sistema*\n\nDetectado às ${ts}:\n"
for a in "${ALERTS[@]}"; do
  msg+="$a\n"
done

if [ ${#RECOVERIES[@]} -gt 0 ]; then
  msg+="\n*Recovery automático:*\n"
  for r in "${RECOVERIES[@]}"; do
    msg+="$r\n"
  done
fi

# Envia via Telegram
TG_TOKEN=$(load_env_var "TELEGRAM_BOT_TOKEN")
TG_CHAT=$(load_env_var "MONITOR_TELEGRAM_CHAT_ID")
[ -z "$TG_CHAT" ] && TG_CHAT="YOUR_TELEGRAM_CHAT_ID"  # default User

if [ -n "$TG_TOKEN" ]; then
  curl -sS -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -d "chat_id=${TG_CHAT}" \
    -d "parse_mode=Markdown" \
    --data-urlencode "text=$(echo -e "$msg")" \
    -o /dev/null
  echo "[$ts] alerta enviado: ${#ALERTS[@]} issues, ${#RECOVERIES[@]} recoveries"
  echo "[$ts] $(echo -e "$msg" | tr '\n' '|')" >> "$ALERT_LOG"
else
  echo "[$ts] alerta NÃO enviado: TELEGRAM_BOT_TOKEN ausente"
fi

exit 0
