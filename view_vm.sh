#!/usr/bin/expect

set response [lindex $argv 0]

spawn ship --vm view debian-vm-base

expect "Do you want a full GUI of the VM(By default the view action will show only a terminal of the VM) ? (y/n):"
send "$response\r"

interact

