pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

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

    // ── State ─────────────────────────────────────────────────────────────────

    property string ssid: ""
    property int strength: -1
    property var networks: []
    property string connecting: ""      // SSID being connected to
    property bool enabled: true
    property string lastConnected: ""   // SSID of last successful connection
    property string lastError: ""       // last connection error message

    // Track previous SSID to detect disconnections
    property string prevSsid: ""
    property bool wifiReady: false

    Component.onCompleted: Qt.callLater(() => { wifiSection.wifiReady = true; })

    onSsidChanged: {
        if (!wifiSection.wifiReady)
            return;
        const prev = wifiSection.prevSsid;
        const cur = wifiSection.ssid;
        // Disconnected (not due to us connecting to something else)
        if (prev !== "" && cur === "" && wifiSection.connecting === "") {
            wifiNotifyProc.command = [
                "notify-send",
                "--app-name=Wi-Fi",
                "--app-icon=network-wireless-offline-symbolic",
                "Wi-Fi Disconnected",
                "Disconnected from " + prev
            ];
            wifiNotifyProc.running = true;
        }
        wifiSection.prevSsid = cur;
    }

    // ── Geometry (match pill row) ─────────────────────────────────────────────

    implicitWidth: wifiRow.implicitWidth
    implicitHeight: wifiRow.implicitHeight

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
                if (wifiSection.enabled)
                    wifiProc.running = true;
                else {
                    wifiSection.networks = [];
                    wifiSection.ssid = "";
                    wifiSection.strength = -1;
                }
            }
        }
    }

    Timer {
        id: wifiPollTimer
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: wifiProc.running = true
    }

    Process {
        id: wifiProc
        command: ["nmcli", "-t", "-f", "ssid,signal,active", "dev", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const nets = [];
                for (const line of this.text.trim().split("\n")) {
                    if (!line)
                        continue;
                    const lastColon = line.lastIndexOf(":");
                    const secondLastColon = line.lastIndexOf(":", lastColon - 1);
                    const active = line.slice(lastColon + 1);
                    const signal = parseInt(line.slice(secondLastColon + 1, lastColon));
                    const ssid_ = line.slice(0, secondLastColon);
                    if (!ssid_)
                        continue;
                    if (!seen[ssid_] || seen[ssid_] < signal) {
                        seen[ssid_] = signal;
                        const existing = nets.findIndex(n => n.ssid === ssid_);
                        const entry = {
                            ssid: ssid_,
                            signal,
                            active: active === "yes"
                        };
                        if (existing >= 0)
                            nets[existing] = entry;
                        else
                            nets.push(entry);
                    }
                }
                nets.sort((a, b) => b.signal - a.signal);
                wifiSection.networks = nets;
                const cur = nets.find(n => n.active);
                if (cur) {
                    wifiSection.ssid = cur.ssid;
                    wifiSection.strength = cur.signal;
                } else {
                    wifiSection.ssid = "";
                    wifiSection.strength = -1;
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
                wifiNotifyProc.command = [
                    "notify-send",
                    "--app-name=Wi-Fi",
                    "--app-icon=network-wireless-symbolic",
                    "Wi-Fi Connected",
                    "Connected to " + ssid_
                ];
                wifiNotifyProc.running = true;
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
                wifiNotifyProc.command = [
                    "notify-send",
                    "--app-name=Wi-Fi",
                    "--app-icon=network-wireless-offline-symbolic",
                    "Wi-Fi Failed",
                    "Could not connect to " + ssid_
                ];
                wifiNotifyProc.running = true;
                wifiProc.running = true;
            }
            wifiConnectProc.stdoutText = "";
            wifiConnectProc.stderrText = "";
        }
    }

    Process {
        id: wifiNotifyProc
    }

    // ── Trigger ───────────────────────────────────────────────────────────────

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: wifiSection.openPopupReq("wifi")
        onExited: wifiSection.keepPopupReq()
        onClicked: {
            wifiSection.toggleWifi();
        }
    }

    RowLayout {
        id: wifiRow
        spacing: Math.round(6 * Config.scale)

        IconImage {
            implicitSize: Config.bar.batteryIconSize
            source: Quickshell.iconPath(wifiSection.icon(wifiSection.strength))
            opacity: wifiSection.enabled ? 1.0 : Config.bar.disabledOpacity
            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
        }
    }

    // ── Popup ─────────────────────────────────────────────────────────────────

    Rectangle {
        id: wifiPopup
        visible: opacity > 0
        opacity: wifiSection.popupOpen ? 1 : 0
        scale: wifiSection.popupOpen ? 1 : 0.90
        transformOrigin: Item.Bottom

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.InOutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 0.5 }
        }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        // Width tracks the widest network row (implicitWidth of the column),
        // plus flickable margins (8+4) and scrollbar track+gap (3+3) = 18 units.
        // Floor at 200, cap at 400.
        width: Math.min(
            Math.round(400 * Config.scale),
            Math.max(
                Math.round(200 * Config.scale),
                wifiListCol.implicitWidth + Math.round(18 * Config.scale)
            )
        )
        Behavior on width {
            NumberAnimation { duration: 150; easing.type: Easing.InOutCubic }
        }
        height: Math.min(
            wifiListCol.implicitHeight + Math.round(16 * Config.scale),
            Math.round(400 * Config.scale)
        )

        radius: Math.round(Config.bar.popupRadius * Config.scale)
        // Glassmorphic gradient fill
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.rgba(0.16, 0.14, 0.28, 0.97) }
            GradientStop { position: 1.0; color: Qt.rgba(0.09, 0.08, 0.18, 0.93) }
        }
        border.color: Config.colors.border
        border.width: 1
        z: 20
        clip: true

        // Top shine
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            radius: parent.radius
            color: "#28ffffff"
        }

        // Drop shadow blob
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: -Math.round(6 * Config.scale)
            width: parent.width * 0.75
            height: Math.round(18 * Config.scale)
            radius: height / 2
            color: Config.colors.shadowDark
            opacity: 0.8
            z: -1
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    wifiSection.openPopupReq("wifi");
                else
                    wifiSection.exitPopupReq();
            }
        }

        // ── Scrollable network list ────────────────────────────────────────

        Flickable {
            id: wifiFlickable
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.right: wifiScrollbar.left
            anchors.topMargin: Math.round(8 * Config.scale)
            anchors.bottomMargin: Math.round(8 * Config.scale)
            anchors.leftMargin: Math.round(8 * Config.scale)
            anchors.rightMargin: Math.round(4 * Config.scale)
            contentWidth: wifiListCol.implicitWidth
            contentHeight: wifiListCol.implicitHeight
            clip: true

            Column {
                id: wifiListCol
                spacing: Math.round(2 * Config.scale)

                // ── Empty-state placeholder ───────────────────────────────
                Text {
                    text: !wifiSection.enabled ? "Wi-Fi is off" : "Scanning\u2026"
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizeStatus
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: Math.round(8 * Config.scale)
                    bottomPadding: Math.round(8 * Config.scale)
                    leftPadding: Math.round(16 * Config.scale)
                    rightPadding: Math.round(16 * Config.scale)
                    visible: wifiSection.networks.length === 0
                }

                Repeater {
                    model: wifiSection.networks
                    delegate: Rectangle {
                        id: wifiEntry
                        required property var modelData
                        readonly property bool isActive: modelData.active
                        readonly property bool isConnecting: wifiSection.connecting === modelData.ssid
                        readonly property bool hadError: wifiSection.lastError === modelData.ssid

                        width: wifiEntryRow.implicitWidth + Math.round(16 * Config.scale)
                        implicitHeight: wifiEntryRow.implicitHeight + Math.round(8 * Config.scale)
                        radius: Math.round(6 * Config.scale)
                        color: isActive
                               ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18)
                               : hadError
                                 ? Qt.rgba(1, 0.3, 0.3, 0.12)
                                 : wifiEntryMouse.containsMouse
                                   ? Qt.rgba(1, 1, 1, 0.07)
                                   : "transparent"
                        Behavior on color {
                            ColorAnimation { duration: 80 }
                        }

                        RowLayout {
                            id: wifiEntryRow
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: Math.round(8 * Config.scale)
                            spacing: Math.round(8 * Config.scale)

                            IconImage {
                                implicitSize: Config.bar.fontSizeStatus + Math.round(4 * Config.scale)
                                source: Quickshell.iconPath(wifiSection.icon(wifiEntry.modelData.signal))
                            }

                            Text {
                                text: wifiEntry.modelData.ssid
                                color: wifiEntry.isActive
                                       ? Config.colors.accent
                                       : wifiEntry.hadError
                                         ? "#ff6666"
                                         : Config.colors.textPrimary
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizeStatus
                            }

                            // Status indicator: spinner, check, error
                            Text {
                                text: wifiEntry.isConnecting
                                      ? "\u2026"
                                      : wifiEntry.isActive
                                        ? "\u2713"
                                        : wifiEntry.hadError
                                          ? "\u00d7"
                                          : ""
                                color: wifiEntry.hadError ? "#ff6666" : Config.colors.accent
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizeStatus
                                visible: wifiEntry.isActive || wifiEntry.isConnecting || wifiEntry.hadError
                            }
                        }

                        MouseArea {
                            id: wifiEntryMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: wifiSection.openPopupReq("wifi")
                            onClicked: {
                                if (!wifiEntry.isActive && !wifiEntry.isConnecting) {
                                    wifiSection.lastError = "";
                                    wifiSection.connectWifi(wifiEntry.modelData.ssid);
                                }
                                wifiSection.openPopupReq("wifi");
                            }
                        }
                    }
                }
            }
        }

        // Scrollbar
        Item {
            id: wifiScrollbar
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: Math.round(8 * Config.scale)
            anchors.bottomMargin: Math.round(8 * Config.scale)
            anchors.rightMargin: Math.round(3 * Config.scale)
            width: Math.round(3 * Config.scale)

            readonly property bool needed: wifiFlickable.contentHeight > wifiFlickable.height
            visible: needed

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Config.colors.border
            }

            Rectangle {
                readonly property real ratio: wifiFlickable.height / Math.max(wifiFlickable.contentHeight, 1)
                readonly property real thumbH: Math.max(Math.round(20 * Config.scale), wifiScrollbar.height * ratio)
                readonly property real travel: wifiScrollbar.height - thumbH
                readonly property real scrollRatio: wifiFlickable.contentHeight > wifiFlickable.height
                                                    ? wifiFlickable.contentY / (wifiFlickable.contentHeight - wifiFlickable.height)
                                                    : 0

                width: parent.width
                height: thumbH
                y: travel * scrollRatio
                radius: width / 2
                color: Config.colors.textMuted
                Behavior on y {
                    NumberAnimation { duration: 60 }
                }
            }
        }
    }
}
