# 03-pytorch-setup.sh Documentation

PyTorch and AI Environment Setup for UC-1 with ROCm Support

## Overview

This script sets up a complete Python AI environment with PyTorch optimized for AMD Radeon 780M (gfx1103) using ROCm 6.4.1. It creates a virtual environment, installs PyTorch with ROCm support, and configures all necessary environment variables for GPU acceleration.

## Prerequisites

- **01-system_prep.sh** must be completed
- **02-rocm_ryzenai_setup.sh** must be completed and system rebooted
- ROCm 6.4.1 installed and functional
- User added to `render` and `video` groups

## System Requirements

### Hardware
- **CPU**: AMD Ryzen 9 8945HS (or compatible Zen 4)
- **GPU**: AMD Radeon 780M integrated GPU (RDNA 3, gfx1103)
- **RAM**: 16GB minimum (32GB+ recommended)
- **Storage**: 5GB free space for AI environment

### Software
- **OS**: Ubuntu 25.04 with kernel 6.14+
- **ROCm**: 6.4.1 (installed via 02-rocm_ryzenai_setup.sh)
- **Python**: 3.10+ (system Python)

## What Gets Installed

### Python Environment
- **Virtual Environment**: `/home/ucadmin/ai-env/`
- **Python**: System Python 3.10+ with pip, setuptools, wheel
- **Activation Script**: `~/activate-uc1-ai.sh`

### PyTorch Stack
- **torch**: PyTorch with ROCm 6.1 support (compatible with ROCm 6.4.1)
- **torchvision**: Computer vision library
- **torchaudio**: Audio processing library

### Machine Learning Packages
- **transformers**: Hugging Face transformers library
- **datasets**: Dataset loading and processing
- **accelerate**: Training acceleration library
- **gradio**: Web UI for ML models
- **streamlit**: Data app framework

### Development Tools
- **jupyterlab**: Jupyter notebook environment
- **ipykernel**: Jupyter kernel support

### Data Science Libraries
- **numpy**: Numerical computing
- **pandas**: Data manipulation and analysis
- **matplotlib**: Plotting library
- **seaborn**: Statistical visualization
- **plotly**: Interactive plotting
- **scikit-learn**: Machine learning library
- **pillow**: Image processing
- **opencv-python**: Computer vision library

## Usage

### Basic Setup (Default)

```bash
cd /home/ucadmin/UC-1/UC-1_Core/optomization
./03-pytorch-setup.sh
```

This runs the default `setup` command.

### All Available Commands

```bash
# Set up complete AI environment
./03-pytorch-setup.sh setup

# Verify PyTorch and GPU functionality
./03-pytorch-setup.sh verify

# Check environment status
./03-pytorch-setup.sh status

# Remove AI environment
./03-pytorch-setup.sh clean

# Show help
./03-pytorch-setup.sh help
```

## Installation Process

### Step 1: ROCm Verification
- Checks that ROCm is installed and accessible
- Sources ROCm environment variables from `~/rocm_env.sh`
- Verifies ROCm commands are available

### Step 2: Virtual Environment Creation
- Creates Python virtual environment at `/home/ucadmin/ai-env/`
- Upgrades pip, setuptools, and wheel
- Removes existing environment if present

### Step 3: ROCm Environment Configuration
- Adds ROCm environment variables to activation script:
  - `ROCM_HOME=/opt/rocm`
  - `HIP_ROOT_DIR=/opt/rocm`
  - `ROCM_PATH=/opt/rocm`
  - `HIP_PATH=/opt/rocm`
  - `HSA_PATH=/opt/rocm`
  - `CMAKE_PREFIX_PATH=/opt/rocm:$CMAKE_PREFIX_PATH`
  - `LD_LIBRARY_PATH=/opt/rocm/lib:$LD_LIBRARY_PATH`
  - `PATH=/opt/rocm/bin:$PATH`
  - `HIP_VISIBLE_DEVICES=0`
  - `HSA_OVERRIDE_GFX_VERSION=11.0.3`
  - `PYTORCH_ROCM_ARCH="gfx1103"`

### Step 4: PyTorch Installation
- Installs PyTorch stack from ROCm 6.1 index
- Downloads from: `https://download.pytorch.org/whl/rocm6.1`
- Ensures ROCm 6.1 compatibility with ROCm 6.4.1 runtime

### Step 5: ML Framework Installation
- Installs comprehensive ML and data science packages
- Configures Jupyter Lab for notebook development
- Sets up web frameworks for model deployment

### Step 6: Activation Script Creation
- Creates `~/activate-uc1-ai.sh` convenience script
- Auto-sources ROCm environment and activates Python environment
- Shows PyTorch version and GPU availability on activation

## Generated Files

### AI Environment Directory
```
/home/ucadmin/ai-env/
├── bin/
│   ├── activate          # Modified with ROCm variables
│   ├── python            # Python interpreter
│   └── pip               # Package manager
├── lib/
│   └── python3.*/
│       └── site-packages/ # Installed packages
└── pyvenv.cfg            # Environment configuration
```

### Activation Script
```bash
~/activate-uc1-ai.sh      # Convenience activation script
```

## Environment Activation

### Method 1: Convenience Script (Recommended)
```bash
source ~/activate-uc1-ai.sh
```

### Method 2: Direct Activation
```bash
source ~/rocm_env.sh
source /home/ucadmin/ai-env/bin/activate
```

### Method 3: Manual Setup
```bash
source /home/ucadmin/ai-env/bin/activate
export HSA_OVERRIDE_GFX_VERSION=11.0.3
export PYTORCH_ROCM_ARCH="gfx1103"
```

## Verification

### Quick Verification
```bash
./03-pytorch-setup.sh verify
```

### Manual Verification
```bash
source ~/activate-uc1-ai.sh

python -c "
import torch
print(f'PyTorch: {torch.__version__}')
print(f'ROCm Available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'GPU: {torch.cuda.get_device_name(0)}')
"
```

### Expected Output
```
🦄 UC-1 PyTorch Verification
========================================
Python: 3.10.12
PyTorch: 2.1.0+rocm6.1
ROCm Available: True
GPU Device: AMD Radeon Graphics
GPU Count: 1

🧪 Testing GPU operations...
✅ Matrix multiplication on GPU: SUCCESS
GPU Memory: 8.0 GB
GPU Memory Used: 0.0 GB

torchvision: 0.16.0+rocm6.1
torchaudio: 2.1.0+rocm6.1
transformers: 4.36.0

🎯 Verification complete!
```

## GPU Memory Management

### AMD 780M Specifications
- **Total Memory**: ~8GB (shared system RAM)
- **Architecture**: RDNA 3 (gfx1103)
- **Compute Units**: 12
- **Peak Performance**: ~8.6 TFLOPS

### Memory Optimization
```python
import torch

# Clear GPU cache
torch.cuda.empty_cache()

# Check memory usage
print(f"Allocated: {torch.cuda.memory_allocated() / 1024**3:.1f} GB")
print(f"Reserved: {torch.cuda.memory_reserved() / 1024**3:.1f} GB")
```

## Common Use Cases

### Running Transformers Models
```bash
source ~/activate-uc1-ai.sh

python -c "
from transformers import pipeline
classifier = pipeline('sentiment-analysis', device=0)  # GPU
result = classifier('I love PyTorch on ROCm!')
print(result)
"
```

### Jupyter Lab Development
```bash
source ~/activate-uc1-ai.sh
jupyter lab --ip=0.0.0.0 --port=8888
```

### Gradio Model Deployment
```bash
source ~/activate-uc1-ai.sh

python -c "
import gradio as gr
import torch

def gpu_test(text):
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    return f'Using device: {device} | Input: {text}'

gr.Interface(gpu_test, 'text', 'text').launch()
"
```

## Troubleshooting

### ROCm Not Detected
```bash
# Check ROCm installation
rocminfo | grep "Marketing Name"

# Check user groups
groups | grep -E "render|video"

# Re-run ROCm setup if needed
./02-rocm_ryzenai_setup.sh
```

### PyTorch GPU Not Available
```bash
# Check environment variables
echo $HSA_OVERRIDE_GFX_VERSION  # Should be 11.0.3
echo $PYTORCH_ROCM_ARCH         # Should be gfx1103

# Recreate environment
./03-pytorch-setup.sh clean
./03-pytorch-setup.sh setup
```

### Permission Errors
```bash
# Fix device permissions
sudo chmod 666 /dev/kfd
sudo chmod 666 /dev/dri/render*

# Add user to groups
sudo usermod -a -G render,video $USER
# Logout and login again
```

### Memory Issues
```bash
# Monitor GPU memory
watch -n 1 'rocm-smi --showmeminfo vram'

# In Python - clear cache
python -c "import torch; torch.cuda.empty_cache()"
```

### Package Installation Failures
```bash
# Update pip
source ~/activate-uc1-ai.sh
pip install --upgrade pip setuptools wheel

# Reinstall specific package
pip install --force-reinstall torch --index-url https://download.pytorch.org/whl/rocm6.1
```

## Performance Optimization

### GPU Performance Settings
```bash
# Set GPU to high performance (requires sudo)
echo "high" | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level

# Monitor GPU usage
rocm-smi --showuse --showtemp --showfan
```

### Memory Optimization
```bash
# Set memory allocation strategy
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
```

## Environment Management

### Backup Environment
```bash
# Create requirements file
source ~/activate-uc1-ai.sh
pip freeze > ~/uc1-ai-requirements.txt
```

### Restore Environment
```bash
./03-pytorch-setup.sh clean
./03-pytorch-setup.sh setup
source ~/activate-uc1-ai.sh
pip install -r ~/uc1-ai-requirements.txt
```

### Update Packages
```bash
source ~/activate-uc1-ai.sh
pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.1
pip install --upgrade transformers gradio streamlit jupyterlab
```

## Integration with Other Tools

### VS Code Integration
1. Install Python extension in VS Code
2. Set Python interpreter: `/home/ucadmin/ai-env/bin/python`
3. ROCm environment variables will be automatically loaded

### Docker Integration
```dockerfile
FROM pytorch/pytorch:2.1.0-devel-rocm6.1-ubuntu22.04
COPY requirements.txt .
RUN pip install -r requirements.txt
ENV HSA_OVERRIDE_GFX_VERSION=11.0.3
ENV PYTORCH_ROCM_ARCH=gfx1103
```

## Version Information

- **Script Version**: 1.0
- **PyTorch Version**: 2.1.0+rocm6.1
- **ROCm Compatibility**: 6.1 (runtime 6.4.1)
- **Target Hardware**: AMD Radeon 780M (gfx1103)
- **Last Updated**: June 2025

## Security Considerations

- Virtual environment isolates packages from system Python
- No sudo required for normal operation
- ROCm device permissions handled by user groups
- All packages installed from official PyTorch and PyPI repositories

## License and Support

This script configures open-source software:
- **PyTorch**: BSD-style license
- **ROCm**: MIT/Apache licenses
- **Python packages**: Various open-source licenses

For issues:
1. Run verification: `./03-pytorch-setup.sh verify`
2. Check ROCm status: `~/test_rocm.sh`
3. Review PyTorch ROCm documentation
4. Check AMD ROCm GitHub issues

## Related Documentation

- [ROCm Setup Guide](./README-02-rocm_ryzenai_setup.md)
- [UC-1 Optimization Chain](./README.md)
- [PyTorch ROCm Documentation](https://pytorch.org/get-started/locally/)
- [AMD ROCm Documentation](https://rocm.docs.amd.com/)