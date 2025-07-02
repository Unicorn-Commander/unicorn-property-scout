#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${PURPLE}🔄 UC-1 Migration to Python 3.11${NC}"
echo -e "${BLUE}Migrating from Python 3.13 to Python 3.11 for better ML framework support${NC}"

OLD_ENV="/home/ucadmin/ai-env"
NEW_ENV="/home/ucadmin/ai-env-py311"

print_section() {
    echo -e "\n${BLUE}[$1]${NC}"
}

print_section "Migration Plan"
echo -e "${BLUE}This script will:${NC}"
echo -e "  1. Backup your current Python 3.13 environment"
echo -e "  2. Create a new Python 3.11 environment"
echo -e "  3. Install PyTorch and ML frameworks with full compatibility"
echo -e "  4. Update activation scripts"
echo -e ""
echo -e "${BLUE}Note: Ollama installation is handled separately${NC}"
echo -e ""
echo -e "${YELLOW}Your current environment will be preserved as backup${NC}"

read -p "Continue with migration? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Migration cancelled"
    exit 1
fi

print_section "Step 1: Backup Current Environment"
if [ -d "$OLD_ENV" ]; then
    if [ ! -d "${OLD_ENV}-py313-backup" ]; then
        echo -e "${BLUE}Backing up current environment...${NC}"
        cp -r "$OLD_ENV" "${OLD_ENV}-py313-backup"
        echo -e "${GREEN}✅ Backup created at ${OLD_ENV}-py313-backup${NC}"
    else
        echo -e "${YELLOW}⚠️ Backup already exists${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ No existing environment to backup${NC}"
fi

print_section "Step 2: Create Python 3.11 Environment"
echo -e "${BLUE}Running 03-pytorch-setup-py311.sh...${NC}"
./03-pytorch-setup-py311.sh setup

print_section "Step 3: Install ML Frameworks"
echo -e "${BLUE}Running 04-ml-frameworks-setup.sh...${NC}"
./04-ml-frameworks-setup.sh setup

print_section "Step 4: Verify Installation"
./03-pytorch-setup-py311.sh verify

print_section "Migration Complete!"
echo -e "${GREEN}✅ Successfully migrated to Python 3.11${NC}"
echo -e ""
echo -e "${BLUE}Usage:${NC}"
echo -e "  ${GREEN}source ~/activate-uc1-ai-py311.sh${NC}  # New Python 3.11 environment"
echo -e "  ${GREEN}source ~/activate-uc1-ai.sh${NC}        # Redirects to Python 3.11"
echo -e ""
echo -e "${BLUE}Your old Python 3.13 environment is backed up at:${NC}"
echo -e "  ${OLD_ENV}-py313-backup"
echo -e ""
echo -e "${BLUE}Now you can install TensorFlow, JAX, and other frameworks successfully!${NC}"