pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "."
import ".."
import "../components"

// Stats drawer — slides down from the top edge of the screen.
// Full-screen transparent window with exclusiveZone: 0 so nothing is displaced.
// A 1-px invisible strip at the very top acts as the hover trigger.
// IPC target "stats": toggle() pins/unpins. Mouse hover still times out normally.
Scope {
    id: root

    property bool visible_: false
    property bool pinned: false   // true when shown via IPC toggle — no auto-hide

    // Convenience sizes (all scaled)
    readonly property int drawerHeight: Math.round(Config.stats.height * Config.scale)
    readonly property int drawerPad:    Math.round(16 * Config.scale)
    readonly property int cardGap:      Math.round(10 * Config.scale)

    // Called by mouse hover — shows with timeout
    function showMouse() {
        root.visible_ = true;
        if (!root.pinned)
            hideTimer.restart();
    }

    // Called by IPC toggle
    function toggle() {
        if (root.visible_ && root.pinned) {
            // Pinned and visible → hide and unpin
            root.pinned = false;
            root.visible_ = false;
            hideTimer.stop();
        } else if (root.visible_) {
            // Visible via mouse → pin it (cancel the timeout)
            root.pinned = true;
            hideTimer.stop();
        } else {
            // Hidden → show and pin
            root.pinned = true;
            root.visible_ = true;
            hideTimer.stop();
        }
    }

    function keepAlive() {
        if (root.visible_ && !root.pinned)
            hideTimer.restart();
    }

    function hide() {
        root.visible_ = false;
        root.pinned = false;
        hideTimer.stop();
    }

    Timer {
        id: hideTimer
        interval: Config.stats.hideDelay
        onTriggered: {
            if (!root.pinned)
                root.hide();
        }
    }

    IpcHandler {
        target: "stats"
        function toggle() {
            root.toggle();
        }
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

        implicitWidth: win.screen ? win.screen.width : 1920
        implicitHeight: win.screen ? win.screen.height : 1080

        // Only intercept mouse input where the drawer or trigger strip is.
        mask: Region {
            // hotspot strip along the middle third of the top edge (always active)
            Region {
                x: Math.round(win.implicitWidth * Config.stats.triggerStart)
                y: 0
                width: Math.round(win.implicitWidth * (Config.stats.triggerEnd - Config.stats.triggerStart))
                height: Config.stats.edgeHotspotSize
                intersection: Intersection.Combine
            }
            // Drawer card itself
            Region {
                item: drawer
                intersection: Intersection.Combine
            }
        }

        // ── Hover trigger strip ──────────────────────────────────────────────
        Item {
            id: triggerStrip
            anchors.top: parent.top
            x: Math.round(win.implicitWidth * Config.stats.triggerStart)
            width: Math.round(win.implicitWidth * (Config.stats.triggerEnd - Config.stats.triggerStart))
            height: Config.stats.edgeHotspotSize

            HoverHandler {
                onHoveredChanged: {
                    if (hovered)
                        root.showMouse();
                    // no else: leaving the strip is handled by the drawer's HoverHandler
                }
            }
        }

        // ── Drawer card ──────────────────────────────────────────────────────
        Rectangle {
            id: drawer

            readonly property int drawerWidth: Math.min(
                win.implicitWidth - Math.round(40 * Config.scale),
                Math.round(Config.stats.maxWidth * Config.scale)
            )

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: root.visible_ ? 0 : -root.drawerHeight

            width: drawer.drawerWidth
            height: root.drawerHeight

            radius: Math.round(Config.stats.radius * Config.scale)
            antialiasing: true
            color: Config.colors.surface
            border.width: Config.panelBorder.width
            border.color: Config.panelBorder.color
            opacity: root.visible_ ? 1 : 0
            clip: true

            Behavior on anchors.topMargin {
                NumberAnimation {
                    duration: Config.stats.animateSpeed
                    easing.type: Easing.InOutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Config.stats.animateSpeed
                    easing.type: Easing.InOutQuad
                }
            }

            // Keep alive while the mouse is over the drawer.
            // Stop the timer while hovered; restart it on leave so hide
            // happens hideDelay ms after the mouse exits, not after entry.
            HoverHandler {
                onHoveredChanged: {
                    if (hovered)
                        hideTimer.stop();
                    else if (!root.pinned)
                        hideTimer.restart();
                }
            }

            // ── Inner layout ─────────────────────────────────────────────────
            // anchors.fill gives drawerRow a real height, so Layout.fillHeight works.
            RowLayout {
                id: drawerRow
                anchors {
                    fill: parent
                    topMargin: root.drawerPad
                    bottomMargin: root.drawerPad
                    leftMargin: root.drawerPad
                    rightMargin: root.drawerPad
                }
                spacing: root.cardGap

                // ── Left: Music ───────────────────────────────────────────────
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: Math.round(Config.stats.musicWidth * Config.scale)
                    radius: Math.round(10 * Config.scale)
                    color: Config.colors.surfaceAlt
                    border.color: Config.colors.border
                    border.width: 1
                    // layer.enabled renders the rectangle (including its radius) as a
                    // texture, so children are clipped to the rounded shape correctly.
                    layer.enabled: true

                    Music {
                        anchors.fill: parent
                    }
                }

                // ── Centre: Clock ─────────────────────────────────────────────
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: Math.round(Config.stats.clockWidth * Config.scale)
                    radius: Math.round(10 * Config.scale)
                    color: Config.colors.surfaceAlt
                    border.color: Config.colors.border
                    border.width: 1

                    Clock {
                        anchors.centerIn: parent
                    }
                }

                // ── Right: Performance + Network + Weather stacked ────────────
                ColumnLayout {
                    Layout.fillHeight: true
                    Layout.preferredWidth: Math.round(Config.stats.rightWidth * Config.scale)
                    spacing: root.cardGap

                    // Performance
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Math.round(10 * Config.scale)
                        color: Config.colors.surfaceAlt
                        border.color: Config.colors.border
                        border.width: 1
                        clip: true

                        ColumnLayout {
                            anchors {
                                fill: parent
                                topMargin: Math.round(8 * Config.scale)
                                leftMargin: Math.round(14 * Config.scale)
                                rightMargin: Math.round(14 * Config.scale)
                                bottomMargin: Math.round(8 * Config.scale)
                            }
                            spacing: Math.round(4 * Config.scale)

                            Text {
                                text: "System"
                                color: Config.colors.textMuted
                                font.family: Config.font.family
                                font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.78)
                            }

                            Performance {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                        }
                    }

                    // Network
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Math.round(10 * Config.scale)
                        color: Config.colors.surfaceAlt
                        border.color: Config.colors.border
                        border.width: 1
                        clip: true

                        ColumnLayout {
                            anchors {
                                fill: parent
                                topMargin: Math.round(8 * Config.scale)
                                leftMargin: Math.round(14 * Config.scale)
                                rightMargin: Math.round(14 * Config.scale)
                                bottomMargin: Math.round(8 * Config.scale)
                            }
                            spacing: Math.round(4 * Config.scale)

                            Text {
                                text: "Network"
                                color: Config.colors.textMuted
                                font.family: Config.font.family
                                font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.78)
                            }

                            Network {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                        }
                    }

                    // Weather
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Math.round(10 * Config.scale)
                        color: Config.colors.surfaceAlt
                        border.color: Config.colors.border
                        border.width: 1
                        clip: true

                        ColumnLayout {
                            anchors {
                                fill: parent
                                topMargin: Math.round(8 * Config.scale)
                                leftMargin: Math.round(14 * Config.scale)
                                rightMargin: Math.round(14 * Config.scale)
                                bottomMargin: Math.round(8 * Config.scale)
                            }
                            spacing: Math.round(4 * Config.scale)

                            Text {
                                text: "Weather"
                                color: Config.colors.textMuted
                                font.family: Config.font.family
                                font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.78)
                            }

                            Weather {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                        }
                    }
                }
            }
        }
    }
}
