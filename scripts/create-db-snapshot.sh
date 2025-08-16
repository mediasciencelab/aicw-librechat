#!/usr/bin/env bash

# This script creates an EBS snapshot of the volume for a given LibreChat environment.

source "$(dirname "$0")/lib/start_script.sh"

stage=`cat $project_root/.sst/stage 2> /dev/null`

# Parse some options

while getopts ":s:d:" opt; do
  case $opt in
    s)
      stage=$OPTARG
      ;;
    d)
      description=$OPTARG
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

# Set default description if not provided
if [[ -z "$description" ]]; then
  description="LibreChat $stage environment backup - $(date '+%Y-%m-%d %H:%M:%S')"
fi

echo "Description: $description"

set -e

# Retrieve the EBS Volume ID from the Storage stack
volume_id=$(
  aws cloudformation describe-stacks \
    --stack-name ${stage}-aiwc-librechat-Storage \
    --query "Stacks[0].Outputs[?OutputKey=='ebsVolumeId'].OutputValue" \
    --output text
)

if [[ -z "$volume_id" ]] || [[ "$volume_id" == "None" ]]; then
  echo "Error: Could not find EBS Volume ID for stage '$stage'"
  echo "Make sure the Storage stack is deployed for this stage."
  exit 1
fi

echo "EBS Volume ID: $volume_id"

# Get the instance ID from the Instance stack
instance_id=$(
  aws cloudformation describe-stacks \
    --stack-name ${stage}-aiwc-librechat-Instance \
    --query "Stacks[0].Outputs[?OutputKey=='instanceId'].OutputValue" \
    --output text
)

if [[ -z "$instance_id" ]] || [[ "$instance_id" == "None" ]]; then
  echo "Warning: Could not find Instance ID for stage '$stage'. Taking snapshot with instance running."
  echo "This may result in inconsistent data if the database is being written to during snapshot."
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
    --tag-specifications "ResourceType=snapshot,Tags=[{Key=mediasci:project,Value=aicw},{Key=mediasci:env:$stage,Value=true},{Key=mediasci:provisioner,Value=script},{Key=Name,Value=aiwc-librechat-$stage-snapshot-$(date '+%Y%m%d-%H%M%S')}]" \
    --query "SnapshotId" \
    --output text
)

echo "Snapshot created successfully!"
echo "Snapshot ID: $snapshot_id"
echo "Volume ID: $volume_id"
echo "Stage: $stage"

# Restart the instance if we stopped it
if [[ -n "$instance_id" ]] && [[ "$instance_id" != "None" ]]; then
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