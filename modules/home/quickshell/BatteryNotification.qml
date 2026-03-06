pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Scope {
    id: root

    property UPowerDevice battery: UPower.displayDevice
    property var firedLevels: []
    property bool ready: false
    property bool initialStateHandled: false
    property bool initialPercentageHandled: false

    Component.onCompleted: {
        Qt.callLater(() => {
            root.ready = true;
        });
    }

    function notify(level) {
        notifyProc.command = ["notify-send", "--app-name=Battery", "--app-icon=" + level.icon, level.title, level.message];
        notifyProc.running = true;
    }

    Process {
        id: notifyProc
    }

    Connections {
        target: root.battery

        function onStateChanged() {
            if (!root.ready)
                return;

            if (!root.initialStateHandled) {
                root.initialStateHandled = true;
                return;
            }

            const state = root.battery.state;

            if (state === UPowerDeviceState.Charging) {
                root.firedLevels = [];
                root.notify(Config.battery.chargeLevels.charging);
            } else if (state === UPowerDeviceState.Discharging) {
                root.firedLevels = [];
                root.notify(Config.battery.chargeLevels.discharging);
            } else if (state === UPowerDeviceState.FullyCharged) {
                root.notify(Config.battery.chargeLevels.fullyCharged);
            }
        }

        function onPercentageChanged() {
            if (!root.ready)
                return;

            if (!root.initialPercentageHandled) {
                root.initialPercentageHandled = true;
                return;
            }

            if (root.battery.state !== UPowerDeviceState.Discharging)
                return;

            const pct = Math.round(root.battery.percentage * 100);
            const levels = Config.battery.warnLevels.slice().sort((a, b) => b.level - a.level);

            for (const warn of levels) {
                if (pct <= warn.level && !root.firedLevels.includes(warn.level)) {
                    root.firedLevels = root.firedLevels.concat([warn.level]);
                    root.notify(warn);
                    break;
                }
            }
        }
    }
}
