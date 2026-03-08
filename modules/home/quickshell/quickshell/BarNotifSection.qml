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
    signal closePopupReq

    // Expose popup rect for Bar.qml input mask
    property alias popup: notifPopup

    // Bound from Bar.qml, which gets them from shell.qml's Notifications instance
    property var notifHistory: []
    signal removeHistoryEntry(var entryId)
    signal dismissAll()

    onNotifHistoryChanged: {
        if (notifSection.notifHistory.length === 0 && notifSection.popupOpen)
            notifSection.closePopupReq();
    }

    // Called by Bar.qml when a live notification is dismissed externally.
    // If the popup is open, animate the history card out (it calls removeHistoryEntry on dismissed).
    // If the popup is closed, no card exists — remove directly.
    property var _historyCards: ({})
    function animateOutEntry(snapId) {
        const card = notifSection._historyCards[snapId];
        if (card)
            card.animateOut();
    }

    // Screen height for popup sizing
    property real availableHeight: 800

    // ── Geometry ──────────────────────────────────────────────────────────────

    implicitWidth: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    implicitHeight: Config.bar.batteryIconSize + Math.round(10 * Config.scale)

    readonly property bool popupOpen: activePopup === "notif"

    // HoverHandler does not synthesize a hover-enter when an item first becomes
    // visible under a stationary cursor — so the first time the popup appears the
    // quickCloseTimer (started by the trigger's onExited) is never cancelled by
    // the popup's HoverHandler, and the popup closes 600 ms later.
    // Fix: whenever the popup transitions from closed→open, re-emit openPopupReq
    // after one event-loop cycle so Bar.qml's openPopup() cancels the timer.
    onPopupOpenChanged: {
        if (notifSection.popupOpen)
            Qt.callLater(() => { notifSection.openPopupReq("notif"); });
    }

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
        onClicked: if (notifSection.notifHistory.length > 0) notifSection.dismissAll()
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
                    color: Config.colors.badgeText
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

        // Scrollable notification history
        PopupScrollView {
            id: scrollView
            anchors.fill: parent
            leftMargin: Math.round(12 * Config.scale)
            contentColumn: popupCol

            // Keep popup open when hovering over cards
            HoverHandler {
                onHoveredChanged: {
                    if (hovered) notifSection.openPopupReq("notif")
                }
            }

            Column {
                id: popupCol
                width: scrollView.contentWidth
                spacing: Math.round(6 * Config.scale)
                y: -scrollView.scrollY

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
                        onHovered: notifSection.openPopupReq("notif")

                        Component.onCompleted: {
                            notifSection._historyCards[histDelegate.modelData.id] = histDelegate;
                            notifSection._historyCardsChanged();
                        }
                        Component.onDestruction: {
                            delete notifSection._historyCards[histDelegate.modelData.id];
                            notifSection._historyCardsChanged();
                        }
                    }
                }
            }
        }
    }
}
