#!/usr/bin/env bash

# This script executes npm commands on the LibreChat Docker container.
# Usage: ./librechat-exec.sh [ssh-instance options] <npm-script-name>

source "$(dirname "$0")/lib/start_script.sh"

if [ $# -eq 0 ]; then
    echo "Usage: $0 [ssh-instance options] <npm-script-name>"
    echo "Example: $0 -s dev list-users"
    echo "Example: $0 create-user"
    exit 1
fi

# Get the last argument (npm script name)
npm_script="${@: -1}"

# Get all arguments except the last one (ssh-instance options)
ssh_args=("${@:1:$(($#-1))}")

# Execute the npm script in the LibreChat container with writable log directory
$this_dir/ssh-instance.sh "${ssh_args[@]}" docker exec -it LibreChat /bin/sh -c "'cd .. && LIBRECHAT_LOG_DIR=/tmp/logs npm run $npm_script'"