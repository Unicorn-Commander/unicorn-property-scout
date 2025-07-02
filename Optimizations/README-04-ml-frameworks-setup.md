# UC-1 ML Frameworks Setup

## Overview

The `04-ml-frameworks-setup.sh` script extends your UC-1 AI environment by installing additional machine learning frameworks with ROCm support. This script builds upon the PyTorch environment created by `03-pytorch-setup.sh` and adds comprehensive ML ecosystem support.

## What it Does

### 🧠 Core ML Frameworks
- **TensorFlow**: Installs TensorFlow with available ROCm support
- **JAX**: Experimental JAX installation with ROCm acceleration attempts  
- **ONNX Runtime**: ONNX Runtime with ROCm provider support
- **Additional Libraries**: XGBoost, LightGBM, CatBoost, and more

### 🔬 Scientific Computing Stack
- **Core Libraries**: SciPy, SymPy, NetworkX for scientific computing
- **Visualization**: Bokeh, Altair, Plotly, Dash for data visualization
- **Optimization**: Optuna, Hyperopt for hyperparameter tuning

### 🖼️ Computer Vision Tools
- **OpenCV**: Computer vision with contrib modules
- **Modern CV**: Ultralytics YOLO, TIMM, Albumentation transforms
- **Image Processing**: imgaug for advanced augmentations

### 🗣️ Natural Language Processing
- **Core NLP**: spaCy, NLTK, Gensim for text processing
- **Tokenization**: SentencePiece, Tokenizers (HuggingFace)
- **Evaluation**: ROUGE, BLEU, evaluation metrics

### 🎵 Audio Processing
- **Audio Libraries**: librosa, soundfile for audio processing
- **Speech**: SpeechBrain for speech recognition and processing

### 🛠️ Development Tools
- **Code Quality**: Black, flake8, mypy for code formatting and linting
- **Testing**: pytest for unit testing
- **Git Tools**: pre-commit hooks, nbstripout for Jupyter notebooks

### 📊 Experiment Tracking
- **MLflow**: Experiment tracking and model registry
- **Weights & Biases**: Advanced experiment monitoring
- **TensorBoard**: Visualization and logging

## Prerequisites

1. **System Preparation**: `01-system_prep.sh` completed
2. **ROCm Installation**: `02-rocm_ryzenai_setup.sh` completed  
3. **PyTorch Environment**: `03-pytorch-setup.sh` completed with Python 3.11 environment

## Usage

### Commands

#### Complete Setup
```bash
./04-ml-frameworks-setup.sh setup
```
Installs all frameworks and libraries.

#### Basic Setup (Python 3.11 Compatible)
```bash
./04-ml-frameworks-setup.sh basic
```
Installs only packages with reliable Python 3.11 support.

#### Individual Framework Installation
```bash
./04-ml-frameworks-setup.sh tensorflow    # Install TensorFlow
./04-ml-frameworks-setup.sh jax          # Install JAX
./04-ml-frameworks-setup.sh onnx         # Install ONNX Runtime
```

#### Verification and Status
```bash
./04-ml-frameworks-setup.sh verify       # Test all frameworks
./04-ml-frameworks-setup.sh status       # Check installation status
```

### Environment Activation

The script updates your activation script with framework detection:
```bash
source ~/activate-uc1-ai-py311.sh
```

## Framework Details

### TensorFlow ROCm Support
- **Stability**: Limited for consumer GPUs like 780M
- **Recommendation**: PyTorch preferred for AMD GPU acceleration
- **Installation**: Attempts ROCm version, falls back to CPU

### JAX ROCm Support  
- **Status**: Experimental support for AMD GPUs
- **Installation**: Tries JAX[rocm], falls back to CPU version
- **Performance**: Limited optimization for consumer hardware

### ONNX Runtime ROCm
- **Providers**: Attempts ROCMExecutionProvider installation
- **Fallback**: CPU execution if ROCm provider unavailable
- **Use Case**: Model inference and cross-framework compatibility

### Additional Libraries
- **Ray**: Distributed computing framework for ML
- **XGBoost/LightGBM**: Gradient boosting frameworks
- **Ultralytics**: Modern YOLO implementation
- **TIMM**: Transformer and CNN model library

## Installation Strategy

### Graceful Failure Handling
The script uses `||` operators to continue if individual packages fail:
```bash
pip install package1 package2 || echo "Some packages failed"
```

### Package Groups
Libraries are installed in logical groups:
1. **Scientific Computing**: Core mathematical libraries
2. **ML Frameworks**: TensorFlow, JAX, ONNX
3. **Computer Vision**: OpenCV, modern CV libraries  
4. **NLP**: Text processing and language models
5. **Audio**: Speech and audio processing
6. **Development**: Code quality and testing tools

### Python 3.11 Compatibility
- Prioritizes packages with stable Python 3.11 support
- Includes fallback options for problematic packages
- Focuses on PyTorch ecosystem which has excellent 3.11 support

## Expected Outcomes

### Successful Installation
```
Available ML Frameworks:
  ✅ PyTorch 2.4.0+rocm6.1 (GPU: True)
  ✅ TensorFlow 2.x.x (Limited ROCm)
  ✅ JAX x.x.x (Experimental ROCm)
  ✅ ONNX Runtime x.x.x (ROCm Provider)
```

### Package Categories
After installation, you'll have access to:
- **15+ ML frameworks** and libraries
- **20+ computer vision** tools
- **10+ NLP libraries**
- **Audio processing** capabilities
- **Experiment tracking** tools
- **Development utilities**

## GPU Acceleration Support

### PyTorch (Primary)
- ✅ Full ROCm 6.1 support
- ✅ AMD 780M optimization
- ✅ Tested and verified GPU operations

### TensorFlow
- ⚠️ Limited consumer GPU support
- ⚠️ ROCm provider may not work on 780M
- ✅ CPU fallback always available

### JAX
- ⚠️ Experimental AMD support
- ⚠️ May default to CPU execution
- 🔬 Research and experimentation usage

### ONNX Runtime
- ⚠️ ROCm provider experimental
- ✅ Excellent CPU performance
- ✅ Cross-framework model execution

## Verification Process

The verification script tests each framework:

```python
# PyTorch GPU Test
x = torch.randn(100, 100).cuda()
y = x @ x  # Matrix multiplication on GPU

# TensorFlow GPU Test  
with tf.device('/GPU:0'):
    x = tf.random.normal([100, 100])
    y = tf.matmul(x, x)

# JAX Compute Test
x = jnp.array([[1, 2], [3, 4]])
y = jnp.dot(x, x)

# ONNX Runtime Provider Check
providers = ort.get_available_providers()
rocm_available = 'ROCMExecutionProvider' in providers
```

## Performance Considerations

### Framework Priority
1. **PyTorch**: Best AMD GPU support, use for primary ML work
2. **Scikit-learn**: Excellent for traditional ML algorithms
3. **XGBoost/LightGBM**: Optimized gradient boosting
4. **ONNX Runtime**: Cross-platform model deployment

### Memory Management
- Libraries share the Python 3.11 environment
- GPU memory shared between frameworks
- Use `torch.cuda.empty_cache()` between frameworks

### Development Workflow
- Use PyTorch for training and development
- Export to ONNX for deployment and inference
- Use traditional ML for structured data

## Troubleshooting

### Common Issues

#### Import Errors
```bash
# Activate environment first
source ~/activate-uc1-ai-py311.sh

# Check specific package
python -c "import torch; print(torch.__version__)"
```

#### GPU Not Detected
```bash
# Verify PyTorch GPU access
python -c "import torch; print(torch.cuda.is_available())"

# Check ROCm installation
rocminfo
```

#### Package Conflicts
```bash
# Update environment
pip install --upgrade pip

# Reinstall specific package
pip uninstall package_name
pip install package_name
```

### Recovery Options

#### Partial Installation Recovery
```bash
# Re-run specific framework installation
./04-ml-frameworks-setup.sh tensorflow

# Or reinstall all additional packages
./04-ml-frameworks-setup.sh basic
```

#### Environment Reset
If major issues occur:
```bash
# Remove and recreate environment (last resort)
rm -rf /home/ucadmin/ai-env-py311
./03-pytorch-setup.sh setup  # Recreate base environment
./04-ml-frameworks-setup.sh setup  # Reinstall frameworks
```

## Integration with UC-1 Pipeline

### Previous Steps
- `01-system_prep.sh`: System foundation
- `02-rocm_ryzenai_setup.sh`: ROCm and GPU support
- `03-pytorch-setup.sh`: PyTorch environment

### Next Steps
- `05-performance-tuning.sh`: System performance optimization
- `06-npu-optimization.sh`: NPU acceleration setup

### Development Workflow
```bash
# Daily activation
source ~/activate-uc1-ai-py311.sh

# Verify frameworks
./04-ml-frameworks-setup.sh verify

# Start development
jupyter lab  # or your preferred environment
```

This script creates a comprehensive ML development environment optimized for the UC-1 system's AMD hardware, with PyTorch as the primary GPU-accelerated framework and extensive ecosystem support.