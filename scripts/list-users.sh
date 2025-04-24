#!/usr/bin/env bash

# This script is used to SSH to the libre-chat instance and run commands and such.

this_dir=$(dirname "$0")
project_root=$this_dir/..

$this_dir/ssh-instance.sh $@ docker exec -it LibreChat /bin/sh -c "'cd .. && npm run list-users'"