pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Widgets
import "components"

// BluetoothDeviceState enum values: Disconnected=0, Connected=1, Disconnecting=2, Connecting=3

// Bluetooth bar section: trigger icon + dropdown popup with device list.
//
// Clicking the bar icon toggles Bluetooth on/off.
// Bar.qml binds activePopup and wires the three popup-manager signals.
Item {
    id: btSection

    // ── Public API ────────────────────────────────────────────────────────────

    property string activePopup: ""     // bound to root.activePopup

    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq

    // Expose the popup rectangle so Bar.qml can include it in the input mask
    property alias popup: btPopup

    // Screen height passed in from Bar.qml so the popup can cap itself.
    property real availableHeight: 800

    // ── State ─────────────────────────────────────────────────────────────────

    readonly property var adapter: Bluetooth.defaultAdapter

    // Track which device address is in a pending connect/disconnect operation
    property string connectingAddress: ""

    // Count of currently connected devices — maintained by delegate onDevStateChanged.
    // Used to show/hide the separator between available and connected lists.
    property int btConnectedCount: 0

    // ── Geometry ──────────────────────────────────────────────────────────────

    implicitWidth: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    implicitHeight: Config.bar.batteryIconSize + Math.round(10 * Config.scale)

    containmentMask: Item {
        x: btSection.popupOpen ? -Math.max(0, (btPopup.width - btSection.width) / 2) : 0
        y: btSection.popupOpen ? -btPopup.height - Config.bar.popupOffset : 0
        width: btSection.popupOpen ? Math.max(btSection.width, btPopup.width) : btSection.width
        height: btSection.popupOpen ? btPopup.height + Config.bar.popupOffset + btSection.height : btSection.height
    }

    readonly property bool popupOpen: activePopup === "bt"

    onPopupOpenChanged: {
        const a = btSection.adapter;
        if (!a || !a.enabled)
            return;
        a.discovering = btSection.popupOpen;
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    function btIcon() {
        const a = btSection.adapter;
        if (!a || !a.enabled)
            return "network-bluetooth-inactive-symbolic";
        const devs = a.devices;
        if (devs) {
            for (let i = 0; i < devs.count; i++) {
                const d = devs.get(i).modelData;
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

    // ── Notification helper ───────────────────────────────────────────────────

    Process {
        id: btNotifyProc
    }

    function btNotify(title, message, icon) {
        btNotifyProc.command = [
            "notify-send",
            "--app-name=Bluetooth",
            "--app-icon=" + icon,
            title,
            message
        ];
        btNotifyProc.running = true;
    }

    // ── Trigger ───────────────────────────────────────────────────────────────

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
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
        }
    }

    // ── Popup ─────────────────────────────────────────────────────────────────

    PopupContainer {
        id: btPopup
        popupOpen: btSection.popupOpen

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        // Width driven by the widest device name text + icon + padding, measured via TextMetrics.
        readonly property real iconSize: Config.bar.fontSizeStatus + Math.round(4 * Config.scale)
        readonly property real rowPadding: Math.round(8 * Config.scale) * 2 + Math.round(8 * Config.scale) + Math.round(18 * Config.scale)
        readonly property real contentWidth: {
            let maxW = 0;
            const a = btSection.adapter;
            const devs = (a && a.enabled) ? a.devices : null;
            if (devs) {
                for (let i = 0; i < devs.count; i++) {
                    const d = devs.get(i).modelData;
                    if (!d) continue;
                    btPopupTextMetrics.text = btSection.deviceName(d);
                    const w = btPopupTextMetrics.boundingRect.width;
                    if (w > maxW) maxW = w;
                }
            }
            return maxW + btPopup.iconSize + btPopup.rowPadding;
        }
        width: Math.max(Math.round(200 * Config.scale), btPopup.contentWidth)
        Behavior on width {
            NumberAnimation { duration: 150; easing.type: Easing.InOutCubic }
        }

        // Max usable height: screen height minus bar pill, offset, and a small margin.
        readonly property real maxHeight: btSection.availableHeight
                                          - btSection.height
                                          - Config.bar.popupOffset
                                          - Math.round(16 * Config.scale)
        // Content height including padding.
        readonly property real contentPadded: btDevListCol.implicitHeight + Math.round(16 * Config.scale)
        // Popup height: full content unless it exceeds the screen.
        height: Math.min(contentPadded, maxHeight)

        z: 20

        TextMetrics {
            id: btPopupTextMetrics
            font.family: Config.font.family
            font.pixelSize: Config.bar.fontSizeStatus
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    btSection.openPopupReq("bt");
                else
                    btSection.exitPopupReq();
            }
        }

        // ── Device list (no drag — scroll-only via WheelHandler) ──────────

        // Track scroll offset manually.
        property real scrollY: 0
        // Clamp scrollY whenever content or popup height changes.
        readonly property real maxScrollY: Math.max(0, btDevListCol.implicitHeight - btListViewport.height)
        onMaxScrollYChanged: {
            if (btPopup.scrollY > btPopup.maxScrollY)
                btPopup.scrollY = btPopup.maxScrollY;
        }

        WheelHandler {
            target: null
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                const step = Math.round(40 * Config.scale);
                btPopup.scrollY = Math.max(0,
                    Math.min(btPopup.maxScrollY,
                        btPopup.scrollY - event.angleDelta.y / 120 * step));
            }
        }

        Item {
            id: btListViewport
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.right: btScrollbar.left
            anchors.topMargin: Math.round(8 * Config.scale)
            anchors.bottomMargin: Math.round(8 * Config.scale)
            anchors.leftMargin: Math.round(8 * Config.scale)
            anchors.rightMargin: Math.round(4 * Config.scale)
            clip: true

            Column {
                id: btDevListCol
                spacing: Math.round(2 * Config.scale)
                y: -btPopup.scrollY

                // ── Empty-state placeholder ───────────────────────────────
                Text {
                    text: {
                        const a = btSection.adapter;
                        if (!a || !a.enabled)
                            return "Bluetooth is off";
                        if (!a.devices || a.devices.count === 0)
                            return a.discovering ? "Scanning\u2026" : "No paired devices";
                        return "";
                    }
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizeStatus
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: Math.round(8 * Config.scale)
                    bottomPadding: Math.round(8 * Config.scale)
                    leftPadding: Math.round(16 * Config.scale)
                    rightPadding: Math.round(16 * Config.scale)
                    visible: {
                        const a = btSection.adapter;
                        return !a || !a.enabled || !a.devices || a.devices.count === 0;
                    }
                }

                // ── Available (non-connected) devices ─────────────────────
                Repeater {
                    model: (btSection.adapter && btSection.adapter.enabled)
                           ? btSection.adapter.devices
                           : null

                    delegate: Rectangle {
                        id: btDevEntry
                        required property var modelData
                        readonly property var device: modelData
                        readonly property int devState: device ? device.state : 0
                        readonly property bool isConnected: devState === 1
                        readonly property bool isConnecting: devState === 3
                        readonly property bool isDisconnecting: devState === 2

                        // Only show non-connected devices in this repeater.
                        visible: !isConnected

                        width: btListViewport.width
                        implicitWidth: btDevRow.implicitWidth + Math.round(16 * Config.scale)
                        implicitHeight: btDevRow.implicitHeight + Math.round(8 * Config.scale)
                        radius: Math.round(6 * Config.scale)
                        color: btDevMouse.containsMouse
                               ? Qt.rgba(1, 1, 1, 0.07)
                               : "transparent"
                        Behavior on color {
                            ColorAnimation { duration: 80 }
                        }

                        onDevStateChanged: {
                            const d = btDevEntry.device;
                            if (!d)
                                return;
                            const addr = d.address || "";
                            const name = btSection.deviceName(d);
                            if (btDevEntry.devState === 1 && btSection.connectingAddress === addr) {
                                btSection.connectingAddress = "";
                                btSection.btNotify(
                                    "Bluetooth Connected",
                                    "Connected to " + name,
                                    "network-bluetooth-activated-symbolic"
                                );
                            }
                        }

                        RowLayout {
                            id: btDevRow
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: Math.round(8 * Config.scale)
                            spacing: Math.round(8 * Config.scale)

                            IconImage {
                                implicitSize: Config.bar.fontSizeStatus + Math.round(4 * Config.scale)
                                source: Quickshell.iconPath(btSection.deviceIcon(btDevEntry.device))
                            }

                            Text {
                                text: btSection.deviceName(btDevEntry.device)
                                color: Config.colors.textPrimary
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizeStatus
                            }

                            Text {
                                text: (btDevEntry.isConnecting || btDevEntry.isDisconnecting)
                                      ? "\u2026"
                                      : ""
                                color: Config.colors.accent
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizeStatus
                                visible: btDevEntry.isConnecting || btDevEntry.isDisconnecting
                            }
                        }

                        MouseArea {
                            id: btDevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: btSection.openPopupReq("bt")
                            onClicked: {
                                const d = btDevEntry.device;
                                if (!d || btDevEntry.isConnecting || btDevEntry.isDisconnecting)
                                    return;
                                btSection.connectingAddress = d.address || "";
                                d.connect();
                                btSection.openPopupReq("bt");
                            }
                        }
                    }
                }

                // ── Separator ─────────────────────────────────────────────
                Rectangle {
                    // Show only when there are both connected and non-connected devices.
                    readonly property int totalCount: {
                        const a = btSection.adapter;
                        return (a && a.enabled && a.devices) ? a.devices.count : 0;
                    }
                    visible: btSection.btConnectedCount > 0
                             && btSection.btConnectedCount < totalCount
                    width: btListViewport.width
                    height: Math.round(1 * Config.scale)
                    color: Config.colors.border
                }

                // ── Connected devices (pinned to bottom) ──────────────────
                Repeater {
                    model: (btSection.adapter && btSection.adapter.enabled)
                           ? btSection.adapter.devices
                           : null

                    delegate: Rectangle {
                        id: btConnectedEntry
                        required property var modelData
                        readonly property var device: modelData
                        readonly property int devState: device ? device.state : 0
                        readonly property bool isConnected: devState === 1
                        readonly property bool isConnecting: devState === 3
                        readonly property bool isDisconnecting: devState === 2

                        // Only show connected devices in this repeater.
                        visible: isConnected

                        // Maintain btSection.btConnectedCount for separator visibility.
                        onIsConnectedChanged: {
                            btSection.btConnectedCount += btConnectedEntry.isConnected ? 1 : -1;
                        }
                        Component.onCompleted: {
                            if (btConnectedEntry.isConnected)
                                btSection.btConnectedCount++;
                        }
                        Component.onDestruction: {
                            if (btConnectedEntry.isConnected)
                                btSection.btConnectedCount--;
                        }

                        width: btListViewport.width
                        implicitWidth: btConnectedRow.implicitWidth + Math.round(16 * Config.scale)
                        implicitHeight: btConnectedRow.implicitHeight + Math.round(8 * Config.scale)
                        radius: Math.round(6 * Config.scale)
                        color: btConnectedMouse.containsMouse
                               ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.28)
                               : Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18)
                        Behavior on color {
                            ColorAnimation { duration: 80 }
                        }

                        RowLayout {
                            id: btConnectedRow
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: Math.round(8 * Config.scale)
                            spacing: Math.round(8 * Config.scale)

                            IconImage {
                                implicitSize: Config.bar.fontSizeStatus + Math.round(4 * Config.scale)
                                source: Quickshell.iconPath(btSection.deviceIcon(btConnectedEntry.device))
                            }

                            Text {
                                text: btSection.deviceName(btConnectedEntry.device)
                                color: Config.colors.accent
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizeStatus
                            }

                            Text {
                                text: btConnectedEntry.isDisconnecting ? "\u2026" : "\u2713"
                                color: Config.colors.accent
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizeStatus
                            }
                        }

                        MouseArea {
                            id: btConnectedMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: btSection.openPopupReq("bt")
                            onClicked: {
                                const d = btConnectedEntry.device;
                                if (!d || btConnectedEntry.isDisconnecting)
                                    return;
                                const name = btSection.deviceName(d);
                                btSection.connectingAddress = d.address || "";
                                d.disconnect();
                                btDisconnectNotifyTimer.targetName = name;
                                btDisconnectNotifyTimer.targetAddress = d.address || "";
                                btDisconnectNotifyTimer.restart();
                                btSection.openPopupReq("bt");
                            }
                        }
                    }
                }
            }
        }

        // Scrollbar column — always present so viewport width is stable.
        // Track rectangle always visible; thumb only shown when content overflows.
        Item {
            id: btScrollbar
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: Math.round(8 * Config.scale)
            anchors.bottomMargin: Math.round(8 * Config.scale)
            anchors.rightMargin: Math.round(3 * Config.scale)
            width: Math.round(3 * Config.scale)

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Config.colors.border
                visible: btPopup.maxScrollY > 0
            }

            Rectangle {
                readonly property real ratio: btListViewport.height / Math.max(btDevListCol.implicitHeight, 1)
                readonly property real thumbH: Math.max(Math.round(20 * Config.scale), btScrollbar.height * ratio)
                readonly property real travel: btScrollbar.height - thumbH
                readonly property real scrollRatio: btPopup.maxScrollY > 0
                                                    ? btPopup.scrollY / btPopup.maxScrollY
                                                    : 0

                width: parent.width
                height: thumbH
                y: travel * scrollRatio
                radius: width / 2
                color: Config.colors.textMuted
                visible: btPopup.maxScrollY > 0
                Behavior on y {
                    NumberAnimation { duration: 60 }
                }
            }
        }
    }

    // ── Connection state cleanup & notifications ──────────────────────────────

    // After initiating a disconnect, notify once the device has actually disconnected.
    Timer {
        id: btDisconnectNotifyTimer
        interval: 4000
        property string targetName: ""
        property string targetAddress: ""

        onTriggered: {
            btSection.connectingAddress = "";
            const devs = btSection.adapter ? btSection.adapter.devices : null;
            if (!devs)
                return;
            for (let i = 0; i < devs.count; i++) {
                const d = devs.get(i).modelData;
                if (!d)
                    continue;
                if ((d.address || "") !== btDisconnectNotifyTimer.targetAddress)
                    continue;
                if (d.state === 0) {
                    btSection.btNotify(
                        "Bluetooth Disconnected",
                        "Disconnected from " + btDisconnectNotifyTimer.targetName,
                        "network-bluetooth-symbolic"
                    );
                }
                break;
            }
        }
    }
}
