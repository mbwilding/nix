pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "components"

// Power-profiles bar section: active profile glyph trigger + popup with profile list.
//
// Bar.qml binds activePopup and wires the popup-manager signals.
Item {
    id: powerSection

    // ── Public API ────────────────────────────────────────────────────────────

    property string activePopup: ""     // bound to root.activePopup

    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq
    signal closePopupReq

    // Expose the popup rectangle so Bar.qml can include it in the input mask
    property alias popup: powerPopup

    // ── State ─────────────────────────────────────────────────────────────────

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
        return profiles[1];  // fallback to Balanced
    }

    // ── Geometry ──────────────────────────────────────────────────────────────

    implicitWidth: powerGlyphText.implicitWidth + Math.round(10 * Config.scale)
    implicitHeight: powerGlyphText.implicitHeight + Math.round(6 * Config.scale)

    containmentMask: Item {
        x: powerSection.popupOpen ? -Math.max(0, (powerPopup.width - powerSection.width) / 2) : 0
        y: powerSection.popupOpen ? -powerPopup.height - Config.bar.popupOffset : 0
        width: powerSection.popupOpen ? Math.max(powerSection.width, powerPopup.width) : powerSection.width
        height: powerSection.popupOpen ? powerPopup.height + Config.bar.popupOffset + powerSection.height : powerSection.height
    }

    readonly property bool popupOpen: activePopup === "power"

    // ── Trigger ───────────────────────────────────────────────────────────────

    MouseArea {
        id: triggerArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: powerSection.openPopupReq("power")
        onExited: powerSection.keepPopupReq()
    }

    Text {
        id: powerGlyphText
        anchors.centerIn: parent
        text: powerSection.activeProfile.glyph
        font.family: Config.font.family
        font.pixelSize: Config.bar.powerIconSize
        color: Config.colors.textSecondary
    }

    // ── Popup ─────────────────────────────────────────────────────────────────

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
