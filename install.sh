#!/usr/bin/env bash

# Enhanced script to setup system configurations and install packages
# for Void Linux and Arch Linux distributions

set -euo pipefail
IFS=$'\n\t'

#==============================================================================
# Configuration Variables
#==============================================================================
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly GTK2_SYSTEM_WIDE="/etc/gtk-2.0"
readonly GTK3_SYSTEM_WIDE="/etc/gtk-3.0"
readonly REPOSITORY="https://github.com/pyranix/dotfiles"
readonly DESTINATION="${HOME}/dotfiles"
readonly LOG_FILE="/tmp/system-setup-$(date +%F-%H%M%S).log"

#==============================================================================
# Package Arrays
#==============================================================================
# Common packages across distributions
readonly COMMON_PACKAGES=(
    xclip git curl neovim feh htop
    rsync wget openssh openssl nano
    xorg-server dunst python3 NetworkManager
    alacritty rofi picom bluez blueman
    zip unzip tar bzip2 zstd lz4 xz
    gvfs udiskie udisks2 brightnessctl
    thunar thunar-archive-plugin thunar-media-tags-plugin
    xdg-user-dirs xdg-desktop-portal make
    pavucontrol acpi acpid imagemagick
    qtile dconf gtk+3 starship
)

# Void-specific packages
readonly VOID_SPECIFIC=(
    void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
    xorg-minimal xorg-input-drivers xorg-fonts xorg-video-drivers
    xfce4-settings xfce4-notifyd powertop pamixer
    xsettingsd dconf-editor aria2 gtk+ gtk4 xinit xsetroot
    dbus elogind gcc gcc-multilib thunar-volman
    psutils acpica-utils dhcpcd-gtk pfetch exa
    nwg-launchers nwg-look linux-firmware-intel intel-gmmlib
    intel-gpu-tools intel-media-driver intel-ucode intel-video-accel
    vulkan-loader android-file-transfer-linux android-tools android-udev-rules
    libvirt libvirt-glib libvirt-python3 xdotool
    apparmor libselinux rpm rpmextract lxappearance lxappearance-obconf
    xfce4-power-manager xfce-polkit polkit-elogind maim viewnior nodeenv
    nodejs xdg-desktop-portal-kde xdg-desktop-portal-wlr
    xdg-desktop-portal-gnome xdg-desktop-portal-gtk 7zip
    libXft-devel libXinerama-devel virt-manager fish-shell
    pasystray network-manager-applet
)

# Arch-specific packages
readonly ARCH_SPECIFIC=(
    plymouth schedtool modprobe-db update-grub libnotify
    xfce4-notifyd bluez-plugins bluez-cups cups
    networkmanager xorg-xinput xorg-drivers xorg-fonts
    xorg-xvidtune xsettingsd dconf-editor aria2
    gtk3 gtk4 gtk2 xorg-xinit xorg-xsetroot gcc
    python-psutil acpica imagemagick exa fzf expac
    xdg-desktop-portal-wlr xdg-desktop-portal-gtk
    xdg-desktop-portal-xapp xdg-user-dirs-gtk xdg-utils
    gnupg mpv linux-firmware intel-media-driver intel-gmmlib intel-gpu-tools
    intel-ucode intel-media-sdk xf86-input-libinput xf86-input-synaptics
    xf86-video-intel xf86-video-fbdev xf86-video-vesa xf86-input-evdev
    vulkan-intel vulkan-icd-loader vulkan-mesa-layers vulkan-tools
    vulkan-utility-libraries vulkan-virtio vulkan-validation-layers
    lib32-vulkan-icd-loader lib32-vulkan-intel lib32-vulkan-mesa-layers
    lib32-vulkan-validation-layers lib32-vulkan-virtio android-file-transfer
    android-tools android-udev gvfs-afc gvfs-goa gvfs-google gvfs-gphoto2
    gvfs-mtp gvfs-nfs gvfs-smb xdotool
    apparmor lxappearance lxappearance-obconf xfce4-power-manager maim
    viewnior nodejs gedit gedit-plugins p7zip unrar
    libxft libxinerama cmake fish pasystray
    network-manager-applet gamescope gamemode jq
)

#==============================================================================
# Utility Functions
#==============================================================================

# Usage information
print_usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Options:
  -h, --help                 Show this help message and exit
  -n, --no-packages          Skip package installation
  -c, --config-only          Only sync configuration files
  -f, --font-skip            Skip font configuration
  --log-file=FILE            Use specified log file instead of default
  --debug                    Enable debug mode

EOF
}

# Logging functions
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Color codes for terminal output
    local color_reset="\033[0m"
    local color_red="\033[0;31m"
    local color_green="\033[0;32m"
    local color_yellow="\033[0;33m"
    local color_blue="\033[0;34m"
    
    local color=""
    case "$level" in
        "INFO")  color="$color_green" ;;
        "WARN")  color="$color_yellow" ;;
        "ERROR") color="$color_red" ;;
        "DEBUG") color="$color_blue" ;;
        *)       color="$color_reset" ;;
    esac
    
    # Only print DEBUG messages if debug mode is enabled
    if [[ "$level" == "DEBUG" && "$DEBUG_MODE" != "true" ]]; then
        return
    fi
    
    # Write to console with colors
    echo -e "${color}[ ${level} ]${color_reset} ${message}" >&2
    
    # Write to log file without colors
    echo "[ ${level} ] ${timestamp} ${message}" >> "$LOG_FILE"
}

info() {
    log "INFO" "$1"
}

warn() {
    log "WARN" "$1"
}

error() {
    log "ERROR" "$1"
    exit 1
}

debug() {
    log "DEBUG" "$1"
}

# Check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Check distributions
is_void() {
    command_exists xbps-install
}

is_arch() {
    command_exists pacman
}

# Execute with retries
retry() {
    local retries=$1
    shift
    local count=0
    
    until "$@"; do
        exit=$?
        count=$((count + 1))
        
        if [[ $count -lt $retries ]]; then
            warn "Command failed (attempt $count/$retries). Retrying in 5 seconds..."
            sleep 5
        else
            error "Command failed after $retries attempts: $*"
            return $exit
        fi
    done
    return 0
}

# Check for root permissions
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
    fi
}

#==============================================================================
# Package Management Functions
#==============================================================================

# Install yay AUR helper for Arch Linux
install_yay() {
    if ! command_exists yay; then
        info "Installing yay AUR helper..."
        local temp_dir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay-bin.git "$temp_dir" || error "Failed to clone yay repository"
        (cd "$temp_dir" && makepkg -si --noconfirm) || error "Failed to install yay"
        rm -rf "$temp_dir"
        info "yay installed successfully"
    else
        info "yay is already installed"
    fi
}

# Install packages based on distribution
install_packages() {
    local distro=""
    
    if is_void; then
        distro="Void Linux"
        info "Installing packages for Void Linux..."
        
        # Enable non-free repositories
        sudo xbps-install -Sy void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree || 
            error "Failed to enable Void Linux repositories"
        
        # Combine common and Void-specific packages
        local all_packages=("${COMMON_PACKAGES[@]}" "${VOID_SPECIFIC[@]}")
        
        # Install in batches to avoid potential issues with very long command lines
        local batch_size=20
        local package_count=${#all_packages[@]}
        
        for ((i=0; i<package_count; i+=batch_size)); do
            local end=$((i + batch_size))
            if [[ $end -gt $package_count ]]; then
                end=$package_count
            fi
            
            local batch=("${all_packages[@]:i:end-i}")
            debug "Installing batch: ${batch[*]}"
            retry 3 sudo xbps-install -Sy "${batch[@]}" || warn "Failed to install some packages in batch"
        done
        
    elif is_arch; then
        distro="Arch Linux"
        info "Installing packages for Arch Linux..."
        
        # Install yay if not already installed
        install_yay
        
        # Update package database
        retry 3 sudo pacman -Syy || error "Failed to update package database"
        
        # Combine common and Arch-specific packages
        local all_packages=("${COMMON_PACKAGES[@]}" "${ARCH_SPECIFIC[@]}")
        
        # Install packages in batches
        local batch_size=20
        local package_count=${#all_packages[@]}
        
        for ((i=0; i<package_count; i+=batch_size)); do
            local end=$((i + batch_size))
            if [[ $end -gt $package_count ]]; then
                end=$package_count
            fi
            
            local batch=("${all_packages[@]:i:end-i}")
            debug "Installing batch: ${batch[*]}"
            retry 3 yay -S --needed --noconfirm "${batch[@]}" || warn "Failed to install some packages in batch"
        done
        
    else
        error "Unsupported distribution. This script supports Void Linux and Arch Linux."
    fi
    
    info "Package installation completed for $distro"
}

# Install Starship shell prompt
install_starship() {
    info "Installing Starship shell prompt..."
    
    if command_exists starship; then
        info "Starship is already installed"
        return 0
    fi
    
    if is_void; then
        retry 3 sudo xbps-install -Sy starship || warn "Failed to install starship via xbps"
    elif is_arch; then
        retry 3 yay -S --needed --noconfirm starship || warn "Failed to install starship via yay"
    else
        info "Installing starship via the official installer..."
        retry 3 curl -fsSL https://starship.rs/install.sh | sh
    fi
    
    if command_exists starship; then
        info "Starship installed successfully"
    else
        warn "Failed to install starship"
    fi
}

#==============================================================================
# Configuration Functions
#==============================================================================

# Clone dotfiles repository
clone_repository() {
    if [[ -d "$DESTINATION" ]]; then
        info "Repository directory already exists at $DESTINATION"
        
        # Ask if user wants to update
        read -rp "Would you like to update the repository? [Y/n] " response
        response=${response,,} # Convert to lowercase
        
        if [[ "$response" =~ ^(no|n)$ ]]; then
            info "Skipping repository update"
            return 0
        fi
        
        info "Updating repository..."
        (cd "$DESTINATION" && git pull) || error "Failed to update repository"
        info "Repository updated successfully"
    else
        info "Cloning dotfiles repository to $DESTINATION..."
        retry 3 git clone "$REPOSITORY" "$DESTINATION" || error "Failed to clone repository"
        info "Repository cloned successfully"
    fi
}

# Sync config files from repository to home directory
sync_config_files() {
    info "Synchronizing configuration files..."
    
    if [[ ! -d "$DESTINATION" ]]; then
        error "Repository directory not found at $DESTINATION. Run clone_repository first."
    fi
    
    # Create backup of existing configs
    local backup_dir="${HOME}/.config-backup-$(date +%F-%H%M%S)"
    mkdir -p "$backup_dir"
    
    # List of directories to back up
    local backup_dirs=(
        "${HOME}/.config/qtile"
        "${HOME}/.config/alacritty"
        "${HOME}/.config/gtk-3.0"
        "${HOME}/.config/dunst"
        "${HOME}/.config/picom"
        "${HOME}/.config/rofi"
    )
    
    # Backup existing configs
    for dir in "${backup_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            cp -r "$dir" "$backup_dir/" || warn "Failed to backup $dir"
        fi
    done
    
    info "Backed up existing configurations to $backup_dir"
    
    # Sync config files, excluding git and miscellaneous files
    rsync -av --progress \
        --exclude=".git*" \
        --exclude="install.sh" \
        --exclude="images" \
        --exclude=".scripts*" \
        --exclude="README.md" \
        --exclude="LICENSE" \
        "$DESTINATION/" "$HOME/" || error "Failed to sync configuration files"
    
    info "Configuration files synchronized"
}

# Configure fonts
configure_fonts() {
    info "Configuring fonts..."
    
    # Refresh font cache
    fc-cache -f
    
    # Check if JetBrainsMono Nerd Font is installed
    if fc-list | grep -iq "JetBrainsMono Nerd Font"; then
        info "JetBrainsMono Nerd Font found, setting as default font"
        
        # Configure for XFCE if xfconf-query is available
        if command_exists xfconf-query; then
            xfconf-query -c xsettings -p /Gtk/FontName -s "JetBrainsMono Nerd Font 11" || warn "Failed to set GTK font"
            xfconf-query -c xfwm4 -p /general/title_font -s "JetBrainsMono Nerd Font Bold 11" || warn "Failed to set window title font"
            xfconf-query -c xsettings -p /Xft/DPI -s "96" || warn "Failed to set DPI"
            info "XFCE font configuration applied"
        else
            info "xfconf-query not available, skipping XFCE-specific font settings"
        fi
        
        # Configure for GTK
        mkdir -p "${HOME}/.config/gtk-3.0"
        cat > "${HOME}/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-font-name=JetBrainsMono Nerd Font 11
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
EOF
        info "GTK3 font configuration applied"
        
        # Configure for GTK2
        cat > "${HOME}/.gtkrc-2.0" << EOF
gtk-font-name="JetBrainsMono Nerd Font 11"
gtk-theme-name="Arc-Dark"
gtk-icon-theme-name="Papirus-Dark"
gtk-cursor-theme-name="Adwaita"
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle="hintfull"
gtk-xft-rgba="rgb"
EOF
        info "GTK2 font configuration applied"
    else
        warn "JetBrainsMono Nerd Font not found. Consider installing it for best experience."
        
        # Optional: Install JetBrainsMono Nerd Font if user approves
        read -rp "Would you like to install JetBrainsMono Nerd Font now? [Y/n] " response
        response=${response,,} # Convert to lowercase
        
        if [[ ! "$response" =~ ^(no|n)$ ]]; then
            info "Installing JetBrainsMono Nerd Font..."
            
            local font_dir="${HOME}/.local/share/fonts/JetBrainsMono"
            mkdir -p "$font_dir"
            
            local temp_dir=$(mktemp -d)
            cd "$temp_dir" || error "Failed to create temporary directory"
            
            curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip || error "Failed to download font"
            unzip JetBrainsMono.zip -d "$font_dir" || error "Failed to extract font"
            
            cd - > /dev/null
            rm -rf "$temp_dir"
            
            fc-cache -f
            info "JetBrainsMono Nerd Font installed successfully"
            
            # Re-run font configuration
            configure_fonts
        fi
    fi
}

# Apply additional system-wide configurations
apply_system_configs() {
    info "Applying additional system-wide configurations..."
    
    # Create necessary directories if they don't exist
    for dir in "/usr/share/icons" "/usr/share/themes" "/usr/share/fonts"; do
        if [[ ! -d "$dir" ]]; then
            sudo mkdir -p "$dir" || warn "Failed to create $dir"
        fi
    done
    
    # Copy icons, themes, and fonts if they exist in the repository
    if [[ -d "$DESTINATION/.icons" ]]; then
        sudo cp -r "$DESTINATION/.icons/"* /usr/share/icons/ || warn "Failed to copy icons"
    fi
    
    if [[ -d "$DESTINATION/.themes" ]]; then
        sudo cp -r "$DESTINATION/.themes/"* /usr/share/themes/ || warn "Failed to copy themes"
    fi
    
    if [[ -d "$DESTINATION/.fonts" ]]; then
        sudo cp -r "$DESTINATION/.fonts/"* /usr/share/fonts/ || warn "Failed to copy fonts"
        sudo fc-cache -f || warn "Failed to update font cache"
    fi
    
    # Apply GTK configurations
    sudo mkdir -p "$GTK3_SYSTEM_WIDE" || warn "Failed to create GTK3 system directory"
    sudo mkdir -p "$GTK2_SYSTEM_WIDE" || warn "Failed to create GTK2 system directory"
    
    if [[ -f "$DESTINATION/.config/gtk-3.0/settings.ini" ]]; then
        sudo cp "$DESTINATION/.config/gtk-3.0/settings.ini" "$GTK3_SYSTEM_WIDE/" || warn "Failed to copy GTK3 settings"
    fi
    
    if [[ -f "$DESTINATION/.gtkrc-2.0" ]]; then
        sudo cp "$DESTINATION/.gtkrc-2.0" "$GTK2_SYSTEM_WIDE/" || warn "Failed to copy GTK2 settings"
    fi
    
    # Update XDG user directories
    if command_exists xdg-user-dirs-update; then
        xdg-user-dirs-update || warn "Failed to update XDG user directories"
    fi
    
    if command_exists xdg-user-dirs-gtk-update; then
        xdg-user-dirs-gtk-update || warn "Failed to update XDG user directories (GTK)"
    fi
    
    info "Additional system configurations applied"
}

# Set up shell configuration
setup_shell() {
    info "Setting up shell configuration..."
    
    # Set up fish shell if available
    if command_exists fish; then
        if [[ "$SHELL" != *"fish"* ]]; then
            info "Changing default shell to fish..."
            
            # Add fish to /etc/shells if not already there
            if ! grep -q "fish" /etc/shells; then
                echo "$(which fish)" | sudo tee -a /etc/shells > /dev/null
            fi
            
            # Change default shell
            chsh -s "$(which fish)" || warn "Failed to set fish as default shell"
        fi
        
        # Create fish config directory if it doesn't exist
        mkdir -p "${HOME}/.config/fish"
        
        # Add starship initialization to fish config if not already there
        if ! grep -q "starship init fish" "${HOME}/.config/fish/config.fish" 2>/dev/null; then
            echo 'if type -q starship' >> "${HOME}/.config/fish/config.fish"
            echo '    starship init fish | source' >> "${HOME}/.config/fish/config.fish"
            echo 'end' >> "${HOME}/.config/fish/config.fish"
            info "Added starship initialization to fish config"
        fi
    else
        # Add starship initialization to bash config if not already there
        if ! grep -q "starship init bash" "${HOME}/.bashrc" 2>/dev/null; then
            echo 'if command -v starship &> /dev/null; then' >> "${HOME}/.bashrc"
            echo '    eval "$(starship init bash)"' >> "${HOME}/.bashrc"
            echo 'fi' >> "${HOME}/.bashrc"
            info "Added starship initialization to bash config"
        fi
    fi
    
    info "Shell configuration completed"
}

#==============================================================================
# Main Execution
#==============================================================================

main() {
    # Parse command line arguments
    local skip_packages=false
    local config_only=false
    local skip_font=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                print_usage
                exit 0
                ;;
            -n|--no-packages)
                skip_packages=true
                shift
                ;;
            -c|--config-only)
                config_only=true
                shift
                ;;
            -f|--font-skip)
                skip_font=true
                shift
                ;;
            --log-file=*)
                LOG_FILE="${1#*=}"
                shift
                ;;
            --debug)
                DEBUG_MODE=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
    
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE" || error "Cannot write to log file $LOG_FILE"
    
    # Print banner
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║   ____            _                   ____       _           ║
║  / ___| _   _ ___| |_ ___ _ __ ___   / ___|  ___| |_ _   _  ║
║  \___ \| | | / __| __/ _ \ '_ ` _ \  \___ \ / _ \ __| | | | ║
║   ___) | |_| \__ \ ||  __/ | | | | |  ___) |  __/ |_| |_| | ║
║  |____/ \__, |___/\__\___|_| |_| |_| |____/ \___|\__|\__,_| ║
║         |___/                                               ║
╚══════════════════════════════════════════════════════════════╝
EOF
    
    info "Starting system setup script"
    info "Logging to $LOG_FILE"
    
    # Check permissions
    check_permissions
    
    # Install packages if not skipped
    if [[ "$skip_packages" == "false" && "$config_only" == "false" ]]; then
        install_packages
    else
        info "Skipping package installation"
    fi
    
    # Clone repository
    if [[ "$config_only" == "false" ]]; then
        clone_repository
    fi
    
    # Sync config files
    sync_config_files
    
    # Additional tasks if not config only
    if [[ "$config_only" == "false" ]]; then
        # Install starship
        install_starship
        
        # Configure fonts unless skipped
        if [[ "$skip_font" == "false" ]]; then
            configure_fonts
        else
            info "Skipping font configuration"
        fi
        
        # Apply system configs
        apply_system_configs
        
        # Set up shell configuration
        setup_shell
    fi
    
    info "Configuration setup completed successfully!"
    info "Log file: $LOG_FILE"
    
    # Suggest a system restart
    if [[ "$config_only" == "false" ]]; then
        echo
        echo "It is recommended to restart your system to apply all changes."
        read -rp "Would you like to restart now? [y/N] " response
        response=${response,,} # Convert to lowercase
        
        if [[ "$response" =~ ^(yes|y)$ ]]; then
            info "Restarting system..."
            sudo reboot
        else
            info "Please remember to restart your system later for all changes to take effect."
        fi
    fi
}

# Set default for debug mode
DEBUG_MODE=false

# Run main function
main "$@"
