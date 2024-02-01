#!/bin/bash

pipewire_conf_dir="/etc/pipewire/pipewire.conf.d"
pipewire_conf_link="/usr/share/examples/wireplumber/10-wireplumber.conf"

# Function to check if a symbolic link exists
check_symlink() {
    [ -L "$1" ]
}

# Function for audio setup
setup_audio() {
    if ! check_symlink "$pipewire_conf_dir/10-wireplumber.conf"; then
        sudo mkdir -p "$pipewire_conf_dir" &&
        sudo ln -s "$pipewire_conf_link" "$pipewire_conf_dir/" &&
        echo "Audio setup completed."
    else
        echo "Audio setup already exists. Skipping."
    fi
}

setup_audio
