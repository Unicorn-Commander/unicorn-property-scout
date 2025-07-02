# KDE Desktop Setup Script Documentation

## Overview
The `02-kde_desktop_setup.sh` script configures a complete KDE Plasma 6 desktop environment on Ubuntu Server 25.04, optimized for AMD 780M iGPU systems. This script handles the transition from Ubuntu Server's default networking to a KDE-compatible network management system.

## Prerequisites
- Ubuntu Server 25.04 with kernel 6.14+
- `01-hardware_ai_setup.sh` must be completed first
- Running as `ucadmin` user with sudo privileges
- Internet connection for package downloads

## Key Features

### Desktop Environment
- **KDE Plasma 6** with Wayland (default for Ubuntu 25.04)
- **SDDM** display manager with KDE integration
- **AMD 780M optimized** compositor settings
- **Papirus icon theme** and additional themes

### Network Management Transition
The script performs a critical network management transition:

#### From: Ubuntu Server Default
- **systemd-networkd** for basic network management
- **netplan** with systemd-networkd renderer
- **cloud-init** network configuration

#### To: KDE Network Management
- **NetworkManager** as the primary network service
- **plasma-nm** for KDE network GUI integration
- **netplan** configured to use NetworkManager renderer
- **Full KDE network interface control**

### Network Configuration Process

1. **Install NetworkManager and KDE Integration**
   ```bash
   sudo apt install -y network-manager plasma-nm network-manager-openvpn network-manager-vpnc
   ```

2. **Transition from systemd-networkd**
   - Stop and disable systemd-networkd services
   - Enable and start NetworkManager
   - Configure NetworkManager for KDE integration

3. **Configure netplan for NetworkManager**
   - Disable cloud-init network management
   - Create `/etc/netplan/01-network-manager-all.yaml` with NetworkManager renderer
   - Remove cloud-init netplan configuration
   - Apply netplan changes

4. **Result**: All network interfaces become manageable through KDE's network GUI

### Applications Installed

#### Development Tools
- **VS Code** with Microsoft repository
- **KDevelop** KDE's integrated development environment
- **Git, CMake, Qt6 development libraries**

#### Productivity Software
- **Firefox ESR** (non-Snap version)
- **LibreOffice** office suite
- **Thunderbird** email client
- **GIMP** image editor
- **Inkscape** vector graphics
- **OBS Studio** screen recording

#### KDE Applications
- **Konsole** terminal emulator
- **Dolphin** file manager
- **Kate** text editor
- **Spectacle** screenshot tool
- **Okular** document viewer
- **Ark** archive manager

## Network Interface Management

### Before Script Execution
```bash
# Interfaces show as "unmanaged" by NetworkManager
nmcli device status
# DEVICE    TYPE      STATE      CONNECTION
# eno1      ethernet  unmanaged  --
# wlp4s0    wifi      unmanaged  --
```

### After Script Execution
```bash
# All interfaces managed by NetworkManager
nmcli device status
# DEVICE    TYPE      STATE      CONNECTION
# eno1      ethernet  connected  Wired connection 1
# wlp4s0    wifi      connected  WiFi Network Name
```

## Configuration Files Created

### NetworkManager Integration
- `/etc/NetworkManager/conf.d/kde-integration.conf`
- `/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg`
- `/etc/netplan/01-network-manager-all.yaml`

### KDE Configuration
- `/home/ucladmin/.config/kwinrc` - AMD 780M optimized compositor
- `/home/ucladmin/.config/dolphinrc` - File manager settings
- `/home/ucladmin/.config/kglobalshortcutsrc` - Keyboard shortcuts

### Desktop Shortcuts
- `AI-Terminal.desktop` - Terminal with AI environment
- `VS-Code-AI.desktop` - VS Code with AI Python environment  
- `UnicornCommander.desktop` - UnicornCommander startup

## Usage

### Running the Script
```bash
# Ensure you're in the UC-1_Core directory
cd ~/UC-1/UC-1_Core

# Run as ucladmin user (not with sudo)
./02-kde_desktop_setup.sh
```

### Expected Output
The script provides color-coded output showing progress through each section:
- 🦄 **Purple**: Script title and major sections
- 🔵 **Blue**: Information and process descriptions  
- 🟢 **Green**: Success confirmations
- 🟡 **Yellow**: Warnings and important notes

## Network Troubleshooting

### Verifying Network Management
```bash
# Check NetworkManager status
systemctl status NetworkManager

# Verify interfaces are managed
nmcli device status

# Check network connections
nmcli connection show

# Test KDE network GUI
# Open KDE System Settings → Network → Connections
```

### Common Issues

#### Interface Still Unmanaged
```bash
# Check if netplan applied correctly
sudo netplan --debug apply

# Verify netplan configuration
cat /etc/netplan/01-network-manager-all.yaml

# Restart NetworkManager
sudo systemctl restart NetworkManager
```

#### Cloud-init Interference
```bash
# Verify cloud-init is disabled for networking
cat /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
# Should contain: network: {config: disabled}

# Check for remaining cloud-init netplan files
ls -la /etc/netplan/
# Should only show 01-network-manager-all.yaml
```

## Post-Installation

### System Ready Indicators
- KDE Plasma 6 desktop environment active
- All network interfaces visible in KDE network settings
- Firefox ESR available (non-Snap)
- Development environment configured
- AI environment integration complete

### Optional Reboot
```bash
# Recommended if hardware script configured NPU memory
sudo reboot
```

### Verification Commands
```bash
# Check hardware monitoring
uc-monitor

# Verify KDE network control
nmcli device status

# Test desktop shortcuts
ls -la ~/Desktop/
```

## Technical Details

### AMD 780M Optimizations
- **OpenGL Core Profile** enabled in KWin
- **Hardware acceleration** for compositor
- **Wayland** as default display server (Ubuntu 25.04 + Kernel 6.14)

### Network Architecture
```
Ubuntu Server 25.04 Default:
cloud-init → netplan → systemd-networkd → interfaces

After Script:
netplan (NetworkManager renderer) → NetworkManager → KDE plasma-nm GUI
```

### Security Configuration
- **UFW firewall** enabled with SSH access
- **Automatic updates** configured
- **User permissions** properly set for network management

## File Permissions
The script ensures proper ownership for all user configuration files:
```bash
chown -R ucladmin:ucladmin /home/ucladmin/.config /home/ucladmin/Desktop
```

## Integration with Other Scripts
- **Requires**: `01-hardware_ai_setup.sh` completion
- **Prepares for**: Theme customization and application deployment
- **AI Environment**: Integrates with Python AI environment if present