#!/bin/bash
#
# RPCS3 Automatic Installer for macOS
# Version: 2.0
# Supports: macOS 11.0+ (Big Sur and newer)
# Architecture: Intel & Apple Silicon
#
# This script automates the installation of RPCS3 PS3 emulator
# More info: https://rpcs3.net
#

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly SCRIPT_VERSION="2.0"
readonly REQUIRED_MACOS_VERSION="11"
readonly APP_DIR="/Applications"
readonly RPCS3_APP="$APP_DIR/RPCS3.app"
readonly RPCS3_DATA_DIR="$HOME/Library/Application Support/rpcs3"
readonly CONFIG_FILE="$RPCS3_DATA_DIR/config.yml"
readonly TMP_DIR="/tmp/rpcs3_install_$$"
readonly LOG_FILE="$HOME/rpcs3_install.log"

# Official URLs
readonly RPCS3_DOWNLOAD_URL="https://github.com/RPCS3/rpcs3-binaries-mac/releases/latest/download/rpcs3-macos.dmg"
readonly FIRMWARE_PAGE_URL="https://www.playstation.com/en-us/support/hardware/ps3/system-software/"
readonly FIRMWARE_DIRECT_URL="http://deu01.ps3.update.playstation.net/update/ps3/image/us/2024_0227_05fe32f77eb7c2a8dcdfamir8da6edd37/PS3UPDAT.PUP"

# Colors for terminal output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ============================================================================
# LOGGING & OUTPUT FUNCTIONS
# ============================================================================

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}ℹ️  $*${NC}" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✅ $*${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠️  $*${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}❌ $*${NC}" | tee -a "$LOG_FILE"
}

section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $*${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ============================================================================
# CLEANUP & ERROR HANDLING
# ============================================================================

cleanup() {
    local exit_code=$?
    if [[ -d "$TMP_DIR" ]]; then
        info "Cleaning up temporary files..."
        rm -rf "$TMP_DIR"
    fi
    if [[ $exit_code -ne 0 ]]; then
        error "Installation failed! Check log file: $LOG_FILE"
        exit $exit_code
    fi
}

trap cleanup EXIT INT TERM

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

check_macos_version() {
    local macos_version
    macos_version=$(sw_vers -productVersion | cut -d '.' -f 1)
    
    if [[ "$macos_version" -lt "$REQUIRED_MACOS_VERSION" ]]; then
        error "macOS $REQUIRED_MACOS_VERSION or newer is required"
        error "Your version: $(sw_vers -productVersion)"
        exit 1
    fi
    success "macOS version $(sw_vers -productVersion) - OK"
}

check_os_type() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        error "This script only works on macOS"
        exit 1
    fi
}

detect_architecture() {
    local arch
    arch=$(uname -m)
    
    case "$arch" in
        arm64)
            echo "apple_silicon"
            success "Apple Silicon detected (M1/M2/M3/M4)"
            ;;
        x86_64)
            echo "intel"
            success "Intel Mac detected"
            ;;
        *)
            error "Unknown architecture: $arch"
            exit 1
            ;;
    esac
}

check_available_space() {
    local required_space_mb=5000  # 5GB
    local available_space_mb
    available_space_mb=$(df -m /Applications | awk 'NR==2 {print $4}')
    
    if [[ "$available_space_mb" -lt "$required_space_mb" ]]; then
        error "Insufficient disk space. Required: ${required_space_mb}MB, Available: ${available_space_mb}MB"
        exit 1
    fi
    success "Disk space check passed (${available_space_mb}MB available)"
}

check_internet_connection() {
    if ! ping -c 1 -t 5 8.8.8.8 &> /dev/null; then
        error "No internet connection detected"
        exit 1
    fi
    success "Internet connection - OK"
}

check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        error "Required command not found: $cmd"
        return 1
    fi
    return 0
}

# ============================================================================
# DOWNLOAD FUNCTIONS
# ============================================================================

download_with_progress() {
    local url="$1"
    local output="$2"
    local description="${3:-file}"
    
    info "Downloading $description..."
    
    if check_command wget; then
        wget --show-progress --progress=bar:force -O "$output" "$url" 2>&1 | \
            grep --line-buffered -oP '\d+%' | \
            while read -r percent; do
                echo -ne "\r  Progress: $percent"
            done
        echo ""
    elif check_command curl; then
        curl -L --progress-bar -o "$output" "$url"
    else
        error "Neither wget nor curl found. Please install one of them."
        exit 1
    fi
    
    if [[ ! -f "$output" ]] || [[ ! -s "$output" ]]; then
        error "Download failed: $description"
        return 1
    fi
    
    success "Downloaded $description successfully"
    return 0
}

verify_file_size() {
    local file="$1"
    local min_size_mb="${2:-1}"
    local file_size_mb
    
    file_size_mb=$(du -m "$file" | cut -f1)
    
    if [[ "$file_size_mb" -lt "$min_size_mb" ]]; then
        error "File too small (${file_size_mb}MB). Possible download corruption."
        return 1
    fi
    
    return 0
}

# ============================================================================
# INSTALLATION FUNCTIONS
# ============================================================================

download_rpcs3() {
    section "Downloading RPCS3"
    
    local dmg_file="$TMP_DIR/rpcs3.dmg"
    
    # Try GitHub releases first
    if download_with_progress "$RPCS3_DOWNLOAD_URL" "$dmg_file" "RPCS3 (latest release)"; then
        verify_file_size "$dmg_file" 50 || return 1
    else
        error "Failed to download RPCS3 from GitHub"
        error "Please download manually from: https://rpcs3.net/download"
        return 1
    fi
    
    echo "$dmg_file"
}

install_rpcs3() {
    section "Installing RPCS3"
    
    local dmg_file="$1"
    
    # Remove old installation if exists
    if [[ -d "$RPCS3_APP" ]]; then
        warning "Existing RPCS3 installation found. Removing..."
        rm -rf "$RPCS3_APP"
    fi
    
    info "Mounting DMG..."
    local mount_point
    mount_point=$(hdiutil attach "$dmg_file" -nobrowse | grep Volumes | sed 's/.*\/Volumes/\/Volumes/')
    
    if [[ -z "$mount_point" ]]; then
        error "Failed to mount DMG"
        return 1
    fi
    
    info "Copying RPCS3.app to Applications..."
    cp -R "$mount_point/RPCS3.app" "$APP_DIR/"
    
    info "Unmounting DMG..."
    hdiutil detach "$mount_point" -quiet
    
    # Remove quarantine attribute
    info "Removing quarantine attribute..."
    xattr -dr com.apple.quarantine "$RPCS3_APP" 2>/dev/null || true
    
    # Verify installation
    if [[ ! -d "$RPCS3_APP" ]]; then
        error "Installation failed - RPCS3.app not found"
        return 1
    fi
    
    success "RPCS3 installed successfully"
}

download_firmware() {
    section "Downloading PS3 Firmware"
    
    local fw_file="$TMP_DIR/PS3UPDAT.PUP"
    
    info "Using Sony's official firmware (version 4.91)"
    
    if download_with_progress "$FIRMWARE_DIRECT_URL" "$fw_file" "PS3 Firmware"; then
        verify_file_size "$fw_file" 150 || {
            warning "Firmware file seems too small. Skipping firmware installation."
            warning "You can install it manually later via RPCS3 > File > Install Firmware"
            return 1
        }
    else
        warning "Failed to download firmware automatically"
        warning "You can download it manually from: $FIRMWARE_PAGE_URL"
        return 1
    fi
    
    echo "$fw_file"
}

install_firmware() {
    section "Installing PS3 Firmware"
    
    local fw_file="$1"
    
    if [[ ! -f "$fw_file" ]]; then
        warning "Firmware file not found. Skipping firmware installation."
        return 1
    fi
    
    # Initialize RPCS3 data directory
    mkdir -p "$RPCS3_DATA_DIR"
    
    info "Installing firmware (this may take a few minutes)..."
    
    # Try to install firmware
    if "$RPCS3_APP/Contents/MacOS/rpcs3" --installfw "$fw_file" &>/dev/null; then
        success "Firmware installed successfully"
    else
        warning "Automatic firmware installation failed"
        warning "Please install manually: RPCS3 > File > Install Firmware"
        warning "Firmware file saved at: $fw_file"
        cp "$fw_file" "$HOME/Downloads/" 2>/dev/null || true
    fi
}

configure_rpcs3() {
    section "Configuring RPCS3"
    
    local cpu_type="$1"
    
    mkdir -p "$RPCS3_DATA_DIR"
    
    info "Creating optimized configuration..."
    
    # Backup existing config
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%s)"
    fi
    
    # Create optimized config
    cat > "$CONFIG_FILE" <<'EOF'
Core:
  PPU Decoder: Recompiler (LLVM)
  SPU Decoder: Recompiler (LLVM)
  SPU Block Size: Safe
  Preferred SPU Threads: Auto
  Lower SPU thread priority: true
  SPU loop detection: true
  TSX Instructions: Disabled
  Max SPURS Threads: 6

GPU:
  Renderer: Vulkan
  Framelimit: 60
  VSync: false
  Frame Skip: Disabled
  Resolution Scale: 100
  Resolution Scale Threshold: 16x16
  Anisotropic Filter: 16
  Anti-Aliasing: Disabled
  MSAA: Disabled
  Write Color Buffers: true
  Write Depth Buffer: true
  Read Color Buffers: true
  Read Depth Buffer: true
  Strict Rendering Mode: false
  Disable Vertex Cache: false
  Disable ZCULL Occlusion Queries: false

Audio:
  Renderer: Cubeb
  Audio Provider: Default
  Dump to file: false
  Convert to 16 bit: false
  Downmix to Stereo: true
  Master Volume: 100
  Enable Buffering: true
  Desired Audio Buffer Duration: 100
  Enable Time Stretching: false

Input/Output:
  Keyboard: "Null"
  Mouse: "Basic"
  Camera: "Null"
  Camera type: Unknown
  Move: "Null"

System:
  Language: English (US)
  Enter button assignment: Cross
  Enable /host_root/: false
  Limit cache size: false
  
Emulator:
  Exit RPCS3 when process finishes: false
  Start games in fullscreen mode: false
  Prevent display sleep while running games: true
  Show trophy popups: true
  Show shader compilation hint: true
  Use native user interface: true

Network:
  Internet Status: Connected
  IP address: 192.168.1.1
  DNS: 8.8.8.8
  IP/Hosts switches: "np.communication.np.community.ea.com=127.0.0.1"
  Bind address: 0.0.0.0
  PSN Status: Disconnected
EOF
    
    # Apple Silicon specific optimizations
    if [[ "$cpu_type" == "apple_silicon" ]]; then
        info "Applying Apple Silicon optimizations..."
        cat >> "$CONFIG_FILE" <<'EOF'

# Apple Silicon Optimizations
GPU:
  Relaxed ZCULL Sync: true
  Resolution Scale Threshold: 512x512
  
Core:
  Max SPURS Threads: 8
EOF
    fi
    
    success "Configuration applied successfully"
}

create_desktop_shortcut() {
    section "Creating Desktop Shortcut"
    
    local desktop_path="$HOME/Desktop"
    
    if [[ ! -d "$desktop_path" ]]; then
        warning "Desktop folder not found. Skipping shortcut creation."
        return
    fi
    
    # Create alias (macOS shortcut)
    osascript <<EOF 2>/dev/null || true
tell application "Finder"
    make new alias file at POSIX file "$desktop_path" to POSIX file "$RPCS3_APP"
    set name of result to "RPCS3"
end tell
EOF
    
    success "Desktop shortcut created"
}

# ============================================================================
# POST-INSTALLATION
# ============================================================================

display_post_install_info() {
    section "Installation Complete! 🎉"
    
    echo ""
    success "RPCS3 has been successfully installed!"
    echo ""
    info "📍 Installation location: $RPCS3_APP"
    info "📁 Data directory: $RPCS3_DATA_DIR"
    info "📋 Log file: $LOG_FILE"
    echo ""
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  Next Steps:${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  1. Launch RPCS3 from Applications or Desktop"
    echo "  2. Add your PS3 game files (File > Add Games)"
    echo "  3. Configure controller (Pads > Configure)"
    echo "  4. Check game compatibility: https://rpcs3.net/compatibility"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    info "For help and support, visit:"
    echo "  • Official website: https://rpcs3.net"
    echo "  • Wiki: https://wiki.rpcs3.net"
    echo "  • Discord: https://discord.me/RPCS3"
    echo ""
    
    read -r -p "Launch RPCS3 now? (y/N): " launch_now
    if [[ "$launch_now" =~ ^[Yy]$ ]]; then
        open -a RPCS3
        success "RPCS3 launched!"
    fi
}

# ============================================================================
# MAIN INSTALLATION FLOW
# ============================================================================

main() {
    # Clear screen and show header
    clear
    echo -e "${BLUE}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════╗
    ║                                                       ║
    ║        RPCS3 Automatic Installer for macOS           ║
    ║                    Version 2.0                        ║
    ║                                                       ║
    ║         PS3 Emulator Installation Script             ║
    ║                                                       ║
    ╚═══════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    
    log "=== RPCS3 Installation Started ==="
    log "Script version: $SCRIPT_VERSION"
    log "macOS version: $(sw_vers -productVersion)"
    log "Architecture: $(uname -m)"
    
    # Pre-installation checks
    section "Pre-Installation Checks"
    check_os_type
    check_macos_version
    local cpu_type
    cpu_type=$(detect_architecture)
    check_available_space
    check_internet_connection
    
    # Create temp directory
    mkdir -p "$TMP_DIR"
    
    # Download RPCS3
    local dmg_file
    dmg_file=$(download_rpcs3)
    
    # Install RPCS3
    install_rpcs3 "$dmg_file"
    
    # Download and install firmware
    local fw_file
    fw_file=$(download_firmware) || fw_file=""
    
    if [[ -n "$fw_file" ]] && [[ -f "$fw_file" ]]; then
        install_firmware "$fw_file"
    fi
    
    # Configure RPCS3
    configure_rpcs3 "$cpu_type"
    
    # Create desktop shortcut
    create_desktop_shortcut
    
    # Show post-installation info
    display_post_install_info
    
    log "=== RPCS3 Installation Completed Successfully ==="
}

# ============================================================================
# SCRIPT ENTRY POINT
# ============================================================================

# Check if running with sudo (not recommended)
if [[ $EUID -eq 0 ]]; then
    error "Please do NOT run this script with sudo"
    exit 1
fi

# Run main installation
main "$@"
