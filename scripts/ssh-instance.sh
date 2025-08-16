#!/usr/bin/env bash

# This script is used to SSH to the libre-chat instance and run commands and such.

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
  echo "No stage provided and no stage found in .sst/stage"
  exit 1
else
  echo "Stage: $stage"
fi

shift $((OPTIND - 1))
cmd="$@"

set -e

# Retrieve the IP address of the instance
instance_ip=$(get_stack_output "$stage" "Static" "libreChatIpAddress")

# SSH to instance

ssh -tt ubuntu@$instance_ip "${cmd}"
