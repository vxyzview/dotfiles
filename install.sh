#!/bin/bash

# System setup script for Arch Linux and Void Linux with snapshots
set -euo pipefail
trap 'log "ERROR" "An error occurred on line $LINENO. Exit code: $?"' ERR

# Configurations
declare -r REPOSITORY="https://github.com/vxyzview/dotfiles"
declare -r DESTINATION="${HOME}/dotfiles"
declare -r SNAPSHOT_DIR="${HOME}/system_snapshot_$(date +%Y%m%d_%H%M%S)"
declare -r TEMP_DIR="/tmp/setup-$$"
declare -r LOG_FILE="/tmp/setup-$$.log"

# Colors and styling for logging
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
RESET="\033[0m"
BOLD="\033[1m"

# Void and Arch package lists
VOID_PACKAGES=(
    xclip powertop xfce4-notifyd pulseaudio bluez blueman rofi pamixer
    NetworkManager alacritty git curl neovim xfce4-settings qtile xorg-minimal
    xorg-input-drivers xorg-fonts xorg-video-drivers xorg-server xsettingsd
    dconf-editor dconf rsync wget aria2 dunst python3 feh gtk+ gtk+3 gtk4
    nano xinit xsetroot dbus elogind gcc gcc-multilib thunar-volman
    thunar-archive-plugin thunar-media-tags-plugin pipewire pavucontrol
    starship psutils acpi acpica-utils acpid dhcpcd-gtk ImageMagick pfetch
    htop exa openssh openssl xdg-user-dirs xdg-user-dirs-gtk picom gnupg2
    mpv nwg-launchers nwg-look linux-firmware-intel intel-gmmlib
    intel-gpu-tools intel-media-driver intel-ucode intel-video-accel
    vulkan-loader android-file-transfer-linux android-tools android-udev-rules
    libvirt libvirt-glib libvirt-python3 gvfs udiskie udisks2 brightnessctl
    xdotool apparmor libselinux rpm rpmextract lxappearance lxappearance-obconf
    xfce4-power-manager xfce-polkit polkit-elogind maim viewnior nodeenv
    nodejs xdg-desktop-portal xdg-desktop-portal-kde xdg-desktop-portal-wlr
    xdg-desktop-portal-gnome xdg-desktop-portal-gtk zip unzip tar 7zip bzip2
    zstd lz4 xz libXft-devel libXinerama-devel make virt-manager fish-shell
    pasystray network-manager-applet
)
ARCH_PACKAGES=(
    plymouth schedtool modprobe-db update-grub xclip powertop libnotify
    xfce4-notifyd bluez bluez-plugins bluez-cups cups blueman rofi
    networkmanager alacritty git curl neovim xfce4-settings qtile xorg-xinput
    xorg-drivers xorg-fonts xorg-xvidtune xorg-server xsettingsd dconf
    dconf-editor rsync wget aria2 dunst python feh gtk3 gtk4 gtk2 nano
    xorg-xinit xorg-xsetroot gcc thunar thunar-archive-plugin
    thunar-media-tags-plugin thunar-volman pavucontrol psutils python-psutil
    acpi acpica acpid imagemagick htop exa fzf expac openssh openssl
    xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
    xdg-desktop-portal-xapp xdg-user-dirs xdg-user-dirs-gtk xdg-utils picom
    gnupg mpv linux-firmware intel-media-driver intel-gmmlib intel-gpu-tools
    intel-ucode intel-media-sdk xf86-input-libinput xf86-input-synaptics
    xf86-video-intel xf86-video-fbdev xf86-video-vesa xf86-input-evdev
    vulkan-intel vulkan-icd-loader vulkan-mesa-layers vulkan-tools
    vulkan-utility-libraries vulkan-virtio vulkan-validation-layers
    lib32-vulkan-icd-loader lib32-vulkan-intel lib32-vulkan-mesa-layers
    lib32-vulkan-validation-layers lib32-vulkan-virtio android-file-transfer
    android-tools android-udev gvfs gvfs-afc gvfs-goa gvfs-google gvfs-gphoto2
    gvfs-mtp gvfs-nfs gvfs-smb udiskie udisks2 brightnessctl polkit xdotool
    apparmor lxappearance lxappearance-obconf xfce4-power-manager maim
    viewnior nodejs gedit gedit-plugins zip unzip tar p7zip unrar bzip2
    zstd lz4 xz libxft libxinerama make cmake fish pasystray
    network-manager-applet gamescope gamemode jq
)

# Logging with enhanced visuals
log() {
    local level="$1"
    local message="$2"
    local icon=""
    local color=""

    case "$level" in
        "INFO") color=$BLUE; icon="ℹ️ " ;;
        "SUCCESS") color=$GREEN; icon="✔" ;;
        "WARNING") color=$YELLOW; icon="⚠️ " ;;
        "ERROR") color=$RED; icon="❌" ;;
        *) color=$RESET; icon="➤" ;;
    esac

    printf "${BOLD}[${color}${icon}${RESET}${BOLD}] $(date '+%Y-%m-%d %H:%M:%S') - ${message}${RESET}\n" | tee -a "$LOG_FILE"
}

# Error handler
die() {
    log "ERROR" "$1"
    exit 1
}

# Check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Create system snapshot
create_snapshot() {
    log "INFO" "Creating a system snapshot at $SNAPSHOT_DIR..."
    mkdir -p "$SNAPSHOT_DIR" || die "Failed to create snapshot directory"

    # Save a list of installed packages
    if command_exists pacman; then
        pacman -Qqe >"$SNAPSHOT_DIR/installed_packages.txt" &
    elif command_exists xbps-query; then
        xbps-query -l | awk '{print $2}' >"$SNAPSHOT_DIR/installed_packages.txt" &
    fi

    # Backup user configuration files
    tar -czf "$SNAPSHOT_DIR/config_backup.tar.gz" \
        "${HOME}/.config" \
        "${HOME}/.bashrc" \
        "${HOME}/.zshrc" \
        "${HOME}/.vimrc" \
        &>/dev/null
    log "SUCCESS" "Snapshot created successfully at $SNAPSHOT_DIR"
}

# Install packages for Void or Arch
install_packages() {
    if command_exists xbps-install; then
        log "INFO" "Detected Void Linux. Installing packages..."
        sudo xbps-install -Sy void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
        sudo xbps-install -Sy "${VOID_PACKAGES[@]}"
        log "SUCCESS" "Packages installed successfully on Void Linux"
    elif command_exists pacman; then
        log "INFO" "Detected Arch Linux. Installing packages..."
        if ! command_exists yay; then
            log "INFO" "Installing yay package manager..."
            mkdir -p "$TEMP_DIR"
            git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$TEMP_DIR/yay" || die "Failed to clone yay repository"
            (cd "$TEMP_DIR/yay" && makepkg -si --noconfirm) || die "Failed to install yay"
            rm -rf "$TEMP_DIR/yay"
            log "SUCCESS" "yay installed successfully"
        fi
        yay -Syu --noconfirm "${ARCH_PACKAGES[@]}"
        log "SUCCESS" "Packages installed successfully on Arch Linux"
    else
        die "Unsupported distribution. Exiting."
    fi
}

# Clone and sync repository
setup_repository() {
    if [[ ! -d "$DESTINATION" ]]; then
        log "INFO" "Cloning dotfiles repository..."
        git clone --depth 1 "$REPOSITORY" "$DESTINATION" || die "Failed to clone repository"
    fi

    log "INFO" "Syncing configuration files..."
    rsync -a --delete \
          --exclude={.git,.git*,install.sh,images,.scripts*,README.md} \
          "$DESTINATION/" "$HOME/" || die "Failed to sync configuration files"
    log "SUCCESS" "Configuration files synced successfully"
}

# Main function
main() {
    clear
    log "INFO" "🎉 Starting system setup for Arch Linux and Void Linux..."
    create_snapshot
    install_packages
    setup_repository
    log "SUCCESS" "✨ Setup completed successfully! Snapshot saved at: $SNAPSHOT_DIR 🚀"
}

main "$@"
