#!/bin/bash

set -e
echo "[DNS] Installation de BIND9"
sudo dnf install -y bind bind-utils

echo "[DNS] Configuration basique"
sudo mkdir -p /etc/named/zones

cat <<EOF | sudo tee /etc/named/zones/db.projet.local
$TTL 86400
@   IN  SOA ns.projet.local. admin.projet.local. (
    20240513    ; Serial
    3600        ; Refresh
    1800        ; Retry
    1209600     ; Expire
    86400 )     ; Minimum TTL
@       IN  NS      ns.projet.local.
ns      IN  A       10.42.0.94
client1 IN  A       10.42.0.94
EOF

cat <<EOF | sudo tee /etc/named/zones/db.0.42.10.in-addr.arpa
$TTL 86400
@   IN  SOA ns.projet.local. admin.projet.local. (
    20240513    ; Serial
    3600        ; Refresh
    1800        ; Retry
    1209600     ; Expire
    86400 )     ; Minimum TTL
@       IN  NS      ns.projet.local.
94      IN  PTR     ns.projet.local.
EOF

sudo systemctl enable --now named
echo "[DNS] ✔️ Bind9 installé et service lancé"
