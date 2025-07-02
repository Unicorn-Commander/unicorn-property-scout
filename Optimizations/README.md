# UC-1 Optimization Scripts Chain

This directory contains the complete optimization script chain for UC-1 hardware (AMD Ryzen 9 8945HS + Radeon 780M + XDNA 2 NPU) running Ubuntu 25.04.

## 📋 Script Execution Order

### Core Optimization Chain (Execute in order)

1. **01-system_prep.sh** ✅ - System preparation and dependencies
   - Fixes memory configuration (memmap parameter removal)
   - Installs build dependencies and Docker
   - Sets up workspace directories
   - Verifies GPU detection

2. **02-rocm_ryzenai_setup.sh** ✅ - ROCm, Vulkan, and NPU setup
   - Complete ROCm 6.4.1 automated installation
   - AMD Radeon 780M iGPU optimization (gfx1103)
   - XDNA 2 NPU support with native kernel drivers
   - Vulkan graphics and compute API setup
   - Environment configuration and system optimizations

3. **03-pytorch-setup.sh** ✅ - PyTorch and AI environment setup
   - Create Python virtual environment with ROCm support
   - Install PyTorch for ROCm 6.1 (compatible with ROCm 6.4.1)
   - Install basic ML frameworks and tools
   - Configure gfx1103 environment variables
   - Verify PyTorch ROCm GPU acceleration

4. **04-ml-frameworks-setup.sh** ✅ - Advanced ML frameworks
   - TensorFlow, JAX, ONNX Runtime 
   - Additional ML libraries (XGBoost, LightGBM, etc.)
   - Computer vision and NLP packages
   - Development and visualization tools
   - Uses Python 3.11 for better compatibility

5. **05-performance-tuning.sh** 🔄 - System performance optimization
   - AMD Radeon 780M high performance mode (2800MHz memory)
   - Ryzen 9 8945HS performance governor and turbo boost
   - Memory optimization for ML workloads
   - Persistent settings with systemd service
   - Complete monitoring and restoration tools

### Additional Optimization Scripts (Optional)

6. **npu_dev_setup.sh** - NPU development environment
   - XDNA 2 NPU development tools
   - AI acceleration for supported workloads

7. **performance_tuning.sh** - Legacy performance script (use 05 instead)
   - CPU governor settings
   - Memory and kernel optimizations
   - GPU performance tuning

## 🚀 Quick Start

```bash
# Navigate to optimizations directory
cd /home/ucadmin/UC-1/UC-1_Core/optomization

# Execute core optimization chain
./01-system_prep.sh          # System preparation (may require reboot)
sudo reboot                  # Reboot after system prep
./02-rocm_ryzenai_setup.sh   # ROCm + NPU setup (requires reboot)
sudo reboot                  # Reboot after ROCm setup
./03-pytorch-setup.sh        # Set up PyTorch and AI environment
./04-ml-frameworks-setup.sh  # Advanced ML frameworks (TensorFlow, JAX, etc.)
sudo ./05-performance-tuning.sh # System performance optimization

# Optional: Additional optimizations
./npu_dev_setup.sh          # NPU development
```

## 📊 Hardware Target

- **CPU**: AMD Ryzen 9 8945HS (Zen 4, 8 cores/16 threads)
- **GPU**: AMD Radeon 780M iGPU (RDNA 3, gfx1103)
- **NPU**: AMD XDNA 2 Neural Processing Unit
- **RAM**: 32GB+ (64GB+ recommended)
- **OS**: Ubuntu 25.04 with kernel 6.14+

## 🔧 Script Details

### 01-system_prep.sh
- **Purpose**: Prepare system for optimization builds
- **Duration**: 10-15 minutes
- **Requires Reboot**: Yes (for kernel parameter changes)
- **Key Features**:
  - Memory configuration fixes
  - Build tool installation
  - Docker setup
  - Workspace preparation

### 02-rocm_ryzenai_setup.sh
- **Purpose**: Complete AMD ROCm and NPU setup
- **Duration**: 15-30 minutes
- **Requires Reboot**: Yes (for driver loading)
- **Key Features**:
  - ROCm 6.4.1 with Ubuntu 25.04 native support
  - Radeon 780M optimization (HSA_OVERRIDE_GFX_VERSION=11.0.3)
  - XDNA 2 NPU native kernel driver support
  - Vulkan Mesa drivers
  - Environment configuration

### 03-pytorch-setup.sh
- **Purpose**: Set up PyTorch with ROCm and AI environment
- **Duration**: 10-15 minutes
- **Requires Reboot**: No
- **Key Features**:
  - Python virtual environment creation
  - PyTorch ROCm 6.1 installation (compatible with ROCm 6.4.1)
  - gfx1103 environment configuration
  - Basic ML frameworks installation
  - GPU acceleration verification

### 04-ml-frameworks-setup.sh
- **Purpose**: Install advanced ML frameworks with Python 3.11
- **Duration**: 15-25 minutes
- **Requires Reboot**: No
- **Key Features**:
  - TensorFlow, JAX, ONNX Runtime (Python 3.11 compatible)
  - Advanced ML libraries (XGBoost, LightGBM, etc.)
  - Computer vision and NLP packages
  - Development tools and visualization libraries
  - Uses Python 3.11 for maximum framework compatibility

### 05-performance-tuning.sh
- **Purpose**: Optimize system performance for maximum ML throughput
- **Duration**: 5-10 minutes
- **Requires Reboot**: No (but recommended)
- **Key Features**:
  - AMD Radeon 780M high performance mode (2800MHz memory)
  - Ryzen 9 8945HS performance governor and sustained turbo
  - Memory optimization for large ML models and datasets
  - Persistent systemd service for boot-time optimization
  - Complete backup and restoration system
  - Real-time performance monitoring tools

## 📁 Generated Files and Directories

### AI Environment (`/home/ucadmin/ai-env/`)
- Python virtual environment with ROCm support
- PyTorch with ROCm 6.1 support
- ML frameworks and tools (transformers, gradio, etc.)
- Jupyter Lab and development tools

### Environment Scripts
- `~/rocm_env.sh` - ROCm environment variables
- `~/activate-uc1-ai.sh` - UC-1 AI environment activation
- `~/test_rocm.sh` - ROCm verification script
- `~/uninstall_rocm.sh` - Clean removal script

## 🧪 Verification Commands

After running the optimization chain:

```bash
# Verify ROCm installation
~/test_rocm.sh

# Verify PyTorch installation
cd /home/ucadmin/UC-1/UC-1_Core/optomization
./03-pytorch-setup.sh verify

# Check performance status
sudo ./05-performance-tuning.sh status

# Check GPU information
rocminfo | grep -A 5 "Marketing Name"
rocm-smi

# Check NPU status
lsmod | grep amdxdna
```

## 🎯 Expected Results

After successful completion:
- ✅ AMD GPU kernel module loaded (`amdgpu`)
- ✅ ROCm device detected (`gfx1103`)
- ✅ HIP platform configured (`amd`)
- ✅ OpenCL devices available (Radeon 780M)
- ✅ Vulkan devices found (Mesa driver)
- ✅ NPU/XDNA driver loaded
- ✅ PyTorch with ROCm GPU acceleration
- ✅ System performance optimized for ML workloads
- ✅ Persistent optimization settings enabled
- ✅ Complete AI environment ready

## 🔄 Script Management

### PyTorch Setup Commands
```bash
./03-pytorch-setup.sh setup     # Set up AI environment with PyTorch
./03-pytorch-setup.sh verify    # Verify PyTorch installation
./03-pytorch-setup.sh status    # Check environment status
./03-pytorch-setup.sh clean     # Remove AI environment
```

### ML Frameworks Commands
```bash
./04-ml-frameworks-setup.sh setup        # Install all advanced frameworks
./04-ml-frameworks-setup.sh tensorflow   # Install only TensorFlow
./04-ml-frameworks-setup.sh jax          # Install only JAX
./04-ml-frameworks-setup.sh onnx         # Install only ONNX Runtime
./04-ml-frameworks-setup.sh verify       # Verify all frameworks
./04-ml-frameworks-setup.sh status       # Check installation status
```

### Performance Tuning Commands
```bash
sudo ./05-performance-tuning.sh setup    # Complete performance optimization
sudo ./05-performance-tuning.sh gpu      # GPU-only optimization
sudo ./05-performance-tuning.sh cpu      # CPU-only optimization
sudo ./05-performance-tuning.sh memory   # Memory-only optimization
sudo ./05-performance-tuning.sh status   # Show current performance settings
sudo ./05-performance-tuning.sh restore  # Restore default settings
```

### Environment Activation
```bash
source ~/activate-uc1-ai.sh     # Activate UC-1 AI environment
```

## 🐛 Troubleshooting

### Common Issues
1. **ROCm not detected**: Ensure reboot after step 2
2. **GPU not available**: Check `HSA_OVERRIDE_GFX_VERSION=11.0.3`
3. **Permission errors**: Check user groups (`render`, `video`)
4. **Environment not loading**: Source `~/rocm_env.sh`

### Log Files
- System prep: `/home/ucadmin/uc1-system-prep.log`
- ROCm setup: `/home/ucadmin/rocm_setup_*.log`
- PyTorch setup: Terminal output during installation

## 📚 Documentation

- [ROCm Setup Details](./README-02-rocm_ryzenai_setup.md)
- [PyTorch Setup Guide](./README-03-pytorch-setup.md)
- [Performance Tuning Guide](./README-05-performance-tuning.md)
- [ROCm Setup Guide](./rocm_setup_readme.md)
- [UC-1 Main Documentation](../README-MODULAR-BUILD.md)

## 🔗 Related Scripts

Scripts in other directories that work with this optimization chain:
- `../source-build-scripts/02-build-pytorch.sh` - PyTorch source build
- `../source-build-scripts/04-integration.sh` - Desktop integration

---

**Version**: 1.0  
**Last Updated**: June 2025  
**Hardware**: AMD Ryzen 9 8945HS + Radeon 780M + XDNA 2  
**OS**: Ubuntu 25.04 + KDE6 + Wayland