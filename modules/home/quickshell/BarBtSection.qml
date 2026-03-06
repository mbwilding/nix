pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets

// Bluetooth bar section: trigger icon + dropdown popup with toggle + device list.
//
// Bar.qml binds activePopup and wires the three popup-manager signals.
Item {
    id: btSection

    // ── Public API ────────────────────────────────────────────────────────────

    property string activePopup: ""     // bound to root.activePopup

    signal openPopupReq(string name)
    signal keepPopupReq()
    signal exitPopupReq()

    // Expose the popup rectangle so Bar.qml can include it in the input mask
    property alias popup: btPopup

    // ── State ─────────────────────────────────────────────────────────────────

    readonly property var adapter: Bluetooth.defaultAdapter

    // ── Geometry ──────────────────────────────────────────────────────────────

    implicitWidth:  btRow.implicitWidth
    implicitHeight: btRow.implicitHeight

    readonly property bool popupOpen: activePopup === "bt"

    // ── Helpers ───────────────────────────────────────────────────────────────

    function btIcon() {
        const a = btSection.adapter;
        if (!a || !a.enabled) return "network-bluetooth-inactive-symbolic";
        const devs = a.devices;
        if (devs) {
            for (let i = 0; i < devs.count; i++) {
                const d = devs.get(i).modelData;
                if (d && d.connected) return "network-bluetooth-activated-symbolic";
            }
        }
        return "network-bluetooth-symbolic";
    }

    // ── Trigger ───────────────────────────────────────────────────────────────

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: btSection.openPopupReq("bt")
        onExited:  btSection.keepPopupReq()
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
        }
    }

    // ── Popup ─────────────────────────────────────────────────────────────────

    Rectangle {
        id: btPopup
        visible: opacity > 0
        opacity: btSection.popupOpen ? 1 : 0
        scale:   btSection.popupOpen ? 1 : 0.92
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
                if (hovered) btSection.openPopupReq("bt");
                else         btSection.exitPopupReq();
            }
        }

        Column {
            id: btPopupCol
            anchors.top:    parent.top
            anchors.left:   parent.left
            anchors.right:  parent.right
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
                    anchors.left:  parent.left
                    anchors.right: parent.right
                    anchors.leftMargin:  Math.round(8 * Config.scale)
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
                        text: btSection.adapter && btSection.adapter.enabled
                            ? "Bluetooth On" : "Bluetooth Off"
                        color: Config.colors.textPrimary
                        font.family:    Config.font.family
                        font.pixelSize: Config.bar.fontSizeStatus
                    }

                    Rectangle {
                        implicitWidth:  Math.round(36 * Config.scale)
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
                    onEntered: btSection.openPopupReq("bt")
                    onClicked: {
                        if (btSection.adapter)
                            btSection.adapter.enabled = !btSection.adapter.enabled;
                        btSection.openPopupReq("bt");
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
                    id: btDevEntry
                    required property var modelData
                    readonly property var  device:      modelData
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
                        anchors.left:  parent.left
                        anchors.right: parent.right
                        anchors.leftMargin:  Math.round(8 * Config.scale)
                        anchors.rightMargin: Math.round(8 * Config.scale)
                        spacing: Math.round(8 * Config.scale)

                        IconImage {
                            implicitSize: Config.bar.fontSizeStatus + Math.round(4 * Config.scale)
                            source: {
                                const d = btDevEntry.device;
                                if (!d) return "";
                                const ico = d.icon || "";
                                return Quickshell.iconPath(ico !== "" ? ico : "network-bluetooth-symbolic");
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: {
                                const d = btDevEntry.device;
                                return d ? (d.name || d.deviceName || "Unknown") : "";
                            }
                            color: btDevEntry.isConnected ? Config.colors.accent : Config.colors.textPrimary
                            font.family:    Config.font.family
                            font.pixelSize: Config.bar.fontSizeStatus
                            elide: Text.ElideRight
                        }

                        Text {
                            text: btDevEntry.isConnected ? "✓" : ""
                            color: Config.colors.accent
                            font.family:    Config.font.family
                            font.pixelSize: Config.bar.fontSizeStatus
                            visible: btDevEntry.isConnected
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
                            if (d) d.connected = !d.connected;
                            btSection.openPopupReq("bt");
                        }
                    }
                }
            }
        }
    }
}
