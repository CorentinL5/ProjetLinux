#!/bin/bash

set -e

# ========================
# CONFIG
# ========================
USER="samba_user"
GROUP="sharedusers"
SHARE_PATH="/srv/share"
SHARE_NAME="Share"

# ========================
# Préparation du dossier
# ========================
echo "[+] Création du groupe et du dossier partagé"
sudo groupadd -f $GROUP
sudo mkdir -p $SHARE_PATH
sudo useradd -M -s /sbin/nologin -g $GROUP $USER || true

# ========================
# Droits
# ========================
echo "[+] Attribution des droits"
sudo chown -R $USER:$GROUP $SHARE_PATH
sudo chmod 2775 $SHARE_PATH

# ========================
# Samba - Installation
# ========================
echo "[+] Installation de Samba"
sudo dnf install -y samba samba-common

# ========================
# Samba - Configuration utilisateur
# ========================
echo "[+] Création de l'utilisateur Samba (sans mot de passe explicite)"
echo -e "\n\n" | sudo smbpasswd -a -n $USER
sudo smbpasswd -e $USER

# ========================
# Configuration du fichier smb.conf
# ========================
echo "[+] Configuration de Samba"
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

sudo tee /etc/samba/smb.conf > /dev/null <<EOF
[global]
   workgroup = SAMBA
   server string = Samba Server
   security = user
   map to guest = Bad User
   guest account = $USER

[$SHARE_NAME]
   path = $SHARE_PATH
   browseable = yes
   writable = yes
   public = yes
   guest ok = yes
   force user = $USER
   create mask = 0664
   directory mask = 2775
EOF

# ========================
# Services
# ========================
echo "[+] Redémarrage des services"
sudo systemctl enable --now smb nmb

# ========================
# Résumé
# ========================
echo "[✓] Samba DFS sans mot de passe configuré avec succès !"
echo "Accès via \\\\IP\\$SHARE_NAME depuis Windows ou Linux"
