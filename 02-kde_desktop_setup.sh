#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${PURPLE}🦄 UnicornCommander KDE Desktop Setup${NC}"
echo -e "${BLUE}Installing KDE Plasma 6 with AMD 780M iGPU optimizations...${NC}"

# Ensure running as ucadmin (not root) with sudo privileges
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}⚠️ This script should NOT be run with sudo. Run as ucadmin user directly.${NC}"
    echo -e "${YELLOW}   Example: ./02-kde_desktop_setup.sh${NC}"
    exit 1
fi

if [ "$(whoami)" != "ucadmin" ]; then
    echo -e "${YELLOW}⚠️ This script must be run as ucadmin user. Current user: $(whoami)${NC}"
    exit 1
fi

if ! sudo -n true 2>/dev/null; then
    echo -e "${YELLOW}⚠️ Sudo privileges required. Run: sudo visudo and add 'ucadmin ALL=(ALL) NOPASSWD:ALL'${NC}"
    exit 1
fi

print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Check if hardware setup was completed (optional check)
print_section "Checking Prerequisites"
if [ ! -f "/usr/local/bin/uc-monitor" ]; then
    echo -e "${YELLOW}⚠️ Hardware setup not detected (01-hardware_ai_setup.sh not run)${NC}"
    echo -e "${BLUE}This script can run independently but you may want to run hardware setup later${NC}"
    echo -e "${BLUE}Continuing with KDE desktop installation...${NC}"
else
    echo -e "${GREEN}✅ Hardware setup detected - full UC-1 integration available${NC}"
fi

# Check if KDE is already installed
print_section "Checking Existing Installation"
if dpkg -l | grep -q "kde-plasma-desktop"; then
    echo -e "${GREEN}✅ KDE Plasma is already installed${NC}"
    echo -e "${BLUE}This script will update configuration and install any missing components...${NC}"
    KDE_ALREADY_INSTALLED=true
else
    echo -e "${BLUE}KDE Plasma not detected, performing fresh installation...${NC}"
    KDE_ALREADY_INSTALLED=false
fi

# Add Mozilla PPA for non-Snap Firefox (if not already configured)
print_section "Configuring Firefox Repository"
if [ ! -f /etc/apt/preferences.d/mozilla-firefox ]; then
    echo -e "${BLUE}Adding Mozilla PPA for Firefox ESR...${NC}"
    sudo add-apt-repository -y ppa:mozillateam/ppa
    echo -e "Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001" | sudo tee /etc/apt/preferences.d/mozilla-firefox
else
    echo -e "${GREEN}✅ Mozilla Firefox repository already configured${NC}"
fi

# Install development tools with improved VS Code repository handling
print_section "Installing Development Tools"
if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then
    echo -e "${BLUE}Adding Microsoft VS Code repository...${NC}"
    
    # Install prerequisites if not already present
    sudo apt-get update
    sudo apt-get install -y wget gpg
    
    # Clean up any existing GPG key files to avoid conflicts
    sudo rm -f /etc/apt/keyrings/packages.microsoft.gpg
    
    # Download and install Microsoft GPG key
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    rm -f packages.microsoft.gpg
    
    # Add VS Code repository
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    
    # Update package list
    sudo apt update
    echo -e "${GREEN}✅ Microsoft VS Code repository added${NC}"
else
    echo -e "${GREEN}✅ Microsoft VS Code repository already configured${NC}"
fi

# Install development packages
echo -e "${BLUE}Installing development packages...${NC}"
sudo apt install -y \
    code \
    git \
    cmake \
    extra-cmake-modules \
    qt6-declarative-dev \
    libplasma-dev

echo -e "${GREEN}✅ Development tools installed${NC}"

# Install KDE Plasma Desktop (minimal, no Snap packages)
print_section "Installing KDE Plasma Desktop"
sudo apt update
sudo apt install -y \
    kde-plasma-desktop \
    sddm \
    plasma-workspace \
    plasma-wayland-protocols \
    wayland-utils \
    firefox-esr \
    konsole \
    dolphin \
    kate \
    kcalc \
    kde-spectacle \
    okular \
    ark \
    vlc \
    gimp

echo -e "${GREEN}✅ KDE Plasma Desktop installed${NC}"

# Install additional KDE applications including archive support
print_section "Installing KDE Applications & Archive Support"
sudo apt install -y \
    kdevelop \
    kwrite \
    kfind \
    plasma-systemmonitor \
    kinfocenter \
    kcharselect \
    kruler \
    kcolorchooser \
    filelight \
    p7zip-full \
    p7zip-rar \
    unzip \
    zip \
    unrar \
    arj \
    lhasa

echo -e "${GREEN}✅ Archive support installed - Ark can handle .zip, .7z, .rar, .tar files${NC}"

# Configure SDDM for KDE Plasma 6 with Wayland (default on Ubuntu 25.04)
print_section "Configuring SDDM"
sudo mkdir -p /etc/sddm.conf.d

# Ubuntu 25.04 + Kernel 6.14 has native AMD 780M support - use Wayland by default
echo -e "${GREEN}✅ Ubuntu 25.04 with kernel 6.14 - using Wayland (KDE Plasma 6 default)${NC}"
DISPLAY_SERVER="wayland"

cat << EOF | sudo tee /etc/sddm.conf.d/kde_settings.conf
[General]
DisplayServer=${DISPLAY_SERVER}
Numlock=on

[Wayland]
SessionDir=/usr/share/wayland-sessions
CompositorCommand=kwin_wayland

[X11]
SessionDir=/usr/share/xsessions
EOF

# Enable SDDM service
sudo systemctl enable sddm
echo -e "${GREEN}✅ SDDM configured${NC}"

# Configure firewall (avoid conflicts with existing setup)
print_section "Configuring Firewall"
if ! systemctl is-enabled ufw >/dev/null 2>&1; then
    sudo apt install -y ufw
    sudo ufw --force enable
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    echo -e "${GREEN}✅ UFW firewall configured${NC}"
else
    echo -e "${GREEN}✅ UFW firewall already configured${NC}"
fi

# Configure automatic updates
print_section "Configuring Automatic Updates"
if ! dpkg -l | grep -q unattended-upgrades; then
    sudo apt install -y unattended-upgrades
    sudo dpkg-reconfigure -f noninteractive unattended-upgrades
    echo -e "${GREEN}✅ Automatic updates configured${NC}"
else
    echo -e "${GREEN}✅ Automatic updates already configured${NC}"
fi

# Install Papirus icon theme and additional themes
print_section "Installing Themes and Icons"
sudo apt install -y \
    papirus-icon-theme \
    breeze-cursor-theme \
    oxygen-cursor-theme \
    adwaita-icon-theme

echo -e "${GREEN}✅ Themes and icons installed${NC}"

# Configure terminal with Bash
print_section "Setting up Bash Terminal"
# Ensure bash is the default shell for ucadmin
if [ "$SHELL" != "/bin/bash" ]; then
    sudo chsh -s /bin/bash ucadmin
    echo -e "${GREEN}✅ Bash set as default shell for ucadmin${NC}"
else
    echo -e "${GREEN}✅ Bash already default shell${NC}"
fi

# Add neofetch for system info (if not already there)
sudo apt install -y neofetch
if ! grep -q "neofetch" /home/ucadmin/.bashrc 2>/dev/null; then
    echo 'neofetch' >> /home/ucadmin/.bashrc
    echo -e "${GREEN}✅ Added neofetch to .bashrc${NC}"
else
    echo -e "${GREEN}✅ neofetch already in .bashrc${NC}"
fi

# Create desktop directories
print_section "Setting up Desktop Environment"
mkdir -p /home/ucadmin/{Desktop,Documents,Downloads,Music,Pictures,Videos,Public,Templates}
xdg-user-dirs-update

# Configure Dolphin file manager with proper ownership
mkdir -p /home/ucadmin/.config
if [ ! -f /home/ucadmin/.config/dolphinrc ]; then
    echo -e "${BLUE}Configuring Dolphin file manager...${NC}"
    cat << EOF > /home/ucadmin/.config/dolphinrc
[General]
ShowFullPath=true
ShowSpaceInfo=true

[DetailsMode]
PreviewSize=32

[IconsMode]
PreviewSize=64
EOF
    chown ucadmin:ucadmin /home/ucadmin/.config/dolphinrc
    echo -e "${GREEN}✅ Dolphin configured${NC}"
else
    echo -e "${GREEN}✅ Dolphin already configured${NC}"
fi

# Ensure UC-1 workspace folders exist
mkdir -p /home/ucadmin/{UC-1,models,datasets,projects,scripts}
chown -R ucadmin:ucadmin /home/ucadmin/{UC-1,models,datasets,projects,scripts}

# Install additional productivity software
print_section "Installing Productivity Software"
sudo apt install -y \
    libreoffice \
    thunderbird \
    transmission-gtk \
    audacity \
    inkscape \
    obs-studio

echo -e "${GREEN}✅ Productivity software installed${NC}"

# Configure KDE for better performance with AMD 780M
print_section "Optimizing KDE Performance for AMD 780M"
if [ ! -f /home/ucadmin/.config/kwinrc ]; then
    echo -e "${BLUE}Configuring KWin compositor for AMD 780M...${NC}"
    cat << EOF > /home/ucadmin/.config/kwinrc
[Compositing]
Enabled=true
Backend=OpenGL
GLCore=true
HiddenPreviews=5
OpenGLIsUnsafe=false

[Effect-Overview]
BorderActivate=9

[Effect-DesktopGrid]
BorderActivate=1

[Wayland]
InputMethod=
VirtualKeyboard=false

[Xwayland]
Scale=1
EOF
    chown ucadmin:ucadmin /home/ucadmin/.config/kwinrc
    echo -e "${GREEN}✅ KWin configured for AMD 780M${NC}"
else
    echo -e "${GREEN}✅ KWin already configured${NC}"
fi

# Set up workspace shortcuts with proper ownership
print_section "Configuring KDE Shortcuts"
if [ ! -f /home/ucadmin/.config/kglobalshortcutsrc ]; then
    cat << EOF > /home/ucadmin/.config/kglobalshortcutsrc
[kwin]
Overview=Meta+Tab,Meta+Tab,Toggle Overview
ShowDesktopGrid=Meta+F8,Meta+F8,Show Desktop Grid
Walk Through Windows=Alt+Tab,Alt+Tab,Walk Through Windows
EOF
    chown ucadmin:ucadmin /home/ucadmin/.config/kglobalshortcutsrc
    echo -e "${GREEN}✅ KDE shortcuts configured${NC}"
else
    echo -e "${GREEN}✅ KDE shortcuts already configured${NC}"
fi

# Configure Plymouth for better boot experience
print_section "Configuring Boot Experience"
if dpkg -l | grep -q plymouth; then
    if ! dpkg -l | grep -q plymouth-theme-breeze; then
        sudo apt install -y plymouth-theme-breeze
        sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/breeze/breeze.plymouth 100
        sudo update-alternatives --set default.plymouth /usr/share/plymouth/themes/breeze/breeze.plymouth
        sudo update-initramfs -u
        echo -e "${GREEN}✅ Plymouth theme configured${NC}"
    else
        echo -e "${GREEN}✅ Plymouth theme already configured${NC}"
    fi
fi

# Create KDE-specific shortcuts for AI environment
print_section "Setting up AI Environment Integration"
if [ -d "/home/ucadmin/ai-env" ]; then
    # Create desktop shortcut for AI environment terminal
    cat << EOF > /home/ucadmin/Desktop/AI-Terminal.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=AI Development Terminal
Comment=Terminal with AI environment activated
Exec=konsole --hold -e bash -c "source ~/ai-env/bin/activate && echo '🦄 AI Environment Activated' && bash"
Icon=utilities-terminal
Terminal=false
Categories=Development;
EOF
    chmod +x /home/ucadmin/Desktop/AI-Terminal.desktop
    chown ucadmin:ucadmin /home/ucadmin/Desktop/AI-Terminal.desktop
    echo -e "${GREEN}✅ AI environment desktop shortcut created${NC}"
    
    # Create VS Code shortcut that uses AI environment
    cat << EOF > /home/ucadmin/Desktop/VS-Code-AI.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=VS Code (AI Environment)
Comment=VS Code with AI Python environment
Exec=bash -c "source ~/ai-env/bin/activate && code"
Icon=code
Terminal=false
Categories=Development;
EOF
    chmod +x /home/ucadmin/Desktop/VS-Code-AI.desktop
    chown ucadmin:ucadmin /home/ucadmin/Desktop/VS-Code-AI.desktop
    echo -e "${GREEN}✅ VS Code AI shortcut created${NC}"
else
    echo -e "${YELLOW}AI environment not found - skipping AI shortcuts${NC}"
fi

# Create UnicornCommander desktop shortcut
if [ -d "/home/ucadmin/UC-1/UC-1_Core" ] && [ -f "/home/ucadmin/UC-1/UC-1_Core/start.sh" ]; then
    cat << EOF > /home/ucadmin/Desktop/UnicornCommander.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=UnicornCommander
Comment=Start UnicornCommander stack
Exec=konsole --hold -e bash -c "cd ~/UC-1/UC-1_Core && ./start.sh"
Icon=applications-development
Terminal=false
Categories=Development;
EOF
    chmod +x /home/ucadmin/Desktop/UnicornCommander.desktop
    chown ucadmin:ucadmin /home/ucadmin/Desktop/UnicornCommander.desktop
    echo -e "${GREEN}✅ UnicornCommander desktop shortcut created${NC}"
else
    echo -e "${YELLOW}UnicornCommander not found - skipping UC shortcut${NC}"
fi

# Fix all file ownership in .config and Desktop
chown -R ucadmin:ucadmin /home/ucadmin/.config /home/ucadmin/Desktop 2>/dev/null || true

# Install NetworkManager and KDE integration packages
print_section "Preparing Network Management"
echo -e "${BLUE}Installing NetworkManager and KDE integration packages...${NC}"
sudo apt install -y network-manager plasma-nm

# Add ucadmin to netdev group for network management
if ! groups ucadmin | grep -q netdev; then
    sudo usermod -a -G netdev ucadmin
    echo -e "${GREEN}✅ Added ucadmin to netdev group${NC}"
else
    echo -e "${GREEN}✅ ucadmin already in netdev group${NC}"
fi

# Prepare NetworkManager configuration files
print_section "Preparing NetworkManager Configuration"
sudo mkdir -p /etc/NetworkManager/conf.d

# Create NetworkManager configuration for stable DHCP behavior
if [ ! -f /etc/NetworkManager/conf.d/kde-integration.conf ]; then
    cat << 'EOF' | sudo tee /etc/NetworkManager/conf.d/kde-integration.conf
[main]
plugins=keyfile
dhcp=internal
dns=default

[connection]
# Use stable connection-specific DHCP client identifier
dhcp-client-id=stable

[keyfile]
unmanaged-devices=none

[device]
wifi.scan-rand-mac-address=yes
EOF
    echo -e "${GREEN}✅ NetworkManager configuration prepared${NC}"
else
    echo -e "${GREEN}✅ NetworkManager already configured${NC}"
fi

# Final system summary
print_section "KDE Desktop Setup Complete"

echo -e "${GREEN}🎉 KDE Desktop setup complete!${NC}"
echo -e "${BLUE}Desktop features installed:${NC}"
echo -e "  - KDE Plasma 6 with Wayland (Ubuntu 25.04 default)"
echo -e "  - Firefox ESR (non-Snap version)"
echo -e "  - Development tools (KDevelop, VS Code)"
echo -e "  - Archive support (Ark with .zip, .7z, .rar, .tar support)"
echo -e "  - Productivity apps (LibreOffice, GIMP, VLC, etc.)"
echo -e "  - AMD 780M optimized compositor settings"
echo -e "  - AI environment integration (if available)"
echo -e "  - UnicornCommander desktop shortcuts (if available)"
echo -e ""
echo -e "${BLUE}Archive file support:${NC}"
echo -e "  - Ark archive manager (default KDE6 app)"
echo -e "  - Supports: .zip, .7z, .rar, .tar, .gz, .bz2, .xz files"
echo -e "  - Right-click any archive → 'Extract Here'"
echo -e "  - Create archives: Select files → Right-click → 'Compress'"
echo -e ""
echo -e "${BLUE}Network configuration:${NC}"
echo -e "  - NetworkManager packages installed"
echo -e "  - KDE network widget integration ready"
echo -e "  - Configuration files prepared"
echo -e "  - Ready for network transition script"
echo -e ""
echo -e "${BLUE}Current configuration:${NC}"
echo -e "  - Display server: Wayland (KDE Plasma 6 default)"
echo -e "  - Ubuntu 25.04 + Kernel 6.14 native AMD support"
echo -e "  - Login manager: SDDM"
echo -e "  - Compositor: KWin with AMD 780M optimizations"
echo -e ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  - Reboot to activate KDE desktop: ${GREEN}sudo reboot${NC}"
echo -e "  - After reboot, log in to KDE Plasma 6"
echo -e "  - Run 'uc-monitor' to check hardware status"
echo -e "  - Use desktop shortcuts for development"
echo -e "  - Test archive support with any .zip file"
echo -e "  - Run network transition script separately"
echo -e ""
echo -e "${GREEN}✅ Script completed successfully - safe to run multiple times!${NC}"
