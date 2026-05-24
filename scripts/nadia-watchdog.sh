#!/bin/bash
# nadia-watchdog.sh
# Camada 2: detecta NADIA com erro de auth/token e alerta + tenta recuperar.
# Roda via cron a cada 2 minutos.
#
# */2 * * * * /opt/AGENTE/scripts/nadia-watchdog.sh >> /var/log/nadia-watchdog.log 2>&1

set -u

LOG=/var/log/nadia-watchdog.log
STATE=/tmp/.nadia-watchdog-state
THROTTLE_MIN=15  # max 1 alerta a cada 15min

TG_TOKEN=$(grep TELEGRAM_BOT_TOKEN /opt/AGENTE-bot/.env 2>/dev/null | cut -d= -f2 | tr -d '"' | tr -d "'")
TG_CHAT="YOUR_TELEGRAM_CHAT_ID"  # User

log() {
  echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $1"
}

throttled() {
  local key="$1"
  local marker="$STATE.$key"
  if [ -f "$marker" ]; then
    local last=$(stat -c %Y "$marker" 2>/dev/null || echo 0)
    local now=$(date +%s)
    if [ $((now - last)) -lt $((THROTTLE_MIN * 60)) ]; then
      return 0  # throttled
    fi
  fi
  touch "$marker"
  return 1
}

send_alert() {
  local key="$1"
  local msg="$2"
  if throttled "$key"; then
    return
  fi
  if [ -z "$TG_TOKEN" ]; then
    log "ERROR no TELEGRAM_BOT_TOKEN"
    return
  fi
  curl -sS -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -d "chat_id=${TG_CHAT}" \
    -d "parse_mode=Markdown" \
    --data-urlencode "text=$(echo -e "$msg")" \
    -o /dev/null
  log "ALERT sent: $key"
}

# === 1. Pausa check ===
if [ -f /tmp/nadia_watchdog_pause ]; then
  log "PAUSED"
  exit 0
fi

# === 2. NADIA tmux + processo ===
if ! tmux has-session -t nadia_cli 2>/dev/null; then
  send_alert "tmux_down" "🚨 *NADIA tmux session NÃO existe*\n\nReinicializando automaticamente..."
  tmux new -d -s nadia_cli "su - agente -s /bin/bash -c '/opt/AGENTE/start_claude.sh'" 2>/dev/null
  log "RECOVERY: tmux recriado"
  exit 0
fi

if ! pgrep -f "claude --model claude-opus-4-7" >/dev/null; then
  send_alert "process_down" "🚨 *NADIA processo claude offline*\n\nTmux existe mas processo morto. Tentando restart..."
  tmux send-keys -t nadia_cli:0 "/opt/AGENTE/start_claude.sh" Enter 2>/dev/null
  log "RECOVERY: tentou restart"
  exit 0
fi

# === 3. Captura tela NADIA e procura erros de auth ===
SCREEN=$(tmux capture-pane -t nadia_cli:0 -p 2>/dev/null | tail -50)

if echo "$SCREEN" | grep -qE "401|Please run /login|authentication_error|Invalid authentication"; then
  log "DETECTED 401/auth error on screen"

  # Verifica idade do token
  EXPIRES=$(grep CLAUDE_CODE_OAUTH_EXPIRES_AT /home/agente/.env_oauth 2>/dev/null | cut -d= -f2)
  if [ -n "$EXPIRES" ]; then
    NOW_MS=$(($(date +%s) * 1000))
    if [ "$EXPIRES" -lt "$NOW_MS" ]; then
      HOURS_AGO=$(( (NOW_MS - EXPIRES) / 3600000 ))
      send_alert "token_expired" "🚨 *NADIA com token EXPIRADO*\n\nExpirou há ${HOURS_AGO}h.\n\n*Faça:*\n1. Abre Claude Desktop no Mac\n2. Confirma login\n3. Aguarda 5min (auto-sync) ou roda no Mac:\n\`bash ~/.local/bin/nadia_token_sync.sh\`"
      exit 0
    fi
  fi

  # Token válido mas tomando 401 — algo estranho, alerta
  send_alert "auth_error" "⚠️ *NADIA recebendo 401 mas token aparenta válido*\n\nPode ser refresh server-side rate-limited. Aguarda 30min ou abre Claude Desktop pra forçar novo token."
  exit 0
fi

# === 4. Stuck REAL: msg em inbox mais recente que último sent + 5min ===
# Compara mtime do inbox mais recente vs sent mais recente.
# Se inbox_latest > sent_latest + 5min → NADIA não respondeu há tempo.
INBOX_LATEST=$(find /opt/AGENTE-bot/inbox -name "*.json" -printf '%T@\n' 2>/dev/null | sort -n | tail -1 | cut -d. -f1)
SENT_LATEST=$(find /opt/AGENTE-bot/sent -type f -printf '%T@\n' 2>/dev/null | sort -n | tail -1 | cut -d. -f1)

if [ -n "$INBOX_LATEST" ] && [ -n "$SENT_LATEST" ]; then
  GAP=$((INBOX_LATEST - SENT_LATEST))
  if [ "$GAP" -gt 300 ]; then  # > 5min sem responder
    LAST_LINE=$(echo "$SCREEN" | grep -v "^$" | tail -1)
    if echo "$LAST_LINE" | grep -qE "bypass permissions|❯ $|Try "; then
      GAP_MIN=$((GAP / 60))
      send_alert "inbox_stuck" "⚠️ *NADIA sem responder há ${GAP_MIN}min*\n\nÚltima msg em inbox: $(date -d "@$INBOX_LATEST" '+%H:%M')\nÚltima resposta enviada: $(date -d "@$SENT_LATEST" '+%H:%M')\n\nNADIA idle. Verifica /opt/AGENTE-bot/inbox/ e tela."
    fi
  fi
fi

log "OK - all checks passed"
exit 0
