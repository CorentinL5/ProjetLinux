#!/bin/bash
set -e

echo "[SELinux] ➤ Vérification de la configuration"

# Vérifie si les paquets SELinux nécessaires sont installés
if ! rpm -q policycoreutils &>/dev/null; then
  echo "[SELinux] ➤ Installation des outils nécessaires"
  sudo dnf install -y policycoreutils policycoreutils-python-utils selinux-policy selinux-policy-targeted
else
  echo "[SELinux] ✔️ Outils déjà installés"
fi

# Appliquer une configuration safe par défaut (permissive)
if ! grep -q '^SELINUX=' /etc/selinux/config; then
  echo "[SELinux] ➤ Création de /etc/selinux/config"
  sudo tee /etc/selinux/config > /dev/null <<EOF
SELINUX=permissive
SELINUXTYPE=targeted
EOF
else
  echo "[SELinux] ➤ Mise à jour vers SELINUX=permissive"
  sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
  sudo sed -i 's/^SELINUXTYPE=.*/SELINUXTYPE=targeted/' /etc/selinux/config
fi

# Vérifie l’état courant
CURRENT_STATE=$(getenforce)
if [[ "$CURRENT_STATE" == "Disabled" ]]; then
  echo "[SELinux] ⚠️ SELinux est désactivé. Un redémarrage est requis pour activer le mode permissive."
else
  echo "[SELinux] ➤ Passage immédiat en mode permissive"
  sudo setenforce 0
fi

# Affichage final
echo "[SELinux] 🔐 État actuel : $(getenforce)"
echo "[SELinux] ✅ Configuration appliquée. Pense à redémarrer si SELinux était désactivé."
