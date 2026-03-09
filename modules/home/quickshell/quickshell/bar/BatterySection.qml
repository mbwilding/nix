pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Widgets

import ".."
import "../components"

BarSectionItem {
    id: batterySection

    readonly property var b: UPower.displayDevice

    implicitHeight: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    implicitWidth: Config.bar.batteryIconSize + Math.round(34 * Config.scale)
    visible: b !== null && b.isLaptopBattery

    BarButton {
        anchors.fill: parent
        hovered: false
        popupOpen: false
        clickable: false

        Row {
            anchors.centerIn: parent
            spacing: Math.round(3 * Config.scale)

            IconImage {
                id: batteryIcon
                anchors.verticalCenter: parent.verticalCenter
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

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    const b = batterySection.b;
                    if (!b || !b.isLaptopBattery) return "";
                    return Math.round(b.percentage * 100) + "%";
                }
                color: {
                    const b = batterySection.b;
                    if (!b) return Config.colors.textPrimary;
                    const pct = b.percentage * 100;
                    if (pct <= 10) return Config.colors.danger;
                    if (pct <= 20) return Config.colors.warning;
                    return Config.colors.textPrimary;
                }
                font.family: Config.font.family
                font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.72)
            }
        }
    }
}
