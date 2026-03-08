pragma ComponentBehavior: Bound

import QtQuick
import ".."

// Neon gradient progress bar: cyan → hot-pink fill on a dark frosted rail.
// Used by BarSliderPopup and OsdRow.
Item {
    id: root

    // 0.0 – 1.0 fill fraction
    property real value: 0

    property int barHeight: Math.round(6 * Config.scale)

    implicitHeight: barHeight + Math.round(4 * Config.scale)

    // Rail — very dark, faint cyan tint
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        width: parent.width
        height: root.barHeight
        radius: height / 2
        color: Config.colors.sliderRail
    }

    // Neon glow layer behind the fill (wider, blurred via opacity)
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        width: Math.min(parent.width, parent.width * Math.max(0, Math.min(1, root.value)))
        height: root.barHeight + Math.round(4 * Config.scale)
        radius: height / 2
        opacity: 0.35
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Config.colors.accent }
            GradientStop { position: 1.0; color: Config.colors.accentAlt }
        }
    }

    // Cyan → pink gradient fill
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
