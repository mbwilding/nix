pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.DBusMenu
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

    // Resolve a tray icon string to a usable source URL.
    // Apps like Steam send: image://icon/steam_tray_mono?path=/some/dir
    // Quickshell can't resolve custom icon paths, so we extract the name
    // and path and look for the file directly on disk.
    function resolveIcon(icon) {
        if (!icon || icon === "") return "";
        // Full filesystem path
        if (icon.startsWith("/")) return icon;
        // image://icon/NAME?path=DIR  — custom icon path
        const m = icon.match(/^image:\/\/icon\/([^?]+)\?path=(.+)$/);
        if (m) {
            const name = m[1];
            const dirs = m[2].split(":");
            for (const dir of dirs) {
                // try common extensions
                for (const ext of ["png", "svg", "xpm"]) {
                    const path = dir + "/" + name + "." + ext;
                    // Return as a file URL — QML Image will verify existence
                    return "file://" + path;
                }
            }
            // Fall back to theme lookup by name only
            return Quickshell.iconPath(name);
        }
        // Plain icon name — look up in theme
        return Quickshell.iconPath(icon);
    }

    // ── Bar window ───────────────────────────────────────────────────────────
    PanelWindow {
        id: barWindow

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusiveZone: 0
        color: "transparent"
        mask: Region {
            Region { item: bar }
            Region { item: menuPopup }
        }

        anchors.bottom: Config.bar.position === "bottom"
        anchors.top:    Config.bar.position === "top"
        anchors.left:   true
        anchors.right:  true

        implicitHeight: Config.bar.height + Math.round(8 * Config.scale)

        // ── Tray menu popup — lives in the window so it's not clipped by bar ──
        Rectangle {
            id: menuPopup

            property SystemTrayItem activeTrayItem: null
            property real anchorX: 0

            visible: activeTrayItem !== null && menuOpener.children.count > 0

            // Position above/below bar pill, aligned to the icon
            x: Math.max(4, Math.min(anchorX - width / 2,
                barWindow.width - width - 4))
            anchors.bottom: Config.bar.position === "bottom"
                ? bar.top : undefined
            anchors.top: Config.bar.position === "top"
                ? bar.bottom : undefined
            anchors.bottomMargin: Math.round(4 * Config.scale)
            anchors.topMargin:    Math.round(4 * Config.scale)

            width: menuCol.implicitWidth + Math.round(16 * Config.scale)
            height: menuCol.implicitHeight + Math.round(12 * Config.scale)
            radius: Config.bar.radius
            color: Config.colors.background
            border.color: Config.colors.border
            border.width: 1
            z: 20

            HoverHandler {
                onHoveredChanged: {
                    if (hovered) {
                        hideTimer.stop();
                    } else if (root.visible_) {
                        hideTimer.restart();
                    }
                }
            }

            QsMenuOpener {
                id: menuOpener
                menu: menuPopup.activeTrayItem ? menuPopup.activeTrayItem.menu : null
            }

            Column {
                id: menuCol
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: Math.round(6 * Config.scale)
                    bottomMargin: Math.round(6 * Config.scale)
                    leftMargin: Math.round(8 * Config.scale)
                    rightMargin: Math.round(8 * Config.scale)
                }
                spacing: 2

                Repeater {
                    model: menuOpener.children

                    delegate: Item {
                        required property QsMenuEntry modelData
                        width: menuCol.width
                        height: modelData.isSeparator
                            ? Math.round(9 * Config.scale)
                            : Math.round(28 * Config.scale)

                        // Separator
                        Rectangle {
                            visible: modelData.isSeparator
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Config.colors.border
                        }

                        // Menu item
                        Rectangle {
                            visible: !modelData.isSeparator
                            anchors.fill: parent
                            radius: Math.round(4 * Config.scale)
                            color: itemHover.containsMouse && modelData.enabled
                                ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.15)
                                : "transparent"

                            Behavior on color { ColorAnimation { duration: 80 } }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: Math.round(4 * Config.scale)
                                text: modelData.text
                                color: modelData.enabled
                                    ? Config.colors.textPrimary
                                    : Config.colors.textMuted
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizeClock
                            }

                            MouseArea {
                                id: itemHover
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: modelData.enabled
                                cursorShape: modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    modelData.sendTriggered();
                                    menuPopup.activeTrayItem = null;
                                }
                            }
                        }
                    }
                }
            }
        }

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
                        interval: 10000
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
                        id: trayDelegate
                        required property SystemTrayItem modelData
                        required property int index

                        implicitWidth: Config.bar.iconSize
                        implicitHeight: Config.bar.iconSize
                        Layout.alignment: Qt.AlignVCenter

                        readonly property bool menuOpen:
                            menuPopup.activeTrayItem === trayDelegate.modelData

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: Config.bar.iconSize
                            source: root.resolveIcon(trayDelegate.modelData.icon)
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Math.round(4 * Config.scale)
                            color: (iconHover.containsMouse || trayDelegate.menuOpen)
                                ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.15)
                                : "transparent"
                            Behavior on color { ColorAnimation { duration: 80 } }
                        }

                        MouseArea {
                            id: iconHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: {
                                hideTimer.stop();
                                if (trayDelegate.modelData.hasMenu) {
                                    // Map icon centre to barWindow coordinates
                                    const pt = trayDelegate.mapToItem(barWindow.contentItem, width / 2, 0);
                                    menuPopup.anchorX = pt.x;
                                    menuPopup.activeTrayItem = trayDelegate.modelData;
                                }
                            }
                            onExited: {
                                // Let the menu popup's own hover keep things open
                                if (root.visible_) hideTimer.restart();
                            }
                            onClicked: {
                                if (!trayDelegate.modelData.hasMenu)
                                    trayDelegate.modelData.activate();
                            }
                        }
                    }
                }
            }
        }
    }
}

