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

    property int statusButtonExtraWidth: Math.round(34 * Config.scale)
    property int statusLabelWidth: 0

    implicitWidth: hasBattery
        ? Config.bar.batteryIconSize + statusButtonExtraWidth
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
                width: powerSection.statusLabelWidth > 0 ? powerSection.statusLabelWidth : implicitWidth
                horizontalAlignment: Text.AlignRight
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

        width: Math.round(250 * Config.scale)
        height: Math.round(6 * Config.scale) + popupHeader.implicitHeight + Math.round(58 * Config.scale)

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
            width: parent.width
            y: Math.round(6 * Config.scale)

            PopupSectionHeader {
                id: popupHeader
                text: "Power Mode"
                width: parent.width
                leftPadding: Math.round(12 * Config.scale)
                rightPadding: Math.round(12 * Config.scale)
            }

            // Discrete power profile slider — mirrors SliderRow layout exactly
            Item {
                id: profileSlider
                width: parent.width
                height: Math.round(58 * Config.scale)

                readonly property var visibleProfiles: {
                    const p = powerSection.profiles;
                    return PowerProfiles.hasPerformanceProfile ? p : p.filter(x => x.profile !== PowerProfile.Performance);
                }
                readonly property int count: visibleProfiles.length
                readonly property int activeIndex: {
                    for (let i = 0; i < visibleProfiles.length; i++)
                        if (PowerProfiles.profile === visibleProfiles[i].profile)
                            return i;
                    return 0;
                }
                readonly property real fraction: count > 1 ? activeIndex / (count - 1) : 0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin:  Math.round(12 * Config.scale)
                    anchors.rightMargin: Math.round(12 * Config.scale)
                    spacing: Math.round(10 * Config.scale)

                    // Left icon — first profile (Power Saver)
                    Item {
                        implicitWidth:  Config.bar.batteryIconSize
                        implicitHeight: Config.bar.batteryIconSize

                        Text {
                            anchors.centerIn: parent
                            text: profileSlider.visibleProfiles.length > 0 ? profileSlider.visibleProfiles[0].glyph : ""
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.powerIconSize
                            color: profileSlider.activeIndex === 0 ? Config.colors.accent : Config.colors.textSecondary
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                    }

                    // Track
                    Item {
                        id: sliderTrack
                        Layout.fillWidth: true
                        height: Math.round(20 * Config.scale)

                        readonly property real frac: profileSlider.fraction

                        // Rail
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: Math.round(6 * Config.scale)
                            radius: height / 2
                            color: Config.colors.sliderRail
                        }

                        // Glow fill
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width * sliderTrack.frac
                            height: Math.round(10 * Config.scale)
                            radius: height / 2
                            opacity: 0.35
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Config.colors.accent }
                                GradientStop { position: 1.0; color: Config.colors.accentAlt }
                            }
                            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutQuart } }
                        }

                        // Fill
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width * sliderTrack.frac
                            height: Math.round(6 * Config.scale)
                            radius: height / 2
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Config.colors.accent }
                                GradientStop { position: 1.0; color: Config.colors.accentAlt }
                            }
                            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutQuart } }
                        }

                        // Snap dots
                        Repeater {
                            model: profileSlider.count
                            delegate: Rectangle {
                                required property int index
                                readonly property real pos: profileSlider.count > 1 ? index / (profileSlider.count - 1) : 0.5
                                anchors.verticalCenter: sliderTrack.verticalCenter
                                x: sliderTrack.width * pos - width / 2
                                width: Math.round(6 * Config.scale)
                                height: width
                                radius: width / 2
                                color: index <= profileSlider.activeIndex ? "transparent" : Config.colors.sliderRail
                            }
                        }

                        // Thumb glow
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: parent.width * sliderTrack.frac - width / 2
                            width: Math.round(18 * Config.scale)
                            height: width
                            radius: width / 2
                            color: Config.colors.glowAccent
                            opacity: 0.55
                            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuart } }
                        }

                        // Thumb
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: parent.width * sliderTrack.frac - width / 2
                            width: Math.round(14 * Config.scale)
                            height: width
                            radius: width / 2
                            color: Config.colors.sliderThumb
                            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuart } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.SizeHorCursor
                            onEntered: powerSection.openPopupReq("power")

                            function pickProfile(mx) {
                                const n = profileSlider.count;
                                if (n < 2) return;
                                const idx = Math.max(0, Math.min(n - 1, Math.round(mx / sliderTrack.width * (n - 1))));
                                PowerProfiles.profile = profileSlider.visibleProfiles[idx].profile;
                            }

                            onPressed:         mouse => pickProfile(mouse.x)
                            onPositionChanged: mouse => { if (pressed) pickProfile(mouse.x); }
                            onWheel: wheel => {
                                const dir = wheel.angleDelta.y > 0 ? -1 : 1;
                                const next = Math.max(0, Math.min(profileSlider.count - 1, profileSlider.activeIndex + dir));
                                PowerProfiles.profile = profileSlider.visibleProfiles[next].profile;
                                powerSection.openPopupReq("power");
                            }
                        }
                    }

                    // Right icon — last profile (Performance or Balanced)
                    Item {
                        implicitWidth:  Config.bar.batteryIconSize
                        implicitHeight: Config.bar.batteryIconSize

                        Text {
                            anchors.centerIn: parent
                            text: profileSlider.visibleProfiles.length > 0 ? profileSlider.visibleProfiles[profileSlider.count - 1].glyph : ""
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.powerIconSize
                            color: profileSlider.activeIndex === profileSlider.count - 1 ? Config.colors.accent : Config.colors.textSecondary
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                    }
                }
            }
        }
    }
}
