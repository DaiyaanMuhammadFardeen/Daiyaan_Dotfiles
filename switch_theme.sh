#!/bin/bash
# KDE Plasma Auto Theme Switcher
# Requires: redshift or manual lat/long setup

# Get your location (replace with your city coords if redshift not used)
LAT="23.8103"   # Example: Dhaka
LON="90.4125"

# Get current time
CURRENT=$(date +%s)

# Get sunrise/sunset from redshift (fallback: hardcode times)
SUNRISE=$(redshift -l $LAT:$LON -p 2>/dev/null | grep "Solar elevation" -A1 | grep rise | awk '{print $2}')
SUNSET=$(redshift -l $LAT:$LON -p 2>/dev/null | grep "Solar elevation" -A1 | grep set | awk '{print $2}')

# Fallback if parsing fails: use static times
[ -z "$SUNRISE" ] && SUNRISE=$(date -d "06:00" +%s)
[ -z "$SUNSET" ] && SUNSET=$(date -d "18:00" +%s)

# Convert sunrise/sunset to timestamps
SUNRISE_TS=$(date -d "$SUNRISE" +%s)
SUNSET_TS=$(date -d "$SUNSET" +%s)

# Switch themes
if [ "$CURRENT" -ge "$SUNRISE_TS" ] && [ "$CURRENT" -lt "$SUNSET_TS" ]; then
    # Daytime → Breeze Light
    lookandfeeltool -a org.kde.breezelight.desktop
else
    # Nighttime → Breeze Dark
    lookandfeeltool -a org.kde.breezedark.desktop
fi
