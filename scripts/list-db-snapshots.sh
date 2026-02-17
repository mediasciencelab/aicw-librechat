#!/usr/bin/env bash

# This script lists EBS snapshots for a given LibreChat environment.

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
else
  echo "Stage: $stage"
fi

set -e

echo "Listing EBS snapshots for stage '$stage'..."

# List snapshots for specific stage (only those created by our script, excludes AMI snapshots)
aws ec2 describe-snapshots \
  --owner-ids self \
  --filters "Name=tag:mediasci:project,Values=aicw" "Name=tag:mediasci:env,Values=$stage" "Name=tag:mediasci:provisioner,Values=script" \
  --query 'Snapshots[*].[SnapshotId,StartTime,Description,Tags[?Key==`Name`].Value|[0]]' \
  --output table