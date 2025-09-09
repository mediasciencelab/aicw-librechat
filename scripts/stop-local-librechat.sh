#!/usr/bin/env bash

# This script stops the local LibreChat development environment
# It stops all services started by docker-compose.mediasci.yml

set -e

source "$(dirname "$0")/lib/start_script.sh"

echo "Stopping local LibreChat development environment..."
echo "Project root: $project_root"

cd "$project_root"

# Check if docker-compose.mediasci.yml exists
if [ ! -f "docker-compose.mediasci.yml" ]; then
    echo "❌ docker-compose.mediasci.yml not found in project root"
    exit 1
fi

# Stop the services
echo "Stopping LibreChat services..."
docker compose -f docker-compose.mediasci.yml down

echo ""
echo "✅ LibreChat services stopped!"
echo ""
echo "To start again: ./scripts/run-local-librechat.sh"
echo "To remove volumes: docker compose -f docker-compose.mediasci.yml down -v"