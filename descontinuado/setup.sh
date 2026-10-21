#!/bin/sh
# Puts the tray in the panel where COSMIC's tray is.
#   ./setup.sh          -> use the tray
#   ./setup.sh --undo   -> back to COSMIC's tray
set -e
cfg="${XDG_CONFIG_HOME:-$HOME/.config}/cosmic/com.system76.CosmicPanel.Panel/v1"
ours=io.github.Aenes0.CosmicTray
theirs=com.system76.CosmicAppletStatusArea

for f in "$cfg/plugins_center" "$cfg/plugins_wings"; do
    [ -f "$f" ] || continue
    if [ "$1" = "--undo" ]; then
        sed -i "s|\"$ours\"|\"$theirs\"|" "$f"
    else
        sed -i "s|\"$theirs\"|\"$ours\"|" "$f"
    fi
done
if [ "$1" = "--undo" ]; then
    echo "COSMIC's tray is back in the panel."
elif grep -qs "\"$ours\"" "$cfg/plugins_center" "$cfg/plugins_wings"; then
    echo "Tray set in the panel."
else
    echo "No tray in the panel: add \"Tray\" in Settings > Desktop > Panel > Applets."
fi
