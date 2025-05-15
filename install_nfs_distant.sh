#!/bin/bash

set -e
echo "[NFS] Installation des outils NFS"
sudo dnf install -y nfs-utils

SHARE_PATH="/srv/nfs/backup"
echo "[NFS] Configuration du répertoire partagé : $SHARE_PATH"
sudo mkdir -p "$SHARE_PATH"
sudo chown nobody:nobody "$SHARE_PATH"
sudo chmod 777 "$SHARE_PATH"

echo "[NFS] Configuration de /etc/exports"
echo "$SHARE_PATH 10.42.0.0/16(rw,sync,no_subtree_check,no_root_squash)" | sudo tee /etc/exports

echo "[NFS] Démarrage du serveur NFS"
sudo systemctl enable --now nfs-server
sudo exportfs -rav

echo "[NFS] ✔️ NFS installé et configuré pour /srv/nfs/backup"
