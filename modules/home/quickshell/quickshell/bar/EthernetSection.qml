pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

import ".."
import "../components"

BarSectionItem {
    id: ethSection

    // List of { device, connection, state, ip4, ip6, speed }
    property var devices: []
    property var toggling: ({})   // device name → true while connect/disconnect is running
    property bool hasEthernetDevice: false
    property string activePopup: ""
    property real availableHeight: 800

    property alias popup: ethPopup

    readonly property bool popupOpen: activePopup === "ethernet"
    readonly property bool anyConnected: ethSection.devices.some(d => d.state === "connected")

    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq
    signal keepAliveReq

    implicitHeight: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    implicitWidth: hasEthernetDevice ? Config.bar.batteryIconSize + Math.round(10 * Config.scale) : 0
    visible: hasEthernetDevice
    popupItem: ethPopup

    function barIcon() {
        if (ethSection.anyConnected)
            return "network-wired-symbolic";
        return "network-wired-disconnected-symbolic";
    }

    Component.onCompleted: {
        ethDeviceProc.running = true;
    }

    // ── Device detection ────────────────────────────────────────────────────

    Process {
        id: ethDeviceProc
        command: ["nmcli", "-t", "-f", "device,type,state,connection", "dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                const ethDevs = [];
                for (const line of lines) {
                    if (!line)
                        continue;
                    // Fields are colon-separated; connection name may contain colons,
                    // so split on first 3 colons only.
                    const parts = line.split(":");
                    if (parts.length < 3)
                        continue;
                    const type = parts[1];
                    if (type !== "ethernet")
                        continue;
                    const device = parts[0];
                    const state = parts[2];
                    // Connection name is everything after the 3rd colon
                    const connection = parts.slice(3).join(":");
                    ethDevs.push({ device, state, connection, ip4: "", ip6: "", speed: "" });
                }
                ethSection.hasEthernetDevice = ethDevs.length > 0;
                if (ethDevs.length > 0) {
                    // Enrich each device with IP + speed
                    ethSection.devices = ethDevs;
                    ethEnrichProc.pending = ethDevs.map(d => d.device);
                    ethEnrichProc.enrichedDevices = ethDevs.map(d => Object.assign({}, d));
                    ethEnrichProc.runNext();
                } else {
                    ethSection.devices = [];
                }
            }
        }
    }

    // Sequentially fetches `nmcli dev show <dev>` for each device to get IP/speed
    QtObject {
        id: ethEnrichProc

        property var pending: []
        property var enrichedDevices: []
        property string currentDevice: ""

        function runNext() {
            if (pending.length === 0) {
                ethSection.devices = enrichedDevices;
                return;
            }
            const dev = pending[0];
            pending = pending.slice(1);
            currentDevice = dev;
            ethShowProc.command = ["nmcli", "-t", "-f", "GENERAL,IP4,WIRED-PROPERTIES", "dev", "show", dev];
            ethShowProc.running = true;
        }
    }

    Process {
        id: ethShowProc
        stdout: StdioCollector {
            onStreamFinished: {
                let ip4 = "";
                let speed = "";
                let carrier = "";
                for (const line of this.text.trim().split("\n")) {
                    if (!line)
                        continue;
                    const colon = line.indexOf(":");
                    if (colon < 0)
                        continue;
                    const key = line.slice(0, colon).trim();
                    const val = line.slice(colon + 1).trim();
                    if (key === "IP4.ADDRESS[1]") {
                        // strip prefix length e.g. /24
                        ip4 = val.split("/")[0];
                    } else if (key === "WIRED-PROPERTIES.CARRIER") {
                        carrier = val; // "on" or "off"
                    }
                }

                // Read speed from sysfs (much simpler than parsing nmcli)
                const devName = ethEnrichProc.currentDevice;
                ethSpeedProc.devName = devName;
                ethSpeedProc.ip4 = ip4;
                ethSpeedProc.carrier = carrier;
                ethSpeedProc.command = ["cat", "/sys/class/net/" + devName + "/speed"];
                ethSpeedProc.running = true;
            }
        }
    }

    Process {
        id: ethSpeedProc
        property string devName: ""
        property string ip4: ""
        property string carrier: ""

        stdout: StdioCollector {
            onStreamFinished: {
                const rawSpeed = parseInt(this.text.trim());
                let speed = "";
                if (!isNaN(rawSpeed) && rawSpeed > 0) {
                    if (rawSpeed >= 1000)
                        speed = (rawSpeed / 1000) + " Gbps";
                    else
                        speed = rawSpeed + " Mbps";
                }

                // Update the enriched device entry
                const devs = ethEnrichProc.enrichedDevices.map(d => {
                    if (d.device === ethSpeedProc.devName)
                        return Object.assign({}, d, { ip4: ethSpeedProc.ip4, speed: speed, carrier: ethSpeedProc.carrier });
                    return d;
                });
                ethEnrichProc.enrichedDevices = devs;
                ethEnrichProc.runNext();
            }
        }
        onExited: code => {
            // speed file may not exist (e.g. loopback or unavailable device)
            if (code !== 0) {
                const devs = ethEnrichProc.enrichedDevices.map(d => {
                    if (d.device === ethSpeedProc.devName)
                        return Object.assign({}, d, { ip4: ethSpeedProc.ip4, carrier: ethSpeedProc.carrier });
                    return d;
                });
                ethEnrichProc.enrichedDevices = devs;
                ethEnrichProc.runNext();
            }
        }
    }

    // ── nmcli monitor for live updates ─────────────────────────────────────

    Process {
        id: ethMonitor
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.trim() !== "")
                    ethDeviceProc.running = true;
            }
        }
        onExited: Qt.callLater(() => {
            ethMonitor.running = true;
        })
    }

    // Fallback polling every 15 seconds
    Timer {
        interval: 15000
        repeat: true
        running: true
        onTriggered: ethDeviceProc.running = true
    }

    // ── Connect / Disconnect toggle ─────────────────────────────────────────

    Process {
        id: ethToggleProc
        property string targetDevice: ""
        onExited: {
            const dev = ethToggleProc.targetDevice;
            const t = Object.assign({}, ethSection.toggling);
            delete t[dev];
            ethSection.toggling = t;
            ethDeviceProc.running = true;
            ethSection.keepAliveReq();
        }
    }

    function toggleDevice(device, state) {
        if (ethSection.toggling[device])
            return;
        const t = Object.assign({}, ethSection.toggling);
        t[device] = true;
        ethSection.toggling = t;
        ethToggleProc.targetDevice = device;
        if (state === "connected")
            ethToggleProc.command = ["nmcli", "dev", "disconnect", device];
        else
            ethToggleProc.command = ["nmcli", "dev", "connect", device];
        ethToggleProc.running = true;
    }

    // ── Bar button ─────────────────────────────────────────────────────────

    MouseArea {
        id: triggerArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor
        onEntered: ethSection.openPopupReq("ethernet")
        onExited: ethSection.keepPopupReq()
    }

    BarButton {
        anchors.fill: parent
        hovered: triggerArea.containsMouse
        popupOpen: ethSection.popupOpen
        clickable: false

        IconImage {
            anchors.centerIn: parent
            implicitSize: Config.bar.batteryIconSize
            source: Quickshell.iconPath(ethSection.barIcon())
            opacity: ethSection.anyConnected ? 1.0 : Config.bar.disabledOpacity
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    // ── Popup ───────────────────────────────────────────────────────────────

    PopupContainer {
        id: ethPopup
        popupOpen: ethSection.popupOpen

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        z: 20

        readonly property real _maxHeight: ethSection.availableHeight - ethSection.height - Config.bar.popupOffset - Math.round(16 * Config.scale)
        readonly property real _contentH: popupCol.implicitHeight + Math.round(16 * Config.scale)

        width: Math.round(280 * Config.scale)
        height: Math.min(_contentH, _maxHeight)

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    ethSection.openPopupReq("ethernet");
                else
                    ethSection.exitPopupReq();
            }
        }

        PopupScrollView {
            id: scrollView
            anchors.fill: parent
            contentColumn: popupCol

            Column {
                id: popupCol
                width: scrollView.contentWidth
                spacing: Math.round(2 * Config.scale)
                y: -scrollView.scrollY

                PopupSectionHeader {
                    text: "Ethernet"
                    width: parent.width
                }

                Repeater {
                    model: ethSection.devices
                    delegate: EthernetDeviceRow {
                        id: devRow
                        required property var modelData
                        width: parent.width
                        deviceInfo: devRow.modelData
                        toggling: !!ethSection.toggling[devRow.modelData?.device ?? ""]
                        onHovered: ethSection.openPopupReq("ethernet")
                        onToggleRequested: ethSection.toggleDevice(devRow.modelData.device, devRow.modelData.state)
                    }
                }

                Text {
                    visible: ethSection.devices.length === 0
                    text: "No ethernet devices"
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizePopup
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                    topPadding: Math.round(8 * Config.scale)
                    bottomPadding: Math.round(8 * Config.scale)
                }
            }
        }
    }

    // ── Device row component ────────────────────────────────────────────────

    component EthernetDeviceRow: Rectangle {
        id: row

        property var deviceInfo: null
        property bool toggling: false

        signal hovered
        signal toggleRequested

        readonly property bool connected: row.deviceInfo?.state === "connected" ?? false
        readonly property bool available: row.deviceInfo?.state !== "unavailable" ?? false
        readonly property bool clickable: row.available && !row.toggling

        implicitHeight: rowContent.implicitHeight + Math.round(12 * Config.scale)
        radius: Math.round(6 * Config.scale)
        color: (row.clickable && rowMouse.containsMouse)
            ? (connected ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.28) : Config.colors.surfaceAlt)
            : (connected ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18) : "transparent")

        Behavior on color {
            ColorAnimation { duration: 80 }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: row.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onEntered: row.hovered()
            onClicked: if (row.clickable) row.toggleRequested()
        }

        ColumnLayout {
            id: rowContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Math.round(8 * Config.scale)
            anchors.rightMargin: Math.round(8 * Config.scale)
            spacing: Math.round(3 * Config.scale)

            opacity: (!row.available || row.toggling) ? Config.bar.disabledOpacity : 1.0
            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * Config.scale)

                IconImage {
                    implicitSize: Math.round(Config.bar.batteryIconSize * 0.78)
                    source: {
                        if (!row.available)
                            return Quickshell.iconPath("network-wired-disconnected-symbolic");
                        if (row.connected)
                            return Quickshell.iconPath("network-wired-symbolic");
                        const carrier = row.deviceInfo?.carrier ?? "";
                        if (carrier === "on")
                            return Quickshell.iconPath("network-wired-no-data-symbolic");
                        return Quickshell.iconPath("network-wired-disconnected-symbolic");
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: {
                        const conn = row.deviceInfo?.connection ?? "";
                        const dev  = row.deviceInfo?.device ?? "";
                        return conn !== "" ? conn : dev;
                    }
                    color: row.connected ? Config.colors.accent : Config.colors.textPrimary
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizePopup
                    elide: Text.ElideRight
                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }
                }

                Text {
                    visible: row.deviceInfo?.speed !== "" && row.deviceInfo?.speed !== undefined
                    text: row.deviceInfo?.speed ?? ""
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.82)
                    horizontalAlignment: Text.AlignRight
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * Config.scale)
                visible: row.deviceInfo?.device !== "" && row.deviceInfo?.device !== undefined

                Text {
                    text: row.deviceInfo?.device ?? ""
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.78)
                }

                Text {
                    visible: (row.deviceInfo?.ip4 ?? "") !== ""
                    text: row.deviceInfo?.ip4 ?? ""
                    color: Config.colors.textSecondary
                    font.family: Config.font.family
                    font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.78)
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
