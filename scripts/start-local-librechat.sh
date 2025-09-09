#!/usr/bin/env bash

# This script runs LibreChat locally using docker-compose.mediasci.yml
# It builds and starts all required services (api, mongodb, meilisearch)
#
# Usage: start-local-librechat.sh [-e env_file]
#   -e env_file    Specify a custom environment file (default: .env)

set -e

source "$(dirname "$0")/lib/start_script.sh"

# Parse command line arguments
env_file=".env"
while getopts "e:" opt; do
    case $opt in
        e) env_file="$OPTARG" ;;
        \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
    esac
done

echo "Starting local LibreChat development environment..."
echo "Project root: $project_root"
echo "Environment file: $env_file"

cd "$project_root"

# Check if docker-compose.mediasci.yml exists
if [ ! -f "docker-compose.mediasci.yml" ]; then
    echo "❌ docker-compose.mediasci.yml not found in project root"
    exit 1
fi

# Check if specified env file exists
if [ ! -f "$env_file" ]; then
    echo "❌ $env_file not found in project root"
    echo "   You need to create one with required environment variables"
    exit 1
fi

# Build and start the services
echo "Building and starting LibreChat services..."
echo "Using environment file: $env_file"
ENV_FILE="$env_file" docker compose -f docker-compose.mediasci.yml up --build -d

echo ""
echo "✅ LibreChat is starting up!"
echo "   - API will be available at: http://localhost:3080"
echo "   - MongoDB running on port 27017"
echo "   - MeiliSearch running internally on port 7700"
echo ""
echo "To view logs: docker compose -f docker-compose.mediasci.yml logs -f"
echo "To stop: docker compose -f docker-compose.mediasci.yml down"