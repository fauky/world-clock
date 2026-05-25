#!/bin/bash

# Check if script is run as root, automatically re-run with sudo if not
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Re-running with sudo..."
    exec sudo "$0" "$@"
fi

# Dynamically determine the user running the script and use that for the systemd service configuration
if [ -n "$SUDO_USER" ]; then
    USERNAME="$SUDO_USER"
else
    echo "Unable to determine the non-root user. Please run this script with sudo from a regular user account."
    exit 1
fi

# Detemine the script directory to use for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Fix Raspbery Pi Configuration
# Update cmdline.txt to disable cursor
# /boot/firmware/cmdline.txt; add vt.global_cursor_default=0 to the end of the line, after rootwait
CMDLINE_FILE="/boot/firmware/cmdline.txt"
if ! grep -q "vt.global_cursor_default=0" "$CMDLINE_FILE"; then
    echo "Updating $CMDLINE_FILE to disable cursor..."
    sed -i 's/\(rootwait\)/\1 vt.global_cursor_default=0/' "$CMDLINE_FILE"
else
    echo "$CMDLINE_FILE already contains vt.global_cursor_default=0, skipping update."
fi

# Update config.txt to set display settings.
# Disable DRM VC4 V3D driver, enable TV out, set TV mode to NTSC, force 16:9 aspect ratio, set framebuffer size, and disable overscan compensation.
CONFIG_FILE="/boot/firmware/config.txt"

if ! grep -q "enable_tvout=1" "$CONFIG_FILE"; then
    echo "Updating $CONFIG_FILE with TV out settings..."

    sed -i 's/^dtoverlay=vc4-kms-v3d/#&/' "$CONFIG_FILE"
    sed -i 's/^max_framebuffers=/#&/' "$CONFIG_FILE"
    # Comment out any existing overscan settings to prevent conflicts
    sed -i 's/^\(overscan_[a-z]*=\)/#&/g' "$CONFIG_FILE"

    cat << 'EOF' >> "$CONFIG_FILE"

[all]
# Enable Composite RCA
enable_tvout=1

# Set to PAL, Possible Values: 0: NTSC, 2: PAL
sdtv_mode=2

# Force 16:9 Aspect Ratio, Possible values: 1 (4:3), 2 (14:9), 3 (16:9)
sdtv_aspect=3

# Force the rendering resolution to match the physical LCD panel
framebuffer_width=480
framebuffer_height=272

# Tell the GPU the physical display size (aspect ratio hint)
display_default_lcd=1

# Disable compensation for displays with overscan
disable_overscan=0

overscan_left=0
overscan_right=-20
overscan_top=-20
overscan_bottom=-20

gpu_mem=128
EOF
else
    echo "Settings already exist in $CONFIG_FILE, skipping update."
fi

# Install dependencies
# Check if fc-list, wget is installed, if not, install fontconfig
if ! command -v fc-list &> /dev/null || ! command -v wget &> /dev/null; then
    echo "Some dependencies not found, installing..."
    apt update && apt install -y fontconfig wget
else
    echo "Dependencies are already installed, skipping installation."
fi

# Install fonts-hosny-amiri for Arabic text support
if ! dpkg -l | grep -q "fonts-hosny-amiri"; then
    echo "Installing fonts-hosny-amiri for Arabic text support..."
    apt update && apt install -y fonts-hosny-amiri
else
    echo "fonts-hosny-amiri is already installed, skipping installation."
fi
# Install Share Tech Mono font for digital clock display
if ! fc-list | grep -q "Share Tech Mono"; then
    echo "Installing Share Tech Mono font for digital clock display..."
    mkdir -p /usr/share/fonts/share-tech-mono
    wget -q https://raw.githubusercontent.com/google/fonts/main/ofl/sharetechmono/ShareTechMono-Regular.ttf -O /usr/share/fonts/share-tech-mono/ShareTechMono-Regular.ttf
    fc-cache -fv
else
    echo "fonts-sharetechmono is already installed, skipping installation."
fi

# Check if qmake is installed, if not, install qt5
if ! command -v qmake &> /dev/null; then
    echo "qmake not found, installing qt5..."
    apt update
    apt install -y \
        build-essential \
        qt5-qmake \
        qtbase5-dev \
        qtdeclarative5-dev \
        qtquickcontrols2-5-dev \
        qml-module-qtquick2 \
        qml-module-qtquick-controls2 \
        qml-module-qtquick-layouts \
        qml-module-qtgraphicaleffects \
        qml-module-qtquick-window2
else
    echo "qmake is already installed, skipping installation."
fi


# Build clock
# Create build and bin directories if they don't exist
BUILD_DIR="build"
BIN_DIR="bin"
sudo -u "$USERNAME" mkdir -p "$BUILD_DIR" "$BIN_DIR"

# Run qmake and make in the build directory as the non-root user
cd "$BUILD_DIR"
sudo -u "$USERNAME" qmake ../world-clock.pro
sudo -u "$USERNAME" make -j4
cd ..

# Move the final binary to the bin directory for deployment
if [ -f "$BUILD_DIR/world-clock" ]; then
    sudo -u "$USERNAME" mv -f "$BUILD_DIR/world-clock" "$BIN_DIR/"
fi

# Copy config file to /etc/world-clock/clock.conf if it doesn't exist
if [ ! -f "/etc/world-clock/clock.conf" ]; then
    mkdir -p "/etc/world-clock"
    cp "config/clock.conf" "/etc/world-clock/clock.conf"
    chown -R "$USERNAME":"$USERNAME" "/etc/world-clock"
fi

# Create systemd service if it doesn't exist
SERVICE_FILE="/etc/systemd/system/world-clock.service"
if [ ! -f "$SERVICE_FILE" ]; then
    echo "Creating systemd service for World Clock..."
    cat << EOF > "$SERVICE_FILE"
[Unit]
Description=World Clock
After=multi-user.target

[Service]
Type=simple
User=$USERNAME
Environment="QT_QPA_PLATFORM=linuxfb:fb=/dev/fb0"
Environment="QT_QPA_FONTDIR=/usr/share/fonts"
Environment="HOME=/home/$USERNAME"
ExecStart=$SCRIPT_DIR/bin/world-clock
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
else
    echo "Systemd service already exists, skipping creation."
fi

systemctl enable --now world-clock.service

# Check if the service is running
if systemctl is-active --quiet world-clock.service; then
    echo "World Clock service is running."
else
    echo "Failed to start World Clock service."
    exit 1
fi

# Set up cron jobs to turn the screen on at 5:00 AM and off at 11:00 PM
# Ask user if they want to set up the cron jobs for screen on/off
CRON_ON="0 5 * * * $SCRIPT_DIR/scripts/screen-on.sh"
CRON_OFF="0 23 * * * $SCRIPT_DIR/scripts/screen-off.sh"
read -p "Do you want to set up cron jobs to turn the screen on at 5:00 AM and off at 11:00 PM? (y/n) " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Setting up cron jobs for screen on/off..."
    chmod +x $SCRIPT_DIR/scripts/*.sh
    # Remove any existing lines for these scripts to avoid duplicates
    (crontab -l 2>/dev/null | grep -v "$SCRIPT_DIR/scripts/screen-on.sh" | \
        grep -v "$SCRIPT_DIR/scripts/screen-off.sh"; echo "$CRON_ON"; echo "$CRON_OFF") | crontab -
    echo "Cron jobs for screen on/off have been created."
else
    echo "Skipping cron job setup. You can set up the cron jobs manually later if you wish."
fi

# Reboot the system to apply changes
# Check if the framebuffer device exists before prompting for reboot
if [ -c /dev/fb0 ]; then
    echo "Framebuffer device found. Changes should be applied."
else
    echo "Framebuffer device not found. A reboot is required to apply changes."

    read -p "Do you want to reboot now? (y/n) " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Rebooting now..."
        reboot
    else
        echo "Please remember to reboot the system as soon as possible to apply all changes."
    fi
fi
