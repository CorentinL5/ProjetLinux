#!/bin/bash

# Usage : ./create_user.sh <username> <password> <ip>
# Ex: ./create_user.sh client42 superpass 10.42.0.94

MYSQL_ROOT_PWD=$(cat /root/.mariadb_root_pass)

if [ $# -ne 4 ]; then
  echo "Usage: $0 <username> <password> <ip> <domain>"
  exit 1
fi

USER="$1"
if [[ "$USER" =~ \  ]]; then
  echo "[!] Le nom d'utilisateur ne doit pas contenir d'espaces."
  exit 1
fi
PASS="$2"
if [[ "$PASS" =~ \  ]]; then
  echo "[!] Le mot de passe ne doit pas contenir d'espaces."
  exit 1
fi
IP="$3"
if ! [[ "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "[!] L'adresse IP n'est pas valide."
  exit 1
fi
DOMAIN="$4"
if [[ "$DOMAIN" =~ \  ]]; then
  echo "[!] Le nom de domaine ne doit pas contenir d'espaces."
  exit 1
fi
USERCONF="$USER.conf"
USERDOMAIN="$USER.$DOMAIN"
USERROOT="/srv/clients/$USER"
WEBROOT="$USERROOT/www"
DB_NAME="${USER}_db"
DB_USER="${USER}_dbuser"
DB_PASS="$(openssl rand -base64 12)"

echo "[+] Vérification de l'utilisateur..."
if id "$USER" &>/dev/null; then
  echo "[!] Utilisateur $USER existe déjà. Annulation."
  exit 1
fi

# 1. Créer utilisateur système et dossiers
echo "[+] Création de l'utilisateur Linux : $USER"
sudo useradd -d "$USERROOT" -s /sbin/nologin "$USER"
echo "$USER:$PASS" | sudo chpasswd

echo "[+] Création des dossiers et attribution des droits"
sudo mkdir -p "$WEBROOT" "$USERROOT/data"
sudo chown -R "$USER":"$USER" "$USERROOT"

# 2. Appliquer quota utilisateur : 25 Mo
echo "[+] Application du quota de 25 Mo"
if mount | grep -q '/srv/clients'; then
  sudo setquota -u "$USER" 25600 25600 0 0 /srv/clients || echo "[!] Échec quota : quota peut ne pas être activé"
else
  echo "[!] Avertissement : /srv/clients n'est pas monté avec quotas. (Quota non appliqué)"
fi

# 3. Web (Apache)
echo "[+] Configuration Apache"

# Créer page d’accueil personnalisée
sudo tee "$WEBROOT/index.html" > /dev/null <<< "<h1>Bienvenue $USER</h1>"

# Appliquer les droits de fichiers
sudo usermod -a -G apache "$USER"
sudo chown -R "$USER:apache" "$WEBROOT"
sudo chmod -R 775 "$WEBROOT"
sudo chmod 644 "$WEBROOT/index.html"

# Corriger les permissions des dossiers parents pour Apache
sudo chmod o+x /srv
sudo chmod o+x /srv/clients
sudo chmod o+x "$USERROOT"

# Créer le VirtualHost Apache
sudo tee /etc/httpd/conf.d/"$USERCONF" > /dev/null <<EOF
<VirtualHost *:80>
    ServerName $USERDOMAIN
    DocumentRoot $WEBROOT

    <Directory $WEBROOT>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Recharger Apache
sudo systemctl reload httpd
echo "[✓] Apache rechargé"


# 4. FTP
echo "[+] Préparation FTP"
echo "$USER" | sudo tee -a /etc/vsftpd/user_list > /dev/null
sudo chown "$USER":"$USER" "$WEBROOT"

# 5. SAMBA
echo "[+] Préparation Samba"
sudo tee -a /etc/samba/smb.conf > /dev/null <<EOF

[$USER]
   path = $USERROOT
   browseable = yes
   read only = no
   guest ok = no
   valid users = $USER
EOF
(echo "$PASS"; echo "$PASS") | sudo smbpasswd -a "$USER"
sudo smbpasswd -e "$USER"
sudo systemctl restart smb nmb

# 6. DNS (manuel)
echo "[!] À ajouter dans la zone DNS :"
echo "$USER IN A $IP"

# 7. MariaDB/MySQL
echo "[+] Création base de données"
sudo mysql -uroot -p"$MYSQL_ROOT_PWD" -e "CREATE DATABASE $DB_NAME;"
sudo mysql -uroot -p"$MYSQL_ROOT_PWD" -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
sudo mysql -uroot -p"$MYSQL_ROOT_PWD" -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
sudo mysql -uroot -p"$MYSQL_ROOT_PWD" -e "FLUSH PRIVILEGES;"

# 8. Fichier de sortie
INFO_FILE="$USERROOT/your_account.txt"
{
  echo "Nom d'utilisateur : $USER"
  echo "Mot de passe FTP/Samba : $PASS"
  echo "Web : http://$USERDOMAIN"
  echo "FTP : ftp://$IP"
  echo "Samba : \\\\$IP\\$USER"
  echo "Base de données : $DB_NAME"
  echo "Utilisateur DB : $DB_USER"
  echo "Mot de passe DB : $DB_PASS"
} | sudo tee "$INFO_FILE"

echo "[✓] $USER prêt. Espace web : $WEBROOT"
