pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml.Models
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications

Scope {
    id: root

    // Cards currently visible on screen (may outlive trackedNotifications when persistent)
    property var activeCards: []

    // Returns the topmost visible card, if any
    function topCard() {
        return root.activeCards.find(c => c.visible_) ?? null;
    }

    IpcHandler {
        target: "notifications"

        function dismiss() {
            const card = root.topCard();
            if (card) card.animateOut();
        }

        function dismissAll() {
            root.activeCards.filter(c => c.visible_).forEach(c => c.animateOut());
        }

        function invoke() {
            const card = root.topCard();
            if (!card) return;
            const n = card.notification;
            if (!n) return;
            const def = (n.actions ?? []).find(a => a.identifier === "default");
            if (def) {
                def.invoke();
            } else if (n.desktopEntry && n.desktopEntry !== "") {
                const entry = DesktopEntries.byId(n.desktopEntry);
                if (entry) entry.launch();
            }
            card.animateOut();
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
                    timeout: Config.notifications.timeout
                    width: Config.notifications.cardWidth
                    parent: notifColumn

                    Component.onCompleted: root.activeCards.push(this)
                    Component.onDestruction: {
                        const idx = root.activeCards.indexOf(this);
                        if (idx !== -1) root.activeCards.splice(idx, 1);
                        root.activeCardsChanged();
                    }

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
