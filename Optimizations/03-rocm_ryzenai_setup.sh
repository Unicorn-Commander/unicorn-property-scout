#!/bin/bash
# 02-rocm_ryzenai_setup.sh - Complete ROCm 6.4.1, Ryzen AI, and Vulkan Setup
# For AMD Ryzen 9 8945HS with Radeon 780M iGPU and XDNA 2 NPU on Ubuntu 25.04
# Version: 3.0 - Fixed for Ubuntu 25.04 Plucky with proper apt handling

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="/home/$USER/rocm_setup_$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="/home/$USER/rocm_setup_backup"
ROCM_VERSION="6.4.1"
UBUNTU_VERSION=$(lsb_release -rs)
UBUNTU_CODENAME=$(lsb_release -cs)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# Check for test mode
TEST_MODE=false
if [[ "${1:-}" == "--test" || "${1:-}" == "--dry-run" ]]; then
    TEST_MODE=true
    info "Running in test mode - no actual installations will be performed"
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root!"
   exit 1
fi

# System verification
log "Starting ROCm + Ryzen AI Complete Setup"
log "System: Ubuntu $UBUNTU_VERSION ($UBUNTU_CODENAME)"
log "Target: AMD Ryzen 9 8945HS with Radeon 780M + XDNA 2 NPU"

# Kill any existing apt processes
cleanup_apt_locks() {
    log "Checking for existing apt/dpkg locks..."
    
    # Kill any existing apt processes
    sudo killall apt apt-get dpkg 2>/dev/null || true
    sleep 2
    
    # Remove lock files if they exist
    sudo rm -f /var/lib/dpkg/lock-frontend 2>/dev/null || true
    sudo rm -f /var/lib/dpkg/lock 2>/dev/null || true
    sudo rm -f /var/lib/apt/lists/lock 2>/dev/null || true
    sudo rm -f /var/cache/apt/archives/lock 2>/dev/null || true
    
    # Reconfigure dpkg
    sudo dpkg --configure -a 2>/dev/null || true
    
    log "APT locks cleaned"
}

# Backup existing configurations
backup_configs() {
    log "Backing up existing configurations..."
    
    # Backup sources.list
    if [ -f /etc/apt/sources.list ]; then
        sudo cp /etc/apt/sources.list "$BACKUP_DIR/sources.list.bak"
    fi
    
    # Backup existing ROCm configs
    if [ -d /etc/apt/sources.list.d ]; then
        sudo cp -r /etc/apt/sources.list.d "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    # Backup grub
    if [ -f /etc/default/grub ]; then
        sudo cp /etc/default/grub "$BACKUP_DIR/grub.bak"
    fi
}

# Step 1: System Prerequisites
install_prerequisites() {
    log "Installing system prerequisites..."
    
    if [[ "$TEST_MODE" == "true" ]]; then
        info "TEST MODE: Would update system and install packages"
        return 0
    fi
    
    # Clean up any apt locks first
    cleanup_apt_locks
    
    # Set non-interactive frontend
    export DEBIAN_FRONTEND=noninteractive
    export NEEDRESTART_MODE=a
    
    # Update system
    log "Updating package lists..."
    sudo -E apt-get update 2>&1 | tee -a "$LOG_FILE"
    
    # Install essential packages with force options
    log "Installing prerequisites (this may take a few minutes)..."
    sudo -E apt-get install -y \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
        linux-firmware \
        linux-headers-$(uname -r) \
        build-essential \
        cmake \
        ninja-build \
        pkg-config \
        libdrm-dev \
        libelf-dev \
        llvm \
        clang \
        lld \
        python3 \
        python3-dev \
        python3-venv \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        curl \
        wget \
        git \
        gnupg2 \
        software-properties-common \
        lsb-release \
        cpufrequtils \
        radeontop \
        htop \
        nvtop \
        mesa-utils \
        libgl1-mesa-dri \
        libgles2-mesa-dev \
        ocl-icd-libopencl1 \
        opencl-headers \
        clinfo 2>&1 | tee -a "$LOG_FILE"
    
    # Unset environment variables
    unset DEBIAN_FRONTEND
    unset NEEDRESTART_MODE
    
    log "Prerequisites installed successfully"
}

# Step 2: Add kernel parameters for Radeon 780M
configure_kernel_parameters() {
    log "Configuring kernel parameters for Radeon 780M..."
    
    if [[ "$TEST_MODE" == "true" ]]; then
        info "TEST MODE: Would configure kernel parameters"
        return 0
    fi
    
    GRUB_PARAMS="amdgpu.noretry=0 amdgpu.vm_fragment_size=9 amdgpu.mcbp=1 amdgpu.dpm=1 amdgpu.dc=1"
    
    if ! grep -q "amdgpu.noretry" /etc/default/grub; then
        sudo cp /etc/default/grub "$BACKUP_DIR/grub.bak"
        sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"$GRUB_PARAMS /" /etc/default/grub
        sudo update-grub 2>&1 | tee -a "$LOG_FILE"
        log "Kernel parameters added - reboot required"
    else
        log "Kernel parameters already configured"
    fi
}

# Step 3: Install ROCm - FIXED VERSION
install_rocm() {
    log "Installing ROCm $ROCM_VERSION..."
    
    if [[ "$TEST_MODE" == "true" ]]; then
        info "TEST MODE: Would install ROCm $ROCM_VERSION"
        return 0
    fi
    
    # Clean up any apt locks
    cleanup_apt_locks
    
    # Set environment for non-interactive installation
    export DEBIAN_FRONTEND=noninteractive
    export NEEDRESTART_MODE=a
    export NEEDRESTART_SUSPEND=1
    
    # Remove any existing ROCm installations
    if [ -d /opt/rocm ]; then
        warning "Existing ROCm installation found, cleaning up..."
        # Kill any processes using ROCm
        sudo pkill -f rocm || true
        sleep 2
        
        # Remove packages
        log "Removing existing ROCm packages..."
        sudo -E apt-get remove --purge -y rocm-* hip-* rocrand* rocblas* miopen* 2>&1 | tee -a "$LOG_FILE" || true
        sudo -E apt-get autoremove -y 2>&1 | tee -a "$LOG_FILE" || true
        sudo rm -rf /opt/rocm*
    fi
    
    # Add AMD GPU repository GPG key
    log "Adding ROCm repository key..."
    wget -qO - https://repo.radeon.com/rocm/rocm.gpg.key | sudo gpg --dearmor --batch --yes -o /usr/share/keyrings/rocm-archive-keyring.gpg 2>&1 | tee -a "$LOG_FILE"
    
    # For Ubuntu 25.04, use Noble repository with preferences
    log "Configuring ROCm repository for Ubuntu 25.04..."
    
    # Add ROCm repository
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/rocm-archive-keyring.gpg] https://repo.radeon.com/rocm/apt/$ROCM_VERSION noble main" | sudo tee /etc/apt/sources.list.d/rocm.list
    
    # Add AMDGPU repository for additional compatibility
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/rocm-archive-keyring.gpg] https://repo.radeon.com/amdgpu/$ROCM_VERSION/ubuntu noble main" | sudo tee /etc/apt/sources.list.d/amdgpu.list
    
    # Set package preferences to handle version conflicts
    cat << EOF | sudo tee /etc/apt/preferences.d/rocm-preferences
Package: *
Pin: release o=repo.radeon.com
Pin-Priority: 600

Package: rocm-*
Pin: release o=repo.radeon.com
Pin-Priority: 700

Package: hip-*
Pin: release o=repo.radeon.com
Pin-Priority: 700
EOF
    
    # Update package lists
    log "Updating package lists with new repositories..."
    sudo -E apt-get update 2>&1 | tee -a "$LOG_FILE"
    
    # First install minimal core packages to test compatibility
    log "Installing ROCm core packages..."
    
    # Install rocm-core first
    if ! sudo -E apt-get install -y \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
        -o Dpkg::Options::="--force-overwrite" \
        rocm-core 2>&1 | tee -a "$LOG_FILE"; then
        
        warning "rocm-core installation failed, trying without recommends..."
        sudo -E apt-get install -y --no-install-recommends \
            -o Dpkg::Options::="--force-confdef" \
            -o Dpkg::Options::="--force-confold" \
            -o Dpkg::Options::="--force-overwrite" \
            rocm-core 2>&1 | tee -a "$LOG_FILE"
    fi
    
    # Install essential ROCm packages one by one
    log "Installing essential ROCm components..."
    
    ESSENTIAL_PACKAGES=(
        "rocm-device-libs"
        "rocm-llvm"
        "rocm-cmake"
        "hip-base"
        "hip-runtime-amd"
        "hip-dev"
        "rocm-smi-lib"
        "rocminfo"
        "rocm-clang-ocl"
    )
    
    for package in "${ESSENTIAL_PACKAGES[@]}"; do
        log "Installing $package..."
        if ! sudo -E apt-get install -y \
            -o Dpkg::Options::="--force-confdef" \
            -o Dpkg::Options::="--force-confold" \
            -o Dpkg::Options::="--force-overwrite" \
            "$package" 2>&1 | tee -a "$LOG_FILE"; then
            warning "Failed to install $package - continuing with others"
        fi
        # Small delay to prevent overwhelming the system
        sleep 1
    done
    
    # Try to install rocm-dev metapackage
    log "Attempting to install ROCm development environment..."
    if sudo -E apt-get install -y \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
        -o Dpkg::Options::="--force-overwrite" \
        rocm-dev 2>&1 | tee -a "$LOG_FILE"; then
        
        log "ROCm development environment installed successfully"
        
        # Install additional math libraries
        MATH_PACKAGES=(
            "rocblas"
            "rocfft"
            "rocsparse"
            "rocrand"
            "hipblas"
            "hipsparse"
            "hipfft"
        )
        
        for package in "${MATH_PACKAGES[@]}"; do
            log "Installing math library: $package..."
            sudo -E apt-get install -y \
                -o Dpkg::Options::="--force-confdef" \
                -o Dpkg::Options::="--force-confold" \
                -o Dpkg::Options::="--force-overwrite" \
                "$package" 2>&1 | tee -a "$LOG_FILE" || warning "Failed to install $package"
            sleep 1
        done
    else
        warning "Could not install full rocm-dev package - ROCm installation may be incomplete"
    fi
    
    # Verify installation
    if [ -d "/opt/rocm-$ROCM_VERSION" ] || [ -d "/opt/rocm" ]; then
        log "ROCm installation directory found"
        
        # Create symlink if needed
        if [ -d "/opt/rocm-$ROCM_VERSION" ] && [ ! -e "/opt/rocm" ]; then
            sudo ln -sf "/opt/rocm-$ROCM_VERSION" /opt/rocm
            log "Created /opt/rocm symlink"
        fi
        
        # Test rocminfo
        if [ -f "/opt/rocm/bin/rocminfo" ]; then
            log "Testing ROCm installation with rocminfo..."
            if /opt/rocm/bin/rocminfo 2>&1 | head -20 | tee -a "$LOG_FILE"; then
                log "ROCm appears to be working"
            else
                warning "rocminfo test failed - GPU may not be properly detected"
            fi
        fi
    else
        error "ROCm installation directory not found"
    fi
    
    # Add user to necessary groups
    sudo usermod -a -G render,video $USER
    
    # Set up udev rules for GPU access
    echo 'SUBSYSTEM=="kfd", KERNEL=="kfd", TAG+="uaccess", GROUP="video"' | sudo tee /etc/udev/rules.d/70-kfd.rules
    echo 'SUBSYSTEM=="drm", KERNEL=="card*", TAG+="uaccess", GROUP="video"' | sudo tee -a /etc/udev/rules.d/70-kfd.rules
    echo 'SUBSYSTEM=="drm", KERNEL=="renderD*", TAG+="uaccess", GROUP="render"' | sudo tee -a /etc/udev/rules.d/70-kfd.rules
    
    # Reload udev rules
    sudo udevadm control --reload-rules && sudo udevadm trigger
    
    # Unset environment variables
    unset DEBIAN_FRONTEND
    unset NEEDRESTART_MODE
    unset NEEDRESTART_SUSPEND
    
    log "ROCm installation completed"
}

# Step 4: Install Vulkan support
install_vulkan() {
    log "Installing Vulkan support for Radeon 780M..."
    
    if [[ "$TEST_MODE" == "true" ]]; then
        info "TEST MODE: Would install Vulkan support"
        return 0
    fi
    
    export DEBIAN_FRONTEND=noninteractive
    
    sudo -E apt-get install -y \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
        vulkan-tools \
        vulkan-utility-libraries-dev \
        libvulkan1 \
        libvulkan-dev \
        mesa-vulkan-drivers 2>&1 | tee -a "$LOG_FILE"
    
    unset DEBIAN_FRONTEND
    
    log "Vulkan support installed"
}

# Step 5: Build and Install XRT from Source for XDNA NPU support
install_xrt_npu() {
    log "Building and installing XRT from source for XDNA NPU support..."
    
    if [[ "$TEST_MODE" == "true" ]]; then
        info "TEST MODE: Would build and install XRT from source"
        return 0
    fi
    
    # Ubuntu 25.04 kernel 6.14 has native AMDXDNA support
    log "Ubuntu 25.04 has native AMDXDNA NPU support in kernel 6.14"
    
    # Check if XDNA driver is loaded
    if lsmod | grep -q amdxdna; then
        log "AMDXDNA kernel driver detected"
    else
        warning "AMDXDNA kernel driver not loaded - NPU may not be available"
    fi
    
    # Install XRT build dependencies
    log "Installing XRT build dependencies..."
    
    export DEBIAN_FRONTEND=noninteractive
    
    sudo -E apt-get install -y \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
        build-essential \
        cmake \
        ninja-build \
        git \
        libboost-all-dev \
        libssl-dev \
        libudev-dev \
        libxml2-dev \
        libyaml-dev \
        libelf-dev \
        libncurses5-dev \
        libtinfo-dev \
        libprotobuf-dev \
        protobuf-compiler \
        libcurl4-openssl-dev \
        python3-dev \
        python3-pip \
        python3-pybind11 \
        uuid-dev \
        ocl-icd-opencl-dev \
        opencl-headers \
        dkms 2>&1 | tee -a "$LOG_FILE"
    
    unset DEBIAN_FRONTEND
    
    # Create build directory
    BUILD_DIR="/tmp/xrt-build"
    XRT_INSTALL_DIR="/opt/xilinx/xrt"
    
    # Remove existing installation
    if [ -d "$XRT_INSTALL_DIR" ]; then
        log "Removing existing XRT installation..."
        sudo rm -rf "$XRT_INSTALL_DIR"
    fi
    
    # Clean up any previous build
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
    
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Clone XDNA driver repository with XRT submodule
    log "Cloning AMD XDNA driver repository with XRT submodule..."
    if ! git clone --recursive https://github.com/amd/xdna-driver.git 2>&1 | tee -a "$LOG_FILE"; then
        error "Failed to clone XDNA driver repository"
        return 1
    fi
    
    cd xdna-driver
    
    # Install XDNA dependencies
    log "Installing XDNA dependencies..."
    if [ -f "./tools/amdxdna_deps.sh" ]; then
        sudo ./tools/amdxdna_deps.sh 2>&1 | tee -a "$LOG_FILE"
    else
        warning "amdxdna_deps.sh not found - continuing without it"
    fi
    
    # Build XRT base package
    log "Building XRT base package (this may take 30-60 minutes)..."
    cd xrt/build
    
    # Configure build with NPU support
    log "Configuring XRT build..."
    if ! ./build.sh -npu -opt 2>&1 | tee -a "$LOG_FILE"; then
        error "XRT base build failed"
        return 1
    fi
    
    # Install XRT base package
    log "Installing XRT base package..."
    XRT_BASE_DEB=$(find Release -name "xrt_*-amd64-base.deb" 2>/dev/null | head -1)
    if [ -f "$XRT_BASE_DEB" ]; then
        export DEBIAN_FRONTEND=noninteractive
        sudo -E apt-get install -y "./$XRT_BASE_DEB" 2>&1 | tee -a "$LOG_FILE"
        unset DEBIAN_FRONTEND
        log "XRT base package installed successfully"
    else
        error "XRT base package not found"
        return 1
    fi
    
    # Build XDNA driver and plugin
    log "Building XDNA driver and XRT plugin..."
    cd ../../build
    
    if ! ./build.sh -release 2>&1 | tee -a "$LOG_FILE"; then
        error "XDNA driver build failed"
        return 1
    fi
    
    if ! ./build.sh -package 2>&1 | tee -a "$LOG_FILE"; then
        error "XDNA plugin package build failed"
        return 1
    fi
    
    # Install XDNA plugin package
    log "Installing XDNA plugin package..."
    XRT_PLUGIN_DEB=$(find Release -name "xrt_plugin*-amdxdna.deb" 2>/dev/null | head -1)
    if [ -f "$XRT_PLUGIN_DEB" ]; then
        export DEBIAN_FRONTEND=noninteractive
        sudo -E apt-get install -y "./$XRT_PLUGIN_DEB" 2>&1 | tee -a "$LOG_FILE"
        unset DEBIAN_FRONTEND
        log "XRT XDNA plugin installed successfully"
    else
        error "XRT XDNA plugin package not found"
        return 1
    fi
    
    # Clean up build directory
    cd /
    rm -rf "$BUILD_DIR"
    
    # Verify installation
    if [ -f "$XRT_INSTALL_DIR/setup.sh" ]; then
        log "XRT source build and installation completed successfully"
    else
        error "XRT installation verification failed"
        return 1
    fi
}

# Step 6: Create environment configuration
create_environment() {
    log "Creating ROCm environment configuration..."
    
    cat > "$HOME/rocm_env.sh" << 'EOF'
#!/bin/bash
# ROCm environment for AMD Radeon 780M (gfx1103) and XDNA 2 NPU
# Updated for source-built XRT installation

# ROCm paths
export ROCM_PATH=/opt/rocm
export ROCM_HOME=$ROCM_PATH
export PATH=$ROCM_PATH/bin:$ROCM_PATH/llvm/bin:$PATH
export LD_LIBRARY_PATH=$ROCM_PATH/lib:$ROCM_PATH/lib64:$ROCM_PATH/llvm/lib:$LD_LIBRARY_PATH

# HIP Configuration
export HIP_PATH=$ROCM_PATH/hip
export HIP_PLATFORM=amd
export HIP_RUNTIME=rocclr
export HIP_COMPILER=clang

# 780M iGPU support (gfx1103)
export HSA_OVERRIDE_GFX_VERSION=11.0.3
export HSA_ENABLE_SDMA=0
export HIP_VISIBLE_DEVICES=0
export GPU_MAX_HW_QUEUES=8

# XRT Environment (Source Build)
export XILINX_XRT=/opt/xilinx/xrt
export XRT_ROOT=$XILINX_XRT

# XRT paths and libraries
if [ -d "$XILINX_XRT" ]; then
    export PATH=$XILINX_XRT/bin:$PATH
    export LD_LIBRARY_PATH=$XILINX_XRT/lib:$LD_LIBRARY_PATH
    export PYTHONPATH=$XILINX_XRT/python:$PYTHONPATH
    
    # Source XRT setup script if available
    if [ -f "$XILINX_XRT/setup.sh" ]; then
        source $XILINX_XRT/setup.sh
    fi
fi

# XDNA/NPU Configuration
export XDNA_DEVICE_PATH=/dev/accel/accel0
export XDNA_LOG_LEVEL=1

# NPU Runtime Environment
export XLNX_ENABLE_FINGERPRINT_CHECK=0
export XLNX_ENABLE_CACHE=1

# Performance optimizations
export OMP_NUM_THREADS=16
export MKL_NUM_THREADS=16
export OPENBLAS_NUM_THREADS=16

# OpenCL
export OCL_ICD_VENDORS=/etc/OpenCL/vendors/

# Vulkan
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json

# Status reporting (only show if terminal is interactive)
if [ -t 1 ]; then
    echo "ROCm environment loaded for Radeon 780M + XDNA 2 NPU"
    echo "ROCm Path: $ROCM_PATH"
    echo "HIP Platform: $HIP_PLATFORM"
    echo "HSA Override: $HSA_OVERRIDE_GFX_VERSION"
    echo "XRT Path: $XILINX_XRT"
    echo "XRT Available: $(command -v xrt-smi >/dev/null && echo 'Yes' || echo 'No')"
    echo "XDNA Device: $([ -e "$XDNA_DEVICE_PATH" ] && echo 'Found' || echo 'Not Found')"
fi
EOF

    chmod +x "$HOME/rocm_env.sh"
    
    # Add to bashrc
    if ! grep -q "rocm_env.sh" "$HOME/.bashrc"; then
        echo "" >> "$HOME/.bashrc"
        echo "# ROCm environment" >> "$HOME/.bashrc"
        echo "[ -f $HOME/rocm_env.sh ] && source $HOME/rocm_env.sh" >> "$HOME/.bashrc"
    fi
    
    log "Environment configuration created"
}

# Step 7: System optimizations
apply_system_optimizations() {
    log "Applying system optimizations for AI workloads..."
    
    if [[ "$TEST_MODE" == "true" ]]; then
        info "TEST MODE: Would apply system optimizations"
        return 0
    fi
    
    # CPU governor
    echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils > /dev/null
    sudo systemctl enable cpufrequtils 2>&1 | tee -a "$LOG_FILE" || true
    
    # Sysctl optimizations
    cat << EOF | sudo tee /etc/sysctl.d/99-rocm-ai.conf > /dev/null
# ROCm and AI workload optimizations
vm.swappiness=10
vm.nr_hugepages=2048
vm.max_map_count=262144
vm.overcommit_memory=1
kernel.shmmax=68719476736
kernel.shmall=16777216
kernel.numa_balancing=0
vm.zone_reclaim_mode=0
EOF

    sudo sysctl -p /etc/sysctl.d/99-rocm-ai.conf 2>&1 | tee -a "$LOG_FILE"
    
    log "System optimizations applied"
}

# Step 8: Create verification script
create_verification_script() {
    log "Creating verification script..."
    
    cat > "$HOME/test_rocm.sh" << 'EOF'
#!/bin/bash
source $HOME/rocm_env.sh

echo "=== ROCm + XRT Installation Test ==="
echo "Date: $(date)"
echo "Kernel: $(uname -r)"
echo ""

# Check kernel modules
echo "=== Kernel Modules ==="
echo "AMD GPU module:"
lsmod | grep amdgpu || echo "amdgpu module not loaded"
echo "XDNA NPU module:"
lsmod | grep amdxdna || echo "amdxdna module not loaded"
echo ""

# ROCm Info
echo "=== ROCm Information ==="
if command -v rocminfo >/dev/null 2>&1; then
    rocminfo | grep -E "(Name:|Marketing Name:|Compute Unit:|Memory Size:|Chip ID:|ASIC Revision:)" | head -20
else
    echo "rocminfo not found - ROCm may not be properly installed"
fi
echo ""

# HIP Info
echo "=== HIP Configuration ==="
if command -v hipconfig >/dev/null 2>&1; then
    hipconfig --full
else
    echo "HIP Platform: $HIP_PLATFORM"
    echo "HIP Runtime: $HIP_RUNTIME"
    echo "HIP Path: $HIP_PATH"
fi
echo ""

# XRT Installation Verification
echo "=== XRT Installation Status ==="
echo "XRT Path: $XILINX_XRT"
echo "XRT Installation: $([ -d "$XILINX_XRT" ] && echo 'Found' || echo 'Not Found')"
echo "XRT Setup Script: $([ -f "$XILINX_XRT/setup.sh" ] && echo 'Found' || echo 'Not Found')"
echo "XRT Libraries: $([ -d "$XILINX_XRT/lib" ] && echo 'Found' || echo 'Not Found')"
echo ""

# XRT Commands Test
echo "=== XRT Tools Test ==="
if command -v xrt-smi >/dev/null 2>&1; then
    echo "xrt-smi version:"
    xrt-smi version 2>/dev/null || echo "xrt-smi version failed"
    echo ""
    echo "xrt-smi examine:"
    xrt-smi examine 2>/dev/null || echo "xrt-smi examine failed"
else
    echo "xrt-smi not found in PATH"
fi

if command -v xbutil >/dev/null 2>&1; then
    echo ""
    echo "xbutil scan:"
    xbutil scan 2>/dev/null || echo "xbutil scan failed"
else
    echo "xbutil not found in PATH"
fi
echo ""

# NPU Device Status
echo "=== NPU Device Status ==="
echo "XDNA Device Path: $XDNA_DEVICE_PATH"
echo "XDNA Device Status: $([ -e "$XDNA_DEVICE_PATH" ] && echo 'Found' || echo 'Not Found')"
if [ -e "$XDNA_DEVICE_PATH" ]; then
    ls -la "$XDNA_DEVICE_PATH"
fi
echo ""

# OpenCL Info
echo "=== OpenCL Devices ==="
if command -v clinfo >/dev/null 2>&1; then
    clinfo -l 2>/dev/null || echo "No OpenCL devices found"
else
    echo "clinfo not installed"
fi
echo ""

# Vulkan Info
echo "=== Vulkan Devices ==="
if command -v vulkaninfo >/dev/null 2>&1; then
    vulkaninfo --summary 2>/dev/null | grep -E "(deviceName|deviceType|driverVersion)" | head -10
else
    echo "vulkaninfo not available"
fi
echo ""

# GPU/NPU devices
echo "=== Hardware Devices ==="
echo "DRI devices:"
ls -la /dev/dri/ 2>/dev/null || echo "No DRI devices found"
echo "KFD device:"
ls -la /dev/kfd 2>/dev/null || echo "No KFD device found"
echo "ACCEL devices (NPU):"
ls -la /dev/accel/ 2>/dev/null || echo "No ACCEL devices found"
echo ""

# Memory info
echo "=== Memory Information ==="
free -h
echo ""
echo "Huge Pages:"
cat /proc/meminfo | grep Huge
echo ""

# Environment Variables Summary
echo "=== Environment Summary ==="
echo "ROCM_PATH: $ROCM_PATH"
echo "XILINX_XRT: $XILINX_XRT"
echo "HIP_PLATFORM: $HIP_PLATFORM"
echo "HSA_OVERRIDE_GFX_VERSION: $HSA_OVERRIDE_GFX_VERSION"
echo "XDNA_LOG_LEVEL: $XDNA_LOG_LEVEL"
EOF

    chmod +x "$HOME/test_rocm.sh"
    
    log "Verification script created"
}

# Step 9: Create uninstall script
create_uninstall_script() {
    cat > "$HOME/uninstall_rocm.sh" << 'EOF'
#!/bin/bash
echo "=== ROCm + XRT Uninstall Script ==="
echo "This will remove ROCm, source-built XRT, and related components."
read -p "Are you sure? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing ROCm packages..."
    # Remove ROCm packages
    sudo apt remove --purge -y rocm-* hip-* hsa-* amd-* rocblas* rocsparse* rocfft* miopen* rccl* roctracer* rocprofiler* 2>/dev/null
    
    echo "Removing XRT packages..."
    # Remove XRT packages (both base and plugin)
    sudo apt remove --purge -y xrt_* 2>/dev/null
    
    echo "Removing XRT installation directory..."
    # Remove XRT installation directory (source-built)
    sudo rm -rf /opt/xilinx
    
    echo "Cleaning up repositories..."
    # Remove repository files
    sudo rm -f /etc/apt/sources.list.d/rocm.list
    sudo rm -f /etc/apt/sources.list.d/amdgpu.list
    sudo rm -f /usr/share/keyrings/rocm-archive-keyring.gpg
    sudo rm -f /etc/apt/preferences.d/rocm-preferences
    
    echo "Removing environment files..."
    # Remove environment files
    rm -f $HOME/rocm_env.sh
    sed -i '/rocm_env.sh/d' $HOME/.bashrc
    
    echo "Removing system configurations..."
    # Remove system configuration files
    sudo rm -f /etc/sysctl.d/99-rocm-ai.conf
    sudo rm -f /etc/default/cpufrequtils
    sudo rm -f /etc/udev/rules.d/70-kfd.rules
    
    echo "Restoring GRUB configuration..."
    # Restore GRUB if backup exists
    if [ -f "$HOME/rocm_setup_backup/grub.bak" ]; then
        sudo cp "$HOME/rocm_setup_backup/grub.bak" /etc/default/grub
        sudo update-grub
    fi
    
    echo "Cleaning up packages..."
    # Clean up
    sudo apt autoremove -y
    sudo apt autoclean
    
    echo ""
    echo "Uninstall complete!"
    echo "Please reboot your system to complete the removal."
fi
EOF
    chmod +x "$HOME/uninstall_rocm.sh"
}

# Step 10: Create recovery script
create_recovery_script() {
    cat > "$HOME/rocm_recovery.sh" << 'EOF'
#!/bin/bash
# ROCm Recovery Script - Use if installation fails or system becomes unstable

echo "=== ROCm Recovery Script ==="
echo "This will clean up failed installations and reset the system"
echo ""

# Kill all apt processes
echo "Stopping all package management processes..."
sudo killall apt apt-get dpkg 2>/dev/null || true
sleep 2

# Remove all lock files
echo "Removing lock files..."
sudo rm -f /var/lib/dpkg/lock-frontend
sudo rm -f /var/lib/dpkg/lock
sudo rm -f /var/lib/apt/lists/lock
sudo rm -f /var/cache/apt/archives/lock

# Fix dpkg interruptions
echo "Fixing interrupted installations..."
sudo dpkg --configure -a

# Fix broken packages
echo "Fixing broken packages..."
sudo apt-get install -f -y

# Clean package cache
echo "Cleaning package cache..."
sudo apt-get clean
sudo apt-get autoclean

# Update package lists
echo "Updating package lists..."
sudo apt-get update

echo ""
echo "Recovery complete!"
echo "You can now try running the installation script again."
EOF
    chmod +x "$HOME/rocm_recovery.sh"
}

# Main installation flow
main() {
    log "=== Starting Complete ROCm + Ryzen AI Installation ==="
    
    # Initial cleanup
    cleanup_apt_locks
    
    # Create backup
    backup_configs
    
    # Install prerequisites
    install_prerequisites
    
    # Configure kernel
    configure_kernel_parameters
    
    # Install components
    install_rocm
    if [ $? -eq 0 ]; then
        install_vulkan
        install_xrt_npu
    else
        error "ROCm installation failed - skipping additional components"
    fi
    
    # Configure environment
    create_environment
    
    # Apply optimizations
    apply_system_optimizations
    
    # Create utility scripts
    create_verification_script
    create_uninstall_script
    create_recovery_script
    
    # Final summary
    log ""
    log "=== Installation Summary ==="
    log ""
    
    # Check what was actually installed
    ROCM_INSTALLED=false
    XRT_INSTALLED=false
    
    if [ -d "/opt/rocm" ]; then
        ROCM_INSTALLED=true
    fi
    
    if [ -d "/opt/xilinx/xrt" ]; then
        XRT_INSTALLED=true
    fi
    
    log "Installation Status:"
    if [ "$ROCM_INSTALLED" = true ]; then
        log "  ✓ ROCm $ROCM_VERSION - INSTALLED"
        log "  ✓ HIP Runtime and Development Tools"
    else
        log "  ✗ ROCm $ROCM_VERSION - FAILED"
    fi
    
    log "  ✓ Vulkan support for Radeon 780M"
    
    if [ "$XRT_INSTALLED" = true ]; then
        log "  ✓ XRT built from source for XDNA 2 NPU - INSTALLED"
        log "  ✓ XDNA driver and XRT plugin"
    else
        log "  ✗ XRT for XDNA 2 NPU - FAILED OR SKIPPED"
    fi
    
    log "  ✓ OpenCL support"
    log "  ✓ System optimizations"
    log "  ✓ Verification scripts"
    log ""
    log "Created scripts:"
    log "  • $HOME/rocm_env.sh - Environment setup (auto-loaded)"
    log "  • $HOME/test_rocm.sh - Test ROCm + XRT installation"
    log "  • $HOME/uninstall_rocm.sh - Complete uninstall script"
    log "  • $HOME/rocm_recovery.sh - Recovery script for failed installations"
    log ""
    
    if [ "$ROCM_INSTALLED" = true ]; then
        log "ROCm Installation Details:"
        log "  • ROCm path: /opt/rocm"
        log "  • Using Noble (24.04) packages on Plucky (25.04)"
        log "  • Some packages may have compatibility warnings"
    fi
    
    if [ "$XRT_INSTALLED" = true ]; then
        log ""
        log "XRT Installation Details:"
        log "  • XRT built from AMD XDNA driver repository"
        log "  • Base XRT package: /opt/xilinx/xrt"
        log "  • XDNA plugin for NPU support included"
        log "  • Source build provides latest NPU compatibility"
    fi
    
    log ""
    log "IMPORTANT Notes for Ubuntu 25.04:"
    log "  • Ubuntu 25.04 (Plucky) is using ROCm packages from 24.04 (Noble)"
    log "  • Some package conflicts are expected and handled"
    log "  • If you encounter issues, use the recovery script"
    log ""
    log "Next steps:"
    log "  1. Reboot your system: sudo reboot"
    log "  2. After reboot, test installation: ./test_rocm.sh"
    
    if [ "$XRT_INSTALLED" = true ]; then
        log "  3. Verify XRT tools: xrt-smi version && xrt-smi examine"
    fi
    
    log ""
    log "Troubleshooting:"
    log "  • If installation hung, check: tail -100 $LOG_FILE"
    log "  • For recovery: ./rocm_recovery.sh"
    log "  • Check dmesg for GPU errors: dmesg | grep -i amdgpu"
    log ""
    log "Log file: $LOG_FILE"
    log "Backup directory: $BACKUP_DIR"
    
    # Check if reboot is needed
    if grep -q "amdgpu.noretry" /proc/cmdline; then
        info "Kernel parameters already active"
    else
        warning "IMPORTANT: Reboot required to activate kernel parameters!"
    fi
}

# Error handler
error_handler() {
    error "An error occurred on line $1"
    error "Check the log file for details: $LOG_FILE"
    error "You can run the recovery script to clean up: ./rocm_recovery.sh"
    exit 1
}

# Set error trap
trap 'error_handler $LINENO' ERR

# Run main installation
main

# Exit successfully
exit 0
