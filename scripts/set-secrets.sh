#!/usr/bin/env bash

# This script is used to set secrets for a LibreChat environment.

source "$(dirname "$0")/lib/start_script.sh"

stage=`cat $project_root/.sst/stage 2> /dev/null`

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
  echo "No stage provided and no stage found in .sst/stage"
  exit 1
else
  echo "Stage: $stage"
fi

shift $((OPTIND - 1))
cmd="$@"

set -e

secrets_file=$1

if [[ -z "$secrets_file" ]]; then
  echo "No secrets file provided"
  exit 1
fi

if [[ ! -f "$secrets_file" ]]; then
  echo "Secrets file not found: $secrets_file"
  exit 1
fi

# Set secret /mediasci/aicw/librechat/$stage/env in SSM.
aws ssm put-parameter \
  --name "/mediasci/aicw/librechat/$stage/env" \
  --value "$(cat $secrets_file)" \
  --type "SecureString" \
  --overwrite \
  --key-id "alias/aiwc-librechat-$stage"

# Add tags to the parameter
aws ssm add-tags-to-resource \
  --resource-type "Parameter" \
  --resource-id "/mediasci/aicw/librechat/$stage/env" \
  --tags \
    Key=mediasci:project,Value=aicw \
    Key=mediasci:env,Value=$stage \
    Key=mediasci:provisioner,Value=set-secrets.sh
