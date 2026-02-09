#!/bin/bash
#
# RPCS3 Diagnostic Tool for macOS
# Checks installation and identifies potential issues
#

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Paths
readonly RPCS3_APP="/Applications/RPCS3.app"
readonly RPCS3_DATA="$HOME/Library/Application Support/rpcs3"
readonly CONFIG_FILE="$RPCS3_DATA/config.yml"

info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
}

success() {
    echo -e "${GREEN}✅ $*${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $*${NC}"
}

error() {
    echo -e "${RED}❌ $*${NC}"
}

check() {
    echo -n "  "
    if "$@"; then
        success "$1: OK"
        return 0
    else
        error "$1: FAILED"
        return 1
    fi
}

# Header
clear
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║         RPCS3 Diagnostic Tool for macOS               ║
║                                                       ║
║          Checking your installation...                ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""

# System Information
echo -e "${BLUE}━━━ System Information ━━━${NC}"
echo ""
info "macOS Version: $(sw_vers -productVersion)"
info "Architecture: $(uname -m)"
info "Kernel: $(uname -r)"
info "Model: $(sysctl -n hw.model)"

if [[ $(uname -m) == "arm64" ]]; then
    info "CPU: Apple Silicon (M-series)"
    if ! pgrep oahd > /dev/null; then
        warning "Rosetta 2 may not be running"
        echo "    Install with: softwareupdate --install-rosetta"
    else
        success "Rosetta 2 is running"
    fi
else
    info "CPU: $(sysctl -n machdep.cpu.brand_string)"
fi

info "RAM: $(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024)) GB"
echo ""

# RPCS3 Installation Check
echo -e "${BLUE}━━━ RPCS3 Installation ━━━${NC}"
echo ""

if [[ -d "$RPCS3_APP" ]]; then
    success "RPCS3 is installed at: $RPCS3_APP"
    
    # Get version
    if [[ -f "$RPCS3_APP/Contents/Info.plist" ]]; then
        version=$(defaults read "$RPCS3_APP/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "Unknown")
        info "Version: $version"
    fi
    
    # Check executable
    if [[ -x "$RPCS3_APP/Contents/MacOS/rpcs3" ]]; then
        success "Executable is present and runnable"
    else
        error "Executable not found or not executable"
    fi
    
    # Check quarantine
    if xattr -l "$RPCS3_APP" 2>/dev/null | grep -q "com.apple.quarantine"; then
        warning "App has quarantine attribute (may prevent launch)"
        info "Fix with: sudo xattr -rd com.apple.quarantine '$RPCS3_APP'"
    else
        success "No quarantine attribute"
    fi
else
    error "RPCS3 is not installed at $RPCS3_APP"
fi
echo ""

# Data Directory Check
echo -e "${BLUE}━━━ Data Directory ━━━${NC}"
echo ""

if [[ -d "$RPCS3_DATA" ]]; then
    success "Data directory exists: $RPCS3_DATA"
    
    # Check subdirectories
    for dir in "dev_hdd0" "dev_flash" "cache" "games"; do
        if [[ -d "$RPCS3_DATA/$dir" ]]; then
            success "$dir directory exists"
        else
            warning "$dir directory missing (may be created on first launch)"
        fi
    done
    
    # Check config
    if [[ -f "$CONFIG_FILE" ]]; then
        success "Configuration file exists"
        
        # Check if valid YAML
        if python3 -c "import yaml; yaml.safe_load(open('$CONFIG_FILE'))" 2>/dev/null; then
            success "Configuration file is valid YAML"
        else
            warning "Configuration file may be corrupted"
        fi
    else
        warning "Configuration file missing (will be created on first launch)"
    fi
else
    warning "Data directory doesn't exist yet (normal for first install)"
fi
echo ""

# Firmware Check
echo -e "${BLUE}━━━ PS3 Firmware ━━━${NC}"
echo ""

if [[ -d "$RPCS3_DATA/dev_flash" ]]; then
    firmware_count=$(find "$RPCS3_DATA/dev_flash" -name "*.SELF" 2>/dev/null | wc -l)
    if [[ $firmware_count -gt 100 ]]; then
        success "PS3 firmware appears to be installed ($firmware_count system files)"
    else
        warning "PS3 firmware may not be installed completely"
        info "Install via: RPCS3 → File → Install Firmware"
    fi
else
    warning "PS3 firmware not installed"
    info "Download from: https://www.playstation.com/en-us/support/hardware/ps3/system-software/"
fi
echo ""

# Graphics Check
echo -e "${BLUE}━━━ Graphics Capabilities ━━━${NC}"
echo ""

# Check for Metal support
if system_profiler SPDisplaysDataType 2>/dev/null | grep -q "Metal"; then
    success "Metal support detected"
else
    warning "Metal support not detected"
fi

# Check GPU
gpu_info=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" | head -1 | cut -d ":" -f2 | xargs)
if [[ -n "$gpu_info" ]]; then
    info "GPU: $gpu_info"
else
    warning "Could not detect GPU"
fi

# Vulkan check
if [[ -d "/usr/local/lib" ]] && find /usr/local/lib -name "*vulkan*" -o -name "*MoltenVK*" 2>/dev/null | grep -q .; then
    success "Vulkan libraries found"
else
    warning "Vulkan/MoltenVK not detected (RPCS3 may include it)"
fi
echo ""

# Disk Space
echo -e "${BLUE}━━━ Disk Space ━━━${NC}"
echo ""

available_space=$(df -h /Applications | awk 'NR==2 {print $4}')
info "Available space on /Applications: $available_space"

if [[ -d "$RPCS3_DATA" ]]; then
    data_size=$(du -sh "$RPCS3_DATA" 2>/dev/null | cut -f1)
    info "RPCS3 data size: $data_size"
fi
echo ""

# Network Check
echo -e "${BLUE}━━━ Network ━━━${NC}"
echo ""

if ping -c 1 -t 5 rpcs3.net &> /dev/null; then
    success "Can reach rpcs3.net"
else
    warning "Cannot reach rpcs3.net (check internet connection)"
fi

if ping -c 1 -t 5 8.8.8.8 &> /dev/null; then
    success "Internet connection active"
else
    error "No internet connection"
fi
echo ""

# Process Check
echo -e "${BLUE}━━━ Running Processes ━━━${NC}"
echo ""

if pgrep -x "rpcs3" > /dev/null; then
    warning "RPCS3 is currently running (PID: $(pgrep -x "rpcs3"))"
else
    info "RPCS3 is not running"
fi
echo ""

# Permissions Check
echo -e "${BLUE}━━━ Permissions ━━━${NC}"
echo ""

if [[ -d "$RPCS3_APP" ]]; then
    if [[ -w "$RPCS3_APP" ]]; then
        success "You have write permission to RPCS3.app"
    else
        warning "No write permission to RPCS3.app"
    fi
fi

if [[ -d "$RPCS3_DATA" ]]; then
    if [[ -w "$RPCS3_DATA" ]]; then
        success "You have write permission to data directory"
    else
        error "No write permission to data directory"
    fi
fi
echo ""

# Common Issues & Solutions
echo -e "${BLUE}━━━ Common Issues & Solutions ━━━${NC}"
echo ""

issues_found=0

# Issue 1: Quarantine
if [[ -d "$RPCS3_APP" ]] && xattr -l "$RPCS3_APP" 2>/dev/null | grep -q "com.apple.quarantine"; then
    warning "Issue: App has quarantine attribute"
    info "Fix: sudo xattr -rd com.apple.quarantine '$RPCS3_APP'"
    ((issues_found++))
fi

# Issue 2: No firmware
if [[ ! -d "$RPCS3_DATA/dev_flash" ]] || [[ $(find "$RPCS3_DATA/dev_flash" -name "*.SELF" 2>/dev/null | wc -l) -lt 100 ]]; then
    warning "Issue: PS3 firmware not installed or incomplete"
    info "Fix: Download from Sony and install via RPCS3"
    ((issues_found++))
fi

# Issue 3: Low disk space
available_mb=$(df -m /Applications | awk 'NR==2 {print $4}')
if [[ $available_mb -lt 5000 ]]; then
    warning "Issue: Low disk space (less than 5GB available)"
    info "Fix: Free up disk space"
    ((issues_found++))
fi

# Issue 4: Old macOS
macos_major=$(sw_vers -productVersion | cut -d '.' -f 1)
if [[ $macos_major -lt 11 ]]; then
    error "Issue: macOS version too old (requires 11.0+)"
    info "Fix: Update macOS"
    ((issues_found++))
fi

if [[ $issues_found -eq 0 ]]; then
    success "No common issues detected!"
fi

echo ""

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Diagnostic Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [[ -d "$RPCS3_APP" ]]; then
    if [[ $issues_found -eq 0 ]]; then
        success "RPCS3 appears to be properly installed!"
        info "If you're experiencing issues, check the RPCS3 logs at:"
        info "$RPCS3_DATA/RPCS3.log"
    else
        warning "$issues_found issue(s) detected - see above for solutions"
    fi
else
    error "RPCS3 is not installed"
    info "Run the installer script to install RPCS3"
fi

echo ""
info "For more help, visit:"
echo "  • RPCS3 Wiki: https://wiki.rpcs3.net"
echo "  • Discord: https://discord.me/RPCS3"
echo ""

# Offer to generate report
read -r -p "Generate detailed report for troubleshooting? (y/N): " generate_report

if [[ "$generate_report" =~ ^[Yy]$ ]]; then
    report_file="$HOME/rpcs3_diagnostic_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "RPCS3 Diagnostic Report"
        echo "Generated: $(date)"
        echo "======================================"
        echo ""
        echo "System Information:"
        echo "  macOS: $(sw_vers -productVersion)"
        echo "  Architecture: $(uname -m)"
        echo "  Model: $(sysctl -n hw.model)"
        echo "  RAM: $(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024)) GB"
        echo ""
        echo "RPCS3 Installation:"
        if [[ -d "$RPCS3_APP" ]]; then
            echo "  Installed: Yes"
            echo "  Location: $RPCS3_APP"
        else
            echo "  Installed: No"
        fi
        echo ""
        echo "Data Directory:"
        if [[ -d "$RPCS3_DATA" ]]; then
            echo "  Exists: Yes"
            echo "  Location: $RPCS3_DATA"
            echo "  Size: $(du -sh "$RPCS3_DATA" 2>/dev/null | cut -f1)"
        else
            echo "  Exists: No"
        fi
        echo ""
        echo "Issues Found: $issues_found"
        echo ""
        echo "Full System Profiler:"
        system_profiler SPHardwareDataType SPDisplaysDataType 2>/dev/null || true
    } > "$report_file"
    
    success "Report saved to: $report_file"
fi

echo ""
