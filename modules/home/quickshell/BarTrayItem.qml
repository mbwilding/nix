pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Item {
    id: root

    required property SystemTrayItem trayItem

    // Popup manager integration — set by Bar.qml delegate
    property string popupName: ""
    property string activePopup: ""
    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq

    signal hovered

    readonly property bool popupOpen: activePopup === popupName && popupName !== ""

    // Expose the popup item so Bar.qml can include it in the input mask
    readonly property Item menuPopup: menuPopupRect

    implicitWidth: iconContainer.implicitWidth
    implicitHeight: iconContainer.implicitHeight

    // ── Popup width calculation ───────────────────────────────────────────────
    // Measures the widest menu entry text to size the popup correctly.

    // Used for per-entry text width measurement
    TextMetrics {
        id: entryTextMetrics
        font.family: Config.font.family
        font.pixelSize: Config.bar.fontSizeStatus
    }

    // Computed imperatively to avoid a binding loop from mutating entryTextMetrics.text
    property int menuPopupWidth: Math.round(200 * Config.scale)

    function recomputePopupWidth() {
        const entries = menuOpener.children ? menuOpener.children.values : [];
        const iconW = Config.bar.fontSizeStatus + Math.round(8 * Config.scale);
        const rowMargins = Math.round(8 * Config.scale) * 2;
        const colPadding = Math.round(16 * Config.scale);
        let maxTextW = Math.round(100 * Config.scale);
        for (let i = 0; i < entries.length; i++) {
            const entry = entries[i];
            if (!entry || entry.isSeparator)
                continue;
            entryTextMetrics.text = entry.text || "";
            const w = entryTextMetrics.boundingRect.width;
            if (w > maxTextW)
                maxTextW = w;
        }
        menuPopupWidth = iconW + maxTextW + rowMargins + colPadding;
    }

    readonly property int maxPopupHeight: Math.round(320 * Config.scale)

    // ─────────────────────────────────────────────────────────────────────────

    Rectangle {
        id: iconContainer

        implicitWidth: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
        implicitHeight: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
        radius: Math.round(8 * Config.scale)
        color: (hoverArea.containsMouse || root.popupOpen) ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18) : "transparent"
        border.color: (hoverArea.containsMouse || root.popupOpen) ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.35) : "transparent"
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
        Behavior on border.color {
            ColorAnimation { duration: 120 }
        }

        IconImage {
            id: icon
            anchors.centerIn: parent
            implicitSize: Config.bar.batteryIconSize
            source: root.trayItem.icon
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onEntered: {
                root.hovered();
                if (root.trayItem.hasMenu && root.popupName !== "")
                    root.openPopupReq(root.popupName);
            }
            onExited: root.keepPopupReq()

            onClicked: mouse => {
                root.hovered();
                if (root.trayItem.hasMenu) {
                    if (root.popupName !== "")
                        root.openPopupReq(root.popupName);
                } else {
                    root.trayItem.activate();
                }
            }
        }
    }

    // ── Menu popup ────────────────────────────────────────────────────────────

    QsMenuOpener {
        id: menuOpener
        menu: root.trayItem.menu
        onChildrenChanged: root.recomputePopupWidth()
    }

    Rectangle {
        id: menuPopupRect

        visible: opacity > 0
        opacity: root.popupOpen ? 1 : 0
        scale: root.popupOpen ? 1 : 0.90
        transformOrigin: Item.Bottom

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.InOutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 0.5 }
        }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        width: root.menuPopupWidth
        height: Math.min(menuCol.implicitHeight + Math.round(16 * Config.scale), root.maxPopupHeight)

        radius: Math.round(Config.bar.popupRadius * Config.scale)
        // Glassmorphic fill
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.rgba(0.16, 0.14, 0.28, 0.97) }
            GradientStop { position: 1.0; color: Qt.rgba(0.09, 0.08, 0.18, 0.93) }
        }
        border.color: Config.colors.border
        border.width: 1
        clip: true
        z: 20

        // Top shine
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            radius: parent.radius
            color: "#28ffffff"
        }

        // Drop shadow
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: -Math.round(6 * Config.scale)
            width: parent.width * 0.75
            height: Math.round(18 * Config.scale)
            radius: height / 2
            color: Config.colors.shadowDark
            opacity: 0.8
            z: -1
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    root.openPopupReq(root.popupName);
                else
                    root.exitPopupReq();
            }
        }

        Flickable {
            id: menuFlickable
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.right: menuScrollbar.left
            anchors.topMargin: Math.round(8 * Config.scale)
            anchors.leftMargin: Math.round(8 * Config.scale)
            anchors.bottomMargin: Math.round(8 * Config.scale)
            anchors.rightMargin: Math.round(4 * Config.scale)
            contentWidth: width
            contentHeight: menuCol.implicitHeight
            clip: true

            Column {
                id: menuCol
                width: menuFlickable.width
                spacing: Math.round(2 * Config.scale)

                Repeater {
                    model: menuOpener.children

                    delegate: Item {
                        id: entryDelegate
                        required property QsMenuEntry modelData
                        width: menuCol.width

                        implicitHeight: modelData.isSeparator ? Math.round(9 * Config.scale) : entryRow.implicitHeight + Math.round(10 * Config.scale)

                        // Separator
                        Rectangle {
                            visible: entryDelegate.modelData.isSeparator
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Config.colors.border
                        }

                        // Menu row (non-separator)
                        Rectangle {
                            visible: !entryDelegate.modelData.isSeparator
                            anchors.fill: parent
                            radius: Math.round(6 * Config.scale)
                            color: entryMouse.containsMouse && entryDelegate.modelData.enabled ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.12) : "transparent"
                            Behavior on color {
                                ColorAnimation {
                                    duration: 80
                                }
                            }

                            RowLayout {
                                id: entryRow
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: Math.round(8 * Config.scale)
                                anchors.rightMargin: Math.round(8 * Config.scale)
                                spacing: Math.round(8 * Config.scale)

                                IconImage {
                                    id: entryIcon
                                    readonly property string iconStr: entryDelegate.modelData.icon
                                    readonly property string resolved: {
                                        if (iconStr === "")
                                            return "";
                                        // Already a URL (qsimage raw data or file path) — use directly
                                        if (iconStr.startsWith("image://") || iconStr.startsWith("/") || iconStr.startsWith("file://"))
                                            return iconStr;
                                        // Theme icon name — look up, but treat bare "image://icon/" as empty
                                        const p = Quickshell.iconPath(iconStr);
                                        return p === "image://icon/" ? "" : p;
                                    }
                                    visible: resolved !== "" && status !== Image.Error
                                    implicitSize: Config.bar.fontSizeStatus
                                    source: resolved
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: entryDelegate.modelData.text
                                    color: entryDelegate.modelData.enabled ? Config.colors.textPrimary : Config.colors.textMuted
                                    font.family: Config.font.family
                                    font.pixelSize: Config.bar.fontSizeStatus
                                }
                            }

                            MouseArea {
                                id: entryMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: entryDelegate.modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                enabled: !entryDelegate.modelData.isSeparator
                                onEntered: root.openPopupReq(root.popupName)
                                onClicked: {
                                    if (entryDelegate.modelData.enabled) {
                                        entryDelegate.modelData.triggered();
                                        root.keepPopupReq();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Scrollbar (only shown when content overflows)
        Item {
            id: menuScrollbar
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: Math.round(8 * Config.scale)
            anchors.rightMargin: Math.round(6 * Config.scale)
            anchors.bottomMargin: Math.round(8 * Config.scale)
            width: Math.round(3 * Config.scale)

            readonly property bool needed: menuFlickable.contentHeight > menuFlickable.height
            visible: needed

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Config.colors.border
            }

            Rectangle {
                readonly property real ratio: menuFlickable.height / Math.max(menuFlickable.contentHeight, 1)
                readonly property real thumbH: Math.max(Math.round(20 * Config.scale), menuScrollbar.height * ratio)
                readonly property real travel: menuScrollbar.height - thumbH
                readonly property real scrollRatio: menuFlickable.contentHeight > menuFlickable.height ? menuFlickable.contentY / (menuFlickable.contentHeight - menuFlickable.height) : 0

                width: parent.width
                height: thumbH
                y: travel * scrollRatio
                radius: width / 2
                color: Config.colors.textMuted
                Behavior on y {
                    NumberAnimation {
                        duration: 60
                    }
                }
            }
        }
    }
}
