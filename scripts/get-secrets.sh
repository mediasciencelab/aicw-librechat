#!/usr/bin/env bash

# This script is used to set secrets for a LibreChat environment.

this_dir=$(dirname "$0")
project_root=$this_dir/..

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
fi

shift $((OPTIND - 1))
cmd="$@"

set -e

# Retrieve SSM secret from /mediasci/aicw/librechat/$stage/env.
aws ssm get-parameter \
  --name "/mediasci/aicw/librechat/$stage/env" \
  --with-decryption \
  --query Parameter.Value \
  --output text

