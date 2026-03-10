pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets

import ".."
import "../components"

// Pin button — toggles the bar's pinned (always-visible) state.
// Place in Config.bar.layout via BarItems.pin.
// Bind `pinned` to Bar.root.pinned; connect onTogglePinReq to root.toggle().
Item {
    id: root

    property bool pinned: false
    signal togglePinReq

    implicitWidth: btn.implicitWidth
    implicitHeight: btn.implicitHeight

    BarButton {
        id: btn
        anchors.fill: parent
        hovered: pinMouse.containsMouse
        popupOpen: root.pinned
        clickable: true

        IconImage {
            anchors.centerIn: parent
            implicitSize: Config.bar.batteryIconSize
            source: Quickshell.iconPath(root.pinned ? "window-pin-symbolic" : "window-unpin-symbolic")
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: root.pinned ? Config.colors.accent : Config.colors.textSecondary
                Behavior on colorizationColor {
                    ColorAnimation {
                        duration: 120
                    }
                }
            }
        }
    }

    MouseArea {
        id: pinMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePinReq()
    }
}
