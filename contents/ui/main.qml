/*
    Fan Stack

    A folder on the panel. Clicking it fans the folder's newest entries out in
    an arc above the icon, the way a macOS Dock stack does. The popup is a
    background-less PlasmaCore.Dialog so only the icons and their labels are
    drawn; the arc geometry and the open/close animation live in FanPopup.qml
    and FanItem.qml.

    The folder listing comes from the same FolderModel the stock Folder View
    uses (org.kde.private.desktopcontainment.folder), so sorting, hidden files
    and thumbnails behave exactly like Folder View. A proxy model trims the
    sorted list to the first N rows; the last fan entry always opens the folder
    in the file manager and says how many more files there are.
*/
import QtCore
import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels
import org.kde.private.desktopcontainment.folder as Folder

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    readonly property bool horizontal: Plasmoid.formFactor !== PlasmaCore.Types.Vertical
    readonly property string folderUrl: Plasmoid.configuration.url.length > 0
        ? Plasmoid.configuration.url
        : StandardPaths.writableLocation(StandardPaths.DownloadLocation).toString()
    readonly property string folderName: {
        const trimmed = folderUrl.replace(/\/+$/, "");
        return decodeURIComponent(trimmed.substring(trimmed.lastIndexOf("/") + 1)) || folderUrl;
    }
    readonly property int fanLimit: Math.max(1, Plasmoid.configuration.fanLimit)
    readonly property string iconName: Plasmoid.configuration.icon || folderModel.iconName || "folder"
    property int totalCount: 0

    // Set by the panel representation once it exists; the popup anchors to them.
    property Item dockIconItem: null
    property Item anchorItem: null

    toolTipMainText: folderName
    toolTipSubText: totalCount === 1 ? i18n("1 item") : i18n("%1 items", totalCount)
    Plasmoid.icon: iconName
    // Keeps an auto-hiding panel on screen while the fan is open.
    Plasmoid.status: fanPopup.open ? PlasmaCore.Types.RequiresAttentionStatus : PlasmaCore.Types.ActiveStatus

    function refreshCount() {
        totalCount = folderModel.rowCount();
        fanModel.invalidateFilter();
    }

    function toggle() {
        if (fanPopup.open) {
            fanPopup.closeFan();
        } else if (Date.now() - fanPopup.lastCloseAt > 300) {
            // A click on the icon while the fan is open first deactivates the
            // popup (which closes it) and only then lands here: don't reopen.
            fanPopup.openFan();
        }
    }

    Folder.FolderModel {
        id: folderModel
        url: root.folderUrl
        sortMode: Plasmoid.configuration.sortMode
        sortDesc: Plasmoid.configuration.sortDesc
        sortDirsFirst: Plasmoid.configuration.sortDirsFirst
        showHiddenFiles: Plasmoid.configuration.showHiddenFiles
        previews: Plasmoid.configuration.previews
        // Must be set explicitly: FolderModel's effective plugin list starts
        // out empty, and an empty list here makes it fall back to the system
        // default thumbnailers (the ones Dolphin uses).
        previewPlugins: []
        viewAdapter: viewAdapter
        onListingCompleted: root.refreshCount()
        onRowsInserted: root.refreshCount()
        onRowsRemoved: root.refreshCount()
        onModelReset: root.refreshCount()
        onLayoutChanged: root.refreshCount()
    }

    // FolderModel only creates its thumbnail generator once it has a view adapter.
    Folder.ItemViewAdapter {
        id: viewAdapter
        adapterView: fanPopup.mainItem
        adapterModel: folderModel
        adapterIconSize: Plasmoid.configuration.fanIconSize
        adapterVisibleArea: Qt.rect(0, 0, 10000, 10000)
    }

    // Only the first fanLimit rows of the sorted folder reach the fan. The
    // callback is rebuilt (and the filter re-run) whenever the limit changes;
    // refreshCount() re-runs it when rows shift.
    KItemModels.KSortFilterProxyModel {
        id: fanModel
        sourceModel: folderModel
        filterRowCallback: {
            const limit = root.fanLimit;
            return function (sourceRow, sourceParent) { return sourceRow < limit; };
        }
        onFilterRowCallbackChanged: invalidateFilter()
    }

    FanPopup {
        id: fanPopup
        dockIcon: root.dockIconItem
        visualParent: root.anchorItem
        fanModel: fanModel
        totalCount: root.totalCount
        folderUrl: root.folderUrl
        folderIcon: root.iconName
    }

    fullRepresentation: Item {
        id: rep

        Layout.minimumWidth: root.horizontal ? rep.height : 0
        Layout.preferredWidth: root.horizontal ? rep.height : -1
        Layout.maximumWidth: root.horizontal ? rep.height : Number.POSITIVE_INFINITY
        Layout.minimumHeight: root.horizontal ? 0 : rep.width
        Layout.preferredHeight: root.horizontal ? -1 : rep.width
        Layout.maximumHeight: root.horizontal ? Number.POSITIVE_INFINITY : rep.width

        Kirigami.Icon {
            id: dockIcon
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height)
            height: width
            source: root.iconName
            active: hover.hovered || fanPopup.open
            scale: leftTap.pressed ? 0.9 : 1
            Behavior on scale {
                NumberAnimation { duration: Kirigami.Units.shortDuration }
            }

            // Dialog centres its popup on visualParent. This 1px item is slid
            // along the icon so that the popup's arc origin lands exactly on
            // the icon's centre, whichever way the fan curves.
            Item {
                id: popupAnchor
                width: 1
                height: dockIcon.height
                x: dockIcon.width / 2 - fanPopup.originX + fanPopup.contentWidth / 2
            }
        }

        HoverHandler {
            id: hover
        }
        TapHandler {
            id: leftTap
            acceptedButtons: Qt.LeftButton
            onTapped: root.toggle()
        }
        TapHandler {
            acceptedButtons: Qt.MiddleButton
            onTapped: Qt.openUrlExternally(root.folderUrl)
        }

        // Dropping files on the icon moves/copies them into the folder.
        DropArea {
            anchors.fill: parent
            onDropped: drop => {
                if (drop.hasUrls) {
                    folderModel.dropCwd(drop);
                }
            }
        }

        Component.onCompleted: {
            root.dockIconItem = dockIcon;
            root.anchorItem = popupAnchor;
        }
    }
}
