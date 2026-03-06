pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth

Scope {
    id: root

    property bool visible_: false

    // ── Shared popup manager ──────────────────────────────────────────────────
    // Only one popup open at a time. Sections call root.openPopup("name") on
    // hover-enter and root.keepPopup() on hover-stay. Leaving both trigger and
    // popup restarts the close timer; if no section reclaims it, closeTimer fires.
    property string activePopup: ""   // "wifi" | "bt" | "volume" | "clock" | ""

    readonly property bool anyPopupOpen: activePopup !== ""

    // Delegates (inside Repeaters) cannot reference section IDs directly due to
    // ComponentBehavior:Bound, so they call these root-level forwarders.
    function openPopup(name) {
        root.activePopup = name;
        popupCloseTimer.restart();
        root.keepAlive();
    }

    function keepPopup() {
        if (root.activePopup !== "") {
            popupCloseTimer.restart();
            root.keepAlive();
        }
    }

    function closePopup() {
        root.activePopup = "";
    }

    // Forwarders for Repeater delegates
    function keepWifiPopup()   { root.openPopup("wifi") }
    function keepBtPopup()     { root.openPopup("bt") }
    function keepVolumePopup() { root.openPopup("volume") }

    Timer {
        id: popupCloseTimer
        interval: Config.bar.hideDelay
        onTriggered: root.closePopup()
    }

    // ── Bar show/hide ─────────────────────────────────────────────────────────

    function show() {
        root.visible_ = true;
        hideTimer.restart();
    }

    function keepAlive() {
        hideTimer.restart();
    }

    IpcHandler {
        target: "bar"
        function toggle() {
            root.show();
        }
    }

    Timer {
        id: hideTimer
        interval: Config.bar.hideDelay
        onTriggered: root.visible_ = false
    }

    property UPowerDevice battery: UPower.displayDevice

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    // ── Wifi ─────────────────────────────────────────────────────────────────

    property string wifiSsid: ""
    property int wifiStrength: -1
    property var wifiNetworks: []
    property string wifiConnecting: ""
    property bool wifiEnabled: true

    function toggleWifi() {
        wifiToggleProc.command = ["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"];
        wifiToggleProc.running = true;
    }

    Process {
        id: wifiToggleProc
        onExited: { wifiRadioProc.running = true; }
    }

    Process {
        id: wifiRadioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = this.text.trim() === "enabled";
                if (root.wifiEnabled) wifiProc.running = true;
                else { root.wifiNetworks = []; root.wifiSsid = ""; root.wifiStrength = -1; }
            }
        }
    }

    // Measures SSID text to compute popup width
    TextMetrics {
        id: wifiTextMetrics
        font.family: Config.font.family
        font.pixelSize: Config.bar.fontSizeStatus
    }

    // Fixed-width reserves for bar labels (prevents layout shifts)
    // All four use "100%" as the widest string — icons convey state changes.
    TextMetrics {
        id: statusTextMetrics
        font.family: Config.font.family
        font.pixelSize: Config.bar.fontSizeStatus
    }

    readonly property int wifiLabelWidth: {
        statusTextMetrics.text = "100%";
        return Math.round(statusTextMetrics.boundingRect.width + 4 * Config.scale);
    }

    readonly property int btLabelWidth: {
        statusTextMetrics.text = "100%";
        return Math.round(statusTextMetrics.boundingRect.width + 4 * Config.scale);
    }

    readonly property int volumeLabelWidth: {
        statusTextMetrics.text = "100%";
        return Math.round(statusTextMetrics.boundingRect.width + 4 * Config.scale);
    }

    readonly property int batteryLabelWidth: {
        statusTextMetrics.text = "100%";
        return Math.round(statusTextMetrics.boundingRect.width + 4 * Config.scale);
    }

    readonly property int wifiPopupWidth: {
        const nets = root.wifiNetworks;
        const iconW = Config.bar.fontSizeStatus + Math.round(4 * Config.scale);
        const checkW = Config.bar.fontSizeStatus;
        const margins = Math.round(8 * Config.scale) * 6; // col margins + row left/right + spacing x2
        let maxSsidW = Math.round(120 * Config.scale);
        for (let i = 0; i < nets.length; i++) {
            wifiTextMetrics.text = nets[i].ssid;
            if (wifiTextMetrics.boundingRect.width > maxSsidW)
                maxSsidW = wifiTextMetrics.boundingRect.width;
        }
        return iconW + maxSsidW + checkW + margins;
    }

    Timer {
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
                    if (!line) continue;
                    const lastColon = line.lastIndexOf(":");
                    const secondLastColon = line.lastIndexOf(":", lastColon - 1);
                    const active = line.slice(lastColon + 1);
                    const signal = parseInt(line.slice(secondLastColon + 1, lastColon));
                    const ssid = line.slice(0, secondLastColon);
                    if (!ssid) continue;
                    if (!seen[ssid] || seen[ssid] < signal) {
                        seen[ssid] = signal;
                        const existing = nets.findIndex(n => n.ssid === ssid);
                        const entry = { ssid, signal, active: active === "yes" };
                        if (existing >= 0) nets[existing] = entry;
                        else nets.push(entry);
                    }
                }
                nets.sort((a, b) => b.signal - a.signal);
                root.wifiNetworks = nets;
                const cur = nets.find(n => n.active);
                if (cur) { root.wifiSsid = cur.ssid; root.wifiStrength = cur.signal; }
                else     { root.wifiSsid = "";        root.wifiStrength = -1; }
            }
        }
    }

    Process {
        id: wifiConnectProc
        onExited: { root.wifiConnecting = ""; wifiProc.running = true; }
    }

    function connectWifi(ssid) {
        root.wifiConnecting = ssid;
        wifiConnectProc.command = ["nmcli", "dev", "wifi", "connect", ssid];
        wifiConnectProc.running = true;
    }

    function wifiIcon(strength) {
        if (strength < 0)  return "network-wireless-offline-symbolic";
        if (strength < 25) return "network-wireless-signal-weak-symbolic";
        if (strength < 50) return "network-wireless-signal-ok-symbolic";
        if (strength < 75) return "network-wireless-signal-good-symbolic";
        return "network-wireless-signal-excellent-symbolic";
    }

    // ── Clock helpers ─────────────────────────────────────────────────────────

    function clockTimeText(date) {
        if (!date) return "--:--";
        if (Config.bar.clock24h) return Qt.formatTime(date, "HH:mm");
        return Qt.formatTime(date, "hh") + ":" + Qt.formatTime(date, "mm") + " " + Qt.formatTime(date, "AP");
    }

    function clockDateText(date) {
        if (!date) return "";
        return Qt.formatDate(date, "dddd, dd-MM-yy");
    }

    // ── Volume ───────────────────────────────────────────────────────────────

    function volumeIcon() {
        const audio = Pipewire.defaultAudioSink?.audio;
        if (!audio || audio.muted) return "audio-volume-muted-symbolic";
        const v = audio.volume;
        if (v <= 0.33) return "audio-volume-low-symbolic";
        if (v <= 0.66) return "audio-volume-medium-symbolic";
        return "audio-volume-high-symbolic";
    }

    // ── Bluetooth ────────────────────────────────────────────────────────────

    function btIcon() {
        const adapter = Bluetooth.defaultAdapter;
        if (!adapter || !adapter.enabled) return "network-bluetooth-inactive-symbolic";
        const devs = adapter.devices;
        if (devs) {
            for (let i = 0; i < devs.count; i++) {
                const d = devs.get(i).modelData;
                if (d && d.connected) return "network-bluetooth-activated-symbolic";
            }
        }
        return "network-bluetooth-symbolic";
    }

    function btConnectedName() {
        const adapter = Bluetooth.defaultAdapter;
        if (!adapter || !adapter.enabled) return "";
        const devs = adapter.devices;
        if (devs) {
            for (let i = 0; i < devs.count; i++) {
                const d = devs.get(i).modelData;
                if (d && d.connected) return d.name || d.deviceName || "";
            }
        }
        return "";
    }

    // ── Window ───────────────────────────────────────────────────────────────

    PanelWindow {
        id: win

        WlrLayershell.layer: WlrLayer.Top
        anchors.bottom: true
        exclusiveZone: 0
        color: "transparent"

        implicitWidth: win.screen ? win.screen.width : 1920
        implicitHeight: pill.implicitHeight + Math.round(16 * Config.scale) + 500

        mask: Region {
            Region { item: pill }
            Region {
                item: root.activePopup === "wifi" ? wifiPopup : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "bt" ? btPopup : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "volume" ? volumePopup : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "clock" ? calendarPopup : null
                intersection: Intersection.Combine
            }
        }

        // Leftover maskRect removed
        Rectangle {
            id: pill

            implicitWidth: content.implicitWidth + Config.bar.padding * 2
            implicitHeight: content.implicitHeight + Math.round(12 * Config.scale) * 2

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.visible_
                ? Math.round(8 * Config.scale)
                : -(pill.implicitHeight + Math.round(8 * Config.scale))

            Behavior on anchors.bottomMargin {
                NumberAnimation { duration: Config.bar.animateSpeed; easing.type: Easing.InOutQuad }
            }

            radius: Config.bar.radius
            color: Config.colors.background
            border.color: Config.colors.border
            border.width: 1

            opacity: root.visible_ ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: Config.bar.animateSpeed; easing.type: Easing.InOutQuad }
            }

            HoverHandler {
                onHoveredChanged: if (hovered) root.keepAlive()
            }

            ColumnLayout {
                id: content
                anchors.centerIn: parent
                width: implicitWidth
                spacing: Math.round(6 * Config.scale)

                // ── Tray ─────────────────────────────────────────────────────
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Config.bar.spacing
                    visible: trayRepeater.count > 0

                    Repeater {
                        id: trayRepeater
                        model: SystemTray.items
                        delegate: BarTrayItem {
                            required property SystemTrayItem modelData
                            trayItem: modelData
                            onHovered: root.keepAlive()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Config.colors.border
                    visible: trayRepeater.count > 0
                }

                // ── Status row ────────────────────────────────────────────────
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Config.bar.sectionSpacing

                    // ── Wifi section ──────────────────────────────────────────
                    Item {
                        id: wifiSection
                        implicitWidth: wifiRow.implicitWidth
                        implicitHeight: wifiRow.implicitHeight

                        readonly property bool popupOpen: root.activePopup === "wifi"

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.openPopup("wifi")
                            onExited: root.keepPopup()
                            onClicked: root.toggleWifi()
                        }

                        RowLayout {
                            id: wifiRow
                            spacing: Math.round(6 * Config.scale)

                            IconImage {
                                implicitSize: Config.bar.batteryIconSize
                                source: Quickshell.iconPath(root.wifiIcon(root.wifiStrength))
                            }

                            Text {
                                Layout.preferredWidth: root.wifiLabelWidth
                                Layout.fillWidth: false
                                text: root.wifiSsid || "No WiFi"
                                color: Config.colors.textSecondary
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizeStatus
                                elide: Text.ElideRight
                            }
                        }

                        // Wifi popup
                        Rectangle {
                            id: wifiPopup
                            visible: opacity > 0
                            opacity: wifiSection.popupOpen ? 1 : 0
                            scale: wifiSection.popupOpen ? 1 : 0.92
                            transformOrigin: Item.Bottom

                            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }
                            Behavior on scale   { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }

                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.top
                            anchors.bottomMargin: Config.bar.popupOffset

                            width: root.wifiPopupWidth
                            height: Math.min(
                                wifiListCol.implicitHeight + Math.round(16 * Config.scale),
                                Math.round(320 * Config.scale)
                            )

                            radius: Math.round(10 * Config.scale)
                            color: Config.colors.background
                            border.color: Config.colors.border
                            border.width: 1
                            z: 20
                            clip: true

                            HoverHandler {
                                onHoveredChanged: {
                                    if (hovered) root.openPopup("wifi");
                                    else root.keepPopup();
                                }
                            }

                            Flickable {
                                anchors.fill: parent
                                anchors.margins: Math.round(8 * Config.scale)
                                contentWidth: width
                                contentHeight: wifiListCol.implicitHeight
                                clip: true

                                Column {
                                    id: wifiListCol
                                    width: parent.width
                                    spacing: Math.round(2 * Config.scale)

                                Repeater {
                                    model: root.wifiNetworks
                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property bool isActive: modelData.active
                                        readonly property bool isConnecting: root.wifiConnecting === modelData.ssid

                                        width: wifiListCol.width
                                        implicitHeight: wifiEntryRow.implicitHeight + Math.round(8 * Config.scale)
                                        radius: Math.round(6 * Config.scale)
                                        color: isActive
                                            ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18)
                                            : (wifiEntryMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent")

                                        Behavior on color { ColorAnimation { duration: 80 } }

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
                                                source: Quickshell.iconPath(root.wifiIcon(parent.parent.modelData.signal))
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: parent.parent.modelData.ssid
                                                color: parent.parent.isActive ? Config.colors.accent : Config.colors.textPrimary
                                                font.family: Config.font.family
                                                font.pixelSize: Config.bar.fontSizeStatus
                                            }

                                            Text {
                                                text: parent.parent.isConnecting ? "…" : parent.parent.isActive ? "✓" : ""
                                                color: Config.colors.accent
                                                font.family: Config.font.family
                                                font.pixelSize: Config.bar.fontSizeStatus
                                                visible: parent.parent.isActive || parent.parent.isConnecting
                                            }
                                        }

                                        MouseArea {
                                            id: wifiEntryMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onEntered: root.keepWifiPopup()
                                            onClicked: {
                                                if (!parent.isActive && !parent.isConnecting)
                                                    root.connectWifi(parent.modelData.ssid);
                                                root.keepWifiPopup();
                                            }
                                        }
                                    }
                                }
                            }  // Column
                            }  // Flickable
                        }
                    }

                    Rectangle {
                        implicitWidth: 1
                        implicitHeight: Config.bar.batteryIconSize
                        color: Config.colors.border
                    }

                    // ── Bluetooth section ─────────────────────────────────────
                    Item {
                        id: btSection
                        implicitWidth: btRow.implicitWidth
                        implicitHeight: btRow.implicitHeight

                        readonly property bool popupOpen: root.activePopup === "bt"
                        readonly property var adapter: Bluetooth.defaultAdapter

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.openPopup("bt")
                            onExited: root.keepPopup()
                            onClicked: {
                                if (btSection.adapter)
                                    btSection.adapter.enabled = !btSection.adapter.enabled;
                            }
                        }

                        RowLayout {
                            id: btRow
                            spacing: Math.round(6 * Config.scale)

                            IconImage {
                                implicitSize: Config.bar.batteryIconSize
                                source: Quickshell.iconPath(root.btIcon())
                            }

                            Text {
                                Layout.preferredWidth: root.btLabelWidth
                                Layout.fillWidth: false
                                text: {
                                    const adapter = btSection.adapter;
                                    if (!adapter || !adapter.enabled) return "Off";
                                    const name = root.btConnectedName();
                                    return name !== "" ? name : "BT";
                                }
                                color: Config.colors.textSecondary
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizeStatus
                                elide: Text.ElideRight
                            }
                        }

                        // Bluetooth popup
                        Rectangle {
                            id: btPopup
                            visible: opacity > 0
                            opacity: btSection.popupOpen ? 1 : 0
                            scale: btSection.popupOpen ? 1 : 0.92
                            transformOrigin: Item.Bottom

                            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }
                            Behavior on scale   { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }

                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.top
                            anchors.bottomMargin: Config.bar.popupOffset

                            width: 260
                            height: btPopupCol.implicitHeight + Math.round(16 * Config.scale)

                            radius: Math.round(10 * Config.scale)
                            color: Config.colors.background
                            border.color: Config.colors.border
                            border.width: 1
                            z: 20

                            HoverHandler {
                                onHoveredChanged: {
                                    if (hovered) root.openPopup("bt");
                                    else root.keepPopup();
                                }
                            }

                            Column {
                                id: btPopupCol
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: Math.round(8 * Config.scale)
                                spacing: Math.round(4 * Config.scale)

                                // Enable / disable toggle row
                                Rectangle {
                                    width: btPopupCol.width
                                    implicitHeight: btToggleRow.implicitHeight + Math.round(8 * Config.scale)
                                    radius: Math.round(6 * Config.scale)
                                    color: btToggleMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 80 } }

                                    RowLayout {
                                        id: btToggleRow
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: Math.round(8 * Config.scale)
                                        anchors.rightMargin: Math.round(8 * Config.scale)
                                        spacing: Math.round(8 * Config.scale)

                                        IconImage {
                                            implicitSize: Config.bar.fontSizeStatus + Math.round(4 * Config.scale)
                                            source: Quickshell.iconPath(
                                                 btSection.adapter && btSection.adapter.enabled
                                                    ? "network-bluetooth-activated-symbolic"
                                                    : "network-bluetooth-inactive-symbolic"
                                            )
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: btSection.adapter && btSection.adapter.enabled ? "Bluetooth On" : "Bluetooth Off"
                                            color: Config.colors.textPrimary
                                            font.family: Config.font.family
                                            font.pixelSize: Config.bar.fontSizeStatus
                                        }

                                        Rectangle {
                                            implicitWidth: Math.round(36 * Config.scale)
                                            implicitHeight: Math.round(18 * Config.scale)
                                            radius: implicitHeight / 2
                                            color: btSection.adapter && btSection.adapter.enabled
                                                ? Config.colors.accent : Config.colors.border
                                            Behavior on color { ColorAnimation { duration: 120 } }
                                        }
                                    }

                                    MouseArea {
                                        id: btToggleMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: root.keepBtPopup()
                                        onClicked: {
                                            if (btSection.adapter)
                                                btSection.adapter.enabled = !btSection.adapter.enabled;
                                            root.keepBtPopup();
                                        }
                                    }
                                }

                                Rectangle {
                                    width: btPopupCol.width
                                    implicitHeight: 1
                                    color: Config.colors.border
                                    visible: btSection.adapter && btSection.adapter.enabled
                                }

                                Repeater {
                                    model: (btSection.adapter && btSection.adapter.enabled)
                                        ? btSection.adapter.devices : null

                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property var device: modelData
                                        readonly property bool isConnected: device && device.connected

                                        width: btPopupCol.width
                                        implicitHeight: btDevRow.implicitHeight + Math.round(8 * Config.scale)
                                        radius: Math.round(6 * Config.scale)
                                        color: isConnected
                                            ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18)
                                            : (btDevMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent")

                                        Behavior on color { ColorAnimation { duration: 80 } }

                                        RowLayout {
                                            id: btDevRow
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.leftMargin: Math.round(8 * Config.scale)
                                            anchors.rightMargin: Math.round(8 * Config.scale)
                                            spacing: Math.round(8 * Config.scale)

                                            IconImage {
                                                implicitSize: Config.bar.fontSizeStatus + Math.round(4 * Config.scale)
                                                source: {
                                                    const d = parent.parent.device;
                                                    if (!d) return "";
                                                    const ico = d.icon || "";
                                                    return Quickshell.iconPath(ico !== "" ? ico : "network-bluetooth-symbolic");
                                                }
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: {
                                                    const d = parent.parent.device;
                                                    return d ? (d.name || d.deviceName || "Unknown") : "";
                                                }
                                                color: parent.parent.isConnected ? Config.colors.accent : Config.colors.textPrimary
                                                font.family: Config.font.family
                                                font.pixelSize: Config.bar.fontSizeStatus
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: parent.parent.isConnected ? "✓" : ""
                                                color: Config.colors.accent
                                                font.family: Config.font.family
                                                font.pixelSize: Config.bar.fontSizeStatus
                                                visible: parent.parent.isConnected
                                            }
                                        }

                                        MouseArea {
                                            id: btDevMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onEntered: root.keepBtPopup()
                                            onClicked: {
                                                const d = parent.device;
                                                if (d) d.connected = !d.connected;
                                                root.keepBtPopup();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: 1
                        implicitHeight: Config.bar.batteryIconSize
                        color: Config.colors.border
                    }

                    // ── Volume section ────────────────────────────────────────
                    Item {
                        id: volumeSection
                        implicitWidth: volumeRow.implicitWidth
                        implicitHeight: volumeRow.implicitHeight

                        readonly property bool popupOpen: root.activePopup === "volume"
                        readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
                        visible: Pipewire.defaultAudioSink !== null

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.openPopup("volume")
                            onExited: root.keepPopup()
                            onClicked: {
                                const a = volumeSection.audio;
                                if (a) a.muted = !a.muted;
                            }
                            onWheel: wheel => {
                                const a = volumeSection.audio;
                                if (a) {
                                    const delta = wheel.angleDelta.y / 120;
                                    a.volume = Math.max(0, Math.min(1.0, a.volume + delta * 0.05));
                                }
                                root.keepAlive();
                            }
                        }

                        RowLayout {
                            id: volumeRow
                            spacing: Math.round(6 * Config.scale)

                            IconImage {
                                implicitSize: Config.bar.batteryIconSize
                                source: Quickshell.iconPath(root.volumeIcon())
                            }

                            Text {
                                Layout.preferredWidth: root.volumeLabelWidth
                                Layout.fillWidth: false
                                text: {
                                    const a = volumeSection.audio;
                                    return a ? Math.round(a.volume * 100) + "%" : "0%";
                                }
                                color: Config.colors.textSecondary
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizeStatus
                            }
                        }

                        // Volume popup
                        Rectangle {
                            id: volumePopup
                            visible: opacity > 0
                            opacity: volumeSection.popupOpen ? 1 : 0
                            scale: volumeSection.popupOpen ? 1 : 0.92
                            transformOrigin: Item.Bottom

                            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }
                            Behavior on scale   { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }

                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.top
                            anchors.bottomMargin: Config.bar.popupOffset

                            width: Math.round(60 * Config.scale)
                            height: Math.round(200 * Config.scale)

                            radius: Math.round(10 * Config.scale)
                            color: Config.colors.background
                            border.color: Config.colors.border
                            border.width: 1
                            z: 20

                            HoverHandler {
                                onHoveredChanged: {
                                    if (hovered) root.openPopup("volume");
                                    else root.keepPopup();
                                }
                            }

                            // Slider track
                            Item {
                                id: sliderArea
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.topMargin: Math.round(20 * Config.scale)
                                anchors.bottomMargin: Math.round(20 * Config.scale)
                                width: Math.round(20 * Config.scale)

                                readonly property real trackH: height
                                readonly property real volFraction: Math.min(volumeSection.audio?.volume ?? 0, 1.0)

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    width: Math.round(6 * Config.scale)
                                    height: parent.trackH
                                    radius: width / 2
                                    color: Config.colors.border
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    width: Math.round(6 * Config.scale)
                                    height: parent.trackH * parent.volFraction
                                    radius: width / 2
                                    color: Config.colors.accent
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: parent.trackH * (1 - parent.volFraction) - height / 2
                                    width: Math.round(14 * Config.scale)
                                    height: width
                                    radius: width / 2
                                    color: Config.colors.accent
                                    Behavior on y { NumberAnimation { duration: 60 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.SizeVerCursor
                                    onEntered: root.keepVolumePopup()

                                    function setVolumeFromY(my) {
                                        const frac = 1.0 - Math.max(0, Math.min(1, my / sliderArea.trackH));
                                        const a = volumeSection.audio;
                                        if (a) a.volume = frac * 1.0;
                                        root.keepVolumePopup();
                                    }

                                    onPressed: mouse => setVolumeFromY(mouse.y)
                                    onPositionChanged: mouse => { if (pressed) setVolumeFromY(mouse.y) }
                                    onWheel: wheel => {
                                        const a = volumeSection.audio;
                                        if (a) a.volume = Math.max(0, Math.min(1.0, a.volume + (wheel.angleDelta.y / 120) * 0.05));
                                        root.keepVolumePopup();
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: 1
                        implicitHeight: Config.bar.batteryIconSize
                        color: Config.colors.border
                        visible: Pipewire.defaultAudioSink !== null
                    }

                    // ── Battery ───────────────────────────────────────────────
                    RowLayout {
                        id: batterySection
                        spacing: Math.round(5 * Config.scale)
                        visible: root.battery !== null && root.battery.isLaptopBattery

                        IconImage {
                            implicitSize: Config.bar.batteryIconSize
                            source: {
                                const b = root.battery;
                                if (!b || !b.isLaptopBattery) return "";
                                const pct = Math.round(b.percentage * 100);
                                const charging = b.state === UPowerDeviceState.Charging
                                             || b.state === UPowerDeviceState.FullyCharged;
                                const level = Math.min(100, Math.round(pct / 10) * 10);
                                const lvlStr = String(level).padStart(3, "0");
                                const chargeSuffix = charging ? "-charging" : "";
                                return Quickshell.iconPath("battery-" + lvlStr + chargeSuffix + "-symbolic");
                            }
                        }

                        Text {
                            Layout.preferredWidth: root.batteryLabelWidth
                            Layout.fillWidth: false
                            text: root.battery && root.battery.isLaptopBattery
                                ? Math.round(root.battery.percentage * 100) + "%" : ""
                            color: {
                                if (!root.battery || !root.battery.isLaptopBattery) return Config.colors.textPrimary;
                                const pct = root.battery.percentage * 100;
                                if (pct <= 10) return "#ff6060";
                                if (pct <= 20) return "#ffaa60";
                                return Config.colors.textSecondary;
                            }
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.fontSizeStatus
                        }
                    }

                    Rectangle {
                        implicitWidth: 1
                        implicitHeight: Config.bar.batteryIconSize
                        color: Config.colors.border
                        visible: batterySection.visible
                    }

                    // ── Power profiles ────────────────────────────────────────
                    RowLayout {
                        id: powerRow
                        spacing: Math.round(2 * Config.scale)

                        readonly property var profiles: [
                            { profile: PowerProfile.PowerSaver,  glyph: "󰌪", label: "Power Saver" },
                            { profile: PowerProfile.Balanced,    glyph: "󰗑", label: "Balanced" },
                            { profile: PowerProfile.Performance, glyph: "󰓅", label: "Performance" }
                        ]

                        Repeater {
                            model: powerRow.profiles
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool isActive: PowerProfiles.profile === modelData.profile
                                readonly property bool isPerf: modelData.profile === PowerProfile.Performance

                                implicitWidth: Config.bar.powerIconSize + Math.round(10 * Config.scale)
                                implicitHeight: Config.bar.powerIconSize + Math.round(6 * Config.scale)
                                radius: Math.round(5 * Config.scale)
                                visible: !isPerf || PowerProfiles.hasPerformanceProfile

                                color: isActive
                                    ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.25)
                                    : (btnMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent")
                                border.color: isActive ? Config.colors.accent : Config.colors.border
                                border.width: 1

                                Behavior on color       { ColorAnimation { duration: 100 } }
                                Behavior on border.color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.modelData.glyph
                                    font.family: Config.font.family
                                    font.pixelSize: Config.bar.powerIconSize
                                    color: parent.isActive ? Config.colors.accent : Config.colors.textSecondary
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }

                                MouseArea {
                                    id: btnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.keepAlive()
                                    onClicked: {
                                        PowerProfiles.profile = parent.modelData.profile;
                                        root.keepAlive();
                                    }
                                }

                                // Tooltip
                                Rectangle {
                                    visible: btnMouse.containsMouse
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.top
                                    anchors.bottomMargin: Config.bar.popupOffset
                                    implicitWidth: tipText.implicitWidth + Math.round(10 * Config.scale)
                                    implicitHeight: tipText.implicitHeight + Math.round(6 * Config.scale)
                                    radius: Math.round(4 * Config.scale)
                                    color: Config.colors.background
                                    border.color: Config.colors.border
                                    border.width: 1
                                    z: 10
                                    Text {
                                        id: tipText
                                        anchors.centerIn: parent
                                        text: parent.parent.modelData.label
                                        color: Config.colors.textSecondary
                                        font.family: Config.font.family
                                        font.pixelSize: Config.bar.fontSizeStatus
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: 1
                        implicitHeight: Config.bar.batteryIconSize
                        color: Config.colors.border
                    }

                    // ── Clock / Date ──────────────────────────────────────────
                    Item {
                        id: clockSection
                        implicitWidth: clockCol.implicitWidth
                        implicitHeight: clockCol.implicitHeight

                        readonly property bool popupOpen: root.activePopup === "clock"

                        HoverHandler {
                            onHoveredChanged: {
                                if (hovered) root.openPopup("clock");
                                else root.keepPopup();
                            }
                        }

                        Column {
                            id: clockCol
                            spacing: Math.round(1 * Config.scale)

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.clockTimeText(clock.date)
                                color: Config.colors.textPrimary
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizeClock
                                font.weight: Font.Medium
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.clockDateText(clock.date)
                                color: Config.colors.textSecondary
                                font.family: Config.font.family
                                font.pixelSize: Math.round(Config.bar.fontSizeStatus * 0.8)
                            }
                        }

                        // Calendar popup
                        Rectangle {
                            id: calendarPopup
                            visible: opacity > 0
                            opacity: clockSection.popupOpen ? 1 : 0
                            scale: clockSection.popupOpen ? 1 : 0.92
                            transformOrigin: Item.Bottom

                            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }
                            Behavior on scale   { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }

                            anchors.right: parent.right
                            anchors.bottom: parent.top
                            anchors.bottomMargin: Config.bar.popupOffset

                            width: 7 * calendarGrid.cellSize + Math.round(32 * Config.scale)
                            height: calHeaderRow.height
                                  + calDayNames.height
                                  + calendarGrid.height
                                  + Math.round(48 * Config.scale)

                            radius: Math.round(10 * Config.scale)
                            color: Config.colors.background
                            border.color: Config.colors.border
                            border.width: 1
                            z: 20

                            property int displayYear: new Date().getFullYear()
                            property int displayMonth: new Date().getMonth() + 1

                            onVisibleChanged: {
                                if (visible) {
                                    const now = new Date();
                                    displayYear = now.getFullYear();
                                    displayMonth = now.getMonth() + 1;
                                }
                            }

                            HoverHandler {
                                onHoveredChanged: {
                                    if (hovered) root.openPopup("clock");
                                    else root.keepPopup();
                                }
                            }

                             RowLayout {
                                id: calHeaderRow
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.topMargin: Math.round(8 * Config.scale)
                                anchors.leftMargin: Math.round(8 * Config.scale)
                                anchors.rightMargin: Math.round(8 * Config.scale)
                                spacing: 0

                                Item {
                                    width: Math.round(32 * Config.scale)
                                    height: Math.round(32 * Config.scale)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "‹"
                                        color: prevMonthMouse.containsMouse ? Config.colors.accent : Config.colors.textSecondary
                                        font.family: Config.font.family
                                        font.pixelSize: Config.bar.fontSizeStatus * 1.2
                                        Behavior on color { ColorAnimation { duration: 80 } }
                                    }
                                    MouseArea {
                                        id: prevMonthMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: root.openPopup("clock")
                                        onClicked: {
                                            if (calendarPopup.displayMonth === 1) {
                                                calendarPopup.displayMonth = 12;
                                                calendarPopup.displayYear -= 1;
                                            } else {
                                                calendarPopup.displayMonth -= 1;
                                            }
                                            root.openPopup("clock");
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: Qt.formatDate(new Date(calendarPopup.displayYear, calendarPopup.displayMonth - 1, 1), "MMMM yyyy")
                                    color: Config.colors.textPrimary
                                    font.family: Config.font.family
                                    font.pixelSize: Config.bar.fontSizeStatus
                                    font.weight: Font.Medium
                                }

                                Item {
                                    width: Math.round(32 * Config.scale)
                                    height: Math.round(32 * Config.scale)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "›"
                                        color: nextMonthMouse.containsMouse ? Config.colors.accent : Config.colors.textSecondary
                                        font.family: Config.font.family
                                        font.pixelSize: Config.bar.fontSizeStatus * 1.2
                                        Behavior on color { ColorAnimation { duration: 80 } }
                                    }
                                    MouseArea {
                                        id: nextMonthMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: root.openPopup("clock")
                                        onClicked: {
                                            if (calendarPopup.displayMonth === 12) {
                                                calendarPopup.displayMonth = 1;
                                                calendarPopup.displayYear += 1;
                                            } else {
                                                calendarPopup.displayMonth += 1;
                                            }
                                            root.openPopup("clock");
                                        }
                                    }
                                }
                            }

                            Row {
                                id: calDayNames
                                anchors.top: calHeaderRow.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.topMargin: Math.round(8 * Config.scale)

                                Repeater {
                                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                                    delegate: Text {
                                        required property string modelData
                                        width: calendarGrid.cellSize
                                        horizontalAlignment: Text.AlignHCenter
                                        text: modelData
                                        color: Config.colors.textMuted
                                        font.family: Config.font.family
                                        font.pixelSize: Math.round(Config.bar.fontSizeStatus * 0.8)
                                    }
                                }
                            }

                            Grid {
                                id: calendarGrid
                                anchors.top: calDayNames.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.topMargin: Math.round(4 * Config.scale)

                                columns: 7
                                property int cellSize: Math.round(36 * Config.scale)

                                property var cells: {
                                    const y = calendarPopup.displayYear;
                                    const m = calendarPopup.displayMonth;
                                    const firstDay = new Date(y, m - 1, 1).getDay();
                                    const offset = (firstDay + 6) % 7;
                                    const daysInMonth = new Date(y, m, 0).getDate();
                                    const arr = [];
                                    for (let i = 0; i < offset; i++) arr.push(0);
                                    for (let d = 1; d <= daysInMonth; d++) arr.push(d);
                                    while (arr.length < 42) arr.push(0);
                                    return arr;
                                }

                                width: 7 * cellSize
                                height: 6 * cellSize

                                Repeater {
                                    model: calendarGrid.cells
                                    delegate: Item {
                                        required property int modelData
                                        required property int index
                                        width: calendarGrid.cellSize
                                        height: calendarGrid.cellSize

                                        readonly property bool isToday: {
                                            const now = new Date();
                                            return modelData > 0
                                                && calendarPopup.displayYear === now.getFullYear()
                                                && calendarPopup.displayMonth === (now.getMonth() + 1)
                                                && modelData === now.getDate();
                                        }

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: calendarGrid.cellSize - Math.round(4 * Config.scale)
                                            height: width
                                            radius: width / 2
                                            color: parent.isToday
                                                ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.3)
                                                : "transparent"
                                            border.color: parent.isToday ? Config.colors.accent : "transparent"
                                            border.width: 1
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData > 0 ? modelData : ""
                                            color: parent.isToday ? Config.colors.accent : Config.colors.textSecondary
                                            font.family: Config.font.family
                                            font.pixelSize: Math.round(Config.bar.fontSizeStatus * 0.85)
                                            font.weight: parent.isToday ? Font.Medium : Font.Normal
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
