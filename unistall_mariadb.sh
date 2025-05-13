#!/bin/bash

set -e

echo "[MariaDB] ➤ Arrêt du service"
sudo systemctl stop mariadb

echo "[MariaDB] ➤ Suppression des paquets"
sudo yum remove -y mariadb1011-server mariadb1011 mariadb*

echo "[MariaDB] ➤ Suppression des fichiers de base de données"
sudo rm -rf /var/lib/mysql

echo "[MariaDB] ➤ Suppression des fichiers de configuration"
sudo rm -rf /etc/my.cnf /etc/my.cnf.d /etc/mysql /root/.mariadb_root_pass

echo "[MariaDB] ✔️ MariaDB complètement désinstallé et réinitialisé"
