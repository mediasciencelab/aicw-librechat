#!/usr/bin/env bash

# This script generates both npm and pnpm lock files for the project.
# This ensures compatibility with both package managers - pnpm for development
# and npm for Docker builds.

set -e

source "$(dirname "$0")/lib/start_script.sh"

echo "Updating package lock files..."
echo "Project root: $project_root"

cd "$project_root"

# Generate pnpm lock file
echo "Generating pnpm-lock.yaml..."
pnpm install --lockfile-only

# Generate npm lock file
echo "Generating package-lock.json..."
npm install --package-lock-only

echo ""
echo "✅ Lock files updated successfully!"
echo "   - pnpm-lock.yaml"
echo "   - package-lock.json"
echo ""
echo "Both files are now in sync with package.json dependencies."