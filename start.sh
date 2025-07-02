#!/bin/bash
set -e

# Directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Create searxng directory if it doesn't exist
mkdir -p searxng

# Ensure .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found"
    exit 1
fi

# Load environment variables from .env file
# Using a safer method that handles quotes properly
set -a
[ -f .env ] && . ./.env
set +a

# Add or update SEARXNG_REDIS_URL in .env file if it doesn't exist or doesn't have the proper format
if ! grep -q "^SEARXNG_REDIS_URL=redis://" .env; then
    echo "Setting proper Redis URL format in .env file..."
    if grep -q "^SEARXNG_REDIS_URL=" .env; then
        sed -i "s|^SEARXNG_REDIS_URL=.*|SEARXNG_REDIS_URL=redis://unicorn-redis:6379/0|" .env
    else
        echo "SEARXNG_REDIS_URL=redis://unicorn-redis:6379/0" >> .env
    fi
    # Reload environment variables
    set -a
    [ -f .env ] && . ./.env
    set +a
fi

# Copy settings template if it doesn't exist in the searxng directory
if [ ! -f searxng/settings.yml ]; then
    echo "Copying default settings.yml template to searxng directory..."
    
    if [ -f settings.yml.template ]; then
        # Use our custom template
        cp settings.yml.template searxng/settings.yml
        
        # Replace placeholders with environment variables from .env
        sed -i "s|\${SEARXNG_SECRET}|${SEARXNG_SECRET}|g" searxng/settings.yml
        sed -i "s|\${SEARXNG_REDIS_URL}|${SEARXNG_REDIS_URL:-redis://unicorn-redis:6379/0}|g" searxng/settings.yml
        
        # Configure BrightData proxy if enabled
        if [ "${USE_ROTATING_PROXY}" = "true" ]; then
            # Ensure we have the BrightData credentials
            if [ -z "${BRIGHTDATA_USERNAME}" ] || [ -z "${BRIGHTDATA_PASSWORD}" ] || [ -z "${BRIGHTDATA_GATEWAY}" ] || [ -z "${BRIGHTDATA_PORT}" ]; then
                echo "Error: BrightData proxy is enabled but credentials are missing in .env file"
                exit 1
            fi
            
            # Replace BrightData placeholders
            sed -i "s|\${BRIGHTDATA_USERNAME}|${BRIGHTDATA_USERNAME}|g" searxng/settings.yml
            sed -i "s|\${BRIGHTDATA_PASSWORD}|${BRIGHTDATA_PASSWORD}|g" searxng/settings.yml
            sed -i "s|\${BRIGHTDATA_GATEWAY}|${BRIGHTDATA_GATEWAY}|g" searxng/settings.yml
            sed -i "s|\${BRIGHTDATA_PORT}|${BRIGHTDATA_PORT}|g" searxng/settings.yml
        else
            # Comment out the proxy configuration
            sed -i '/# Proxy Configuration/,/# Engine Configurations/s/^/#/' searxng/settings.yml
        fi
    else
        echo "Warning: No settings.yml.template found, will use container defaults"
        # The container will create a default settings.yml file
    fi
fi

# Copy uwsgi.ini if it doesn't exist in the searxng directory
if [ ! -f searxng/uwsgi.ini ]; then
    echo "Copying uwsgi.ini to searxng directory..."
    cp uwsgi.ini searxng/uwsgi.ini
fi

# Check which docker compose command is available
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    echo "Error: Neither docker-compose nor docker compose is available"
    echo "Please install Docker and Docker Compose first"
    exit 1
fi

echo "Building required services and starting Docker Compose stack..."
# Let's try a different approach - completely restart the container
echo "Attempting to restart the SearXNG container..."

# Stop and remove the container if it exists
if $DOCKER_COMPOSE ps unicorn-searxng | grep -q unicorn-searxng; then
    echo "Stopping and removing existing SearXNG container..."
    $DOCKER_COMPOSE stop unicorn-searxng
    $DOCKER_COMPOSE rm -f unicorn-searxng
fi

# Generate a random secret key if not already set in .env
if [ -z "${SEARXNG_SECRET}" ]; then
    echo "Generating random secret key for SearXNG..."
    SEARXNG_SECRET=$(openssl rand -hex 32)
    # Add or replace SEARXNG_SECRET in .env file
    if grep -q "^SEARXNG_SECRET=" .env; then
        sed -i "s|^SEARXNG_SECRET=.*|SEARXNG_SECRET='${SEARXNG_SECRET}'|" .env
    else
        echo "SEARXNG_SECRET='${SEARXNG_SECRET}'" >> .env
    fi
    # Reload environment variables
    set -a
    [ -f .env ] && . ./.env
    set +a
fi

# Ensure settings.yml exists with proper secret key
if [ ! -f searxng/settings.yml ] || grep -q "ultrasecretkey" searxng/settings.yml; then
    echo "Creating or updating SearXNG settings.yml with secure secret key..."
    cp settings.yml searxng/settings.yml
    
    # Replace variables with values from .env
    sed -i "s|\${SEARXNG_SECRET}|${SEARXNG_SECRET}|g" searxng/settings.yml
    sed -i "s|\${SEARXNG_REDIS_URL}|${SEARXNG_REDIS_URL:-redis://unicorn-redis:6379/0}|g" searxng/settings.yml
    
    # Configure proxy if enabled
    if [ "${USE_ROTATING_PROXY}" = "true" ]; then
        sed -i "s|\${BRIGHTDATA_USERNAME}|${BRIGHTDATA_USERNAME}|g" searxng/settings.yml
        sed -i "s|\${BRIGHTDATA_PASSWORD}|${BRIGHTDATA_PASSWORD}|g" searxng/settings.yml
        sed -i "s|\${BRIGHTDATA_GATEWAY}|${BRIGHTDATA_GATEWAY}|g" searxng/settings.yml
        sed -i "s|\${BRIGHTDATA_PORT}|${BRIGHTDATA_PORT}|g" searxng/settings.yml
    else
        # Comment out proxy config if disabled
        sed -i '/# Proxy Configuration/,/# Engine Configurations/s/^/#/' searxng/settings.yml
    fi
fi

# Start just the SearXNG container in detached mode
echo "Starting SearXNG container..."
$DOCKER_COMPOSE up -d unicorn-searxng

# Once SearXNG is running, start the rest of the stack
echo "Starting the rest of UnicornCommander stack..."
$DOCKER_COMPOSE up -d

echo "UnicornCommander stack is now running!"
echo "SearXNG is available at: http://localhost:8888"
echo "Open-WebUI is available at: http://localhost:8080"

# Documentation service info
echo -e "\n📚 Documentation Service:"
echo "To start the UC-1 documentation site:"
echo "  cd ../UC-1_Extensions/UC-1_Documentation && ./start-docs.sh"
echo "  Then access at: http://localhost:7911"

# Helpful tip about logs
echo -e "\nTo view logs, use: $DOCKER_COMPOSE logs -f [service_name]"
echo "Example: $DOCKER_COMPOSE logs -f unicorn-searxng"