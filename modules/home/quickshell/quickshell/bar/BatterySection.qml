pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Widgets

import ".."
import "../components"

BarSectionItem {
    id: batterySection

    property alias popup: batteryPopup
    property string activePopup: ""

    readonly property bool popupOpen: activePopup === "battery"
    readonly property var b: UPower.displayDevice

    signal exitPopupReq
    signal openPopupReq(string name)

    implicitHeight: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    implicitWidth: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    popupItem: batteryPopup
    visible: b !== null && b.isLaptopBattery

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
