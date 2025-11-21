#!/bin/bash
# Project Archgle - Part 2: The "Google Pixel" Experience
# Installs Hyprland, ZRAM, Google Tools, and Pentest Utils

echo "🚀 Starting Phase 2: Building Archgle..."

# 1. AUR Helper (Yay)
if ! command -v yay &> /dev/null; then
    echo ">> Installing Yay..."
    git clone https://aur.archlinux.org/yay.git
    cd yay && makepkg -si --noconfirm && cd .. && rm -rf yay
fi

# 2. The "8GB RAM" Performance Fix (ZRAM)
echo ">> Configuring ZRAM & Swap..."
sudo pacman -S --noconfirm zram-generator
echo -e "[zram0]\nzram-size = min(ram, 8192)\ncompression-algorithm = zstd" | sudo tee /etc/systemd/zram-generator.conf
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0

# Tuned "Windows-Like" Swappiness
echo "vm.swappiness = 130" | sudo tee /etc/sysctl.d/99-swappiness.conf
echo "vm.page-cluster = 0" | sudo tee -a /etc/sysctl.d/99-swappiness.conf
sudo sysctl --system

# 3. Visual Stack (Hyprland & Material You)
echo ">> Installing Hyprland & Material You..."
yay -S --noconfirm hyprland kit-ty waybar-git wofi swaybg mako \
    ttf-google-sans-code-vf ttf-google-fonts-git \
    hyprland-material-you-git python-pywal polkit-gnome

# 4. Google Ecosystem
echo ">> Installing Google Tools..."
yay -S --noconfirm google-cloud-cli google-drive-ocamlfuse google-chrome
# Note: Assuming 'antigravity-bin' exists in AUR. If not, it skips.
yay -S --noconfirm google-antigravity-bin || echo "⚠️ Antigravity not in AUR yet, install .deb manually via debtap"

# 5. Gemini AI Agent
echo ">> Installing Gemini CLI..."
sudo pacman -S --noconfirm npm
sudo npm install -g @google/gemini-cli

# 6. Pentest Tools (BlackArch Slim)
echo ">> Installing BlackArch Repo..."
curl -O https://blackarch.org/strap.sh
chmod +x strap.sh
sudo ./strap.sh
sudo pacman -S --noconfirm nmap metasploit wireshark-qt aircrack-ng hashcat binwalk

# 7. Config Generation (The "Glue")
mkdir -p ~/.config/hypr
cat <<EOT > ~/.config/hypr/hyprland.conf
# ARCHGLE OFFICIAL CONFIG
monitor=,preferred,auto,1

# Startup
exec-once = waybar & swaybg -i ~/Pictures/wallpaper.jpg & mako
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

# Input (Mac-like Gestures)
input {
    kb_layout = us
    touchpad {
        natural_scroll = true
        clickfinger_behavior = true
    }
}
gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
}

# Antigravity Agent Rules (Prevent Lag)
windowrulev2 = workspace 9 silent, class:^(google-antigravity-agent)$
windowrulev2 = float, class:^(gemini-agent)$
windowrulev2 = center, class:^(gemini-agent)$
windowrulev2 = size 60% 60%, class:^(gemini-agent)$

# Keybinds
$mainMod = SUPER
bind = $mainMod, Q, exec, kitty
bind = $mainMod, C, killactive
bind = $mainMod, E, exec, nautilus
bind = $mainMod, Space, exec, wofi --show drun
bind = $mainMod, G, exec, kitty --class gemini-agent -e gemini chat

# Network Panic Button (Super+Shift+N)
bind = $mainMod SHIFT, N, exec, nmcli networking off
bind = $mainMod CTRL, N, exec, nmcli networking on
EOT

echo "✅ INSTALLATION COMPLETE!"
echo ">> Next Steps:"
echo "1. Login to Google Cloud: 'gcloud init'"
echo "2. Mount Drive: 'google-drive-ocamlfuse ~/GoogleDrive'"
echo "3. Enjoy Archgle."
