pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

import ".."
import "../components"

BarSectionItem {
    id: wifiSection

    property alias popup: wifiPopup
    property bool enabled: true
    property bool wifiReady: false
    property bool wifiScanning: false
    property bool hasWifiDevice: true
    property int noActiveCount: 0
    property int strength: -1
    property real availableHeight: 800
    property string activePopup: ""
    property string connecting: ""
    property string lastConnected: ""
    property string lastError: ""
    property string prevSsid: ""
    property string ssid: ""
    property var networks: []
    property var savedSsids: ({})

    readonly property bool popupOpen: activePopup === "wifi"
    readonly property string barIcon: (wifiSection.connecting !== "" || wifiSection.wifiScanning) ? wifiSection.connectAnimIcons[wifiSection.connectAnimStep] : wifiSection.icon(wifiSection.strength)
    readonly property var connectAnimIcons: ["network-wireless-signal-weak-symbolic", "network-wireless-signal-ok-symbolic", "network-wireless-signal-good-symbolic", "network-wireless-signal-excellent-symbolic"]

    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq
    signal keepAliveReq
    signal showPasswordDialogReq(string ssid_)
    signal hidePasswordDialogReq

    implicitHeight: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    implicitWidth: hasWifiDevice ? Config.bar.batteryIconSize + Math.round(10 * Config.scale) : 0
    visible: hasWifiDevice
    popupItem: wifiPopup

    Component.onCompleted: {
        wifiDeviceProc.running = true;
    }

    onSsidChanged: {
        if (!wifiSection.wifiReady)
            return;
        const prev = wifiSection.prevSsid;
        const cur = wifiSection.ssid;
        if (prev !== "" && cur === "" && wifiSection.connecting === "") {
            wifiDisconnectedNotifyProc.command = ["notify-send", "--app-name=Wi-Fi", "--app-icon=network-wireless-offline-symbolic", "Wi-Fi Disconnected", "Disconnected from " + prev];
            wifiDisconnectedNotifyProc.running = true;
        } else if (cur !== "" && prev === "" && wifiSection.connecting === "" && cur !== wifiSection.lastConnected) {
            wifiConnectedNotifyProc.command = ["notify-send", "--app-name=Wi-Fi", "--app-icon=network-wireless-symbolic", "Wi-Fi Connected", "Connected to " + cur];
            wifiConnectedNotifyProc.running = true;
        } else if (cur !== "" && prev === "" && wifiSection.connecting === "" && cur === wifiSection.lastConnected) {
            wifiSection.lastConnected = "";
        }
        wifiSection.prevSsid = cur;
    }

    function icon(sig) {
        if (sig < 0)
            return "network-wireless-offline-symbolic";
        if (sig < 25)
            return "network-wireless-signal-weak-symbolic";
        if (sig < 50)
            return "network-wireless-signal-ok-symbolic";
        if (sig < 75)
            return "network-wireless-signal-good-symbolic";
        return "network-wireless-signal-excellent-symbolic";
    }

    function toggleWifi() {
        wifiToggleProc.command = ["nmcli", "radio", "wifi", wifiSection.enabled ? "off" : "on"];
        wifiToggleProc.running = true;
    }

    function connectWifi(ssid_) {
        if (wifiSection.connecting !== "")
            return;
        wifiSection.connecting = ssid_;
        wifiSection.lastError = "";
        wifiConnectProc.targetSsid = ssid_;
        wifiConnectProc.command = ["nmcli", "--wait", "15", "dev", "wifi", "connect", ssid_];
        wifiConnectProc.running = true;
    }

    function connectWifiWithPassword(ssid_, password) {
        if (wifiSection.connecting !== "")
            return;
        wifiSection.connecting = ssid_;
        wifiSection.lastError = "";
        wifiSection.hidePasswordDialogReq();
        wifiConnectProc.targetSsid = ssid_;
        wifiConnectProc.command = ["nmcli", "--wait", "30", "dev", "wifi", "connect", ssid_, "password", password];
        wifiConnectProc.running = true;
    }

    Process {
        id: wifiDeviceProc
        command: ["nmcli", "-t", "-f", "device,type", "dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                const hasWifi = this.text.trim().split("\n").some(line => {
                    const colon = line.lastIndexOf(":");
                    return colon >= 0 && line.slice(colon + 1).trim() === "wifi";
                });
                wifiSection.hasWifiDevice = hasWifi;
                if (hasWifi) {
                    wifiSavedProc.running = true;
                    if (!wifiSection.wifiReady) {
                        // On startup, check radio state first so enabled/disabled
                        // is correct before deciding whether to scan.
                        wifiRadioProc.running = true;
                    } else {
                        // Subsequent calls (from monitor/poll): normal immediate refresh.
                        wifiProc.running = true;
                    }
                }
            }
        }
    }

    Process {
        id: wifiToggleProc
        onExited: {
            wifiRadioProc.running = true;
        }
    }

    Process {
        id: wifiRadioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                wifiSection.enabled = this.text.trim() === "enabled";
                if (wifiSection.enabled) {
                    wifiSection.networks = [];
                    wifiSection.strength = -1;
                    wifiSection.noActiveCount = 0;
                    wifiSection.wifiScanning = true;
                    wifiEnableDelayTimer.restart();
                } else {
                    wifiSection.networks = [];
                    wifiSection.strength = -1;
                    wifiSection.noActiveCount = 2;
                    wifiProc.running = true;
                }
            }
        }
    }

    Timer {
        id: wifiEnableDelayTimer
        interval: 1500
        repeat: false
        onTriggered: {
            wifiProc.scanForReal = true;
            wifiProc.running = true;
        }
    }

    Process {
        id: wifiMonitor
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.trim() !== "" && !wifiSection.wifiScanning) {
                    // wifiDeviceProc will fire wifiProc itself in the post-ready path
                    wifiDeviceProc.running = true;
                    wifiSavedProc.running = true;
                }
            }
        }

        onExited: Qt.callLater(() => {
            wifiMonitor.running = true;
        })
    }

    Timer {
        id: wifiPollTimer
        interval: 10000
        repeat: true
        running: true
        onTriggered: if (!wifiSection.wifiScanning)
            wifiProc.running = true
    }

    Process {
        id: wifiSavedProc
        command: ["nmcli", "-t", "-f", "name,type", "con", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const saved = {};
                for (const line of this.text.trim().split("\n")) {
                    if (!line)
                        continue;
                    const colon = line.lastIndexOf(":");
                    if (colon < 0)
                        continue;
                    const type = line.slice(colon + 1).trim();
                    if (type === "802-11-wireless") {
                        const name = line.slice(0, colon);
                        saved[name] = true;
                    }
                }
                wifiSection.savedSsids = saved;
            }
        }
    }

    Process {
        id: wifiProc
        command: ["nmcli", "-t", "-f", "ssid,signal,active", "dev", "wifi"]

        property bool scanForReal: false

        stdout: StdioCollector {
            onStreamFinished: {
                if (wifiSection.wifiScanning && !wifiProc.scanForReal) {
                    return;
                }

                wifiProc.scanForReal = false;
                wifiSection.wifiScanning = false;

                const seen = {};
                const nets = [];

                for (const line of this.text.trim().split("\n")) {
                    if (!line)
                        continue;
                    const lastColon = line.lastIndexOf(":");
                    const secondLastColon = line.lastIndexOf(":", lastColon - 1);
                    const active = line.slice(lastColon + 1) === "yes";
                    const signal = parseInt(line.slice(secondLastColon + 1, lastColon));
                    const ssid_ = line.slice(0, secondLastColon);
                    if (!ssid_)
                        continue;
                    const existing = nets.findIndex(n => n.ssid === ssid_);
                    if (existing >= 0) {
                        const prev = nets[existing];
                        if (active && !prev.active)
                            nets[existing] = {
                                ssid: ssid_,
                                signal,
                                active
                            };
                        else if (!active && !prev.active && signal > prev.signal)
                            nets[existing] = {
                                ssid: ssid_,
                                signal,
                                active
                            };
                    } else {
                        nets.push({
                            ssid: ssid_,
                            signal,
                            active
                        });
                    }
                    seen[ssid_] = true;
                }
                nets.sort((a, b) => b.signal - a.signal);
                wifiSection.networks = nets;
                const cur = nets.find(n => n.active);
                if (cur) {
                    wifiSection.noActiveCount = 0;
                    wifiSection.ssid = cur.ssid;
                    wifiSection.strength = cur.signal;
                } else {
                    wifiSection.noActiveCount++;
                    if (wifiSection.noActiveCount >= 2) {
                        wifiSection.ssid = "";
                        wifiSection.strength = -1;
                    }
                }

                if (!wifiSection.wifiReady) {
                    wifiSection.prevSsid = wifiSection.ssid;
                    wifiSection.wifiReady = true;
                }
            }
        }
    }

    Process {
        id: wifiConnectProc
        property string targetSsid: ""
        property string stdoutText: ""
        property string stderrText: ""

        stdout: StdioCollector {
            onStreamFinished: wifiConnectProc.stdoutText = this.text
        }
        stderr: StdioCollector {
            onStreamFinished: wifiConnectProc.stderrText = this.text
        }

        onExited: code => {
            const ssid_ = wifiConnectProc.targetSsid;
            const errText = (wifiConnectProc.stderrText + wifiConnectProc.stdoutText).toLowerCase();

            if (code === 0) {
                wifiSection.lastConnected = ssid_;
                wifiSection.lastError = "";
                wifiSection.connecting = "";
                wifiConnectedNotifyProc.command = ["notify-send", "--app-name=Wi-Fi", "--app-icon=network-wireless-symbolic", "Wi-Fi Connected", "Connected to " + ssid_];
                wifiConnectedNotifyProc.running = true;
                wifiProc.running = true;
            } else if (errText.includes("secrets") || errText.includes("password") || errText.includes("no-secrets")) {
                wifiSection.connecting = "";
                wifiSection.keepAliveReq();
                wifiSection.showPasswordDialogReq(ssid_);
            } else {
                wifiSection.connecting = "";
                wifiSection.lastError = ssid_;
                wifiSection.lastConnected = "";
                wifiFailedNotifyProc.command = ["notify-send", "--app-name=Wi-Fi", "--app-icon=network-wireless-offline-symbolic", "Wi-Fi Failed", "Could not connect to " + ssid_];
                wifiFailedNotifyProc.running = true;
                wifiProc.running = true;
            }
            wifiConnectProc.stdoutText = "";
            wifiConnectProc.stderrText = "";
        }
    }

    Process {
        id: wifiConnectedNotifyProc
    }

    Process {
        id: wifiFailedNotifyProc
    }

    Process {
        id: wifiDisconnectedNotifyProc
    }

    Process {
        id: wifiDisconnectProc
        onExited: wifiProc.running = true
    }

    property int connectAnimStep: 0
    Timer {
        id: connectAnimTimer
        interval: 350
        repeat: true
        running: wifiSection.connecting !== "" || wifiSection.wifiScanning
        onRunningChanged: {
            if (!running)
                wifiSection.connectAnimStep = 0;
            else
                wifiSection.connectAnimStep = 0;
        }
        onTriggered: {
            wifiSection.connectAnimStep = (wifiSection.connectAnimStep + 1) % 4;
        }
    }

    MouseArea {
        id: triggerArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: wifiSection.openPopupReq("wifi")
        onExited: wifiSection.keepPopupReq()
        onClicked: {
            wifiSection.toggleWifi();
        }
    }

    BarButton {
        anchors.fill: parent
        hovered: triggerArea.containsMouse
        popupOpen: wifiSection.popupOpen

        IconImage {
            anchors.centerIn: parent
            implicitSize: Config.bar.batteryIconSize
            source: Quickshell.iconPath(wifiSection.barIcon)
            opacity: wifiSection.enabled ? 1.0 : Config.bar.disabledOpacity
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    BarSectionPopup {
        id: wifiPopup
        popupOpen: wifiSection.popupOpen

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        availableHeight: wifiSection.availableHeight - wifiSection.height - Config.bar.popupOffset

        emptyText: !wifiSection.enabled ? "Wi-Fi is off" : "Scanning\u2026"

        availableItems: wifiSection.networks.filter(n => !n.active).map(n => ({
                    label: n.ssid,
                    icon: wifiSection.icon(n.signal),
                    saved: !!wifiSection.savedSsids[n.ssid]
                }))

        connectedItems: wifiSection.networks.filter(n => n.active).map(n => ({
                    label: n.ssid,
                    icon: wifiSection.icon(n.signal),
                    saved: true
                }))

        onHoverOpen: wifiSection.openPopupReq("wifi")
        onHoverExit: wifiSection.exitPopupReq()

        onAvailableClicked: index => {
            const nets = wifiSection.networks.filter(n => !n.active);
            const net = nets[index];
            if (net && wifiSection.connecting === "") {
                wifiSection.lastError = "";
                wifiSection.connectWifi(net.ssid);
            }
            wifiSection.openPopupReq("wifi");
        }

        onConnectedClicked: index => {
            wifiSection.openPopupReq("wifi");
            const nets = wifiSection.networks.filter(n => n.active);
            const net = nets[index];
            if (net) {
                wifiDisconnectProc.command = ["nmcli", "con", "down", "id", net.ssid];
                wifiDisconnectProc.running = true;
            }
        }
    }
}
