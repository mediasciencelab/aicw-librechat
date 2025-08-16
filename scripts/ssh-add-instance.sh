#!/usr/bin/env bash

# This script is used to add the SSH key for a libre-chat environment to the ssh agent.

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

set -e

# Retrieve SSH key
ssh_key_param=$(get_stack_output "$stage" "Static" "keyPairPrivateKeyParameter")

echo "SSH key param: $ssh_key_param"

# Retrieve the key

ssh_key=$(aws ssm get-parameter \
  --name $ssh_key_param \
  --with-decryption \
  --query Parameter.Value \
  --output text)

# Retrieve the IP address of the instance
instance_ip=$(get_stack_output "$stage" "Static" "libreChatIpAddress")

# Add the SSH key to the ssh-agent
ssh-add - <<< "$ssh_key" > /dev/null

echo Ready to SSH to instance at $instance_ip