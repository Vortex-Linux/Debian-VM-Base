#!/usr/bin/expect

spawn tmux attach-session -t debian-vm-base

expect "localhost login:"
send "root\r"

interact

