#!/bin/bash

set -e
echo "[SAMBA] Installation de Samba"
sudo dnf install -y samba samba-common-tools

echo "[SAMBA] Configuration du répertoire partagé"
SHARE_PATH="/srv/share"
sudo mkdir -p $SHARE_PATH
sudo chown -R nobody:nobody $SHARE_PATH
sudo chmod 2775 $SHARE_PATH

echo "[SAMBA] Sauvegarde de smb.conf"
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

echo "[SAMBA] Configuration smb.conf"
sudo tee /etc/samba/smb.conf > /dev/null <<EOF
[global]
   workgroup = SAMBA
   server string = Samba Server
   security = user
   map to guest = Bad User
   guest account = nobody

[Share]
   path = $SHARE_PATH
   browseable = yes
   writable = yes
   public = yes
   guest ok = yes
   force user = nobody
   create mask = 0664
   directory mask = 2775
EOF

echo "[SAMBA] Démarrage des services"
sudo systemctl enable --now smb nmb

echo "[SAMBA] ✔️ Samba configuré avec partage public : \\\\IP\\Share"
