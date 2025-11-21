#!/usr/bin/env bash
#
# Archgle Hardware-Aware Performance Optimization
# Detects hardware and applies appropriate optimizations
#

set -euo pipefail

PERF_PROFILE="/etc/archgle/performance-profile"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[Performance]${NC} $*"
}

success() {
    echo -e "${GREEN}✓${NC} $*"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

detect_hardware() {
    log "Detecting hardware capabilities..."
    
    # CPU info
    CPU_CORES=$(nproc)
    CPU_MODEL=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
    
    # RAM (in GB)
    RAM_GB=$(free -g | awk '/^Mem:/ {print $2}')
    
    # Storage type
    if lsblk -d -o name,rota | grep -q "0$"; then
        STORAGE="ssd"
    else
        STORAGE="hdd"
    fi
    
    # GPU detection
    GPU_VENDOR="none"
    if lspci | grep -i "vga\|3d" | grep -qi "nvidia"; then
        GPU_VENDOR="nvidia"
    elif lspci | grep -i "vga\|3d" | grep -qi "amd"; then
        GPU_VENDOR="amd"
    elif lspci | grep -i "vga\|3d" | grep -qi "intel"; then
        GPU_VENDOR="intel"
    fi
    
    # NPU detection (Intel AI accelerators, AMD XDNA, etc.)
    NPU_PRESENT="no"
    if lspci | grep -qi "accelerator\|npu\|ai"; then
        NPU_PRESENT="yes"
    fi
    
    echo ""
    success "CPU: $CPU_MODEL ($CPU_CORES cores)"
    success "RAM: ${RAM_GB}GB"
    success "Storage: $STORAGE"
    success "GPU: $GPU_VENDOR"
    success "NPU: $NPU_PRESENT"
    echo ""
}

choose_profile() {
    # Determine performance profile based on hardware
    if [[ $RAM_GB -ge 16 && $CPU_CORES -ge 8 && "$STORAGE" == "ssd" ]]; then
        PROFILE="performance"
    elif [[ $RAM_GB -ge 8 && $CPU_CORES -ge 4 ]]; then
        PROFILE="balanced"
    else
        PROFILE="efficiency"
    fi
    
    log "Recommended profile: $PROFILE"
    
    # Allow override
    read -p "Use this profile? (y/n) or choose (p)erformance/(b)alanced/(e)fficiency: " choice
    
    case "$choice" in
        p) PROFILE="performance" ;;
        b) PROFILE="balanced" ;;
        e) PROFILE="efficiency" ;;
        n)
            echo "Skipping performance optimization"
            exit 0
            ;;
    esac
    
    echo "$PROFILE" > "$PERF_PROFILE"
    log "Using profile: $PROFILE"
}

optimize_cpu() {
    log "Optimizing CPU settings..."
    
    case "$PROFILE" in
        performance)
            # Maximum performance
            echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
            success "CPU governor: performance"
            ;;
        balanced)
            # Balanced
            echo "schedutil" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
            success "CPU governor: schedutil"
            ;;
        efficiency)
            # Power saving with boost
            echo "powersave" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
            success "CPU governor: powersave"
            ;;
    esac
}

optimize_memory() {
    log "Optimizing memory settings..."
    
    case "$PROFILE" in
        performance)
            # Minimal swap, aggressive caching
            sudo sysctl -w vm.swappiness=10
            sudo sysctl -w vm.vfs_cache_pressure=50
            success "Swappiness: 10 (minimal swap)"
            ;;
        balanced)
            # Moderate swap
            sudo sysctl -w vm.swappiness=30
            sudo sysctl -w vm.vfs_cache_pressure=100
            success "Swappiness: 30 (balanced)"
            ;;
        efficiency)
            # Use zram for memory efficiency
            if ! lsblk | grep -q zram; then
                sudo modprobe zram
                echo "lz4" | sudo tee /sys/block/zram0/comp_algorithm > /dev/null
                echo "${RAM_GB}G" | sudo tee /sys/block/zram0/disksize > /dev/null
                sudo mkswap /dev/zram0
                sudo swapon /dev/zram0 -p 100
                success "Zram enabled (${RAM_GB}GB compressed swap)"
            fi
            sudo sysctl -w vm.swappiness=60
            ;;
    esac
}

optimize_io() {
    log "Optimizing I/O scheduler..."
    
    for disk in /sys/block/sd* /sys/block/nvme*; do
        if [[ -e "$disk/queue/scheduler" ]]; then
            disk_name=$(basename "$disk")
            
            case "$PROFILE" in
                performance)
                    if [[ "$STORAGE" == "ssd" ]]; then
                        echo "none" | sudo tee "$disk/queue/scheduler" > /dev/null
                        success "$disk_name: none (SSD optimized)"
                    else
                        echo "mq-deadline" | sudo tee "$disk/queue/scheduler" > /dev/null
                        success "$disk_name: mq-deadline"
                    fi
                    ;;
                balanced|efficiency)
                    echo "bfq" | sudo tee "$disk/queue/scheduler" > /dev/null
                    success "$disk_name: bfq (balanced)"
                    ;;
            esac
        fi
    done
}

optimize_gpu() {
    log "Optimizing GPU settings..."
    
    case "$GPU_VENDOR" in
        nvidia)
            # NVIDIA optimizations
            if command -v nvidia-settings &> /dev/null; then
                if [[ "$PROFILE" == "performance" ]]; then
                    sudo nvidia-smi -pm 1  # Persistence mode
                    sudo nvidia-smi -pl 0   # Max power limit
                    success "NVIDIA: Maximum performance mode"
                fi
            fi
            
            # Ensure modules are loaded
            sudo modprobe nvidia nvidia_modeset nvidia_uvm nvidia_drm
            success "NVIDIA modules loaded"
            ;;
        amd)
            # AMD optimizations
            if [[ "$PROFILE" == "performance" ]]; then
                echo "high" | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level > /dev/null 2>&1 || true
                success "AMD: High performance mode"
            fi
            
            # ROCm support
            if command -v rocm-smi &> /dev/null; then
                success "AMD ROCm detected"
            fi
            ;;
        intel)
            # Intel optimizations
            sudo modprobe i915
            
            # Enable GuC/HuC firmware
            echo "options i915 enable_guc=2" | sudo tee /etc/modprobe.d/i915.conf > /dev/null
            success "Intel GPU optimizations applied"
            ;;
    esac
}

optimize_npu() {
    if [[ "$NPU_PRESENT" == "yes" ]]; then
        log "Configuring NPU for AI acceleration..."
        
        # Intel NPU (Meteor Lake+)
        if lspci | grep -qi "intel.*ai"; then
            # Load Intel NPU drivers
            sudo modprobe intel_vpu || warn "Intel NPU driver not available"
            
            # Set up OpenVINO if available
            if [[ -d "/opt/intel/openvino" ]]; then
                source /opt/intel/openvino/setupvars.sh 2>/dev/null || true
                success "OpenVINO configured for Intel NPU"
            fi
        fi
        
        # AMD XDNA NPU
        if lspci | grep -qi "amd.*ai\|xdna"; then
            warn "AMD NPU detected - driver support may vary"
        fi
        
        success "NPU optimizations applied"
    fi
}

make_persistent() {
    log "Making optimizations persistent..."
    
    # Create sysctl config
    sudo tee /etc/sysctl.d/99-archgle-performance.conf > /dev/null << EOF
# Archgle Performance Optimizations
# Profile: $PROFILE

# Memory management
vm.swappiness=$(grep swappiness /proc/sys/vm/swappiness | cut -d'=' -f2 || echo 30)
vm.vfs_cache_pressure=$(grep vfs_cache_pressure /proc/sys/vm/vfs_cache_pressure | cut -d'=' -f2 || echo 100)

# Network performance
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
EOF
    
    success "Sysctl configuration saved"
}

main() {
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}  Archgle Hardware-Aware Optimization  ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo ""
    
    mkdir -p /etc/archgle
    
    detect_hardware
    choose_profile
    
    echo ""
    log "Applying optimizations..."
    echo ""
    
    optimize_cpu
    optimize_memory
    optimize_io
    optimize_gpu
    optimize_npu
    make_persistent
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}  Optimization complete!                ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo ""
    
    log "Profile: $PROFILE"
    log "Configuration saved to: $PERF_PROFILE"
    echo ""
}

main "$@"
