#!/bin/bash
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
XML_FILE="/tmp/debian-vm-base.xml"

ship --vm delete debian-vm-base 

echo n | ship --vm create debian-vm-base --source https://cdimage.debian.org/images/cloud/bookworm/latest/debian-12-nocloud-amd64.qcow2

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

./login.sh 

COMMANDS=$(cat <<EOF 
sudo apt update &&
sudo apt upgrade -y &&
echo "root:debian" | sudo chpasswd && 
sudo hostnamectl set-hostname "debianlinux" && 
sudo adduser --quiet --disabled-password --gecos "" debian && 
echo "debian:debian" | sudo chpasswd && 
sudo usermod -aG sudo debian &&

sudo apt install -y xorg xinit &&

echo -e "X11Forwarding yes\nX11DisplayOffset 10" | sudo tee -a /etc/ssh/sshd_config && 
sudo systemctl reload sshd && 

sudo tee /etc/systemd/system/xorg.service > /dev/null <<SERVICE
[Unit]
Description=X.Org Server
After=network.target

[Service]
ExecStart=/usr/bin/Xorg :0 -config /etc/X11/xorg.conf
Restart=always
User=debian
Environment=DISPLAY=:0

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload && 
sudo systemctl enable --now xorg.service
EOF
)

tmux send-keys -t debian-vm-base "$COMMANDS" C-m

./view_vm.sh

