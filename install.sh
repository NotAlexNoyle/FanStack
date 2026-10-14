#!/bin/sh
# Installs the widget for the current user, or upgrades it if it is already
# installed. Run from anywhere; the package is this directory.
set -e
cd "$(dirname "$0")"
id=$(sed -n 's/.*"Id": *"\([^"]*\)".*/\1/p' metadata.json)
if kpackagetool6 --type Plasma/Applet --list 2>/dev/null | grep -q "^$id\$"; then
    kpackagetool6 --type Plasma/Applet --upgrade .
    echo "Upgraded $id. Reload the shell to pick up the new version:"
    echo "  qdbus org.kde.plasmashell /PlasmaShell refreshCurrentShell"
else
    kpackagetool6 --type Plasma/Applet --install .
    echo "Installed $id. Add it to a panel with 'Add Widgets…' (search for Fan Stack)."
fi
