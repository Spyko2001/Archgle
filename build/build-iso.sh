#!/usr/bin/env bash
#
# Archgle ISO Build Script
# Builds the Archgle ISO using mkarchiso
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WORK_DIR="/tmp/archgle-build"
OUT_DIR="$PROJECT_ROOT/out"
PROFILE_DIR="$PROJECT_ROOT/archiso"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[Build]${NC} $*"
}

success() {
    echo -e "${GREEN}✓${NC} $*"
}

error() {
    echo -e "${RED}✗${NC} $*"
}

check_dependencies() {
    log "Checking dependencies..."
    
    local missing=()
    
    for cmd in mkarchiso pacman; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing dependencies: ${missing[*]}"
        echo "Install with: sudo pacman -S archiso"
        exit 1
    fi
    
    success "All dependencies present"
}

validate_profile() {
    log "Validating profile..."
    
    if [[ ! -f "$PROFILE_DIR/profiledef.sh" ]]; then
        error "Profile definition not found: $PROFILE_DIR/profiledef.sh"
        exit 1
    fi
    
    if [[ ! -f "$PROFILE_DIR/packages.x86_64" ]]; then
        error "Package list not found: $PROFILE_DIR/packages.x86_64"
        exit 1
    fi
    
    success "Profile validated"
}

prepare_build_env() {
    log "Preparing build environment..."
    
    # Clean previous build
    if [[ -d "$WORK_DIR" ]]; then
        sudo rm -rf "$WORK_DIR"
    fi
    
    mkdir -p "$WORK_DIR"
    mkdir -p "$OUT_DIR"
    
    success "Build environment ready"
}

copy_custom_files() {
    log "Copying custom files..."
    
    # Create airootfs structure
    local airootfs="$PROFILE_DIR/airootfs"
    mkdir -p "$airootfs"/{usr/local/bin,etc/archgle,usr/share/archgle}
    
    # Copy AI daemon
    cp "$PROJECT_ROOT/scripts/ai/archgle-ai-daemon.py" "$airootfs/usr/local/bin/archgle-ai-daemon"
    cp "$PROJECT_ROOT/scripts/ai/archgle-ai-cli" "$airootfs/usr/local/bin/archgle-ai"
    cp "$PROJECT_ROOT/configs/ai/archgle-ai-daemon.service" "$airootfs/usr/lib/systemd/system/"
    
    # Copy installer
    cp "$PROJECT_ROOT/installer/archgle-installer.sh" "$airootfs/usr/local/bin/archgle-installer"
    
    # Copy scripts
    cp "$PROJECT_ROOT/scripts/google-services-setup.sh" "$airootfs/usr/local/bin/"
    cp "$PROJECT_ROOT/scripts/performance-tweaks.sh" "$airootfs/usr/local/bin/"
    
    # Copy configurations
    cp "$PROJECT_ROOT/configs/hyprland/hyprland.conf" "$airootfs/etc/skel/.config/hypr/"
    cp "$PROJECT_ROOT/configs/software/categories.json" "$airootfs/etc/archgle/"
    
    # Copy branding assets
    mkdir -p "$airootfs/usr/share/archgle/wallpapers"
    # Wallpapers will be copied from .gemini artifacts to final location
    
    # Set permissions
    chmod +x "$airootfs/usr/local/bin/"*
    
    success "Custom files copied"
}

build_iso() {
    log "Building ISO..."
    echo ""
    
    sudo mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$PROFILE_DIR"
    
    if [[ $? -eq 0 ]]; then
        success "ISO built successfully!"
    else
        error "ISO build failed"
        exit 1
    fi
}

create_checksums() {
    log "Creating checksums..."
    
    cd "$OUT_DIR"
    
    for iso in *.iso; do
        if [[ -f "$iso" ]]; then
            sha256sum "$iso" > "${iso}.sha256"
            md5sum "$iso" > "${iso}.md5"
            success "Checksums created for $iso"
        fi
    done
    
    cd - > /dev/null
}

cleanup() {
    log "Cleaning up..."
    
    if [[ -d "$WORK_DIR" ]]; then
        sudo rm -rf "$WORK_DIR"
    fi
    
    success "Cleanup complete"
}

main() {
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}  Archgle ISO Builder                  ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo ""
    
    check_dependencies
    validate_profile
    prepare_build_env
    copy_custom_files
    build_iso
    create_checksums
    cleanup
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}  Build Complete!                       ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo ""
    
    log "ISO file: $OUT_DIR/archgle-*.iso"
    log "You can now write this ISO to a USB drive or use it in a VM"
    echo ""
}

# Handle interrupts
trap cleanup EXIT

main "$@"
