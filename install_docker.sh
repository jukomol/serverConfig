#!/usr/bin/env bash
set -e

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

echo "Updating system..."
apt update
apt upgrade -y

echo "Installing prerequisites..."
apt install -y ca-certificates curl gnupg lsb-release

echo "Adding Docker GPG key..."
install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
fi

echo "Adding Docker repository..."
ARCH=$(dpkg --print-architecture)
CODENAME=$(lsb_release -cs)

cat <<EOF > /etc/apt/sources.list.d/docker.list
deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $CODENAME stable
EOF

echo "Installing Docker Engine..."
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Enabling Docker service..."
systemctl enable docker
systemctl start docker

# Add invoking user to docker group
if [ -n "$SUDO_USER" ]; then
  usermod -aG docker "$SUDO_USER"
  echo "User $SUDO_USER added to docker group"
fi

echo "Verifying Docker installation..."
docker run --rm hello-world

echo "Docker installation completed successfully."
echo "Log out and log back in to use Docker without sudo."
