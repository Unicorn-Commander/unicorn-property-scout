#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

# Script metadata
SCRIPT_VERSION="1.2"
SCRIPT_NAME="UC-1 System Preparation"
LOG_FILE="/home/ucadmin/uc1-system-prep.log"

echo -e "${PURPLE}🦄 UC-1 System Preparation for Ryzen 9 8945HS + 780M Graphics${NC}"
echo -e "${BLUE}Version $SCRIPT_VERSION - Preparing Ubuntu 25.04 + KDE6 for optimal AI performance...${NC}"
echo -e "${BLUE}Log file: $LOG_FILE${NC}"

# Logging function
log_and_print() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Error handling function
handle_error() {
    echo -e "${RED}❌ Error occurred in ${BASH_SOURCE[1]}:${BASH_LINENO[0]}${NC}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}Check log file: $LOG_FILE${NC}"
    exit 1
}

trap 'handle_error' ERR

# Initialize log
echo "=== UC-1 System Preparation Log ===" > "$LOG_FILE"
echo "Started: $(date)" >> "$LOG_FILE"

# Ensure running as ucadmin with sudo privileges
if [ "$(whoami)" != "ucadmin" ]; then
    echo -e "${YELLOW}⚠️ This script must be run as ucadmin. Exiting...${NC}"
    exit 1
fi

if ! sudo -n true 2>/dev/null; then
    echo -e "${YELLOW}⚠️ Sudo privileges required. Run: sudo visudo and add 'ucadmin ALL=(ALL) NOPASSWD:ALL'${NC}"
    exit 1
fi

print_section() {
    echo -e "\n${BLUE}[$1]${NC}"
    echo "=== $1 ===" >> "$LOG_FILE"
}

# Prerequisites checking
print_section "Verifying System Prerequisites"
log_and_print "${BLUE}Checking OS version and architecture...${NC}"

# Check Ubuntu version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_VERSION="$VERSION_ID"
    log_and_print "${BLUE}Detected: $PRETTY_NAME${NC}"
    
    if [[ ! "$ID" == "ubuntu" ]]; then
        log_and_print "${RED}❌ This script is designed for Ubuntu. Detected: $ID${NC}"
        exit 1
    fi
    
    # Check if version is 24.04 or newer (25.04 preferred)
    if [[ $(echo "$OS_VERSION >= 24.04" | bc 2>/dev/null || echo "0") -eq 0 ]]; then
        log_and_print "${YELLOW}⚠️ Ubuntu 24.04+ recommended. You have: $OS_VERSION${NC}"
        read -p "Continue anyway? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
else
    log_and_print "${RED}❌ Cannot detect OS version${NC}"
    exit 1
fi

# Check architecture
ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" ]]; then
    log_and_print "${RED}❌ This script requires x86_64 architecture. Detected: $ARCH${NC}"
    exit 1
fi
log_and_print "${GREEN}✅ Architecture: $ARCH${NC}"

# Check available disk space (need at least 50GB total for builds)
ROOT_SPACE_KB=$(df / | tail -1 | awk '{print $4}')
ROOT_SPACE_GB=$((ROOT_SPACE_KB / 1024 / 1024))
HOME_SPACE_KB=$(df /home | tail -1 | awk '{print $4}')
HOME_SPACE_GB=$((HOME_SPACE_KB / 1024 / 1024))

log_and_print "${BLUE}Disk space check:${NC}"
log_and_print "${BLUE}  Root (/): ${ROOT_SPACE_GB}GB available${NC}"
log_and_print "${BLUE}  Home (/home): ${HOME_SPACE_GB}GB available${NC}"

if [ $ROOT_SPACE_GB -lt 10 ] || [ $HOME_SPACE_GB -lt 30 ]; then
    log_and_print "${RED}❌ Insufficient disk space for source builds${NC}"
    log_and_print "${YELLOW}Required: 10GB+ on root, 30GB+ on home${NC}"
    exit 1
fi
log_and_print "${GREEN}✅ Sufficient disk space available${NC}"

# Check current memory limitation
print_section "Checking Memory Configuration"
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))

log_and_print "${BLUE}Current detected RAM: ${TOTAL_RAM_GB}GB${NC}"

if [ $TOTAL_RAM_GB -lt 64 ]; then
    log_and_print "${RED}❌ Critical: Only ${TOTAL_RAM_GB}GB RAM detected. Expected 96GB+${NC}"
    log_and_print "${YELLOW}This appears to be caused by the memmap=1GG kernel parameter.${NC}"
    
    # Check for memmap parameter
    if grep -q "memmap=" /proc/cmdline; then
        MEMMAP_PARAM=$(grep -o "memmap=[^ ]*" /proc/cmdline || true)
        log_and_print "${YELLOW}Found memmap parameter in kernel command line: $MEMMAP_PARAM${NC}"
        
        print_section "Fixing GRUB Configuration"
        
        # Create backup with verification
        BACKUP_FILE="/etc/default/grub.backup.$(date +%Y%m%d_%H%M%S)"
        log_and_print "${BLUE}Backing up current GRUB configuration to: $BACKUP_FILE${NC}"
        
        if sudo cp /etc/default/grub "$BACKUP_FILE"; then
            log_and_print "${GREEN}✅ GRUB backup created successfully${NC}"
        else
            log_and_print "${RED}❌ Failed to create GRUB backup${NC}"
            exit 1
        fi
        
        # Show current GRUB config
        log_and_print "${BLUE}Current GRUB configuration:${NC}"
        grep "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub | log_and_print
        
        # Remove memmap parameter
        log_and_print "${BLUE}Removing memmap parameter from GRUB...${NC}"
        sudo sed -i 's/memmap=[^ ]*//g' /etc/default/grub
        sudo sed -i 's/  / /g' /etc/default/grub  # Clean up double spaces
        
        # Remove any existing amdgpu parameters
        log_and_print "${BLUE}Removing existing amdgpu parameters...${NC}"
        sudo sed -i 's/amdgpu\.[^ ]*//g' /etc/default/grub
        
        # Add optimized parameters for Ryzen 9 8945HS + 780M
        log_and_print "${BLUE}Adding optimized parameters for Ryzen 9 8945HS + 780M...${NC}"
        OPTIMIZED_PARAMS="amd_pstate=active amdgpu.gfxoff=0 amdgpu.runpm=0 amdgpu.dpm=1 amdgpu.ppfeaturemask=0xffffffff"
        
        if grep -q "GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub; then
            sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"\\([^\"]*\\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\\1 $OPTIMIZED_PARAMS\"/" /etc/default/grub
        else
            echo "GRUB_CMDLINE_LINUX_DEFAULT=\"$OPTIMIZED_PARAMS\"" | sudo tee -a /etc/default/grub
        fi
        
        # Verify the changes
        log_and_print "${BLUE}Updated GRUB configuration:${NC}"
        grep "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub | log_and_print
        
        # Update GRUB bootloader
        log_and_print "${BLUE}Updating GRUB bootloader...${NC}"
        if sudo update-grub; then
            log_and_print "${GREEN}✅ GRUB bootloader updated successfully${NC}"
        else
            log_and_print "${RED}❌ Failed to update GRUB bootloader${NC}"
            log_and_print "${YELLOW}Restoring backup...${NC}"
            sudo cp "$BACKUP_FILE" /etc/default/grub
            exit 1
        fi
        
        log_and_print "${GREEN}✅ GRUB configuration updated${NC}"
        log_and_print "${YELLOW}⚠️ REBOOT REQUIRED to activate changes${NC}"
        log_and_print "${BLUE}After reboot, you should see ~96GB RAM available${NC}"
        
        # Create a status file to track progress
        echo "grub_fixed=$(date)" > /home/ucadmin/.uc1-prep-status
        chown ucadmin:ucadmin /home/ucadmin/.uc1-prep-status
        
        read -p "Would you like to reboot now? (y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_and_print "${BLUE}Rebooting in 10 seconds... (Ctrl+C to cancel)${NC}"
            sleep 10
            sudo reboot
        else
            log_and_print "${YELLOW}Please reboot manually before running the next script${NC}"
            log_and_print "${BLUE}After reboot, re-run this script to continue preparation${NC}"
            exit 0
        fi
    else
        log_and_print "${YELLOW}No memmap parameter found, but RAM is still low.${NC}"
        log_and_print "${YELLow}Check BIOS settings to ensure full RAM is enabled${NC}"
        log_and_print "${YELLOW}This may affect PyTorch build performance${NC}"
        
        read -p "Continue with low RAM? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
else
    log_and_print "${GREEN}✅ RAM configuration looks good (${TOTAL_RAM_GB}GB detected)${NC}"
fi

# Verify GPU detection
print_section "Verifying GPU Detection"
GPU_INFO=$(lspci | grep -i vga | head -1 || echo "No VGA device found")
log_and_print "${BLUE}Detected GPU: $GPU_INFO${NC}"

# More comprehensive GPU detection
if echo "$GPU_INFO" | grep -qi "780M\|Phoenix\|Radeon.*Graphics"; then
    log_and_print "${GREEN}✅ AMD integrated graphics detected${NC}"
    GPU_DETECTED=true
elif echo "$GPU_INFO" | grep -qi "AMD\|Radeon"; then
    log_and_print "${YELLOW}⚠️ AMD GPU detected but not 780M. Continuing anyway...${NC}"
    GPU_DETECTED=true
else
    log_and_print "${YELLOW}⚠️ Expected AMD 780M, please verify GPU detection${NC}"
    log_and_print "${BLUE}Detected: $GPU_INFO${NC}"
    GPU_DETECTED=false
fi

# Check AMDGPU driver status
if lsmod | grep -q amdgpu; then
    log_and_print "${GREEN}✅ AMDGPU driver loaded${NC}"
    
    # Check VRAM allocation - try multiple card locations
    VRAM_TOTAL=""
    for card_path in /sys/class/drm/card*/device/mem_info_vram_total; do
        if [ -f "$card_path" ]; then
            VRAM_TOTAL=$(cat "$card_path" 2>/dev/null)
            break
        fi
    done
    
    if [ -n "$VRAM_TOTAL" ] && [ "$VRAM_TOTAL" -gt 0 ]; then
        VRAM_GB=$((VRAM_TOTAL / 1024 / 1024 / 1024))
        log_and_print "${BLUE}Current VRAM allocation: ${VRAM_GB}GB${NC}"
        if [ $VRAM_GB -lt 8 ]; then
            log_and_print "${YELLOW}⚠️ Consider increasing VRAM allocation in BIOS to 16GB for better performance${NC}"
            log_and_print "${BLUE}This improves PyTorch performance on integrated graphics${NC}"
        else
            log_and_print "${GREEN}✅ Good VRAM allocation: ${VRAM_GB}GB${NC}"
        fi
    else
        log_and_print "${YELLOW}⚠️ Could not determine VRAM allocation${NC}"
    fi
    
    # Check GPU frequency and power management
    if [ -f /sys/class/drm/card1/device/pp_dpm_sclk ]; then
        log_and_print "${BLUE}GPU frequency states available${NC}"
    fi
else
    log_and_print "${YELLOW}⚠️ AMDGPU driver not loaded${NC}"
    log_and_print "${BLUE}This may affect GPU acceleration for PyTorch${NC}"
fi

# Save GPU status to status file
if [ "$GPU_DETECTED" = true ]; then
    echo "gpu_detected=true" >> /home/ucadmin/.uc1-prep-status
else
    echo "gpu_detected=false" >> /home/ucadmin/.uc1-prep-status
fi

# Prepare package system
print_section "Preparing Package System"
log_and_print "${BLUE}Verifying repository compatibility...${NC}"

# Check for deadsnakes PPA and warn (but don't remove)
if [ -f /etc/apt/sources.list.d/deadsnakes-*.list ]; then
    log_and_print "${YELLOW}⚠️ deadsnakes PPA detected${NC}"
    log_and_print "${BLUE}  This PPA may not be compatible with Ubuntu 25.04${NC}"
    log_and_print "${BLUE}  Use with caution - remove if you encounter Python conflicts${NC}"
    log_and_print "${BLUE}  You can remove it later with: ${GREEN}sudo add-apt-repository --remove ppa:deadsnakes/ppa${NC}"
fi

# Update package cache with retry logic
log_and_print "${BLUE}Updating package lists...${NC}"
RETRY_COUNT=3
for i in $(seq 1 $RETRY_COUNT); do
    if sudo apt update --fix-missing; then
        log_and_print "${GREEN}✅ Package lists updated successfully${NC}"
        break
    elif [ $i -eq $RETRY_COUNT ]; then
        log_and_print "${RED}❌ Failed to update package lists after $RETRY_COUNT attempts${NC}"
        exit 1
    else
        log_and_print "${YELLOW}⚠️ Attempt $i failed, retrying...${NC}"
        sleep 5
    fi
done

# Install essential build dependencies
print_section "Installing Essential Dependencies"
log_and_print "${BLUE}Installing core build tools and dependencies...${NC}"

CORE_PACKAGES=(
    build-essential
    cmake
    ninja-build
    git
    wget
    curl
    pkg-config
    ccache
    software-properties-common
    apt-transport-https
    ca-certificates
    gnupg
    lsb-release
    bc
    pciutils
    linux-headers-$(uname -r)
)

# Install with progress tracking
log_and_print "${BLUE}Installing ${#CORE_PACKAGES[@]} core packages...${NC}"
if sudo apt install -y "${CORE_PACKAGES[@]}"; then
    log_and_print "${GREEN}✅ Core build tools installed successfully${NC}"
else
    log_and_print "${RED}❌ Failed to install core build tools${NC}"
    exit 1
fi

# Install GCC-11 specifically (required for PyTorch build)
print_section "Installing GCC-11 Compiler"
log_and_print "${BLUE}Installing GCC-11 for PyTorch compatibility...${NC}"
if sudo apt install -y gcc-11 g++-11; then
    log_and_print "${GREEN}✅ GCC-11 installed successfully${NC}"
    echo "gcc11_installed=$(date)" >> /home/ucadmin/.uc1-prep-status
else
    log_and_print "${YELLOW}⚠️ Failed to install GCC-11, will use default compiler${NC}"
fi

# Verify key tools are available
for tool in gcc g++ cmake ninja git; do
    if command -v $tool >/dev/null 2>&1; then
        VERSION=$($tool --version 2>/dev/null | head -1 || echo "version unknown")
        log_and_print "${GREEN}✅ $tool: $VERSION${NC}"
    else
        log_and_print "${RED}❌ $tool not found after installation${NC}"
        exit 1
    fi
done

# Install Python build dependencies
log_and_print "${BLUE}Installing Python build dependencies...${NC}"
PYTHON_PACKAGES=(
    zlib1g-dev
    libncurses5-dev
    libgdbm-dev
    libnss3-dev
    libssl-dev
    libreadline-dev
    libffi-dev
    libsqlite3-dev
    libbz2-dev
    liblzma-dev
    tk-dev
    uuid-dev
    libexpat1-dev
    libmpdec-dev
)

if sudo apt install -y "${PYTHON_PACKAGES[@]}"; then
    log_and_print "${GREEN}✅ Python build dependencies installed successfully${NC}"
    echo "dependencies_installed=$(date)" >> /home/ucadmin/.uc1-prep-status
else
    log_and_print "${RED}❌ Failed to install Python build dependencies${NC}"
    exit 1
fi

# Install additional dependencies for PyTorch ROCm build
print_section "Installing PyTorch Build Dependencies"
log_and_print "${BLUE}Installing additional libraries for PyTorch ROCm build...${NC}"

PYTORCH_DEPS=(
    libblis-dev
    libblis-openmp-dev
    libopenblas-dev
    libopenblas-openmp-dev
    liblapack-dev
    libprotobuf-dev
    protobuf-compiler
    libnuma-dev
    libboost-all-dev
)

if sudo apt install -y "${PYTORCH_DEPS[@]}"; then
    log_and_print "${GREEN}✅ PyTorch build dependencies installed${NC}"
    echo "pytorch_deps_installed=$(date)" >> /home/ucadmin/.uc1-prep-status
else
    log_and_print "${YELLOW}⚠️ Some PyTorch dependencies failed to install${NC}"
fi

# Create workspace directories
print_section "Creating Workspace Directories"
WORKSPACE_DIRS=(
    "/home/ucadmin/models"
    "/home/ucadmin/datasets"
    "/home/ucadmin/projects"
    "/home/ucadmin/scripts"
    "/home/ucadmin/build-cache"
    "/home/ucadmin/build-temp"
    "/home/ucadmin/UC-1/build-scripts"
)

for dir in "${WORKSPACE_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        if mkdir -p "$dir" && chown ucadmin:ucadmin "$dir"; then
            log_and_print "${BLUE}Created $dir${NC}"
        else
            log_and_print "${RED}❌ Failed to create $dir${NC}"
            exit 1
        fi
    else
        log_and_print "${GREEN}✅ $dir already exists${NC}"
    fi
done

# Set up ccache for faster rebuilds
print_section "Configuring Build Optimization"
export CCACHE_DIR="/home/ucadmin/build-cache/ccache"
if mkdir -p "$CCACHE_DIR" && chown ucadmin:ucadmin "$CCACHE_DIR"; then
    log_and_print "${BLUE}Setting up ccache...${NC}"
    if ccache --set-config=max_size=10G && ccache --set-config=compression=true; then
        CCACHE_VERSION=$(ccache --version | head -1)
        log_and_print "${GREEN}✅ ccache configured: $CCACHE_VERSION${NC}"
        log_and_print "${BLUE}Cache size: 10GB, compression enabled${NC}"
        echo "ccache_configured=$(date)" >> /home/ucadmin/.uc1-prep-status
    else
        log_and_print "${YELLOW}⚠️ ccache configuration failed but continuing...${NC}"
    fi
else
    log_and_print "${RED}❌ Failed to set up ccache directory${NC}"
    exit 1
fi

# Create system monitoring utility
print_section "Creating System Utilities"
cat << 'EOF' | sudo tee /usr/local/bin/uc-sysinfo
#!/bin/bash
echo "🦄 UC-1 System Information"
echo "========================="
echo "Hardware:"
echo "  CPU: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)"
echo "  RAM: $(free -h | grep 'Mem:' | awk '{print $2}') total, $(free -h | grep 'Mem:' | awk '{print $7}') available"
echo "  GPU: $(lspci | grep -i vga | head -1 | cut -d':' -f3 | xargs)"
echo ""
echo "GPU Memory:"
VRAM_TOTAL=""
for card_path in /sys/class/drm/card*/device/mem_info_vram_total; do
    if [ -f "$card_path" ]; then
        VRAM_TOTAL=$(cat "$card_path" 2>/dev/null)
        break
    fi
done

if [ -n "$VRAM_TOTAL" ] && [ "$VRAM_TOTAL" -gt 0 ]; then
    VRAM_USED=$(cat "$(dirname "$card_path")/mem_info_vram_used" 2>/dev/null || echo "0")
    VRAM_TOTAL_GB=$((VRAM_TOTAL / 1024 / 1024 / 1024))
    VRAM_USED_MB=$((VRAM_USED / 1024 / 1024))
    echo "  VRAM: ${VRAM_TOTAL_GB}GB total, ${VRAM_USED_MB}MB used"
else
    echo "  VRAM: Information not available"
fi
echo ""
echo "Storage:"
echo "  Root: $(df -h / | tail -1 | awk '{print $3"/"$2" ("$5" used)"}')"
echo "  Home: $(df -h /home | tail -1 | awk '{print $3"/"$2" ("$5" used)"}')"
echo "  Temp: $(df -h /tmp | tail -1 | awk '{print $3"/"$2" ("$5" used)"}')"
echo ""
echo "Services:"
echo "  Docker: $(systemctl is-active docker)"
EOF

if sudo chmod +x /usr/local/bin/uc-sysinfo; then
    log_and_print "${GREEN}✅ System utilities installed${NC}"
    echo "utilities_installed=$(date)" >> /home/ucadmin/.uc1-prep-status
else
    log_and_print "${YELLOW}⚠️ Failed to install system utilities${NC}"
fi

# Final summary and completion
print_section "System Preparation Complete"
echo "prep_completed=$(date)" >> /home/ucadmin/.uc1-prep-status
echo "script_version=$SCRIPT_VERSION" >> /home/ucadmin/.uc1-prep-status

log_and_print "${GREEN}🎉 UC-1 System preparation completed successfully!${NC}"
log_and_print ""
log_and_print "${BLUE}Summary of changes:${NC}"

# Read status file and show what was completed
if [ -f /home/ucadmin/.uc1-prep-status ]; then
    STATUS_FILE="/home/ucadmin/.uc1-prep-status"
    
    if grep -q "grub_fixed" "$STATUS_FILE"; then
        log_and_print "${GREEN}✅ GRUB configuration fixed for memory${NC}"
    fi
    
    if grep -q "dependencies_installed" "$STATUS_FILE"; then
        log_and_print "${GREEN}✅ Build dependencies installed${NC}"
    fi
    
    if grep -q "ccache_configured" "$STATUS_FILE"; then
        log_and_print "${GREEN}✅ Build optimization (ccache) configured${NC}"
    fi
    
    if grep -q "gpu_detected=true" "$STATUS_FILE"; then
        log_and_print "${GREEN}✅ AMD GPU detected and ready${NC}"
    elif grep -q "gpu_detected=false" "$STATUS_FILE"; then
        log_and_print "${YELLOW}⚠️ GPU detection needs verification${NC}"
    fi
    
    if grep -q "gcc11_installed" "$STATUS_FILE"; then
        log_and_print "${GREEN}✅ GCC-11 installed for PyTorch compatibility${NC}"
    fi
    
    if grep -q "pytorch_deps_installed" "$STATUS_FILE"; then
        log_and_print "${GREEN}✅ PyTorch build dependencies installed${NC}"
    fi
fi

log_and_print ""
log_and_print "${BLUE}System Information:${NC}"
log_and_print "${BLUE}  RAM: ${TOTAL_RAM_GB}GB detected${NC}"
log_and_print "${BLUE}  Disk Space: ${ROOT_SPACE_GB}GB (root), ${HOME_SPACE_GB}GB (home)${NC}"
log_and_print "${BLUE}  OS: $PRETTY_NAME${NC}"
log_and_print "${BLUE}  Architecture: $ARCH${NC}"

log_and_print ""
log_and_print "${BLUE}Next steps:${NC}"

# Check if reboot is needed
if grep -q "grub_fixed" /home/ucadmin/.uc1-prep-status 2>/dev/null; then
    log_and_print "${YELLOW}  1. REBOOT REQUIRED to activate memory fixes${NC}"
    log_and_print "${BLUE}  2. After reboot, verify RAM with: ${GREEN}uc-sysinfo${NC}"
    log_and_print "${BLUE}  3. Run: ${GREEN}./02-build-pytorch.sh${NC} to build optimized PyTorch"
else
    log_and_print "${BLUE}  1. Consider setting BIOS VRAM to 16GB for optimal performance${NC}"
    log_and_print "${BLUE}  2. Run: ${GREEN}./02-build-pytorch.sh${NC} to build optimized PyTorch"
    log_and_print "${BLUE}  3. Check system status: ${GREEN}uc-sysinfo${NC}"
fi

log_and_print ""
log_and_print "${BLUE}Logs and status:${NC}"
log_and_print "${BLUE}  Full log: $LOG_FILE${NC}"
log_and_print "${BLUE}  Status: /home/ucadmin/.uc1-prep-status${NC}"
log_and_print ""
log_and_print "${PURPLE}🦄 System ready for UC-1 source builds!${NC}"

# Final log entry
echo "=== System Preparation Completed Successfully ===" >> "$LOG_FILE"
echo "Completed: $(date)" >> "$LOG_FILE"
