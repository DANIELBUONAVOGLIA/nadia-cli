---
name: monitorar-vps
description: Monitor de saúde do VPS — checa status dos serviços (NADIA, Secretary, bots Telegram), uso de CPU/memória/disco, expiração de tokens OAuth, e alerta proativamente o User via Telegram quando algo cai ou está perto de falhar. Roda como cron a cada 5min. Acionar para "monitora a infra", "verifica saúde do sistema", "alerta se algo cair", "health check VPS".
license: Comercial - YourBrand
allowed-tools: Read, Write, Bash
---

# Skill: Monitor VPS — Vigilante Secretary

## O que essa skill faz

Roda **a cada 5 minutos via cron** e verifica:

1. **Processos críticos:**
   - NADIA (claude --model opus-4-7) rodando como agente
   - Secretary (claude no /opt/SECRETARY) rodando como agente
   - Bots Telegram (`secretary-telegram-bot.service`, agente-bot equivalent)

2. **Recursos do sistema:**
   - Uso de disco (alerta se > 80%)
   - Memória disponível (alerta se < 1GB livre)
   - CPU sustained > 90% por 5+ min (alerta possível runaway)

3. **Tokens OAuth:**
   - `CLAUDE_CODE_OAUTH_EXPIRES_AT` se < 24h pra expirar → alerta
   - Refresh log: se últimas 3 tentativas falharam → alerta

4. **Outbox queue:**
   - Mensagens travadas no outbox por > 5min → alerta (bot pode estar offline)

5. **Conectividade:**
   - DNS resolve OK
   - Ping a api.anthropic.com

## Como avisa o User

**Canal principal:** Telegram via Secretary (faz parte da função de secretária dela).

Mensagem chega assim:
> 🚨 *Secretary aqui — alerta de saúde*
>
> Detectei:
> - ❌ NADIA tmux não responde (offline há 8min)
> - ⚠️ Disco em 87% (alerta de threshold)
>
> Já tentei recovery automático em NADIA. Sem sucesso.
> Roda no terminal: `tmux kill-session -t nadia_cli && tmux new -d ...`

**Recovery automático tenta:**
- Reiniciar tmux session se não responde (1 retry)
- Renovar OAuth se token expirou (chama `refresh_token.sh`)
- Limpar `/tmp/*` se disco cheio (libera espaço temp)

Se recovery falhar, alerta User.

## Setup

### 1) Instalar o script

```bash
# (já feito pelo deploy desta skill)
ls /opt/AGENTE/skills/monitorar-vps/scripts/monitor.sh
```

### 2) Adicionar cron como root

```bash
# Editar crontab root
crontab -e

# Adicionar linha:
*/5 * * * * /opt/AGENTE/skills/monitorar-vps/scripts/monitor.sh >> /var/log/nadia_monitor.log 2>&1
```

### 3) Configurar Telegram alerts

A Secretary já tem `TELEGRAM_BOT_TOKEN` em `/opt/SECRETARY-bot/.env`. O monitor reusa esse token + o `chat_id` do User (`YOUR_TELEGRAM_CHAT_ID`) pra enviar alertas.

Override possível via `/opt/AGENTE/.env`:
```
MONITOR_TELEGRAM_CHAT_ID=YOUR_TELEGRAM_CHAT_ID    # User
MONITOR_TELEGRAM_BOT_TOKEN=...          # se preferir bot dedicado
MONITOR_ALERT_THROTTLE_MIN=30           # nao spam mesmo alerta em 30min
```

## Output

- Log persistente em `/var/log/nadia_monitor.log`
- Estado atual em `/tmp/nadia_monitor_state.json` (último check)
- Histórico de alertas em `/var/log/nadia_monitor_alerts.log`

## Princípios

- **Anti-spam:** mesmo alerta = 1x a cada 30min (throttling)
- **Recovery first:** tenta consertar antes de avisar
- **Severity levels:** INFO (log), WARN (log + dashboard), CRIT (Telegram)
- **Idempotente:** rodar várias vezes seguidas não duplica nada
- **Lightweight:** check completo em < 5 segundos

## Limites

- Não monitora aplicações fora do VPS (Vercel, Cloudflare etc — seria outra skill)
- Não substitui ferramentas profissionais (Datadog, NewRelic) — é "good enough" pra solo dev/agência pequena
- Threshold são tunáveis no script

## Como User reverte (parar monitoramento)

```bash
# Remover linha do crontab
crontab -e
# (apaga a linha do monitor.sh)
```

Ou silenciar temporariamente:
```bash
touch /tmp/monitor_pause   # script detecta e pula até remover
```

## Roadmap

- Dashboard web em `monitor.dominio.com.br` mostrando status real-time
- Métricas histórias (uptime %, recovery rate)
- Integração com PagerDuty quando virar enterprise
