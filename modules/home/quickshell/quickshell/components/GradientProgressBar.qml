pragma ComponentBehavior: Bound

import QtQuick
import ".."

// Horizontal gradient progress bar: a frosted rail with an accent→accentAlt fill.
// Used by BarSliderPopup and OsdRow.
Item {
    id: root

    // 0.0 – 1.0 fill fraction
    property real value: 0

    property int barHeight: Math.round(6 * Config.scale)

    implicitHeight: barHeight + Math.round(4 * Config.scale)

    // Rail
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        width: parent.width
        height: root.barHeight
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.10)
    }

    // Gradient fill
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        width: Math.min(parent.width, parent.width * Math.max(0, Math.min(1, root.value)))
        height: root.barHeight
        radius: height / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Config.colors.accent }
            GradientStop { position: 1.0; color: Config.colors.accentAlt }
        }
    }
}
