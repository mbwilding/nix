pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

// Wifi bar section: trigger icon + dropdown popup listing nearby networks.
//
// Bar.qml binds activePopup and wires the three popup-manager signals.
Item {
    id: wifiSection

    // ── Public API ────────────────────────────────────────────────────────────

    property string activePopup: ""     // bound to root.activePopup

    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq
    signal keepAliveReq

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

    // Password dialog state
    property string pendingSsid: ""     // SSID awaiting password entry
    property bool showPasswordDialog: false

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
        wifiSection.showPasswordDialog = false;
        wifiSection.pendingSsid = "";
        wifiConnectProc.targetSsid = ssid_;
        wifiConnectProc.command = ["nmcli", "--wait", "30", "dev", "wifi", "connect", ssid_, "password", password];
        wifiConnectProc.running = true;
    }

    // Width metric for popup — computed from longest SSID
    TextMetrics {
        id: wifiTextMetrics
        font.family: Config.font.family
        font.pixelSize: Config.bar.fontSizeStatus
    }

    property int popupWidth: Math.round(240 * Config.scale)

    function recomputePopupWidth() {
        const nets = wifiSection.networks;
        const iconW = Config.bar.fontSizeStatus + Math.round(4 * Config.scale);
        const checkW = Config.bar.fontSizeStatus;
        const margins = Math.round(8 * Config.scale) * 6;
        let maxSsidW = Math.round(140 * Config.scale);
        for (let i = 0; i < nets.length; i++) {
            wifiTextMetrics.text = nets[i].ssid;
            if (wifiTextMetrics.boundingRect.width > maxSsidW)
                maxSsidW = wifiTextMetrics.boundingRect.width;
        }
        wifiSection.popupWidth = Math.min(Math.round(400 * Config.scale), iconW + maxSsidW + checkW + margins);
    }

    onNetworksChanged: recomputePopupWidth()

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
                wifiSection.pendingSsid = ssid_;
                wifiSection.showPasswordDialog = true;
                wifiSection.keepAliveReq();
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
            wifiSection.openPopupReq("wifi");
        }
    }

    RowLayout {
        id: wifiRow
        spacing: Math.round(6 * Config.scale)

        IconImage {
            implicitSize: Config.bar.batteryIconSize
            source: Quickshell.iconPath(wifiSection.icon(wifiSection.strength))
        }
    }

    // ── Popup ─────────────────────────────────────────────────────────────────

    Rectangle {
        id: wifiPopup
        visible: opacity > 0
        opacity: wifiSection.popupOpen ? 1 : 0
        scale: wifiSection.popupOpen ? 1 : 0.92
        transformOrigin: Item.Bottom

        Behavior on opacity {
            NumberAnimation {
                duration: 120
                easing.type: Easing.InOutQuad
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.InOutQuad
            }
        }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        width: wifiSection.showPasswordDialog ? Math.max(wifiSection.popupWidth, Math.round(260 * Config.scale)) : wifiSection.popupWidth
        height: wifiSection.showPasswordDialog
                ? Math.round(200 * Config.scale)
                : Math.min(wifiPopupCol.implicitHeight + Math.round(16 * Config.scale), Math.round(400 * Config.scale))

        radius: Math.round(10 * Config.scale)
        color: Config.colors.background
        border.color: Config.colors.border
        border.width: 1
        z: 20
        clip: true

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    wifiSection.openPopupReq("wifi");
                else
                    wifiSection.exitPopupReq();
            }
        }

        // ── Content column (toggle + divider + network list) ───────────────

        Column {
            id: wifiPopupCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Math.round(8 * Config.scale)
            anchors.leftMargin: Math.round(8 * Config.scale)
            anchors.rightMargin: Math.round(8 * Config.scale)
            spacing: Math.round(4 * Config.scale)

            // ── Enable / disable toggle row ────────────────────────────────
            Rectangle {
                width: wifiPopupCol.width
                implicitHeight: wifiToggleRow.implicitHeight + Math.round(8 * Config.scale)
                radius: Math.round(6 * Config.scale)
                color: wifiToggleMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
                Behavior on color {
                    ColorAnimation { duration: 80 }
                }

                RowLayout {
                    id: wifiToggleRow
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Math.round(8 * Config.scale)
                    anchors.rightMargin: Math.round(8 * Config.scale)
                    spacing: Math.round(8 * Config.scale)

                    IconImage {
                        implicitSize: Config.bar.fontSizeStatus + Math.round(4 * Config.scale)
                        source: Quickshell.iconPath(wifiSection.enabled ? "network-wireless-symbolic" : "network-wireless-offline-symbolic")
                    }

                    Text {
                        Layout.fillWidth: true
                        text: wifiSection.enabled ? "Wi-Fi On" : "Wi-Fi Off"
                        color: Config.colors.textPrimary
                        font.family: Config.font.family
                        font.pixelSize: Config.bar.fontSizeStatus
                    }

                    // Pill toggle switch
                    Rectangle {
                        implicitWidth: Math.round(36 * Config.scale)
                        implicitHeight: Math.round(18 * Config.scale)
                        radius: implicitHeight / 2
                        color: wifiSection.enabled ? Config.colors.accent : Config.colors.border
                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        Rectangle {
                            width: Math.round(12 * Config.scale)
                            height: Math.round(12 * Config.scale)
                            radius: width / 2
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                            x: wifiSection.enabled
                               ? parent.width - width - Math.round(3 * Config.scale)
                               : Math.round(3 * Config.scale)
                            Behavior on x {
                                NumberAnimation { duration: 120; easing.type: Easing.InOutQuad }
                            }
                        }
                    }
                }

                MouseArea {
                    id: wifiToggleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: wifiSection.openPopupReq("wifi")
                    onClicked: {
                        wifiSection.toggleWifi();
                        wifiSection.openPopupReq("wifi");
                    }
                }
            }

            // ── Separator ─────────────────────────────────────────────────
            Rectangle {
                width: wifiPopupCol.width
                implicitHeight: 1
                color: Config.colors.border
                visible: wifiSection.enabled
            }

            // ── Network list (only when enabled) ──────────────────────────
            Item {
                width: wifiPopupCol.width
                // Height is the scrollable area, capped so total popup ≤ 400
                height: Math.min(
                    wifiListCol.implicitHeight,
                    Math.round(400 * Config.scale)
                        - (wifiToggleRow.implicitHeight + Math.round(8 * Config.scale))
                        - Math.round(1 * Config.scale)
                        - Math.round(20 * Config.scale)
                )
                visible: wifiSection.enabled
                clip: true

                Flickable {
                    id: wifiFlickable
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.right: wifiScrollbar.left
                    anchors.rightMargin: Math.round(4 * Config.scale)
                    contentWidth: width
                    contentHeight: wifiListCol.implicitHeight
                    clip: true

                    Column {
                        id: wifiListCol
                        width: wifiFlickable.width
                        spacing: Math.round(2 * Config.scale)

                        // ── "No networks" placeholder ─────────────────────
                        Text {
                            width: parent.width
                            text: "Scanning…"
                            color: Config.colors.textMuted
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.fontSizeStatus
                            horizontalAlignment: Text.AlignHCenter
                            topPadding: Math.round(8 * Config.scale)
                            bottomPadding: Math.round(8 * Config.scale)
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

                                width: wifiListCol.width
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
                                    anchors.right: parent.right
                                    anchors.leftMargin: Math.round(8 * Config.scale)
                                    anchors.rightMargin: Math.round(8 * Config.scale)
                                    spacing: Math.round(8 * Config.scale)

                                    IconImage {
                                        implicitSize: Config.bar.fontSizeStatus + Math.round(4 * Config.scale)
                                        source: Quickshell.iconPath(wifiSection.icon(wifiEntry.modelData.signal))
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: wifiEntry.modelData.ssid
                                        color: wifiEntry.isActive
                                               ? Config.colors.accent
                                               : wifiEntry.hadError
                                                 ? "#ff6666"
                                                 : Config.colors.textPrimary
                                        font.family: Config.font.family
                                        font.pixelSize: Config.bar.fontSizeStatus
                                        elide: Text.ElideRight
                                    }

                                    // Status indicator: spinner text, check, error, or signal %
                                    Text {
                                        text: wifiEntry.isConnecting
                                              ? "…"
                                              : wifiEntry.isActive
                                                ? "✓"
                                                : wifiEntry.hadError
                                                  ? "✕"
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

        // ── Password dialog overlay ────────────────────────────────────────

        Rectangle {
            id: passwordOverlay
            anchors.fill: parent
            radius: parent.radius
            color: Config.colors.background
            visible: wifiSection.showPasswordDialog
            z: 10

            HoverHandler {
                onHoveredChanged: {
                    if (hovered)
                        wifiSection.openPopupReq("wifi");
                    else
                        wifiSection.exitPopupReq();
                }
            }

            onVisibleChanged: {
                if (visible) {
                    passwordField.text = "";
                    passwordField.forceActiveFocus();
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Math.round(16 * Config.scale)
                spacing: Math.round(10 * Config.scale)

                Text {
                    Layout.fillWidth: true
                    text: "Connect to"
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizeStatus
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    Layout.fillWidth: true
                    text: wifiSection.pendingSsid
                    color: Config.colors.accent
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizeStatus
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                }

                // Password input field
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(32 * Config.scale)
                    radius: Math.round(6 * Config.scale)
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.color: passwordField.activeFocus ? Config.colors.accent : Config.colors.border
                    border.width: 1
                    Behavior on border.color {
                        ColorAnimation { duration: 100 }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(8 * Config.scale)
                        anchors.rightMargin: Math.round(4 * Config.scale)
                        spacing: Math.round(4 * Config.scale)

                        TextInput {
                            id: passwordField
                            Layout.fillWidth: true
                            color: Config.colors.textPrimary
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.fontSizeStatus
                            echoMode: showPasswordBtn.showPw ? TextInput.Normal : TextInput.Password
                            passwordCharacter: "•"
                            clip: true
                            selectByMouse: true
                            verticalAlignment: TextInput.AlignVCenter

                            // Placeholder
                            Text {
                                anchors.fill: parent
                                text: "Password"
                                color: Config.colors.textMuted
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizeStatus
                                verticalAlignment: Text.AlignVCenter
                                visible: passwordField.text === "" && !passwordField.activeFocus
                            }

                            Keys.onReturnPressed: {
                                if (passwordField.text.length > 0)
                                    wifiSection.connectWifiWithPassword(wifiSection.pendingSsid, passwordField.text);
                            }
                            Keys.onEscapePressed: {
                                wifiSection.showPasswordDialog = false;
                                wifiSection.pendingSsid = "";
                            }
                        }

                        // Show/hide password toggle
                        Rectangle {
                            id: showPasswordBtn
                            property bool showPw: false
                            implicitWidth: Math.round(22 * Config.scale)
                            implicitHeight: Math.round(22 * Config.scale)
                            radius: Math.round(4 * Config.scale)
                            color: showPwMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: showPasswordBtn.showPw ? "🙈" : "👁"
                                font.pixelSize: Math.round(11 * Config.scale)
                            }

                            MouseArea {
                                id: showPwMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: showPasswordBtn.showPw = !showPasswordBtn.showPw
                            }
                        }
                    }
                }

                // Buttons row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(8 * Config.scale)

                    // Cancel
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.round(28 * Config.scale)
                        radius: Math.round(6 * Config.scale)
                        color: cancelMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.05)
                        border.color: Config.colors.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Config.colors.textPrimary
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.fontSizeStatus
                        }

                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                wifiSection.showPasswordDialog = false;
                                wifiSection.pendingSsid = "";
                            }
                        }
                    }

                    // Connect
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.round(28 * Config.scale)
                        radius: Math.round(6 * Config.scale)
                        color: connectMouse.containsMouse
                               ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.35)
                               : Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.2)
                        border.color: Config.colors.accent
                        border.width: 1
                        opacity: passwordField.text.length > 0 ? 1.0 : 0.4

                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            color: Config.colors.accent
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.fontSizeStatus
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: connectMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (passwordField.text.length > 0)
                                    wifiSection.connectWifiWithPassword(wifiSection.pendingSsid, passwordField.text);
                            }
                        }
                    }
                }
            }
        }
    }
}
