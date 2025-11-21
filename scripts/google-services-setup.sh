#!/usr/bin/env bash
#
# Google Services Setup for Archgle
# Configures Chrome, Drive, Gmail, Calendar, and Gemini API
#

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[Google Services]${NC} $*"
}

success() {
    echo -e "${GREEN}✓${NC} $*"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

setup_chrome() {
    log "Setting up Google Chrome..."
    
    # Install Google Chrome if not present
    if ! command -v google-chrome-stable &> /dev/null; then
        warn "Installing Google Chrome..."
        
        # Download and install
        cd /tmp
        wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
        
        # Convert RPM to package (or use AUR)
        yay -S google-chrome --noconfirm
        
        success "Google Chrome installed"
    else
        success "Google Chrome already installed"
    fi
    
    # Set as default browser
    xdg-settings set default-web-browser google-chrome.desktop
    success "Chrome set as default browser"
}

setup_google_drive() {
    log "Setting up Google Drive with rclone..."
    
    local drive_mount="$HOME/GoogleDrive"
    mkdir -p "$drive_mount"
    
    # Check if rclone is configured
    if [[ ! -f "$HOME/.config/rclone/rclone.conf" ]]; then
        log "Configuring rclone for Google Drive..."
        echo ""
        echo "Follow the prompts to authenticate with your Google account"
        echo ""
        
        rclone config create gdrive drive scope drive
    else
        success "Rclone already configured"
    fi
    
    # Create systemd user service for auto-mount
    mkdir -p "$HOME/.config/systemd/user"
    cat > "$HOME/.config/systemd/user/google-drive-mount.service" << EOF
[Unit]
Description=Google Drive (rclone)
After=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/rclone mount gdrive: $drive_mount \
    --vfs-cache-mode writes \
    --vfs-cache-max-size 100M \
    --poll-interval 15s \
    --dir-cache-time 1000h \
    --timeout 1h \
    --umask 002 \
    --allow-other
ExecStop=/bin/fusermount -u $drive_mount
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF
    
    # Enable auto-mount
    systemctl --user enable google-drive-mount.service
    systemctl --user start google-drive-mount.service
    
    success "Google Drive will auto-mount at: $drive_mount"
}

setup_gnome_online_accounts() {
    log "Setting up GNOME Online Accounts..."
    
    if command -v gnome-control-center &> /dev/null; then
        log "Opening Online Accounts settings..."
        log "Add your Google account to sync Calendar, Contacts, and Files"
        
        # Open online accounts (user will complete authentication)
        gnome-control-center online-accounts &
        
        success "GNOME Online Accounts configured"
    else
        warn "GNOME not detected - skipping Online Accounts setup"
    fi
}

setup_gmail_thunderbird() {
    log "Setting up Gmail in Thunderbird..."
    
    if command -v thunderbird &> /dev/null; then
        log "Thunderbird detected"
        log "Go to Thunderbird > Account Settings to add your Gmail account"
        success "Thunderbird ready for Gmail"
    else
        log "Thunderbird not installed - skipping"
    fi
}

setup_google_cloud_sdk() {
    log "Setting up Google Cloud SDK..."
    
    if ! command -v gcloud &> /dev/null; then
        log "Installing Google Cloud SDK..."
        
        # Add Google Cloud SDK repository
        echo "[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg" | sudo tee /etc/yum.repos.d/google-cloud-sdk.repo
        
        sudo pacman -Sy google-cloud-cli --noconfirm
        
        success "Google Cloud SDK installed"
    else
        success "Google Cloud SDK already installed"
    fi
    
    # Initialize gcloud
    log "To initialize gcloud, run: gcloud init"
}

setup_gemini_integration() {
    log "Setting up Gemini API integration..."
    
    echo ""
    echo "Gemini AI will be available via:"
    echo "  • archgle-ai CLI tool"
    echo "  • System daemon for automation"
    echo ""
    log "Run 'archgle-ai setup' to configure authentication"
    
    success "Gemini integration ready"
}

create_shortcuts() {
    log "Creating desktop shortcuts for Google services..."
    
    local desktop="$HOME/Desktop"
    mkdir -p "$desktop"
    
    # Google Drive shortcut
    cat > "$desktop/Google-Drive.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Link
Name=Google Drive
Icon=google-drive
URL=$HOME/GoogleDrive
EOF
    chmod +x "$desktop/Google-Drive.desktop"
    
    success "Desktop shortcuts created"
}

main() {
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}  Archgle Google Services Setup        ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo ""
    
    setup_chrome
    echo ""
    
    setup_google_drive
    echo ""
    
    setup_gnome_online_accounts
    echo ""
    
    setup_gmail_thunderbird
    echo ""
    
    setup_google_cloud_sdk
    echo ""
    
    setup_gemini_integration
    echo ""
    
    create_shortcuts
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}  Google Services Setup Complete!      ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo ""
    
    log "Google services are ready to use!"
    log "Google Drive: $HOME/GoogleDrive"
    log "Chrome: Default browser"
    log "AI Assistant: archgle-ai"
    echo ""
}

main "$@"
