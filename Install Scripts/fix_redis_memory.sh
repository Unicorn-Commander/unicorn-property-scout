#!/bin/bash

echo "🧠 Magic Unicorn: Fixing Redis memory overcommit setting..."

# Step 1: Add or update the line in /etc/sysctl.conf
CONF_LINE="vm.overcommit_memory = 1"
SYSCTL_FILE="/etc/sysctl.conf"

if grep -q "^vm.overcommit_memory" "$SYSCTL_FILE"; then
    sudo sed -i "s/^vm.overcommit_memory.*/$CONF_LINE/" "$SYSCTL_FILE"
    echo "✅ Updated existing vm.overcommit_memory line."
else
    echo "$CONF_LINE" | sudo tee -a "$SYSCTL_FILE" > /dev/null
    echo "✅ Added vm.overcommit_memory to $SYSCTL_FILE."
fi

# Step 2: Apply the change immediately
sudo sysctl -w vm.overcommit_memory=1

# Step 3: Confirm it worked
CURRENT=$(cat /proc/sys/vm/overcommit_memory)
if [[ "$CURRENT" == "1" ]]; then
    echo "✅ Success: vm.overcommit_memory is now set to 1."
else
    echo "❌ Failed: vm.overcommit_memory is still set to $CURRENT."
fi