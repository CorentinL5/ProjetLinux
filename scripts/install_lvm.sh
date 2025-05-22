#!/bin/bash

# install_LVM.sh
# Initialise un volume LVM partagé pour /srv/clients avec support des quotas utilisateur

set -e

echo "[LVM] ➤ Installation de lvm2 (si manquant)"
sudo yum install -y lvm2 quota

# Vérifie si les disques existent
if [ ! -b /dev/xvdb ] || [ ! -b /dev/xvdc ]; then
  echo "[ERREUR] Les disques /dev/xvdb et /dev/xvdc doivent être attachés avant d'exécuter ce script."
  exit 1
fi

# 1. Création des volumes physiques
echo "[LVM] ➤ Initialisation des disques /dev/xvdb et /dev/xvdc"
sudo pvcreate /dev/xvdb /dev/xvdc

# 2. Création du groupe de volumes
echo "[LVM] ➤ Création du groupe de volumes vg_clients"
sudo vgcreate vg_clients /dev/xvdb /dev/xvdc

# 3. Création du volume logique de 4 Go
echo "[LVM] ➤ Création du volume logique lv_clients (4G)"
sudo lvcreate -l 100%FREE -n lv_clients vg_clients

# 4. Formatage avec ext4
echo "[LVM] ➤ Formatage du volume avec ext4 + usrquota"
sudo mkfs.ext4 /dev/vg_clients/lv_clients

# 5. Montage
echo "[LVM] ➤ Montage sur /srv/clients avec usrquota"
sudo mkdir -p /srv/clients
echo "/dev/vg_clients/lv_clients /srv/clients ext4 defaults,usrquota 0 0" | sudo tee -a /etc/fstab
sudo mount -a
sudo mount -o remount,usrquota /srv/clients

# 6. Activation des quotas
echo "[LVM] ➤ Initialisation et activation des quotas"
sudo quotacheck -cum /srv/clients
sudo quotaon /srv/clients

echo "[LVM] ✅ Volume logique monté sur /srv/clients avec quotas activés"
