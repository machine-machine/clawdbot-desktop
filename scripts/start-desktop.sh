#!/bin/bash

# Wait for X server to be fully active
# Increased wait time slightly for Xorg warm-up
for i in $(seq 1 10);
do
    if xdpyinfo -display :0 &>/dev/null;
then
        break
    fi
    echo "Waiting for X server..."
    sleep 1
done

export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp/runtime-developer
# Ensure dbus is available for theme switching
export DBUS_SESSION_BUS_ADDRESS=$(dbus-launch --sh-syntax | grep DBUS_SESSION_BUS_ADDRESS | cut -d= -f2- | tr -d "'")

# =============================================================================
# XFCE4 Modernization Settings
# =============================================================================
# CHANGE: ENABLE COMPOSITING (Crucial for modern feel)
xfconf-query -c xfwm4 -p /general/use_compositing -s true 2>/dev/null || true

# Enable shadows for dock styling
xfconf-query -c xfwm4 -p /general/show_dock_shadow -s true 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/show_frame_shadow -s true 2>/dev/null || true

# Set slightly larger, modern cursor size
xfconf-query -c xsettings -p /Gtk/CursorThemeSize -s 32 2>/dev/null || true

# ... (Theme settings remain the same)
xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-Dark" 2>/dev/null || true
# ...

# Set wallpaper
if [ -f ~/.local/share/backgrounds/wallpaper.png ]; then
    # Ensure xfdesktop is running before trying to set property
    xfdesktop & sleep 2
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorscreen/workspace0/last-image \
        -s ~/.local/share/backgrounds/wallpaper.png 2>/dev/null || true
fi

# Start Plank dock (add slight delay to ensure compositor is ready)
sleep 2 && plank &

# Start XFCE4 session
exec startxfce4