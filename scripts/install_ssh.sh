#!/bin/bash

# Définir le nom d'utilisateur
ADMIN_USER="admin"

# Vérifier si l'utilisateur existe déjà
if ! id "$ADMIN_USER" &>/dev/null; then
    echo "L'utilisateur $ADMIN_USER n'existe pas. Création de l'utilisateur."
    useradd -m -s /bin/bash "$ADMIN_USER"
    # Définir un mot de passe pour l'utilisateur admin (si nécessaire, sinon ça sera désactivé pour l'auth SSH)
    echo "$ADMIN_USER:password" | chpasswd
    usermod -aG sudo "$ADMIN_USER"
else
    echo "L'utilisateur $ADMIN_USER existe déjà."
fi

# Créer la clé SSH si elle n'existe pas
if [ ! -f "/home/$ADMIN_USER/.ssh/id_rsa" ]; then
    echo "Clé SSH privée non trouvée. Génération d'une nouvelle clé SSH."
    mkdir -p /home/$ADMIN_USER/.ssh
    ssh-keygen -t rsa -b 4096 -f /home/$ADMIN_USER/.ssh/id_rsa -N ""
    chown -R $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/.ssh
else
    echo "Clé SSH privée déjà existante pour $ADMIN_USER."
fi

# Récupérer la clé publique générée et l'ajouter au fichier authorized_keys
echo "Ajout de la clé publique dans authorized_keys..."
mkdir -p /home/$ADMIN_USER/.ssh

# Utilisation de la clé publique générée pour admin
PUBLIC_KEY=$(cat /home/$ADMIN_USER/.ssh/id_rsa.pub)

# Ajouter la clé publique au fichier authorized_keys
echo "$PUBLIC_KEY" >> /home/$ADMIN_USER/.ssh/authorized_keys

# Appliquer les bonnes permissions
chmod 700 /home/$ADMIN_USER/.ssh
chmod 600 /home/$ADMIN_USER/.ssh/authorized_keys
chown -R $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/.ssh

# Configuration du SSH pour n'accepter que les connexions par clé
echo "Modification de la configuration SSH pour ne pas autoriser les mots de passe..."
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd


echo "Configuration terminée avec succès."