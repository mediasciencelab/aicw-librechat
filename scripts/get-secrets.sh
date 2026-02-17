#!/usr/bin/env bash

# This script is used to set secrets for a LibreChat environment.

source "$(dirname "$0")/lib/start_script.sh"
source "$(dirname "$0")/lib/sst.sh"
source "$(dirname "$0")/lib/aws.sh"

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

shift $((OPTIND - 1))
cmd="$@"

set -e

# Retrieve SSM secret from /mediasci/aicw/librechat/$stage/env.
get_ssm_parameter "/mediasci/aicw/librechat/$stage/env"

