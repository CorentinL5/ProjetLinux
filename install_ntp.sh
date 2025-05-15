#!/bin/bash

set -e

echo "[NTP] Installation du serveur NTP (chronyd)"
sudo yum install -y chrony

echo "[NTP] Activation et démarrage du service"
sudo systemctl enable --now chronyd

echo "[NTP] Configuration du serveur pour fournir l'heure aux autres machines"
sudo sed -i 's|^#allow.*|allow 10.42.0.0/16|' /etc/chrony.conf

echo "[NTP] Redémarrage du service chronyd"
sudo systemctl restart chronyd

echo "[NTP] ✔️ Serveur NTP prêt à synchroniser les clients du réseau local"
