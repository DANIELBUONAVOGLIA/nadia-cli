#!/bin/bash
# NADIA Orchestrator — PreToolUse Hook (v3.1 — subagent-aware)
#
# v3.1 changes:
#   - Usa o campo correto: agent_type (não agent_name) — descoberto via debug log
#   - Quando agent_type != "" → chamada de subagente → libera tudo
#   - Quando agent_type == "" → é a NADIA orquestradora → aplica regra estrita
#   - Loga input JSON completo em /var/log/nadia_hook_debug.log pra análise

set -u

input=$(cat)

# ───────────────────────────────────────────────────────────────────
# Debug: salva input completo (rotaciona em 1MB)
# ───────────────────────────────────────────────────────────────────
DEBUG_LOG=/var/log/nadia_hook_debug.log
{
  echo "=== $(date -u +'%Y-%m-%dT%H:%M:%SZ') ==="
  echo "$input" | jq -C . 2>/dev/null || echo "$input"
  echo ""
} >> "$DEBUG_LOG" 2>/dev/null || true

# Rotação simples
debug_size=$(stat -c %s "$DEBUG_LOG" 2>/dev/null || echo 0)
if [ "$debug_size" -gt 1048576 ]; then
  mv "$DEBUG_LOG" "${DEBUG_LOG}.old" 2>/dev/null || true
fi

# ───────────────────────────────────────────────────────────────────
# Extrai campos relevantes
# ───────────────────────────────────────────────────────────────────
tool_name=$(echo "$input"        | jq -r '.tool_name        // empty')
tool_command=$(echo "$input"     | jq -r '.tool_input.command // empty')
agent_type=$(echo "$input"       | jq -r '.agent_type       // empty')
agent_id=$(echo "$input"         | jq -r '.agent_id         // empty')
subagent_type=$(echo "$input"    | jq -r '.tool_input.subagent_type // empty')
session_id=$(echo "$input"       | jq -r '.session_id       // empty')
transcript_path=$(echo "$input"  | jq -r '.transcript_path  // empty')
parent_tool_use_id=$(echo "$input" | jq -r '.parent_tool_use_id // empty')
hook_event_name=$(echo "$input"  | jq -r '.hook_event_name  // empty')

LOG=/var/log/nadia_delegation.log
ts=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

log() {
  echo "[$ts] $1 :: tool=$tool_name agent_type=$agent_type agent_id=$agent_id cmd=$(echo "$tool_command" | tr '\n' ' ' | cut -c1-120)" >> "$LOG" 2>/dev/null || true
}

# ───────────────────────────────────────────────────────────────────
# 0) DETECÇÃO DE SUBAGENTE — libera tudo se for subagente
# ───────────────────────────────────────────────────────────────────
# Sinal A (PRINCIPAL): agent_type presente e não vazio = chamada de subagente
if [ -n "$agent_type" ] && [ "$agent_type" != "null" ]; then
  log "ALLOW subagent (agent_type=$agent_type)"
  exit 0
fi

# Sinal B: parent_tool_use_id presente
if [ -n "$parent_tool_use_id" ] && [ "$parent_tool_use_id" != "null" ]; then
  log "ALLOW subagent (parent_tool_use_id=$parent_tool_use_id)"
  exit 0
fi

# Sinal C: transcript_path tem "agents/" ou "subagent" no caminho
if echo "$transcript_path" | grep -qE '(agents/|subagent|/agent-)'; then
  log "ALLOW subagent (transcript_path=$transcript_path)"
  exit 0
fi

# ───────────────────────────────────────────────────────────────────
# 1) Main NADIA: tools de orquestração sempre liberadas
# ───────────────────────────────────────────────────────────────────
case "$tool_name" in
  Agent|Task|TodoWrite)
    log "ALLOW orchestration (subagent_type=$subagent_type)"
    exit 0
    ;;
esac

# ───────────────────────────────────────────────────────────────────
# 2) Bash do outbox do Telegram — única exceção, com anti-smuggling
# ───────────────────────────────────────────────────────────────────
if [ "$tool_name" = "Bash" ]; then
  if echo "$tool_command" | grep -qE '>[[:space:]]*/opt/AGENTE-bot/outbox/'; then

    # 2a) Comando deve COMEÇAR com echo, jq, ou printf
    if ! echo "$tool_command" | grep -qE '^[[:space:]]*(echo|jq|printf)([[:space:]]|$)'; then
      log "BLOCK non-standard outbox writer"
      cat >&2 <<'MSG'
🚫 BLOQUEADO — writer não autorizado para outbox.

O Bash do outbox deve COMEÇAR com echo/jq/printf.
Para qualquer outro processamento, DELEGUE para subagente via Agent/Task.
MSG
      exit 2
    fi

    # 2b) Strip das substituições PERMITIDAS
    stripped=$(echo "$tool_command" | sed -E 's/\$\(date[^)]*\)//g; s/\$\(uuidgen[^)]*\)//g')

    # 2c) Smuggling via $(...) ou backticks
    if echo "$stripped" | grep -qE '\$\(|`[a-zA-Z_/.]'; then
      log "BLOCK smuggle via substitution"
      cat >&2 <<'MSG'
🚫 BLOQUEADO — SMUGGLING via command substitution detectado.

Para obter dados, DELEGUE via Agent/Task → coder/explorer.
Receba o resultado e SÓ ENTÃO escreva no outbox.
MSG
      exit 2
    fi

    # 2d) Pipes, chaining, process substitution
    if echo "$stripped" | grep -qE '(\|\||&&|;[[:space:]]|<\(|>\([^>])'; then
      log "BLOCK pipe/chain in outbox"
      cat >&2 <<'MSG'
🚫 BLOQUEADO — pipe ou encadeamento no outbox.
Escrita no outbox é operação simples e atômica.
MSG
      exit 2
    fi

    if echo "$stripped" | grep -qE '\|[[:space:]]*(cat|find|ls|grep|awk|sed|xargs|head|tail|wc|sort|uniq|cut|tr|tee|jq|curl|wget|bash|sh|python|perl|node|npm|exec|eval)\b'; then
      log "BLOCK pipe-to-command in outbox"
      cat >&2 <<'MSG'
🚫 BLOQUEADO — pipe para comando externo no outbox.
MSG
      exit 2
    fi

    log "ALLOW outbox write (main NADIA)"
    exit 0
  fi
fi

# ───────────────────────────────────────────────────────────────────
# 2.5) Read em /opt/AGENTE-bot/photos/ — leitura de imagens recebidas via Telegram
# ───────────────────────────────────────────────────────────────────
if [ "$tool_name" = "Read" ]; then
  file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
  if echo "$file_path" | grep -qE '^/opt/AGENTE-bot/photos/[^/]+\.(jpg|jpeg|png|webp|gif)$'; then
    log "ALLOW photo read ($file_path)"
    exit 0
  fi
fi

# ───────────────────────────────────────────────────────────────────
# 3) Main NADIA + qualquer outra tool = bloqueado
# ───────────────────────────────────────────────────────────────────
log "BLOCK main NADIA direct tool"

cat >&2 <<'MSG'
🚫 BLOQUEADO PELO HOOK DE DELEGAÇÃO (v3)

Você é a NADIA — ORQUESTRADORA. Você NÃO executa tools diretamente.

OBRIGATÓRIO: use Agent ou Task com subagent_type apropriado:

  • explorer    → buscar arquivos, grep, mapear código (read-only)
  • coder       → editar, criar, modificar, rodar comandos (full access)
  • reviewer    → revisar diffs, validar testes
  • researcher  → pesquisa web, leitura de docs

Os subagentes têm Bash/Read/Edit/etc LIBERADOS — o hook só bloqueia VOCÊ
(orquestradora). Delegue e o subagente executa sem problema.

ÚNICA EXCEÇÃO direta: Bash escrevendo em /opt/AGENTE-bot/outbox/*.json
com echo/jq/printf, sem $(...) (exceto $(date)/$(uuidgen)).
MSG

exit 2
