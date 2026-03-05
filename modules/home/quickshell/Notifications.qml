pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

Scope {
    id: root

    readonly property int animateSpeed: 250
    readonly property int maxNotifications: 5

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
    }

    PanelWindow {
        WlrLayershell.layer: WlrLayer.Overlay
        anchors.top: true
        anchors.right: true
        exclusiveZone: 0
        color: "transparent"
        mask: Region {}

        implicitWidth: 376
        implicitHeight: notifColumn.implicitHeight + 16

        Column {
            id: notifColumn

            anchors {
                top: parent.top
                right: parent.right
                topMargin: 8
                rightMargin: 8
            }

            width: 360
            spacing: 0

            Repeater {
                id: repeater
                // Most recent first — reverse the list
                model: {
                    const all = server.trackedNotifications;
                    const capped = all.slice(Math.max(0, all.length - root.maxNotifications));
                    return capped.slice().reverse();
                }

                delegate: NotificationCard {
                    required property Notification modelData

                    notification: modelData
                    animateSpeed: root.animateSpeed
                    width: 360

                    // Slide in shortly after creation so the height animation
                    // has time to open up space before the card slides in
                    Component.onCompleted: Qt.callLater(() => { visible_ = true; })

                    Connections {
                        target: modelData
                        function onClosed() {
                            visible_ = false;
                        }
                    }
                }
            }
        }
    }
}
