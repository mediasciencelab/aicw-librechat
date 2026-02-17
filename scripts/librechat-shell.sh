#!/usr/bin/env bash

# This script opens a shell in the LibreChat Docker container.
# Usage: ./librechat-shell.sh [ssh-instance options]

source "$(dirname "$0")/lib/start_script.sh"
source "$(dirname "$0")/lib/sst.sh"

stage=$(get_stage)

# Parse some options
while getopts ":s:" opt; do
  case $opt in
    s)
      stage=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [[ -z "$stage" ]]; then
  echo "No stage provided and no stage found in infra/.sst/stage"
  exit 1
fi

# Execute shell in the LibreChat container
$this_dir/ssh-instance.sh -s "$stage" docker exec -it LibreChat /bin/sh