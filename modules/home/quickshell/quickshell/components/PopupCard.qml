pragma ComponentBehavior: Bound

import QtQuick
import ".."

// Reusable glassmorphic card — deep navy background, subtle border, top-shine rim.
// Set popupRadius to override the default bar popup radius.
// Place child items inside via the default property (they stack on top of the card).
Rectangle {
    id: root

    property int popupRadius: Config.bar.popupRadius

    radius: popupRadius
    antialiasing: true
    color: Qt.rgba(0.12, 0.11, 0.22, 0.95)
    border.color: Config.colors.border
    border.width: 1
    clip: true

    // Top shine rim
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.leftMargin: parent.radius
        anchors.rightMargin: parent.radius
        height: 1
        color: "#25ffffff"
        z: 1
    }
}
