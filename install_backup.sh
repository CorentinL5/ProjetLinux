#!/bin/bash
set -e

echo "📦 Installation du système de sauvegarde"

# 1. Choix local ou distant
read -rp "Souhaites-tu utiliser un serveur NFS distant pour stocker les backups ? (y/n) : " NFS_CHOICE

if [[ "$NFS_CHOICE" == "y" ]]; then
  read -rp "➡️  IP du serveur NFS : " NFS_IP
  NFS_PATH="/srv/nfs/backup"

  echo "[+] Montage du dossier NFS distant sur /backup"
  sudo mkdir -p /backup
  echo "${NFS_IP}:${NFS_PATH} /backup nfs defaults,_netdev 0 0" | sudo tee -a /etc/fstab
  sudo mount -a
else
  echo "[+] Utilisation locale de /backup"
  sudo mkdir -p /backup
fi

# 2. Création des répertoires
echo "[+] Préparation de la structure /backup"
sudo mkdir -p /backup/{daily,weekly,monthly}

# 3. Script principal
cat <<'EOF' | sudo tee /root/backup.sh > /dev/null
#!/bin/bash
set -e

TODAY=$(date +%F)
DAY=$(date +%u)
MONTH_DAY=$(date +%d)

DAILY="/backup/daily/$TODAY"
WEEKLY="/backup/weekly/week_$DAY"
MONTHLY="/backup/monthly/month_$MONTH_DAY"

MYSQL_PWD=$(cat /root/.mariadb_root_pass)

# ➤ Sauvegarde quotidienne
mkdir -p "$DAILY/clients" "$DAILY/db"
rsync -a --delete /srv/clients/ "$DAILY/clients/"

for db in $(mysql -uroot -p"$MYSQL_PWD" -e "SHOW DATABASES;" | grep -Ev "Database|information_schema|mysql|performance_schema|sys"); do
  mysqldump -uroot -p"$MYSQL_PWD" "$db" > "$DAILY/db/$db.sql"
done

# ➤ Sauvegarde hebdo (dimanche)
if [[ "$DAY" == "7" ]]; then
  mkdir -p "$WEEKLY/configs"
  cp -r /etc/httpd /etc/vsftpd /etc/samba /etc/named* /etc/chrony.conf "$WEEKLY/configs/" 2>/dev/null || true
fi

# ➤ Sauvegarde mensuelle (1er jour)
if [[ "$MONTH_DAY" == "01" ]]; then
  mkdir -p "$MONTHLY"
  dd if=/dev/vg_clients/lv_clients of="$MONTHLY/lv_clients_backup.img" bs=1M status=progress
fi

# ➤ Rotation
find /backup/daily/ -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \;
find /backup/weekly/ -mindepth 1 -maxdepth 1 -type d -mtime +30 -exec rm -rf {} \;
find /backup/monthly/ -mindepth 1 -maxdepth 1 -type d -mtime +180 -exec rm -rf {} \;

echo "[✓] Sauvegarde complète terminée à $(date)"
EOF

sudo chmod +x /root/backup.sh

# 4. Cron automatique à 2h
( crontab -l 2>/dev/null; echo "0 2 * * * /root/backup.sh >> /var/log/backup.log 2>&1" ) | crontab -

echo "✅ Script de sauvegarde installé avec succès"
[[ "$NFS_CHOICE" == "y" ]] && echo "🌐 Backup via NFS : monté depuis $NFS_IP:$NFS_PATH"
echo "🕒 Lancement automatique quotidien à 2h"
