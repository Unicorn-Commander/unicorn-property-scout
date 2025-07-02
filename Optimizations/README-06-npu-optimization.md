# UC-1 NPU Optimization & Tuning

## Overview

The `06-npu-optimization.sh` script provides comprehensive optimization and monitoring for the XDNA 2 NPU (Neural Processing Unit) in the AMD Ryzen 9 8945HS processor. This script creates a complete NPU development environment with performance tuning, workload balancing, and monitoring capabilities.

## What it Does

### 🔧 NPU Environment Setup
- **XRT Installation**: Verifies Xilinx Runtime (XRT) for NPU access
- **Vitis AI Workspace**: Sets up development environment with timeout handling
- **Driver Verification**: Checks XDNA driver loading and NPU device access
- **Development Tools**: Creates comprehensive NPU development toolkit

### ⚡ Performance Optimization
- **Memory Tuning**: Optimizes system memory for NPU workloads
- **Power Management**: Configures NPU and CPU power settings for maximum performance
- **DMA Buffers**: Increases DMA buffer sizes for large NPU operations
- **System Service**: Creates persistent optimization service

### 🔄 GPU/NPU Workload Balancing
- **Intelligent Distribution**: Automatically recommends GPU vs NPU for different models
- **Load Monitoring**: Real-time utilization tracking for both processors
- **Model Optimization**: Suggests optimal device based on model type and system load
- **Configuration Management**: Customizable balancing rules and thresholds

### 📊 Comprehensive Benchmarking
- **Latency Testing**: Measures NPU inference latency with statistical analysis
- **Throughput Testing**: Evaluates batch processing performance
- **Memory Benchmarking**: Tests memory allocation and transfer speeds
- **Performance Profiling**: Detailed performance characterization

### 📈 Real-time Monitoring
- **System Dashboard**: Live monitoring of NPU, GPU, CPU, and memory
- **Health Checks**: Automated NPU system health verification
- **Performance Tracking**: Historical performance data collection
- **Alert System**: Notification of performance issues

## Prerequisites

1. **System Preparation**: `01-system_prep.sh` completed
2. **ROCm Installation**: `02-rocm_ryzenai_setup.sh` completed
3. **PyTorch Environment**: `03-pytorch-setup.sh` completed
4. **ML Frameworks**: `04-ml-frameworks-setup.sh` recommended

## Commands

### Complete Setup
```bash
./06-npu-optimization.sh setup
```
Runs the complete NPU optimization pipeline.

### Individual Operations
```bash
./06-npu-optimization.sh tune        # Tune NPU performance parameters
./06-npu-optimization.sh benchmark   # Run NPU benchmarks
./06-npu-optimization.sh balance     # Configure GPU/NPU workload balancing
./06-npu-optimization.sh status      # Show NPU status and performance
./06-npu-optimization.sh monitor     # Start real-time monitoring
```

### Profile and Test
```bash
./06-npu-optimization.sh profile     # Alias for benchmark
```

## NPU Optimization Components

### Memory Optimization
```bash
# DMA Buffer Configuration
echo "134217728" > /proc/sys/kernel/dma_buf_max_size  # 128MB

# VM Memory Settings
echo "65536" > /proc/sys/vm/min_free_kbytes
echo "1" > /proc/sys/vm/compact_memory
echo "1" > /proc/sys/vm/overcommit_memory
echo "50" > /proc/sys/vm/overcommit_ratio
```

### Power Management
```bash
# NPU Always-On Mode
echo "on" > /sys/class/drm/card0/device/power/control

# Disable Runtime Power Management
echo "0" > /sys/module/xdna/parameters/power_management

# CPU Performance Mode
cpupower frequency-set -g performance
```

### Service Creation
Creates `uc1-npu-performance.service` for persistent optimizations across reboots.

## Workload Balancing System

### Intelligent Model Routing
The workload balancer analyzes models and system load to recommend optimal processing:

#### NPU-Optimized Models
- MobileNet, EfficientNet family
- YOLO object detection models
- SSD detection networks
- ResNet18, ResNet34
- Inception models

#### GPU-Preferred Models
- Large Language Models (LLaMA, GPT, BERT)
- Stable Diffusion image generation
- Whisper speech recognition
- Complex transformer architectures

### Configuration File
```json
{
  "npu_priority_models": ["mobilenet", "efficientnet", "yolo", "ssd"],
  "gpu_priority_models": ["llama", "bert", "gpt", "transformer"],
  "memory_threshold_npu": 512,
  "memory_threshold_gpu": 2048,
  "load_threshold": 0.8
}
```

### Usage Examples
```bash
# Get device recommendation
python3 workload_balancer.py recommend "mobilenet_v2"

# Monitor system balance
python3 workload_balancer.py monitor 300

# View current configuration
python3 workload_balancer.py config
```

## Benchmarking Suite

### Latency Benchmark
Tests NPU inference latency with comprehensive statistics:
- **Metrics**: Mean, median, std dev, min/max, P95/P99
- **Sample Size**: 100 inference calls
- **Output**: Detailed latency distribution analysis

### Throughput Benchmark
Evaluates batch processing performance:
- **Batch Sizes**: 1, 2, 4, 8, 16, 32
- **Duration**: 10-second test per batch size
- **Metrics**: Operations per second, efficiency curves

### Memory Benchmark
Tests NPU memory subsystem:
- **Allocation Sizes**: 1MB to 512MB
- **Metrics**: Allocation time, transfer bandwidth
- **Analysis**: Memory hierarchy performance

### Example Benchmark Results
```
UC-1 NPU Benchmark Results
==========================
Latency (ms):
  Mean: 2.34
  P95:  3.12
  P99:  4.87

Throughput:
  Peak: 1,247 ops/sec (batch size 16)

Memory:
  Peak Bandwidth: 15.2 GB/s
```

## Monitoring Tools

### Real-time Monitor (`npu_monitor.sh`)
```bash
~/npu-workspace/npu_monitor.sh
```
Displays live system dashboard with:
- NPU status and utilization
- GPU temperature and usage
- CPU and memory utilization
- Active AI processes

### Health Check (`npu_healthcheck.sh`)
```bash
~/npu-workspace/npu_healthcheck.sh
```
Comprehensive system health verification:
- XRT installation status
- NPU device access
- XDNA driver loading
- Vitis AI workspace
- Python NPU libraries
- Thermal status

### Output Files

#### Benchmark Results
```
~/npu-workspace/benchmark_results/
├── npu_benchmark_20241219_143022.json
├── npu_benchmark_20241219_150335.json
└── ...
```

#### Workspace Structure
```
~/npu-workspace/
├── Vitis-AI/                    # Vitis AI development tools
├── workload_balancer.py         # GPU/NPU workload balancer
├── npu_benchmark.py             # Performance benchmarking suite
├── npu_monitor.sh               # Real-time monitoring
├── npu_healthcheck.sh           # Health verification
├── balance_config.json          # Workload balancing configuration
└── benchmark_results/           # Historical benchmark data
```

## Integration with System

### Persistent Service
The script creates `uc1-npu-performance.service` that:
- Applies NPU optimizations at boot
- Configures memory settings
- Sets performance mode
- Enables at startup

### System Integration
```bash
# Check service status
systemctl status uc1-npu-performance

# View system information
uc-sysinfo

# Monitor NPU in real-time
./06-npu-optimization.sh monitor
```

## Performance Expectations

### NPU Characteristics
- **Optimal Models**: Computer vision, object detection
- **Memory**: Efficient for models under 512MB
- **Latency**: 1-5ms for optimized models
- **Throughput**: 1000+ ops/sec for batch processing

### System Impact
- **Memory Usage**: ~512MB reserved for NPU operations
- **Power**: Performance mode increases power consumption
- **Thermal**: Monitor temperatures during intensive workloads

## Troubleshooting

### Common Issues

#### NPU Not Detected
```bash
# Check XRT installation
which xrt-smi

# Verify driver loading
lsmod | grep xdna

# Check device nodes
ls -la /dev/accel*
```

#### Permission Issues
```bash
# Add user to render group
sudo usermod -a -G render ucadmin

# Check device permissions
ls -la /dev/accel*
```

#### Performance Issues
```bash
# Verify service is running
systemctl status uc1-npu-performance

# Check current settings
cat /proc/sys/kernel/dma_buf_max_size
cat /proc/sys/vm/min_free_kbytes
```

### Debug Commands
```bash
# NPU status
./06-npu-optimization.sh status

# Detailed health check
~/npu-workspace/npu_healthcheck.sh

# Benchmark performance
./06-npu-optimization.sh benchmark
```

## Advanced Configuration

### Custom Workload Rules
Edit `~/npu-workspace/balance_config.json`:
```json
{
  "npu_priority_models": ["custom_model_name"],
  "memory_threshold_npu": 1024,
  "load_threshold": 0.9
}
```

### Performance Tuning
```bash
# Increase DMA buffer size
echo "268435456" | sudo tee /proc/sys/kernel/dma_buf_max_size

# Adjust memory overcommit
echo "80" | sudo tee /proc/sys/vm/overcommit_ratio
```

### Model Optimization
Use Vitis AI tools for model compilation:
```bash
cd ~/npu-workspace/Vitis-AI
# Follow Vitis AI documentation for model compilation
```

## Safety Features

### Error Handling
- Network timeout protection (60 seconds for git operations)
- Graceful fallback for failed NPU operations
- Comprehensive backup and restore capabilities

### System Protection
- Non-destructive power management changes
- Reversible memory optimizations
- Service-based persistence (can be disabled)

### Monitoring Safety
- Temperature monitoring and alerts
- Resource usage tracking
- Automatic scaling based on load

## Next Steps

After NPU optimization:
1. **Test Workload Balancing**: Run mixed GPU/NPU workloads
2. **Model Optimization**: Compile models for NPU using Vitis AI
3. **Performance Monitoring**: Use monitoring tools during development
4. **Benchmark Comparison**: Compare NPU vs GPU performance for your models

The NPU optimization script completes the UC-1 system setup, providing advanced AI acceleration capabilities beyond traditional GPU computing.
