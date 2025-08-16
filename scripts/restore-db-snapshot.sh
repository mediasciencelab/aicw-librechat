#!/usr/bin/env bash

# This script restores an EBS volume from a snapshot by updating the Storage stack.
# This will replace the current volume with a new one created from the snapshot.

# Be warned: This script was primarily written by Claude Code SDK.

source "$(dirname "$0")/lib/start_script.sh"
source "$(dirname "$0")/lib/sst.sh"

stage=$(get_stage)

# Parse some options
while getopts ":s:n:" opt; do
  case $opt in
    s)
      stage=$OPTARG
      ;;
    n)
      snapshot_id=$OPTARG
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

if [[ -z "$snapshot_id" ]]; then
  echo "Snapshot ID is required. Use -n <snapshot-id>"
  echo ""
  echo "You can list available snapshots with:"
  echo "./scripts/list-db-snapshots.sh -s $stage"
  exit 1
fi

echo "Stage: $stage"
echo "Snapshot ID: $snapshot_id"

set -e

# Verify the snapshot exists and get its details
echo "Verifying snapshot..."
snapshot_info=$(
  aws ec2 describe-snapshots \
    --snapshot-ids "$snapshot_id" \
    --query "Snapshots[0].[State,VolumeSize,Description,StartTime]" \
    --output text 2>/dev/null || {
      echo "Error: Snapshot $snapshot_id not found or not accessible"
      exit 1
    }
)

read -r snapshot_state volume_size description start_time <<< "$snapshot_info"

if [[ "$snapshot_state" != "completed" ]]; then
  echo "Error: Snapshot is not in 'completed' state (current: $snapshot_state)"
  exit 1
fi

echo "Snapshot Details:"
echo "  State: $snapshot_state"
echo "  Size: ${volume_size}GB"
echo "  Description: $description"
echo "  Created: $start_time"
echo ""

# Confirm before proceeding
echo "⚠️  WARNING: This will:"
echo "   - Stop the EC2 instance"
echo "   - Replace the current EBS volume with a new one from the snapshot"
echo "   - All data since the snapshot was created will be LOST"
echo "   - The instance will restart with the restored data"
echo ""
read -p "Do you want to proceed? (yes to proceed): " confirm

if [[ "$confirm" != "yes" ]]; then
  echo "Restore cancelled."
  exit 0
fi

echo ""
echo "Starting restore process..."

# Step 1: Stop the instance first (to avoid data corruption)
echo "Stopping EC2 instance..."
pnpm sst remove --stage "$stage" Instance

# Step 2: Stop the instance first (to avoid data corruption)
echo "Removing storage..."
pnpm sst remove --stage "$stage" Storage

# Step 3: Write snapshot ID to file and deploy Storage stack
echo "Writing snapshot ID to .snapshot-id.$stage file..."
echo "$snapshot_id" > "$project_root/.snapshot-id.$stage"
echo "Wrote snapshot ID $snapshot_id to .snapshot-id.$stage"

echo "Deploying Storage stack with snapshot..."
cd "$project_root"
pnpm sst deploy --stage "$stage" Storage

# Step 4: Redeploy other stacks
echo "Redeploying remaining stack..."
pnpm sst deploy --stage "$stage"

echo ""
echo "✅ Restore completed successfully!"
echo "✅ Instance has been restarted with data from snapshot: $snapshot_id"
echo ""
echo "Please verify that your application is working correctly."
echo "You can SSH to the instance with: ./scripts/ssh-instance.sh -s $stage"