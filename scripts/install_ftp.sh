#!/bin/bash

set -e

echo "[FTP] ➤ Installation de vsftpd"
sudo dnf install -y vsftpd

echo "[FTP] ➤ Sauvegarde du fichier de configuration"
sudo cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.bak

echo "[FTP] ➤ Nettoyage et configuration propre"
sudo sed -i '/^anonymous_enable=/d' /etc/vsftpd/vsftpd.conf
sudo sed -i '/^userlist_enable=/d' /etc/vsftpd/vsftpd.conf
sudo sed -i '/^userlist_file=/d' /etc/vsftpd/vsftpd.conf
sudo sed -i '/^chroot_local_user=/d' /etc/vsftpd/vsftpd.conf
sudo sed -i '/^allow_writeable_chroot=/d' /etc/vsftpd/vsftpd.conf
sudo sed -i '/^userlist_deny=/d' /etc/vsftpd/vsftpd.conf

sudo tee -a /etc/vsftpd/vsftpd.conf > /dev/null <<EOF
anonymous_enable=NO
userlist_enable=YES
userlist_file=/etc/vsftpd/user_list
userlist_deny=NO
chroot_local_user=YES
allow_writeable_chroot=YES
EOF

sudo touch /etc/vsftpd/user_list

echo "[FTP] ➤ Démarrage du service vsftpd"
sudo systemctl enable --now vsftpd

echo "[FTP] ✔️ vsftpd installé et configuré"
