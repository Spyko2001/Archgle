#!/bin/bash
# Project Archgle - Part 1: Base System Installer
# WARNING: THIS WILL WIPE YOUR DRIVE.

# --- CONFIGURATION ---
DISK="/dev/sda"             # CHANGE THIS to your SSD (use 'lsblk' to check)
HOSTNAME="archgle"
USERNAME="admin"            # Your new user
PASSWORD="password123"      # CHANGE THIS immediately after install!
REGION="Europe"
CITY="Athens"
# ---------------------

echo "⚠️  WARNING: ALL DATA ON $DISK WILL BE DESTROYED. STARTING IN 5 SECONDS..."
sleep 5

# 1. Partitioning & Formatting (Btrfs Optimized)
echo ">> Wiping and Partitioning..."
wipefs -a $DISK
parted $DISK mklabel gpt
parted $DISK mkpart ESP fat32 1MiB 513MiB
parted $DISK set 1 boot on
parted $DISK mkpart ROOT btrfs 513MiB 100%

mkfs.fat -F32 -n BOOT ${DISK}1
mkfs.btrfs -f -L ARCHGLE ${DISK}2

# 2. Btrfs Subvolumes (Snapshot Layout)
echo ">> Creating Subvolumes..."
mount ${DISK}2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@snapshots
umount /mnt

mount -o noatime,compress=zstd:3,space_cache=v2,subvol=@ ${DISK}2 /mnt
mkdir -p /mnt/{boot,home,var,.snapshots}
mount -o noatime,compress=zstd:3,space_cache=v2,subvol=@home ${DISK}2 /mnt/home
mount -o noatime,compress=zstd:3,space_cache=v2,subvol=@var ${DISK}2 /mnt/var
mount -o noatime,compress=zstd:3,space_cache=v2,subvol=@snapshots ${DISK}2 /mnt/.snapshots
mount ${DISK}1 /mnt/boot

# 3. Base Install
echo ">> Installing Base System..."
pacstrap /mnt base linux linux-firmware git vim networkmanager intel-ucode sudo btrfs-progs base-devel

# 4. System Config
genfstab -U /mnt >> /mnt/etc/fstab
ln -sf /mnt/usr/share/zoneinfo/$REGION/$CITY /mnt/etc/localtime
arch-chroot /mnt hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
echo "$HOSTNAME" > /mnt/etc/hostname

# 5. User & Network Setup
echo ">> Setting up User: $USERNAME..."
arch-chroot /mnt useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | arch-chroot /mnt chpasswd
echo "root:$PASSWORD" | arch-chroot /mnt chpasswd
echo "%wheel ALL=(ALL) ALL" > /mnt/etc/sudoers.d/99_wheel

arch-chroot /mnt systemctl enable NetworkManager

# 6. Bootloader (GRUB)
echo ">> Installing GRUB..."
arch-chroot /mnt pacman -S --noconfirm grub efibootmgr
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCHGLE
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

echo "✅ Part 1 Complete! Copying Part 2 script..."
# Assume Part 2 is in the same folder as this script
cp install_post.sh /mnt/home/$USERNAME/install_post.sh
chmod +x /mnt/home/$USERNAME/install_post.sh
arch-chroot /mnt chown $USERNAME:$USERNAME /home/$USERNAME/install_post.sh

echo ">> Rebooting in 3 seconds. Remove USB!"
sleep 3
reboot
