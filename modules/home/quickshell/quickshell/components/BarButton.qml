import QtQuick
import Quickshell
import Quickshell.Widgets

import ".."

// Cyberpunk button-look wrapper for bar section trigger icons.
// On hover/active: cyan tint fill + neon cyan border + outer glow ring.
//
// Two variants — controlled by whether iconSource is set:
//
//   Icon-only (iconSource not set):
//     Place children directly inside via the default content alias.
//     implicitWidth stays at batteryIconSize + 10.
//
//   Icon + label (iconSource set):
//     BarButton renders the icon and optional percentage label itself.
//     - label: string to show to the right of the icon. Empty = icon only.
//     - labelColor: color for the label text (default textPrimary).
//     - dimmed: when true, fades icon + label to disabledOpacity with a
//               smooth animation — use for muted/disabled states.
//     - labelWidth: fixed pixel width reserved for the label column so
//                   the icon never shifts as the digit count changes.
//                   Passed down from Bar.qml's statusLabelWidth.
//     implicitWidth expands to fit icon + spacing + labelWidth + padding.
Rectangle {
    id: root

    property bool hovered: false
    property bool popupOpen: false
    property bool clickable: true

    // ── Icon+label variant ────────────────────────────────────────────────────
    property url    iconSource: ""          // set to activate icon+label mode
    property string label: ""              // percentage string, e.g. "85%"
    property color  labelColor: Config.colors.textPrimary
    property bool   dimmed: false          // true → fade to disabledOpacity
    property int    labelWidth: 0          // fixed width for label column

    // ── Fallback (icon-only / custom content) ─────────────────────────────────
    default property alias content: root.data

    // ── Geometry ──────────────────────────────────────────────────────────────

    readonly property bool _iconMode: iconSource != ""
    readonly property int  _spacing:  Math.round(3 * Config.scale)
    readonly property int  _pad:      Math.round(10 * Config.scale)

    implicitWidth: _iconMode && label !== ""
        ? Config.bar.batteryIconSize + _spacing + labelWidth + _pad
        : Config.bar.batteryIconSize + _pad
    implicitHeight: Config.bar.batteryIconSize + _pad

    // ── Visuals ───────────────────────────────────────────────────────────────

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

    Behavior on color       { ColorAnimation { duration: 80 } }
    Behavior on border.color { ColorAnimation { duration: 80 } }

    // ── Icon + label row (only when iconSource is set) ────────────────────────

    Row {
        visible: root._iconMode
        anchors.centerIn: parent
        spacing: root._spacing

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: Config.bar.batteryIconSize
            source: root.iconSource

            opacity: root.dimmed ? Config.bar.disabledOpacity : 1.0
            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label !== ""
            text: root.label
            // Fixed width so the icon never shifts as digit count changes (9% → 100%).
            width: root.labelWidth > 0 ? root.labelWidth : implicitWidth
            horizontalAlignment: Text.AlignHCenter
            color: root.labelColor
            font.family: Config.font.family
            font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.72)

            opacity: root.dimmed ? Config.bar.disabledOpacity : 1.0
            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
        }
    }
}
