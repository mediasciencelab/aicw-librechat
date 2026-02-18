#!/usr/bin/env bash

# Restart the LibreChat EC2 instance (stop + start) using the AWS EC2 API.

source "$(dirname "$0")/lib/start_script.sh"
source "$(dirname "$0")/lib/sst.sh"
source "$(dirname "$0")/lib/aws.sh"

stage=$(get_stage)

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
else
  echo "Stage: $stage"
fi

set -e

instance_id=$(get_stack_output "$stage" "Instance" "instanceId")

if [[ -z "$instance_id" ]]; then
  echo "Could not find instance ID for stage $stage" >&2
  exit 1
fi

echo "Stopping instance $instance_id..."
aws ec2 stop-instances --instance-ids "$instance_id"
echo "Waiting for instance to stop..."
aws ec2 wait instance-stopped --instance-ids "$instance_id"

echo "Starting instance $instance_id..."
aws ec2 start-instances --instance-ids "$instance_id"
echo "Waiting for instance to start..."
aws ec2 wait instance-running --instance-ids "$instance_id"

echo "Instance $instance_id restarted."