pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml.Models
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

        // Must explicitly track notifications or they are discarded
        onNotification: notification => { notification.tracked = true; }
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

            Instantiator {
                model: server.trackedNotifications
                delegate: NotificationCard {
                    required property Notification modelData

                    notification: modelData
                    animateSpeed: root.animateSpeed
                    width: 360
                    parent: notifColumn

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
