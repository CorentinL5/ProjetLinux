#!/bin/bash

set -e
echo "[FTP] Installation de vsftpd"
sudo dnf install -y vsftpd

echo "[FTP] Configuration"
sudo cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.bak
sudo sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd/vsftpd.conf
echo "userlist_enable=YES" | sudo tee -a /etc/vsftpd/vsftpd.conf
echo "userlist_file=/etc/vsftpd/user_list" | sudo tee -a /etc/vsftpd/vsftpd.conf
echo "chroot_local_user=YES" | sudo tee -a /etc/vsftpd/vsftpd.conf
echo "allow_writeable_chroot=YES" | sudo tee -a /etc/vsftpd/vsftpd.conf

sudo touch /etc/vsftpd/user_list

sudo systemctl enable --now vsftpd
echo "[FTP] ✔️ vsftpd prêt à l'emploi"
