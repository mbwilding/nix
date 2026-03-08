pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Widgets
import "components"

// Battery bar section: level icon trigger + small popup showing pct + charging status.
//
// Bar.qml binds activePopup and wires the popup-manager signals.
BarSectionItem {
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

    implicitWidth: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    implicitHeight: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    visible: b !== null && b.isLaptopBattery

    readonly property bool popupOpen: activePopup === "battery"
    popupItem: batteryPopup

    // ── Trigger ───────────────────────────────────────────────────────────────

    HoverHandler {
        id: triggerHover
        onHoveredChanged: {
            if (hovered)
                batterySection.openPopupReq("battery");
            else
                batterySection.exitPopupReq();
        }
    }

    BarButton {
        id: batteryButton
        anchors.fill: parent
        hovered: triggerHover.hovered
        popupOpen: batterySection.popupOpen
        clickable: false

        IconImage {
            id: batteryIcon
            anchors.centerIn: parent
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
    }

    // ── Popup ─────────────────────────────────────────────────────────────────

    PopupContainer {
        id: batteryPopup
        popupOpen: batterySection.popupOpen

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        height: Math.round(56 * Config.scale)
        width: batteryPopupRow.implicitWidth + Math.round(28 * Config.scale)

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
                font.pixelSize: Config.bar.fontSizePopup
            }
        }
    }
}
