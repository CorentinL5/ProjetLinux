#!/bin/bash

set -e

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
  bash install_dns.sh
  bash install_ntp.sh
  bash install_nfs.sh
  bash install_samba.sh
  bash install_ftp.sh
  bash fix_vsftpd.sh
  bash fix_web.sh
  bash install_monitoring.sh
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
    echo "q) Retour"
    echo "==============================================="
    read -p "Choix : " s

    case $s in
      1) bash install_lvm.sh ;;
      2) bash install_fw.sh ;;
      3) bash install_web.sh ;;
      4) bash install_mariadb.sh ;;
      5) bash install_dns.sh ;;
      6) bash install_ntp.sh ;;
      7) bash install_nfs.sh ;;
      8) bash install_samba.sh ;;
      9) bash install_ftp.sh ;;
      10) bash fix_vsftpd.sh ;;
      11) bash fix_web.sh ;;
      12) bash install_monitoring.sh ;;
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
        read -p "Adresse IP : " ip
        bash create_user.sh "$user" "$pass" "$ip"
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
