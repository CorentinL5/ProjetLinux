#!/bin/bash

set -e

echo "[FTP-FIX] ➤ Correction complète de vsftpd (PAM, config, TLS désactivé, Passive)"

# 1. Sauvegarde de la conf PAM
echo "[FTP-FIX] ➤ Sauvegarde de /etc/pam.d/vsftpd"
sudo cp /etc/pam.d/vsftpd /etc/pam.d/vsftpd.bak 2>/dev/null || true

# 2. Réécriture du fichier PAM minimal
echo "[FTP-FIX] ➤ Application du fichier PAM minimal"
sudo tee /etc/pam.d/vsftpd > /dev/null <<EOF
#%PAM-1.0
auth       required     pam_unix.so
account    required     pam_unix.so
session    required     pam_loginuid.so
EOF

# 3. Nettoyage de la config vsftpd
echo "[FTP-FIX] ➤ Correction de la configuration vsftpd"
sudo cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.bak 2>/dev/null || true

sudo sed -i '/^anonymous_enable=/d' /etc/vsftpd/vsftpd.conf
sudo sed -i '/^userlist_enable=/d' /etc/vsftpd/vsftpd.conf
sudo sed -i '/^userlist_file=/d' /etc/vsftpd/vsftpd.conf
sudo sed -i '/^userlist_deny=/d' /etc/vsftpd/vsftpd.conf
sudo sed -i '/^chroot_local_user=/d' /etc/vsftpd/vsftpd.conf
sudo sed -i '/^allow_writeable_chroot=/d' /etc/vsftpd/vsftpd.conf
sudo sed -i '/^pam_service_name=/d' /etc/vsftpd/vsftpd.conf
sudo sed -i '/^ssl_enable=/d' /etc/vsftpd/vsftpd.conf
sudo sed -i '/^pasv_enable=/d' /etc/vsftpd/vsftpd.conf
sudo sed -i '/^pasv_min_port=/d' /etc/vsftpd/vsftpd.conf
sudo sed -i '/^pasv_max_port=/d' /etc/vsftpd/vsftpd.conf

# 4. Ajout des directives recommandées
sudo tee -a /etc/vsftpd/vsftpd.conf > /dev/null <<EOF
pam_service_name=vsftpd
anonymous_enable=NO
userlist_enable=YES
userlist_file=/etc/vsftpd/user_list
userlist_deny=NO
chroot_local_user=YES
allow_writeable_chroot=YES
ssl_enable=NO
pasv_enable=YES
pasv_min_port=30000
pasv_max_port=30010
EOF

# 5. Ouvrir les ports dans firewalld
echo "[FTP-FIX] ➤ Configuration du pare-feu"
sudo firewall-cmd --permanent --add-service=ftp
sudo firewall-cmd --permanent --add-port=30000-30010/tcp
sudo firewall-cmd --reload

# 6. Redémarrage du service
echo "[FTP-FIX] ➤ Redémarrage du service vsftpd"
sudo systemctl restart vsftpd

echo "[FTP-FIX] ✅ Correction terminée. Le serveur FTP est prêt à fonctionner."
