#!/bin/bash

# init_clients_volume.sh
# Initialise un volume LVM partagé pour /srv/clients avec support des quotas utilisateur

set -e

# 1. Création des volumes physiques
echo "[LVM] ➤ Initialisation des disques /dev/xvdb et /dev/xvdc"
sudo pvcreate /dev/xvdb /dev/xvdc

# 2. Création du groupe de volume
echo "[LVM] ➤ Création du volume group vg_clients"
sudo vgcreate vg_clients /dev/xvdb /dev/xvdc

# 3. Création d'un volume logique unique de 4 Go
echo "[LVM] ➤ Création du volume logique lv_clients (4G)"
sudo lvcreate -L4G -n lv_clients vg_clients

# 4. Formatage en ext4
echo "[LVM] ➤ Formatage en ext4 avec support des quotas"
sudo mkfs.ext4 /dev/vg_clients/lv_clients

# 5. Création du point de montage
echo "[LVM] ➤ Montage sur /srv/clients avec usrquota"
sudo mkdir -p /srv/clients
echo "/dev/vg_clients/lv_clients /srv/clients ext4 defaults,usrquota 0 0" | sudo tee -a /etc/fstab
sudo mount -a
sudo mount -o remount,usrquota /srv/clients

# 6. Activation des quotas
echo "[LVM] ➤ Initialisation et activation des quotas"
sudo quotacheck -cum /srv/clients
sudo quotaon /srv/clients

echo "[LVM] ✅ Volume /srv/clients prêt avec quotas utilisateur activés"
