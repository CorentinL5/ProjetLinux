#!/bin/bash

set -e
echo "[WEB] Installation d'Apache"
sudo dnf install -y httpd
sudo systemctl enable --now httpd

echo "[WEB] Configuration de base"
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload

echo "[WEB] ✔️ Apache prêt à servir"
