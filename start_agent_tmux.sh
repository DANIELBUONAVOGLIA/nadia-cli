#!/bin/bash
# Garante que a sessão tmux existe e inicia o Claude com OAuth
tmux has-session -t nadia_cli 2>/dev/null || tmux new-session -d -s nadia_cli -n main
sleep 1
tmux send-keys -t nadia_cli:0 "su - agente -s /bin/bash -c '/opt/AGENTE/start_claude.sh'" Enter
