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
    signal keepPopupReq()
    signal exitPopupReq()

    signal hovered()

    readonly property bool popupOpen: activePopup === popupName && popupName !== ""

    // Expose the popup item so Bar.qml can include it in the input mask
    readonly property Item menuPopup: menuPopupRect

    implicitWidth: iconContainer.implicitWidth
    implicitHeight: iconContainer.implicitHeight

    // ── Popup width calculation ───────────────────────────────────────────────
    // Measures the widest menu entry text to size the popup correctly.

    // Used for line-height measurement (text fixed to "Mg" for ascent+descent)
    TextMetrics {
        id: lineMetrics
        font.family: Config.font.family
        font.pixelSize: Config.bar.fontSizeStatus
        text: "Mg"
    }

    // Used for per-entry text width measurement (text mutated in JS loop)
    TextMetrics {
        id: entryTextMetrics
        font.family: Config.font.family
        font.pixelSize: Config.bar.fontSizeStatus
    }

    // Actual rendered line height: max of icon size and text implicit height.
    // Text.implicitHeight ≈ boundingRect.height (ascent+descent) + 1px headroom.
    readonly property int entryLineHeight: Math.max(
        Config.bar.fontSizeStatus,
        Math.ceil(lineMetrics.boundingRect.height) + 1
    )

    readonly property int menuPopupWidth: {
        const entries = menuOpener.children ? menuOpener.children.values : [];
        const iconW = Config.bar.fontSizeStatus + Math.round(8 * Config.scale); // entry icon + spacing
        const rowMargins = Math.round(8 * Config.scale) * 2;  // left + right row margin
        const colPadding = Math.round(16 * Config.scale);     // popup left + right padding
        let maxTextW = Math.round(100 * Config.scale);
        for (let i = 0; i < entries.length; i++) {
            const entry = entries[i];
            if (!entry || entry.isSeparator) continue;
            entryTextMetrics.text = entry.text || "";
            const w = entryTextMetrics.boundingRect.width;
            if (w > maxTextW) maxTextW = w;
        }
        return iconW + maxTextW + rowMargins + colPadding;
    }

    readonly property int menuPopupHeight: {
        const entries = menuOpener.children ? menuOpener.children.values : [];
        const rowH = root.entryLineHeight + Math.round(10 * Config.scale); // line height + vertical padding
        const sepH = Math.round(9 * Config.scale);
        const spacing = Math.round(2 * Config.scale);
        const padding = Math.round(8 * Config.scale) * 2;
        let total = 0;
        for (let i = 0; i < entries.length; i++) {
            if (i > 0) total += spacing;
            total += entries[i] && entries[i].isSeparator ? sepH : rowH;
        }
        return total + padding;
    }

    // ─────────────────────────────────────────────────────────────────────────

    Rectangle {
        id: iconContainer

        implicitWidth: Config.bar.batteryIconSize + Math.round(8 * Config.scale)
        implicitHeight: Config.bar.batteryIconSize + Math.round(8 * Config.scale)
        radius: Math.round(6 * Config.scale)
        color: (hoverArea.containsMouse || root.popupOpen)
            ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.15)
            : "transparent"

        Behavior on color {
            ColorAnimation { duration: 100 }
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
                root.hovered()
                if (root.trayItem.hasMenu && root.popupName !== "")
                    root.openPopupReq(root.popupName)
            }
            onExited: root.keepPopupReq()

            onClicked: mouse => {
                root.hovered()
                if (root.trayItem.hasMenu) {
                    if (root.popupName !== "")
                        root.openPopupReq(root.popupName)
                } else {
                    root.trayItem.activate()
                }
            }
        }
    }

    // ── Menu popup ────────────────────────────────────────────────────────────

    QsMenuOpener {
        id: menuOpener
        menu: root.trayItem.menu
    }

    Rectangle {
        id: menuPopupRect

        visible: opacity > 0
        opacity: root.popupOpen ? 1 : 0
        scale: root.popupOpen ? 1 : 0.92
        transformOrigin: Item.Bottom

        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }
        Behavior on scale   { NumberAnimation { duration: 120; easing.type: Easing.InOutQuad } }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        width: root.menuPopupWidth
        height: root.menuPopupHeight

        radius: Math.round(10 * Config.scale)
        color: Config.colors.background
        border.color: Config.colors.border
        border.width: 1
        clip: true
        z: 20

        HoverHandler {
            onHoveredChanged: {
                if (hovered) root.openPopupReq(root.popupName)
                else root.exitPopupReq()
            }
        }

        Column {
            id: menuCol
            x: Math.round(8 * Config.scale)
            y: Math.round(8 * Config.scale)
            width: menuPopupRect.width - Math.round(8 * Config.scale) * 2
            spacing: Math.round(2 * Config.scale)

            Repeater {
                model: menuOpener.children

                delegate: Item {
                    id: entryDelegate
                    required property QsMenuEntry modelData
                    width: menuCol.width

                    implicitHeight: modelData.isSeparator
                        ? Math.round(9 * Config.scale)
                        : entryRow.implicitHeight + Math.round(10 * Config.scale)

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
                        color: entryMouse.containsMouse && entryDelegate.modelData.enabled
                            ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
                        Behavior on color { ColorAnimation { duration: 80 } }

                        RowLayout {
                            id: entryRow
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: Math.round(8 * Config.scale)
                            anchors.rightMargin: Math.round(8 * Config.scale)
                            spacing: Math.round(8 * Config.scale)

                            IconImage {
                                visible: entryDelegate.modelData.icon !== ""
                                implicitSize: Config.bar.fontSizeStatus
                                source: entryDelegate.modelData.icon !== ""
                                    ? Quickshell.iconPath(entryDelegate.modelData.icon) : ""
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: entryDelegate.modelData.text
                                color: entryDelegate.modelData.enabled
                                    ? Config.colors.textPrimary : Config.colors.textMuted
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizeStatus
                            }
                        }

                        MouseArea {
                            id: entryMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: entryDelegate.modelData.enabled
                                ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: !entryDelegate.modelData.isSeparator
                            onEntered: root.openPopupReq(root.popupName)
                            onClicked: {
                                if (entryDelegate.modelData.enabled) {
                                    entryDelegate.modelData.triggered()
                                    root.keepPopupReq()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
