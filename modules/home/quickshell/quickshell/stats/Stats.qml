pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

import "."
import ".."
import "../components"

// Stats drawer — slides down from the top edge of the screen.
Scope {
    id: root

    property bool visible_: false
    property bool pinned: false

    readonly property int drawerHeight: Math.round(Config.stats.height * Config.scale) + Math.round(44 * Config.scale)
    readonly property int drawerPad:    Math.round(16 * Config.scale)

    function showMouse() {
        root.visible_ = true
        if (!root.pinned) hideTimer.restart()
    }

    function toggle() {
        if (root.visible_ && root.pinned) {
            root.pinned = false
            root.visible_ = false
            hideTimer.stop()
        } else if (root.visible_) {
            root.pinned = true
            hideTimer.stop()
        } else {
            root.pinned = true
            root.visible_ = true
            hideTimer.stop()
        }
    }

    function hide() {
        root.visible_ = false
        root.pinned = false
        hideTimer.stop()
    }

    Timer {
        id: hideTimer
        interval: Config.stats.hideDelay
        onTriggered: { if (!root.pinned) root.hide() }
    }

    IpcHandler {
        target: "stats"
        function toggle() { root.toggle() }
    }

    PanelWindow {
        id: win

        screen: Quickshell.screens[Config.monitor]
        WlrLayershell.layer: WlrLayer.Overlay
        anchors.top: true
        anchors.left: true
        anchors.right: true
        exclusiveZone: 0
        color: "transparent"

        implicitWidth:  win.screen ? win.screen.width  : 1920
        implicitHeight: win.screen ? win.screen.height : 1080

        mask: Region {
            Region {
                x: Math.round(win.implicitWidth * Config.stats.triggerStart)
                y: 0
                width: Math.round(win.implicitWidth * (Config.stats.triggerEnd - Config.stats.triggerStart))
                height: Config.stats.edgeHotspotSize
                intersection: Intersection.Combine
            }
            Region {
                item: drawer
                intersection: Intersection.Combine
            }
        }

        // ── Hover trigger strip ──────────────────────────────────────────────
        Item {
            anchors.top: parent.top
            x: Math.round(win.implicitWidth * Config.stats.triggerStart)
            width: Math.round(win.implicitWidth * (Config.stats.triggerEnd - Config.stats.triggerStart))
            height: Config.stats.edgeHotspotSize
            HoverHandler {
                onHoveredChanged: { if (hovered) root.showMouse() }
            }
        }

        // ── Drawer ───────────────────────────────────────────────────────────
        Rectangle {
            id: drawer

            // Tab bar runs across the top; content fills below.
            readonly property int tabBarHeight:  Math.round(44 * Config.scale)
            readonly property int drawerWidth:   Math.round(400 * Config.scale)

            // 0=Media  1=CPU  2=RAM  3=Network
            property int activeTab: 0

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: root.visible_ ? 0 : -root.drawerHeight

            width:  drawer.drawerWidth
            height: root.drawerHeight

            radius: Math.round(Config.stats.radius * Config.scale)
            antialiasing: true
            color: Config.colors.surface
            border.width: Config.panelBorder.width
            border.color: Config.panelBorder.color
            opacity: root.visible_ ? 1 : 0
            layer.enabled: true   // clips album art + all children to radius

            Behavior on anchors.topMargin {
                NumberAnimation { duration: Config.stats.animateSpeed; easing.type: Easing.InOutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: Config.stats.animateSpeed; easing.type: Easing.InOutQuad }
            }

            HoverHandler {
                onHoveredChanged: {
                    if (hovered)           hideTimer.stop()
                    else if (!root.pinned) hideTimer.restart()
                }
            }

            // ── Layout: tab bar (top) | content (below) ─────────────────────
            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // ── Tab bar ───────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: drawer.tabBarHeight
                    color: Qt.rgba(0, 0, 0, 0.20)

                    // Tabs spread evenly across the bar
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin:  Math.round(8 * Config.scale)
                        anchors.rightMargin: Math.round(8 * Config.scale)
                        spacing: 0

                        TabIcon {
                            Layout.fillWidth: true
                            iconName: "audio-x-generic-symbolic"
                            label: "Media"
                            active: drawer.activeTab === 0
                            onHovered: drawer.activeTab = 0
                        }
                        TabIcon {
                            Layout.fillWidth: true
                            iconName: "computer-symbolic"
                            label: "CPU"
                            active: drawer.activeTab === 1
                            onHovered: drawer.activeTab = 1
                        }
                        TabIcon {
                            Layout.fillWidth: true
                            iconName: "drive-harddisk-symbolic"
                            label: "RAM"
                            active: drawer.activeTab === 2
                            onHovered: drawer.activeTab = 2
                        }
                        TabIcon {
                            Layout.fillWidth: true
                            iconName: "network-wired-symbolic"
                            label: "Network"
                            active: drawer.activeTab === 3
                            onHovered: drawer.activeTab = 3
                        }
                    }

                    // Bottom separator
                    Rectangle {
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: Config.colors.border
                        opacity: 0.5
                    }
                }

                // ── Content area ──────────────────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Tab 0 — Media (full-bleed art)
                    Music {
                        anchors.fill: parent
                        visible: drawer.activeTab === 0
                        opacity: drawer.activeTab === 0 ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    // Tab 1 — CPU boxes (full-bleed, self-padded)
                    Performance {
                        anchors.fill: parent
                        visible: drawer.activeTab === 1
                        opacity: drawer.activeTab === 1 ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    // Tab 2 — RAM
                    Ram {
                        anchors.fill: parent
                        visible: drawer.activeTab === 2
                        opacity: drawer.activeTab === 2 ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    // Tab 3 — Network
                    Network {
                        anchors.fill: parent
                        visible: drawer.activeTab === 3
                        opacity: drawer.activeTab === 3 ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }
            }
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.color: Config.panelBorder.color
                border.width: Config.panelBorder.width
            }
        }
    }

    // ── Inline tab icon component ─────────────────────────────────────────────
    component TabIcon: Item {
        id: tabIcon
        property string iconName: ""
        property string label: ""
        property bool active: false
        signal hovered

        implicitHeight: Math.round(44 * Config.scale)

        Rectangle {
            anchors.fill: parent
            anchors.margins: Math.round(4 * Config.scale)
            radius: Math.round(7 * Config.scale)
            color: tabIcon.active
                ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.22)
                : tabHover.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Math.round(2 * Config.scale)

            IconImage {
                Layout.alignment: Qt.AlignHCenter
                implicitSize: Math.round(14 * Config.scale)
                source: Quickshell.iconPath(tabIcon.iconName)
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: tabIcon.active ? Config.colors.accent : Qt.rgba(1, 1, 1, 0.55)
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: tabIcon.label
                color: tabIcon.active ? Config.colors.accent : Qt.rgba(1, 1, 1, 0.55)
                font.family: Config.font.family
                font.pixelSize: Math.round(Config.font.sizeSm * 0.78)
                font.weight: tabIcon.active ? Font.Medium : Font.Normal
                Behavior on color { ColorAnimation { duration: 100 } }
            }
        }

        HoverHandler {
            id: tabHover
            onHoveredChanged: { if (hovered) tabIcon.hovered() }
        }
    }
}
