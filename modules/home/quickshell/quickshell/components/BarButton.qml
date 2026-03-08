import QtQuick

import ".."

// Cyberpunk button-look wrapper for bar section trigger icons.
// On hover/active: cyan tint fill + neon cyan border + outer glow ring.
// Snappier ColorAnimation (80ms) for crisp response.
Rectangle {
    id: root

    property bool hovered: false
    property bool popupOpen: false
    property bool clickable: true

    default property alias content: root.data

    implicitWidth: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    implicitHeight: Config.bar.batteryIconSize + Math.round(10 * Config.scale)

    radius: Math.round(8 * Config.scale)

    color: (clickable && (hovered || popupOpen))
        ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.12)
        : "transparent"

    border.color: (clickable && (hovered || popupOpen))
        ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.70)
        : "transparent"
    border.width: 1

    // Outer neon glow ring — only on hover/active
    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: root.radius + 3
        color: "transparent"
        border.color: Config.colors.glowAccent
        border.width: 2
        opacity: (root.clickable && (root.hovered || root.popupOpen)) ? 0.4 : 0
        antialiasing: true
        Behavior on opacity { NumberAnimation { duration: 80 } }
    }

    Behavior on color {
        ColorAnimation { duration: 80 }
    }
    Behavior on border.color {
        ColorAnimation { duration: 80 }
    }
}
