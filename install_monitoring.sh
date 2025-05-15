#!/bin/bash

set -e

ROLE="$1"

echo "[Monitoring] ➤ Installation de Netdata"
bash <(curl -SsL https://my-netdata.io/kickstart.sh) --dont-wait --disable-telemetry

if [[ "$ROLE" == "1" ]]; then
  echo "[Monitoring] ➤ Configuration en tant que serveur principal"

  # Ouverture du port 19999
  if command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-port=19999/tcp
    sudo firewall-cmd --reload
  fi

  # Configuration de netdata.conf
  sudo sed -i '/^\\[web\\]/,/^\\[/ s/^#* *allow connections from.*/  allow connections from = */' /etc/netdata/netdata.conf || true
  sudo sed -i '/^\\[web\\]/,/^\\[/ s/^#* *allow dashboard from.*/  allow dashboard from = */' /etc/netdata/netdata.conf || true

  sudo sed -i '/^\\[stream\\]/,/^\\[/ s/^#* *enabled.*/  enabled = yes/' /etc/netdata/netdata.conf || true
  sudo sed -i '/^\\[stream\\]/,/^\\[/ s/^#* *default history.*/  default history = 3600/' /etc/netdata/netdata.conf || true
  sudo sed -i '/^\\[stream\\]/,/^\\[/ s/^#* *allow from.*/  allow from = */' /etc/netdata/netdata.conf || true

  sudo systemctl enable --now netdata
  sudo systemctl restart netdata

  IP=$(hostname -I | awk '{print $1}')
  echo "[✅] Serveur principal Netdata actif : http://$IP:19999"

elif [[ "$ROLE" == "2" ]]; then
  # read -p "💡 IP du serveur principal (main) : " parent_ip
  while true; do
    read -p "[Monitoring] ➤ 💡 IP du serveur principal (main) : " parent_ip
    if [[ "$parent_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      break
    else
      echo "❌ Adresse IP invalide. Veuillez réessayer."
    fi
  done

  echo "[Monitoring] ➤ Configuration client pour streamer vers $parent_ip"

  sudo sed -i '/^\\[stream\\]/,/^\\[/ s/^#* *enabled.*/  enabled = yes/' /etc/netdata/netdata.conf || true

  # Ajout ou remplacement de la ligne destination
  if grep -q "^ *destination" /etc/netdata/netdata.conf; then
    sudo sed -i "s|^ *destination.*|  destination = $parent_ip:19999|" /etc/netdata/netdata.conf
  else
    echo "  destination = $parent_ip:19999" | sudo tee -a /etc/netdata/netdata.conf
  fi

  if grep -q "^ *api key" /etc/netdata/netdata.conf; then
    sudo sed -i "s|^ *api key.*|  api key = auto|" /etc/netdata/netdata.conf
  else
    echo "  api key = auto" | sudo tee -a /etc/netdata/netdata.conf
  fi

  sudo systemctl enable --now netdata
  sudo systemctl restart netdata

  echo "[✅] Ce serveur envoie maintenant ses stats à : http://$parent_ip:19999"

else
  echo "❌ Choix invalide. Annulation."
  exit 1
fi
