#!/usr/bin/env bash

# AWS utility functions

# Get a CloudFormation stack output value
# Usage: get_stack_output <stage> <stack-name> <output-key>
# Example: get_stack_output "dev" "Static" "libreChatIpAddress"
get_stack_output() {
    local stage=$1
    local stack_name=$2
    local output_key=$3
    
    aws cloudformation describe-stacks \
        --stack-name "${stage}-aiwc-librechat-${stack_name}" \
        --query "Stacks[0].Outputs[?OutputKey=='${output_key}'].OutputValue" \
        --output text
}