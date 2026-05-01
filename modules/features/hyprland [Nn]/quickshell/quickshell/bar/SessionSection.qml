pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

import ".."
import "../components"

// Session button — opens a popup with shutdown, reboot, and logout actions.
// Place in Config.bar.layout via BarItems.session.
BarSectionItem {
    id: root

    property alias popup: sessionPopup
    property string activePopup: ""

    readonly property bool popupOpen: activePopup === "session"

    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq
    signal closePopupReq

    implicitWidth: btn.implicitWidth
    implicitHeight: btn.implicitHeight
    popupItem: sessionPopup

    BarButton {
        id: btn
        anchors.fill: parent
        hovered: triggerArea.containsMouse
        popupOpen: root.popupOpen
        clickable: true

        IconImage {
            anchors.centerIn: parent
            implicitSize: Config.bar.batteryIconSize
            source: Quickshell.iconPath("system-shutdown-symbolic")
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: root.popupOpen ? Config.colors.accent : Config.colors.textSecondary
                Behavior on colorizationColor {
                    ColorAnimation { duration: 120 }
                }
            }
        }
    }

    MouseArea {
        id: triggerArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.openPopupReq("session")
        onExited: root.keepPopupReq()
        onClicked: {
            if (root.popupOpen)
                root.closePopupReq()
            else
                root.openPopupReq("session")
        }
    }

    PopupContainer {
        id: sessionPopup
        popupOpen: root.popupOpen

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        width: Math.round(160 * Config.scale)
        implicitHeight: sessionCol.implicitHeight + Math.round(16 * Config.scale)

        z: 20

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    root.openPopupReq("session")
                else
                    root.exitPopupReq()
            }
        }

        Column {
            id: sessionCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Math.round(8 * Config.scale)
            anchors.bottomMargin: Math.round(8 * Config.scale)
            spacing: Math.round(2 * Config.scale)

            // Shutdown
            SessionActionRow {
                width: parent.width
                iconName: "system-shutdown-symbolic"
                label: "Shutdown"
                onActionTriggered: {
                    root.closePopupReq()
                    shutdownProc.running = true
                }
            }

            // Reboot
            SessionActionRow {
                width: parent.width
                iconName: "system-reboot-symbolic"
                label: "Reboot"
                onActionTriggered: {
                    root.closePopupReq()
                    rebootProc.running = true
                }
            }

            // Logout
            SessionActionRow {
                width: parent.width
                iconName: "system-log-out-symbolic"
                label: "Logout"
                onActionTriggered: {
                    root.closePopupReq()
                    logoutProc.running = true
                }
            }

            Item { implicitHeight: Math.round(6 * Config.scale) }
        }
    }

    // ── Processes ──────────────────────────────────────────────────────────────

    Process {
        id: shutdownProc
        command: ["systemctl", "poweroff"]
        running: false
    }

    Process {
        id: rebootProc
        command: ["systemctl", "reboot"]
        running: false
    }

    Process {
        id: logoutProc
        command: ["hyprctl", "dispatch", "exit"]
        running: false
    }

    // ── Inline action row component ────────────────────────────────────────────

    component SessionActionRow: Item {
        id: actionRow

        property string iconName: ""
        property string label: ""
        signal actionTriggered

        implicitHeight: Math.round(36 * Config.scale)

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: Math.round(6 * Config.scale)
            anchors.rightMargin: Math.round(6 * Config.scale)
            radius: Math.round(8 * Config.scale)
            color: rowMouse.containsMouse ? Config.colors.rowHover : "transparent"
            Behavior on color {
                ColorAnimation { duration: 80 }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Math.round(10 * Config.scale)
                anchors.rightMargin: Math.round(10 * Config.scale)
                spacing: Math.round(8 * Config.scale)

                IconImage {
                    implicitSize: Math.round(16 * Config.scale)
                    source: Quickshell.iconPath(actionRow.iconName)
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: rowMouse.containsMouse ? Config.colors.accent : Config.colors.textSecondary
                        Behavior on colorizationColor {
                            ColorAnimation { duration: 80 }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: actionRow.label
                    color: rowMouse.containsMouse ? Config.colors.textPrimary : Config.colors.textSecondary
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizePopup
                    Behavior on color {
                        ColorAnimation { duration: 80 }
                    }
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: actionRow.actionTriggered()
            }
        }
    }
}
