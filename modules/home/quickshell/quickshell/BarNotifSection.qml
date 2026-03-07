pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "components"

// Notification history bar section.
// Shows a bell icon with an unread badge. Clicking/hovering opens the history popup.
Item {
    id: notifSection

    // ── Public API ────────────────────────────────────────────────────────────

    property string activePopup: ""

    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq

    // Expose popup rect for Bar.qml input mask
    property alias popup: notifPopup

    // Bound from Bar.qml, which gets them from shell.qml's Notifications instance
    property var notifHistory: []
    signal removeHistoryEntry(var entryId)

    // Screen height for popup sizing
    property real availableHeight: 800

    // ── Geometry ──────────────────────────────────────────────────────────────

    implicitWidth: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    implicitHeight: Config.bar.batteryIconSize + Math.round(10 * Config.scale)

    readonly property bool popupOpen: activePopup === "notif"

    containmentMask: Item {
        x: notifSection.popupOpen ? -Math.max(0, (notifPopup.width - notifSection.width) / 2) : 0
        y: notifSection.popupOpen ? -notifPopup.height - Config.bar.popupOffset : 0
        width: notifSection.popupOpen ? Math.max(notifSection.width, notifPopup.width) : notifSection.width
        height: notifSection.popupOpen ? notifPopup.height + Config.bar.popupOffset + notifSection.height : notifSection.height
    }

    // ── Trigger ───────────────────────────────────────────────────────────────

    MouseArea {
        id: triggerArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: notifSection.notifHistory.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: if (notifSection.notifHistory.length > 0) notifSection.openPopupReq("notif")
        onExited: notifSection.keepPopupReq()
        onClicked: if (notifSection.notifHistory.length > 0) notifSection.openPopupReq("notif")
    }

    BarButton {
        anchors.fill: parent
        hovered: triggerArea.containsMouse
        popupOpen: notifSection.popupOpen
        clickable: notifSection.notifHistory.length > 0

        // Bell icon + badge — dim when nothing in history
        Item {
            anchors.fill: parent
            opacity: notifSection.notifHistory.length > 0 ? 1.0 : Config.bar.disabledOpacity
            Behavior on opacity { NumberAnimation { duration: 200 } }

            // Bell icon
            Text {
                anchors.centerIn: parent
                text: "\uF0F3"   // fa-bell (NerdFont)
                font.family: Config.font.family
                font.pixelSize: Math.round(Config.bar.batteryIconSize * 0.72)
                color: notifSection.notifHistory.length > 0 ? Config.colors.accent : Config.colors.textMuted
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            // Badge
            Rectangle {
                visible: notifSection.notifHistory.length > 0
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Math.round(4 * Config.scale)
                anchors.rightMargin: Math.round(4 * Config.scale)

                width: badgeText.implicitWidth + Math.round(6 * Config.scale)
                height: Math.round(14 * Config.scale)
                radius: height / 2

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Config.colors.accent }
                    GradientStop { position: 1.0; color: Config.colors.accentAlt }
                }

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: notifSection.notifHistory.length > 99 ? "99+" : String(notifSection.notifHistory.length)
                    color: "#1a1a2e"
                    font.family: Config.font.family
                    font.pixelSize: Math.round(Config.bar.fontSizeStatus * 0.65)
                    font.weight: Font.Bold
                }
            }
        }
    }

    // ── Popup ─────────────────────────────────────────────────────────────────

    PopupContainer {
        id: notifPopup
        popupOpen: notifSection.popupOpen

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        // Width: match notification card width + padding
        width: Config.notifications.cardWidth + Math.round(24 * Config.scale)

        // Height: cap to available screen space
        readonly property real _maxHeight: notifSection.availableHeight
                                           - notifSection.height
                                           - Config.bar.popupOffset
                                           - Math.round(16 * Config.scale)
        readonly property real _contentH: popupCol.implicitHeight + Math.round(16 * Config.scale)
        height: Math.min(_contentH, _maxHeight)

        z: 20

        HoverHandler {
            onHoveredChanged: {
                if (hovered) notifSection.openPopupReq("notif")
                else notifSection.exitPopupReq()
            }
        }

        // Scroll state (wheel/touchpad, no Flickable)
        property real scrollY: 0
        readonly property real _viewportH: notifPopup.height - Math.round(16 * Config.scale)
        readonly property real maxScrollY: Math.max(0, popupCol.implicitHeight - notifPopup._viewportH)
        onMaxScrollYChanged: {
            if (notifPopup.scrollY > notifPopup.maxScrollY)
                notifPopup.scrollY = notifPopup.maxScrollY;
        }

        WheelHandler {
            target: null
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                const step = Math.round(40 * Config.scale);
                notifPopup.scrollY = Math.max(0,
                    Math.min(notifPopup.maxScrollY,
                        notifPopup.scrollY - event.angleDelta.y / 120 * step));
            }
        }

        // Viewport
        Item {
            id: viewport
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.right: scrollbarItem.left
            anchors.topMargin: Math.round(8 * Config.scale)
            anchors.bottomMargin: Math.round(8 * Config.scale)
            anchors.leftMargin: Math.round(12 * Config.scale)
            anchors.rightMargin: Math.round(4 * Config.scale)
            clip: true

            Column {
                id: popupCol
                width: viewport.width
                spacing: Math.round(6 * Config.scale)
                y: -notifPopup.scrollY

                // ── Empty state ───────────────────────────────────────────
                Text {
                    visible: notifSection.notifHistory.length === 0
                    width: parent.width
                    text: "No notifications"
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizeStatus
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: Math.round(12 * Config.scale)
                    bottomPadding: Math.round(8 * Config.scale)
                }

                // ── History cards ─────────────────────────────────────────
                Repeater {
                    model: notifSection.notifHistory

                    delegate: NotificationCard {
                        id: histDelegate
                        required property var modelData

                        historyMode: true
                        snapshot: histDelegate.modelData
                        width: popupCol.width

                        onDismissed: notifSection.removeHistoryEntry(histDelegate.modelData.id)
                    }
                }
            }
        }

        // Scrollbar
        Item {
            id: scrollbarItem
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: Math.round(8 * Config.scale)
            anchors.bottomMargin: Math.round(8 * Config.scale)
            anchors.rightMargin: Math.round(3 * Config.scale)
            width: Math.round(3 * Config.scale)

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Config.colors.border
                visible: notifPopup.maxScrollY > 0
            }

            Rectangle {
                readonly property real ratio: notifPopup._viewportH / Math.max(popupCol.implicitHeight, 1)
                readonly property real thumbH: Math.max(Math.round(20 * Config.scale), scrollbarItem.height * ratio)
                readonly property real travel: scrollbarItem.height - thumbH
                readonly property real scrollRatio: notifPopup.maxScrollY > 0
                                                    ? notifPopup.scrollY / notifPopup.maxScrollY : 0

                width: parent.width
                height: thumbH
                y: travel * scrollRatio
                radius: width / 2
                color: Config.colors.textMuted
                visible: notifPopup.maxScrollY > 0
                Behavior on y { NumberAnimation { duration: 60 } }
            }
        }
    }
}
