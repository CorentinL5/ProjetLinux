#!/bin/bash
set -e

echo "[PHPMyAdmin] ➤ Installation manuelle de phpMyAdmin"

VERSION="5.2.1"
PHPMYADMIN_DIR="/usr/share/phpMyAdmin"
CONF_FILE="$PHPMYADMIN_DIR/config.inc.php"

# Installer les dépendances PHP + Apache
sudo dnf install -y php php-mbstring php-mysqlnd php-json php-common httpd unzip wget

# Télécharger phpMyAdmin depuis le site officiel
cd /tmp
wget https://files.phpmyadmin.net/phpMyAdmin/${VERSION}/phpMyAdmin-${VERSION}-all-languages.zip

# Extraire et déplacer
sudo unzip -q phpMyAdmin-${VERSION}-all-languages.zip -d /usr/share/
sudo mv /usr/share/phpMyAdmin-${VERSION}-all-languages "$PHPMYADMIN_DIR"

# Config phpMyAdmin
sudo cp "$PHPMYADMIN_DIR/config.sample.inc.php" "$CONF_FILE"
sudo sed -i "s/\$cfg\['blowfish_secret'\] = '';/\$cfg['blowfish_secret'] = '$(openssl rand -hex 16)';/" "$CONF_FILE"

# 🔒 Interdiction du root via interface
echo "\$cfg['Servers'][\$i]['AllowRoot'] = false;" | sudo tee -a "$CONF_FILE" > /dev/null

# Lien Apache
echo "[PHPMyAdmin] ➤ Création de l'accès Apache /phpmyadmin"
sudo ln -s "$PHPMYADMIN_DIR" /var/www/html/phpmyadmin

# Droits
sudo chown -R apache:apache "$PHPMYADMIN_DIR"
sudo chmod -R 755 "$PHPMYADMIN_DIR"

# Pare-feu
echo "[PHPMyAdmin] ➤ Ouverture du port HTTP (80)"
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload

# Apache
sudo systemctl enable --now httpd
sudo systemctl restart httpd

echo "✅ PHPMyAdmin installé et sécurisé"
echo "🌐 Accès : http://<ip>/phpmyadmin (sans root)"
