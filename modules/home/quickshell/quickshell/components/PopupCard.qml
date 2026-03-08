pragma ComponentBehavior: Bound

import QtQuick

import ".."

// Glassmorphic card base — deep navy background with themed outline.
// Outline is controlled globally via Config.panelBorder.
// Set popupRadius to override the default bar popup radius.
Rectangle {
    id: root

    property int popupRadius: Config.bar.popupRadius

    radius: popupRadius
    antialiasing: true
    color: Config.colors.surface
    border.width: Config.panelBorder.width
    border.color: Config.panelBorder.color
    clip: true
}
