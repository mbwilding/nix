pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Widgets

import ".."
import "../components"

BarSectionItem {
    id: powerSection

    property alias popup: powerPopup
    property string activePopup: ""

    readonly property bool popupOpen: activePopup === "power"
    readonly property var b: UPower.displayDevice
    readonly property bool hasBattery: b !== null && b.isLaptopBattery
    readonly property var profiles: [
        {
            profile: PowerProfile.PowerSaver,
            glyph: "󰌪",
            label: "Power Saver"
        },
        {
            profile: PowerProfile.Balanced,
            glyph: "󰗑",
            label: "Balanced"
        },
        {
            profile: PowerProfile.Performance,
            glyph: "󰓅",
            label: "Performance"
        }
    ]
    readonly property var activeProfile: {
        for (let i = 0; i < profiles.length; i++)
            if (PowerProfiles.profile === profiles[i].profile)
                return profiles[i];
        return profiles[1];
    }

    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq
    signal closePopupReq

    implicitWidth: hasBattery
        ? Config.bar.batteryIconSize + Math.round(34 * Config.scale)
        : powerGlyphText.implicitWidth + Math.round(10 * Config.scale)
    implicitHeight: hasBattery
        ? Config.bar.batteryIconSize + Math.round(10 * Config.scale)
        : powerGlyphText.implicitHeight + Math.round(6 * Config.scale)
    popupItem: powerPopup

    MouseArea {
        id: triggerArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: powerSection.openPopupReq("power")
        onExited: powerSection.keepPopupReq()
    }

    // Battery mode: icon + percentage
    BarButton {
        anchors.fill: parent
        visible: powerSection.hasBattery
        hovered: triggerArea.containsMouse
        popupOpen: powerSection.popupOpen
        clickable: false

        Row {
            anchors.centerIn: parent
            spacing: Math.round(3 * Config.scale)

            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: Config.bar.batteryIconSize
                source: {
                    const b = powerSection.b;
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
                    const b = powerSection.b;
                    if (!b || !b.isLaptopBattery) return "";
                    return Math.round(b.percentage * 100) + "%";
                }
                color: {
                    const b = powerSection.b;
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

    // No-battery mode: active power profile glyph
    Text {
        id: powerGlyphText
        anchors.centerIn: parent
        visible: !powerSection.hasBattery
        text: powerSection.activeProfile.glyph
        font.family: Config.font.family
        font.pixelSize: Config.bar.powerIconSize
        color: Config.colors.textSecondary
    }

    PopupContainer {
        id: powerPopup
        popupOpen: powerSection.popupOpen

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        width: powerPopupCol.implicitWidth + Math.round(20 * Config.scale)
        height: powerPopupCol.implicitHeight + Math.round(20 * Config.scale)

        z: 20

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    powerSection.openPopupReq("power");
                else
                    powerSection.exitPopupReq();
            }
        }

        Column {
            id: powerPopupCol
            anchors.centerIn: parent
            spacing: Math.round(2 * Config.scale)

            PopupSectionHeader {
                text: "Power Mode"
            }

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

                    color: isActive ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.22) : (profileMouse.containsMouse ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.10) : "transparent")
                    border.color: isActive ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.45) : "transparent"
                    border.width: 1
                    Behavior on color {
                        ColorAnimation {
                            duration: 80
                        }
                    }

                    RowLayout {
                        id: profileRow
                        anchors.centerIn: parent
                        spacing: Math.round(8 * Config.scale)

                        Text {
                            text: profileDelegate.modelData.glyph
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.powerIconSize
                            color: profileDelegate.isActive ? Config.colors.accent : Config.colors.textSecondary
                            Behavior on color {
                                ColorAnimation {
                                    duration: 100
                                }
                            }
                        }

                        Text {
                            text: profileDelegate.modelData.label
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.fontSizePopup
                            color: profileDelegate.isActive ? Config.colors.accent : Config.colors.textPrimary
                            Behavior on color {
                                ColorAnimation {
                                    duration: 100
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: profileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: powerSection.openPopupReq("power")
                        onClicked: {
                            PowerProfiles.profile = profileDelegate.modelData.profile;
                            powerSection.closePopupReq();
                        }
                    }
                }
            }
        }
    }
}
