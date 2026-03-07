import QtQuick
import ".."

// Shared button-look wrapper for bar section trigger icons.
//
// Callers set `hovered` and `popupOpen` from their own interaction handlers.
// Place icon content as direct children — they are reparented into this Rectangle.
//
// Sizing: defaults to batteryIconSize + 10px padding on each axis. Override
// implicitWidth/implicitHeight if needed (e.g. text glyphs with different sizes).
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
        ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18)
        : "transparent"

    border.color: (clickable && (hovered || popupOpen))
        ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.35)
        : "transparent"
    border.width: 1

    Behavior on color {
        ColorAnimation { duration: 120 }
    }
    Behavior on border.color {
        ColorAnimation { duration: 120 }
    }
}
