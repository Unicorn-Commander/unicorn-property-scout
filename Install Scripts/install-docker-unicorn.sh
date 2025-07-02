#!/bin/bash
set -e

echo "🦄 Magic Unicorn Installer: Docker + Permissions for Ubuntu 25.04+"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

# Ensure required packages are installed
echo "✅ Installing prerequisites..."
sudo apt update
sudo apt install -y curl tar ca-certificates gnupg lsb-release

# Remove old Docker packages just in case
echo "🧹 Cleaning up old Docker packages..."
sudo apt remove -y docker docker-engine docker.io containerd runc || true

# Create directory and download Docker
echo "📦 Downloading Docker binaries..."
mkdir -p ~/docker-downloads && cd ~/docker-downloads
curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-25.0.3.tgz -o docker.tgz
tar xzvf docker.tgz
sudo mv docker/* /usr/bin/

# Set up systemd service
echo "⚙️ Creating Docker systemd service..."
sudo tee /etc/systemd/system/docker.service > /dev/null <<EOF
[Unit]
Description=Docker Daemon
After=network.target

[Service]
ExecStart=/usr/bin/dockerd
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

# Start Docker service
echo "🚀 Enabling and starting Docker..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl start docker

# Install Docker Compose v2
echo "🔧 Installing Docker Compose v2 plugin..."
mkdir -p ~/.docker/cli-plugins/
curl -SL https://github.com/docker/compose/releases/download/v2.24.2/docker-compose-linux-x86_64 \
  -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose

# Add user to necessary groups
echo "👤 Adding user '$USER' to required groups: docker, video, render..."
sudo groupadd docker || true
sudo usermod -aG docker,video,render $USER

echo -e "${GREEN}🎉 All set!${NC}"
echo -e "${GREEN}👉 Log out and back in OR run 'newgrp docker' to apply group changes.${NC}"
echo -e "${GREEN}🧪 Then run: 'docker run hello-world' to test.${NC}"
