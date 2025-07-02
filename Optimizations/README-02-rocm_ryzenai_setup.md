# 02-rocm_ryzenai_setup.sh Documentation

Complete ROCm 6.4.1, Ryzen AI, and Vulkan Setup for AMD Ryzen 9 8945HS with Radeon 780M iGPU and XDNA 2 NPU on Ubuntu 25.04

## Overview

This script provides a complete, automated installation of AMD ROCm 6.4.1 optimized for Ubuntu 25.04 Server with native kernel 6.14 support. It leverages the built-in AMDGPU and AMDXDNA drivers instead of requiring external installer packages.

## System Requirements

### Hardware
- **CPU**: AMD Ryzen 9 8945HS (or compatible Ryzen 7040/8040 series)
- **GPU**: AMD Radeon 780M integrated GPU (RDNA 3, gfx1103)
- **NPU**: AMD XDNA 2 Neural Processing Unit
- **RAM**: 16GB minimum (32GB+ recommended)
- **Storage**: 10GB free space for ROCm installation

### Software
- **OS**: Ubuntu 25.04 (Plucky Puffin) Server or Desktop
- **Kernel**: 6.14+ with native AMDGPU and AMDXDNA driver support
- **Python**: 3.13+ (system Python)

## What Gets Installed

### Core Components
- **ROCm 6.4.1**: AMD's open-source GPU compute platform
- **HIP**: Heterogeneous-compute Interface for Portability
- **OpenCL**: Open Computing Language support
- **Vulkan**: Graphics and compute API with Mesa drivers
- **Native AMDXDNA**: NPU support via kernel 6.14

### ROCm Packages
- `rocm-dev` - Development tools and headers
- `rocm-libs` - Runtime libraries
- `rocm-utils` - Utility tools
- `hip-runtime-amd` - HIP runtime for AMD GPUs
- `rocblas`, `rocfft`, `rocsparse` - Math libraries
- `miopen-hip` - Machine learning primitives
- `rocm-smi-lib` - System management interface

### Vulkan Packages
- `vulkan-tools` - Vulkan utilities and info tools
- `vulkan-utility-libraries-dev` - Validation layers (Ubuntu 25.04)
- `libvulkan1` - Vulkan runtime library
- `mesa-vulkan-drivers` - Mesa Vulkan drivers for AMD

## Usage

### Basic Installation

```bash
# Make executable
chmod +x 02-rocm_ryzenai_setup.sh

# Run installation
./02-rocm_ryzenai_setup.sh
```

### Test Mode (Dry Run)

```bash
# Test without installing
./02-rocm_ryzenai_setup.sh --test
./02-rocm_ryzenai_setup.sh --dry-run
```

## Installation Process

### Step 1: System Prerequisites
- Updates package repositories
- Installs build tools, Python development headers
- Installs Mesa utilities and OpenCL support

### Step 2: Kernel Parameters
- Configures GRUB parameters for Radeon 780M optimization:
  - `amdgpu.noretry=0`
  - `amdgpu.vm_fragment_size=9` 
  - `amdgpu.mcbp=1`
  - `amdgpu.dpm=1`
  - `amdgpu.dc=1`

### Step 3: ROCm Installation
- Adds AMD ROCm repository with modern GPG key handling
- Installs ROCm 6.4.1 packages directly (no amdgpu-install needed)
- Adds user to `render` and `video` groups

### Step 4: Vulkan Support
- Installs Vulkan tools and Mesa drivers
- Uses Ubuntu 25.04 compatible package names

### Step 5: NPU Support
- Detects native AMDXDNA kernel driver
- Warns about XRT tools (build from source if needed)

### Step 6: Environment Configuration
- Creates `~/rocm_env.sh` with optimized settings
- Auto-loads environment in new terminal sessions
- Sets HSA_OVERRIDE_GFX_VERSION=11.0.3 for 780M compatibility

### Step 7: System Optimizations
- CPU performance governor
- Memory optimizations for AI workloads
- Kernel parameters for improved performance

## Generated Files

### Environment Script: `~/rocm_env.sh`
```bash
# ROCm paths
export ROCM_PATH=/opt/rocm
export HIP_PLATFORM=amd
export HSA_OVERRIDE_GFX_VERSION=11.0.3

# NPU environment
export XILINX_XRT=/opt/xilinx/xrt

# Performance optimizations
export OMP_NUM_THREADS=16
```

### Verification Script: `~/test_rocm.sh`
Tests all installed components:
- AMD GPU kernel module
- ROCm device detection
- HIP configuration
- OpenCL devices
- Vulkan support
- NPU/XDNA status

### Uninstall Script: `~/uninstall_rocm.sh`
Complete removal of ROCm and related components.

## Post-Installation

### Required: Reboot System
```bash
sudo reboot
```

### Verify Installation
```bash
# Test ROCm installation
~/test_rocm.sh

# Check GPU info
rocminfo | grep -A 5 "Marketing Name"

# Test Vulkan
vulkaninfo --summary
```

### Expected Output
- AMD GPU kernel module: ✅ `amdgpu` loaded
- ROCm device: ✅ `gfx1103` detected
- HIP platform: ✅ `amd`
- OpenCL: ✅ Radeon 780M device
- Vulkan: ✅ Mesa driver
- NPU: ✅ AMDXDNA driver loaded

## Key Features

### Ubuntu 25.04 Optimizations
- **Native kernel support**: Uses built-in drivers instead of DKMS
- **Modern package management**: GPG keys without deprecated `apt-key`
- **Correct package names**: Updated for Ubuntu 25.04 repositories

### Hardware-Specific Tuning
- **Radeon 780M (gfx1103)**: HSA override for compatibility
- **XDNA 2 NPU**: Native kernel 6.14 driver support
- **Ryzen 9 8945HS**: Performance governor and memory tuning

### Robust Error Handling
- **Repository fallback**: Oracular → Noble if needed
- **Package validation**: Checks for Ubuntu 25.04 compatibility
- **Test mode**: Safe dry-run capability

## Troubleshooting

### Common Issues

#### ROCm Not Detected
```bash
# Check kernel module
lsmod | grep amdgpu

# Check user groups
groups | grep -E "render|video"

# Re-add to groups if needed
sudo usermod -a -G render,video $USER
```

#### Environment Not Loading
```bash
# Manually source environment
source ~/rocm_env.sh

# Check if added to bashrc
grep rocm_env ~/.bashrc
```

#### NPU Not Working
```bash
# Check XDNA driver
lsmod | grep amdxdna

# For full NPU support, build XRT from source:
# https://github.com/amd/xdna-driver
```

### Log Files
Installation logs are saved to:
```
~/rocm_setup_YYYYMMDD_HHMMSS.log
```

### Backup Directory
Configuration backups stored in:
```
~/rocm_setup_backup/
```

## Advanced Usage

### Manual Environment Loading
```bash
source ~/rocm_env.sh
```

### GPU Memory Check
```bash
rocm-smi --showmeminfo vram
```

### Performance Monitoring
```bash
# Real-time GPU usage
radeontop

# ROCm system info
rocm-smi

# Detailed device info
rocminfo
```

## Version Information

- **Script Version**: 2.0
- **ROCm Version**: 6.4.1
- **Target OS**: Ubuntu 25.04 (Plucky Puffin)
- **Kernel**: 6.14+ with native AMDGPU/AMDXDNA support
- **Last Updated**: June 2025

## Dependencies

### Required Packages
- `build-essential` - Compilation tools
- `cmake`, `ninja-build` - Build systems
- `python3-dev` - Python development headers
- `mesa-vulkan-drivers` - Vulkan support
- `clinfo` - OpenCL information tool

### Repository Sources
- Main Ubuntu 25.04 repositories
- AMD ROCm repository (repo.radeon.com)

## License and Support

This script is provided as-is under MIT License. ROCm, Mesa, and other installed software are subject to their respective licenses.

For issues:
1. Check installation log: `~/rocm_setup_*.log`
2. Run verification: `~/test_rocm.sh`
3. Consult [ROCm Documentation](https://rocm.docs.amd.com/)

## Changelog

### Version 2.0 (Current)
- Ubuntu 25.04 native kernel 6.14 support
- Removed dependency on amdgpu-install tool
- Updated Vulkan package names for Ubuntu 25.04
- Added AMDXDNA native NPU detection
- Modern GPG key handling
- Test mode functionality

### Version 1.0
- Initial ROCm 6.4.1 installation
- Basic Vulkan and XRT support
- Environment configuration