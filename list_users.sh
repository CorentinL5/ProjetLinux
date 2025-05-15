#!/bin/bash

# list_users.sh
# Liste les utilisateurs avec quota, DB, dossier et fichier your_account.txt

set -e

echo "🧾 Liste des utilisateurs dans /srv/clients :"
echo "------------------------------------------"

for USERDIR in /srv/clients/*; do
    if [ -d "$USERDIR" ]; then
        USER=$(basename "$USERDIR")

        # Ignore les dossiers système ou cachés
        if [[ "$USER" == "lost+found" || "$USER" == .* ]]; then
            continue
        fi

        echo "👤 Utilisateur : $USER"

        # Quota disque (utilisé / alloué)
        quota_line=$(sudo quota -u "$USER" | awk 'NR==4')
        used_blocks=$(echo "$quota_line" | awk '{print $1}')
        soft_limit=$(echo "$quota_line" | awk '{print $2}')

        if [[ "$used_blocks" =~ ^[0-9]+$ && "$soft_limit" =~ ^[0-9]+$ ]]; then
            used_mb=$((used_blocks / 1024))
            soft_mb=$((soft_limit / 1024))
            echo "📦 Quota : $used_mb Mo utilisés sur $soft_mb Mo alloués"
        else
            echo "📦 Quota : (non disponible)"
        fi

        # Base de données
        DB_NAME="${USER}_db"
        echo "🛢️ Base de données : $DB_NAME"

        # Dossier
        echo "📁 Dossier : $USERDIR"

        # Fichier your_account.txt
        INFO_FILE="$USERDIR/your_account.txt"
        if [ -f "$INFO_FILE" ]; then
            echo "📄 Contenu de your_account.txt :"
            cat "$INFO_FILE" | sed 's/^/   📌 /'
        else
            echo "📄 Fichier your_account.txt : (absent)"
        fi

        echo "------------------------------------------"
    fi
done
