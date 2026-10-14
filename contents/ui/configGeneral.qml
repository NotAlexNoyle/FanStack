import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs as QtDialogs

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.iconthemes as KIconThemes

KCM.SimpleKCM {
    id: page

    property string cfg_url
    property string cfg_icon
    property alias cfg_fanLimit: fanLimitSpin.value
    property alias cfg_fanIconSize: iconSizeSpin.value
    property int cfg_direction
    property alias cfg_newestAtTop: newestAtTopCheck.checked
    property alias cfg_fanLean: leanSpin.value
    property alias cfg_previews: previewsCheck.checked
    property alias cfg_showHiddenFiles: hiddenCheck.checked
    property int cfg_sortMode
    property alias cfg_sortDesc: sortDescCheck.checked
    property alias cfg_sortDirsFirst: dirsFirstCheck.checked
    property alias cfg_animationDuration: durationSpin.value

    Kirigami.FormLayout {
        RowLayout {
            Kirigami.FormData.label: i18n("Folder:")
            QQC2.TextField {
                id: urlField
                Layout.fillWidth: true
                text: page.cfg_url
                placeholderText: i18n("Downloads folder")
                onTextEdited: page.cfg_url = text
            }
            QQC2.Button {
                icon.name: "folder-open"
                text: i18n("Browse…")
                onClicked: folderDialog.open()
            }
        }

        QQC2.Button {
            Kirigami.FormData.label: i18n("Icon:")
            icon.name: page.cfg_icon
            text: page.cfg_icon
            onClicked: iconDialog.open()
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.SpinBox {
            id: fanLimitSpin
            Kirigami.FormData.label: i18n("Files shown in the fan:")
            from: 1
            to: 30
        }

        QQC2.SpinBox {
            id: iconSizeSpin
            Kirigami.FormData.label: i18n("Fan icon size:")
            from: 22
            to: 128
            stepSize: 2
            textFromValue: (value, locale) => i18n("%1 px", value)
            valueFromText: (text, locale) => parseInt(text)
        }

        QQC2.SpinBox {
            id: leanSpin
            Kirigami.FormData.label: i18n("Fan lean at the top:")
            from: 10
            to: 60
            textFromValue: (value, locale) => i18n("%1°", value)
            valueFromText: (text, locale) => parseInt(text)
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Fan curves:")
            model: [i18n("Away from the screen edge"), i18n("To the right"), i18n("To the left")]
            currentIndex: page.cfg_direction
            onActivated: page.cfg_direction = currentIndex
        }

        QQC2.SpinBox {
            id: durationSpin
            Kirigami.FormData.label: i18n("Animation length:")
            from: 0
            to: 2000
            stepSize: 50
            textFromValue: (value, locale) => i18n("%1 ms", value)
            valueFromText: (text, locale) => parseInt(text)
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: sortCombo
            Kirigami.FormData.label: i18n("Sort by:")
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("Date"), value: 2 },
                { text: i18n("Name"), value: 0 },
                { text: i18n("Size"), value: 1 },
                { text: i18n("Type"), value: 6 }
            ]
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(page.cfg_sortMode))
            onActivated: page.cfg_sortMode = currentValue
        }

        QQC2.CheckBox {
            id: newestAtTopCheck
            text: i18n("First file at the top of the fan")
        }

        QQC2.CheckBox {
            id: sortDescCheck
            text: i18n("Descending (newest or largest first)")
        }

        QQC2.CheckBox {
            id: dirsFirstCheck
            text: i18n("Folders first")
        }

        QQC2.CheckBox {
            id: previewsCheck
            text: i18n("Show thumbnails")
        }

        QQC2.CheckBox {
            id: hiddenCheck
            text: i18n("Show hidden files")
        }

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("Animation length is scaled by the system-wide animation speed. Middle-click the panel icon to open the folder directly; files dropped on it are moved into the folder.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }
    }

    QtDialogs.FolderDialog {
        id: folderDialog
        currentFolder: page.cfg_url
        onAccepted: page.cfg_url = selectedFolder.toString()
    }

    KIconThemes.IconDialog {
        id: iconDialog
        onIconSelected: iconName => page.cfg_icon = iconName
    }
}
