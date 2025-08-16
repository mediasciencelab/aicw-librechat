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

# Get SSM parameter value with decryption
# Usage: get_ssm_parameter <parameter-name>
# Example: get_ssm_parameter "/mediasci/aicw/librechat/dev/env"
get_ssm_parameter() {
    local parameter_name=$1
    aws ssm get-parameter \
        --name "$parameter_name" \
        --with-decryption \
        --query Parameter.Value \
        --output text
}