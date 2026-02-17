#!/usr/bin/env bash

# This script creates an EBS snapshot of the volume for a given LibreChat environment.

source "$(dirname "$0")/lib/start_script.sh"
source "$(dirname "$0")/lib/sst.sh"
source "$(dirname "$0")/lib/aws.sh"

stage=$(get_stage)
stop_instance=true

# Parse some options

while [[ $# -gt 0 ]]; do
  case $1 in
    -s)
      stage="$2"
      shift 2
      ;;
    -d)
      description="$2"
      shift 2
      ;;
    --no-stop)
      stop_instance=false
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [-s stage] [-d description] [--no-stop]"
      echo "  -s stage       Specify the environment stage"
      echo "  -d description Custom snapshot description"
      echo "  --no-stop      Skip stopping/starting the instance (may result in inconsistent snapshot)"
      exit 0
      ;;
    -*)
      echo "Invalid option: $1" >&2
      exit 1
      ;;
    *)
      echo "Unexpected argument: $1" >&2
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

# Set default description if not provided
if [[ -z "$description" ]]; then
  description="LibreChat $stage environment backup - $(date '+%Y-%m-%d %H:%M:%S')"
fi

echo "Description: $description"

set -e

# Retrieve the EBS Volume ID from the Storage stack
volume_id=$(get_stack_output "$stage" "Storage" "ebsVolumeId")

if [[ -z "$volume_id" ]] || [[ "$volume_id" == "None" ]]; then
  echo "Error: Could not find EBS Volume ID for stage '$stage'"
  echo "Make sure the Storage stack is deployed for this stage."
  exit 1
fi

echo "EBS Volume ID: $volume_id"

# Get the instance ID from the Instance stack
instance_id=$(get_stack_output "$stage" "Instance" "instanceId")

if [[ "$stop_instance" == "false" ]]; then
  echo "Skipping instance stop as requested with --no-stop option."
  echo "Warning: This may result in inconsistent data if the database is being written to during snapshot."
elif [[ -z "$instance_id" ]] || [[ "$instance_id" == "None" ]]; then
  echo "Warning: Could not find Instance ID for stage '$stage'. Taking snapshot with instance running."
  echo "This may result in inconsistent data if the database is being written to during snapshot."
  stop_instance=false
else
  echo "Instance ID: $instance_id"
  
  # Stop the instance for consistent snapshot
  echo "Stopping EC2 instance for consistent snapshot..."
  aws ec2 stop-instances --instance-ids "$instance_id"
  
  echo "Waiting for instance to stop..."
  aws ec2 wait instance-stopped --instance-ids "$instance_id"
  echo "Instance stopped successfully"
fi

# Create the snapshot
echo "Creating EBS snapshot..."
snapshot_id=$(
  aws ec2 create-snapshot \
    --volume-id "$volume_id" \
    --description "$description" \
    --tag-specifications "ResourceType=snapshot,Tags=[{Key=mediasci:project,Value=aicw},{Key=mediasci:env,Value=$stage},{Key=mediasci:provisioner,Value=script},{Key=Name,Value=aiwc-librechat-$stage-snapshot-$(date '+%Y%m%d-%H%M%S')}]" \
    --query "SnapshotId" \
    --output text
)

echo "Snapshot created successfully!"
echo "Snapshot ID: $snapshot_id"
echo "Volume ID: $volume_id"
echo "Stage: $stage"

# Restart the instance if we stopped it
if [[ "$stop_instance" == "true" ]] && [[ -n "$instance_id" ]] && [[ "$instance_id" != "None" ]]; then
  echo ""
  echo "Restarting EC2 instance..."
  aws ec2 start-instances --instance-ids "$instance_id"
  
  echo "Waiting for instance to start..."
  aws ec2 wait instance-running --instance-ids "$instance_id"
  echo "Instance restarted successfully"
fi

echo ""
echo "You can monitor the snapshot progress with:"
echo "aws ec2 describe-snapshots --snapshot-ids $snapshot_id --query 'Snapshots[0].[State,Progress]' --output table"