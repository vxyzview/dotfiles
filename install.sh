#!/bin/bash

# Optimized script for system configuration and package installation
# Features parallel processing, better error handling, and cleaner organization

set -euo pipefail
trap 'echo "Error on line $LINENO. Exit code: $?"' ERR

# Configuration
declare -r GTK2_SYSTEM_WIDE="/etc/gtk-2.0"
declare -r GTK3_SYSTEM_WIDE="/etc/gtk-3.0"
declare -r REPOSITORY="https://github.com/pyranix/dotfiles"
declare -r DESTINATION="${HOME}/dotfiles"
declare -r TEMP_DIR="/tmp/setup-$$"
declare -r LOG_FILE="/tmp/setup-$$.log"

# Load package lists from separate arrays for better maintainability
source <(cat << 'EOF'
declare -ra VOID_PACKAGES=(
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

declare -ra ARCH_PACKAGES=(
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
EOF
)

# Logging function
log() {
    local level="$1"
    shift
    echo "[$level] $(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

# Error handling function
die() {
    log "ERROR" "$*"
    exit 1
}

# Function to check command existence with timeout
command_exists() {
    timeout 5 command -v "$1" &>/dev/null
}

# Parallel installation for supported package managers
parallel_install() {
    local -n packages=$1
    local chunk_size=10
    local total=${#packages[@]}
    
    for ((i = 0; i < total; i += chunk_size)); do
        local end=$((i + chunk_size))
        [[ $end -gt $total ]] && end=$total
        local chunk=("${packages[@]:i:chunk_size}")
        
        if command_exists xbps-install; then
            sudo xbps-install -y "${chunk[@]}" &
        elif command_exists yay; then
            yay -S --noconfirm "${chunk[@]}" &
        fi
    done
    wait
}

# Optimized Yay installation
install_yay() {
    if ! command_exists yay; then
        log "INFO" "Installing yay..."
        mkdir -p "$TEMP_DIR"
        git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$TEMP_DIR/yay" || die "Failed to clone yay"
        (cd "$TEMP_DIR/yay" && makepkg -si --noconfirm) || die "Failed to install yay"
        rm -rf "$TEMP_DIR/yay"
    fi
}

# Optimized package installation
install_packages() {
    if command_exists xbps-install; then
        log "INFO" "Installing packages for Void Linux..."
        sudo xbps-install -Sy void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
        parallel_install VOID_PACKAGES
    elif command_exists pacman; then
        install_yay
        log "INFO" "Installing packages for Arch Linux..."
        parallel_install ARCH_PACKAGES
    else
        die "Unsupported distribution"
    fi
}

# Optimized repository handling
setup_repository() {
    if [[ ! -d "$DESTINATION" ]]; then
        log "INFO" "Cloning repository..."
        git clone --depth 1 "$REPOSITORY" "$DESTINATION" || die "Failed to clone repository"
    fi
    
    log "INFO" "Syncing configuration files..."
    rsync -a --delete \
          --exclude={.git,.git*,install.sh,images,.scripts*,README.md} \
          "$DESTINATION/" "$HOME/" || die "Failed to sync config files"
}

# Optimized font configuration
configure_fonts() {
    log "INFO" "Configuring fonts..."
    fc-cache -f &>/dev/null
    
    if fc-list | grep -iq "JetBrainsMono Nerd Font"; then
        xfconf-query -n -c xsettings -p /Gtk/FontName -t string -s "JetBrainsMono Nerd Font 11"
        xfconf-query -n -c xfwm4 -p /general/title_font -t string -s "JetBrainsMono Nerd Font Bold 11"
        xfconf-query -n -c xsettings -p /Xft/DPI -t int -s 96
    else
        die "Required font not found"
    fi
}

# Optimized system configuration
configure_system() {
    log "INFO" "Applying system configurations..."
    
    # Parallel copy operations
    {
        sudo cp -r "$DESTINATION/.icons/"* /usr/share/icons/ &
        sudo cp -r "$DESTINATION/.themes/"* /usr/share/themes/ &
        sudo cp -r "$DESTINATION/.fonts/"* /usr/share/fonts/ &
        sudo cp "$DESTINATION/.config/gtk-3.0/settings.ini" "$GTK3_SYSTEM_WIDE/" &
        sudo cp "$DESTINATION/.gtkrc-2.0" "$GTK2_SYSTEM_WIDE/" &
    } wait
    
    # Update XDG directories
    xdg-user-dirs-update &
    xdg-user-dirs-gtk-update &
    wait
}

# Main execution with cleanup
main() {
    mkdir -p "$TEMP_DIR"
    
    # Execute main functions
    install_packages
    setup_repository
    configure_fonts
    configure_system
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    log "INFO" "Setup completed successfully"
}

main "$@"
