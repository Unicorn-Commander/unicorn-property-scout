#!/bin/bash
# UnicornCommander Network Cutover Script for KDE6/Wayland
# Ubuntu Server 25.04 → KDE Plasma Desktop with NetworkManager
# Features: Clone prevention (default), KDE6 integration, Wayland support, Docker awareness
set -e

# Arguments handling - clone prevention is DEFAULT
CLONE_PREVENTION=true
PRE_CLONE_ONLY=false
for arg in "$@"; do
    case "$arg" in
        --no-clone) CLONE_PREVENTION=false ;;
        --pre-clone) PRE_CLONE_ONLY=true ;;
        --help|-h) 
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --no-clone    Skip clone prevention (keep existing hostname/IDs)"
            echo "  --pre-clone   Only run pre-clone cleanup (prepare for imaging)"
            echo "  --help        Show this help"
            exit 0
            ;;
        *) echo "Unknown option: $arg (use --help for options)" && exit 1 ;;
    esac
done

# Output colors
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'
PURPLE='\033[0;35m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${PURPLE}🦄 UnicornCommander Network Cutover${NC}"
echo -e "${BLUE}Ubuntu 25.04 | KDE6 Plasma | Wayland | AMD 8945HS${NC}"
echo -e "${BLUE}Clone Prevention: ${GREEN}$([ "$CLONE_PREVENTION" = true ] && echo "ENABLED (default)" || echo "DISABLED")${NC}"

# Check user and sudo
[ "$EUID" -eq 0 ] && echo -e "${YELLOW}⚠️ Run as user: ./$(basename "$0")${NC}" && exit 1
! sudo -n true 2>/dev/null && echo -e "${YELLOW}⚠️ Sudo access required${NC}" && exit 1

print_section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

# Pre-clone cleanup mode
if [ "$PRE_CLONE_ONLY" = true ]; then
    print_section "Pre-Clone Cleanup Mode"
    echo -e "${YELLOW}Preparing system for imaging...${NC}"
    
    # Remove machine-specific data
    sudo rm -f /etc/machine-id
    sudo rm -f /var/lib/dbus/machine-id
    sudo rm -f /etc/ssh/ssh_host_*
    
    # Clean NetworkManager state
    sudo rm -rf /var/lib/NetworkManager/*
    sudo rm -f /var/lib/dhcp/*.leases
    
    # Clear logs
    sudo journalctl --vacuum-time=1s
    sudo rm -rf /var/log/*
    
    # Remove user-specific data
    rm -f ~/.bash_history
    rm -rf ~/.cache/*
    history -c
    
    echo -e "${GREEN}✅ System prepared for cloning${NC}"
    echo -e "${YELLOW}Shutdown now and create your image${NC}"
    exit 0
fi

# Pre-flight check
print_section "Pre-flight Check"
echo "Detected Interfaces:"
for iface in eno1 enp3s0 wlan0; do
    if ip link show "$iface" 2>/dev/null | grep -q "$iface"; then
        MAC=$(ip link show "$iface" | awk '/ether/ {print $2}')
        echo "  $iface: $MAC"
    fi
done
echo "Current Hostname: $(hostname)"
echo "Current Primary IP: $(hostname -I | awk '{print $1}')"
echo -e "${YELLOW}This will reset ALL network connections${NC}"
read -p "Continue? (y/N) " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

# Install critical dependencies - using correct KDE6 package names
print_section "Installing Dependencies"
PACKAGES="network-manager plasma-nm iwd uuid-runtime ethtool"
# KDE6 specific packages for Ubuntu 25.04
KDE_PACKAGES="kde-config-systemd kio-extras"
# Check if qdbus is available (Qt5 vs Qt6)
if apt-cache show qdbus-qt6 >/dev/null 2>&1; then
    KDE_PACKAGES="$KDE_PACKAGES qdbus-qt6"
elif apt-cache show qdbus >/dev/null 2>&1; then
    KDE_PACKAGES="$KDE_PACKAGES qdbus"
fi

sudo apt update
sudo apt install -y $PACKAGES $KDE_PACKAGES || {
    echo -e "${YELLOW}Some packages failed to install, continuing...${NC}"
}
echo -e "${GREEN}✅ Network components installed${NC}"

# Comprehensive backup
print_section "Creating Backup"
BACKUP_DIR="/home/$(whoami)/network-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup all configurations
for item in /etc/netplan /etc/NetworkManager /etc/hostname /etc/hosts /etc/machine-id /var/lib/dbus/machine-id; do
    [ -e "$item" ] && sudo cp -r "$item" "$BACKUP_DIR/" 2>/dev/null || true
done
nmcli con show > "$BACKUP_DIR/connections.txt" 2>/dev/null || true
ip addr show > "$BACKUP_DIR/ip_addresses.txt"
echo -e "${GREEN}✅ Backup saved: $BACKUP_DIR${NC}"

# Clone prevention (default behavior)
if [ "$CLONE_PREVENTION" = true ]; then
    print_section "Clone Prevention Configuration"
    
    # Generate unique hostname based on primary interface MAC
    if ip link show eno1 >/dev/null 2>&1; then
        PRIMARY_MAC=$(ip link show eno1 | awk '/ether/ {print $2}' | tr -d ':' | tail -c 6 | tr '[:lower:]' '[:upper:]')
        NEW_HOSTNAME="UC-${PRIMARY_MAC}"
    else
        # Fallback to any ethernet interface
        PRIMARY_MAC=$(ip -o link show | awk '/ether/ {print $4}' | head -1 | tr -d ':' | tail -c 6 | tr '[:lower:]' '[:upper:]')
        NEW_HOSTNAME="UC-${PRIMARY_MAC:-RANDOM}"
    fi
    
    echo "Setting unique hostname: $NEW_HOSTNAME"
    sudo hostnamectl set-hostname "$NEW_HOSTNAME"
    
    # Update hosts file
    sudo sed -i '/^127\.0\.1\.1/d' /etc/hosts
    echo "127.0.1.1    $NEW_HOSTNAME" | sudo tee -a /etc/hosts >/dev/null
    
    # Generate new machine IDs
    echo "Generating new machine IDs..."
    sudo rm -f /etc/machine-id /var/lib/dbus/machine-id
    sudo systemd-machine-id-setup
    sudo ln -sf /etc/machine-id /var/lib/dbus/machine-id
    
    # Remove ALL existing network connections (including WiFi)
    echo "Removing all saved network profiles..."
    nmcli -t -f UUID con show 2>/dev/null | while read -r uuid; do
        sudo nmcli con delete "$uuid" 2>/dev/null || true
    done
    
    echo -e "${GREEN}✅ Clone prevention configured${NC}"
else
    echo -e "${YELLOW}⚠️ Clone prevention disabled - keeping existing identity${NC}"
fi

# Clean up network configurations
print_section "Cleaning Network Configurations"

# Remove only non-Docker connections if not already done
if [ "$CLONE_PREVENTION" = false ]; then
    nmcli -t -f UUID,NAME con show 2>/dev/null | while IFS=: read -r uuid name; do
        if [[ ! "$name" =~ ^(docker|veth|br-) ]]; then
            echo "  Removing: $name"
            sudo nmcli con delete "$uuid" 2>/dev/null || true
        fi
    done
fi

# Clean up old netplan files
sudo find /etc/netplan -name "*.yaml" -not -name "*docker*" -delete 2>/dev/null || true
echo -e "${GREEN}✅ Cleaned old configurations${NC}"

# Configure NetworkManager to ignore Docker but show IP info
print_section "NetworkManager Configuration"
sudo tee /etc/NetworkManager/conf.d/10-uc-production.conf >/dev/null <<'EOF'
[main]
plugins=keyfile
dhcp=internal
# Prevent auto-creation of connections
no-auto-default=*

[keyfile]
# Don't ignore any devices at this level
unmanaged-devices=interface-name:veth*;interface-name:docker*;interface-name:br-*;interface-name:virbr*

[device]
# Manage only real hardware
match-device=type:ethernet,!interface-name:veth*,!interface-name:docker*,!interface-name:br-*
match-device=type:wifi

[connection]
# Stable connection IDs
connection.stable-id=${DEVICE}
# Use MAC-based DHCP client ID
ipv4.dhcp-client-id=mac
ipv6.dhcp-duid=ll

[connectivity]
# Enable for KDE to show connection status
enabled=true
uri=http://connectivity-check.ubuntu.com/
interval=300

[logging]
# Moderate logging
level=INFO
domains=CORE,DEVICE,ETHER,WIFI,DHCP4,DHCP6
EOF

# DHCP configuration for UniFi
sudo tee /etc/NetworkManager/conf.d/20-dhcp-unifi.conf >/dev/null <<EOF
[ipv4]
# Send unique hostname to DHCP server
dhcp-send-hostname=true
dhcp-hostname=$(hostname)

[connection]
# Each interface gets unique identity
ipv4.dhcp-client-id=mac
EOF

# Create minimal netplan
print_section "Creating Netplan Configuration"
sudo tee /etc/netplan/01-network-manager.yaml >/dev/null <<'EOF'
# UnicornCommander Network Configuration
# Managed by NetworkManager
network:
  version: 2
  renderer: NetworkManager
EOF

sudo chmod 600 /etc/netplan/01-network-manager.yaml

# Disable systemd-networkd
print_section "Disabling systemd-networkd"
sudo systemctl stop systemd-networkd 2>/dev/null || true
sudo systemctl disable systemd-networkd 2>/dev/null || true
sudo systemctl mask systemd-networkd 2>/dev/null || true

# Apply configuration
print_section "Applying Network Configuration"
echo -e "${YELLOW}⚠️ Network will restart briefly${NC}"
[ -n "$SSH_CONNECTION" ] && echo -e "${YELLOW}   SSH users may need to reconnect${NC}" && sleep 5

sudo netplan generate
sudo netplan apply
sudo systemctl enable NetworkManager
sudo systemctl restart NetworkManager

# Wait for NetworkManager
print_section "Waiting for NetworkManager"
for i in {1..20}; do 
    if nmcli general status >/dev/null 2>&1; then
        echo -e "${GREEN}✅ NetworkManager ready${NC}"
        break
    fi
    sleep 1
    echo -n "."
done
echo

# Create network connections
print_section "Creating Network Connections"

# Function to safely create connections
create_ethernet_connection() {
    local iface=$1
    local name=$2
    local priority=$3
    local is_primary=$4
    
    if ! ip link show "$iface" >/dev/null 2>&1; then
        echo "  Interface $iface not found, skipping..."
        return
    fi
    
    echo "Creating connection: $name"
    
    # Base connection arguments
    local args=(
        type ethernet
        ifname "$iface"
        con-name "$name"
        connection.autoconnect yes
        connection.autoconnect-priority "$priority"
        ipv4.method auto
        ipv4.dhcp-hostname "$(hostname)"
        ipv4.dhcp-send-hostname yes
        ipv6.method auto
        ipv6.addr-gen-mode stable-privacy
    )
    
    # Add secondary interface settings
    if [ "$is_primary" = "false" ]; then
        args+=(
            ipv4.never-default yes
            ipv4.route-metric 200
            ipv4.dhcp-hostname "$(hostname)-secondary"
        )
    fi
    
    sudo nmcli con add "${args[@]}" 2>/dev/null || echo "  Failed to create $name"
}

# Create connections
create_ethernet_connection eno1 "Primary Network" 100 true
create_ethernet_connection enp3s0 "Secondary Network" 50 false

# WiFi template
if ip link show wlan0 >/dev/null 2>&1; then
    echo "Creating WiFi template..."
    sudo nmcli con add type wifi ifname wlan0 con-name "WiFi-Template" ssid "CHANGE-ME" \
        connection.autoconnect no \
        wifi.hidden no \
        ipv4.method auto \
        ipv4.dhcp-hostname "$(hostname)-wifi" \
        ipv6.method auto 2>/dev/null || true
fi

# Activate primary connection
print_section "Activating Primary Network"
sudo nmcli con up "Primary Network" 2>/dev/null || {
    echo -e "${YELLOW}⚠️ Trying fallback activation...${NC}"
    sudo nmcli device connect eno1 2>/dev/null || true
}

# Configure KDE6 integration
print_section "Configuring KDE6 Integration"

# KDE network management settings
mkdir -p ~/.config
cat > ~/.config/networkmanagementrc <<'EOF'
[General]
ManageVirtualConnections=false

[Notifications]
DeviceStateChangedNotification=false
EOF

# Create first-boot service for cloned systems
print_section "Creating First-Boot Service"
sudo tee /usr/local/bin/uc-first-boot.sh >/dev/null <<'EOF'
#!/bin/bash
# UnicornCommander First Boot Configuration

MARKER="/var/lib/uc-first-boot-complete"
[ -f "$MARKER" ] && exit 0

echo "Running first boot configuration..."

# Ensure connections are active
nmcli con up "Primary Network" 2>/dev/null || nmcli device connect eno1 2>/dev/null || true

# Regenerate SSH keys if missing
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    dpkg-reconfigure openssh-server
fi

touch "$MARKER"
echo "First boot complete - $(hostname)"
EOF

sudo chmod +x /usr/local/bin/uc-first-boot.sh

sudo tee /etc/systemd/system/uc-first-boot.service >/dev/null <<'EOF'
[Unit]
Description=UnicornCommander First Boot
After=network-pre.target
Before=NetworkManager.service
ConditionPathExists=!/var/lib/uc-first-boot-complete

[Service]
Type=oneshot
ExecStart=/usr/local/bin/uc-first-boot.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable uc-first-boot.service

# Verification
print_section "Network Status Verification"

echo -e "${BLUE}Active Connections:${NC}"
nmcli -t -f NAME,TYPE,DEVICE,STATE con show --active | grep -v docker | column -t -s ':'

echo -e "\n${BLUE}Device Status:${NC}"
nmcli -t -f DEVICE,TYPE,STATE dev | grep -E "eno1|enp3s0|wlan0" | column -t -s ':'

echo -e "\n${BLUE}IP Configuration:${NC}"
ip -4 addr show | grep -E "eno1|enp3s0|inet " | grep -v "127.0.0.1\|docker\|br-"

# Check for IP conflicts
echo -e "\n${BLUE}Checking for duplicate IPs:${NC}"
DUPE_IPS=$(ip -4 addr show | grep inet | grep -v "127.0.0.1\|172.17\|172.18" | awk '{print $2}' | cut -d/ -f1 | sort | uniq -d)
if [ -n "$DUPE_IPS" ]; then
    echo -e "${RED}⚠️ WARNING: Duplicate IPs detected: $DUPE_IPS${NC}"
else
    echo -e "${GREEN}✅ No duplicate IPs detected${NC}"
fi

# Create rollback script
print_section "Creating Rollback Script"
cat <<'ROLLBACK' | sudo tee "$BACKUP_DIR/rollback.sh" >/dev/null
#!/bin/bash
# Network Configuration Rollback
set -e

echo "Rolling back network configuration..."
echo "Restoring from: BACKUP_DIR_PLACEHOLDER"

# Restore files
for item in hostname hosts machine-id netplan NetworkManager; do
    if [ -e "BACKUP_DIR_PLACEHOLDER/$item" ]; then
        sudo cp -rf "BACKUP_DIR_PLACEHOLDER/$item" "/etc/$item" 2>/dev/null || true
    fi
done

# Restore machine-id to dbus
[ -f "BACKUP_DIR_PLACEHOLDER/machine-id" ] && sudo cp -f "BACKUP_DIR_PLACEHOLDER/machine-id" /var/lib/dbus/

# Restart services
sudo systemctl unmask systemd-networkd 2>/dev/null || true
sudo netplan generate 2>/dev/null || true
sudo netplan apply 2>/dev/null || true
sudo systemctl restart NetworkManager

echo "Rollback complete - reboot recommended"
ROLLBACK

# Replace placeholder with actual backup dir
sudo sed -i "s|BACKUP_DIR_PLACEHOLDER|$BACKUP_DIR|g" "$BACKUP_DIR/rollback.sh"
sudo chmod +x "$BACKUP_DIR/rollback.sh"

# Final summary
print_section "Setup Complete! 🎉"
echo -e "${GREEN}✅ Network cutover successful${NC}"
echo
echo -e "${BLUE}System Identity:${NC}"
echo "  Hostname: $(hostname)"
echo "  Primary IP: $(hostname -I | awk '{print $1}')"
echo "  Clone Prevention: $([ "$CLONE_PREVENTION" = true ] && echo "Active" || echo "Disabled")"
echo
echo -e "${BLUE}Network Management:${NC}"
echo "• Click network icon in KDE system tray"
echo "• Or System Settings → Connections"
echo "• Secondary network: nmcli con up 'Secondary Network'"
echo
echo -e "${BLUE}UniFi will see:${NC}"
echo "• $(hostname) - Primary ethernet"
echo "• $(hostname)-secondary - Secondary ethernet (when active)"
echo "• $(hostname)-wifi - WiFi (when configured)"
echo
echo -e "${YELLOW}Before creating system image:${NC}"
echo "1. Test all network functions"
echo "2. Run: $0 --pre-clone"
echo "3. Shutdown immediately after"
echo
echo -e "${YELLOW}If issues occur:${NC}"
echo "sudo $BACKUP_DIR/rollback.sh"
