pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "components"

BarSectionItem {
    id: root

    required property SystemTrayItem trayItem

    // Popup manager integration — set by Bar.qml delegate
    property string popupName: ""
    property string activePopup: ""
    property real availableHeight: 800
    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq
    signal closePopupReq

    signal hovered

    readonly property bool popupOpen: activePopup === popupName && popupName !== ""

    // Expose the popup item so Bar.qml can include it in the input mask
    readonly property Item menuPopup: menuPopupRect

    implicitWidth: iconContainer.implicitWidth
    implicitHeight: iconContainer.implicitHeight

    popupItem: menuPopupRect

    // ── Popup width calculation ───────────────────────────────────────────────
    // Measures the widest menu entry text to size the popup correctly.

    // Used for per-entry text width measurement
    TextMetrics {
        id: entryTextMetrics
        font.family: Config.font.family
        font.pixelSize: Config.bar.fontSizePopup
    }

    // Computed imperatively to avoid a binding loop from mutating entryTextMetrics.text
    property int menuPopupWidth: Math.round(200 * Config.scale)

    function recomputePopupWidth() {
        const entries = menuOpener.children ? menuOpener.children.values : [];
        const iconW = Config.bar.fontSizePopup + Math.round(8 * Config.scale);
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

    readonly property int maxPopupHeight: root.availableHeight
                                          - root.height
                                          - Config.bar.popupOffset
                                          - Math.round(16 * Config.scale)

    // ─────────────────────────────────────────────────────────────────────────

    BarButton {
        id: iconContainer

        hovered: hoverArea.containsMouse
        popupOpen: root.popupOpen

        IconImage {
            id: icon
            anchors.centerIn: parent
            implicitSize: Config.bar.batteryIconSize
            mipmap: true
            source: root.trayItem.icon
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor

            onEntered: {
                root.hovered();
                if (root.trayItem.hasMenu && root.popupName !== "")
                    root.openPopupReq(root.popupName);
            }
            onExited: root.keepPopupReq()

            onClicked: {
                root.hovered();
                root.trayItem.activate();
            }
        }
    }

    // ── Menu popup ────────────────────────────────────────────────────────────

    QsMenuOpener {
        id: menuOpener
        menu: root.trayItem.menu
        onChildrenChanged: root.recomputePopupWidth()
    }

    PopupContainer {
        id: menuPopupRect

        popupOpen: root.popupOpen

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        width: root.menuPopupWidth
        height: Math.min(menuCol.implicitHeight + Math.round(16 * Config.scale), root.maxPopupHeight)

        z: 20

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    root.openPopupReq(root.popupName);
                else
                    root.exitPopupReq();
            }
        }

        ScrollableList {
            id: menuScrollList
            anchors.fill: parent
            topPadding: Math.round(8 * Config.scale)
            bottomPadding: Math.round(8 * Config.scale)
            leftPadding: Math.round(8 * Config.scale)
            thumbColor: Config.colors.textMuted

            Column {
                id: menuCol
                width: parent.width
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
                                    implicitSize: Config.bar.fontSizePopup
                                    source: resolved
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: entryDelegate.modelData.text
                                    color: entryDelegate.modelData.enabled ? Config.colors.textPrimary : Config.colors.textMuted
                                    font.family: Config.font.family
                                    font.pixelSize: Config.bar.fontSizePopup
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
                                        root.closePopupReq();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
