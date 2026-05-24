# FAILOVER — Anthropic caiu, ativar Nadia backup-agent

## Quando usar
Quando NADIA_CLI parar de responder por motivo de **Anthropic** (não problema local).
Sintomas: 401 persistente que não recupera, `api.anthropic.com` retornando 5xx,
status.anthropic.com mostrando incidente ativo, ou User sabe por outras fontes.

Se for problema local (token expirado, tmux morto, etc) → seguir
`/opt/AGENTE/RECOVERY.md`, NÃO este documento.

## Resumo arquitetural
- **NADIA_CLI**: roda em Claude Code, 100% dependente da Anthropic. Fica off.
- **Nadia backup-agent**: roda em backup-agent com `openai-codex/gpt-5.5` como primary.
  Os 12 subagentes Haiku-only (personas,
  davi, lucas, felipe, matheus, amanda, carolina, bianca) têm fallback
  configurado pra `openai-codex/gpt-5.4-mini`. Reeve usa gpt-5.5.
- O conteúdo (subagentes + memory) é sincronizado **toda noite 03:00 BRT**
  via `/opt/AGENTE/scripts/sync-nadia-to-backup-agent.py`. Logs em
  `/var/log/nadia-backup-agent-sync.log`.

## 3 passos pra ativar

### 1. Confirmar que NADIA está realmente off por causa da Anthropic
```bash
ssh -i ~/.ssh/nadia_admin_ed25519 root@YOUR_VPS_IP \
  'tail -30 /var/log/nadia-watchdog.log; \
   tail -30 /var/log/secretary-watchdog.log; \
   curl -s -o /dev/null -w "%{http_code}\n" https://api.anthropic.com'
```
Se watchdogs mostram 401/auth_error E status.anthropic.com confirma incidente
→ é Anthropic, segue. Se for outra coisa → vai pra RECOVERY.md.

### 2. Pausar bots NADIA (pra não acumular fila em vão)
```bash
ssh root@YOUR_VPS_IP 'touch /tmp/nadia_watchdog_pause; \
  systemctl stop nadia_cli-bot.service'
```

### 3. Confirmar que backup-agent está vivo e responder pelo backup-agent
```bash
# Gateway backup-agent rodando?
ssh root@YOUR_VPS_IP 'systemctl status backup-agent-gateway --no-pager | head -5; \
  nc -z 127.0.0.1 18789 && echo "porta 18789 OK"'

# Subagentes carregaram com fallback? (deve mostrar openai-codex/gpt-5.4-mini)
ssh root@YOUR_VPS_IP 'python3 -c "
import json
cfg=json.load(open(\"/root/.backup-agent/backup-agent.json\"))
for a in cfg[\"agents\"][\"list\"]:
    print(a[\"id\"], a[\"model\"][\"primary\"], a[\"model\"][\"fallbacks\"])
"'
```

A partir daqui, mandar tarefas pelo bot Telegram da backup-agent (token diferente,
em `/root/.backup-agent/backup-agent.json` campo `channels.telegram.botToken`). Você
pode usar esse bot pra falar com a Nadia backup-agent enquanto a Anthropic não volta.

## Quando Anthropic voltar
```bash
ssh root@YOUR_VPS_IP 'rm /tmp/nadia_watchdog_pause; \
  systemctl start nadia_cli-bot.service'
```
O `nadia-watchdog` (cron 2min) detecta tmux/processo e reinicia se preciso.

## Validar saúde da sincronização (qualquer hora)
```bash
ssh root@YOUR_VPS_IP 'tail -20 /var/log/nadia-backup-agent-sync.log'
```
Se a última linha for `=== sync done — alterados: N, erros: 0 ===`, OK.
Se Telegram chegou alerta de FALHA, abrir o log e ver causa.

## Limites conhecidos
- Sync é one-way (NADIA → backup-agent). Qualquer edição direta em
  `/root/.backup-agent/workspace-*/SOUL.md` é sobrescrita na próxima sync.
- SOUL/AGENTS/USER/STARTUP/TOOLS do main workspace (`/root/.backup-agent/workspace/`)
  NÃO são tocados pela sync — são curados manualmente.
- NADIA agents sem mapeamento backup-agent (alex-design, amanda-crm, analista-mercado,
  coder, student-clone-dm, explorer, researcher, reviewer) NÃO existem na
  backup-agent. Se precisar deles em failover, criar manualmente no backup-agent.json
  e em `/root/.backup-agent/workspace-<nome>/`.
- Subagentes openai-codex/gpt-5.4-mini só funcionam se a conta OpenAI tem
  saldo/quota. Verificar antes do failover real.
