pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml.Models
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Services.UPower

Scope {
    id: root

    property var activeCards: []

    function topCard() {
        return root.activeCards.find(c => c.visible_) ?? null;
    }

    property UPowerDevice battery: UPower.displayDevice
    property var firedLevels: []
    property bool batteryReady: false
    property bool initialStateHandled: false
    property bool initialPercentageHandled: false
    property int lastCheckedPct: -1

    Component.onCompleted: {
        Qt.callLater(() => {
            root.batteryReady = true;
        });
    }

    function batteryNotify(level) {
        batteryNotifyProc.command = ["notify-send", "--app-name=Battery", "--app-icon=" + level.icon, level.title, level.message];
        batteryNotifyProc.running = true;
    }

    Process {
        id: batteryNotifyProc
    }

    Connections {
        target: root.battery

        function onStateChanged() {
            if (!root.batteryReady)
                return;

            if (!root.initialStateHandled) {
                root.initialStateHandled = true;
                return;
            }

            const state = root.battery.state;

            if (state === UPowerDeviceState.Charging) {
                root.firedLevels = [];
                root.lastCheckedPct = -1;
                root.batteryNotify(Config.battery.chargeLevels.charging);
            } else if (state === UPowerDeviceState.Discharging) {
                root.firedLevels = [];
                root.lastCheckedPct = Math.round(root.battery.percentage * 100);
                root.batteryNotify(Config.battery.chargeLevels.discharging);
            } else if (state === UPowerDeviceState.FullyCharged) {
                root.batteryNotify(Config.battery.chargeLevels.fullyCharged);
            }
        }

        function onPercentageChanged() {
            if (!root.batteryReady)
                return;

            if (!root.initialPercentageHandled) {
                root.initialPercentageHandled = true;
                root.lastCheckedPct = Math.round(root.battery.percentage * 100);
                return;
            }

            if (root.battery.state !== UPowerDeviceState.Discharging)
                return;

            const pct = Math.round(root.battery.percentage * 100);

            // Only act when the integer percent actually changes
            if (pct === root.lastCheckedPct)
                return;
            root.lastCheckedPct = pct;

            const levels = Config.battery.warnLevels.slice().sort((a, b) => b.level - a.level);

            for (const warn of levels) {
                if (pct <= warn.level && !root.firedLevels.includes(warn.level)) {
                    root.firedLevels = root.firedLevels.concat([warn.level]);
                    root.batteryNotify(warn);
                    break;
                }
            }
        }
    }

    IpcHandler {
        target: "notifications"

        function dismiss() {
            const card = root.topCard();
            if (card)
                card.animateOut();
        }

        function dismissAll() {
            root.activeCards.filter(c => c.visible_).forEach(c => c.animateOut());
        }

        function invoke() {
            const card = root.topCard();
            if (!card)
                return;
            const n = card.notification;
            if (!n)
                return;
            const def = (n.actions ?? []).find(a => a.identifier === "default");
            if (def) {
                def.invoke();
            } else if (n.desktopEntry && n.desktopEntry !== "") {
                const entry = DesktopEntries.byId(n.desktopEntry);
                if (entry)
                    entry.launch();
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
                        if (idx !== -1)
                            root.activeCards.splice(idx, 1);
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
