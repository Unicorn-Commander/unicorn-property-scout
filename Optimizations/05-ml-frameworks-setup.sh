#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${PURPLE}🦄 UC-1 ML Frameworks Setup for gfx1103${NC}"
echo -e "${BLUE}Installing additional ML frameworks with ROCm support...${NC}"

AI_ENV_PATH="/home/ucadmin/ai-env-py311"

print_section() {
    echo -e "\n${BLUE}[$1]${NC}"
}

show_help() {
    echo -e "${BLUE}Usage: $0 [command]${NC}"
    echo -e ""
    echo -e "${BLUE}Commands:${NC}"
    echo -e "  ${GREEN}setup${NC}       Install additional ML frameworks"
    echo -e "  ${GREEN}basic${NC}       Install only Python 3.13 compatible packages"
    echo -e "  ${GREEN}tensorflow${NC} Install TensorFlow ROCm"
    echo -e "  ${GREEN}jax${NC}        Install JAX ROCm"
    echo -e "  ${GREEN}onnx${NC}       Install ONNX Runtime ROCm"
    echo -e "  ${GREEN}verify${NC}     Verify all frameworks"
    echo -e "  ${GREEN}status${NC}     Check installation status"
    echo -e ""
    echo -e "${BLUE}Prerequisites: 03-pytorch-setup-py311.sh must be completed${NC}"
    echo -e "${YELLOW}Note: Python 3.13 has limited ML framework support${NC}"
}

check_prerequisites() {
    # Check if PyTorch environment exists
    if [ ! -d "$AI_ENV_PATH" ]; then
        echo -e "${RED}❌ AI environment not found${NC}"
        echo -e "${BLUE}Please run: 03-pytorch-setup-py311.sh setup${NC}"
        exit 1
    fi
    
    # Check if ROCm is available
    if ! command -v rocminfo >/dev/null 2>&1; then
        echo -e "${RED}❌ ROCm not found${NC}"
        echo -e "${BLUE}Please run: 02-rocm_ryzenai_setup.sh${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites satisfied${NC}"
}

install_tensorflow() {
    print_section "Installing TensorFlow for ROCm"
    
    source "$AI_ENV_PATH/bin/activate"
    
    # Check Python version
    PYTHON_VERSION=$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    echo -e "${BLUE}Python version: $PYTHON_VERSION${NC}"
    
    echo -e "${BLUE}Installing TensorFlow stable version...${NC}"
    pip install tensorflow
    
    # Note about ROCm support
    echo -e "${YELLOW}Note: TensorFlow ROCm support is limited for consumer GPUs${NC}"
    
    echo -e "${GREEN}✅ TensorFlow installation attempted${NC}"
    echo -e "${YELLOW}Note: PyTorch is recommended for AMD GPU acceleration${NC}"
    deactivate
}

install_jax() {
    print_section "Installing JAX for ROCm"
    
    source "$AI_ENV_PATH/bin/activate"
    
    # Check Python version
    PYTHON_VERSION=$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    echo -e "${BLUE}Python version: $PYTHON_VERSION${NC}"
    
    echo -e "${BLUE}Installing JAX...${NC}"
    pip install --upgrade pip
    pip install jax jaxlib
    
    # Try JAX ROCm if available (experimental)
    echo -e "${BLUE}Attempting JAX ROCm installation (experimental)...${NC}"
    pip install --upgrade jax[rocm] || echo "JAX ROCm not available - using CPU version"
    
    echo -e "${GREEN}✅ JAX installation attempted${NC}"
    echo -e "${YELLOW}Note: JAX ROCm support is experimental${NC}"
    deactivate
}

install_onnx() {
    print_section "Installing ONNX Runtime for ROCm"
    
    source "$AI_ENV_PATH/bin/activate"
    
    echo -e "${BLUE}Installing ONNX Runtime...${NC}"
    
    # Install standard ONNX Runtime (ROCm version may not be available)
    pip install onnxruntime
    
    # Try ROCm version if available
    echo -e "${BLUE}Attempting ONNX Runtime ROCm installation...${NC}"
    pip install onnxruntime-rocm || echo "ONNX Runtime ROCm not available - using CPU version"
    
    # Also install ONNX tools
    pip install onnx onnxsim
    
    echo -e "${GREEN}✅ ONNX Runtime installed${NC}"
    echo -e "${YELLOW}Note: ONNX Runtime ROCm support may be limited. CPU version will be used if ROCm fails.${NC}"
    deactivate
}

# Ollama installation removed - handled by separate script

install_additional_packages() {
    print_section "Installing Additional ML Libraries"
    
    source "$AI_ENV_PATH/bin/activate"
    
    echo -e "${BLUE}Installing additional packages in groups...${NC}"
    
    # Scientific computing and visualization (basic)
    echo -e "${BLUE}Installing scientific computing packages...${NC}"
    pip install --no-deps scipy sympy networkx bokeh altair || echo "Some scientific packages failed"
    
    # Try igraph separately as it can be problematic
    pip install python-igraph || echo "python-igraph failed, trying igraph" && pip install igraph || echo "igraph packages failed"
    
    # Dash (Plotly's web framework)
    pip install dash plotly || echo "Dash/Plotly failed"
    
    # Machine learning libraries (core)
    echo -e "${BLUE}Installing ML libraries...${NC}"
    pip install xgboost lightgbm catboost || echo "Some boosting libraries failed"
    pip install optuna hyperopt || echo "Hyperparameter optimization libraries failed"
    pip install wandb tensorboard mlflow || echo "Some experiment tracking tools failed"
    
    # Ray (can be large/complex)
    echo -e "${BLUE}Installing Ray (this may take a while)...${NC}"
    pip install "ray[tune]" || echo "Ray failed - continuing without it"
    
    # Computer vision
    echo -e "${BLUE}Installing computer vision packages...${NC}"
    pip install opencv-contrib-python albumentations || echo "Some CV packages failed"
    pip install ultralytics timm || echo "Some modern CV libraries failed"
    pip install imgaug || echo "imgaug failed"
    
    # Natural language processing
    echo -e "${BLUE}Installing NLP packages...${NC}"
    pip install spacy nltk gensim || echo "Some NLP core packages failed"
    pip install sentencepiece tokenizers || echo "Some tokenizer packages failed"
    pip install evaluate rouge-score sacrebleu || echo "Some evaluation packages failed"
    
    # Audio processing
    echo -e "${BLUE}Installing audio packages...${NC}"
    pip install librosa soundfile || echo "Some audio packages failed"
    pip install speechbrain || echo "SpeechBrain failed"
    
    # Development tools
    echo -e "${BLUE}Installing development tools...${NC}"
    pip install black flake8 pytest mypy || echo "Some dev tools failed"
    pip install pre-commit nbstripout || echo "Some git tools failed"
    
    # Notebook and web tools
    echo -e "${BLUE}Installing web and notebook tools...${NC}"
    pip install voila panel || echo "Some notebook tools failed"
    pip install fastapi uvicorn || echo "Some web framework tools failed"
    
    echo -e "${GREEN}✅ Additional packages installation completed${NC}"
    echo -e "${YELLOW}Note: Some packages may have failed - this is normal${NC}"
    deactivate
}

setup_all() {
    print_section "Setting up All ML Frameworks"
    
    check_prerequisites
    
    # Install frameworks in order
    install_additional_packages
    install_tensorflow
    install_jax
    install_onnx
    
    # Update activation script
    print_section "Updating Activation Script"
    
    # Add framework info to activation script
    cat << 'FRAMEWORKS_INFO' >> ~/activate-uc1-ai-py311.sh

# Display available frameworks
echo "Available ML Frameworks:"
python -c "
import sys
frameworks = []
try:
    import torch; frameworks.append(f'PyTorch {torch.__version__}')
except: pass
try:
    import tensorflow as tf; frameworks.append(f'TensorFlow {tf.__version__}')
except: pass
try:
    import jax; frameworks.append(f'JAX {jax.__version__}')
except: pass
try:
    import onnxruntime; frameworks.append(f'ONNX Runtime {onnxruntime.__version__}')
except: pass

for fw in frameworks:
    print(f'  ✅ {fw}')
if not frameworks:
    print('  ⚠️ No frameworks detected')
"
FRAMEWORKS_INFO
    
    echo -e "${GREEN}✅ All ML frameworks setup complete!${NC}"
    echo -e "${BLUE}Activate with: source ~/activate-uc1-ai.sh${NC}"
}

verify_frameworks() {
    print_section "Verifying ML Frameworks"
    
    if [ ! -d "$AI_ENV_PATH" ]; then
        echo -e "${RED}❌ AI environment not found${NC}"
        exit 1
    fi
    
    source "$AI_ENV_PATH/bin/activate"
    
    python << 'VERIFY_FRAMEWORKS'
import sys

print("🦄 UC-1 ML Frameworks Verification")
print("=" * 50)

frameworks = []
results = {}

# Test PyTorch
try:
    import torch
    gpu_available = torch.cuda.is_available()
    results['PyTorch'] = f"{torch.__version__} (GPU: {gpu_available})"
    if gpu_available:
        try:
            x = torch.randn(100, 100).cuda()
            y = x @ x
            results['PyTorch'] += " ✅ GPU Test: PASS"
        except Exception as e:
            results['PyTorch'] += f" ❌ GPU Test: {e}"
    frameworks.append('PyTorch')
except ImportError as e:
    results['PyTorch'] = f"❌ Not installed: {e}"

# Test TensorFlow
try:
    import tensorflow as tf
    gpus = tf.config.list_physical_devices('GPU')
    results['TensorFlow'] = f"{tf.__version__} (GPUs: {len(gpus)})"
    if gpus:
        try:
            with tf.device('/GPU:0'):
                x = tf.random.normal([100, 100])
                y = tf.matmul(x, x)
            results['TensorFlow'] += " ✅ GPU Test: PASS"
        except Exception as e:
            results['TensorFlow'] += f" ❌ GPU Test: {e}"
    frameworks.append('TensorFlow')
except ImportError as e:
    results['TensorFlow'] = f"❌ Not installed: {e}"

# Test JAX
try:
    import jax
    devices = jax.devices()
    results['JAX'] = f"{jax.__version__} (Devices: {len(devices)})"
    try:
        import jax.numpy as jnp
        x = jnp.array([[1, 2], [3, 4]])
        y = jnp.dot(x, x)
        results['JAX'] += " ✅ Compute Test: PASS"
    except Exception as e:
        results['JAX'] += f" ❌ Compute Test: {e}"
    frameworks.append('JAX')
except ImportError as e:
    results['JAX'] = f"❌ Not installed: {e}"

# Test ONNX Runtime
try:
    import onnxruntime as ort
    providers = ort.get_available_providers()
    rocm_available = 'ROCMExecutionProvider' in providers
    results['ONNX Runtime'] = f"{ort.__version__} (ROCm: {rocm_available})"
    frameworks.append('ONNX Runtime')
except ImportError as e:
    results['ONNX Runtime'] = f"❌ Not installed: {e}"

# Display results
for framework, result in results.items():
    print(f"{framework:15}: {result}")

print(f"\n✅ {len(frameworks)} frameworks available")

# Test GPU memory if available
try:
    import torch
    if torch.cuda.is_available():
        props = torch.cuda.get_device_properties(0)
        print(f"\nGPU: {props.name}")
        print(f"Memory: {props.total_memory / 1024**3:.1f} GB")
        print(f"Compute: {props.major}.{props.minor}")
except:
    pass

print("\n🎯 Framework verification complete!")
VERIFY_FRAMEWORKS
    
    deactivate
}

check_status() {
    print_section "ML Frameworks Status"
    
    if [ ! -d "$AI_ENV_PATH" ]; then
        echo -e "${RED}❌ AI environment not found${NC}"
        return 1
    fi
    
    source "$AI_ENV_PATH/bin/activate"
    
    echo -e "${BLUE}Checking installed frameworks...${NC}"
    
    # Check each framework
    frameworks=("torch" "tensorflow" "jax" "onnxruntime")
    for fw in "${frameworks[@]}"; do
        if python -c "import $fw" 2>/dev/null; then
            version=$(python -c "import $fw; print($fw.__version__)" 2>/dev/null || echo "unknown")
            echo -e "${GREEN}✅ $fw: $version${NC}"
        else
            echo -e "${RED}❌ $fw: Not installed${NC}"
        fi
    done
    
    # Ollama check removed - handled by separate script
    
    deactivate
}

setup_basic() {
    print_section "Setting up Python 3.13 Compatible Packages"
    
    check_prerequisites
    
    # Only install packages that work well with Python 3.13
    install_additional_packages
    
    # Update activation script
    print_section "Updating Activation Script"
    
    cat << 'BASIC_INFO' >> ~/activate-uc1-ai-py311.sh

# Display available packages (Python 3.13 compatible)
echo "Python 3.13 Compatible ML Environment:"
python -c "
import sys
packages = []
try:
    import torch; packages.append(f'PyTorch {torch.__version__}')
except: pass
try:
    import sklearn; packages.append(f'scikit-learn {sklearn.__version__}')
except: pass
try:
    import xgboost; packages.append(f'XGBoost {xgboost.__version__}')
except: pass

for pkg in packages:
    print(f'  ✅ {pkg}')
print(f'  ✅ Python {sys.version.split()[0]}')
"
BASIC_INFO
    
    echo -e "${GREEN}✅ Python 3.13 compatible setup complete!${NC}"
    echo -e "${BLUE}Focus: PyTorch + scikit-learn + XGBoost + many utility libraries${NC}"
}

# Main command processing
case "${1:-setup}" in
    "setup")
        setup_all
        ;;
    "basic")
        setup_basic
        ;;
    "tensorflow")
        check_prerequisites
        install_tensorflow
        ;;
    "jax")
        check_prerequisites
        install_jax
        ;;
    "onnx")
        check_prerequisites
        install_onnx
        ;;
    "verify")
        verify_frameworks
        ;;
    "status")
        check_status
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
