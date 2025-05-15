#!/bin/bash
set -e

DOMAIN="$1"

if [ -z "$DOMAIN" ]; then
  echo "❌ Usage : $0 <nom_de_domaine>"
  exit 1
fi

echo "[WEB] ➤ Installation d'Apache"
sudo dnf install -y httpd httpd-core httpd-filesystem

echo "[WEB] ➤ Installation de PHP et des modules"
sudo dnf install -y php php-cli php-common php-mysqlnd php-gd php-opcache php-mbstring php-pdo php-fpm php-json mod_php

echo "[WEB] ➤ Activation du service Apache"
sudo systemctl enable --now httpd

echo "[WEB] ➤ Configuration du pare-feu (port 80)"
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload

echo "[WEB] ➤ Création du répertoire /var/www/html (si absent)"
sudo mkdir -p /var/www/html
sudo tee /var/www/html/index.php > /dev/null <<'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>Serveur Web Apache</title>
</head>
<body>
  <h1>Bienvenue sur le serveur Apache 🐧</h1>
  <p>Ce serveur est opérationnel.</p>
  <?php
    echo "<p>PHP fonctionne correctement !</p>";
    echo "<p>Adresse IP : " . $_SERVER['SERVER_ADDR'] . "</p>";
    echo "<p>Nom d'hôte : " . $_SERVER['SERVER_NAME'] . "</p>";
    echo "<p>Nom de domaine : " . $_SERVER['HTTP_HOST'] . "</p>";
    echo "<p>Version PHP : " . phpversion() . "</p>";
    echo "<p>Heure actuelle : " . date('Y-m-d H:i:s') . "</p>";
  ?>
</body>
</html>
EOF

echo "[WEB] ➤ Droits sur /var/www/html"
sudo chown -R apache:apache /var/www/html
sudo chmod -R 755 /var/www
sudo chmod -R 755 /var/www/html
sudo chmod 644 /var/www/html/index.php

echo "[WEB] ➤ Permissions d'accès (chmod o+x sur le chemin)"
sudo chmod o+x /var
sudo chmod o+x /var/www
sudo chmod o+x /var/www/html

echo "[WEB] ➤ Vérification du bloc <Directory> dans httpd.conf"
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

echo "[WEB] ➤ Création du VirtualHost pour $DOMAIN"
sudo tee /etc/httpd/conf.d/000-default.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    DocumentRoot /var/www/html

    <Directory /var/www/html>
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
EOF

echo "[WEB] ➤ Redémarrage final d'Apache"
sudo systemctl restart httpd

echo "[WEB] ➤ Test HTTP local"
curl -sI http://localhost | grep "HTTP"

echo "[WEB] ✔️ Apache est prêt sur http://$DOMAIN"
