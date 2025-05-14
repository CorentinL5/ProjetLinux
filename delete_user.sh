#!/bin/bash

# delete_user.sh <username>
# Supprime proprement un utilisateur : Linux, base de données, FTP, Samba, fichiers

set -e

if [ $# -ne 1 ]; then
  echo "Usage: $0 <username>"
  exit 1
fi

USER="$1"
DB_NAME="${USER}_db"
DB_USER="${USER}_dbuser"
USERROOT="/srv/clients/$USER"
APACHE_CONF="/etc/httpd/conf.d/$USER.conf"

echo "[−] Suppression de la base de données"
sudo mariadb -e "DROP DATABASE IF EXISTS $DB_NAME;"
sudo mariadb -e "DROP USER IF EXISTS '$DB_USER'@'localhost';"
sudo mariadb -e "FLUSH PRIVILEGES;"

echo "[−] Suppression du dossier $USERROOT"
sudo rm -rf "$USERROOT"

echo "[−] Suppression de l'utilisateur Linux"
sudo userdel -r "$USER" || true

echo "[−] Suppression du quota"
sudo setquota -u $USER 0 0 0 0 /srv/clients || true

echo "[−] Suppression de la config Apache"
sudo rm -f "$APACHE_CONF"
sudo systemctl reload httpd

echo "[−] Suppression de l'entrée FTP"
sudo sed -i "/^$USER$/d" /etc/vsftpd/user_list

echo "[−] Suppression de l'entrée Samba"
sudo smbpasswd -x $USER || true
sudo sed -i "/\\[$USER\\]/,+6d" /etc/samba/smb.conf
sudo systemctl restart smb nmb

echo "[✓] $USER supprimé proprement."
