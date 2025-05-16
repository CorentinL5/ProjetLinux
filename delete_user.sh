#!/bin/bash

# Usage : ./delete_user.sh <username>
# Supprime proprement un utilisateur : Linux, base de données, FTP, Samba, Apache, fichiers

MYSQL_ROOT_PWD=$(cat /root/.mariadb_root_pass)

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

# 1. Base de données
echo "[−] Suppression de la base de données"
sudo mysql -uroot -p"$MYSQL_ROOT_PWD" -e "DROP DATABASE IF EXISTS $DB_NAME;" || true
sudo mysql -uroot -p"$MYSQL_ROOT_PWD" -e "DROP USER IF EXISTS '$DB_USER'@'localhost';" || true
sudo mysql -uroot -p"$MYSQL_ROOT_PWD" -e "FLUSH PRIVILEGES;" || true

# 2. Dossier
echo "[−] Suppression du dossier $USERROOT"
sudo rm -rf "$USERROOT"

# 3. Utilisateur système
echo "[−] Suppression de l'utilisateur Linux"
sudo userdel -r "$USER" 2>/dev/null || true

# 4. Quota
echo "[−] Suppression du quota"
sudo setquota -u $USER 0 0 0 0 /srv/clients || true

# 5. Apache
echo "[−] Suppression de la config Apache"
sudo rm -f "$APACHE_CONF"
sudo systemctl reload httpd

# 6. FTP
echo "[−] Suppression de l'entrée FTP"
sudo sed -i "/^$USER$/d" /etc/vsftpd/user_list

# 7. Samba
echo "[−] Suppression de l'entrée Samba"
sudo smbpasswd -x $USER 2>/dev/null || true
if grep -q "^\[$USER\]" /etc/samba/smb.conf; then
  sudo sed -i "/^\[$USER\]/,/^\[/d" /etc/samba/smb.conf
fi
sudo systemctl restart smb nmb

echo "[✓] $USER supprimé proprement."
