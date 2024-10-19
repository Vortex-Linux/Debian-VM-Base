#!/bin/bash

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
XML_FILE="/tmp/debian-vm-base.xml"

LATEST_IMAGE=$(lynx -dump -listonly -nonumbers https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/ | grep netinst | head -n 1)

ship --vm delete debian-vm-base 

echo n | ship --vm create debian-vm-base --source "$LATEST_IMAGE"

sed -i '/<\/devices>/i \
  <console type="pty">\
    <target type="virtio"/>\
  </console>\
  <serial type="pty">\
    <target port="0"/>\
  </serial>' "$XML_FILE"

virsh -c qemu:///system undefine debian-vm-base
virsh -c qemu:///system define "$XML_FILE"

ship --vm start debian-vm-base 

./setup.sh
./view_vm.sh
./release.sh

