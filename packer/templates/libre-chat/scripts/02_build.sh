#!/bin/bash

set -e

sudo usermod -aG docker ubuntu

tar --warning=no-unknown-keyword -xzf /var/tmp/libre-chat.tar.gz
rm /var/tmp/libre-chat.tar.gz

sudo docker build -f Dockerfile.multi -t libre-chat --target api-build .

sudo docker pull mongo:latest
sudo docker pull getmeili/meilisearch:v1.12.3

cp /var/tmp/firstrun.sh /home/ubuntu/firstrun.sh
sudo chmod +x /home/ubuntu/firstrun.sh
cp /var/tmp/fetch-secrets.sh /home/ubuntu/fetch-secrets.sh
sudo chmod +x /home/ubuntu/fetch-secrets.sh
sudo cp /var/tmp/libre-chat.service /etc/systemd/system/libre-chat.service
cp /var/tmp/librechat.mediasci.yaml /home/ubuntu/librechat.yaml

mkdir -p /home/ubuntu/data
mkdir -p /home/ubuntu/data-node
mkdir -p /home/ubuntu/images
mkdir -p /home/ubuntu/meili_data_v1.12
mkdir -p /home/ubuntu/logs
mkdir -p /home/ubuntu/uploads

