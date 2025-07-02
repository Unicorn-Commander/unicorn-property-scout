#!/bin/bash
set -e

echo "🧭 Installing Portainer CE (Community Edition)..."

# Create volume for persistent data
docker volume create portainer_data

# Run the Portainer container
docker run -d \
  --name portainer \
  --restart=always \
  -p 9000:9000 \
  -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

echo "✅ Portainer is up and running!"

echo "🔗 Access it at: http://<your-server-ip>:9000 or https://<your-server-ip>:9443"
echo "🛡️ First time? You'll be prompted to create an admin user."
