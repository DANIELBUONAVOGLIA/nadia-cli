# Agente Claude Code + Telegram - Setup Automatizado (v3 - VERSAO PUBLICA PRA ALUNOS)

---

## INSTALACAO 5 MIN - Sem mexer em terminal (caminho recomendado)

> **Voce nao precisa saber comando nenhum.** O Claude Code do seu PC faz SSH na sua VPS automaticamente, instala tudo, configura, sobe o agente. Voce so responde perguntas.

**6 passos:**

1. Compre uma VPS Ubuntu 22.04+ (Hostinger, Hetzner, DigitalOcean - 4GB RAM, ~R$30-60/mes)
2. Anote IP, usuario (`root`) e senha que o provedor te mandou
3. Abra o Claude Code no seu computador ([claude.com/code](https://claude.com/code) ou extensao VS Code)
4. Cole o prompt magico que esta em [`prompt-instalador.txt`](./prompt-instalador.txt)
5. Responda as perguntas do Claude (uma por vez, calmamente)
6. Quando ele falar "agente no ar", abra o Telegram e converse com seu bot

**Guia detalhado passo a passo:** [`INSTRUCAO-PARA-ALUNO.md`](./INSTRUCAO-PARA-ALUNO.md)

---

## Caminho avancado (manual, pra quem ja sabe terminal)

Se voce e desenvolvedor e prefere SSH na VPS e rodar os comandos voce mesmo, siga as secoes abaixo. O fluxo termina no mesmo agente, so e mais "hands on".

> **VERSAO PUBLICA - ALUNOS DO User**
> Esse repo e a versao publica/sanitizada do setup interno do User. Todos os dados pessoais do dono original viraram placeholders no formato `{{NOME}}`. Voce, aluno, vai preencher com os SEUS proprios dados (nome, dominios, IPs, tokens, bot Telegram, etc).
>
> Nao tente rodar nada sem antes substituir os placeholders. Veja a tabela em `SETUP-AGENTE.md` (ETAPA 0) com cada `{{NOME}}` e onde pegar/o que e.

Instala um agente Claude Code conectado ao Telegram em qualquer VPS Ubuntu 22+ ou macOS. Roda 24/7 via tmux + systemd (Linux) ou tmux + launchd (Mac), sobrevive reboots e auto-reinicia se cair.

**v3 (abril 2026)** - upgrade massivo da v2:
- agent-manager.py via PM2 (porta 3600 + Caddy + Cloudflare tunnel)
- 5 subagentes especializados (paulo-dev, juliana-ops, jonathan-copy, rafael-projetos, davi-sdr)
- Audio bidirecional (Whisper entrada + ElevenLabs saida)
- Memoria vetorial PostgreSQL + pgvector

## Uso

### 1. Na VPS limpa (Ubuntu 22.04+) ou no Mac:

```bash
curl -fsSL https://raw.githubusercontent.com/student2013-bot/agente-claude-telegram-setup-alunos-student/main/bootstrap.sh | bash
```

Linux: roda como `root`. Mac: roda como usuario normal (sem sudo na chamada). O script detecta o SO e instala o que precisa.

Instala: Node 22 (via nvm), Python 3, ffmpeg, Claude Code CLI 2.1.118 (pinado), tmux, PostgreSQL 16 + pgvector, Caddy, pm2 globalmente. Baixa o `SETUP-AGENTE.md` pra `/root/` (Linux) ou `~/` (Mac).

### 2. Logar na conta Claude:

```bash
claude auth login --claudeai
```

Abre link no navegador, loga com Pro/Max, autoriza.

### 3. Iniciar o Claude e deixar ele fazer o resto:

```bash
cd /root        # ou cd ~ no Mac
claude --dangerously-skip-permissions
```

### 4. Dentro do Claude, cola:

```
Leia o arquivo SETUP-AGENTE.md e execute todos os passos.
Me faca perguntas quando precisar de informacao minha.
```

O Claude pergunta nome do agente, dono, tokens, configura tudo e entrega o agente rodando.

## Arquitetura v3

```
[Telegram]  <==>  [Bot Python systemd 24/7]  <==>  tmux send-keys + outbox JSON
                            |                              |
                            v                              v
                   [audio Whisper / TTS]          [Claude Code (tmux)]
                                                          |
                                                          v
                                               [agent-manager.py PM2]
                                                          |
                                  +---------+---------+---+---+
                                  v         v         v       v
                              paulo-dev juliana-ops jonathan rafael davi-sdr
```

5 camadas de resiliencia:
- Bot Python systemd `Restart=always`
- Claude Code tmux + start.sh com backoff
- agent-manager via PM2 (auto-restart)
- Healthcheck a cada 2 min com auto-alerta no Telegram

## Recursos v3

- Bot externo Python sempre vivo (independente do Claude Code)
- Audio entrada (Whisper PT-BR) e saida (ElevenLabs TTS) bidirecional
- "Digitando..." automatico durante todo processamento
- 5 subagentes especializados (paulo-dev, juliana-ops, jonathan-copy, rafael-projetos, davi-sdr)
- Memoria vetorial PostgreSQL + pgvector (HNSW index)
- agent-manager.py via PM2 (porta 3600 + Caddy proxy HTTPS)
- Healthcheck a cada 2 min com auto-alerta
- Backup conversas a cada 2h, relatorio diario as 9h

## Requisitos

- VPS Ubuntu 22.04+ (4 GB RAM minimo, 8 GB recomendado, 50 GB disco) **ou** macOS 13+
- Conta Claude Pro ou Max
- Conta Telegram (pra @BotFather)
- (Opcional) OpenAI API key (audio entrada via Whisper)
- (Opcional) ElevenLabs API key (audio saida via TTS)
- (Opcional, deploy publico) GitHub PAT + Vercel token + Cloudflare DNS token

## Custo mensal por agente (estimado)

- VPS 4-8 GB: R$40-120 (Hostinger, Hetzner, DigitalOcean)
- Claude Max: US$100 (Pro tambem serve)
- OpenAI Whisper: ~$0.006/min de audio (irrelevante)
- ElevenLabs: free tier 10k chars/mes serve, basic $5/mes
- Telegram: gratis
- PostgreSQL: gratis (local)

Total por agente: ~R$600-700/mes.

## Migracao da v2 para v3

Se ja tem agente v2 rodando, pra adicionar features v3:
1. Atualiza Claude Code: `npm i -g @anthropic-ai/claude-code@2.1.118`
2. Instala PM2: `npm i -g pm2`
3. Cria `agent-manager.py` em `/opt/AGENTE/agent-manager/`
4. Configura Caddy proxy + Cloudflare tunnel
5. Reinicia tudo: `systemctl restart AGENTE AGENTE-bot && pm2 restart agent-manager`

## Issues / Suporte

https://github.com/student2013-bot/agente-claude-telegram-setup-alunos-student/issues

## Como personalizar (placeholders)

Antes de rodar o setup, voce precisa preencher os placeholders no formato `{{NOME}}` que estao espalhados pelos arquivos. Tabela completa em `SETUP-AGENTE.md` (ETAPA 0).

Resumo dos principais:

| Placeholder | O que e | Onde voce acha |
|---|---|---|
| `User` | Seu primeiro nome (ou da empresa) | Voce decide |
| `User` | Nome completo do dono do agente | Voce decide |
| `youruser` | Versao "slug" do nome (lowercase, sem espacos) | Ex: `joao` se voce e Joao |
| `your-email@example.com` | Seu email | Seu email pessoal/profissional |
| `User` | Nome da empresa/produto/marca | Voce decide |
| `youruser` | Slug da empresa | Ex: `meunicho` |
| `PENDENTE` | Seu ID numerico no Telegram | Mande `/id` pra @userinfobot |
| `PENDENTE_bot` | Username do bot que voce criou no @BotFather | Ex: `meuagente_bot` |
| `youruser` | Seu @ no Instagram (sem o @) | Ex: `joao.silva` |
| `YOUR_VPS_IP` | IP da VPS principal onde roda o agente | Hostinger/Hetzner/DigitalOcean |
| `YOUR_VPS_IP` / `YOUR_VPS_IP` / `YOUR_VPS_IP` | IPs de VPS adicionais (se tiver) | Painel da sua provedora |
| `nadia.local` | Seu dominio raiz | Ex: `meusite.com` |
| `nadia.local` | Dominio secundario (opcional) | Ex: `meusite.ai` |
| `crm.nadia.local` | Dominio do CRM (se tiver) | Ex: `crm.meusite.com` |
| `cliente.nadia.local` | Subdominio exemplo de cliente | Ex: `cliente1.meusite.com` |
| `Nadia` | Nome do seu produto/SaaS principal | Voce decide |
| `nadia` | Slug do produto | Ex: `meu-produto` |
| `Mentoria Nadia` / `Formacao Nadia IA` / `Comunidade Nadia` | Nomes dos seus produtos educacionais | Voce decide |
| `nadia2026` | Senha admin que voce vai usar (TROCA depois!) | Voce define |
| `youruser` | Seu username no GitHub | Conta sua |
| `YOURUSER` / `YOURUSER` | Versoes em CAIXA ALTA | Use os mesmos valores ja definidos, em uppercase |
