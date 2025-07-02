#!/bin/bash
# setup_npu_dev.sh - Setup NPU development environment for XDNA 2

echo "=== Setting up NPU Development Environment ==="

# Check if XRT is installed
if ! command -v xrt-smi >/dev/null 2>&1; then
    echo "ERROR: XRT not found. Please run the main setup script first."
    exit 1
fi

# Install Vitis AI dependencies
echo "Installing Vitis AI dependencies..."
sudo apt install -y \
    libjson-c-dev \
    libgoogle-glog-dev \
    libprotobuf-dev \
    protobuf-compiler \
    libboost-all-dev

# Create NPU workspace
mkdir -p $HOME/npu-workspace
cd $HOME/npu-workspace

# Download Vitis AI runtime
echo "Downloading Vitis AI runtime..."
git clone https://github.com/Xilinx/Vitis-AI.git
cd Vitis-AI

# Create NPU test script
cat > $HOME/test_npu.py << 'EOF'
#!/usr/bin/env python3
import numpy as np
import time

try:
    import xir
    import vart
    print("✓ XIR and VART libraries loaded successfully")
    
    # List available DPU devices
    print("\nAvailable DPU devices:")
    devices = vart.get_dpu_devices()
    for i, device in enumerate(devices):
        print(f"  Device {i}: {device}")
    
except ImportError as e:
    print("✗ NPU libraries not found:", e)
    print("  Please install Vitis AI runtime")

# Simple benchmark placeholder
print("\nNPU development environment ready!")
print("Use Vitis AI tools to compile models for NPU acceleration")
EOF

chmod +x $HOME/test_npu.py

echo "NPU development setup complete!"
echo "Workspace: $HOME/npu-workspace"
echo "Test NPU: python3 $HOME/test_npu.py"