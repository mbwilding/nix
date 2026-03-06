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

    Component.onCompleted: {
        Qt.callLater(() => {
            root.ready = true;
        });
    }

    function notify(summary, body, icon) {
        notifyProc.command = ["notify-send", "--app-name=Battery", "--app-icon=" + icon, summary, body];
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

            const state = root.battery.state;

            if (state === UPowerDeviceState.Charging) {
                root.firedLevels = [];
                root.notify(Config.battery.charging.title, Config.battery.charging.message, Config.battery.charging.icon);
            } else if (state === UPowerDeviceState.Discharging) {
                root.firedLevels = [];
                root.notify(Config.battery.discharging.title, Config.battery.discharging.message, Config.battery.discharging.icon);
            } else if (state === UPowerDeviceState.FullyCharged) {
                root.notify(Config.battery.fullyCharged.title, Config.battery.fullyCharged.message, Config.battery.fullyCharged.icon);
            }
        }

        function onPercentageChanged() {
            if (!root.ready)
                return;
            if (root.battery.state !== UPowerDeviceState.Discharging)
                return;

            const pct = Math.round(root.battery.percentage * 100);
            const levels = Config.battery.warnLevels.slice().sort((a, b) => b.level - a.level);

            for (const warn of levels) {
                if (pct <= warn.level && !root.firedLevels.includes(warn.level)) {
                    root.firedLevels = root.firedLevels.concat([warn.level]);
                    root.notify(warn.title, warn.message, warn.icon);
                    break;
                }
            }
        }
    }
}
