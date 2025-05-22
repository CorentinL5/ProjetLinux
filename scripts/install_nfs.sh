#!/bin/bash

set -e

SHARE_PATH="$1"


echo "[NFS] Installation des outils NFS"
sudo dnf install -y nfs-utils

echo "[NFS] Configuration du répertoire partagé : $SHARE_PATH"
sudo mkdir -p "$SHARE_PATH"
sudo chown nobody:nobody "$SHARE_PATH"
sudo chmod 2775 "$SHARE_PATH"

echo "[NFS] Configuration de /etc/exports"
echo "$SHARE_PATH *(rw,sync,no_subtree_check,no_root_squash)" | sudo tee /etc/exports

echo "[NFS] Démarrage du serveur NFS"
sudo systemctl enable --now nfs-server
sudo exportfs -rav

echo "[NFS] ✔️ NFS installé et configuré"
