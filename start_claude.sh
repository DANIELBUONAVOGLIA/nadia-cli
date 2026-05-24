#!/bin/bash
source /home/agente/.env_oauth
export CLAUDE_CODE_OAUTH_TOKEN
export CLAUDE_CODE_OAUTH_REFRESH_TOKEN
# Desabilitar API key para forçar uso do OAuth
unset ANTHROPIC_API_KEY
cd /opt/AGENTE
exec /usr/local/bin/claude --model claude-opus-4-7 --dangerously-skip-permissions
