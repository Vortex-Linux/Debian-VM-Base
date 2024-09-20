#!/usr/bin/expect

spawn tmux attach-session -t debian-vm-base

expect "localhost login:"
send "root\r"

set prompt "root@localhost:~# "

set commands {
    "sudo apt update && sudo apt upgrade -y"
    "echo \"root:debian\" | sudo chpasswd"
    "sudo hostnamectl set-hostname debianlinux"
    "sudo adduser --quiet --disabled-password --gecos \"\" debian"
    "echo \"debian:debian\" | sudo chpasswd"
    "sudo usermod -aG sudo debian"
    "sudo apt install -y xorg xinit"
    "echo -e \"X11Forwarding yes\\nX11DisplayOffset 10\" | sudo tee -a /etc/ssh/sshd_config"
    "sudo systemctl reload sshd"
    "sudo tee /etc/systemd/system/xorg.service > /dev/null <<SERVICE
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
SERVICE"
    "sudo systemctl daemon-reload"
    "sudo systemctl enable --now xorg.service"
}

foreach cmd $commands {
    send -- "$cmd\r" 
    expect $prompt
}

interact

