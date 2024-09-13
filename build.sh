SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
XML_FILE="/tmp/debian-vm-base.xml"

ship --vm create debian-vm-base --source https://cdimage.debian.org/images/cloud/bookworm/latest/debian-12-nocloud-amd64.qcow2

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

COMMANDS=$(cat <<'EOF'
root
EOF
)

while IFS= read -r command; do
    if [[ -n "$command" ]]; then
        tmux send-keys -t debian-vm-base "$command" C-m
        sleep 1
    fi
done <<< "$COMMANDS"

COMMANDS=$(cat <<'EOF'
echo "hi"
echo "its working"
EOF
)

COMBINED_COMMANDS=$(echo "$COMMANDS" | awk '{print $0 " &&"}' | sed '$s/ &&$//') 

tmux send-keys -t debian-vm-base "$COMBINED_COMMANDS" C-m

ship --vm view debian-vm-base
