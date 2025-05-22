#!/bin/bash
set -e

echo "[CONFIG] ➤ Installation de Git (si absent)"
if ! command -v git &>/dev/null; then
  sudo dnf install -y git
fi

echo "[CONFIG] ➤ Clonage du dépôt ProjetLinux"
sudo rm -rf /opt/ProjetLinux
sudo git clone https://github.com/CorentinL5/ProjetLinux.git /opt/ProjetLinux

echo "[CONFIG] ➤ Mise en exécution des scripts"
sudo chmod +x /opt/ProjetLinux/scripts/*.sh

echo "[CONFIG] ➤ Lancement du menu principal"
cd /opt/ProjetLinux/scripts/

sudo /opt/ProjetLinux/scripts/master_install.sh
