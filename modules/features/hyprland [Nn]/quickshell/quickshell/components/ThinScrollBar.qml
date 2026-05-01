pragma ComponentBehavior: Bound

import QtQuick

import ".."

// Thin ambient scrollbar shown when popup content overflows.
//
// Usage:
//   ThinScrollBar {
//       anchors.top/right/bottom: parent.*
//       scrollY:    <popup>.scrollY
//       maxScrollY: <popup>.maxScrollY
//       contentH:   col.implicitHeight
//       viewportH:  viewport.height
//   }
//
// All four properties must be bound by the caller.
Item {
    id: root

    property real scrollY: 0
    property real maxScrollY: 0
    property real contentH: 0
    property real viewportH: 0

    // Optional thumb color override (defaults to textMuted)
    property color thumbColor: Config.colors.textMuted

    anchors.topMargin: Math.round(8 * Config.scale)
    anchors.bottomMargin: Math.round(8 * Config.scale)
    anchors.rightMargin: Math.round(3 * Config.scale)
    width: Math.round(3 * Config.scale)

    visible: root.maxScrollY > 0

    // Rail
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Config.colors.border
    }

    // Thumb
    Rectangle {
        readonly property real ratio: root.viewportH / Math.max(root.contentH, 1)
        readonly property real thumbH: Math.max(Math.round(20 * Config.scale), root.height * ratio)
        readonly property real travel: root.height - thumbH
        readonly property real scrollRatio: root.maxScrollY > 0 ? root.scrollY / root.maxScrollY : 0

        width: parent.width
        height: thumbH
        y: travel * scrollRatio
        radius: width / 2
        color: root.thumbColor

        Behavior on y {
            NumberAnimation {
                duration: 60
            }
        }
    }
}
