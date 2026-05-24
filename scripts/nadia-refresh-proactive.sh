#!/bin/bash
# nadia-refresh-proactive.sh
# Camada 1: refresh proativo do token NADIA — roda 2x por hora.
# Se token expira em menos de 2h, força refresh ANTES de morrer.
#
# */30 * * * * /opt/AGENTE/scripts/nadia-refresh-proactive.sh >> /var/log/nadia-refresh-proactive.log 2>&1

set -u

LOG_PREFIX="[$(date -u +'%Y-%m-%dT%H:%M:%SZ')]"
ENV_OAUTH="/home/agente/.env_oauth"

if [ ! -f "$ENV_OAUTH" ]; then
  echo "$LOG_PREFIX ERROR: $ENV_OAUTH não existe"
  exit 1
fi

EXPIRES_MS=$(grep CLAUDE_CODE_OAUTH_EXPIRES_AT "$ENV_OAUTH" | cut -d= -f2 | tr -d '"')
NOW_MS=$(($(date +%s) * 1000))

if [ -z "$EXPIRES_MS" ]; then
  echo "$LOG_PREFIX WARN: EXPIRES_AT não encontrado"
  exit 0
fi

DIFF_MS=$((EXPIRES_MS - NOW_MS))
HOURS_LEFT=$((DIFF_MS / 3600000))
MINUTES_LEFT=$((DIFF_MS / 60000))

echo "$LOG_PREFIX Token vence em ${MINUTES_LEFT}min (${HOURS_LEFT}h)"

# Se faltam < 2 horas → refresh AGORA (proativo)
if [ "$DIFF_MS" -lt 7200000 ]; then
  echo "$LOG_PREFIX < 2h restantes → fazendo refresh proativo"

  if [ -x /opt/AGENTE/refresh_token.sh ]; then
    /opt/AGENTE/refresh_token.sh >> /var/log/claude_token_refresh.log 2>&1
    if [ $? -eq 0 ]; then
      echo "$LOG_PREFIX refresh OK"
    else
      echo "$LOG_PREFIX refresh FALHOU (rate limit?) — auto-sync Mac vai tentar"
    fi
  else
    echo "$LOG_PREFIX WARN: /opt/AGENTE/refresh_token.sh não existe ou não é executável"
  fi
elif [ "$DIFF_MS" -lt 0 ]; then
  echo "$LOG_PREFIX EXPIRED — auto-sync Mac é o único caminho"
fi
