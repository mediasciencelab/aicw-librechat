#!/usr/bin/env bash

# This script is used to SSH to the libre-chat instance and run commands and such.

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
else
  echo "Stage: $stage"
fi

shift $((OPTIND - 1))
cmd="$@"

set -e

# Retrieve the IP address of the instance
instance_ip=$(
  aws cloudformation describe-stacks \
    --stack-name ${stage}-aiwc-librechat-Static \
    --query "Stacks[0].Outputs[?OutputKey=='libreChatIpAddress'].OutputValue" \
    --output text
)

# SSH to instance

ssh -tt ubuntu@$instance_ip "${cmd}"
