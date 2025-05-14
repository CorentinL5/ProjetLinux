#!/bin/bash

# Usage : ./create_user.sh <username> <password> <ip>
# Ex: ./create_user.sh client42 superpass 10.42.0.94

if [ $# -ne 3 ]; then
  echo "Usage: $0 <username> <password> <ip>"
  exit 1
fi

USER="$1"
PASS="$2"
IP="$3"
DOMAIN="$USER.projet.heh"
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

echo "[+] Création des dossiers"
sudo mkdir -p "$WEBROOT"
sudo mkdir -p "$USERROOT/data"
sudo chown -R $USER:$USER "$USERROOT"

# 2. Appliquer quota utilisateur : 25 Mo (blocs 1K)
echo "[+] Application du quota de 25 Mo"
if mount | grep -q '/srv/clients'; then
  sudo setquota -u $USER 25600 25600 0 0 /srv/clients || echo "[!] Échec quota : quota peut ne pas être activé"
else
  echo "[!] Avertissement : /srv/clients n'est pas monté avec quotas. (Quota non appliqué)"
fi

# 3. Web (Apache)
echo "[+] Configuration Apache"
echo "<h1>Bienvenue $USER</h1>" | sudo tee "$WEBROOT/index.html" > /dev/null
sudo chown -R apache:apache "$WEBROOT"
sudo tee /etc/httpd/conf.d/$USER.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    DocumentRoot $WEBROOT
    <Directory $WEBROOT>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
sudo systemctl reload httpd

# 4. FTP
echo "[+] Préparation FTP"
echo "$USER" | sudo tee -a /etc/vsftpd/user_list > /dev/null
sudo chown $USER:$USER "$WEBROOT"

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
(echo "$PASS"; echo "$PASS") | sudo smbpasswd -a $USER
sudo smbpasswd -e $USER
sudo systemctl restart smb nmb

# 6. DNS (manuel)
echo "[!] À ajouter dans la zone DNS :"
echo "$USER IN A $IP"

# 7. MariaDB/MySQL
echo "[+] Création base de données"
sudo mysql -e "CREATE DATABASE $DB_NAME;"
sudo mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
sudo mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# 8. Fichier de sortie
INFO_FILE="$USERROOT/your_account.txt"
echo "Nom d'utilisateur : $USER" | sudo tee "$INFO_FILE"
echo "Mot de passe FTP/Samba : $PASS" | sudo tee -a "$INFO_FILE"
echo "Web : http://$DOMAIN" | sudo tee -a "$INFO_FILE"
echo "FTP : ftp://$IP" | sudo tee -a "$INFO_FILE"
echo "Samba : \\\\$IP\\$USER" | sudo tee -a "$INFO_FILE"
echo "Base de données : $DB_NAME" | sudo tee -a "$INFO_FILE"
echo "Utilisateur DB : $DB_USER" | sudo tee -a "$INFO_FILE"
echo "Mot de passe DB : $DB_PASS" | sudo tee -a "$INFO_FILE"

echo "[✓] $USER prêt. Espace web : $WEBROOT"
