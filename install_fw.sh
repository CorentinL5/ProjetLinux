#!/bin/bash

set -e
echo "[FIREWALL] ➤ Activation de firewall-cmd (Firewalld)"
sudo systemctl enable --now firewalld

echo "[FIREWALL] ➤ Ouverture des ports standards"
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-service=ftp
sudo firewall-cmd --permanent --add-service=dns
sudo firewall-cmd --permanent --add-service=ntp
sudo firewall-cmd --permanent --add-port=2049/tcp   # NFS
sudo firewall-cmd --permanent --add-port=2049/udp
sudo firewall-cmd --permanent --add-port=445/tcp    # Samba
sudo firewall-cmd --permanent --add-port=139/tcp
sudo firewall-cmd --permanent --add-port=137-138/udp
sudo firewall-cmd --reload

echo "[FIREWALL] ✅ Configuration terminée"
