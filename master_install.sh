#!/bin/bash

set -e

echo "=== [1] Installation DNS ==="
bash install_dns.sh

echo "=== [2] Installation Serveur Web ==="
bash install_web.sh

echo "=== [3] Installation FTP ==="
bash install_ftp.sh

echo "=== [4] Installation Samba ==="
bash install_samba.sh

echo "=== [5] Installation MariaDB ==="
bash install_mariadb.sh

echo "=== [6] Installation NTP ==="
bash install_ntp.sh

echo "=== [7] Installation Monitoring ==="
bash install_monitoring.sh

echo "=== ✔️ Tous les services sont installés ==="
