# UnicornCommander SearXNG Setup Guide

## File Structure
Ensure your directory structure is set up as follows:

```
~/UnicornCommander/
├── docker-compose.yml        # Your complete stack config
├── .env                      # Environment variables
├── render-settings.py        # Template renderer (updated)
├── start.sh                  # Startup script (updated)
├── searxng/
    ├── Dockerfile            # SearXNG build from source
    ├── .dockerignore         # Optimization for Docker builds
    ├── settings.yml.template # Configuration template
    ├── uwsgi.ini             # uWSGI web server config
    └── limiter.toml          # Empty limiter file
```

## Setup Steps

1. **Create or update all the necessary files**
   - Update `docker-compose.yml` with the SearXNG service
   - Create the `searxng/Dockerfile` for building from source
   - Update `render-settings.py` to handle environment variables
   - Create the `start.sh` script for launching the service
   - Create `.dockerignore` for optimized builds

2. **Make the start script executable**
   ```bash
   chmod +x start.sh
   ```

3. **Launch the Stack**
   ```bash
   ./start.sh
   ```
   This will:
   - Render the settings.yml from your template using Docker
   - Build the SearXNG container
   - Start the service

4. **Verify the deployment**
   ```bash
   # Check if the container is running
   docker ps | grep unicorn-searxng
   
   # View logs for any errors
   docker logs unicorn-searxng
   
   # Access the web interface
   xdg-open http://localhost:8888
   ```

## Troubleshooting

If you encounter issues:

1. **Check the generated settings.yml**
   ```bash
   cat searxng/settings.yml
   ```
   Ensure the proxy settings are correctly applied.

2. **Verify network connectivity**
   ```bash
   # Check if Redis is accessible from SearXNG
   docker exec unicorn-searxng ping -c 1 unicorn-redis
   ```

3. **Test the proxy configuration**
   ```bash
   # View logs for proxy-related issues
   docker logs unicorn-searxng | grep -i proxy
   ```

4. **Restart the service if needed**
   ```bash
   docker compose restart unicorn-searxng
   ```

## Integration with Open-WebUI

The SearXNG service should automatically integrate with Open-WebUI based on your environment variables:

```
SEARCH_ENGINE: "searxng"
SEARXNG_URL: "http://unicorn-searxng:8888"
```

You can verify the integration is working by:
1. Opening Open-WebUI at http://localhost:8080
2. Creating a new chat and asking a question that requires search
3. Checking if results are retrieved from SearXNG