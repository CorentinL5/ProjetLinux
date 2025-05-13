#!/bin/bash

set -e

echo "[Monitoring] Installation de Netdata"
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait --disable-telemetry

echo "[Monitoring] Configuration en tant que service"
sudo systemctl enable --now netdata

echo "[Monitoring] ✔️ Netdata est disponible sur : http://<IP>:19999"
