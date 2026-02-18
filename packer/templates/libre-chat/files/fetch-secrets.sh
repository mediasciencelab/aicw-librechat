#!/bin/bash

set -e

ENV=$(cat /etc/env)
aws ssm get-parameter \
  --name "/mediasci/aicw/librechat/${ENV}/env" \
  --with-decryption \
  --region us-east-1 \
  --query Parameter.Value \
  --output text > /home/ubuntu/.env