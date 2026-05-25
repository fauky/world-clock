#!/bin/bash

# This script disables the framebuffer blanking and starts the World Clock service.

# This script must be run as root. Re-running with sudo
if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

# Disable framebuffer blanking
echo 0 > /sys/class/graphics/fb0/blank

# Start the World Clock service
systemctl start world-clock.service
