pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Item {
    id: root

    required property SystemTrayItem trayItem
    signal hovered

    implicitWidth: iconContainer.implicitWidth
    implicitHeight: iconContainer.implicitHeight

    Rectangle {
        id: iconContainer

        implicitWidth: Config.bar.batteryIconSize + Math.round(8 * Config.scale)
        implicitHeight: Config.bar.batteryIconSize + Math.round(8 * Config.scale)
        radius: Math.round(6 * Config.scale)
        color: hoverArea.containsMouse ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.15) : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 100
            }
        }

        IconImage {
            id: icon
            anchors.centerIn: parent
            implicitSize: Config.bar.batteryIconSize
            source: root.trayItem.icon
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onEntered: root.hovered()

            onClicked: mouse => {
                root.hovered();
                if (mouse.button === Qt.RightButton) {
                    if (root.trayItem.hasMenu)
                        root.trayItem.display(hoverArea.window, root.mapToItem(null, 0, 0).x, root.mapToItem(null, 0, 0).y);
                } else {
                    if (root.trayItem.hasMenu)
                        root.trayItem.display(hoverArea.window, root.mapToItem(null, 0, 0).x, root.mapToItem(null, 0, 0).y);
                    else
                        root.trayItem.activate();
                }
            }
        }
    }
}
