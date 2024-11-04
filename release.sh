#!/bin/bash 

echo "Shutting down the Debian VM..." 

echo y | ship --vm shutdown debian-vm-base 

echo "Compressing the Debian VM disk image..."

ship --vm compress debian-vm-base 

echo "Copying the Debian VM disk image to generate the release package for 'debian-vm-base'..."

DISK_IMAGE=$(sudo virsh domblklist debian-vm-base | grep .qcow2 | awk '{print $2}')

cp "$DISK_IMAGE" output/debian.qcow2

echo "The release package for 'debian-vm-base' has been generated successfully!"

