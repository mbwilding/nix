pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "components"

// Wifi bar section: trigger icon + dropdown popup listing nearby networks.
//
// Clicking the bar icon toggles Wi-Fi on/off.
// Bar.qml binds activePopup and wires the three popup-manager signals.
Item {
    id: wifiSection

    // ── Public API ────────────────────────────────────────────────────────────

    property string activePopup: ""     // bound to root.activePopup

    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq
    signal keepAliveReq
    signal showPasswordDialogReq(string ssid_)   // ask Bar to show the overlay
    signal hidePasswordDialogReq                 // ask Bar to hide the overlay

    // Expose the popup rectangle so Bar.qml can include it in the input mask
    property alias popup: wifiPopup

    // ── Public API (sizing) ───────────────────────────────────────────────────

    // Screen height passed in from Bar.qml so the popup can cap itself.
    property real availableHeight: 800

    // ── State ─────────────────────────────────────────────────────────────────

    property string ssid: ""
    property int strength: -1
    property var networks: []
    property string connecting: ""      // SSID being connected to
    property bool enabled: true
    property string lastConnected: ""   // SSID of last successful connection
    property string lastError: ""       // last connection error message
    property var savedSsids: ({})       // set of SSIDs with saved NM connections

    // Track previous SSID to detect disconnections
    property string prevSsid: ""
    property bool wifiReady: false
    // True while wifi was just re-enabled and we're waiting to scan.
    // Suppresses wifiMonitor and wifiProc updates until we're ready.
    property bool wifiScanning: false
    // Consecutive wifiProc results showing no active network.
    // We require 2 in a row before clearing ssid, to avoid spurious
    // disconnect notifications from transient nmcli scan glitches.
    property int noActiveCount: 0

    Component.onCompleted: {
        wifiProc.running = true;
        wifiSavedProc.running = true;
    }

    onSsidChanged: {
        if (!wifiSection.wifiReady)
            return;
        const prev = wifiSection.prevSsid;
        const cur = wifiSection.ssid;
        if (prev !== "" && cur === "" && wifiSection.connecting === "") {
            wifiDisconnectedNotifyProc.command = [
                "notify-send",
                "--app-name=Wi-Fi",
                "--app-icon=network-wireless-offline-symbolic",
                "Wi-Fi Disconnected",
                "Disconnected from " + prev
            ];
            wifiDisconnectedNotifyProc.running = true;
        } else if (cur !== "" && prev === "" && wifiSection.connecting === ""
                   && cur !== wifiSection.lastConnected) {
            // Auto-reconnect (e.g. re-enabling wifi) — not handled by wifiConnectProc.
            // Skip if wifiConnectProc just handled this SSID to avoid a double notification.
            wifiConnectedNotifyProc.command = [
                "notify-send",
                "--app-name=Wi-Fi",
                "--app-icon=network-wireless-symbolic",
                "Wi-Fi Connected",
                "Connected to " + cur
            ];
            wifiConnectedNotifyProc.running = true;
        } else if (cur !== "" && prev === "" && wifiSection.connecting === ""
                   && cur === wifiSection.lastConnected) {
            // wifiConnectProc already notified — clear the guard so future
            // auto-reconnects to the same SSID do fire a notification.
            wifiSection.lastConnected = "";
        }
        wifiSection.prevSsid = cur;
    }

    // ── Geometry (match pill row) ─────────────────────────────────────────────

    implicitWidth: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    implicitHeight: Config.bar.batteryIconSize + Math.round(10 * Config.scale)

    containmentMask: Item {
        x: wifiSection.popupOpen ? -Math.max(0, (wifiPopup.width - wifiSection.width) / 2) : 0
        y: wifiSection.popupOpen ? -wifiPopup.height - Config.bar.popupOffset : 0
        width: wifiSection.popupOpen ? Math.max(wifiSection.width, wifiPopup.width) : wifiSection.width
        height: wifiSection.popupOpen ? wifiPopup.height + Config.bar.popupOffset + wifiSection.height : wifiSection.height
    }

    readonly property bool popupOpen: activePopup === "wifi"

    // ── Helpers ───────────────────────────────────────────────────────────────

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

    readonly property var connectAnimIcons: [
        "network-wireless-signal-weak-symbolic",
        "network-wireless-signal-ok-symbolic",
        "network-wireless-signal-good-symbolic",
        "network-wireless-signal-excellent-symbolic"
    ]
    readonly property string barIcon: (wifiSection.connecting !== "" || wifiSection.wifiScanning)
        ? wifiSection.connectAnimIcons[wifiSection.connectAnimStep]
        : wifiSection.icon(wifiSection.strength)

    function toggleWifi() {
        wifiToggleProc.command = ["nmcli", "radio", "wifi", wifiSection.enabled ? "off" : "on"];
        wifiToggleProc.running = true;
    }

    // Try connecting: first attempt without password (uses saved credentials).
    // If nmcli exits non-zero and output contains "secrets", show password dialog.
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

    // ── Processes ─────────────────────────────────────────────────────────────

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
                    // Clear stale visual state immediately.
                    wifiSection.networks = [];
                    wifiSection.strength = -1;
                    wifiSection.noActiveCount = 0;
                    // Enter scanning state: suppresses wifiMonitor/wifiProc updates
                    // until the delay timer fires, preventing stale cached NM data
                    // from briefly showing full signal.
                    wifiSection.wifiScanning = true;
                    wifiEnableDelayTimer.restart();
                } else {
                    // Let wifiProc run so ssid transitions through "" via onSsidChanged,
                    // which is needed to fire the disconnect notification correctly.
                    wifiSection.networks = [];
                    wifiSection.strength = -1;
                    wifiSection.noActiveCount = 2; // force immediate clear on disable
                    wifiProc.running = true;
                }
            }
        }
    }

    // Short delay after re-enabling wifi before the first scan, so NM has
    // time to reflect actual state (scanning) rather than stale cached data.
    // wifiScanning stays true until that specific wifiProc run completes.
    Timer {
        id: wifiEnableDelayTimer
        interval: 1500
        repeat: false
        onTriggered: {
            wifiProc.scanForReal = true;
            wifiProc.running = true;
        }
    }

    // ── nmcli monitor — event-driven state refresh ─────────────────────────
    // Fires one line per NetworkManager event; we re-run wifiProc on each one.
    // This replaces the 5-second poll for connection state changes.
    Process {
        id: wifiMonitor
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.trim() !== "" && !wifiSection.wifiScanning) {
                    wifiProc.running = true;
                    wifiSavedProc.running = true;
                }
            }
        }
        // Restart monitor if it unexpectedly exits
        onExited: Qt.callLater(() => { wifiMonitor.running = true; })
    }

    // Slow background poll (30 s) to keep signal-strength bars fresh.
    // Connection state changes are handled immediately by wifiMonitor above.
    Timer {
        id: wifiPollTimer
        interval: 10000
        repeat: true
        running: true
        onTriggered: if (!wifiSection.wifiScanning) wifiProc.running = true
    }

    // Fetches the set of SSIDs that have a saved NM connection profile.
    // Output: one "name:type" line per connection; we keep wireless ones.
    Process {
        id: wifiSavedProc
        command: ["nmcli", "-t", "-f", "name,type", "con", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const saved = {};
                for (const line of this.text.trim().split("\n")) {
                    if (!line) continue;
                    const colon = line.lastIndexOf(":");
                    if (colon < 0) continue;
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
        // Set true by wifiEnableDelayTimer to identify the post-delay scan.
        property bool scanForReal: false
        stdout: StdioCollector {
            onStreamFinished: {
                // While scanning (waiting for post-enable delay), drop all results
                // except the one explicitly triggered by wifiEnableDelayTimer.
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
                        // Always keep the active entry; otherwise keep the higher signal.
                        if (active && !prev.active)
                            nets[existing] = { ssid: ssid_, signal, active };
                        else if (!active && !prev.active && signal > prev.signal)
                            nets[existing] = { ssid: ssid_, signal, active };
                    } else {
                        nets.push({ ssid: ssid_, signal, active });
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
                    // Only clear ssid after 2 consecutive empty results, to avoid
                    // spurious disconnect notifications from transient nmcli glitches.
                    if (wifiSection.noActiveCount >= 2) {
                        wifiSection.ssid = "";
                        wifiSection.strength = -1;
                    }
                }
                // Mark ready after first result so onSsidChanged can start
                // firing notifications. prevSsid is now in sync with ssid.
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
                // Success
                wifiSection.lastConnected = ssid_;
                wifiSection.lastError = "";
                wifiSection.connecting = "";
                wifiConnectedNotifyProc.command = [
                    "notify-send",
                    "--app-name=Wi-Fi",
                    "--app-icon=network-wireless-symbolic",
                    "Wi-Fi Connected",
                    "Connected to " + ssid_
                ];
                wifiConnectedNotifyProc.running = true;
                wifiProc.running = true;
            } else if (errText.includes("secrets") || errText.includes("password") || errText.includes("no-secrets")) {
                // Password required
                wifiSection.connecting = "";
                wifiSection.keepAliveReq();
                wifiSection.showPasswordDialogReq(ssid_);
            } else {
                // Other failure
                wifiSection.connecting = "";
                wifiSection.lastError = ssid_;
                wifiSection.lastConnected = "";
                wifiFailedNotifyProc.command = [
                    "notify-send",
                    "--app-name=Wi-Fi",
                    "--app-icon=network-wireless-offline-symbolic",
                    "Wi-Fi Failed",
                    "Could not connect to " + ssid_
                ];
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

    // Cycles 0–3 while connecting or scanning to animate the bar icon signal bars
    property int connectAnimStep: 0
    Timer {
        id: connectAnimTimer
        interval: 350
        repeat: true
        running: wifiSection.connecting !== "" || wifiSection.wifiScanning
        onRunningChanged: {
            if (!running) wifiSection.connectAnimStep = 0;
            else wifiSection.connectAnimStep = 0;
        }
        onTriggered: {
            wifiSection.connectAnimStep = (wifiSection.connectAnimStep + 1) % 4;
        }
    }

    // ── Trigger ───────────────────────────────────────────────────────────────

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
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
        }
    }

    // ── Popup ─────────────────────────────────────────────────────────────────

    BarSectionPopup {
        id: wifiPopup
        popupOpen: wifiSection.popupOpen

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        availableHeight: wifiSection.availableHeight
                         - wifiSection.height
                         - Config.bar.popupOffset

        emptyText: !wifiSection.enabled ? "Wi-Fi is off" : "Scanning\u2026"

        availableItems: wifiSection.networks
            .filter(n => !n.active)
            .map(n => ({ label: n.ssid, icon: wifiSection.icon(n.signal), saved: !!wifiSection.savedSsids[n.ssid] }))

        connectedItems: wifiSection.networks
            .filter(n => n.active)
            .map(n => ({ label: n.ssid, icon: wifiSection.icon(n.signal), saved: true }))

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

        onConnectedClicked: {
            wifiSection.openPopupReq("wifi");
            wifiDisconnectProc.command = ["nmcli", "dev", "disconnect", "wlan0"];
            wifiDisconnectProc.running = true;
        }
    }
}
