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

    // ── State ─────────────────────────────────────────────────────────────────

    readonly property var adapter: Bluetooth.defaultAdapter

    // Track which device address is in a pending connect/disconnect operation
    property string connectingAddress: ""

    // ── Geometry ──────────────────────────────────────────────────────────────

    implicitWidth: btRow.implicitWidth
    implicitHeight: btRow.implicitHeight

    containmentMask: Item {
        x: -btPopup.width
        y: -btPopup.height
        width: btPopup.width * 2 + btSection.width
        height: btPopup.height + btSection.height
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

    RowLayout {
        id: btRow
        spacing: Math.round(6 * Config.scale)

        IconImage {
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

        // Width tracks the widest device row (implicitWidth of the column),
        // plus flickable margins (8+4) and scrollbar track+gap (3+3) = 18 units.
        // Floor at 200, cap at 400.
        width: Math.min(
            Math.round(400 * Config.scale),
            Math.max(
                Math.round(200 * Config.scale),
                btDevListCol.implicitWidth + Math.round(18 * Config.scale)
            )
        )
        Behavior on width {
            NumberAnimation { duration: 150; easing.type: Easing.InOutCubic }
        }
        height: Math.min(
            btDevListCol.implicitHeight + Math.round(16 * Config.scale),
            Math.round(400 * Config.scale)
        )

        z: 20

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    btSection.openPopupReq("bt");
                else
                    btSection.exitPopupReq();
            }
        }

        // ── Scrollable device list ─────────────────────────────────────────

        Flickable {
            id: btFlickable
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.right: btScrollbar.left
            anchors.topMargin: Math.round(8 * Config.scale)
            anchors.bottomMargin: Math.round(8 * Config.scale)
            anchors.leftMargin: Math.round(8 * Config.scale)
            anchors.rightMargin: Math.round(4 * Config.scale)
            contentWidth: btDevListCol.implicitWidth
            contentHeight: btDevListCol.implicitHeight
            clip: true

            Column {
                id: btDevListCol
                spacing: Math.round(2 * Config.scale)

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

                Repeater {
                    model: (btSection.adapter && btSection.adapter.enabled)
                           ? btSection.adapter.devices
                           : null

                    delegate: Rectangle {
                        id: btDevEntry
                        required property var modelData
                        readonly property var device: modelData
                        // Use state enum: Connected=1, Connecting=3, Disconnecting=2, Disconnected=0
                        readonly property int devState: device ? device.state : 0
                        readonly property bool isConnected: devState === 1   // BluetoothDeviceState.Connected
                        readonly property bool isConnecting: devState === 3  // BluetoothDeviceState.Connecting
                        readonly property bool isDisconnecting: devState === 2

                        width: btDevRow.implicitWidth + Math.round(16 * Config.scale)
                        implicitHeight: btDevRow.implicitHeight + Math.round(8 * Config.scale)
                        radius: Math.round(6 * Config.scale)
                        color: isConnected
                               ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18)
                               : btDevMouse.containsMouse
                                 ? Qt.rgba(1, 1, 1, 0.07)
                                 : "transparent"
                        Behavior on color {
                            ColorAnimation { duration: 80 }
                        }

                        // Notify on state transitions
                        onDevStateChanged: {
                            const d = btDevEntry.device;
                            if (!d)
                                return;
                            const addr = d.address || "";
                            const name = btSection.deviceName(d);
                            if (btDevEntry.devState === 1 && btSection.connectingAddress === addr) {
                                // Successfully connected to device we initiated
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
                                color: btDevEntry.isConnected
                                       ? Config.colors.accent
                                       : Config.colors.textPrimary
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizeStatus
                            }

                            // Status: connecting/disconnecting spinner, check if connected
                            Text {
                                text: (btDevEntry.isConnecting || btDevEntry.isDisconnecting)
                                      ? "\u2026"
                                      : btDevEntry.isConnected
                                        ? "\u2713"
                                        : ""
                                color: Config.colors.accent
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizeStatus
                                visible: btDevEntry.isConnected || btDevEntry.isConnecting || btDevEntry.isDisconnecting
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
                                const wasConnected = btDevEntry.isConnected;
                                const name = btSection.deviceName(d);
                                btSection.connectingAddress = d.address || "";
                                if (wasConnected) {
                                    d.disconnect();
                                    // Notify disconnect after small delay (state will update)
                                    btDisconnectNotifyTimer.targetName = name;
                                    btDisconnectNotifyTimer.targetAddress = d.address || "";
                                    btDisconnectNotifyTimer.restart();
                                } else {
                                    d.connect();
                                }
                                btSection.openPopupReq("bt");
                            }
                        }
                    }
                }
            }
        }

        // Scrollbar
        Item {
            id: btScrollbar
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: Math.round(8 * Config.scale)
            anchors.bottomMargin: Math.round(8 * Config.scale)
            anchors.rightMargin: Math.round(3 * Config.scale)
            width: Math.round(3 * Config.scale)

            readonly property bool needed: btFlickable.contentHeight > btFlickable.height
            visible: needed

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Config.colors.border
            }

            Rectangle {
                readonly property real ratio: btFlickable.height / Math.max(btFlickable.contentHeight, 1)
                readonly property real thumbH: Math.max(Math.round(20 * Config.scale), btScrollbar.height * ratio)
                readonly property real travel: btScrollbar.height - thumbH
                readonly property real scrollRatio: btFlickable.contentHeight > btFlickable.height
                                                    ? btFlickable.contentY / (btFlickable.contentHeight - btFlickable.height)
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

    // ── Connection state cleanup & notifications ──────────────────────────────

    // After initiating a disconnect, notify once the device has actually disconnected.
    Timer {
        id: btDisconnectNotifyTimer
        interval: 4000
        property string targetName: ""
        property string targetAddress: ""

        onTriggered: {
            btSection.connectingAddress = "";
            // Check if device is actually disconnected now
            const devs = btSection.adapter ? btSection.adapter.devices : null;
            if (!devs)
                return;
            let found = false;
            for (let i = 0; i < devs.count; i++) {
                const d = devs.get(i).modelData;
                if (!d)
                    continue;
                if ((d.address || "") !== btDisconnectNotifyTimer.targetAddress)
                    continue;
                found = true;
                // state 0 = Disconnected, 1 = Connected
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
