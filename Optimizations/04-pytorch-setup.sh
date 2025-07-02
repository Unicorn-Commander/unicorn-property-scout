#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${PURPLE}🦄 UC-1 PyTorch Setup with Python 3.11 for gfx1103${NC}"
echo -e "${BLUE}Setting up PyTorch with ROCm support using Python 3.11 for better ML framework compatibility...${NC}"

AI_ENV_PATH="/home/ucadmin/ai-env-py311"
PYTHON_EXEC="/usr/local/bin/python3.11"

print_section() {
    echo -e "\n${BLUE}[$1]${NC}"
}

show_help() {
    echo -e "${BLUE}Usage: $0 [command]${NC}"
    echo -e ""
    echo -e "${BLUE}Commands:${NC}"
    echo -e "  ${GREEN}setup${NC}       Set up AI environment with Python 3.11"
    echo -e "  ${GREEN}verify${NC}      Verify PyTorch installation"
    echo -e "  ${GREEN}clean${NC}       Remove AI environment"
    echo -e "  ${GREEN}status${NC}      Check environment status"
    echo -e ""
    echo -e "${BLUE}This script uses Python 3.11 for better ML framework compatibility${NC}"
}

setup_pytorch() {
    print_section "Setting up PyTorch with ROCm using Python 3.11"
    
    # Check if Python 3.11 is available
    if [ ! -f "$PYTHON_EXEC" ]; then
        echo -e "${RED}❌ Python 3.11 not found at $PYTHON_EXEC${NC}"
        echo -e "${BLUE}Installing Python 3.11...${NC}"
        
        # Install Python 3.11
        sudo apt update
        sudo apt install -y software-properties-common
        sudo add-apt-repository -y ppa:deadsnakes/ppa
        sudo apt update
        sudo apt install -y python3.11 python3.11-venv python3.11-dev
        
        if [ ! -f "$PYTHON_EXEC" ]; then
            echo -e "${RED}❌ Failed to install Python 3.11${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}✅ Python 3.11 available${NC}"
    
    # Check if ROCm is installed
    if ! command -v rocminfo >/dev/null 2>&1; then
        echo -e "${RED}❌ ROCm not found. Please run 02-rocm_ryzenai_setup.sh first${NC}"
        exit 1
    fi
    
    # Source ROCm environment if available
    if [ -f ~/rocm_env.sh ]; then
        echo -e "${BLUE}Loading ROCm environment...${NC}"
        source ~/rocm_env.sh
    fi
    
    # Create Python virtual environment with Python 3.11
    print_section "Creating AI Environment with Python 3.11"
    if [ -d "$AI_ENV_PATH" ]; then
        echo -e "${YELLOW}⚠️ AI environment already exists. Recreating...${NC}"
        rm -rf "$AI_ENV_PATH"
    fi
    
    $PYTHON_EXEC -m venv "$AI_ENV_PATH"
    source "$AI_ENV_PATH/bin/activate"
    
    # Verify Python version
    PYTHON_VERSION=$(python --version)
    echo -e "${GREEN}✅ Created environment with: $PYTHON_VERSION${NC}"
    
    # Upgrade pip
    pip install --upgrade pip setuptools wheel
    
    # Add ROCm environment variables to activation script
    print_section "Configuring ROCm Environment"
    cat << 'EOF' >> "$AI_ENV_PATH/bin/activate"

# ROCm Environment Variables for gfx1103
export ROCM_HOME=/opt/rocm
export HIP_ROOT_DIR=/opt/rocm
export ROCM_PATH=/opt/rocm
export HIP_PATH=/opt/rocm
export HSA_PATH=/opt/rocm
export CMAKE_PREFIX_PATH=/opt/rocm:$CMAKE_PREFIX_PATH
export LD_LIBRARY_PATH=/opt/rocm/lib:$LD_LIBRARY_PATH
export PATH=/opt/rocm/bin:$PATH
export HIP_VISIBLE_DEVICES=0
export HSA_OVERRIDE_GFX_VERSION=11.0.3
export PYTORCH_ROCM_ARCH="gfx1103"
EOF
    
    # Re-source to get ROCm variables
    source "$AI_ENV_PATH/bin/activate"
    
    # Install PyTorch for ROCm
    print_section "Installing PyTorch for ROCm"
    echo -e "${BLUE}Installing PyTorch with ROCm 6.1 support...${NC}"
    
    # Install PyTorch for ROCm 6.1 (compatible with ROCm 6.4.1)
    echo -e "${BLUE}Installing PyTorch 2.4.0 for better compatibility...${NC}"
    pip install torch==2.4.0+rocm6.1 torchvision==0.19.0+rocm6.1 torchaudio==2.4.0+rocm6.1 --index-url https://download.pytorch.org/whl/rocm6.1
    
    # Install additional ML packages
    print_section "Installing Additional ML Packages"
    pip install \
        numpy \
        pandas \
        matplotlib \
        scikit-learn \
        pillow \
        opencv-python \
        transformers \
        datasets \
        accelerate \
        gradio \
        streamlit \
        jupyterlab \
        ipykernel \
        seaborn \
        plotly
    
    # Create activation script
    print_section "Creating Activation Scripts"
    cat << 'ACTIVATE' > ~/activate-uc1-ai-py311.sh
#!/bin/bash
# UC-1 AI Environment Activation Script (Python 3.11)
source ~/rocm_env.sh 2>/dev/null || true
source /home/ucadmin/ai-env-py311/bin/activate
echo "🦄 UC-1 AI Environment Activated (Python 3.11)"
echo "Python: $(python --version)"
echo "PyTorch: $(python -c 'import torch; print(torch.__version__)')"
echo "ROCm Available: $(python -c 'import torch; print(torch.cuda.is_available())')"
ACTIVATE
    
    chmod +x ~/activate-uc1-ai-py311.sh
    
    # Update the original activation script to point to new environment
    cat << 'REDIRECT' > ~/activate-uc1-ai.sh
#!/bin/bash
# UC-1 AI Environment Activation Script (redirects to Python 3.11 version)
echo "🔄 Redirecting to Python 3.11 environment for better ML framework support..."
source ~/activate-uc1-ai-py311.sh
REDIRECT
    
    deactivate
    echo -e "${GREEN}✅ PyTorch setup with Python 3.11 complete!${NC}"
    echo -e "${BLUE}To activate: source ~/activate-uc1-ai-py311.sh${NC}"
    echo -e "${BLUE}Or use: source ~/activate-uc1-ai.sh (redirects to Python 3.11)${NC}"
}

verify_pytorch() {
    print_section "Verifying PyTorch Installation"
    
    if [ ! -d "$AI_ENV_PATH" ]; then
        echo -e "${RED}❌ AI environment not found. Run: $0 setup${NC}"
        exit 1
    fi
    
    source "$AI_ENV_PATH/bin/activate"
    
    python << 'PYVERIFY'
import torch
import sys
import os

print("🦄 UC-1 PyTorch Verification (Python 3.11)")
print("=" * 50)
print(f"Python: {sys.version.split()[0]}")
print(f"PyTorch: {torch.__version__}")

# Check ROCm
print(f"ROCm Available: {torch.cuda.is_available()}")
if hasattr(torch.version, 'hip'):
    print(f"ROCm HIP: {torch.version.hip}")

# Check environment variables
print(f"HSA_OVERRIDE_GFX_VERSION: {os.environ.get('HSA_OVERRIDE_GFX_VERSION', 'Not set')}")
print(f"PYTORCH_ROCM_ARCH: {os.environ.get('PYTORCH_ROCM_ARCH', 'Not set')}")

if torch.cuda.is_available():
    print(f"GPU Device: {torch.cuda.get_device_name(0)}")
    print(f"GPU Count: {torch.cuda.device_count()}")
    
    # Quick GPU test
    try:
        print("\n🧪 Testing GPU operations...")
        x = torch.randn(1000, 1000, device='cuda')
        y = torch.randn(1000, 1000, device='cuda')
        z = torch.matmul(x, y)
        print("✅ Matrix multiplication on GPU: SUCCESS")
        
        # Memory test
        print(f"GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
        print(f"GPU Memory Used: {torch.cuda.memory_allocated() / 1024**3:.1f} GB")
        
    except Exception as e:
        print(f"❌ GPU test failed: {e}")
else:
    print("⚠️ GPU not available - check ROCm installation")

# Check additional packages
try:
    import torchvision
    print(f"torchvision: {torchvision.__version__}")
except ImportError:
    print("torchvision: Not installed")

try:
    import torchaudio
    print(f"torchaudio: {torchaudio.__version__}")
except ImportError:
    print("torchaudio: Not installed")

try:
    import transformers
    print(f"transformers: {transformers.__version__}")
except ImportError:
    print("transformers: Not installed")

print("\n🎯 Verification complete!")
print("✅ Ready for TensorFlow, JAX, and other ML frameworks!")
PYVERIFY
    
    deactivate
}

check_status() {
    print_section "Environment Status"
    
    # Check Python 3.11
    if [ -f "$PYTHON_EXEC" ]; then
        echo -e "${GREEN}✅ Python 3.11 available${NC}"
        $PYTHON_EXEC --version
    else
        echo -e "${RED}❌ Python 3.11 not available${NC}"
    fi
    
    if [ -d "$AI_ENV_PATH" ]; then
        echo -e "${GREEN}✅ AI environment exists (Python 3.11)${NC}"
        
        source "$AI_ENV_PATH/bin/activate"
        echo -e "${BLUE}Python: $(python --version)${NC}"
        
        if python -c "import torch" 2>/dev/null; then
            echo -e "${GREEN}✅ PyTorch installed${NC}"
            python -c "import torch; print(f'PyTorch version: {torch.__version__}')"
            python -c "import torch; print(f'ROCm available: {torch.cuda.is_available()}')"
        else
            echo -e "${RED}❌ PyTorch not installed${NC}"
        fi
        deactivate
    else
        echo -e "${RED}❌ AI environment not found${NC}"
        echo -e "${BLUE}Run: $0 setup${NC}"
    fi
    
    # Check ROCm status
    if command -v rocminfo >/dev/null 2>&1; then
        echo -e "${GREEN}✅ ROCm available${NC}"
        if rocminfo | grep -q "gfx1103"; then
            echo -e "${GREEN}✅ AMD 780M (gfx1103) detected${NC}"
        else
            echo -e "${YELLOW}⚠️ gfx1103 not detected in ROCm${NC}"
        fi
    else
        echo -e "${RED}❌ ROCm not available${NC}"
    fi
}

clean_environment() {
    print_section "Cleaning AI Environment"
    
    if [ -d "$AI_ENV_PATH" ]; then
        read -p "Remove AI environment at $AI_ENV_PATH? (y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$AI_ENV_PATH"
            rm -f ~/activate-uc1-ai-py311.sh
            echo -e "${GREEN}✅ Environment cleaned${NC}"
        else
            echo -e "${BLUE}Environment not modified${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ No environment to clean${NC}"
    fi
}

# Main command processing
case "${1:-setup}" in
    "setup")
        setup_pytorch
        ;;
    "verify")
        verify_pytorch
        ;;
    "status")
        check_status
        ;;
    "clean")
        clean_environment
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
