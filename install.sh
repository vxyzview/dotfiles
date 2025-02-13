#!/bin/bash
# Script to setup system configurations and install packages based on Linux distribution
set -euo pipefail

# Configuration
readonly GTK2_SYSTEM_WIDE="/etc/gtk-2.0"
readonly GTK3_SYSTEM_WIDE="/etc/gtk-3.0"
readonly REPOSITORY="https://github.com/pyranix/dotfiles"
readonly DESTINATION="$HOME/dotfiles"
readonly LOG_FILE="$HOME/setup_log.txt"
readonly SUMMARY_FILE="$HOME/setup_summary.txt"

# Array of packages for Void Linux
void_packages=(
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

# Array of packages for Arch Linux
arch_packages=(
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

# Function to log messages
log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [$level] $message" >> "$LOG_FILE"
}

# Function to display a dialog message
show_message() {
    local title="$1"
    local message="$2"
    dialog --msgbox "$message" 10 50
}

# Function to display a progress bar
show_progress() {
    local title="$1"
    local message="$2"
    local percentage="$3"
    dialog --title "$title" --gauge "$message" 10 50 "$percentage"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to install dialog if not already installed
install_dialog() {
    if ! command_exists dialog; then
        log "INFO" "Dialog not found, installing dialog..."
        if command_exists xbps-install; then
            sudo xbps-install -Sy dialog > /dev/null 2>&1
        elif command_exists pacman; then
            sudo pacman -S --noconfirm dialog > /dev/null 2>&1
        else
            log "ERROR" "Cannot install dialog on this distribution."
            show_message "Error" "Cannot install dialog on this distribution."
            exit 1
        fi
        log "INFO" "Dialog installed successfully."
    else
        log "INFO" "Dialog is already installed."
    fi
}

# Function to install yay if not already installed
install_yay() {
    if ! command_exists yay; then
        log "INFO" "Yay not found, installing yay..."
        temp_dir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay-bin.git "$temp_dir" > /dev/null 2>&1
        (cd "$temp_dir" && makepkg -si --noconfirm) > /dev/null 2>&1
        rm -rf "$temp_dir"
        log "INFO" "Yay installed successfully."
    else
        log "INFO" "Yay is already installed."
    fi
}

# Function to determine distribution and install packages
install_packages() {
    if command_exists xbps-install; then
        log "INFO" "Installing packages for Void Linux..."
        show_progress "Installing Packages" "Installing packages for Void Linux..." 10
        sudo xbps-install -Sy void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree > /dev/null 2>&1
        show_progress "Installing Packages" "Installing packages for Void Linux..." 50
        sudo xbps-install -Sy "${void_packages[@]}" > /dev/null 2>&1
        show_progress "Installing Packages" "Installing packages for Void Linux..." 100
        log "INFO" "Packages installed successfully on Void Linux."
    elif command_exists pacman; then
        install_yay
        log "INFO" "Installing packages for Arch Linux..."
        show_progress "Installing Packages" "Installing packages for Arch Linux..." 10
        yay -S --noconfirm "${arch_packages[@]}" > /dev/null 2>&1
        show_progress "Installing Packages" "Installing packages for Arch Linux..." 100
        log "INFO" "Packages installed successfully on Arch Linux."
    else
        log "ERROR" "Package installation not supported on this distribution."
        show_message "Error" "Package installation not supported on this distribution."
        exit 1
    fi
}

# Function to clone repository if not already present
clone_repository() {
    if [ ! -d "$DESTINATION" ]; then
        log "INFO" "Cloning repository..."
        show_progress "Cloning Repository" "Cloning repository..." 50
        if git clone "$REPOSITORY" "$DESTINATION" > /dev/null 2>&1; then
            show_progress "Cloning Repository" "Cloning repository..." 100
            log "INFO" "Repository cloned successfully."
        else
            log "ERROR" "Failed to clone repository."
            show_message "Error" "Failed to clone repository."
            exit 1
        fi
    else
        log "INFO" "Repository already exists. Updating..."
        show_progress "Updating Repository" "Updating repository..." 50
        if (cd "$DESTINATION" && git pull > /dev/null 2>&1); then
            show_progress "Updating Repository" "Updating repository..." 100
            log "INFO" "Repository updated successfully."
        else
            log "ERROR" "Failed to update repository."
            show_message "Error" "Failed to update repository."
            exit 1
        fi
    fi
}

# Function to sync configuration files
sync_config_files() {
    log "INFO" "Synchronizing configuration files..."
    show_progress "Synchronizing Config Files" "Synchronizing configuration files..." 50
    rsync -av --exclude={'.git*', 'install.sh', 'images', '.scripts*', 'README.md'} "$DESTINATION/" "$HOME" > /dev/null 2>&1
    show_progress "Synchronizing Config Files" "Synchronizing configuration files..." 100
    log "INFO" "Configuration files synchronized."
}

# Function to install Starship shell prompt
starship_shell_install() {
    log "INFO" "Installing Starship shell prompt..."
    show_progress "Installing Starship" "Installing Starship shell prompt..." 50
    if command_exists xbps-install || command_exists pacman; then
        sudo xbps-install -Sy starship > /dev/null 2>&1 || yay -S --noconfirm starship > /dev/null 2>&1
    else
        curl -fsSL https://starship.rs/install.sh | sh > /dev/null 2>&1
    fi
    show_progress "Installing Starship" "Installing Starship shell prompt..." 100
    log "INFO" "Starship installed successfully."
}

# Function to copy fonts
copy_fonts() {
    log "INFO" "Copying fonts..."
    show_progress "Copying Fonts" "Copying fonts..." 50
    if [ -d "$DESTINATION/.fonts" ]; then
        sudo cp -r "$DESTINATION/.fonts/"* /usr/share/fonts/ > /dev/null 2>&1
        fc-cache -f > /dev/null 2>&1
        show_progress "Copying Fonts" "Copying fonts..." 100
        log "INFO" "Fonts copied and cache updated."
    else
        log "WARNING" "No fonts found in the dotfiles repository."
        show_message "Warning" "No fonts found in the dotfiles repository."
        show_progress "Copying Fonts" "Copying fonts..." 100
    fi
}

# Function to copy icons
copy_icons() {
    log "INFO" "Copying icons..."
    show_progress "Copying Icons" "Copying icons..." 50
    if [ -d "$DESTINATION/.icons" ]; then
        sudo cp -r "$DESTINATION/.icons/"* /usr/share/icons/ > /dev/null 2>&1
        show_progress "Copying Icons" "Copying icons..." 100
        log "INFO" "Icons copied successfully."
    else
        log "WARNING" "No icons found in the dotfiles repository."
        show_message "Warning" "No icons found in the dotfiles repository."
        show_progress "Copying Icons" "Copying icons..." 100
    fi
}

# Function to copy themes
copy_themes() {
    log "INFO" "Copying themes..."
    show_progress "Copying Themes" "Copying themes..." 50
    if [ -d "$DESTINATION/.themes" ]; then
        sudo cp -r "$DESTINATION/.themes/"* /usr/share/themes/ > /dev/null 2>&1
        show_progress "Copying Themes" "Copying themes..." 100
        log "INFO" "Themes copied successfully."
    else
        log "WARNING" "No themes found in the dotfiles repository."
        show_message "Warning" "No themes found in the dotfiles repository."
        show_progress "Copying Themes" "Copying themes..." 100
    fi
}

# Function to copy GTK2 and GTK3 configurations
copy_gtk_configs() {
    log "INFO" "Copying GTK2 and GTK3 configurations..."
    show_progress "Copying GTK Configs" "Copying GTK2 and GTK3 configurations..." 50
    if [ -f "$DESTINATION/.config/gtk-3.0/settings.ini" ]; then
        sudo cp "$DESTINATION/.config/gtk-3.0/settings.ini" "$GTK3_SYSTEM_WIDE/" > /dev/null 2>&1
    fi
    if [ -f "$DESTINATION/.gtkrc-2.0" ]; then
        sudo cp "$DESTINATION/.gtkrc-2.0" "$GTK2_SYSTEM_WIDE/" > /dev/null 2>&1
    fi
    show_progress "Copying GTK Configs" "Copying GTK2 and GTK3 configurations..." 100
    log "INFO" "GTK2 and GTK3 configurations copied successfully."
}

# Function to change font across all XFCE components
change_font_all_xfce() {
    log "INFO" "Setting XFCE font..."
    show_progress "Setting XFCE Font" "Setting XFCE font..." 50
    if fc-list | grep -iq "JetBrainsMono Nerd Font"; then
        xfconf-query -c xsettings -p /Gtk/FontName -s "JetBrainsMono Nerd Font 11" > /dev/null 2>&1
        xfconf-query -c xfwm4 -p /general/title_font -s "JetBrainsMono Nerd Font Bold 11" > /dev/null 2>&1
        xfconf-query -c xsettings -p /Xft/DPI -s "96" > /dev/null 2>&1
        show_progress "Setting XFCE Font" "Setting XFCE font..." 100
        log "INFO" "Font has been set to JetBrainsMono Nerd Font."
    else
        log "ERROR" "JetBrainsMono Nerd Font not found. Please install it first."
        show_message "Error" "JetBrainsMono Nerd Font not found. Please install it first."
        show_progress "Setting XFCE Font" "Setting XFCE font..." 100
        exit 1
    fi
}

# Function for additional configurations
additional_configuration() {
    log "INFO" "Applying additional configurations..."
    show_progress "Applying Additional Configurations" "Applying additional configurations..." 50
    xdg-user-dirs-update > /dev/null 2>&1
    xdg-user-dirs-gtk-update > /dev/null 2>&1
    show_progress "Applying Additional Configurations" "Applying additional configurations..." 100
    log "INFO" "Additional configurations applied."
}

# Function to generate a summary report
generate_summary_report() {
    log "INFO" "Generating summary report..."
    local summary=""
    summary+="Configuration Setup Summary:\n"
    summary+="============================\n"
    summary+="Packages Installed: $(grep '\[INFO\] Packages installed successfully' "$LOG_FILE" | wc -l)\n"
    summary+="Repository Cloned/Updated: $(grep '\[INFO\] Repository cloned successfully\|Repository updated successfully' "$LOG_FILE" | wc -l)\n"
    summary+="Configuration Files Synchronized: $(grep '\[INFO\] Configuration files synchronized' "$LOG_FILE" | wc -l)\n"
    summary+="Fonts Copied: $(grep '\[INFO\] Fonts copied and cache updated' "$LOG_FILE" | wc -l)\n"
    summary+="Icons Copied: $(grep '\[INFO\] Icons copied successfully' "$LOG_FILE" | wc -l)\n"
    summary+="Themes Copied: $(grep '\[INFO\] Themes copied successfully' "$LOG_FILE" | wc -l)\n"
    summary+="GTK Configurations Copied: $(grep '\[INFO\] GTK2 and GTK3 configurations copied successfully' "$LOG_FILE" | wc -l)\n"
    summary+="XFCE Font Set: $(grep '\[INFO\] Font has been set to JetBrainsMono Nerd Font' "$LOG_FILE" | wc -l)\n"
    summary+="Additional Configurations Applied: $(grep '\[INFO\] Additional configurations applied' "$LOG_FILE" | wc -l)\n"
    summary+="Starship Installed: $(grep '\[INFO\] Starship installed successfully' "$LOG_FILE" | wc -l)\n"
    summary+="Skipped Steps:\n"
    summary+="--------------\n"
    summary+="Package Installation Skipped: $(grep '\[INFO\] Package installation skipped by user' "$LOG_FILE" | wc -l)\n"
    summary+="Repository Cloning/Updating Skipped: $(grep '\[INFO\] Repository cloning skipped by user\|Repository updating skipped by user' "$LOG_FILE" | wc -l)\n"
    summary+="Configuration File Synchronization Skipped: $(grep '\[INFO\] Configuration file synchronization skipped by user' "$LOG_FILE" | wc -l)\n"
    summary+="Font Copying Skipped: $(grep '\[INFO\] Font copying skipped by user' "$LOG_FILE" | wc -l)\n"
    summary+="Icon Copying Skipped: $(grep '\[INFO\] Icon copying skipped by user' "$LOG_FILE" | wc -l)\n"
    summary+="Theme Copying Skipped: $(grep '\[INFO\] Theme copying skipped by user' "$LOG_FILE" | wc -l)\n"
    summary+="GTK Configuration Copying Skipped: $(grep '\[INFO\] GTK2 and GTK3 configuration copying skipped by user' "$LOG_FILE" | wc -l)\n"
    summary+="Font Setting Skipped: $(grep '\[INFO\] Font setting skipped by user' "$LOG_FILE" | wc -l)\n"
    summary+="Starship Installation Skipped: $(grep '\[INFO\] Starship shell prompt installation skipped by user' "$LOG_FILE" | wc -l)\n"
    summary+="Additional Configurations Skipped: $(grep '\[INFO\] Additional configurations skipped by user' "$LOG_FILE" | wc -l)\n"
    summary+="\nLog File: $LOG_FILE\n"
    echo -e "$summary" > "$SUMMARY_FILE"
    log "INFO" "Summary report generated: $SUMMARY_FILE"
}

# Function to clean up temporary files and directories
cleanup() {
    log "INFO" "Cleaning up temporary files and directories..."
    rm -f "$LOG_FILE"
    log "INFO" "Temporary files and directories cleaned up."
}

# Main execution
install_dialog
log "INFO" "Starting configuration setup..."

# Display welcome message
dialog --title "Welcome" --msgbox "Welcome to the System Setup Script!\nThis script will configure your system and install necessary packages." 10 50

# User confirmation before execution
if dialog --yesno "Do you want to start the configuration setup?" 10 50; then
    # Install packages
    if dialog --yesno "Do you want to install the required packages?" 10 50; then
        install_packages
    else
        log "INFO" "Package installation skipped by user."
        show_message "Info" "Package installation skipped by user."
    fi

    # Clone or Update repository
    if dialog --yesno "Do you want to clone or update the dotfiles repository?" 10 50; then
        clone_repository
    else
        log "INFO" "Repository cloning/updating skipped by user."
        show_message "Info" "Repository cloning/updating skipped by user."
    fi

    # Sync configuration files
    if dialog --yesno "Do you want to synchronize configuration files?" 10 50; then
        sync_config_files
    else
        log "INFO" "Configuration file synchronization skipped by user."
        show_message "Info" "Configuration file synchronization skipped by user."
    fi

    # Copy fonts
    if dialog --yesno "Do you want to copy the fonts?" 10 50; then
        copy_fonts
    else
        log "INFO" "Font copying skipped by user."
        show_message "Info" "Font copying skipped by user."
    fi

    # Copy icons
    if dialog --yesno "Do you want to copy the icons?" 10 50; then
        copy_icons
    else
        log "INFO" "Icon copying skipped by user."
        show_message "Info" "Icon copying skipped by user."
    fi

    # Copy themes
    if dialog --yesno "Do you want to copy the themes?" 10 50; then
        copy_themes
    else
        log "INFO" "Theme copying skipped by user."
        show_message "Info" "Theme copying skipped by user."
    fi

    # Copy GTK2 and GTK3 configurations
    if dialog --yesno "Do you want to copy GTK2 and GTK3 configurations?" 10 50; then
        copy_gtk_configs
    else
        log "INFO" "GTK2 and GTK3 configuration copying skipped by user."
        show_message "Info" "GTK2 and GTK3 configuration copying skipped by user."
    fi

    # Change font for XFCE
    if dialog --yesno "Do you want to set the JetBrainsMono Nerd Font for XFCE?" 10 50; then
        change_font_all_xfce
    else
        log "INFO" "Font setting skipped by user."
        show_message "Info" "Font setting skipped by user."
    fi

    # Install Starship shell prompt
    if dialog --yesno "Do you want to install Starship shell prompt?" 10 50; then
        starship_shell_install
    else
        log "INFO" "Starship shell prompt installation skipped by user."
        show_message "Info" "Starship shell prompt installation skipped by user."
    fi

    # Apply additional configurations
    if dialog --yesno "Do you want to apply additional configurations?" 10 50; then
        additional_configuration
    else
        log "INFO" "Additional configurations skipped by user."
        show_message "Info" "Additional configurations skipped by user."
    fi

    # Generate summary report
    generate_summary_report

    # Display completion message
    dialog --title "Completion" --msgbox "Configuration setup completed successfully!\nSummary report generated: $SUMMARY_FILE" 10 50
    log "INFO" "Configuration setup completed successfully."

    # Cleanup
    cleanup
else
    log "INFO" "Setup aborted by user."
    show_message "Aborted" "Setup aborted by user."
    cleanup
fi
