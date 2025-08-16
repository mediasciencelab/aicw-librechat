#!/usr/bin/env bash

# This script is used to SSH to the libre-chat instance and run commands and such.

source "$(dirname "$0")/lib/start_script.sh"

$this_dir/librechat-npm-run.sh $@ list-users