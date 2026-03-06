pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Widgets

// Battery bar section: level icon trigger + small popup showing pct + charging status.
//
// Bar.qml binds activePopup and wires the popup-manager signals.
Item {
    id: batterySection

    // ── Public API ────────────────────────────────────────────────────────────

    property string activePopup: ""     // bound to root.activePopup

    signal openPopupReq(string name)
    signal exitPopupReq

    // Expose the popup rectangle so Bar.qml can include it in the input mask
    property alias popup: batteryPopup

    // ── State ─────────────────────────────────────────────────────────────────

    readonly property var b: UPower.displayDevice

    // ── Geometry ──────────────────────────────────────────────────────────────

    implicitWidth: batteryIcon.implicitWidth
    implicitHeight: batteryIcon.implicitHeight
    visible: b !== null && b.isLaptopBattery

    readonly property bool popupOpen: activePopup === "battery"

    // ── Trigger ───────────────────────────────────────────────────────────────

    HoverHandler {
        onHoveredChanged: {
            if (hovered)
                batterySection.openPopupReq("battery");
            else
                batterySection.exitPopupReq();
        }
    }

    IconImage {
        id: batteryIcon
        implicitSize: Config.bar.batteryIconSize
        source: {
            const b = batterySection.b;
            if (!b || !b.isLaptopBattery)
                return "";
            const pct = Math.round(b.percentage * 100);
            const charging = b.state === UPowerDeviceState.Charging || b.state === UPowerDeviceState.FullyCharged;
            const level = Math.min(100, Math.round(pct / 10) * 10);
            const lvlStr = String(level).padStart(3, "0");
            const chargeSuffix = charging ? "-charging" : "";
            return Quickshell.iconPath("battery-" + lvlStr + chargeSuffix + "-symbolic");
        }
    }

    // ── Popup ─────────────────────────────────────────────────────────────────

    Rectangle {
        id: batteryPopup
        visible: opacity > 0
        opacity: batterySection.popupOpen ? 1 : 0
        scale: batterySection.popupOpen ? 1 : 0.90
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

        height: Math.round(56 * Config.scale)
        width: batteryPopupRow.implicitWidth + Math.round(28 * Config.scale)

        radius: Math.round(Config.bar.popupRadius * Config.scale)
        color: Qt.rgba(0.12, 0.11, 0.22, 0.95)
        border.color: Config.colors.border
        border.width: 1
        clip: true
        z: 20

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    batterySection.openPopupReq("battery");
                else
                    batterySection.exitPopupReq();
            }
        }

        RowLayout {
            id: batteryPopupRow
            anchors.centerIn: parent
            spacing: Math.round(8 * Config.scale)

            // Same battery level icon as the trigger
            IconImage {
                implicitSize: Config.bar.batteryIconSize
                source: batteryIcon.source
            }

            Text {
                text: {
                    const b = batterySection.b;
                    if (!b || !b.isLaptopBattery)
                        return "";
                    return Math.round(b.percentage * 100) + "%";
                }
                color: {
                    const b = batterySection.b;
                    if (!b)
                        return Config.colors.textPrimary;
                    const pct = b.percentage * 100;
                    if (pct <= 10)
                        return Config.colors.danger;
                    if (pct <= 20)
                        return Config.colors.warning;
                    return Config.colors.textPrimary;
                }
                font.family: Config.font.family
                font.bold: true
                font.pixelSize: Config.bar.fontSizeStatus
            }
        }
    }
}
