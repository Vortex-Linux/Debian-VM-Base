#!/bin/bash

INITIAL_COMMANDS=$(cat <<'EOF'
root
exec bash
EOF
)

while IFS= read -r command; do
    if [[ -n "$command" ]]; then
        tmux send-keys -t debian-vm-base "$command" C-m
        sleep 1
    fi
done <<< "$INITIAL_COMMANDS"

INSTALLATION_SCRIPT=$(cat << 'EOF'
cat << 'INSTALL_SCRIPT' > "install.sh"
#!/bin/bash
sgdisk --new=1:2048:+2M --typecode=1:ef02 --change-name=1:"BIOS boot" /dev/vda
sgdisk --new=2:0:+1G --typecode=2:8300 --change-name=2:"boot" /dev/vda
sgdisk --new=3:0:0 --typecode=3:8e00 --change-name=3:"LVM" /dev/vda

partprobe /dev/vda

pvcreate /dev/vda3 
vgcreate vg0 /dev/vda3

lvcreate --type thin-pool -L 1999G -n thinpool vg0 
lvcreate --thin vg0/thinpool --virtualsize 10G -n swap  
lvcreate --thin vg0/thinpool --virtualsize 1000G -n root 
lvcreate --thin vg0/thinpool --virtualsize 989G -n home 

mkfs.ext4 /dev/vda2
mkfs.ext4 /dev/vg0/root 
mkfs.ext4 /dev/vg0/home 
mkswap /dev/vg0/swap 
swapon /dev/vg0/swap 

mount /dev/vg0/root /mnt  

mkdir /mnt/boot 
mount /dev/vda2 /mnt/boot 

mkdir /mnt/home 
mount /dev/vg0/home /mnt/home 

sleep 60  

apt update 
apt install -y sudo debootstrap

debootstrap --arch amd64 bookworm /mnt http://deb.debian.org/debian/

genfstab -U -p /mnt >> /mnt/etc/fstab  

chroot /mnt /bin/bash <<CHROOT 

sed -i 's/^#\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "debian" > /etc/hostname  

systemctl enable fstrim.timer

echo "root:debian" | chpasswd

useradd -m -g users -G sudo,storage,power -s /bin/bash debian
echo "debian:debian" | chpasswd

apt install -y xorg xinit openbox network-manager

systemctl enable NetworkManager.service

tee /etc/systemd/system/xorg.service > /dev/null <<SERVICE
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

systemctl enable xorg.service

CHROOT

INSTALL_SCRIPT
EOF
)

tmux send-keys -t debian-vm-base "$INSTALLATION_SCRIPT" C-m 

sleep 5 &&

EXECUTE_INSTALL_SCRIPT="bash install.sh"

tmux send-keys -t debian-vm-base "$EXECUTE_INSTALL_SCRIPT" C-m 

