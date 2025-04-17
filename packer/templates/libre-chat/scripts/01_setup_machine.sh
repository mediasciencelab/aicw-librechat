#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

echo "***********************************"
echo "Updated package manager"
echo "***********************************"

# update system
sudo apt update -y || exit 1
sudo apt upgrade -y || exit 1

# Install extra libraries.
# Instructions from: https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
sudo apt install ca-certificates curl -y || exit 1

sudo install -m 0755 -d /etc/apt/keyrings || exit 1
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc || exit 1
sudo chmod a+r /etc/apt/keyrings/docker.asc || exit 1

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || exit 1

sudo apt-get update || exit 1

echo "***********************************"
echo "Install dependencies"
echo "***********************************"

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y || exit 1

echo "***********************************"
echo "Install AWS CLI"
echo "***********************************"

sudo snap install aws-cli --classic
