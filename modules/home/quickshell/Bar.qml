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
    // popup either restarts the close timer (if pill still hovered) or starts a
    // short grace-period timer; if nothing re-claims it in time, popup closes.
    property string activePopup: ""   // "wifi" | "bt" | "volume" | "screen" | "kbd" | "power" | "clock" | ""

    readonly property bool anyPopupOpen: activePopup !== ""

    // True while the pointer is over the pill bar itself
    property bool pillHovered: false

    // Tracks the currently visible tray popup Item for the input mask
    property Item activeTrayMenuPopup: null

    function registerTrayPopup(item) { root.activeTrayMenuPopup = item; }
    function unregisterTrayPopup()   { root.activeTrayMenuPopup = null; }

    // Delegates (inside Repeaters) cannot reference section IDs directly due to
    // ComponentBehavior:Bound, so they call these root-level forwarders.
    function openPopup(name) {
        root.activePopup = name;
        popupCloseTimer.stop();
        popupCloseTimerFast.stop();
        root.keepAlive();
    }

    function keepPopup() {
        if (root.activePopup !== "") {
            // If pointer is still over the pill, use the full delay.
            // If pointer has left everything, use a short grace period so the
            // popup closes quickly when focus moves away.
            if (root.pillHovered) {
                popupCloseTimerFast.stop();
                popupCloseTimer.restart();
            } else {
                popupCloseTimer.stop();
                popupCloseTimerFast.restart();
            }
            root.keepAlive();
        }
    }

    function closePopup() {
        root.activePopup = "";
        popupCloseTimer.stop();
        popupCloseTimerFast.stop();
    }

    // Forwarders for Repeater delegates
    function keepWifiPopup()   { root.openPopup("wifi") }
    function keepBtPopup()     { root.openPopup("bt") }
    function keepVolumePopup() { root.openPopup("volume") }
    function keepScreenPopup() { root.openPopup("screen") }
    function keepKbdPopup()    { root.openPopup("kbd") }

    // Full-delay timer: runs while pointer is still over pill or popup
    Timer {
        id: popupCloseTimer
        interval: Config.bar.hideDelay
        onTriggered: root.closePopup()
    }

    // Short grace-period timer: fires when pointer has left pill+popup area
    Timer {
        id: popupCloseTimerFast
        interval: 150
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

    // Fixed-width reserve for slider popup percentage labels
    TextMetrics {
        id: statusTextMetrics
        font.family: Config.font.family
        font.pixelSize: Config.bar.fontSizeStatus
        text: "100%"
    }

    readonly property int sliderLabelWidth: Math.round(statusTextMetrics.boundingRect.width + 4 * Config.scale)

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

    // ── Screen & Keyboard brightness ─────────────────────────────────────────

    property string screenDevice: ""
    property string kbdDevice: ""
    property int _screenMax: 1
    property int _screenRaw: -1
    property int _kbdMax: 1
    property int _kbdRaw: -1
    property real screenBrightness: 0   // 0..1
    property real kbdBrightness: 0      // 0..1
    readonly property bool screenAvailable: _screenMax > 1
    readonly property bool kbdAvailable: _kbdMax > 1

    Process {
        command: ["sh", "-c", "ls /sys/class/backlight/ | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const dev = this.text.trim();
                if (dev) root.screenDevice = "/sys/class/backlight/" + dev;
            }
        }
    }

    Process {
        command: ["sh", "-c", "ls /sys/class/leds/ | grep kbd_backlight | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const dev = this.text.trim();
                if (dev) root.kbdDevice = "/sys/class/leds/" + dev;
            }
        }
    }

    Process {
        command: ["cat", root.screenDevice + "/max_brightness"]
        running: root.screenDevice !== ""
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v > 0) root._screenMax = v;
            }
        }
    }

    Process {
        command: ["cat", root.kbdDevice + "/max_brightness"]
        running: root.kbdDevice !== ""
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v > 0) root._kbdMax = v;
            }
        }
    }

    Timer {
        interval: 200
        repeat: true
        running: root.screenDevice !== ""
        onTriggered: screenPollProc.running = true
    }

    Process {
        id: screenPollProc
        command: ["cat", root.screenDevice + "/brightness"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v !== root._screenRaw) {
                    root._screenRaw = v;
                    root.screenBrightness = root._screenMax > 0 ? v / root._screenMax : 0;
                }
            }
        }
    }

    Timer {
        interval: 200
        repeat: true
        running: root.kbdDevice !== ""
        onTriggered: kbdPollProc.running = true
    }

    Process {
        id: kbdPollProc
        command: ["cat", root.kbdDevice + "/brightness"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v !== root._kbdRaw) {
                    root._kbdRaw = v;
                    root.kbdBrightness = root._kbdMax > 0 ? v / root._kbdMax : 0;
                }
            }
        }
    }

    // Write brightness via brightnessctl (doesn't need root if user is in video group)
    Process {
        id: screenBrightnessProc
    }

    Process {
        id: kbdBrightnessProc
    }

    function setScreenBrightness(frac) {
        const raw = Math.round(frac * root._screenMax);
        screenBrightnessProc.command = ["brightnessctl", "--device=" + root.screenDevice.split("/").pop(), "set", String(raw)];
        screenBrightnessProc.running = true;
    }

    function setKbdBrightness(frac) {
        const raw = Math.round(frac * root._kbdMax);
        kbdBrightnessProc.command = ["brightnessctl", "--device=" + root.kbdDevice.split("/").pop(), "set", String(raw)];
        kbdBrightnessProc.running = true;
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

    // ── Reusable horizontal-slider popup ─────────────────────────────────────
    // Used by volume, screen brightness, and keyboard brightness sections.
    // Layout: [icon] [====track====] [pct]
    // Parent must position it (anchors.bottom: parent.top, etc.)
    component SliderPopup: Rectangle {
        id: sliderPopup

        property string popupName: ""   // "volume" | "screen" | "kbd"
        property string iconName: ""    // icon to show inside the popup
        property real fraction: 0       // 0..1  current value
        property string label: Math.round(fraction * 100) + "%"
        signal setFraction(real v)      // emitted when user drags/clicks
        signal scrollDelta(real delta)  // emitted on mouse wheel (+/- 1 per notch)

        readonly property bool popupOpen: root.activePopup === popupName

        visible: opacity > 0
        opacity: popupOpen ? 1 : 0
        scale: popupOpen ? 1 : 0.92
        transformOrigin: Item.Bottom

        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }
        Behavior on scale   { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }

        // Wide flat pill
        width: Math.round(240 * Config.scale)
        height: Math.round(56 * Config.scale)

        radius: Math.round(10 * Config.scale)
        color: Config.colors.background
        border.color: Config.colors.border
        border.width: 1
        z: 20

        HoverHandler {
            onHoveredChanged: {
                if (hovered) root.openPopup(sliderPopup.popupName);
                else root.keepPopup();
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.round(12 * Config.scale)
            anchors.rightMargin: Math.round(12 * Config.scale)
            spacing: Math.round(10 * Config.scale)

            // Icon
            IconImage {
                implicitSize: Config.bar.batteryIconSize
                source: Quickshell.iconPath(sliderPopup.iconName)
            }

            // Track area — fills remaining space
            Item {
                id: sliderTrack
                Layout.fillWidth: true
                height: Math.round(20 * Config.scale)

                readonly property real trackW: width
                readonly property real frac: Math.max(0, Math.min(1, sliderPopup.fraction))

                // Background rail
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    width: parent.trackW
                    height: Math.round(6 * Config.scale)
                    radius: height / 2
                    color: Config.colors.border
                }

                // Filled portion
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    width: parent.trackW * parent.frac
                    height: Math.round(6 * Config.scale)
                    radius: height / 2
                    color: Config.colors.accent
                }

                // Thumb
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.trackW * parent.frac - width / 2
                    width: Math.round(14 * Config.scale)
                    height: width
                    radius: width / 2
                    color: Config.colors.accent
                    Behavior on x { NumberAnimation { duration: 60 } }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.SizeHorCursor
                    onEntered: root.openPopup(sliderPopup.popupName)

                    function setFromX(mx) {
                        const v = Math.max(0, Math.min(1, mx / sliderTrack.trackW));
                        sliderPopup.setFraction(v);
                        root.openPopup(sliderPopup.popupName);
                    }

                    onPressed: mouse => setFromX(mouse.x)
                    onPositionChanged: mouse => { if (pressed) setFromX(mouse.x) }
                    onWheel: wheel => {
                        sliderPopup.scrollDelta(wheel.angleDelta.y / 120);
                        root.openPopup(sliderPopup.popupName);
                    }
                }
            }

            // Percentage label
            Text {
                text: sliderPopup.label
                color: Config.colors.textSecondary
                font.family: Config.font.family
                font.pixelSize: Config.bar.fontSizeStatus
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: root.sliderLabelWidth
                Layout.fillWidth: false
            }
        }
    }

    // ── Window ───────────────────────────────────────────────────────────────

    PanelWindow {
        id: win

        WlrLayershell.layer: WlrLayer.Top
        anchors.bottom: true
        exclusiveZone: 0
        color: "transparent"

        implicitWidth: win.screen ? win.screen.width : 1920
        implicitHeight: win.screen ? win.screen.height : 1080

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
                item: root.activePopup === "screen" ? screenPopup : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "kbd" ? kbdPopup : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "battery" ? batteryPopup : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "power" ? powerPopup : null
                intersection: Intersection.Combine
            }
            Region {
                    item: root.activePopup === "clock" ? calendarPopup : null
                    intersection: Intersection.Combine
                }
                Region {
                    item: root.activeTrayMenuPopup
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
                onHoveredChanged: {
                    root.pillHovered = hovered;
                    if (hovered) root.keepAlive()
                }
            }

            RowLayout {
                id: content
                anchors.centerIn: parent
                spacing: Config.bar.sectionSpacing

                // ── Tray ─────────────────────────────────────────────────────
                Repeater {
                    id: trayRepeater
                    model: SystemTray.items
                    delegate: BarTrayItem {
                        id: trayDelegate
                        required property SystemTrayItem modelData
                        required property int index
                        trayItem: modelData
                        popupName: "tray-" + trayDelegate.index
                        activePopup: root.activePopup
                        onHovered: root.keepAlive()
                        onOpenPopupReq: name => {
                            root.openPopup(name)
                            root.registerTrayPopup(trayDelegate.menuPopup)
                        }
                        onKeepPopupReq: root.keepPopup()
                        onPopupOpenChanged: {
                            if (!trayDelegate.popupOpen)
                                root.unregisterTrayPopup()
                        }
                    }
                }

                Rectangle {
                    implicitWidth: 1
                    implicitHeight: Config.bar.batteryIconSize
                    color: Config.colors.border
                    visible: trayRepeater.count > 0
                }

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
                                id: wifiFlickable
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom
                                anchors.right: wifiScrollbar.left
                                anchors.topMargin: Math.round(8 * Config.scale)
                                anchors.leftMargin: Math.round(8 * Config.scale)
                                anchors.bottomMargin: Math.round(8 * Config.scale)
                                anchors.rightMargin: Math.round(4 * Config.scale)
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
                                }
                            }  // Flickable

                            // Scrollbar track
                            Item {
                                id: wifiScrollbar
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.topMargin: Math.round(8 * Config.scale)
                                anchors.rightMargin: Math.round(6 * Config.scale)
                                anchors.bottomMargin: Math.round(8 * Config.scale)
                                width: Math.round(3 * Config.scale)

                                readonly property bool needed: wifiFlickable.contentHeight > wifiFlickable.height
                                visible: needed

                                // Track
                                Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: Config.colors.border
                                }

                                // Thumb
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

                                    Behavior on y { NumberAnimation { duration: 60 } }
                                }
                            }
                        }
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

                    // ── Volume section ────────────────────────────────────────
                    Item {
                        id: volumeSection
                        implicitWidth: volumeRow.implicitWidth
                        implicitHeight: volumeRow.implicitHeight

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
                                    a.volume = Math.max(0, Math.min(1.0, a.volume + (wheel.angleDelta.y / 120) * 0.05));
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
                        }

                        SliderPopup {
                            id: volumePopup
                            popupName: "volume"
                            iconName: root.volumeIcon()
                            fraction: Math.min(volumeSection.audio?.volume ?? 0, 1.0)
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.top
                            anchors.bottomMargin: Config.bar.popupOffset

                            onSetFraction: v => {
                                const a = volumeSection.audio;
                                if (a) a.volume = v;
                            }
                            onScrollDelta: delta => {
                                const a = volumeSection.audio;
                                if (a) a.volume = Math.max(0, Math.min(1.0, a.volume + delta * 0.05));
                            }
                        }
                    }

                    // ── Screen brightness section ──────────────────────────────
                    Item {
                        id: screenSection
                        implicitWidth: screenRow.implicitWidth
                        implicitHeight: screenRow.implicitHeight
                        visible: root.screenAvailable

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.openPopup("screen")
                            onExited: root.keepPopup()
                            onWheel: wheel => {
                                const delta = wheel.angleDelta.y / 120;
                                root.setScreenBrightness(Math.max(0, Math.min(1, root.screenBrightness + delta * 0.05)));
                                root.keepAlive();
                            }
                        }

                        RowLayout {
                            id: screenRow
                            spacing: Math.round(6 * Config.scale)

                            IconImage {
                                implicitSize: Config.bar.batteryIconSize
                                source: Quickshell.iconPath("video-display-brightness-symbolic")
                            }
                        }

                        SliderPopup {
                            id: screenPopup
                            popupName: "screen"
                            iconName: "video-display-brightness-symbolic"
                            fraction: root.screenBrightness
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.top
                            anchors.bottomMargin: Config.bar.popupOffset

                            onSetFraction: v => root.setScreenBrightness(v)
                            onScrollDelta: delta => {
                                root.setScreenBrightness(Math.max(0, Math.min(1, root.screenBrightness + delta * 0.05)));
                            }
                        }
                    }

                    // ── Keyboard brightness section ────────────────────────────
                    Item {
                        id: kbdSection
                        implicitWidth: kbdRow.implicitWidth
                        implicitHeight: kbdRow.implicitHeight
                        visible: root.kbdAvailable

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.openPopup("kbd")
                            onExited: root.keepPopup()
                            onWheel: wheel => {
                                const delta = wheel.angleDelta.y / 120;
                                root.setKbdBrightness(Math.max(0, Math.min(1, root.kbdBrightness + delta * 0.05)));
                                root.keepAlive();
                            }
                        }

                        RowLayout {
                            id: kbdRow
                            spacing: Math.round(6 * Config.scale)

                            IconImage {
                                implicitSize: Config.bar.batteryIconSize
                                source: Quickshell.iconPath("input-keyboard-brightness")
                            }
                        }

                        SliderPopup {
                            id: kbdPopup
                            popupName: "kbd"
                            iconName: "input-keyboard-brightness"
                            fraction: root.kbdBrightness
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.top
                            anchors.bottomMargin: Config.bar.popupOffset

                            onSetFraction: v => root.setKbdBrightness(v)
                            onScrollDelta: delta => {
                                root.setKbdBrightness(Math.max(0, Math.min(1, root.kbdBrightness + delta * 0.05)));
                            }
                        }
                    }

                    // ── Battery ───────────────────────────────────────────────
                    Item {
                        id: batterySection
                        implicitWidth: batteryIcon.implicitWidth
                        implicitHeight: batteryIcon.implicitHeight
                        visible: root.battery !== null && root.battery.isLaptopBattery

                        readonly property bool popupOpen: root.activePopup === "battery"
                        readonly property var b: root.battery

                        HoverHandler {
                            onHoveredChanged: {
                                if (hovered) root.openPopup("battery")
                                else root.keepPopup()
                            }
                        }

                        IconImage {
                            id: batteryIcon
                            implicitSize: Config.bar.batteryIconSize
                            source: {
                                const b = batterySection.b;
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

                        // Battery popup — icon + optional charging icon + percentage
                        Rectangle {
                            id: batteryPopup
                            visible: opacity > 0
                            opacity: batterySection.popupOpen ? 1 : 0
                            scale: batterySection.popupOpen ? 1 : 0.92
                            transformOrigin: Item.Bottom

                            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }
                            Behavior on scale   { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }

                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.top
                            anchors.bottomMargin: Config.bar.popupOffset

                            height: Math.round(56 * Config.scale)
                            width: batteryPopupRow.implicitWidth + Math.round(24 * Config.scale)

                            radius: Math.round(10 * Config.scale)
                            color: Config.colors.background
                            border.color: Config.colors.border
                            border.width: 1
                            z: 20

                            HoverHandler {
                                onHoveredChanged: {
                                    if (hovered) root.openPopup("battery")
                                    else root.keepPopup()
                                }
                            }

                            RowLayout {
                                id: batteryPopupRow
                                anchors.centerIn: parent
                                spacing: Math.round(8 * Config.scale)

                                // Battery level icon
                                IconImage {
                                    implicitSize: Config.bar.batteryIconSize
                                    source: batteryIcon.source
                                }

                                // Charging bolt — visible when charging or full
                                IconImage {
                                    implicitSize: Config.bar.batteryIconSize
                                    source: Quickshell.iconPath("battery-full-charging-symbolic")
                                    visible: {
                                        const b = batterySection.b;
                                        return b && (b.state === UPowerDeviceState.Charging
                                                  || b.state === UPowerDeviceState.FullyCharged);
                                    }
                                }

                                // Percentage
                                Text {
                                    text: {
                                        const b = batterySection.b;
                                        if (!b || !b.isLaptopBattery) return "";
                                        return Math.round(b.percentage * 100) + "%";
                                    }
                                    color: {
                                        const b = batterySection.b;
                                        if (!b) return Config.colors.textSecondary;
                                        const pct = b.percentage * 100;
                                        if (pct <= 10) return "#ff6060";
                                        if (pct <= 20) return "#ffaa60";
                                        return Config.colors.textSecondary;
                                    }
                                    font.family: Config.font.family
                                    font.pixelSize: Config.bar.fontSizeStatus
                                }
                            }
                        }
                    }

                    // ── Power profiles ────────────────────────────────────────
                    Item {
                        id: powerSection
                        implicitWidth: powerGlyphText.implicitWidth + Math.round(10 * Config.scale)
                        implicitHeight: powerGlyphText.implicitHeight + Math.round(6 * Config.scale)

                        readonly property bool popupOpen: root.activePopup === "power"

                        readonly property var profiles: [
                            { profile: PowerProfile.PowerSaver,  glyph: "󰌪", label: "Power Saver" },
                            { profile: PowerProfile.Balanced,    glyph: "󰗑", label: "Balanced" },
                            { profile: PowerProfile.Performance, glyph: "󰓅", label: "Performance" }
                        ]

                        readonly property var activeProfile: {
                            for (let i = 0; i < profiles.length; i++)
                                if (PowerProfiles.profile === profiles[i].profile) return profiles[i];
                            return profiles[1]; // fallback to Balanced
                        }

                        MouseArea {
                            id: powerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.openPopup("power")
                            onExited: root.keepPopup()
                        }

                        // Active profile glyph
                        Text {
                            id: powerGlyphText
                            anchors.centerIn: parent
                            text: powerSection.activeProfile.glyph
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.powerIconSize
                            color: Config.colors.textSecondary
                        }

                        // Power profile popup — vertical list of profile rows
                        Rectangle {
                            id: powerPopup
                            visible: opacity > 0
                            opacity: powerSection.popupOpen ? 1 : 0
                            scale: powerSection.popupOpen ? 1 : 0.92
                            transformOrigin: Item.Bottom

                            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }
                            Behavior on scale   { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }

                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.top
                            anchors.bottomMargin: Config.bar.popupOffset

                            width: powerPopupCol.implicitWidth + Math.round(16 * Config.scale)
                            height: powerPopupCol.implicitHeight + Math.round(16 * Config.scale)

                            radius: Math.round(10 * Config.scale)
                            color: Config.colors.background
                            border.color: Config.colors.border
                            border.width: 1
                            z: 20

                            HoverHandler {
                                onHoveredChanged: {
                                    if (hovered) root.openPopup("power");
                                    else root.keepPopup();
                                }
                            }

                            Column {
                                id: powerPopupCol
                                anchors.centerIn: parent
                                spacing: Math.round(2 * Config.scale)

                                 Repeater {
                                    model: powerSection.profiles
                                    delegate: Rectangle {
                                        id: profileDelegate
                                        required property var modelData
                                        readonly property bool isActive: PowerProfiles.profile === modelData.profile
                                        readonly property bool isPerf: modelData.profile === PowerProfile.Performance
                                        visible: !isPerf || PowerProfiles.hasPerformanceProfile

                                        implicitWidth: profileRow.implicitWidth + Math.round(16 * Config.scale)
                                        implicitHeight: profileRow.implicitHeight + Math.round(10 * Config.scale)
                                        radius: Math.round(6 * Config.scale)

                                        color: isActive
                                            ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18)
                                            : (profileMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent")
                                        Behavior on color { ColorAnimation { duration: 80 } }

                                        RowLayout {
                                            id: profileRow
                                            anchors.centerIn: parent
                                            spacing: Math.round(8 * Config.scale)

                                            Text {
                                                text: profileDelegate.modelData.glyph
                                                font.family: Config.font.family
                                                font.pixelSize: Config.bar.powerIconSize
                                                color: profileDelegate.isActive ? Config.colors.accent : Config.colors.textSecondary
                                                Behavior on color { ColorAnimation { duration: 100 } }
                                            }

                                            Text {
                                                text: profileDelegate.modelData.label
                                                font.family: Config.font.family
                                                font.pixelSize: Config.bar.fontSizeStatus
                                                color: profileDelegate.isActive ? Config.colors.accent : Config.colors.textPrimary
                                                Behavior on color { ColorAnimation { duration: 100 } }
                                            }
                                        }

                                        MouseArea {
                                            id: profileMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onEntered: root.openPopup("power")
                                            onClicked: {
                                                PowerProfiles.profile = profileDelegate.modelData.profile;
                                                root.openPopup("power");
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
