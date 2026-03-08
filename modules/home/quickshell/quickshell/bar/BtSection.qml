pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Widgets

import ".."
import "../components"

BarSectionItem {
    id: btSection

    property alias popup: btPopup
    property real availableHeight: 800
    property string activePopup: ""
    property string connectingAddress: ""

    readonly property bool popupOpen: activePopup === "bt"
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var availableDevices: {
        void btSection.popupOpen;
        const a = btSection.adapter;
        const vals = (a && a.enabled && a.devices) ? a.devices.values : null;
        if (!vals || vals.length === 0)
            return [];
        const result = [];
        for (let i = 0; i < vals.length; i++) {
            const d = vals[i];
            if (d && !d.connected)
                result.push({
                    label: btSection.deviceName(d),
                    icon: btSection.deviceIcon(d),
                    address: d.address || ""
                });
        }
        return result;
    }
    readonly property var connectedDevices: {
        void btSection.popupOpen;
        const a = btSection.adapter;
        const vals = (a && a.enabled && a.devices) ? a.devices.values : null;
        if (!vals || vals.length === 0)
            return [];
        const result = [];
        for (let i = 0; i < vals.length; i++) {
            const d = vals[i];
            if (d && d.connected)
                result.push({
                    label: btSection.deviceName(d),
                    icon: btSection.deviceIcon(d),
                    address: d.address || ""
                });
        }
        return result;
    }

    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq

    implicitWidth: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    implicitHeight: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    popupItem: btPopup
    onPopupOpenChanged: {
        const a = btSection.adapter;
        if (!a || !a.enabled)
            return;
        a.discovering = btSection.popupOpen;
    }

    function btIcon() {
        const a = btSection.adapter;
        if (!a || !a.enabled)
            return "network-bluetooth-inactive-symbolic";
        const vals = a.devices ? a.devices.values : null;
        if (vals) {
            for (let i = 0; i < vals.length; i++) {
                const d = vals[i];
                if (d && d.connected)
                    return "network-bluetooth-activated-symbolic";
            }
        }
        return "network-bluetooth-symbolic";
    }

    function deviceName(d) {
        if (!d)
            return "Unknown";
        return d.name || d.deviceName || d.address || "Unknown";
    }

    function deviceIcon(d) {
        if (!d)
            return "network-bluetooth-symbolic";
        const ico = d.icon || "";
        return ico !== "" ? ico : "network-bluetooth-symbolic";
    }

    Process {
        id: btNotifyProc
    }

    function btNotify(title, message, icon) {
        btNotifyProc.command = ["notify-send", "--app-name=Bluetooth", "--app-icon=" + icon, title, message];
        btNotifyProc.running = true;
    }

    MouseArea {
        id: triggerArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: btSection.openPopupReq("bt")
        onExited: btSection.keepPopupReq()
        onClicked: {
            if (btSection.adapter)
                btSection.adapter.enabled = !btSection.adapter.enabled;
        }
    }

    BarButton {
        anchors.fill: parent
        hovered: triggerArea.containsMouse
        popupOpen: btSection.popupOpen

        IconImage {
            anchors.centerIn: parent
            implicitSize: Config.bar.batteryIconSize
            source: Quickshell.iconPath(btSection.btIcon())
            opacity: (btSection.adapter && btSection.adapter.enabled) ? 1.0 : Config.bar.disabledOpacity
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    BarSectionPopup {
        id: btPopup
        popupOpen: btSection.popupOpen

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        availableHeight: btSection.availableHeight - btSection.height - Config.bar.popupOffset

        emptyText: {
            const a = btSection.adapter;
            if (!a || !a.enabled)
                return "Bluetooth is off";
            if (a.discovering)
                return "Scanning\u2026";
            return "No devices found";
        }

        availableItems: btSection.availableDevices
        connectedItems: btSection.connectedDevices
        rawModel: (btSection.adapter && btSection.adapter.enabled) ? btSection.adapter.devices : null
        rawIsConnectedFn: d => d && d.connected
        rawSavedFn: d => d && d.paired
        rawLabelFn: d => btSection.deviceName(d)
        rawIconFn: d => btSection.deviceIcon(d)
        rawBatteryFn: d => (d && d.batteryAvailable) ? d.battery : -1
        onHoverOpen: btSection.openPopupReq("bt")
        onHoverExit: btSection.exitPopupReq()
        onRawAvailableClicked: d => {
            if (!d || d.state === 3 || d.state === 2)
                return;
            btSection.connectingAddress = d.address || "";
            if (d.paired)
                d.connect();
            else
                d.pair();
            btSection.openPopupReq("bt");
        }
        onRawConnectedClicked: d => {
            if (!d || d.state === 2)
                return;
            const name = btSection.deviceName(d);
            btSection.connectingAddress = d.address || "";
            btDisconnectNotifyTimer.targetName = name;
            btDisconnectNotifyTimer.targetAddress = d.address || "";
            d.disconnect();
            btDisconnectNotifyTimer.restart();
            btSection.openPopupReq("bt");
        }
    }

    Repeater {
        model: (btSection.adapter && btSection.adapter.enabled) ? btSection.adapter.devices : null
        delegate: Item {
            id: btWatcher
            required property var modelData
            readonly property int devState: modelData ? modelData.state : 0

            onDevStateChanged: {
                const d = btWatcher.modelData;
                if (!d)
                    return;
                if (d.connected && btSection.connectingAddress === (d.address || "")) {
                    btSection.connectingAddress = "";
                    btSection.btNotify("Bluetooth Connected", "Connected to " + btSection.deviceName(d), "network-bluetooth-activated-symbolic");
                }
            }
        }
    }

    Timer {
        id: btDisconnectNotifyTimer
        interval: 4000
        property string targetName: ""
        property string targetAddress: ""

        onTriggered: {
            btSection.connectingAddress = "";
            const vals = (btSection.adapter && btSection.adapter.devices) ? btSection.adapter.devices.values : null;
            if (!vals)
                return;
            for (let i = 0; i < vals.length; i++) {
                const d = vals[i];
                if (!d)
                    continue;
                if ((d.address || "") !== btDisconnectNotifyTimer.targetAddress)
                    continue;
                if (d.state === 0) {
                    btSection.btNotify("Bluetooth Disconnected", "Disconnected from " + btDisconnectNotifyTimer.targetName, "network-bluetooth-symbolic");
                }
                break;
            }
        }
    }
}
