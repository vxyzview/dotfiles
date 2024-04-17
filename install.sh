#!/bin/bash
#
# Script to setup system configurations and install packages based on Linux distribution

set -euo pipefail

# Configuration
readonly gtk2_system_wide="/etc/gtk-2.0"
readonly gtk3_system_wide="/etc/gtk-3.0"
readonly repository="https://github.com/pyranix/dotfiles"
readonly destination="$HOME/dotfiles"

# Function to check if a directory or file exists
check_existence() {
    [[ -e "$1" ]]
}

# Function to install packages based on distribution
install_packages() {
    if command -v xbps-install &>/dev/null; then
        sudo xbps-install -Sy \
            xclip powertop xfce4-notifyd pulseaudio bluez blueman \
            rofi pamixer NetworkManager alacritty git curl neovim \
            xfce4-settings qtile xorg-minimal xorg-input-drivers \
            xorg-fonts xorg-video-drivers xorg-server xorg xsettingsd \
            dconf-editor dconf rsync vsv wget aria2 dunst python3 \
            feh gtk+ gtk+3 gtk4 nano xinit xsetroot dbus elogind \
            gcc gcc-multilib thunar-volman thunar-archive-plugin \
            thunar-media-tags-plugin pipewire pavucontrol starship \
            psutils acpi acpica-utils acpid dhcpcd-gtk ImageMagick \
            pfetch htop exa openssh openssl xdg-user-dirs xdg-user-dirs-gtk \
            picom gnupg2 mpv nwg-launchers nwg-look linux-firmware-intel \
            intel-gmmlib intel-gpu-tools intel-media-driver intel-ucode \
            intel-video-accel vulkan-loader android-file-transfer-linux \
            android-tools android-udev-rules libvirt libvirt-glib \
            libvirt-python3 gvfs udiskie udisks2 brightnessctl xdotool \
            apparmor libselinux rpm rpmextract lxappearance \
            lxappearance-obconf xfce4-power-manager xfce-polkit \
            polkit-elogind maim viewnior nodeenv nodejs xdg-desktop-portal \
            xdg-desktop-portal-kde xdg-desktop-portal-wlr \
            xdg-desktop-portal-gnome xdg-desktop-portal-gtk xdg-user-dirs \
            xdg-user-dirs-gtk xdg-utils gedit zip unzip tar 7zip \
            7zip-unrar bzip2 zstd lz4 lz4jsoncat xz libXft-devel \
            libXinerama-devel make virt-manager virt-manager-tools fish \
            pasystray network-manager-applet void-repo-nonfree \
            void-repo-multilib void-repo-multilib-nonfree
        echo "Packages installed successfully on Void Linux."
    elif command -v pacman &>/dev/null; then
        yay -S --noconfirm \
            plymouth schedtool modprobe-db update-grub xclip powertop \
            libnotify xfce4-notifyd bluez bluez-plugins bluez-cups cups \
            blueman rofi networkmanager alacritty git curl neovim \
            xfce4-settings qtile xorg-xinput xorg-drivers xorg-fonts \
            xorg-xvidtune xorg-server xorg xsettingsd dconf dconf-editor \
            rsync wget aria2 dunst python feh gtk3 gtk4 gtk2 nano \
            xorg-xinit xorg-xsetroot gcc thunar thunar-archive-plugin \
            thunar-media-tags-plugin thunar-volman pavucontrol \
            psutils python-psutil acpi acpica acpid imagemagick htop \
            exa fzf expac openssh openssl xdg-desktop-portal \
            xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
            xdg-desktop-portal-xapp xdg-user-dirs xdg-user-dirs-gtk \
            xdg-utils picom gnupg mpv linux-firmware intel-media-driver \
            intel-gmmlib intel-gpu-tools intel-ucode intel-media-sdk \
            xf86-input-libinput xf86-input-synaptics xf86-video-intel \
            xf86-video-fbdev xf86-video-vesa xf86-input-evdev \
            vulkan-intel vulkan-icd-loader vulkan-mesa-layers \
            vulkan-tools vulkan-utility-libraries vulkan-virtio \
            vulkan-validation-layers lib32-vulkan-icd-loader \
            lib32-vulkan-intel lib32-vulkan-mesa-layers \
            lib32-vulkan-validation-layers lib32-vulkan-virtio \
            android-file-transfer android-tools android-udev gvfs \
            gvfs-afc gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp \
            gvfs-nfs gvfs-smb udiskie udisks2 brightnessctl polkit \
            xdotool apparmor lxappearance lxappearance-obconf \
            xfce4-power-manager maim viewnior nodejs gedit \
            gedit-plugins zip unzip tar p7zip unrar bzip2 zstd \
            lz4 xz libxft libxinerama make cmake fish pasystray \
            network-manager-applet gamescope gamemode jq
        echo "Packages installed successfully on Arch Linux."
    else
        echo "Package installation not supported on this distribution."
    fi
}

# Function to clone repository if not already present
clone_repository() {
    check_existence "$destination" && echo "Repository already cloned. Skipping." || \
        (git clone "$repository" "$destination" && echo "Repository cloned successfully.") || \
        { echo "Error: Git clone failed."; exit 1; }
}

# Function to sync configuration files
sync_config_files() {
    rsync -a --exclude=".git*" --exclude="install.sh" --exclude=".scripts*" --exclude="README.md" "$destination/" "$HOME"
}

# Function to install Starship shell prompt
starship_shell_install() {
    curl -fsSL https://starship.rs/install.sh | bash
}

# Function for additional configurations
additional_configuration() {
    # Update font cache
    fc-cache -f

    # Copy icons, themes, and fonts
    sudo cp -r "$destination/.icons/"* /usr/share/icons/
    sudo cp -r "$destination/.themes/"* /usr/share/themes/
    sudo cp -r "$destination/.fonts/"* /usr/share/fonts/

    # Copy GTK settings
    sudo cp "$destination/.config/gtk-3.0/settings.ini" "$gtk3_system_wide/"
    sudo cp "$destination/.gtkrc-2.0" "$gtk2_system_wide/"

    # Update user directories
    xdg-user-dirs-update
    xdg-user-dirs-gtk-update
}

restart_qtile() {
    qtile cmd-obj -o cmd -f restart
}

# Main execution
install_packages
clone_repository
sync_config_files
starship_shell_install
additional_configuration
restart_qtile

echo "Configuration setup completed."
