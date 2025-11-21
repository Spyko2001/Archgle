# ⚡ Archgle — The Ultimate Hybrid Workstation

### Hyper-Optimized Arch Linux for Pentesting • Cloud Development • AI Workflows

<p align="center">
  <img src="https://img.shields.io/badge/Arch-Linux-blue?style=for-the-badge">
  <img src="https://img.shields.io/badge/Window%20Manager-Hyprland-purple?style=for-the-badge">
  <img src="https://img.shields.io/badge/Performance-Optimized-brightgreen?style=for-the-badge">
  <img src="https://img.shields.io/badge/Google-Tools-black?style=for-the-badge">
</p>

---

## 📖 About The Project

**Archgle** (Arch + Google) is a high-performance, hybrid Arch Linux environment designed to transform **low-spec hardware** into a smooth, powerful workstation.

Built for:

* 🛡️ **Pentesting**
* ☁️ **Cloud & DevOps Workflows**
* 🤖 **AI / Agentic Workloads**
* 🖥️ **Daily Driving**

Archgle uses **kernel-level optimizations**, **Btrfs storage tuning**, **ZRAM**, and the ultra-light **Hyprland Wayland compositor** to deliver **Mac/Windows-tier smoothness** with full Arch Linux flexibility.

---

## ✨ Key Features

### 🧠 Low-Spec Optimization Engine

* **RAM Doubling**
  `zram-generator` with `zstd` compression makes **8GB behave like 12–16GB**.

* **Storage Compression**
  Btrfs with `compress=zstd:3` saves **30–40% disk space** on code & forensic data.

* **Windows-Like Paging**
  `vm.swappiness=130` keeps active windows responsive while pushing background tasks to ZRAM swap.

---

### 🛡️ Hybrid Security & Dev Environment

* **Antigravity Ready**
  Custom wrapper prevents the IDE from hogging system memory.

* **Gemini OS Mode**
  **Super + G** opens a floating Gemini AI agent for instant terminal code generation.

* **Panic Button**
  **Super + Shift + N** triggers a hardware-level **network kill switch**.

* **BlackArch Slim**
  Only essential pentesting tools — no bloat.

---

## 🚀 Installation Guide

### Two-Phase Automated Deployment

---

## 📦 Prerequisites

* Arch Linux bootable USB
* Minimum **8GB RAM / 250GB storage**
* `install_usb.sh` and `install_post.sh` copied to USB

---

# 🧩 Phase 1 — Base System Provisioning

### `install_usb.sh`

> ⚠️ **WARNING: THIS SCRIPT WILL COMPLETELY WIPE YOUR TARGET DISK.**

This script handles:

* Disk partitioning
* Btrfs subvolumes (with compression)
* Base system installation (`pacstrap`)
* Copies Phase 2 installer to the new system

Run from the **Arch ISO live environment**:

```bash
#!/bin/bash
# Project Archgle - Part 1: Base System Installer
# WARNING: THIS WILL WIPE YOUR DISK. Review variables before running.

DISK="/dev/sda"             # CHANGE THIS to your SSD (use 'lsblk' to check)
USERNAME="admin"
PASSWORD="password123"      # CHANGE THIS immediately after install!

echo "⚠️  WARNING: ALL DATA ON $DISK WILL BE DESTROYED. STARTING IN 5 SECONDS..."
# ... (rest of partitioning and pacstrap commands) ...

# The script copies install_post.sh to new user's home and reboots.
# ...
```

---

# 🧩 Phase 2 — Post-Install Environment Setup

### `install_post.sh`

Run after rebooting into the new Arch install:

```bash
#!/bin/bash
# Project Archgle - Part 2: The "Google Pixel" Experience
# Installs Hyprland, ZRAM, Google Tools, and Pentest Utils

echo "🚀 Starting Phase 2: Building Archgle..."
# This script performs the following:
# 1. Installs Yay (AUR helper)
# 2. Configures ZRAM and custom Swappiness
# 3. Installs Hyprland, Material You theme, and Google fonts
# 4. Installs Google Cloud SDK, Gemini CLI, and Antigravity-bin
# 5. Installs the BlackArch Slim pentesting toolkit
# 6. Sets up all dotfiles and the memory-safe launch wrappers.

# ... (Script commands here) ...
echo "✅ INSTALLATION COMPLETE! Log out and back in to start Hyprland."
```

---

## ⌨️ Keybindings (Hyprland)

| Keybind               | Action             | Context                        |
| --------------------- | ------------------ | ------------------------------ |
| **Super + Space**     | App Launcher       | Wofi (Material Themed)         |
| **Super + Q**         | Terminal           | Kitty                          |
| **Super + G**         | Gemini Agent       | Floating AI Chat Window        |
| **Super + Return**    | Launch Antigravity | Through memory-safe wrapper    |
| **Super + Shift + N** | ⚠️ PANIC BUTTON    | Disable all network interfaces |
| **3-Finger Swipe**    | Switch Workspace   | Left/Right                     |

---

## 🏗️ System Architecture

```
Archgle
├── Optimized Kernel (zram + IO schedulers)
├── BTRFS (compress=zstd:3)
├── Hyprland (Wayland)
├── Google Cloud / Gemini / Antigravity
├── BlackArch Slim Toolkit
└── Memory-Safe Wrappers & System Tweaks
```

---

## ⚠️ Legal Disclaimer

* Not affiliated with Google in any way.
* Pentesting tools included in this project must **only** be used on systems you own or have explicit permission to test.
* The author is not responsible for misuse or damages.

---

## ❤️ Community

Built with passion for:

* The **Arch Linux** community
* **Pentesters & Red Teamers**
* **Cloud developers & SREs**
* **AI researchers and power users**

---

## ⭐ Support the Project

If you like Archgle:

* ⭐ Star the repo
* 🐛 Submit issues
* 🧩 Contribute pull requests
* 📢 Share with the community

---

### 🚀 Welcome to your new supercharged Linux workstation.
