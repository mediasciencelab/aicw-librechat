#!/bin/bash

echo "***********************************"
echo "First Run Libre Chat"
echo "***********************************"

ENV=`cat /etc/env`
DEV="/dev/nvme1n1"
MOUNT_PATH="/home/ubuntu/data-node"

# Make sure data device is formatted and mounted
echo "$DEV $MOUNT_PATH ext4 defaults 0 0" >> /etc/fstab
systemctl daemon-reload

DEVICE_ATTACHED=false
for i in {1..60}
do
  if lsblk $DEV; then
    echo "Data device is attached to instance"
    DEVICE_ATTACHED=true
    break
  fi
  sleep 1
done

if [[ $DEVICE_ATTACHED != true ]]; then
  echo "Data device not attached to instance" >&2
  exit 1
fi

echo "Mounting data device..."
mount -a
MOUNT_STATUS=$?
if [[ $MOUNT_STATUS == 32 ]]; then
  mkfs -t ext4 $DEV
  echo "Data device formatted"
  mount -a
  MOUNT_STATUS=$?
fi

if [[ $MOUNT_STATUS != 0 ]]; then
  echo "Failed to mount $MOUNT_PATH" >&2
  exit 1
fi

# Make sure the mount path is owned by the ubuntu user
chown -R 1000:1000 $MOUNT_PATH

# enable and start service
echo "Starting libre-chat service..."
systemctl enable libre-chat.service
systemctl start libre-chat
echo "Libre-chat service started"
