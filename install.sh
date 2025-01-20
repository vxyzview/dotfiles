#!/bin/bash

# System setup script for Arch Linux and Void Linux with snapshots
set -euo pipefail
trap 'log "ERROR" "An error occurred on line $LINENO. Exit code: $?"' ERR

# Configurations
declare -r REPOSITORY="https://github.com/pyranix/dotfiles"
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
)
ARCH_PACKAGES=(
    xclip powertop libnotify xfce4-notifyd bluez blueman rofi
    networkmanager alacritty git curl neovim xfce4-settings qtile xorg-xinput
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
