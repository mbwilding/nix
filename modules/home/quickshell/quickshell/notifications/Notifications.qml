pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml.Models
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Services.UPower

import ".."

Scope {
    id: root

    property UPowerDevice battery: UPower.displayDevice
    property bool batteryReady: false
    property bool initialPercentageHandled: false
    property bool initialStateHandled: false
    property int lastCheckedPct: -1
    property var _notifSnapshotIds: ({})
    property var _pendingDirectRemovals: []
    property var _pendingRemoval: ({})
    property var activeCards: []
    property var firedLevels: []
    property var notifHistory: []

    signal animateOutHistoryEntry(var snapId)

    Component.onCompleted: {
        Qt.callLater(() => {
            root.batteryReady = true;
        });
    }

    function topCard() {
        return root.activeCards.find(c => c.visible_) ?? null;
    }

    function dismissAll() {
        root.activeCards.filter(c => c.visible_).forEach(c => c.animateOut());
        dismissAllTimer.restart();
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

    function removeHistoryEntry(entryId) {
        if (root._pendingRemoval[entryId]) {
            delete root._pendingRemoval[entryId];
            root.notifHistory = root.notifHistory.filter(e => e.id !== entryId);
            return;
        }

        const entry = root.notifHistory.find(e => e.id === entryId);
        if (entry?.liveNotif) {
            const liveCard = root.activeCards.find(c => c.notification === entry.liveNotif && c.visible_);
            if (liveCard) {
                root._pendingRemoval[entryId] = true;
                liveCard.animateOut();
                return;
            } else {
                entry.liveNotif.dismiss();
            }
        }
        root.notifHistory = root.notifHistory.filter(e => e.id !== entryId);
    }

    Timer {
        id: directRemovalTimer
        interval: Config.notifications.animateSpeed + 50
        repeat: false
        onTriggered: {
            const ids = root._pendingDirectRemovals;
            root._pendingDirectRemovals = [];
            root.notifHistory = root.notifHistory.filter(e => !ids.includes(e.id));
        }
    }

    Timer {
        id: dismissAllTimer
        interval: Config.notifications.animateSpeed + 50
        repeat: false
        onTriggered: {
            root.notifHistory = [];
            root._notifSnapshotIds = ({});
            root._pendingRemoval = ({});
            root._pendingDirectRemovals = [];
            directRemovalTimer.stop();
        }
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
            root.dismissAll();
        }

        function invoke() {
            const card = root.topCard();
            if (!card)
                return;
            const n = card.notification;
            if (!n)
                return;
            // Iterate via index to avoid QV4 sequence-wrapping the C++ QList.
            const rawActions = n.actions;
            let def = null;
            for (let i = 0; i < rawActions.length; i++) {
                if (rawActions[i].identifier === "default") {
                    def = rawActions[i];
                    break;
                }
            }
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

            // Snapshot actions as plain JS objects immediately — holding a live
            // C++ QList<Action*> reference in a var property crashes Qt's QV4
            // sequence wrapper when the list is later iterated by a Repeater.
            const rawActions = notification.actions ?? [];
            const actions = [];
            for (let i = 0; i < rawActions.length; i++) {
                const a = rawActions[i];
                actions.push({
                    identifier: a.identifier ?? "",
                    text: a.text ?? ""
                });
            }

            const snapId = Date.now() + Math.random();
            const snapshot = {
                id: snapId,
                liveNotif: notification,
                appName: notification.appName ?? "",
                appIcon: notification.appIcon ?? "",
                desktopEntry: notification.desktopEntry ?? "",
                summary: notification.summary ?? "",
                body: notification.body ?? "",
                actions: actions,
                receivedAt: new Date()
            };
            root.notifHistory = [snapshot].concat(root.notifHistory);

            root._notifSnapshotIds[notification.id] = snapId;
        }
    }

    PanelWindow {
        screen: Quickshell.screens[Config.monitor]
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
                delegate: NotificationsCard {
                    id: notifCardDelegate
                    required property Notification modelData

                    notification: modelData
                    timeout: Config.notifications.timeout
                    width: Config.notifications.cardWidth
                    parent: notifColumn

                    onDismissed: {
                        const snapId = root._notifSnapshotIds[notifCardDelegate.modelData.id];
                        if (snapId !== undefined) {
                            delete root._notifSnapshotIds[notifCardDelegate.modelData.id];

                            if (root._pendingRemoval[snapId]) {
                                delete root._pendingRemoval[snapId];
                            }

                            root.animateOutHistoryEntry(snapId);
                            root._pendingDirectRemovals.push(snapId);
                            directRemovalTimer.restart();
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
