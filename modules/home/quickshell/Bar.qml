pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Scope {
    id: root

    property bool visible_: false

    function show() {
        root.visible_ = true;
        hideTimer.restart();
    }

    function hide() {
        root.visible_ = false;
        hideTimer.stop();
    }

    function toggle() {
        if (root.visible_) {
            root.hide();
        } else {
            root.show();
        }
    }

    // IPC handler — allows: qs ipc call default toggleBar
    IpcHandler {
        target: "default"

        function toggleBar() {
            root.toggle();
        }
    }

    Timer {
        id: hideTimer
        interval: Config.bar.hideDelay
        repeat: false
        onTriggered: root.visible_ = false
    }

    // ── Bar window ───────────────────────────────────────────────────────────
    PanelWindow {
        id: barWindow

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusiveZone: 0           // overlay — does not push windows
        color: "transparent"
        mask: Region {
            item: bar
        }

        anchors.bottom: Config.bar.position === "bottom"
        anchors.top:    Config.bar.position === "top"
        anchors.left:   true
        anchors.right:  true

        implicitHeight: Config.bar.height + Math.round(8 * Config.scale)

        Rectangle {
            id: bar

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: Config.bar.position === "bottom" ? parent.bottom : undefined
            anchors.top:    Config.bar.position === "top"    ? parent.top    : undefined
            anchors.bottomMargin: Math.round(4 * Config.scale)
            anchors.topMargin:    Math.round(4 * Config.scale)

            implicitWidth: barRow.implicitWidth + Config.bar.padding * 2
            implicitHeight: Config.bar.height
            radius: Config.bar.radius
            color: Config.colors.background

            border.color: Config.colors.border
            border.width: 1

            HoverHandler {
                id: barHover
                onHoveredChanged: {
                    if (hovered) {
                        hideTimer.stop();
                    } else if (root.visible_) {
                        hideTimer.restart();
                    }
                }
            }

            // Slide in/out from the edge
            transform: Translate {
                id: slideTranslate
                readonly property real hiddenY: Config.bar.position === "bottom"
                    ?  bar.height + Math.round(8 * Config.scale)
                    : -(bar.height + Math.round(8 * Config.scale))
                y: root.visible_ ? 0 : hiddenY
                Behavior on y {
                    NumberAnimation {
                        duration: Config.bar.animateSpeed
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            opacity: root.visible_ ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Config.bar.animateSpeed
                    easing.type: Easing.InOutQuad
                }
            }

            RowLayout {
                id: barRow
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    right: parent.right
                    leftMargin: Config.bar.padding
                    rightMargin: Config.bar.padding
                }
                spacing: Config.bar.spacing

                // ── Clock ────────────────────────────────────────────────────
                Text {
                    id: clock
                    color: Config.colors.textPrimary
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizeClock
                    font.weight: Font.Medium
                    text: Qt.formatDateTime(new Date(), "hh:mm")

                    Timer {
                        interval: 10000   // update every 10 s — cheap, no seconds display
                        repeat: true
                        running: true
                        triggeredOnStart: true
                        onTriggered: clock.text = Qt.formatDateTime(new Date(), "hh:mm")
                    }
                }

                // Separator
                Rectangle {
                    width: 1
                    height: Math.round(16 * Config.scale)
                    color: Config.colors.border
                    visible: trayRepeater.count > 0
                }

                // ── System tray ──────────────────────────────────────────────
                Repeater {
                    id: trayRepeater
                    model: SystemTray.items

                    delegate: Item {
                        required property SystemTrayItem modelData

                        implicitWidth: Config.bar.iconSize
                        implicitHeight: Config.bar.iconSize
                        Layout.alignment: Qt.AlignVCenter

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: Config.bar.iconSize
                            // icon may be a theme name or a full path/url
                            source: modelData.icon.startsWith("/") || modelData.icon.startsWith(":")
                                ? modelData.icon
                                : Quickshell.iconPath(modelData.icon)
                        }

                        // Left click → activate
                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: modelData.activate()
                        }

                        // Right click → context menu
                        TapHandler {
                            acceptedButtons: Qt.RightButton
                            onTapped: {
                                if (modelData.hasMenu)
                                    modelData.display(barWindow, parent.x, parent.y)
                            }
                        }

                        HoverHandler {
                            id: itemHover
                        }

                        // Tooltip
                        Rectangle {
                            visible: itemHover.hovered && modelData.tooltipTitle !== ""
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: Config.bar.position === "bottom"
                                ? parent.top : undefined
                            anchors.top: Config.bar.position === "top"
                                ? parent.bottom : undefined
                            anchors.bottomMargin: Math.round(6 * Config.scale)
                            anchors.topMargin: Math.round(6 * Config.scale)
                            width: tooltipText.implicitWidth + Math.round(12 * Config.scale)
                            height: tooltipText.implicitHeight + Math.round(6 * Config.scale)
                            radius: Math.round(4 * Config.scale)
                            color: Config.colors.background
                            border.color: Config.colors.border
                            border.width: 1
                            z: 10

                            Text {
                                id: tooltipText
                                anchors.centerIn: parent
                                text: modelData.tooltipTitle
                                color: Config.colors.textSecondary
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizeClock
                            }
                        }
                    }
                }
            }
        }
    }
}
