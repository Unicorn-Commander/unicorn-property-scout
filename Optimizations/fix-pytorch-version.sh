#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔧 UC-1 PyTorch Version Fix${NC}"
echo -e "${BLUE}Downgrading PyTorch to 2.4.0 for better ROCm compatibility...${NC}"

AI_ENV_PATH="/home/ucadmin/ai-env-py311"

if [ ! -d "$AI_ENV_PATH" ]; then
    echo -e "${RED}❌ Python 3.11 environment not found${NC}"
    exit 1
fi

source "$AI_ENV_PATH/bin/activate"

echo -e "${BLUE}Current PyTorch version:${NC}"
python -c "import torch; print(f'PyTorch: {torch.__version__}')"

echo -e "${BLUE}Uninstalling current PyTorch...${NC}"
pip uninstall -y torch torchvision torchaudio

echo -e "${BLUE}Installing PyTorch 2.4.0 with ROCm 6.1...${NC}"
pip install torch==2.4.0+rocm6.1 torchvision==0.19.0+rocm6.1 torchaudio==2.4.0+rocm6.1 --index-url https://download.pytorch.org/whl/rocm6.1

echo -e "${GREEN}✅ PyTorch version fixed${NC}"

echo -e "${BLUE}Testing GPU functionality...${NC}"
python << 'GPUTEST'
import torch
print(f"PyTorch: {torch.__version__}")
print(f"ROCm Available: {torch.cuda.is_available()}")

if torch.cuda.is_available():
    try:
        # Test GPU operations
        x = torch.randn(100, 100, device='cuda')
        y = torch.randn(100, 100, device='cuda')
        z = torch.matmul(x, y)
        print("✅ GPU matrix multiplication: SUCCESS")
        
        # Test more operations
        z2 = torch.nn.functional.relu(z)
        print("✅ GPU ReLU operation: SUCCESS")
        
        print(f"GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
        
    except Exception as e:
        print(f"❌ GPU test failed: {e}")
        print("Try setting: export AMD_SERIALIZE_KERNEL=3")
else:
    print("❌ GPU not available")
GPUTEST

deactivate

echo -e "${GREEN}✅ PyTorch fix complete!${NC}"
echo -e "${BLUE}If you still get GPU errors, try:${NC}"
echo -e "${BLUE}export AMD_SERIALIZE_KERNEL=3${NC}"