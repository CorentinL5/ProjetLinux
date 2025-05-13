#!/bin/bash

set -e
echo "[NFS] Installation des outils NFS"
sudo dnf install -y nfs-utils

SHARE_PATH="/srv/share"
echo "[NFS] Configuration du répertoire partagé : $SHARE_PATH"
sudo mkdir -p $SHARE_PATH
sudo chown nobody:nobody $SHARE_PATH
sudo chmod 2775 $SHARE_PATH

echo "[NFS] Configuration de /etc/exports"
echo "$SHARE_PATH *(rw,sync,no_subtree_check,no_root_squash)" | sudo tee /etc/exports

echo "[NFS] Démarrage du serveur NFS"
sudo systemctl enable --now nfs-server
sudo exportfs -rav

echo "[NFS] ✔️ NFS prêt à exporter : mount <IP>:$SHARE_PATH /mnt"
