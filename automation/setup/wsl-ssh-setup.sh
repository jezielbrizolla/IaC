#!/usr/bin/env bash
set -e

git config --global --add safe.directory /mnt/c/Users/jezie/OneDrive/Documentos/Estudos/IaC/labs

if ! grep -q "Start ssh-agent and load ssh-iac" ~/.bashrc 2>/dev/null; then
  cat >> ~/.bashrc <<'EOF'
# Start ssh-agent and load ssh-iac for GitHub SSH
if [ -n "$PS1" ] && [ -f ~/.ssh/ssh-iac ]; then
  if [ -z "$SSH_AUTH_SOCK" ] || ! ssh-add -l >/dev/null 2>&1; then
    eval "$(ssh-agent -s)" >/dev/null
    ssh-add ~/.ssh/ssh-iac >/dev/null 2>&1
  fi
fi
EOF
fi

[ -f ~/.ssh/config ] && chmod 600 ~/.ssh/config
[ -f ~/.ssh/ssh-iac ] && chmod 600 ~/.ssh/ssh-iac
