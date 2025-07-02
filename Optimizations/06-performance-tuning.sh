#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${PURPLE}🦄 UC-1 Performance Tuning for gfx1103${NC}"
echo -e "${BLUE}Optimizing AMD Ryzen 9 8945HS + Radeon 780M for maximum ML performance...${NC}"

print_section() {
    echo -e "\n${BLUE}[$1]${NC}"
}

show_help() {
    echo -e "${BLUE}Usage: $0 [command]${NC}"
    echo -e ""
    echo -e "${BLUE}Commands:${NC}"
    echo -e "  ${GREEN}setup${NC}       Apply all performance optimizations"
    echo -e "  ${GREEN}gpu${NC}         GPU-only optimizations"
    echo -e "  ${GREEN}cpu${NC}         CPU-only optimizations"
    echo -e "  ${GREEN}memory${NC}      Memory optimizations"
    echo -e "  ${GREEN}status${NC}      Show current performance settings"
    echo -e "  ${GREEN}restore${NC}     Restore default settings"
    echo -e ""
    echo -e "${YELLOW}⚠️ This script requires sudo privileges${NC}"
    echo -e "${BLUE}Optimizations will persist across reboots${NC}"
}

check_prerequisites() {
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run with sudo${NC}"
        echo -e "${BLUE}Usage: sudo $0 [command]${NC}"
        exit 1
    fi
    
    # Check if ROCm is installed
    if ! command -v rocminfo >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️ ROCm not found - GPU optimizations may be limited${NC}"
    fi
    
    # Check if cpupower is installed
    if ! command -v cpupower >/dev/null 2>&1; then
        echo -e "${BLUE}Installing cpupower...${NC}"
        apt update && apt install -y linux-tools-common linux-tools-generic
    fi
    
    echo -e "${GREEN}✅ Prerequisites satisfied${NC}"
}

backup_current_settings() {
    print_section "Backing Up Current Settings"
    
    BACKUP_DIR="/home/ucadmin/performance-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup CPU settings
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor > "$BACKUP_DIR/cpu_governor.bak"
    fi
    
    # Backup GPU settings
    if [ -f /sys/class/drm/card0/device/power_dpm_force_performance_level ]; then
        cat /sys/class/drm/card0/device/power_dpm_force_performance_level > "$BACKUP_DIR/gpu_performance_level.bak"
    fi
    
    # Backup memory settings
    if [ -f /sys/kernel/mm/transparent_hugepage/enabled ]; then
        cat /sys/kernel/mm/transparent_hugepage/enabled > "$BACKUP_DIR/hugepage_setting.bak"
    fi
    
    echo -e "${GREEN}✅ Settings backed up to: $BACKUP_DIR${NC}"
    echo "$BACKUP_DIR" > /tmp/last_performance_backup
}

optimize_gpu() {
    print_section "GPU Performance Optimization"
    
    # Find the correct GPU card
    GPU_DEVICE=""
    for card in /sys/class/drm/card*; do
        if [ -f "$card/device/power_dpm_force_performance_level" ]; then
            GPU_DEVICE="$card/device"
            break
        fi
    done
    
    # Alternative path check
    if [ -z "$GPU_DEVICE" ]; then
        if [ -f "/sys/devices/pci0000:00/0000:00:08.1/0000:c6:00.0/power_dpm_force_performance_level" ]; then
            GPU_DEVICE="/sys/devices/pci0000:00/0000:00:08.1/0000:c6:00.0"
        fi
    fi
    
    if [ -z "$GPU_DEVICE" ]; then
        echo -e "${YELLOW}⚠️ AMD GPU performance controls not found${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Found GPU controls at: $GPU_DEVICE${NC}"
    
    echo -e "${BLUE}Setting GPU to high performance mode...${NC}"
    
    # Set GPU to high performance mode
    echo "high" > "$GPU_DEVICE/power_dpm_force_performance_level"
    echo -e "${GREEN}✅ GPU set to high performance mode${NC}"
    
    # For integrated GPUs like 780M, high performance mode handles clocks optimally
    # Manual clock setting often fails, so we skip it and let the driver optimize
    
    echo -e "${BLUE}Checking available clock controls...${NC}"
    if [ -f "$GPU_DEVICE/pp_dpm_mclk" ]; then
        echo -e "${GREEN}✅ Memory clock controls available${NC}"
        cat "$GPU_DEVICE/pp_dpm_mclk" | head -5
    fi
    
    if [ -f "$GPU_DEVICE/pp_dpm_sclk" ]; then
        echo -e "${GREEN}✅ GPU clock controls available${NC}"
        # Don't manually set clocks for integrated GPUs - high mode handles this
        echo -e "${BLUE}High performance mode will optimize clocks automatically${NC}"
    fi
    
    # Disable GPU power management for consistent performance (optional)
    if [ -f /sys/module/amdgpu/parameters/runpm ]; then
        if echo "0" > /sys/module/amdgpu/parameters/runpm 2>/dev/null; then
            echo -e "${GREEN}✅ GPU runtime power management disabled${NC}"
        else
            echo -e "${YELLOW}⚠️ GPU runtime power management setting not writable (not critical)${NC}"
        fi
    fi
    
    echo -e "${GREEN}✅ GPU optimization complete${NC}"
}

optimize_cpu() {
    print_section "CPU Performance Optimization"
    
    echo -e "${BLUE}Optimizing AMD Ryzen 9 8945HS...${NC}"
    
    # Set CPU governor to performance
    if command -v cpupower >/dev/null 2>&1; then
        cpupower frequency-set -g performance
        echo -e "${GREEN}✅ CPU governor set to performance${NC}"
    fi
    
    # Set scaling governor for all CPUs
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [ -f "$cpu" ]; then
            echo "performance" > "$cpu"
        fi
    done
    echo -e "${GREEN}✅ All CPU cores set to performance mode${NC}"
    
    # Optimize CPU frequency scaling
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq ]; then
        MAX_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq; do
            if [ -f "$cpu" ]; then
                echo $MAX_FREQ > "$cpu"
            fi
        done
        echo -e "${GREEN}✅ CPU minimum frequency set to maximum: ${MAX_FREQ} kHz${NC}"
    fi
    
    # Enable turbo boost consistency
    if [ -f /sys/devices/system/cpu/cpufreq/boost ]; then
        echo "1" > /sys/devices/system/cpu/cpufreq/boost
        echo -e "${GREEN}✅ CPU turbo boost enabled${NC}"
    fi
    
    echo -e "${GREEN}✅ CPU optimization complete${NC}"
}

optimize_memory() {
    print_section "Memory Performance Optimization"
    
    echo -e "${BLUE}Optimizing memory for ML workloads...${NC}"
    
    # Enable transparent huge pages for better memory performance
    if [ -f /sys/kernel/mm/transparent_hugepage/enabled ]; then
        echo "always" > /sys/kernel/mm/transparent_hugepage/enabled
        echo -e "${GREEN}✅ Transparent huge pages enabled${NC}"
    fi
    
    # Optimize huge page defragmentation
    if [ -f /sys/kernel/mm/transparent_hugepage/defrag ]; then
        echo "defer+madvise" > /sys/kernel/mm/transparent_hugepage/defrag
        echo -e "${GREEN}✅ Huge page defragmentation optimized${NC}"
    fi
    
    # Reduce swappiness for ML workloads (keep data in RAM)
    echo "10" > /proc/sys/vm/swappiness
    echo -e "${GREEN}✅ Swappiness set to 10 (keep data in RAM)${NC}"
    
    # Optimize dirty page writeback for better I/O
    echo "15" > /proc/sys/vm/dirty_background_ratio
    echo "25" > /proc/sys/vm/dirty_ratio
    echo -e "${GREEN}✅ Dirty page ratios optimized${NC}"
    
    # Increase max map count for large ML models
    echo "262144" > /proc/sys/vm/max_map_count
    echo -e "${GREEN}✅ Max map count increased for large models${NC}"
    
    echo -e "${GREEN}✅ Memory optimization complete${NC}"
}

create_performance_service() {
    print_section "Creating Persistent Performance Service"
    
    # Create the performance script
    cat > /usr/local/bin/uc1-performance.sh << 'PERFSCRIPT'
#!/bin/bash
# UC-1 Performance optimization script - auto-applied on boot

# GPU optimizations - find the correct card
GPU_DEVICE=""
for card in /sys/class/drm/card*; do
    if [ -f "$card/device/power_dpm_force_performance_level" ]; then
        GPU_DEVICE="$card/device"
        break
    fi
done

if [ -z "$GPU_DEVICE" ] && [ -f "/sys/devices/pci0000:00/0000:00:08.1/0000:c6:00.0/power_dpm_force_performance_level" ]; then
    GPU_DEVICE="/sys/devices/pci0000:00/0000:00:08.1/0000:c6:00.0"
fi

if [ -n "$GPU_DEVICE" ]; then
    echo "high" > "$GPU_DEVICE/power_dpm_force_performance_level"
fi

# CPU optimizations
if command -v cpupower >/dev/null 2>&1; then
    cpupower frequency-set -g performance
fi

for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    if [ -f "$cpu" ]; then
        echo "performance" > "$cpu"
    fi
done

if [ -f /sys/devices/system/cpu/cpufreq/boost ]; then
    echo "1" > /sys/devices/system/cpu/cpufreq/boost
fi

# Memory optimizations
if [ -f /sys/kernel/mm/transparent_hugepage/enabled ]; then
    echo "always" > /sys/kernel/mm/transparent_hugepage/enabled
fi

if [ -f /sys/kernel/mm/transparent_hugepage/defrag ]; then
    echo "defer+madvise" > /sys/kernel/mm/transparent_hugepage/defrag
fi

echo "10" > /proc/sys/vm/swappiness
echo "15" > /proc/sys/vm/dirty_background_ratio
echo "25" > /proc/sys/vm/dirty_ratio
echo "262144" > /proc/sys/vm/max_map_count

echo "UC-1 performance optimizations applied at $(date)"
PERFSCRIPT
    
    chmod +x /usr/local/bin/uc1-performance.sh
    
    # Create systemd service
    cat > /etc/systemd/system/uc1-performance.service << 'PERFSERVICE'
[Unit]
Description=UC-1 Performance Optimizations
After=multi-user.target
DefaultDependencies=false

[Service]
Type=oneshot
ExecStart=/usr/local/bin/uc1-performance.sh
RemainAfterExit=yes
StandardOutput=journal

[Install]
WantedBy=multi-user.target
PERFSERVICE
    
    # Enable and start service
    systemctl daemon-reload
    systemctl enable uc1-performance.service
    
    echo -e "${GREEN}✅ Performance service created and enabled${NC}"
    echo -e "${BLUE}Settings will automatically apply on every boot${NC}"
}

show_status() {
    print_section "Current Performance Status"
    
    # GPU Status
    echo -e "${BLUE}GPU Performance:${NC}"
    GPU_DEVICE=""
    for card in /sys/class/drm/card*; do
        if [ -f "$card/device/power_dpm_force_performance_level" ]; then
            GPU_DEVICE="$card/device"
            break
        fi
    done
    
    if [ -z "$GPU_DEVICE" ] && [ -f "/sys/devices/pci0000:00/0000:00:08.1/0000:c6:00.0/power_dpm_force_performance_level" ]; then
        GPU_DEVICE="/sys/devices/pci0000:00/0000:00:08.1/0000:c6:00.0"
    fi
    
    if [ -n "$GPU_DEVICE" ]; then
        LEVEL=$(cat "$GPU_DEVICE/power_dpm_force_performance_level")
        echo -e "  Performance Level: ${GREEN}$LEVEL${NC}"
    else
        echo -e "  ${YELLOW}GPU controls not available${NC}"
    fi
    
    # CPU Status
    echo -e "\n${BLUE}CPU Performance:${NC}"
    if command -v cpupower >/dev/null 2>&1; then
        GOVERNOR=$(cpupower frequency-info -p 2>/dev/null | grep "current policy" | awk '{print $4}' || echo "unknown")
        echo -e "  Governor: ${GREEN}$GOVERNOR${NC}"
    fi
    
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]; then
        FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
        FREQ_MHZ=$((FREQ / 1000))
        echo -e "  Current Frequency: ${GREEN}${FREQ_MHZ} MHz${NC}"
    fi
    
    # Memory Status
    echo -e "\n${BLUE}Memory Settings:${NC}"
    if [ -f /sys/kernel/mm/transparent_hugepage/enabled ]; then
        HUGEPAGE=$(cat /sys/kernel/mm/transparent_hugepage/enabled | grep -o '\[.*\]' | tr -d '[]')
        echo -e "  Transparent Huge Pages: ${GREEN}$HUGEPAGE${NC}"
    fi
    
    if [ -f /proc/sys/vm/swappiness ]; then
        SWAPPINESS=$(cat /proc/sys/vm/swappiness)
        echo -e "  Swappiness: ${GREEN}$SWAPPINESS${NC}"
    fi
    
    # Service Status
    echo -e "\n${BLUE}Service Status:${NC}"
    if systemctl is-enabled uc1-performance.service >/dev/null 2>&1; then
        echo -e "  UC-1 Performance Service: ${GREEN}Enabled${NC}"
    else
        echo -e "  UC-1 Performance Service: ${YELLOW}Not enabled${NC}"
    fi
}

restore_defaults() {
    print_section "Restoring Default Settings"
    
    echo -e "${YELLOW}⚠️ This will restore default performance settings${NC}"
    read -p "Continue? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled"
        exit 0
    fi
    
    # Restore GPU settings
    GPU_DEVICE=""
    for card in /sys/class/drm/card*; do
        if [ -f "$card/device/power_dpm_force_performance_level" ]; then
            GPU_DEVICE="$card/device"
            break
        fi
    done
    
    if [ -z "$GPU_DEVICE" ] && [ -f "/sys/devices/pci0000:00/0000:00:08.1/0000:c6:00.0/power_dpm_force_performance_level" ]; then
        GPU_DEVICE="/sys/devices/pci0000:00/0000:00:08.1/0000:c6:00.0"
    fi
    
    if [ -n "$GPU_DEVICE" ]; then
        echo "auto" > "$GPU_DEVICE/power_dpm_force_performance_level"
        echo -e "${GREEN}✅ GPU set to auto performance${NC}"
    fi
    
    # Restore CPU settings
    if command -v cpupower >/dev/null 2>&1; then
        cpupower frequency-set -g ondemand
        echo -e "${GREEN}✅ CPU governor set to ondemand${NC}"
    fi
    
    # Restore memory settings
    if [ -f /sys/kernel/mm/transparent_hugepage/enabled ]; then
        echo "madvise" > /sys/kernel/mm/transparent_hugepage/enabled
        echo -e "${GREEN}✅ Transparent huge pages set to madvise${NC}"
    fi
    
    echo "60" > /proc/sys/vm/swappiness
    echo -e "${GREEN}✅ Swappiness restored to 60${NC}"
    
    # Disable service
    if systemctl is-enabled uc1-performance.service >/dev/null 2>&1; then
        systemctl disable uc1-performance.service
        echo -e "${GREEN}✅ Performance service disabled${NC}"
    fi
    
    echo -e "${GREEN}✅ Default settings restored${NC}"
}

setup_all() {
    print_section "UC-1 Complete Performance Setup"
    
    check_prerequisites
    backup_current_settings
    optimize_gpu
    optimize_cpu
    optimize_memory
    create_performance_service
    
    print_section "Performance Optimization Complete!"
    echo -e "${GREEN}✅ All optimizations applied successfully${NC}"
    echo -e "${BLUE}Your UC-1 system is now optimized for maximum ML performance${NC}"
    echo -e ""
    echo -e "${BLUE}Monitoring commands:${NC}"
    echo -e "  ${GREEN}watch -n 1 rocm-smi${NC}                    # GPU monitoring"
    echo -e "  ${GREEN}watch -n 1 'cat /proc/cpuinfo | grep MHz'${NC} # CPU frequency"
    echo -e "  ${GREEN}htop${NC}                                   # System overview"
    echo -e ""
    echo -e "${YELLOW}Settings will persist across reboots${NC}"
}

# Main command processing
case "${1:-setup}" in
    "setup")
        setup_all
        ;;
    "gpu")
        check_prerequisites
        backup_current_settings
        optimize_gpu
        ;;
    "cpu")
        check_prerequisites
        backup_current_settings
        optimize_cpu
        ;;
    "memory")
        check_prerequisites
        backup_current_settings
        optimize_memory
        ;;
    "status")
        show_status
        ;;
    "restore")
        check_prerequisites
        restore_defaults
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
