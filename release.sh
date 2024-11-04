#!/bin/bash 

echo "Shutting down the Debian VM..." 

echo y | ship --vm shutdown debian-vm-base 

echo "Compressing the Debian VM disk image..."

ship --vm compress debian-vm-base 

echo "Starting the xz compression of the Debian disk image to generate the release package for 'debian-vm-base'..."

DISK_IMAGE=$(sudo virsh domblklist debian-vm-base | grep .qcow2 | awk '{print $2}')

xz -9 -z "$DISK_IMAGE"

echo "Moving the compressed disk image to the output directory..."

mv "$DISK_IMAGE.xz" output/debian.qcow2.xz

echo "The release package for 'debian-vm-base' has been generated successfully!"
