#!/bin/bash
set -e

cd "$(dirname "$0")"

# Demande une fois l'IP du serveur
read -p "🔧 IP de ce serveur (ex: 10.42.0.52) : " SERVEUR_IP
read -p "🌐 Nom de domaine (ex: projet.heh) : " DOMAIN
read -p "🗝️ serveur de backup ? (oui/non) : " BACKUP_SERVER
while [[ "$BACKUP_SERVER" != "oui" && "$BACKUP_SERVER" != "non" ]]; do
  read -p "??️ serveur de backup ? (oui/non) : " BACKUP_SERVER
done

SHARE_PATH="/srv/nfs/share"
ROLE="2" # Par défaut, on considère que c'est un client
# Si c'est un serveur de backup, on change le chemin de partage
if [[ "$BACKUP_SERVER" == "oui" ]]; then
  SHARE_PATH="/srv/nfs/backup"
  ROLE="1" # On considère que c'est le serveur principal
fi

export SERVEUR_IP
export DOMAIN
export BACKUP_SERVER
export SHARE_PATH


main_menu() {
  while true; do
    clear
    echo "========== 🌐 MASTER CONFIG MENU =========="
    echo "1) ⚡ Installation complète (tout configurer)"
    echo "2) 🔧 Installation manuelle (par service)"
    echo "3) 👤 Gestion des utilisateurs clients"
    echo "q) ❌ Quitter"
    echo "=========================================="
    read -p "Choix : " main_choice

    case $main_choice in
      1) full_setup ;;
      2) service_menu ;;
      3) user_menu ;;
      q|Q) echo "👋 À bientôt !"; exit 0 ;;
      *) echo "Choix invalide. Entrée pour continuer..."; read ;;
    esac
  done
}

full_setup() {
  echo "[SETUP COMPLET] ➤ Lancement de toutes les installations..."
  bash install_lvm.sh
  bash install_fw.sh
  bash install_web.sh
  bash install_mariadb.sh
  bash install_dns.sh "$SERVEUR_IP" "$DOMAIN"
  bash install_ntp.sh
  bash install_nfs.sh "$SHARE_PATH"
  bash install_samba.sh "$SHARE_PATH"
  bash install_ftp.sh
  bash fix_vsftpd.sh
  bash fix_web.sh
  bash install_monitoring.sh "$ROLE"
  bash install_crontab.sh
  bash install_backup.sh
  bash install_phpmyadmin.sh
  bash install_antivirus.sh
  echo "[SETUP COMPLET] ✔️ Terminé"
  read -p "Appuyez sur Entrée pour revenir au menu..."
}

service_menu() {
  while true; do
    clear
    echo "===== 🔧 INSTALLATION MANUELLE PAR SERVICE ====="
    echo "1) LVM et quotas"
    echo "2) Firewall"
    echo "3) Apache + PHP"
    echo "4) MariaDB"
    echo "5) DNS"
    echo "6) NTP"
    echo "7) NFS"
    echo "8) Samba"
    echo "9) vsftpd"
    echo "10) Corriger vsftpd"
    echo "11) Corriger Apache"
    echo "12) Monitoring (Netdata)"
    echo "13) Cron"
    echo "14) Backup"
    echo "15) phpMyAdmin"
    echo "16) Antivirus"
    echo "q) Retour"
    echo "==============================================="
    read -p "Choix : " s

    case $s in
      1) bash install_lvm.sh ;;
      2) bash install_fw.sh ;;
      3) bash install_web.sh ;;
      4) bash install_mariadb.sh ;;
      5) bash install_dns.sh "$SERVEUR_IP" "$DOMAIN" ;;
      6) bash install_ntp.sh ;;
      7) bash install_nfs.sh "$SHARE_PATH" ;;
      8) bash install_samba.sh "$SHARE_PATH" ;;
      9) bash install_ftp.sh ;;
      10) bash fix_vsftpd.sh ;;
      11) bash fix_web.sh ;;
      12) bash install_monitoring.sh "$ROLE" ;;
      13) bash install_crontab.sh ;;
      14) bash install_backup.sh ;;
      15) bash install_phpmyadmin.sh ;;
      16) bash install_antivirus.sh ;;
      q|Q) break ;;
      *) echo "Choix invalide. Entrée pour continuer..."; read ;;
    esac
  done
}

user_menu() {
  while true; do
    clear
    echo "===== 👤 GESTION UTILISATEURS CLIENTS ====="
    echo "1) ➕ Créer un utilisateur"
    echo "2) ➖ Supprimer un utilisateur"
    echo "3) 📄 Lister les utilisateurs"
    echo "q) Retour"
    echo "=========================================="
    read -p "Choix : " u

    case $u in
      1)
        read -p "Nom utilisateur : " user
        read -p "Mot de passe : " pass
        bash create_user.sh "$user" "$pass" "$SERVEUR_IP" "$DOMAIN"
        ;;
      2)
        read -p "Nom utilisateur à supprimer : " user
        bash delete_user.sh "$user"
        ;;
      3) bash list_users.sh ;;
      q|Q) break ;;
      *) echo "Choix invalide. Entrée pour continuer..."; read ;;
    esac
  done
}

# Lancer le menu principal
main_menu
