#!/bin/bash
#
# RPCS3 Uninstaller for macOS
# Completely removes RPCS3 and all associated data
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
readonly RPCS3_PREFS="$HOME/Library/Preferences/rpcs3"
readonly RPCS3_CACHE="$HOME/Library/Caches/rpcs3"
readonly DESKTOP_ALIAS="$HOME/Desktop/RPCS3"

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

# Header
clear
echo -e "${RED}"
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║          RPCS3 Uninstaller for macOS                  ║
║                                                       ║
║     This will remove RPCS3 and all its data          ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""

# Warning
warning "This will remove:"
echo "  • RPCS3 application"
echo "  • All game saves and data"
echo "  • Configuration files"
echo "  • Cache and preferences"
echo "  • Desktop shortcuts"
echo ""

warning "Your game files (ISO/PKG) will NOT be deleted"
echo ""

# Confirmation
read -r -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm

if [[ "$confirm" != "yes" ]]; then
    info "Uninstallation cancelled"
    exit 0
fi

echo ""
info "Starting uninstallation..."
echo ""

# Kill RPCS3 if running
if pgrep -x "rpcs3" > /dev/null; then
    info "Closing RPCS3..."
    pkill -x "rpcs3" || true
    sleep 2
fi

# Remove application
if [[ -d "$RPCS3_APP" ]]; then
    info "Removing RPCS3 application..."
    rm -rf "$RPCS3_APP"
    success "Application removed"
else
    warning "Application not found (may already be removed)"
fi

# Ask about data
echo ""
read -r -p "Remove all game saves and data? (y/N): " remove_data

if [[ "$remove_data" =~ ^[Yy]$ ]]; then
    if [[ -d "$RPCS3_DATA" ]]; then
        info "Backing up to ~/rpcs3_backup_$(date +%s).tar.gz..."
        tar -czf "$HOME/rpcs3_backup_$(date +%s).tar.gz" -C "$HOME/Library/Application Support" "rpcs3" 2>/dev/null || true
        
        info "Removing data directory..."
        rm -rf "$RPCS3_DATA"
        success "Data removed (backup created in home directory)"
    else
        warning "Data directory not found"
    fi
else
    info "Keeping game saves and data at: $RPCS3_DATA"
fi

# Remove preferences
if [[ -d "$RPCS3_PREFS" ]]; then
    info "Removing preferences..."
    rm -rf "$RPCS3_PREFS"
    success "Preferences removed"
fi

# Remove cache
if [[ -d "$RPCS3_CACHE" ]]; then
    info "Removing cache..."
    rm -rf "$RPCS3_CACHE"
    success "Cache removed"
fi

# Remove desktop shortcut
if [[ -e "$DESKTOP_ALIAS" ]]; then
    info "Removing desktop shortcut..."
    rm -rf "$DESKTOP_ALIAS"
    success "Desktop shortcut removed"
fi

# Remove installation log
if [[ -f "$HOME/rpcs3_install.log" ]]; then
    info "Removing installation log..."
    rm -f "$HOME/rpcs3_install.log"
fi

echo ""
success "✨ RPCS3 has been completely uninstalled"
echo ""
info "Thank you for using RPCS3!"
echo ""
