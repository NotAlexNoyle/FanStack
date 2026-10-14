# Fan Stack

A folder widget for the KDE Plasma 6 panel that fans its newest files out in
an arc above the icon, the way a macOS Dock stack does.

Click the icon and the folder's newest entries unroll along a curve, each
with a thumbnail (or file type icon) and a label. Click an entry to open it,
click the last entry to open the folder itself, click anywhere else (or press
Escape) to fold the fan back into the icon.

## Features

- Animated fan that unrolls from the panel icon and folds back on close.
  The whole thing honours the system-wide animation speed setting.
- Newest files first (or any other Folder View sort order), with a
  "N more…" entry that opens the folder in your file manager.
- Thumbnails for images, PDFs, videos and whatever else your thumbnailers
  cover, using the same preview plugins as Dolphin.
- Curves to the right, or to the left when the arc would not fit on screen.
- Configurable lean angle, number of entries, icon size, animation length,
  folder, panel icon, sort order, hidden files.
- Middle-click the panel icon to open the folder. Drop files on it to move
  them into the folder.

## Requirements

- KDE Plasma 6 (developed and tested on 6.7, Wayland).
- `plasma-desktop` (provides the Folder View model the widget reuses),
  `kitemmodels`, and Qt 6.5+ (for `QtQuick.Effects`). All of these are part
  of a normal Plasma installation.

## Install

```sh
./install.sh
```

or, by hand:

```sh
kpackagetool6 --type Plasma/Applet --install .     # first time
kpackagetool6 --type Plasma/Applet --upgrade .     # later versions
```

Then right-click a panel, choose *Add Widgets…*, and drag **Fan Stack** onto
the panel. By default it shows your Downloads folder; right-click the icon
and choose *Configure…* to change the folder, icon and the rest.

## Settings

| Setting | Default | Meaning |
| --- | --- | --- |
| Folder | Downloads | Folder to fan out |
| Icon | `folder-download` | Icon shown on the panel |
| Files shown in the fan | 8 | Entries before the "N more…" item |
| Fan icon size | 48 px | Icon size inside the fan |
| Fan lean at the top | 38° | How far the top entry tilts from vertical; the arc starts vertical at the icon |
| Fan curves | Away from the screen edge | Force right or left if you prefer |
| Animation length | 350 ms | Scaled by the global animation speed |
| Sort by / Descending / Folders first | Date, descending | Same options as Folder View |
| First file at the top | on | Otherwise the newest file sits nearest the panel |
| Show thumbnails | on | Uses the system preview plugins |
| Show hidden files | off | |

## Hacking

The widget is plain QML, no build step. After editing an installed copy,
reload Plasma's QML without restarting it:

```sh
qdbus org.kde.plasmashell /PlasmaShell refreshCurrentShell
```

For development you can symlink the checkout into place instead of
installing it:

```sh
ln -s "$PWD" ~/.local/share/plasma/plasmoids/com.notalexnoyle.fanstack
```

Layout:

- `contents/ui/main.qml` – panel icon, folder model, proxy that trims the list
- `contents/ui/FanPopup.qml` – the frameless popup and the arc geometry
- `contents/ui/FanItem.qml` – one entry: icon, label, open/close animation
- `contents/ui/configGeneral.qml`, `contents/config/main.xml` – settings

The arc is a circle that leaves the panel icon vertically. Its radius grows
with the number of entries so that the top entry tilts exactly as far as the
configured lean, capped at 60° to keep each label clear of the icon above.

## License

GPL-2.0-or-later. See `LICENSE`.
