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

    readonly property int drawerHeight: drawer.drawerWidth + Math.round(44 * Config.scale)
    readonly property int drawerPad: Math.round(16 * Config.scale)

    function showMouse() {
        root.visible_ = true;
        if (!root.pinned)
            hideTimer.restart();
    }

    function toggle() {
        if (root.visible_ && root.pinned) {
            root.pinned = false;
            root.visible_ = false;
            hideTimer.stop();
        } else if (root.visible_) {
            root.pinned = true;
            hideTimer.stop();
        } else {
            root.pinned = true;
            root.visible_ = true;
            hideTimer.stop();
        }
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
                onHoveredChanged: {
                    if (hovered)
                        root.showMouse();
                }
            }
        }

        // ── Drawer ───────────────────────────────────────────────────────────
        Rectangle {
            id: drawer

            // Tab bar runs across the top; content fills below.
            readonly property int tabBarHeight: Math.round(36 * Config.scale)
            readonly property int drawerWidth: Math.round(400 * Config.scale)

            // 0=Media  1=CPU  2=RAM  3=GPU  4=Network
            property int activeTab: 0

            // Fullscreen expansion — double-click any tab icon to toggle
            property bool expanded: false
            readonly property int expandedW: win.implicitWidth
            readonly property int expandedH: win.implicitHeight

            readonly property int targetW: expanded ? expandedW : drawerWidth
            readonly property int targetH: expanded ? expandedH : root.drawerHeight
            readonly property int targetRadius: expanded ? 0 : Math.round(Config.stats.radius * Config.scale)

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: root.visible_ ? 0 : -root.drawerHeight

            width: targetW
            height: targetH

            radius: targetRadius
            antialiasing: true
            color: Config.colors.surface
            opacity: root.visible_ ? 1 : 0
            clip: true

            Behavior on width {
                NumberAnimation { duration: 280; easing.type: Easing.InOutCubic }
            }
            Behavior on height {
                NumberAnimation { duration: 280; easing.type: Easing.InOutCubic }
            }
            Behavior on radius {
                NumberAnimation { duration: 280; easing.type: Easing.InOutCubic }
            }
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

            // Escape key collapses fullscreen
            Keys.onEscapePressed: drawer.expanded = false
            focus: drawer.expanded

            HoverHandler {
                onHoveredChanged: {
                    if (hovered)
                        hideTimer.stop();
                    else if (!root.pinned)
                        hideTimer.restart();
                }
            }

            // ── Layout: tab bar (top) | content (below) ─────────────────────
            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // ── Tab bar ───────────────────────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: drawer.tabBarHeight

                    // Subtle dark background
                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(0, 0, 0, 0.28)
                    }

                    // Bottom separator line
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.08)
                    }

                    // Sliding accent underline indicator
                    Rectangle {
                        id: tabIndicator
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 0
                        height: Math.round(2 * Config.scale)
                        width: tabRow.itemWidth
                        x: drawer.activeTab * tabRow.itemWidth
                        radius: height / 2
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Config.colors.accent }
                            GradientStop { position: 1.0; color: Config.colors.accentAlt }
                        }
                        Behavior on x {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }

                    RowLayout {
                        id: tabRow
                        anchors.fill: parent
                        anchors.leftMargin: 0
                        anchors.rightMargin: 0
                        spacing: 0

                        // Width per tab slot (excludes pin button + separator)
                        readonly property real itemWidth: (width - pinTabBtn.implicitWidth - 1 - Math.round(6 * Config.scale)) / 5

                        TabIcon {
                            Layout.fillWidth: true
                            iconName: "audio-headphones-symbolic"
                            active: drawer.activeTab === 0
                            onClicked: drawer.activeTab = 0
                            onDoubleClicked: drawer.expanded = !drawer.expanded
                        }
                        TabIcon {
                            Layout.fillWidth: true
                            iconName: "show-gpu-effects-symbolic"
                            active: drawer.activeTab === 1
                            onClicked: drawer.activeTab = 1
                            onDoubleClicked: drawer.expanded = !drawer.expanded
                        }
                        TabIcon {
                            Layout.fillWidth: true
                            iconName: "media-flash-sd-mmc-symbolic"
                            active: drawer.activeTab === 2
                            onClicked: drawer.activeTab = 2
                            onDoubleClicked: drawer.expanded = !drawer.expanded
                        }
                        TabIcon {
                            Layout.fillWidth: true
                            iconName: "audio-card-symbolic"
                            active: drawer.activeTab === 3
                            onClicked: drawer.activeTab = 3
                            onDoubleClicked: drawer.expanded = !drawer.expanded
                        }
                        TabIcon {
                            Layout.fillWidth: true
                            iconName: "network-wired-symbolic"
                            active: drawer.activeTab === 4
                            onClicked: drawer.activeTab = 4
                            onDoubleClicked: drawer.expanded = !drawer.expanded
                        }

                        // Hairline separator before pin
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            width: 1
                            height: Math.round(20 * Config.scale)
                            color: Qt.rgba(1, 1, 1, 0.10)
                        }

                        // Pin button — right edge
                        PinTabButton {
                            id: pinTabBtn
                            Layout.alignment: Qt.AlignVCenter
                            Layout.rightMargin: Math.round(6 * Config.scale)
                            pinned: root.pinned
                            onClicked: root.toggle()
                        }
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
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                    }

                    // Tab 1 — CPU boxes (full-bleed, self-padded)
                    Performance {
                        anchors.fill: parent
                        visible: drawer.activeTab === 1
                        opacity: drawer.activeTab === 1 ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                    }

                    // Tab 2 — RAM
                    Ram {
                        anchors.fill: parent
                        visible: drawer.activeTab === 2
                        opacity: drawer.activeTab === 2 ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                    }

                    // Tab 3 — GPU
                    Gpu {
                        anchors.fill: parent
                        visible: drawer.activeTab === 3
                        opacity: drawer.activeTab === 3 ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                    }

                    // Tab 4 — Network
                    Network {
                        anchors.fill: parent
                        visible: drawer.activeTab === 4
                        opacity: drawer.activeTab === 4 ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                    }
                }
            }
        }

        // ── Border overlay — sibling of drawer, so it renders above layer.enabled ──
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: root.visible_ ? 0 : -root.drawerHeight
            width: drawer.targetW
            height: drawer.targetH
            radius: drawer.targetRadius
            color: "transparent"
            border.color: Config.panelBorder.color
            border.width: Config.panelBorder.width
            opacity: root.visible_ ? 1 : 0
            Behavior on width {
                NumberAnimation { duration: 280; easing.type: Easing.InOutCubic }
            }
            Behavior on height {
                NumberAnimation { duration: 280; easing.type: Easing.InOutCubic }
            }
            Behavior on radius {
                NumberAnimation { duration: 280; easing.type: Easing.InOutCubic }
            }
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
        }
    }

    // ── Inline tab icon component ─────────────────────────────────────────────
    component TabIcon: Item {
        id: tabIcon
        property string iconName: ""
        property bool active: false
        property int tabIndex: -1
        signal clicked
        signal doubleClicked

        implicitHeight: Math.round(36 * Config.scale)

        Rectangle {
            anchors.fill: parent
            anchors.margins: Math.round(4 * Config.scale)
            radius: Math.round(6 * Config.scale)
            color: tabMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
            Behavior on color {
                ColorAnimation { duration: 100 }
            }
        }

        IconImage {
            anchors.centerIn: parent
            implicitSize: Math.round(20 * Config.scale)
            source: Quickshell.iconPath(tabIcon.iconName)
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: tabIcon.active ? Config.colors.accent : Qt.rgba(1, 1, 1, 0.50)
                Behavior on colorizationColor {
                    ColorAnimation { duration: 120 }
                }
            }
        }

        // Short delay so a double-click can cancel the single-click action
        Timer {
            id: clickTimer
            interval: 180
            onTriggered: tabIcon.clicked()
        }

        MouseArea {
            id: tabMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: clickTimer.restart()
            onDoubleClicked: {
                clickTimer.stop()
                tabIcon.doubleClicked()
            }
        }
    }

    // ── Inline pin button component ───────────────────────────────────────────
    component PinTabButton: Item {
        id: pinTab
        property bool pinned: false
        signal clicked

        implicitWidth: Math.round(32 * Config.scale)
        implicitHeight: Math.round(36 * Config.scale)

        // Circular hover/pinned background — subtle, not boxy
        Rectangle {
            anchors.centerIn: parent
            width: Math.round(26 * Config.scale)
            height: width
            radius: width / 2
            color: pinTab.pinned
                   ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18)
                   : pinHover.containsMouse ? Qt.rgba(1, 1, 1, 0.09) : "transparent"
            Behavior on color {
                ColorAnimation { duration: 120 }
            }
        }

        IconImage {
            anchors.centerIn: parent
            implicitSize: Math.round(18 * Config.scale)
            source: Quickshell.iconPath(pinTab.pinned ? "window-pin-symbolic" : "window-unpin-symbolic")
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: pinTab.pinned ? Config.colors.accent : Qt.rgba(1, 1, 1, 0.45)
                Behavior on colorizationColor {
                    ColorAnimation { duration: 150 }
                }
            }
        }

        HoverHandler {
            id: pinHover
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: pinTab.clicked()
        }
    }
}
