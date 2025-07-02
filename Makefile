.PHONY: setup build start stop restart logs clean help

# Default target
help:
	@echo "UnicornCommander SearXNG Management"
	@echo ""
	@echo "Available targets:"
	@echo "  setup    - Install dependencies and prepare environment"
	@echo "  build    - Build SearXNG container"
	@echo "  start    - Start SearXNG service"
	@echo "  stop     - Stop SearXNG service"
	@echo "  restart  - Restart SearXNG service"
	@echo "  logs     - View SearXNG logs"
	@echo "  clean    - Remove generated files"
	@echo "  help     - Show this help message"

# Setup environment
setup:
	@echo "Installing dependencies..."
	pip3 install -r requirements.txt
	@echo "Making start script executable..."
	chmod +x start.sh

# Build SearXNG container
build:
	@echo "Rendering settings..."
	python3 render-settings.py
	@echo "Building SearXNG container..."
	docker compose build unicorn-searxng

# Start SearXNG service
start:
	@echo "Starting SearXNG service..."
	./start.sh

# Stop SearXNG service
stop:
	@echo "Stopping SearXNG service..."
	docker compose stop unicorn-searxng

# Restart SearXNG service
restart: stop start

# View SearXNG logs
logs:
	docker compose logs -f unicorn-searxng

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	rm -f searxng/settings.yml
	@echo "Done."