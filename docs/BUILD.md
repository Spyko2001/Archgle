# Building Archgle

This guide explains how to build the Archgle ISO from source.

## Prerequisites

You need an Arch Linux environment to build Archgle. This can be:
- A Hyper-V VM running Arch Linux
- An existing Arch Linux install
- Docker container with Arch Linux

## Setup Build Environment

### Option 1: Hyper-V VM (Recommended for Windows)

1. **Download Arch Linux ISO**
   ```bash
   # Download from https://archlinux.org/download/
   ```

2. **Create Hyper-V VM**
   - Memory: 4GB+ recommended
   - Storage: 50GB+
   - Generation 2 (UEFI)

3. **Install Arch Linux**
   ```bash
   # Follow the official Arch installation guide
   # https://wiki.archlinux.org/title/Installation_guide
   ```

4. **Install build tools**
   ```bash
   sudo pacman -Syu
   sudo pacman -S archiso git base-devel
   ```

### Option 2: Existing Arch System

```bash
sudo pacman -S archiso git base-devel
```

## Build Process

1. **Clone the repository**
   ```bash
   git clone https://github.com/Spyko2001/Archgle.git
   cd Archgle
   ```

2. **Run the build script**
   ```bash
   cd build
   chmod +x build-iso.sh
   sudo ./build-iso.sh
   ```

3. **Wait for build to complete**
   - This may take 30-60 minutes depending on your system
   - The script will download all packages and create the ISO

4. **Find your ISO**
   ```bash
   ls ../out/
   # archgle-YYYY.MM.DD-x86_64.iso
   ```

## What Gets Built

The ISO includes:

### Core System
- Arch Linux base with latest kernel
- Multi-GPU support (AMD, Intel, Nvidia)
- NPU support for AI acceleration

### Desktop Environments
- Hyprland (Wayland tiling compositor)
- GNOME (with Google integration)
- Display managers (GDM, SDDM)

### Google Services
- Google Chrome
- rclone (for Google Drive)
- GNOME Online Accounts
- Google Cloud SDK
- Gemini API integration

### AI Components
- Archgle AI Daemon
- AI CLI tool
- Kernel hooks for system monitoring
- Google OAuth support

### Development Tools
- Antigravity IDE (will be downloaded during install)
- Docker
- Git & GitHub CLI
- Node.js, Python, and popular runtimes

## Testing the ISO

### In a VM (QEMU/KVM)
```bash
qemu-system-x86_64 \
  -enable-kvm \
  -m 4G \
  -cpu host \
  -smp 4 \
  -boot d \
  -cdrom ../out/archgle-*.iso \
  -drive file=archgle-test.qcow2,format=qcow2
```

### In Hyper-V
1. Create new VM
2. Mount the ISO
3. Boot and test installer

### Write to USB
```bash
# WARNING: This will erase all data on the USB drive!
sudo dd if=../out/archgle-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

## Build Options

### Custom Package List

Edit `archiso/packages.x86_64` to add/remove packages:
```bash
nano archiso/packages.x86_64
```

### Custom Configuration

Modify files in `configs/` directory:
- `configs/hyprland/` - Hyprland settings
- `configs/ai/` - AI daemon configuration
- `configs/software/` - Software recommendations

### Custom Branding

Replace images in `themes/`:
- `themes/wallpapers/` - Desktop wallpapers
- `themes/grub/` - GRUB boot theme
- `themes/plymouth/` - Boot splash

## Troubleshooting

### Build fails with dependency errors
```bash
# Update mirrorlist
sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Syu
```

### Out of disk space
```bash
# Clean package cache
sudo pacman -Scc
```

### Permission errors
```bash
# The build script must be run with sudo
sudo ./build-iso.sh
```

## Advanced Customization

### Adding Your Own Packages

1. Add package names to `archiso/packages.x86_64`
2. Rebuild the ISO

### Custom Scripts

1. Add scripts to `scripts/`
2. Update `build/build-iso.sh` to copy them
3. Rebuild

### Custom Kernel Parameters

Edit `archiso/profiledef.sh` and modify boot parameters.

## Contributing

To contribute improvements to the build system:

1. Fork the repository
2. Make your changes
3. Test the build
4. Submit a pull request

## Support

For build issues, check:
- [Arch Wiki - Archiso](https://wiki.archlinux.org/title/Archiso)
- [Archgle GitHub Issues](https://github.com/Spyko2001/Archgle/issues)
