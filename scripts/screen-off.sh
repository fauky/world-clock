#!/bin/bash

# This script stops the World Clock service and blanks the screen.

# This script must be run as root. Re-running with sudo
if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

systemctl stop world-clock.service

# Blank the screen
# This does not turn off the backlight, but it will blank the display.
echo 1 > /sys/class/graphics/fb0/blank
