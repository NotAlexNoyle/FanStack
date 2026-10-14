/*
    The fan itself: a frameless, background-less dialog that sits on top of
    the panel icon. Every entry is a FanItem whose position is a point on a
    circular arc; the arc's centre lies to the side of the dock icon, so the
    entries climb and curve away from the panel like a Dock stack.

    All coordinates are in popup space. The origin (centre of the dock icon)
    sits just below the popup's bottom edge, since the dialog is placed flush
    against the top of the icon.
*/
import QtQuick

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmaCore.Dialog {
    id: dialog

    property Item dockIcon: null
    property var fanModel: null
    property int totalCount: 0
    property string folderUrl: ""
    property string folderIcon: "folder"

    // true from the start of the open animation until the close starts
    property bool open: false
    property bool closing: false
    property double lastCloseAt: 0
    // +1 curves to the right, -1 to the left; chosen every time the fan opens
    property int direction: 1

    signal openStarted()
    signal closeStarted()
    signal itemsReset()

    // ---- geometry ----
    readonly property int iconSize: Plasmoid.configuration.fanIconSize
    readonly property int gap: Math.round(iconSize * 0.35)
    readonly property int step: iconSize + gap
    readonly property bool newestAtTop: Plasmoid.configuration.newestAtTop
    // The arc leaves the dock icon vertically and curls over with a fixed
    // radius, like the Dock's fan: a short fan is simply the bottom of the
    // same curve. Above ~60° of tilt a label, which sits beside its icon
    // towards the inside of the curve, would run into the icon above it even
    // with the small downward label offset, so the radius only grows beyond
    // the configured one when a very large fan would pass that.
    readonly property real fixedRadius: step * Math.max(4, Math.min(60, Plasmoid.configuration.fanRadius))
    readonly property real maxTangent: 60 * Math.PI / 180
    readonly property int labelDrop: Math.round(iconSize / 6)
    readonly property int labelGap: Math.round(iconSize * 0.25)
    readonly property int labelMaxWidth: iconSize * 5
    readonly property int margin: Kirigami.Units.largeSpacing * 2
    readonly property real dockHalf: dockIcon ? dockIcon.height / 2 : 0
    readonly property real firstDistance: dockHalf + iconSize * 0.75
    readonly property int itemCount: fanRepeater.count + 1
    readonly property real arcLength: firstDistance + (itemCount - 1) * step
    readonly property real arcRadius: Math.max(fixedRadius, arcLength / maxTangent)
    readonly property real maxAngle: angleFor(itemCount - 1)
    readonly property real arcWidth: arcRadius * (1 - Math.cos(maxAngle))
    readonly property real arcHeight: arcRadius * Math.sin(maxAngle)
    readonly property int contentWidth: Math.ceil(margin * 2 + iconSize + arcWidth + labelGap + labelMaxWidth)
    readonly property int contentHeight: Math.ceil(margin + iconSize / 2 + arcHeight - dockHalf)
    readonly property real originX: direction > 0 ? margin + iconSize / 2 : contentWidth - margin - iconSize / 2
    readonly property real originY: contentHeight + dockHalf

    // ---- timing (honours the global animation speed) ----
    readonly property int duration: Math.round(Plasmoid.configuration.animationDuration * Kirigami.Units.longDuration / 200)
    readonly property int stagger: Math.round(duration * 0.08)
    readonly property int closeDuration: Math.round(duration * 0.7)

    // Angle (radians) of entry i around the arc's centre; the origin is at 0.
    function angleFor(i) {
        return (firstDistance + i * step) / arcRadius;
    }

    function pickDirection() {
        const wanted = Plasmoid.configuration.direction;
        if (wanted === 1) {
            return 1;
        }
        if (wanted === 2) {
            return -1;
        }
        if (!dockIcon) {
            return 1;
        }
        const centre = dockIcon.mapToGlobal(dockIcon.width / 2, 0);
        const screen = Plasmoid.containment.screenGeometry;
        const reach = contentWidth - margin - iconSize / 2;
        const fitsRight = centre.x + reach <= screen.x + screen.width;
        const fitsLeft = centre.x - reach >= screen.x;
        return (!fitsRight && fitsLeft) ? -1 : 1;
    }

    function openFan() {
        if (open) {
            return;
        }
        closeTimer.stop();
        itemsReset();
        direction = pickDirection();
        closing = false;
        open = true;
        visible = true;
        requestActivate();
        Qt.callLater(openStarted);
    }

    function closeFan() {
        if (!open || closing) {
            return;
        }
        open = false;
        closing = true;
        lastCloseAt = Date.now();
        closeStarted();
        closeTimer.restart();
    }

    location: Plasmoid.location
    type: PlasmaCore.Dialog.PopupMenu
    flags: Qt.WindowStaysOnTopHint
    backgroundHints: PlasmaCore.Dialog.NoBackground
    hideOnWindowDeactivate: false
    visible: false

    // Clicking anywhere else closes the fan, but with the animation.
    onActiveChanged: {
        if (!active && open) {
            closeFan();
        }
    }

    onVisibleChanged: {
        if (!visible) {
            closeTimer.stop();
            if (open || closing) {
                lastCloseAt = Date.now();
            }
            open = false;
            closing = false;
            itemsReset();
        }
    }

    mainItem: Item {
        id: content
        width: dialog.contentWidth
        height: dialog.contentHeight
        focus: true
        Keys.onEscapePressed: dialog.closeFan()

        // Lives here because anything declared directly under the Dialog
        // would be taken as its mainItem.
        Timer {
            id: closeTimer
            interval: (dialog.itemCount - 1) * dialog.stagger + dialog.closeDuration + 40
            onTriggered: dialog.visible = false
        }

        // Clicks on empty space close the fan, like the Dock does.
        MouseArea {
            anchors.fill: parent
            onClicked: dialog.closeFan()
        }

        Repeater {
            id: fanRepeater
            model: dialog.fanModel
            delegate: FanItem {
                // FanItem has required properties, so the usual context
                // injection of model/index is off and we must ask for them.
                required property int index
                required property var model

                fan: dialog
                fanIndex: dialog.newestAtTop ? fanRepeater.count - index : index
                iconSource: model.decoration
                // display is briefly undefined while a row is being removed
                label: model.display ?? ""
                onActivated: {
                    const target = model.url;
                    dialog.closeFan();
                    Qt.openUrlExternally(target);
                }
            }
        }

        FanItem {
            fan: dialog
            fanIndex: dialog.newestAtTop ? 0 : fanRepeater.count
            iconSource: dialog.folderIcon
            emphasised: true
            label: {
                const more = dialog.totalCount - fanRepeater.count;
                return more > 0 ? i18n("%1 more…", more) : i18n("Open folder…");
            }
            onActivated: {
                dialog.closeFan();
                Qt.openUrlExternally(dialog.folderUrl);
            }
        }
    }
}
