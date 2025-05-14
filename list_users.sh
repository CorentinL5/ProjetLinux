#!/bin/bash

# list_users.sh
# Affiche les utilisateurs présents dans /srv/clients avec leur quota disque et base MySQL

set -e

echo "🧾 Liste des utilisateurs dans /srv/clients :"
echo "------------------------------------------"

for USERDIR in /srv/clients/*; do
    if [ -d "$USERDIR" ]; then
        USER=$(basename "$USERDIR")
        echo "👤 Utilisateur : $USER"

        # Quota (en blocs 1K) converti en Mo
        quota_output=$(sudo quota -u "$USER" /srv/clients | awk 'NR==4 {print $2}')
        if [[ "$quota_output" =~ ^[0-9]+$ ]]; then
            quota_mb=$((quota_output / 1024))
            echo "📦 Quota utilisé : $quota_mb Mo"
        else
            echo "📦 Quota utilisé : (non disponible)"
        fi

        # Base de données
        DB_NAME="${USER}_db"
        echo "🛢️ Base de données : $DB_NAME"

        echo "------------------------------------------"
    fi
done
