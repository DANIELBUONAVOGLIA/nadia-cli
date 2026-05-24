#!/bin/bash
# Renova o token OAuth usando o refresh token
source /home/agente/.env_oauth

RESPONSE=$(curl -s -X POST "https://platform.claude.com/v1/oauth/token" \
  -H "Content-Type: application/json" \
  -d "{
    \"grant_type\": \"refresh_token\",
    \"refresh_token\": \"$CLAUDE_CODE_OAUTH_REFRESH_TOKEN\",
    \"client_id\": \"9d1c250a-e61b-44d9-88ed-5944d1962f5e\"
  }")

NEW_TOKEN=$(echo "$RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('access_token',''))" 2>/dev/null)
NEW_REFRESH=$(echo "$RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('refresh_token',''))" 2>/dev/null)

if [ -n "$NEW_TOKEN" ] && [ "$NEW_TOKEN" != "None" ]; then
    echo "$(date): Token renovado com sucesso" >> /var/log/claude_token_refresh.log
    cat > /home/agente/.env_oauth << ENVEOF
CLAUDE_CODE_OAUTH_TOKEN=$NEW_TOKEN
CLAUDE_CODE_OAUTH_REFRESH_TOKEN=${NEW_REFRESH:-$CLAUDE_CODE_OAUTH_REFRESH_TOKEN}
ENVEOF
    chmod 600 /home/agente/.env_oauth
    chown agente:agente /home/agente/.env_oauth
else
    echo "$(date): ERRO ao renovar token: $RESPONSE" >> /var/log/claude_token_refresh.log
fi
