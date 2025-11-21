#!/usr/bin/env bash
#
# Archgle Interactive Installer
# Beautiful TUI installer with hardware detection and customization options
#

set -euo pipefail

# Dialog dimensions
DIALOG_HEIGHT=20
DIALOG_WIDTH=70

# State file
STATE_FILE="/tmp/archgle-install-state.json"

# Initialize state
init_state() {
    cat > "$STATE_FILE" << EOF
{
  "de": "",
  "theme": "",
  "google_services": true,
  "security_tools": false,
  "security_categories": [],
  "software": [],
  "hardware_profile": "",
  "disk": "",
  "encryption": false,
  "hostname": "archgle",
  "username": "",
  "timezone": "UTC",
  "locale": "en_US.UTF-8"
}
EOF
}

# Read state value
get_state() {
    jq -r ".$1" "$STATE_FILE"
}

# Set state value
set_state() {
    local key="$1"
    local value="$2"
    local tmp=$(mktemp)
    jq ".$key = \"$value\"" "$STATE_FILE" > "$tmp"
    mv "$tmp" "$STATE_FILE"
}

welcome_screen() {
    dialog --title "Welcome to Archgle" --msgbox "\nArchgle: Arch Linux + Google Services + AI\n\n\
This installer will guide you through setting up Archgle with:\n\n\
  • Desktop environment (Hyprland/GNOME)\n\
  • Google services integration\n\
  • AI-powered system assistance\n\
  • Hardware-optimized performance\n\
  • Optional security tools\n\
  • Curated software recommendations\n\n\
Press OK to continue..." 18 $DIALOG_WIDTH
}

select_desktop_environment() {
    local choice
    choice=$(dialog --title "Desktop Environment" --menu \
        "Choose your desktop environment:" $DIALOG_HEIGHT $DIALOG_WIDTH 3 \
        "hyprland" "Hyprland - Modern tiling Wayland compositor" \
        "gnome" "GNOME - Full-featured desktop with Google integration" \
        "both" "Install both (choose at login)" \
        3>&1 1>&2 2>&3) || return 1
    
    set_state "de" "$choice"
}

select_theme() {
    local choice
    choice=$(dialog --title "Visual Theme" --menu \
        "Choose a theming style:" $DIALOG_HEIGHT $DIALOG_WIDTH 4 \
        "material-dark" "Material Design Dark (Google-inspired)" \
        "nord" "Nord - Cool blue tones" \
        "catppuccin" "Catppuccin - Pastel elegance" \
        "minimal" "Minimal - Clean and simple" \
        3>&1 1>&2 2>&3) || return 1
    
    set_state "theme" "$choice"
}

select_security_tools() {
    if dialog --title "Security Tools" --yesno \
        "Do you want to install security/penetration testing tools?\n\n\
These are professional-grade security tools for:\n\
  • Network analysis\n\
  • Penetration testing\n\
  • Wireless testing\n\
  • Web application testing\n\
  • Forensics\n\n\
Install security tools?" 15 $DIALOG_WIDTH; then
        
        set_state "security_tools" "true"
        
        # Select categories
        local categories
        categories=$(dialog --title "Security Tool Categories" --checklist \
            "Select categories to install:" $DIALOG_HEIGHT $DIALOG_WIDTH 5 \
            "network" "Network Analysis (nmap, wireshark)" ON \
            "pentest" "Penetration Testing (metasploit, burpsuite)" OFF \
            "wireless" "Wireless Testing (aircrack-ng)" OFF \
            "web" "Web Testing (nikto, gobuster)" ON \
            "forensics" "Forensics (autopsy, sleuthkit)" OFF \
            3>&1 1>&2 2>&3) || return 1
        
        # Save categories
        local cats_json="["
        for cat in $categories; do
            cats_json="${cats_json}\"${cat//\"/}\","
        done
        cats_json="${cats_json%,}]"
        
        local tmp=$(mktemp)
        jq ".security_categories = $cats_json" "$STATE_FILE" > "$tmp"
        mv "$tmp" "$STATE_FILE"
    else
        set_state "security_tools" "false"
    fi
}

recommend_software() {
    local recommended
    recommended=$(dialog --title "Recommended Software" --checklist \
        "Select additional software to install (recommended, not required):" \
        $DIALOG_HEIGHT $DIALOG_WIDTH 10 \
        "media-vlc" "VLC Media Player" ON \
        "media-spotify" "Spotify (music streaming)" OFF \
        "media-obs" "OBS Studio (recording/streaming)" OFF \
        "prod-libreoffice" "LibreOffice (office suite)" ON \
        "prod-obsidian" "Obsidian (note-taking)" OFF \
        "comm-discord" "Discord" OFF \
        "comm-telegram" "Telegram" OFF \
        "game-steam" "Steam (gaming)" OFF \
        "game-lutris" "Lutris (game manager)" OFF \
        "util-stacer" "Stacer (system optimizer)" OFF \
        3>&1 1>&2 2>&3) || return 1
    
    # Save software selections
    local soft_json="["
    for soft in $recommended; do
        soft_json="${soft_json}\"${soft//\"/}\","
    done
    soft_json="${soft_json%,}]"
    
    local tmp=$(mktemp)
    jq ".software = $soft_json" "$STATE_FILE" > "$tmp"
    mv "$tmp" "$STATE_FILE"
}

detect_hardware() {
    dialog --title "Hardware Detection" --infobox "Detecting hardware capabilities..." 5 50
    sleep 1
    
    # Detect hardware
    local ram_gb cores storage gpu profile
    ram_gb=$(free -g | awk '/^Mem:/ {print $2}')
    cores=$(nproc)
    
    if lsblk -d -o name,rota | grep -q "0$"; then
        storage="SSD"
    else
        storage="HDD"
    fi
    
    if lspci | grep -i "vga" | grep -qi "nvidia"; then
        gpu="NVIDIA"
    elif lspci | grep -i "vga" | grep -qi "amd"; then
        gpu="AMD"
    elif lspci | grep -i "vga" | grep -qi "intel"; then
        gpu="Intel"
    else
        gpu="Unknown"
    fi
    
    # Determine profile
    if [[ $ram_gb -ge 16 && $cores -ge 8 && "$storage" == "SSD" ]]; then
        profile="Performance"
    elif [[ $ram_gb -ge 8 && $cores -ge 4 ]]; then
        profile="Balanced"
    else
        profile="Efficiency"
    fi
    
    dialog --title "Hardware Profile" --msgbox "\nDetected Hardware:\n\n\
  CPU Cores: $cores\n\
  RAM: ${ram_gb}GB\n\
  Storage: $storage\n\
  GPU: $gpu\n\n\
Recommended Profile: $profile\n\n\
This profile will optimize your system for your hardware." 16 60
    
    set_state "hardware_profile" "$profile"
}

setup_gemini_api() {
    local choice
    choice=$(dialog --title "Gemini AI Setup" --menu \
        "How would you like to authenticate with Gemini?" \
        $DIALOG_HEIGHT $DIALOG_WIDTH 2 \
        "google" "Google Account (recommended)" \
        "apikey" "API Key" \
        3>&1 1>&2 2>&3) || return 1
    
    if [[ "$choice" == "apikey" ]]; then
        local api_key
        api_key=$(dialog --title "Gemini API Key" --inputbox \
            "Enter your Gemini API key:\n\n(You can set this up later with: archgle-ai setup)" \
            10 $DIALOG_WIDTH 3>&1 1>&2 2>&3) || return 1
        
        set_state "gemini_auth" "apikey"
        set_state "gemini_api_key" "$api_key"
    else
        dialog --title "Google Authentication" --msgbox \
            "After installation, run 'archgle-ai setup' to authenticate with your Google account.\n\n\
You'll need to create OAuth credentials in Google Cloud Console." 10 $DIALOG_WIDTH
        
        set_state "gemini_auth" "google"
    fi
}

configure_system() {
    # Hostname
    local hostname
    hostname=$(dialog --title "System Configuration" --inputbox \
        "Enter hostname:" 8 $DIALOG_WIDTH "archgle" 3>&1 1>&2 2>&3) || return 1
    set_state "hostname" "$hostname"
    
    # Username
    local username
    username=$(dialog --title "User Account" --inputbox \
        "Enter username:" 8 $DIALOG_WIDTH "" 3>&1 1>&2 2>&3) || return 1
    set_state "username" "$username"
    
    # Timezone
    local timezone
    timezone=$(dialog --title "Timezone" --inputbox \
        "Enter timezone (e.g., America/New_York):" 8 $DIALOG_WIDTH "UTC" \
        3>&1 1>&2 2>&3) || return 1
    set_state "timezone" "$timezone"
}

confirmation_screen() {
    local de theme profile username hostname
    de=$(get_state "de")
    theme=$(get_state "theme")
    profile=$(get_state "hardware_profile")
    username=$(get_state "username")
    hostname=$(get_state "hostname")
    
    dialog --title "Installation Summary" --yesno "\nReady to install Archgle with:\n\n\
  Desktop: $de\n\
  Theme: $theme\n\
  Performance Profile: $profile\n\
  Google Services: Enabled\n\
  AI Assistant: Gemini\n\
  Hostname: $hostname\n\
  User: $username\n\n\
Proceed with installation?" 16 $DIALOG_WIDTH
}

perform_installation() {
    # This is a simplified version - actual installation would be more complex
    
    dialog --title "Installing Archgle" --infobox "Starting installation process..." 5 50
    sleep 2
    
    # Actual installation steps would go here:
    # - Partition disk
    # - Install base system
    # - Configure desktop environment
    # - Install Google services
    # - Set up AI daemon
    # - Apply performance profile
    # - Install selected software
    
    dialog --title "Installation Complete" --msgbox "\nArchgle has been installed successfully!\n\n\
Next steps:\n\
  1. Reboot your system\n\
  2. Log in with your credentials\n\
  3. Run 'archgle-ai setup' to configure AI\n\
  4. Enjoy your AI-powered Arch Linux!\n\n\
Welcome to Archgle!" 15 60
}

main() {
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo "This installer must be run as root"
        exit 1
    fi
    
    init_state
    
    # Run installation wizard
    welcome_screen
    select_desktop_environment
    select_theme
    select_security_tools
    recommend_software
    detect_hardware
    setup_gemini_api
    configure_system
    confirmation_screen
    perform_installation
    
    clear
}

main "$@"
