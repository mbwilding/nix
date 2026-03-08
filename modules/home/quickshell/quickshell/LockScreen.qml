pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import "components"

// Lock screen using the ext-session-lock-v1 Wayland protocol.
// Lock:   qs ipc call lockscreen lock
// Unlock: qs ipc call lockscreen unlock
Scope {
    id: root

    property var notifHistory: []

    // ── WiFi state ───────────────────────────────────────────────────────────
    property bool wifiEnabled: true
    property int wifiStrength: -1
    property string wifiSsid: ""
    property var wifiNetworks: []

    // ── Bluetooth ────────────────────────────────────────────────────────────
    readonly property var btAdapter: Bluetooth.defaultAdapter

    // ── System battery ───────────────────────────────────────────────────────
    readonly property var sysBattery: UPower.displayDevice

    // ── Volume ───────────────────────────────────────────────────────────────
    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var audio: defaultSink?.audio ?? null

    // ── IPC ──────────────────────────────────────────────────────────────────
    IpcHandler {
        target: "lockscreen"
        function lock()   { sessionLock.locked = true;  }
        function unlock() { sessionLock.locked = false; }
    }

    // ── WiFi polling (only runs while locked) ─────────────────────────────
    Process {
        id: lockWifiMonitor
        command: ["nmcli", "monitor"]
        running: sessionLock.locked
        stdout: SplitParser {
            onRead: line => {
                if (line.trim() !== "") lockWifiProc.running = true;
            }
        }
        onExited: if (sessionLock.locked) Qt.callLater(() => { lockWifiMonitor.running = true; })
    }

    Process {
        id: lockWifiProc
        command: ["nmcli", "-t", "-f", "ssid,signal,active", "dev", "wifi"]
        running: sessionLock.locked
        stdout: StdioCollector {
            onStreamFinished: {
                const nets = [];
                for (const line of this.text.trim().split("\n")) {
                    if (!line) continue;
                    const lastColon = line.lastIndexOf(":");
                    const secondLastColon = line.lastIndexOf(":", lastColon - 1);
                    const active = line.slice(lastColon + 1) === "yes";
                    const signal = parseInt(line.slice(secondLastColon + 1, lastColon));
                    const ssid = line.slice(0, secondLastColon);
                    if (!ssid) continue;
                    const existing = nets.findIndex(n => n.ssid === ssid);
                    if (existing >= 0) {
                        if (active && !nets[existing].active)
                            nets[existing] = { ssid, signal, active };
                        else if (!active && !nets[existing].active && signal > nets[existing].signal)
                            nets[existing] = { ssid, signal, active };
                    } else {
                        nets.push({ ssid, signal, active });
                    }
                }
                nets.sort((a, b) => b.signal - a.signal);
                root.wifiNetworks = nets;
                const cur = nets.find(n => n.active);
                root.wifiSsid    = cur ? cur.ssid   : "";
                root.wifiStrength = cur ? cur.signal : -1;
                lockWifiRadioProc.running = true;
            }
        }
    }

    Process {
        id: lockWifiRadioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = this.text.trim() === "enabled";
            }
        }
    }

    Timer {
        interval: 15000
        repeat: true
        running: sessionLock.locked
        onTriggered: lockWifiProc.running = true
    }

    // ── Helper functions ─────────────────────────────────────────────────────
    function wifiIcon(sig) {
        if (!root.wifiEnabled || sig < 0) return "network-wireless-offline-symbolic";
        if (sig < 25) return "network-wireless-signal-weak-symbolic";
        if (sig < 50) return "network-wireless-signal-ok-symbolic";
        if (sig < 75) return "network-wireless-signal-good-symbolic";
        return "network-wireless-signal-excellent-symbolic";
    }

    function btDeviceName(d) {
        if (!d) return "Unknown";
        return d.name || d.deviceName || d.address || "Unknown";
    }

    function btDeviceIcon(d) {
        if (!d) return "network-bluetooth-symbolic";
        return (d.icon || "") !== "" ? d.icon : "network-bluetooth-symbolic";
    }

    // ── Clock ─────────────────────────────────────────────────────────────────
    SystemClock { id: wallClock; precision: SystemClock.Seconds }

    // ── Session lock ─────────────────────────────────────────────────────────
    WlSessionLock {
        id: sessionLock
        locked: false

        surface: WlSessionLockSurface {
            id: lockSurface

            Item {
                anchors.fill: parent

                // ── Background ────────────────────────────────────────────
                Rectangle {
                    anchors.fill: parent
                    color: "#e8101020"
                }

                // Subtle grid pattern for cyberpunk depth
                Item {
                    anchors.fill: parent
                    opacity: 0.025

                    Repeater {
                        model: Math.ceil(lockSurface.height / 48) + 1
                        delegate: Rectangle {
                            id: hLineD
                            required property int index
                            y: index * 48
                            width: lockSurface.width
                            height: 1
                            color: "#c0aaff"
                        }
                    }

                    Repeater {
                        model: Math.ceil(lockSurface.width / 48) + 1
                        delegate: Rectangle {
                            id: vLineD
                            required property int index
                            x: index * 48
                            width: 1
                            height: lockSurface.height
                            color: "#c0aaff"
                        }
                    }
                }

                // Ambient glow blobs
                Rectangle {
                    x: lockSurface.width * 0.04
                    y: -Math.round(100 * Config.scale)
                    width: Math.round(520 * Config.scale)
                    height: width
                    radius: width / 2
                    color: Qt.rgba(0.75, 0.67, 1.0, 0.055)
                }

                Rectangle {
                    x: lockSurface.width * 0.65
                    y: lockSurface.height * 0.48
                    width: Math.round(400 * Config.scale)
                    height: width
                    radius: width / 2
                    color: Qt.rgba(1.0, 0.62, 0.95, 0.045)
                }

                // ── Main layout ────────────────────────────────────────────
                Item {
                    anchors.fill: parent
                    anchors.margins: Math.round(52 * Config.scale)

                    // ── LEFT: Clock + Notifications ────────────────────────
                    Column {
                        id: leftCol
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.round(450 * Config.scale)
                        spacing: Math.round(30 * Config.scale)

                        // Clock block
                        Column {
                            width: parent.width
                            spacing: Math.round(4 * Config.scale)

                            Text {
                                text: Qt.formatTime(wallClock.time,
                                    Config.bar.clock24h ? "HH:mm" : "hh:mm AP")
                                color: Config.colors.accent
                                font.family: Config.font.family
                                font.pixelSize: Math.round(88 * Config.scale)
                                font.weight: Font.Light
                            }

                            Text {
                                text: Qt.formatDate(wallClock.time, "dddd, MMMM d")
                                color: Config.colors.textSecondary
                                font.family: Config.font.family
                                font.pixelSize: Math.round(20 * Config.scale)
                            }

                            Text {
                                text: Qt.formatDate(wallClock.time, "yyyy")
                                color: Config.colors.textMuted
                                font.family: Config.font.family
                                font.pixelSize: Math.round(13 * Config.scale)
                                opacity: 0.55
                            }

                            // Accent underline
                            Rectangle {
                                width: Math.round(180 * Config.scale)
                                height: Math.round(2 * Config.scale)
                                radius: height / 2
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: Config.colors.accent }
                                    GradientStop { position: 0.55; color: Config.colors.accentAlt }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                            }
                        }

                        // Notifications (view-only, scrollable)
                        Column {
                            width: parent.width
                            spacing: Math.round(8 * Config.scale)
                            visible: root.notifHistory.length > 0

                            // Header row
                            RowLayout {
                                width: parent.width

                                Text {
                                    text: "\uF0F3  Notifications"
                                    color: Config.colors.textMuted
                                    font.family: Config.font.family
                                    font.pixelSize: Math.round(Config.font.sizeSm * 0.85)
                                    font.weight: Font.Medium
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: root.notifHistory.length > 99 ? "99+" : String(root.notifHistory.length)
                                    color: Config.colors.accentAlt
                                    font.family: Config.font.family
                                    font.pixelSize: Math.round(Config.font.sizeSm * 0.8)
                                    font.weight: Font.Bold
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Config.colors.border
                                opacity: 0.4
                            }

                            // Scrollable list
                            Item {
                                id: notifScrollContainer
                                width: parent.width
                                height: Math.min(
                                    notifInnerCol.implicitHeight,
                                    Math.round(380 * Config.scale)
                                )
                                clip: true

                                property real scrollY: 0
                                readonly property real maxScrollY: Math.max(0, notifInnerCol.implicitHeight - notifScrollContainer.height)

                                WheelHandler {
                                    target: null
                                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                    onWheel: event => {
                                        const step = Math.round(36 * Config.scale);
                                        notifScrollContainer.scrollY = Math.max(0,
                                            Math.min(notifScrollContainer.maxScrollY,
                                                notifScrollContainer.scrollY - event.angleDelta.y / 120 * step));
                                    }
                                }

                                Column {
                                    id: notifInnerCol
                                    width: notifScrollContainer.width - Math.round(6 * Config.scale)
                                    spacing: Math.round(6 * Config.scale)
                                    y: -notifScrollContainer.scrollY

                                    Repeater {
                                        model: root.notifHistory
                                        delegate: LockNotificationCard {
                                            id: lockNotifD
                                            required property var modelData
                                            snapshot: lockNotifD.modelData
                                            width: notifInnerCol.width
                                        }
                                    }
                                }

                                // Thin scrollbar
                                Rectangle {
                                    visible: notifScrollContainer.maxScrollY > 0
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: Math.round(3 * Config.scale)
                                    radius: width / 2
                                    color: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18)

                                    Rectangle {
                                        readonly property real _thumbH: notifScrollContainer.maxScrollY <= 0 ? parent.height
                                            : Math.max(Math.round(28 * Config.scale),
                                                parent.height * (notifScrollContainer.height / notifInnerCol.implicitHeight))
                                        readonly property real _thumbY: notifScrollContainer.maxScrollY <= 0 ? 0
                                            : (parent.height - _thumbH) * (notifScrollContainer.scrollY / notifScrollContainer.maxScrollY)
                                        y: _thumbY
                                        width: parent.width
                                        height: _thumbH
                                        radius: width / 2
                                        color: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.55)
                                    }
                                }
                            }
                        }

                        // Lock indicator (shown when no notifications)
                        Item {
                            visible: root.notifHistory.length === 0
                            width: parent.width
                            height: lockIndicatorCol.implicitHeight

                            Column {
                                id: lockIndicatorCol
                                spacing: Math.round(8 * Config.scale)

                                Text {
                                    text: "\uF023"
                                    color: Config.colors.accent
                                    font.family: Config.font.family
                                    font.pixelSize: Math.round(32 * Config.scale)
                                    opacity: 0.45

                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.75; duration: 2200; easing.type: Easing.InOutSine }
                                        NumberAnimation { to: 0.3;  duration: 2200; easing.type: Easing.InOutSine }
                                    }
                                }

                                Text {
                                    text: "Screen locked"
                                    color: Config.colors.textMuted
                                    font.family: Config.font.family
                                    font.pixelSize: Math.round(13 * Config.scale)
                                    opacity: 0.5
                                }

                                Text {
                                    text: "qs ipc call lockscreen unlock"
                                    color: Config.colors.textMuted
                                    font.family: Config.font.family
                                    font.pixelSize: Math.round(10 * Config.scale)
                                    opacity: 0.3
                                }
                            }
                        }
                    }

                    // ── RIGHT: Status widgets ──────────────────────────────
                    Column {
                        id: rightCol
                        anchors.right: parent.right
                        anchors.top: parent.top
                        width: Math.round(310 * Config.scale)
                        spacing: Math.round(14 * Config.scale)

                        // ── WiFi widget ────────────────────────────────────
                        Rectangle {
                            width: parent.width
                            height: wifiInner.implicitHeight + Math.round(24 * Config.scale)
                            radius: Math.round(14 * Config.scale)
                            color: Config.colors.surface
                            border.width: Config.panelBorder.width
                            border.color: Config.panelBorder.color

                            Column {
                                id: wifiInner
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Math.round(16 * Config.scale)
                                spacing: Math.round(10 * Config.scale)

                                // Section header
                                RowLayout {
                                    width: parent.width
                                    spacing: Math.round(8 * Config.scale)

                                    IconImage {
                                        implicitSize: Math.round(17 * Config.scale)
                                        source: Quickshell.iconPath(root.wifiIcon(root.wifiStrength))
                                        opacity: root.wifiEnabled ? 1.0 : 0.4
                                        Behavior on opacity { NumberAnimation { duration: 200 } }
                                    }

                                    Text {
                                        text: "Wi-Fi"
                                        color: Config.colors.textMuted
                                        font.family: Config.font.family
                                        font.pixelSize: Math.round(11 * Config.scale)
                                        font.weight: Font.Medium
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        width: Math.round(7 * Config.scale)
                                        height: width
                                        radius: width / 2
                                        color: root.wifiEnabled ? Config.colors.success : Config.colors.danger
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                }

                                // Connected SSID
                                Text {
                                    width: parent.width
                                    text: {
                                        if (!root.wifiEnabled) return "Wi-Fi is off";
                                        if (root.wifiSsid !== "") return root.wifiSsid;
                                        return "Not connected";
                                    }
                                    color: root.wifiSsid !== "" ? Config.colors.accent : Config.colors.textSecondary
                                    font.family: Config.font.family
                                    font.pixelSize: Math.round(15 * Config.scale)
                                    font.weight: Font.SemiBold
                                    elide: Text.ElideRight
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }

                                // Signal strength bar
                                Item {
                                    visible: root.wifiEnabled && root.wifiStrength >= 0
                                    width: parent.width
                                    height: Math.round(5 * Config.scale)

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: height / 2
                                        color: Config.colors.sliderRail
                                    }

                                    Rectangle {
                                        width: parent.width * Math.max(0, Math.min(1, root.wifiStrength / 100))
                                        height: parent.height
                                        radius: height / 2
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: Config.colors.accent }
                                            GradientStop { position: 1.0; color: Config.colors.accentAlt }
                                        }
                                        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                    }
                                }

                                Text {
                                    visible: root.wifiEnabled && root.wifiStrength >= 0
                                    text: root.wifiStrength + "% signal"
                                    color: Config.colors.textMuted
                                    font.family: Config.font.family
                                    font.pixelSize: Math.round(10 * Config.scale)
                                    opacity: 0.7
                                }

                                // Nearby networks (top 3 inactive)
                                Column {
                                    visible: root.wifiEnabled && root.wifiNetworks.filter(n => !n.active).length > 0
                                    width: parent.width
                                    spacing: Math.round(3 * Config.scale)

                                    Text {
                                        text: "Nearby"
                                        color: Config.colors.textMuted
                                        font.family: Config.font.family
                                        font.pixelSize: Math.round(9 * Config.scale)
                                        opacity: 0.6
                                    }

                                    Repeater {
                                        model: {
                                            const avail = root.wifiNetworks.filter(n => !n.active);
                                            return avail.slice(0, 3);
                                        }
                                        delegate: RowLayout {
                                            id: nearbyRow
                                            required property var modelData
                                            width: wifiInner.width
                                            spacing: Math.round(5 * Config.scale)

                                            IconImage {
                                                implicitSize: Math.round(12 * Config.scale)
                                                source: Quickshell.iconPath(root.wifiIcon(nearbyRow.modelData.signal))
                                                opacity: 0.5
                                            }
                                            Text {
                                                text: nearbyRow.modelData.ssid
                                                color: Config.colors.textMuted
                                                font.family: Config.font.family
                                                font.pixelSize: Math.round(10 * Config.scale)
                                                elide: Text.ElideRight
                                                opacity: 0.7
                                                Layout.fillWidth: true
                                            }
                                            Text {
                                                text: nearbyRow.modelData.signal + "%"
                                                color: Config.colors.textMuted
                                                font.family: Config.font.family
                                                font.pixelSize: Math.round(9 * Config.scale)
                                                opacity: 0.5
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── Bluetooth widget ───────────────────────────────
                        Rectangle {
                            visible: root.btAdapter !== null
                            width: parent.width
                            height: btInner.implicitHeight + Math.round(24 * Config.scale)
                            radius: Math.round(14 * Config.scale)
                            color: Config.colors.surface
                            border.width: Config.panelBorder.width
                            border.color: Config.panelBorder.color

                            Column {
                                id: btInner
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Math.round(16 * Config.scale)
                                spacing: Math.round(10 * Config.scale)

                                // Header
                                RowLayout {
                                    width: parent.width
                                    spacing: Math.round(8 * Config.scale)

                                    IconImage {
                                        implicitSize: Math.round(17 * Config.scale)
                                        source: {
                                            const a = root.btAdapter;
                                            if (!a || !a.enabled) return Quickshell.iconPath("network-bluetooth-inactive-symbolic");
                                            const vals = a.devices ? a.devices.values : null;
                                            if (vals) {
                                                for (let i = 0; i < vals.length; i++) {
                                                    if (vals[i] && vals[i].connected)
                                                        return Quickshell.iconPath("network-bluetooth-activated-symbolic");
                                                }
                                            }
                                            return Quickshell.iconPath("network-bluetooth-symbolic");
                                        }
                                        opacity: (root.btAdapter && root.btAdapter.enabled) ? 1.0 : 0.4
                                        Behavior on opacity { NumberAnimation { duration: 200 } }
                                    }

                                    Text {
                                        text: "Bluetooth"
                                        color: Config.colors.textMuted
                                        font.family: Config.font.family
                                        font.pixelSize: Math.round(11 * Config.scale)
                                        font.weight: Font.Medium
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        width: Math.round(7 * Config.scale)
                                        height: width
                                        radius: width / 2
                                        color: (root.btAdapter && root.btAdapter.enabled) ? Config.colors.accent : Config.colors.danger
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                }

                                // Connected devices
                                Column {
                                    id: btDevList
                                    width: parent.width
                                    spacing: Math.round(10 * Config.scale)

                                    readonly property var connectedDevs: {
                                        const a = root.btAdapter;
                                        if (!a || !a.enabled || !a.devices) return [];
                                        const vals = a.devices.values;
                                        const result = [];
                                        for (let i = 0; i < vals.length; i++) {
                                            if (vals[i] && vals[i].connected) result.push(vals[i]);
                                        }
                                        return result;
                                    }

                                    Text {
                                        visible: btDevList.connectedDevs.length === 0
                                        text: {
                                            const a = root.btAdapter;
                                            if (!a || !a.enabled) return "Bluetooth is off";
                                            return "No devices connected";
                                        }
                                        color: Config.colors.textMuted
                                        font.family: Config.font.family
                                        font.pixelSize: Math.round(13 * Config.scale)
                                        opacity: 0.6
                                    }

                                    Repeater {
                                        model: btDevList.connectedDevs

                                        delegate: Column {
                                            id: btDevEntry
                                            required property var modelData
                                            width: btDevList.width
                                            spacing: Math.round(5 * Config.scale)

                                            readonly property real _batt: (btDevEntry.modelData && btDevEntry.modelData.batteryAvailable)
                                                ? btDevEntry.modelData.battery : -1
                                            readonly property bool _hasBatt: btDevEntry._batt >= 0

                                            RowLayout {
                                                width: parent.width
                                                spacing: Math.round(8 * Config.scale)

                                                IconImage {
                                                    implicitSize: Math.round(17 * Config.scale)
                                                    source: Quickshell.iconPath(root.btDeviceIcon(btDevEntry.modelData))
                                                }

                                                Text {
                                                    text: root.btDeviceName(btDevEntry.modelData)
                                                    color: Config.colors.accent
                                                    font.family: Config.font.family
                                                    font.pixelSize: Math.round(13 * Config.scale)
                                                    font.weight: Font.SemiBold
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }

                                                Text {
                                                    visible: btDevEntry._hasBatt
                                                    text: btDevEntry._hasBatt ? Math.round(btDevEntry._batt * 100) + "%" : ""
                                                    color: {
                                                        const pct = btDevEntry._batt * 100;
                                                        if (pct <= 15) return Config.colors.danger;
                                                        if (pct <= 30) return Config.colors.warning;
                                                        return Config.colors.success;
                                                    }
                                                    font.family: Config.font.family
                                                    font.pixelSize: Math.round(11 * Config.scale)
                                                    font.weight: Font.Bold
                                                }
                                            }

                                            // Device battery bar
                                            Item {
                                                visible: btDevEntry._hasBatt
                                                width: parent.width
                                                height: visible ? Math.round(4 * Config.scale) : 0

                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: height / 2
                                                    color: Config.colors.sliderRail
                                                }

                                                Rectangle {
                                                    width: Math.max(height, parent.width * Math.max(0, Math.min(1, btDevEntry._batt)))
                                                    height: parent.height
                                                    radius: height / 2
                                                    gradient: Gradient {
                                                        orientation: Gradient.Horizontal
                                                        GradientStop {
                                                            position: 0.0
                                                            color: btDevEntry._batt <= 0.15 ? Config.colors.danger
                                                                 : btDevEntry._batt <= 0.30 ? Config.colors.warning
                                                                 : Config.colors.success
                                                        }
                                                        GradientStop {
                                                            position: 1.0
                                                            color: btDevEntry._batt <= 0.15 ? Qt.rgba(1, 0.41, 0.47, 0.7)
                                                                 : btDevEntry._batt <= 0.30 ? Qt.rgba(1, 0.69, 0.38, 0.7)
                                                                 : Config.colors.accent
                                                        }
                                                    }
                                                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── System battery widget ──────────────────────────
                        Rectangle {
                            visible: root.sysBattery !== null && root.sysBattery.isLaptopBattery
                            width: parent.width
                            height: sysBattInner.implicitHeight + Math.round(24 * Config.scale)
                            radius: Math.round(14 * Config.scale)
                            color: Config.colors.surface
                            border.width: Config.panelBorder.width
                            border.color: Config.panelBorder.color

                            Column {
                                id: sysBattInner
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Math.round(16 * Config.scale)
                                spacing: Math.round(10 * Config.scale)

                                RowLayout {
                                    width: parent.width
                                    spacing: Math.round(8 * Config.scale)

                                    IconImage {
                                        implicitSize: Math.round(17 * Config.scale)
                                        source: {
                                            const b = root.sysBattery;
                                            if (!b || !b.isLaptopBattery) return "";
                                            const pct = Math.round(b.percentage * 100);
                                            const charging = b.state === UPowerDeviceState.Charging
                                                          || b.state === UPowerDeviceState.FullyCharged;
                                            const level = Math.min(100, Math.round(pct / 10) * 10);
                                            return Quickshell.iconPath("battery-" + String(level).padStart(3, "0")
                                                + (charging ? "-charging" : "") + "-symbolic");
                                        }
                                    }

                                    Text {
                                        text: "Battery"
                                        color: Config.colors.textMuted
                                        font.family: Config.font.family
                                        font.pixelSize: Math.round(11 * Config.scale)
                                        font.weight: Font.Medium
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: {
                                            const b = root.sysBattery;
                                            if (!b || !b.isLaptopBattery) return "";
                                            return Math.round(b.percentage * 100) + "%";
                                        }
                                        color: {
                                            const b = root.sysBattery;
                                            if (!b) return Config.colors.textPrimary;
                                            const pct = b.percentage * 100;
                                            if (pct <= 10) return Config.colors.danger;
                                            if (pct <= 20) return Config.colors.warning;
                                            return Config.colors.success;
                                        }
                                        font.family: Config.font.family
                                        font.pixelSize: Math.round(14 * Config.scale)
                                        font.weight: Font.Bold
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: Math.round(5 * Config.scale)

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: height / 2
                                        color: Config.colors.sliderRail
                                    }

                                    Rectangle {
                                        readonly property real _pct: root.sysBattery ? root.sysBattery.percentage : 0
                                        width: Math.max(height, parent.width * Math.max(0, Math.min(1, _pct)))
                                        height: parent.height
                                        radius: height / 2
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop {
                                                position: 0.0
                                                color: {
                                                    const b = root.sysBattery;
                                                    if (!b) return Config.colors.accent;
                                                    const pct = b.percentage * 100;
                                                    if (pct <= 10) return Config.colors.danger;
                                                    if (pct <= 20) return Config.colors.warning;
                                                    return Config.colors.accent;
                                                }
                                            }
                                            GradientStop {
                                                position: 1.0
                                                color: {
                                                    const b = root.sysBattery;
                                                    if (!b) return Config.colors.accentAlt;
                                                    const pct = b.percentage * 100;
                                                    if (pct <= 10) return Qt.rgba(1, 0.41, 0.47, 0.7);
                                                    if (pct <= 20) return Qt.rgba(1, 0.69, 0.38, 0.7);
                                                    return Config.colors.accentAlt;
                                                }
                                            }
                                        }
                                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                                    }
                                }

                                Text {
                                    text: {
                                        const b = root.sysBattery;
                                        if (!b || !b.isLaptopBattery) return "";
                                        if (b.state === UPowerDeviceState.Charging) return "Charging";
                                        if (b.state === UPowerDeviceState.FullyCharged) return "Fully charged";
                                        if (b.state === UPowerDeviceState.Discharging) return "Discharging";
                                        return "";
                                    }
                                    color: Config.colors.textMuted
                                    font.family: Config.font.family
                                    font.pixelSize: Math.round(10 * Config.scale)
                                    opacity: 0.7
                                }
                            }
                        }

                        // ── Volume widget ──────────────────────────────────
                        Rectangle {
                            visible: root.audio !== null
                            width: parent.width
                            height: volInner.implicitHeight + Math.round(24 * Config.scale)
                            radius: Math.round(14 * Config.scale)
                            color: Config.colors.surface
                            border.width: Config.panelBorder.width
                            border.color: Config.panelBorder.color

                            Column {
                                id: volInner
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Math.round(16 * Config.scale)
                                spacing: Math.round(10 * Config.scale)

                                RowLayout {
                                    width: parent.width
                                    spacing: Math.round(8 * Config.scale)

                                    IconImage {
                                        implicitSize: Math.round(17 * Config.scale)
                                        source: {
                                            const a = root.audio;
                                            if (!a || a.muted) return Quickshell.iconPath("audio-volume-muted-symbolic");
                                            if (a.volume < 0.33) return Quickshell.iconPath("audio-volume-low-symbolic");
                                            if (a.volume < 0.66) return Quickshell.iconPath("audio-volume-medium-symbolic");
                                            return Quickshell.iconPath("audio-volume-high-symbolic");
                                        }
                                        opacity: (root.audio && root.audio.muted) ? 0.4 : 1.0
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                    }

                                    Text {
                                        text: "Volume"
                                        color: Config.colors.textMuted
                                        font.family: Config.font.family
                                        font.pixelSize: Math.round(11 * Config.scale)
                                        font.weight: Font.Medium
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: {
                                            const a = root.audio;
                                            if (!a) return "–";
                                            if (a.muted) return "Muted";
                                            return Math.round(a.volume * 100) + "%";
                                        }
                                        color: (root.audio && root.audio.muted)
                                            ? Config.colors.textMuted : Config.colors.textPrimary
                                        font.family: Config.font.family
                                        font.pixelSize: Math.round(13 * Config.scale)
                                        font.weight: Font.Medium
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: Math.round(5 * Config.scale)

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: height / 2
                                        color: Config.colors.sliderRail
                                    }

                                    Rectangle {
                                        width: {
                                            const a = root.audio;
                                            if (!a || a.muted) return height;
                                            return Math.max(height, parent.width * Math.max(0, Math.min(1, a.volume)));
                                        }
                                        height: parent.height
                                        radius: height / 2
                                        opacity: (root.audio && root.audio.muted) ? 0.25 : 1.0
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: Config.colors.accent }
                                            GradientStop { position: 1.0; color: Config.colors.accentAlt }
                                        }
                                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                    }
                                }
                            }
                        }
                    }

                    // ── Bottom center: lock hint ────────────────────────────
                    Item {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: lockHint.implicitWidth
                        height: lockHint.implicitHeight

                        Column {
                            id: lockHint
                            spacing: Math.round(6 * Config.scale)
                            anchors.centerIn: parent

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "\uF023"
                                color: Config.colors.accent
                                font.family: Config.font.family
                                font.pixelSize: Math.round(22 * Config.scale)
                                opacity: 0.4

                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.7; duration: 2400; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 0.25; duration: 2400; easing.type: Easing.InOutSine }
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "qs ipc call lockscreen unlock"
                                color: Config.colors.textMuted
                                font.family: Config.font.family
                                font.pixelSize: Math.round(10 * Config.scale)
                                opacity: 0.35
                            }
                        }
                    }
                }
            }
        }
    }
}
