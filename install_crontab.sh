#!/bin/bash
set -e

echo "🛠️ Installation du service cron..."

# Installe cronie s’il n’existe pas
if ! command -v crontab &> /dev/null; then
  sudo dnf install -y cronie
fi

# Active et démarre crond
sudo systemctl enable --now crond

# Vérifie que crond est actif
if systemctl is-active --quiet crond; then
  echo "✅ Service crond actif et prêt"
else
  echo "⛔ Le service crond ne démarre pas. Vérifie avec : systemctl status crond"
  exit 1
fi
