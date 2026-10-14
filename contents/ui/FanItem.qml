/*
    One entry of the fan: an icon with a pill-shaped label beside it.

    `t` runs from 0 (tucked into the dock icon, invisible) to 1 (resting on
    the arc). The entry slides along the arc as t grows, growing and fading in
    on the way; the label fades in during the second half. Opening animates t
    up with a per-entry delay so the fan unrolls from the bottom; closing
    animates it back down from the top.
*/
import QtQuick
import QtQuick.Effects

import org.kde.kirigami as Kirigami

Item {
    id: item

    required property var fan
    required property int fanIndex
    property var iconSource
    property string label: ""
    property bool emphasised: false

    signal activated()

    property real t: 0

    readonly property int size: fan.iconSize
    readonly property int dir: fan.direction
    readonly property real angle: fan.angleFor(fanIndex) * t
    readonly property real cx: fan.originX + dir * fan.arcRadius * (1 - Math.cos(angle))
    readonly property real cy: fan.originY - fan.arcRadius * Math.sin(angle)
    readonly property real clampedT: Math.max(0, Math.min(1, t))
    readonly property bool hovered: hover.hovered
    readonly property bool settled: t >= 1

    width: size + fan.labelGap + pill.width
    height: size
    x: dir > 0 ? cx - size / 2 : cx + size / 2 - width
    y: cy - size / 2
    z: hovered ? 1000 : fanIndex
    opacity: Math.min(1, clampedT * 2.5)
    visible: t > 0.001

    Item {
        id: iconBox
        width: item.size
        height: item.size
        x: item.dir > 0 ? 0 : item.width - item.size
        scale: (0.55 + 0.45 * item.clampedT) * (item.hovered && item.settled ? 1.12 : 1)
        Behavior on scale {
            enabled: item.settled
            NumberAnimation {
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.OutCubic
            }
        }

        Kirigami.Icon {
            id: icon
            anchors.fill: parent
            source: item.iconSource
            visible: false
        }
        MultiEffect {
            anchors.fill: icon
            source: icon
            shadowEnabled: true
            shadowColor: "black"
            shadowOpacity: 0.6
            shadowBlur: 0.9
            shadowVerticalOffset: 2
        }
    }

    Rectangle {
        id: pill
        x: item.dir > 0 ? item.size + item.fan.labelGap : 0
        anchors.verticalCenter: iconBox.verticalCenter
        anchors.verticalCenterOffset: item.fan.labelDrop
        width: labelText.width + Kirigami.Units.largeSpacing * 2
        height: labelText.implicitHeight + Kirigami.Units.smallSpacing * 2
        radius: height / 2
        color: Qt.rgba(0, 0, 0, item.hovered ? 0.82 : 0.62)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.18)
        opacity: Math.max(0, (item.clampedT - 0.45) / 0.55)

        Text {
            id: labelText
            anchors.centerIn: parent
            width: Math.min(implicitWidth, item.fan.labelMaxWidth)
            text: item.label
            color: "white"
            elide: Text.ElideRight
            font.family: Kirigami.Theme.defaultFont.family
            font.pointSize: Kirigami.Theme.defaultFont.pointSize
            font.weight: item.emphasised ? Font.DemiBold : Font.Normal
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: item.activated()
    }

    SequentialAnimation {
        id: openAnim
        PauseAnimation {
            duration: item.fanIndex * item.fan.stagger
        }
        NumberAnimation {
            target: item
            property: "t"
            to: 1
            duration: item.fan.duration
            easing.type: Easing.OutBack
            easing.overshoot: 0.9
        }
    }
    SequentialAnimation {
        id: closeAnim
        PauseAnimation {
            duration: Math.max(0, item.fan.itemCount - 1 - item.fanIndex) * item.fan.stagger
        }
        NumberAnimation {
            target: item
            property: "t"
            to: 0
            duration: item.fan.closeDuration
            easing.type: Easing.InCubic
        }
    }
    Connections {
        target: item.fan
        function onOpenStarted() {
            closeAnim.stop();
            openAnim.restart();
        }
        function onCloseStarted() {
            openAnim.stop();
            closeAnim.restart();
        }
        function onItemsReset() {
            openAnim.stop();
            closeAnim.stop();
            item.t = 0;
        }
    }
}
