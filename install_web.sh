#!/bin/bash

set -e



DOMAIN="$1"

echo "[WEB] ➤ Installation d'Apache"
sudo dnf install -y httpd

echo "[WEB] ➤ Installation de PHP et du module Apache"
sudo dnf install -y php php-cli php-common php-mysqlnd php-gd php-opcache php-mbstring php-pdo php-fpm php-json mod_php

echo "[WEB] ➤ Activation du service Apache"
sudo systemctl enable --now httpd

echo "[WEB] ➤ Configuration du pare-feu (port 80)"
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload

echo "[WEB] ➤ Création de la page d'accueil"
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


echo "[WEB] ➤ Création du VirtualHost pour $DOMAIN (prioritaire)"
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

echo "[WEB] ➤ Redémarrage d'Apache"
sudo systemctl restart httpd

echo "[WEB] ✔️ Apache prêt avec VirtualHost http://$DOMAIN (vers /var/www/html)"
