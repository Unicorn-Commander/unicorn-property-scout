#!/bin/bash
# This script will fix the SearXNG container health check issue

# First, let's check the current health check configuration
echo "Checking current Docker health check configuration..."

if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    echo "Error: Neither docker-compose nor docker compose is available"
    exit 1
fi

# Get the container ID for SearXNG
CONTAINER_ID=$($DOCKER_COMPOSE ps -q unicorn-searxng)
if [ -z "$CONTAINER_ID" ]; then
    echo "Error: Could not find SearXNG container"
    exit 1
fi

echo "SearXNG container ID: $CONTAINER_ID"

# Check current health check
echo "Current health check configuration:"
docker inspect --format='{{json .Config.Healthcheck}}' $CONTAINER_ID | python3 -m json.tool

# Let's also check the container logs for health check failures
echo -e "\nChecking health check logs:"
docker inspect --format='{{json .State.Health}}' $CONTAINER_ID | python3 -m json.tool

# Now let's modify the docker-compose.yml file to update the health check
COMPOSE_FILE="docker-compose.yml"
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Error: docker-compose.yml file not found"
    echo "Please enter the path to your docker-compose.yml file:"
    read COMPOSE_FILE
    if [ ! -f "$COMPOSE_FILE" ]; then
        echo "Error: Could not find docker-compose.yml file at $COMPOSE_FILE"
        exit 1
    fi
fi

# Create a backup of the docker-compose.yml file
cp "$COMPOSE_FILE" "${COMPOSE_FILE}.bak"
echo "Created backup of docker-compose.yml at ${COMPOSE_FILE}.bak"

# Option 1: Modify the health check in docker-compose.yml
echo -e "\nUpdating health check in $COMPOSE_FILE..."
echo "Choose a health check fix option:"
echo "1) Check web page without expecting specific content"
echo "2) Increase start period and retries"
echo "3) Disable health check (not recommended for production)"
read -p "Enter option (1-3): " OPTION

case $OPTION in
    1)
        # Update docker-compose.yml to use a simpler health check
        # This is tricky to do with sed, so we'll give instructions
        echo -e "\nInstructions to update your docker-compose.yml file:"
        echo "Find the 'unicorn-searxng' service section and update the healthcheck to:"
        echo "healthcheck:"
        echo "  test: [\"CMD\", \"wget\", \"-q\", \"--spider\", \"http://localhost:8080/\"]"
        echo "  interval: 30s"
        echo "  timeout: 10s"
        echo "  retries: 3"
        echo "  start_period: 30s"
        ;;
    2)
        # Update docker-compose.yml to increase start period and retries
        echo -e "\nInstructions to update your docker-compose.yml file:"
        echo "Find the 'unicorn-searxng' service section and update the healthcheck to:"
        echo "healthcheck:"
        echo "  test: [\"CMD\", \"wget\", \"-q\", \"--spider\", \"http://localhost:8080/\"]"
        echo "  interval: 30s"
        echo "  timeout: 10s"
        echo "  retries: 5"
        echo "  start_period: 60s"
        ;;
    3)
        # Update docker-compose.yml to disable health check
        echo -e "\nInstructions to update your docker-compose.yml file:"
        echo "Find the 'unicorn-searxng' service section and add:"
        echo "healthcheck:"
        echo "  disable: true"
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

# Instructions to restart the container
echo -e "\nAfter updating the docker-compose.yml file, restart the containers with:"
echo "$DOCKER_COMPOSE up -d"

# Option 2: Create a custom health check script
echo -e "\nAlternatively, you can create a custom health check script:"
cat << 'EOF' > custom-healthcheck.sh
#!/bin/bash
# Custom health check for SearXNG
# Place this inside the container or mount it as a volume

# Simple check: just verify the process is listening on the port
if netstat -tuln | grep -q ":8080"; then
  echo "SearXNG is listening on port 8080"
  exit 0
else
  echo "SearXNG is not listening on port 8080"
  exit 1
fi
EOF

chmod +x custom-healthcheck.sh
echo "Created custom-healthcheck.sh - you can use this in your Docker configuration"

echo -e "\nIf you're still seeing issues, you might want to check if there's a port conflict:"
echo "$DOCKER_COMPOSE ps"
