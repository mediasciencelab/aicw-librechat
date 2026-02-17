#!/usr/bin/env bash

# SST-related utility functions

# Function to get the current stage from infra/.sst/stage file
get_stage() {
    cat "$project_root/infra/.sst/stage" 2> /dev/null
}