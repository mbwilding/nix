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
    readonly property int timeout: 5000

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true

        onNotification: notification => { notification.tracked = true; }
    }

    PanelWindow {
        WlrLayershell.layer: WlrLayer.Overlay
        anchors.top: true
        anchors.right: true
        anchors.bottom: true
        exclusiveZone: 0
        color: "transparent"

        implicitWidth: 376

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

            move: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: root.animateSpeed
                    easing.type: Easing.InOutQuad
                }
            }

            Instantiator {
                model: server.trackedNotifications
                delegate: NotificationCard {
                    required property Notification modelData

                    notification: modelData
                    animateSpeed: root.animateSpeed
                    timeout: root.timeout
                    width: 360
                    parent: notifColumn

                    Connections {
                        target: modelData
                        function onClosed() {
                            animateOut();
                        }
                    }
                }
            }
        }
    }
}
