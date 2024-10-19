#!/bin/bash

echo "Starting the compression of the Arch disk image to generate the release package for 'arch-vm-base'..."

DISK_IMAGE=$(sudo virsh domblklist arch-vm-base | grep .qcow2 | awk '{print $2}')

xz -z "$DISK_IMAGE"

mv "$DISK_IMAGE.xz" output/archlinux.qcow2.xz
