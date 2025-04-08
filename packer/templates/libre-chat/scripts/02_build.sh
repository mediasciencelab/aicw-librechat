#!/bin/bash

set -e

sudo usermod -aG docker ubuntu

tar --warning=no-unknown-keyword -xzf /var/tmp/libre-chat.tar.gz || exit 1
rm /var/tmp/libre-chat.tar.gz || exit 1

gunzip -c /var/tmp/libre-chat.image.tar.gz | sudo docker load || exit 1
rm /var/tmp/libre-chat.image.tar.gz || exit 1

sudo docker pull mongo:latest || exit 1

sudo cp /var/tmp/libre-chat.service /etc/systemd/system/libre-chat.service || exit 1
sudo systemctl enable libre-chat.service