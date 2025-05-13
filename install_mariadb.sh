#!/bin/bash

set -e

echo "[MariaDB] Vérification de la présence de MariaDB 10.11..."

if ! rpm -q mariadb1011-server > /dev/null 2>&1; then
  echo "[MariaDB] MariaDB 10.11 non installée. Installation..."
  sudo yum install -y mariadb1011-server mariadb1011
else
  echo "[MariaDB] ✔️ MariaDB 10.11 est déjà installée"
fi

echo "[MariaDB] Activation et démarrage du service"
sudo systemctl enable --now mariadb

echo "[MariaDB] Attente du lancement complet"
sleep 1
until sudo mariadb -e "SELECT 1;" &>/dev/null; do
  echo "[MariaDB] En attente du service..."
  sleep 1
done

echo "[MariaDB] Sécurisation automatique..."

# Supprimer les utilisateurs anonymes
sudo mariadb -e "DELETE FROM mysql.user WHERE User='';"

# Supprimer les accès root distants
sudo mariadb -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"

# Supprimer la base de test
sudo mariadb -e "DROP DATABASE IF EXISTS test;"
sudo mariadb -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"

# Appliquer les changements
sudo mariadb -e "FLUSH PRIVILEGES;"

# Définir un mot de passe root (généré automatiquement)
ROOTPWD=$(openssl rand -base64 16)
sudo mariadb -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOTPWD}';"

# Sauvegarder le mot de passe root dans un fichier root-only
echo "$ROOTPWD" | sudo tee /root/.mariadb_root_pass > /dev/null
sudo chmod 600 /root/.mariadb_root_pass

echo "[MariaDB] ✔️ MariaDB 10.11 est sécurisé"
echo "[MariaDB] 🔐 Mot de passe root enregistré dans /root/.mariadb_root_pass"
