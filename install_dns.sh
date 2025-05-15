#!/bin/bash

# Script d'installation et configuration d'un serveur DNS local (BIND) pour Amazon Linux 2023

set -e

DNS_IP="$1"
DOMAIN="$2"
REVERSE_ZONE="52.0.42.10.in-addr.arpa"

# Vérification root
if [ "$(id -u)" -ne 0 ]; then
  echo "Ce script doit être lancé en tant que root"
  exit 1
fi

echo "[DNS] ➤ Mise à jour et installation de BIND"
dnf install -y bind bind-utils

echo "[DNS] ➤ Configuration de /etc/named.conf"
cat > /etc/named.conf <<EOF
options {
    listen-on port 53 { 127.0.0.1; ${DNS_IP}; };
    listen-on-v6 port 53 { ::1; };
    directory "/var/named";
    dump-file "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    secroots-file "/var/named/data/named.secroots";
    recursing-file "/var/named/data/named.recursing";
    allow-query { localhost; 10.42.0.0/24; };
    recursion yes;
    dnssec-validation auto;
    managed-keys-directory "/var/named/dynamic";
    include "/etc/crypto-policies/back-ends/bind.config";
};

logging {
    channel default_debug {
        file "data/named.run";
        severity dynamic;
    };
};

zone "." IN {
    type hint;
    file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

zone "${DOMAIN}" IN {
    type master;
    file "forward.${DOMAIN}";
    allow-update { none; };
};

zone "${REVERSE_ZONE}" IN {
    type master;
    file "reverse.${DOMAIN}";
    allow-update { none; };
};
EOF

echo "[DNS] ➤ Création de /var/named/forward.${DOMAIN}"
cat > /var/named/forward.${DOMAIN} <<EOF
\$TTL 86400
@   IN  SOA     ns1.${DOMAIN}. admin.${DOMAIN}. (
        2023051301  ; Serial
        3600        ; Refresh
        1800        ; Retry
        604800      ; Expire
        86400       ; Minimum TTL
)
@       IN  NS      ns1.${DOMAIN}.
@       IN  A       ${DNS_IP}
ns1     IN  A       ${DNS_IP}
EOF

echo "[DNS] ➤ Création de /var/named/reverse.${DOMAIN}"
PTR_LAST_OCTET=$(echo "$DNS_IP" | awk -F. '{print $4}')
cat > /var/named/reverse.${DOMAIN} <<EOF
\$TTL 86400
@   IN  SOA     ns1.${DOMAIN}. admin.${DOMAIN}. (
        2023051301
        3600
        1800
        604800
        86400
)
@       IN  NS      ns1.${DOMAIN}.
${PTR_LAST_OCTET} IN  PTR     ns1.${DOMAIN}.
EOF

chown named:named /var/named/forward.${DOMAIN}
chown named:named /var/named/reverse.${DOMAIN}

echo "[DNS] ➤ Firewall : ouverture du port 53"
firewall-cmd --permanent --add-port=53/udp
firewall-cmd --permanent --add-port=53/tcp
firewall-cmd --reload

echo "[DNS] ➤ Activation et démarrage de named"
systemctl enable --now named

echo "[DNS] ➤ Vérification des fichiers de zone"
named-checkconf
named-checkzone "${DOMAIN}" /var/named/forward.${DOMAIN}
named-checkzone "${REVERSE_ZONE}" /var/named/reverse.${DOMAIN}

echo "[DNS] ➤ Test dig"
dig @127.0.0.1 ns1.${DOMAIN}
dig @127.0.0.1 -x ${DNS_IP}

# Optionnel : résolv.conf local
if ! grep -q "${DOMAIN}" /etc/resolv.conf; then
  echo "[DNS] ➤ Configuration de /etc/resolv.conf"
  cp /etc/resolv.conf /etc/resolv.conf.bak
  cat > /etc/resolv.conf <<EOF
nameserver 127.0.0.1
search ${DOMAIN}
EOF
  chattr +i /etc/resolv.conf
fi

echo "[✓] DNS serveur ${DOMAIN} prêt sur ${DNS_IP}"
