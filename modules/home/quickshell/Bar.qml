pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower

Scope {
    id: root

    property bool visible_: false

    function show() {
        root.visible_ = true;
        hideTimer.restart();
    }

    function keepAlive() {
        hideTimer.restart();
    }

    IpcHandler {
        target: "bar"
        function toggle() {
            root.show();
        }
    }

    Timer {
        id: hideTimer
        interval: Config.bar.hideDelay
        onTriggered: root.visible_ = false
    }

    property UPowerDevice battery: UPower.displayDevice

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    PanelWindow {
        id: win

        WlrLayershell.layer: WlrLayer.Top
        anchors.bottom: true
        exclusiveZone: 0
        color: "transparent"

        implicitWidth: win.screen ? win.screen.width : 1920
        implicitHeight: pill.implicitHeight + Math.round(16 * Config.scale)

        mask: Region {
            item: pill
        }

        Rectangle {
            id: pill

            implicitWidth: content.implicitWidth + Config.bar.padding * 2
            implicitHeight: content.implicitHeight + Math.round(12 * Config.scale) * 2

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.visible_ ? Math.round(8 * Config.scale) : -(pill.implicitHeight + Math.round(8 * Config.scale))

            Behavior on anchors.bottomMargin {
                NumberAnimation {
                    duration: Config.bar.animateSpeed
                    easing.type: Easing.InOutQuad
                }
            }

            radius: Config.bar.radius
            color: Config.colors.background
            border.color: Config.colors.border
            border.width: 1

            opacity: root.visible_ ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Config.bar.animateSpeed
                    easing.type: Easing.InOutQuad
                }
            }

            HoverHandler {
                onHoveredChanged: if (hovered) root.keepAlive()
            }

            ColumnLayout {
                id: content
                anchors.centerIn: parent
                width: implicitWidth
                spacing: Math.round(6 * Config.scale)

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Config.bar.spacing
                    visible: trayRepeater.count > 0

                    Repeater {
                        id: trayRepeater
                        model: SystemTray.items
                        delegate: BarTrayItem {
                            required property SystemTrayItem modelData
                            trayItem: modelData
                            onHovered: root.keepAlive()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Config.colors.border
                    visible: trayRepeater.count > 0
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Config.bar.sectionSpacing

                    RowLayout {
                        id: batterySection
                        spacing: Math.round(5 * Config.scale)
                        visible: root.battery !== null && root.battery.isLaptopBattery

                        IconImage {
                            implicitSize: Config.bar.batteryIconSize
                            source: {
                                const b = root.battery;
                                if (!b || !b.isLaptopBattery)
                                    return "";
                                const n = b.iconName;
                                return Quickshell.iconPath(n !== "" ? n : "battery-missing-symbolic");
                            }
                        }

                        Text {
                            text: root.battery && root.battery.isLaptopBattery ? Math.round(root.battery.percentage * 100) + "%" : ""
                            color: {
                                if (!root.battery || !root.battery.isLaptopBattery)
                                    return Config.colors.textPrimary;
                                const pct = root.battery.percentage * 100;
                                if (pct <= 10)
                                    return "#ff6060";
                                if (pct <= 20)
                                    return "#ffaa60";
                                return Config.colors.textPrimary;
                            }
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.fontSizeStatus
                        }
                    }

                    Rectangle {
                        implicitWidth: 1
                        implicitHeight: Config.bar.batteryIconSize
                        color: Config.colors.border
                        visible: batterySection.visible
                    }

                    RowLayout {
                        id: powerRow
                        spacing: Math.round(2 * Config.scale)

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

                        Repeater {
                            model: powerRow.profiles
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool isActive: PowerProfiles.profile === modelData.profile
                                readonly property bool isPerf: modelData.profile === PowerProfile.Performance

                                implicitWidth: Config.bar.powerIconSize + Math.round(10 * Config.scale)
                                implicitHeight: Config.bar.powerIconSize + Math.round(6 * Config.scale)
                                radius: Math.round(5 * Config.scale)
                                visible: !isPerf || PowerProfiles.hasPerformanceProfile

                                color: isActive ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.25) : (btnMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent")
                                border.color: isActive ? Config.colors.accent : Config.colors.border
                                border.width: 1

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 100
                                    }
                                }
                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 100
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.modelData.glyph
                                    font.family: Config.font.family
                                    font.pixelSize: Config.bar.powerIconSize
                                    color: parent.isActive ? Config.colors.accent : Config.colors.textSecondary
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 100
                                        }
                                    }
                                }

                                MouseArea {
                                    id: btnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.keepAlive()
                                    onClicked: {
                                        PowerProfiles.profile = parent.modelData.profile;
                                        root.keepAlive();
                                    }
                                }

                                Rectangle {
                                    visible: btnMouse.containsMouse
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.top
                                    anchors.bottomMargin: Config.bar.popupOffset
                                    implicitWidth: tipText.implicitWidth + Math.round(10 * Config.scale)
                                    implicitHeight: tipText.implicitHeight + Math.round(6 * Config.scale)
                                    radius: Math.round(4 * Config.scale)
                                    color: Config.colors.background
                                    border.color: Config.colors.border
                                    border.width: 1
                                    z: 10
                                    Text {
                                        id: tipText
                                        anchors.centerIn: parent
                                        text: parent.parent.modelData.label
                                        color: Config.colors.textSecondary
                                        font.family: Config.font.family
                                        font.pixelSize: Config.bar.fontSizeStatus
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: 1
                        implicitHeight: Config.bar.batteryIconSize
                        color: Config.colors.border
                    }

                    Text {
                        text: Qt.formatTime(clock.date, Config.bar.clockFormat) || "--:--"
                        color: Config.colors.textPrimary
                        font.family: Config.font.family
                        font.pixelSize: Config.bar.fontSizeClock
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }
}
