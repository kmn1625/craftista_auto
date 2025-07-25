#!/bin/bash
set -e

echo "[INFO] Installing Docker..."

# Remove any old versions
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

# Update system
sudo apt-get update -y

# Install prerequisites
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repo if not added
if ! grep -q "download.docker.com" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
fi

# Install Docker
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add user to docker group
sudo usermod -aG docker $USER

echo "[INFO] Docker installation completed!"
