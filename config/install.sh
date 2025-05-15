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
sudo chmod +x /opt/ProjetLinux/*.sh

echo "[CONFIG] ➤ Lancement du menu principal"
cd /opt/ProjetLinux

sudo /opt/ProjetLinux/master_install.sh
