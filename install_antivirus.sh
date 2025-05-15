#!/bin/bash

set -e
echo "[ANTIVIRUS] ➤ Installation de ClamAV (antivirus open source)"
sudo dnf install -y clamav clamav-update

echo "[ANTIVIRUS] ➤ Mise à jour de la base de définitions"
sudo freshclam

echo "[ANTIVIRUS] ➤ Scan de test du dossier /home"
sudo clamscan -r /home

echo "[ANTIVIRUS] ✅ Antivirus installé et prêt à l'emploi"
