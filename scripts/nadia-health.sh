#!/bin/bash
# nadia-health.sh
# Camada 4: comando único de status. Roda quando quiser saber estado da NADIA.
#
# Uso: bash /opt/AGENTE/scripts/nadia-health.sh

set -u

echo "════════════════════════════════════════════════════"
echo "  NADIA HEALTH CHECK — $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "════════════════════════════════════════════════════"
echo ""

# Token
ENV_OAUTH="/home/agente/.env_oauth"
if [ -f "$ENV_OAUTH" ]; then
  EXPIRES_MS=$(grep CLAUDE_CODE_OAUTH_EXPIRES_AT "$ENV_OAUTH" | cut -d= -f2 | tr -d '"')
  if [ -n "$EXPIRES_MS" ]; then
    NOW_MS=$(($(date +%s) * 1000))
    DIFF_MS=$((EXPIRES_MS - NOW_MS))
    HOURS_LEFT=$((DIFF_MS / 3600000))
    MIN_LEFT=$(( (DIFF_MS / 60000) % 60 ))
    if [ "$DIFF_MS" -lt 0 ]; then
      echo "🔴 TOKEN: EXPIRADO há $(( -DIFF_MS / 60000 ))min"
    elif [ "$DIFF_MS" -lt 7200000 ]; then
      echo "🟡 TOKEN: vence em ${HOURS_LEFT}h${MIN_LEFT}min (refresh proativo deve agir)"
    else
      echo "✅ TOKEN: vence em ${HOURS_LEFT}h${MIN_LEFT}min"
    fi
    EXPIRES_HUMAN=$(date -d "@$((EXPIRES_MS / 1000))" -u '+%Y-%m-%d %H:%M:%S UTC')
    echo "   Expiração exata: $EXPIRES_HUMAN"
  fi
fi
echo ""

# Tmux + processo
echo "▸ TMUX SESSIONS:"
if tmux has-session -t nadia_cli 2>/dev/null; then
  CREATED=$(tmux list-sessions 2>/dev/null | grep nadia_cli | grep -oE "created.*" | cut -d'(' -f1)
  echo "   ✅ nadia_cli: $CREATED"
else
  echo "   🔴 nadia_cli: NÃO EXISTE"
fi

if tmux has-session -t secretary_cli 2>/dev/null; then
  echo "   ✅ secretary_cli: rodando"
else
  echo "   🔴 secretary_cli: NÃO EXISTE"
fi
echo ""

echo "▸ PROCESSOS CLAUDE:"
PIDS=$(pgrep -af "claude --dangerously-skip-permissions" | grep -v "watchdog\|sync")
if [ -z "$PIDS" ]; then
  echo "   🔴 NENHUM"
else
  echo "$PIDS" | sed 's/^/   ✅ /'
fi
echo ""

# Bot Telegram
echo "▸ BOTS TELEGRAM:"
for bot in nadia_cli-bot secretary-telegram-bot; do
  STATUS=$(systemctl is-active "$bot.service" 2>/dev/null || echo "missing")
  if [ "$STATUS" = "active" ]; then
    echo "   ✅ $bot: $STATUS"
  else
    echo "   🔴 $bot: $STATUS"
  fi
done
echo ""

# Mensagens travadas
echo "▸ MENSAGENS PENDENTES:"
INBOX_LATEST=$(find /opt/AGENTE-bot/inbox -name "*.json" -printf '%T@\n' 2>/dev/null | sort -n | tail -1 | cut -d. -f1)
SENT_LATEST=$(find /opt/AGENTE-bot/sent -type f -printf '%T@\n' 2>/dev/null | sort -n | tail -1 | cut -d. -f1)
INBOX_TOTAL=$(find /opt/AGENTE-bot/inbox -name "*.json" 2>/dev/null | wc -l)
GAP=0
if [ -n "$INBOX_LATEST" ] && [ -n "$SENT_LATEST" ]; then
  GAP=$((INBOX_LATEST - SENT_LATEST))
fi
OUTBOX_FAIL=$(find /opt/AGENTE-bot/outbox -name "*.failed" 2>/dev/null | wc -l)
if [ "$GAP" -gt 300 ]; then
  GAP_MIN=$((GAP / 60))
  echo "   🟡 NADIA sem responder há ${GAP_MIN}min (última msg > última resposta)"
  echo "      Inbox latest: $(date -d "@$INBOX_LATEST" '+%H:%M:%S')"
  echo "      Sent latest:  $(date -d "@$SENT_LATEST" '+%H:%M:%S')"
elif [ -n "$INBOX_LATEST" ] && [ -n "$SENT_LATEST" ]; then
  GAP_MIN=$((GAP / 60))
  echo "   ✅ NADIA respondeu última msg (gap: ${GAP_MIN}min)"
fi
echo "   ℹ️  Inbox total acumulado: $INBOX_TOTAL arquivos"
if [ "$OUTBOX_FAIL" -gt 0 ]; then
  echo "   🟡 Outbox: $OUTBOX_FAIL mensagens falhas"
else
  echo "   ✅ Outbox sem falhas"
fi
echo ""

# Última atividade na tela
echo "▸ ÚLTIMA TELA NADIA (3 linhas):"
tmux capture-pane -t nadia_cli:0 -p 2>/dev/null | grep -v "^$" | tail -3 | sed 's/^/   /'
echo ""

# Logs recentes
echo "▸ ÚLTIMOS REFRESHES DE TOKEN:"
tail -3 /var/log/claude_token_refresh.log 2>/dev/null | sed 's/^/   /' || echo "   (sem log)"
echo ""

echo "▸ ÚLTIMOS SYNCS Mac→VPS:"
tail -3 /var/log/nadia_token_receive.log 2>/dev/null | sed 's/^/   /' || echo "   (sem log)"
echo ""

echo "▸ ÚLTIMOS WATCHDOG CHECKS:"
tail -5 /var/log/nadia-watchdog.log 2>/dev/null | sed 's/^/   /' || echo "   (sem log)"
echo ""

echo "════════════════════════════════════════════════════"
echo ""
echo "Comandos úteis:"
echo "  - Pausar watchdog: touch /tmp/nadia_watchdog_pause"
echo "  - Retomar: rm /tmp/nadia_watchdog_pause"
echo "  - Restart NADIA: tmux kill-session -t nadia_cli && tmux new -d -s nadia_cli 'su - agente -s /bin/bash -c /opt/AGENTE/start_claude.sh'"
echo "  - Forçar refresh: /opt/AGENTE/refresh_token.sh"
