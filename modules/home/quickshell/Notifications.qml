pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml.Models
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

Scope {
    id: root

    // Returns the topmost (first) tracked notification, if any
    function topNotification() {
        return server.trackedNotifications.length > 0
            ? server.trackedNotifications[0]
            : null;
    }

    IpcHandler {
        target: "notifications"

        function dismiss() {
            const n = root.topNotification();
            if (n) n.dismiss();
        }

        function invoke() {
            const n = root.topNotification();
            if (!n) return;
            const def = (n.actions ?? []).find(a => a.identifier === "default");
            if (def) {
                def.invoke();
            } else if (n.desktopEntry && n.desktopEntry !== "") {
                const entry = DesktopEntries.byId(n.desktopEntry);
                if (entry) entry.launch();
            }
            n.dismiss();
        }
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true;
        }
    }

    PanelWindow {
        WlrLayershell.layer: WlrLayer.Overlay
        anchors.top: true
        anchors.right: true
        anchors.bottom: true
        exclusiveZone: 0
        color: "transparent"
        mask: Region {
            item: notifColumn
        }

        implicitWidth: Config.notifications.cardWidth + Math.round(16 * Config.scale)

        Column {
            id: notifColumn

            anchors {
                top: parent.top
                right: parent.right
                topMargin: Math.round(8 * Config.scale)
                rightMargin: Math.round(8 * Config.scale)
            }

            width: Config.notifications.cardWidth
            spacing: 0

            move: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: Config.notifications.animateSpeed
                    easing.type: Easing.InOutQuad
                }
            }

            Instantiator {
                model: server.trackedNotifications
                delegate: NotificationCard {
                    required property Notification modelData

                    notification: modelData
                    animateSpeed: Config.notifications.animateSpeed
                    timeout: Config.notifications.timeout
                    width: Config.notifications.cardWidth
                    parent: notifColumn

                    Connections {
                        target: modelData
                        function onClosed() {
                            if (Config.notifications.timeout !== 0)
                                animateOut();
                        }
                    }
                }
            }
        }
    }
}
