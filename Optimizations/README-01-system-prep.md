# UC-1 System Preparation Script

## Overview

The `01-system_prep.sh` script prepares your Ubuntu 25.04 system with KDE6 for optimal AI development on the AMD Ryzen 9 8945HS processor with integrated 780M graphics. This script is the foundation for the entire UC-1 optimization pipeline.

## What it Does

### 🔍 System Verification
- **OS Compatibility**: Verifies Ubuntu 24.04+ (25.04 preferred)
- **Architecture Check**: Ensures x86_64 architecture
- **Disk Space**: Verifies minimum 10GB root + 30GB home space
- **Memory Detection**: Checks RAM configuration and fixes memory mapping issues

### 🛠️ Critical Fixes
- **Memory Mapping Fix**: Removes problematic `memmap=1GG` kernel parameter that limits RAM to ~64GB
- **GRUB Optimization**: Adds AMD-specific performance parameters:
  ```bash
  amd_pstate=active amdgpu.gfxoff=0 amdgpu.runpm=0 amdgpu.dpm=1 amdgpu.ppfeaturemask=0xffffffff
  ```
- **GPU Detection**: Verifies AMD 780M integrated graphics detection

### 📦 Build Environment Setup
- **Core Tools**: Installs build-essential, cmake, ninja-build, git, wget, curl
- **GCC-11**: Installs GCC-11 specifically for PyTorch compatibility
- **Python Dependencies**: Installs all Python build dependencies for source compilation
- **PyTorch Dependencies**: BLIS, OpenBLAS, LAPACK, Protocol Buffers, NUMA libraries

### ⚡ Performance Optimization
- **ccache**: Configures 10GB cache with compression for faster rebuilds
- **Workspace Creation**: Sets up organized directories for models, datasets, projects
- **Docker Verification**: Ensures Docker is installed and working

## Prerequisites

- Ubuntu 24.04+ (25.04 recommended)
- AMD Ryzen 9 8945HS processor
- At least 40GB free disk space
- Sudo privileges for ucadmin user

## Usage

### Basic Usage
```bash
./01-system_prep.sh
```

### Key Features

#### Automatic Memory Fix
If the script detects the `memmap=1GG` issue (common with UC-1 systems), it will:
1. Create a backup of your GRUB configuration
2. Remove the problematic memory mapping parameter
3. Add optimized AMD parameters for better performance
4. Update GRUB bootloader
5. Prompt for immediate reboot

#### Build Environment
Sets up a complete development environment including:
- **Compilers**: GCC-11 for compatibility
- **Build Tools**: CMake, Ninja, pkg-config
- **Caching**: ccache for faster rebuilds
- **Libraries**: All dependencies for ML framework compilation

#### System Monitoring
Creates the `uc-sysinfo` utility for monitoring:
- CPU and memory usage
- GPU/VRAM information
- Storage utilization
- Service status

## Output Files

### Status Tracking
- **Log File**: `/home/ucadmin/uc1-system-prep.log`
- **Status File**: `/home/ucadmin/.uc1-prep-status`

### System Utility
- **Monitoring Tool**: `/usr/local/bin/uc-sysinfo`

### Workspace Directories
```
/home/ucadmin/
├── models/           # ML models storage
├── datasets/         # Training datasets
├── projects/         # Development projects
├── scripts/          # Custom scripts
├── build-cache/      # ccache directory
├── build-temp/       # Temporary build files
└── UC-1/
    └── build-scripts/ # UC-1 specific scripts
```

## Important Notes

### Memory Configuration
- **Before Fix**: ~64GB RAM detected due to memmap parameter
- **After Fix**: Full 96GB RAM available
- **Reboot Required**: Changes take effect after restart

### GPU Optimization
- Disables power management features that can cause instability
- Enables all PowerPlay features for maximum performance
- Optimizes for integrated graphics workloads

### Build Performance
- ccache reduces rebuild times by 50-80%
- GCC-11 ensures compatibility with PyTorch 2.4.0
- Optimized for parallel builds with available CPU cores

## Troubleshooting

### Common Issues

#### Low RAM Detection
```bash
# Check current kernel parameters
cat /proc/cmdline

# If memmap parameter found, the script will fix it automatically
# Manual verification after reboot:
free -h
```

#### GPU Not Detected
```bash
# Check GPU detection
lspci | grep -i vga

# Verify AMDGPU driver
lsmod | grep amdgpu

# Check VRAM allocation
uc-sysinfo
```

#### Package Installation Failures
```bash
# Update package lists manually
sudo apt update --fix-missing

# Check specific package availability
apt search build-essential
```

### Recovery

#### GRUB Backup Restoration
If GRUB changes cause boot issues:
```bash
# Boot from recovery mode or live USB
sudo mount /dev/sdXY /mnt  # Replace with your root partition
sudo cp /mnt/etc/default/grub.backup.* /mnt/etc/default/grub
sudo chroot /mnt update-grub
```

## Next Steps

After successful completion:

1. **Reboot** (if GRUB was modified)
2. **Verify** RAM with `uc-sysinfo`
3. **Continue** with `02-rocm_ryzenai_setup.sh`

## Performance Impact

### Memory Optimization
- **Before**: Limited to ~64GB usable RAM
- **After**: Full 96GB available for builds
- **Impact**: Enables larger parallel builds, faster compilation

### Build Acceleration
- **ccache**: 50-80% faster rebuilds
- **Parallel builds**: Optimized for 16-core processor
- **Dependencies**: All requirements pre-installed

### System Stability
- **Power Management**: Optimized for continuous workloads
- **GPU Stability**: Prevents random freezes during AI training
- **Docker**: Verified working for containerized builds

## Script Safety

### Backup Strategy
- Automatic GRUB configuration backup
- Non-destructive package installations
- Comprehensive error handling

### Error Recovery
- Rollback capabilities for GRUB changes
- Detailed logging for debugging
- Graceful failure handling

This script forms the foundation for the entire UC-1 AI development environment and should be run first in the optimization sequence.