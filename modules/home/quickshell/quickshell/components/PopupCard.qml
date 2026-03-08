pragma ComponentBehavior: Bound

import QtQuick
import ".."

// Glassmorphic card base — deep navy background, outer glow ring, optional top-shine.
// No hard border.width — the glow ring provides all framing.
// Set popupRadius to override the default bar popup radius.
// Set showShine: false to suppress the top-shine (e.g. on the OSD panel).
Rectangle {
    id: root

    property int popupRadius: Config.bar.popupRadius
    property bool showShine: true

    radius: popupRadius
    antialiasing: true
    color: Config.colors.surface
    border.width: 0
    clip: true

    // Outer glow ring — atmospheric halo just outside the card edge
    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: root.radius + 2
        color: "transparent"
        border.color: Config.colors.glowAccent
        border.width: 2
        opacity: 0.30
        z: -1
        antialiasing: true
    }

    // Top shine rim — subtle highlight along the top inner edge
    Rectangle {
        visible: root.showShine
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.leftMargin: parent.radius
        anchors.rightMargin: parent.radius
        height: 1
        color: Config.colors.separator
        z: 2
    }
}
