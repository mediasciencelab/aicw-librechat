#!/bin/bash

set -e

sudo usermod -aG docker ubuntu

tar --warning=no-unknown-keyword -xzf /var/tmp/libre-chat.tar.gz
rm /var/tmp/libre-chat.tar.gz

sudo docker build -f Dockerfile.multi -t libre-chat --target api-build .

sudo docker pull mongo:latest

sudo cp /var/tmp/001-firstrun.sh /var/lib/cloud/scripts/per-instance/001-firstrun.sh
sudo chmod +x /var/lib/cloud/scripts/per-instance/001-firstrun.sh
sudo cp /var/tmp/libre-chat.service /etc/systemd/system/libre-chat.service
cp /var/tmp/librechat.mediasci.yaml /home/ubuntu/librechat.yaml

mkdir -p /home/ubuntu/data-node
