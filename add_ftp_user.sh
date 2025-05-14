#!/bin/bash

set -e

# Vérifie les arguments
if [ $# -ne 2 ]; then
    echo "Usage : $0 <nom_utilisateur> <mot_de_passe>"
    exit 1
fi

CLIENT="$1"
PASS="$2"
DIR="/srv/www/$CLIENT"

echo "[FTP] ➤ Création de l'utilisateur : $CLIENT"
sudo useradd -d "$DIR" -s /sbin/nologin "$CLIENT" || echo "[INFO] Utilisateur déjà existant"

echo "[FTP] ➤ Définition du mot de passe"
echo "$CLIENT:$PASS" | sudo chpasswd

echo "[FTP] ➤ Ajout à /etc/vsftpd/user_list (si absent)"
grep -qxF "$CLIENT" /etc/vsftpd/user_list || echo "$CLIENT" | sudo tee -a /etc/vsftpd/user_list > /dev/null

echo "[FTP] ➤ Création du dossier : $DIR"
sudo mkdir -p "$DIR"
sudo chown "$CLIENT:$CLIENT" "$DIR"
sudo chmod 755 "$DIR"

echo "<h1>Bienvenue $CLIENT</h1>" | sudo tee "$DIR/index.html" > /dev/null

echo "[FTP] ✔️ Utilisateur créé avec succès"
echo "    ➤ Nom     : $CLIENT"
echo "    ➤ Mot de passe : $PASS"
echo "    ➤ Dossier : $DIR"
echo "    ➤ Accès FTP : ftp://<IP>:21 (FileZilla ou explorateur FTP)"
