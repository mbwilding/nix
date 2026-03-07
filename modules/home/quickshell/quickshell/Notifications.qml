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

    // ── Notification history ──────────────────────────────────────────────────

    // Array of snapshot objects
    property var notifHistory: []

    // Maps live notification id → snapshot id
    // so we can remove history when the live card is dismissed.
    property var _notifSnapshotIds: ({})

    // Emitted when a live toast is dismissed — tells the history popup to
    // animate out the matching card, which then calls removeHistoryEntry itself.
    signal animateOutHistoryEntry(var snapId)

    function removeHistoryEntry(entryId) {
        // When called from the history card (user dismissed from history),
        // also dismiss the live notification if still present.
        const entry = root.notifHistory.find(e => e.id === entryId);
        if (entry?.liveNotif)
            entry.liveNotif.dismiss();
        root.notifHistory = root.notifHistory.filter(e => e.id !== entryId);
    }

    // ── Battery ───────────────────────────────────────────────────────────────

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

    function batteryIconName(pct, charging) {
        const level = Math.min(100, Math.round(pct / 10) * 10);
        const lvlStr = String(level).padStart(3, "0");
        const chargeSuffix = charging ? "-charging" : "";
        return "battery-" + lvlStr + chargeSuffix + "-symbolic";
    }

    function batteryNotify(level, pct, charging) {
        const icon = batteryIconName(pct, charging);
        batteryNotifyProc.command = ["notify-send", "--app-name=Battery", "--app-icon=" + icon, level.title, level.message];
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

            const pct = Math.round(root.battery.percentage * 100);

            if (state === UPowerDeviceState.Charging) {
                root.firedLevels = [];
                root.lastCheckedPct = -1;
                root.batteryNotify(Config.battery.chargeLevels.charging, pct, true);
            } else if (state === UPowerDeviceState.Discharging) {
                root.firedLevels = [];
                root.lastCheckedPct = pct;
                root.batteryNotify(Config.battery.chargeLevels.discharging, pct, false);
            } else if (state === UPowerDeviceState.FullyCharged) {
                root.batteryNotify(Config.battery.chargeLevels.fullyCharged, pct, false);
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
                    root.batteryNotify(warn, pct, false);
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

            // Snapshot into history — keep live notification + action objects so they can still be invoked
            const snapId = Date.now() + Math.random();
            const snapshot = {
                id: snapId,
                liveNotif: notification,              // live Notification object for dismiss/invoke
                appName: notification.appName ?? "",
                appIcon: notification.appIcon ?? "",
                desktopEntry: notification.desktopEntry ?? "",
                summary: notification.summary ?? "",
                body: notification.body ?? "",
                actions: notification.actions ?? [],   // live NotificationAction objects
                receivedAt: new Date()
            };
            root.notifHistory = [snapshot].concat(root.notifHistory);

            // Remember which snapshot this notification maps to
            root._notifSnapshotIds[notification.id] = snapId;
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
                    id: notifCardDelegate
                    required property Notification modelData

                    notification: modelData
                    timeout: Config.notifications.timeout
                    width: Config.notifications.cardWidth
                    parent: notifColumn

                    onDismissed: {
                        const snapId = root._notifSnapshotIds[notifCardDelegate.modelData.id];
                        if (snapId !== undefined) {
                            // Signal the history popup to animate the card out first;
                            // the card's onDismissed will then call removeHistoryEntry.
                            root.animateOutHistoryEntry(snapId);
                            delete root._notifSnapshotIds[notifCardDelegate.modelData.id];
                        }
                    }

                    Component.onCompleted: root.activeCards.push(this)
                    Component.onDestruction: {
                        const idx = root.activeCards.indexOf(this);
                        if (idx !== -1)
                            root.activeCards.splice(idx, 1);
                        root.activeCardsChanged();
                    }

                    Connections {
                        target: notifCardDelegate.modelData
                        function onClosed() {
                            if (Config.notifications.timeout !== 0)
                                notifCardDelegate.animateOut();
                        }
                    }
                }
            }
        }
    }
}
