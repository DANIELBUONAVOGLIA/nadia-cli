# NADIA — Recovery Runbook

## Acesso ao VPS

1. **Admin key (preferido):** `ssh -i ~/.ssh/nadia_admin_ed25519 root@YOUR_VPS_IP`
2. **Senha:** `ssh -o PubkeyAuthentication=no root@YOUR_VPS_IP`
3. **Hostinger Terminal (bypass sshd):** hpanel.hostinger.com → VPS → Terminal

⚠️ `~/.ssh/nadia_vps_ed25519` no Mac tem forced command (só sync OAuth) — NÃO use pra admin.

## Diagnóstico rápido

```
/opt/AGENTE/healthcheck.sh && tail -30 /var/log/nadia_healthcheck.log
```

## NADIA não responde no Telegram

1. `tmux ls` — sessão `nadia_cli` viva? Reattach: `tmux attach -t nadia_cli` (detach Ctrl-B D)
2. `systemctl status nadia_cli-bot` + `journalctl -u nadia_cli-bot -n 50`
3. Token: `cat /home/agente/.env_oauth | grep EXPIRES_AT` (converte ms→data: `date -d @$((VAL/1000))`)
4. Outbox: `ls -la /opt/AGENTE-bot/outbox/` (arquivos antigos = bot parado)

## Token OAuth expirou

1. No Mac: abre Claude Desktop, sync de 5min empurra
2. Manual no Mac: `bash ~/.local/bin/nadia_token_sync.sh`
3. Verificar no VPS: `stat /home/agente/.env_oauth` — mtime recente?

Se Mac não está no ar / sync travado:
- `pgrep -lf caffeinate` no Mac (deve estar rodando)
- `launchctl list | grep nadia` no Mac (3 agents: tokensync, caffeinate, desktopmonitor)
- `open -ga "Claude"` no Mac pra reabrir Desktop

## SSH travado

- **Permission denied (publickey,password)** → use admin key: `ssh -i ~/.ssh/nadia_admin_ed25519 root@YOUR_VPS_IP`
- **fail2ban banindo seu IP** → Hostinger Terminal e: `fail2ban-client unban <SEU_IP>`
- **Trava silencioso** → key errada com forced command. NUNCA use `~/.ssh/nadia_vps_ed25519` pra admin.
- **Server isn't responding** → Hostinger Terminal apertando teclas (~5min) até logind acordar. Depois `passwd root`.

## Bot dá pau

```
systemctl restart nadia_cli-bot
journalctl -u nadia_cli-bot -f
```

tmux com socket errado? Recria como root:
```
tmux kill-session -t nadia_cli 2>/dev/null
tmux new -d -s nadia_cli "su - agente -s /bin/bash -c '/opt/AGENTE/start_claude.sh'"
```

## Cloudflare deploy falha

```
/opt/AGENTE/cloudflare/list_pages.sh
```

HTTP 401 → token rotacionou/foi revogado. Gera novo no dashboard CF → atualiza:
```
read -s -p "Novo CF token: " NEW && echo && sed -i "s|^CLOUDFLARE_API_TOKEN=.*|CLOUDFLARE_API_TOKEN=$NEW|" /opt/AGENTE/.env_cloudflare
```

## Restart limpo (último recurso)

```
systemctl restart nadia_cli-bot
tmux kill-session -t nadia_cli 2>/dev/null
tmux new -d -s nadia_cli "su - agente -s /bin/bash -c '/opt/AGENTE/start_claude.sh'"
```

## NÃO fazer

- "Force restart" no Hostinger se cron acabou de rodar — pode corromper `.env_oauth`. Espera 5min após cada xx:00 UTC.
- Usar `~/.ssh/nadia_vps_ed25519` pra admin — vai travar (tem forced command).
- Fazer mais de 3 tentativas com senha errada — fail2ban vai banir seu IP por 10min.
