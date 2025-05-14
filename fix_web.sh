#!/bin/bash

# Script de correction complète de l'accès Web Apache sur Amazon Linux

set -e

echo "[WEB-FIX] ➤ Redémarrage du service Apache"
sudo systemctl restart httpd || true

echo "[WEB-FIX] ➤ Vérification des fichiers racine /var/www/html"
sudo mkdir -p /var/www/html
echo "<h1>Apache fonctionne ✅</h1>" | sudo tee /var/www/html/index.html > /dev/null
sudo chown -R apache:apache /var/www/html
sudo chmod -R 755 /var/www
sudo chmod -R 755 /var/www/html
sudo chmod 644 /var/www/html/index.html

echo "[WEB-FIX] ➤ Vérification du bloc <Directory>"
CONF="/etc/httpd/conf/httpd.conf"
if ! grep -q '<Directory "/var/www/html">' $CONF; then
  echo "[!] Bloc <Directory /var/www/html> manquant. Ajout..."
  sudo tee -a $CONF > /dev/null <<EOF

<Directory "/var/www/html">
    AllowOverride None
    Require all granted
</Directory>
EOF
fi

echo "[WEB-FIX] ➤ Vérification permissions d'accès du chemin"
sudo chmod o+x /var
sudo chmod o+x /var/www
sudo chmod o+x /var/www/html

echo "[WEB-FIX] ➤ Vérification pare-feu (port 80)"
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload

echo "[WEB-FIX] ➤ Redémarrage final"
sudo systemctl restart httpd

echo "[WEB-FIX] ✅ Vérification de l'état"
curl -sI http://localhost | grep "HTTP"

echo "[WEB-FIX] ✔️ Apache est fonctionnel sur http://<ip>"
