#!/usr/bin/env bash

set -e

# This script is used to promote the latest AMI from one environment to another.

source_env=$1
target_env=$2

if [ -z "$source_env" ] || [ -z "$target_env" ]; then
  echo "Usage: $0 <source-env> <target-env>"
  exit 1
fi

# Get the latest AMI ID from the source environment. This is by searching for AMIs that start
# with "aiwc-librechat-" and have the tags `mediasci:env:$source_env`=`true` and
# `mediasci:project`=`aicw`.
latest_ami_id=$(
  aws ec2 describe-images \
  --filters "Name=name,Values=aiwc-librechat-*" \
  "Name=tag:mediasci:env:$source_env,Values=true" \
  "Name=tag:mediasci:project,Values=aicw" \
  --query 'Images[*]' --output json \
  | jq -r '. | sort_by(.CreationDate) | reverse | .[0] | "\(.ImageId)"'
)

echo "Latest AMI ID: $latest_ami_id"

# Set the tag `mediasci:env:$target_env`=`true` on the AMI.
aws ec2 create-tags \
  --resources $latest_ami_id \
  --tags "Key=mediasci:env:$target_env,Value=true"

echo "AMI $latest_ami_id promoted to environment $target_env"