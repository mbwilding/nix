pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import ".."
import "../components"
import "../notifications"

BarSectionItem {
    id: notifSection

    property alias popup: notifPopup
    property real availableHeight: 800
    property string activePopup: ""
    property var _historyCards: ({})
    property var notifHistory: []

    readonly property bool popupOpen: activePopup === "notif"

    signal closePopupReq
    signal dismissAll
    signal exitPopupReq
    signal keepPopupReq
    signal openPopupReq(string name)
    signal removeHistoryEntry(var entryId)

    implicitWidth: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    implicitHeight: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    popupItem: notifPopup
    onNotifHistoryChanged: {
        if (notifSection.notifHistory.length === 0 && notifSection.popupOpen)
            notifSection.closePopupReq();
    }
    onPopupOpenChanged: {
        if (notifSection.popupOpen)
            Qt.callLater(() => {
                notifSection.openPopupReq("notif");
            });
    }

    function animateOutEntry(snapId) {
        const card = notifSection._historyCards[snapId];
        if (card)
            card.animateOut();
    }

    MouseArea {
        id: triggerArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: notifSection.notifHistory.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: if (notifSection.notifHistory.length > 0)
            notifSection.openPopupReq("notif")
        onExited: notifSection.keepPopupReq()
        onClicked: if (notifSection.notifHistory.length > 0)
            notifSection.dismissAll()
    }

    BarButton {
        anchors.fill: parent
        hovered: triggerArea.containsMouse
        popupOpen: notifSection.popupOpen
        clickable: notifSection.notifHistory.length > 0

        Item {
            anchors.fill: parent
            opacity: notifSection.notifHistory.length > 0 ? 1.0 : Config.bar.disabledOpacity
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            Text {
                anchors.centerIn: parent
                text: "\uF0F3"
                font.family: Config.font.family
                font.pixelSize: Math.round(Config.bar.batteryIconSize * 0.72)
                color: notifSection.notifHistory.length > 0 ? Config.colors.accent : Config.colors.textMuted
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
            }

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
                    GradientStop {
                        position: 0.0
                        color: Config.colors.accent
                    }
                    GradientStop {
                        position: 1.0
                        color: Config.colors.accentAlt
                    }
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

    PopupContainer {
        id: notifPopup
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset
        anchors.horizontalCenter: parent.horizontalCenter
        height: Math.min(_contentH, _maxHeight)
        popupOpen: notifSection.popupOpen
        width: Config.notifications.cardWidth + Math.round(24 * Config.scale)
        z: 20

        readonly property real _maxHeight: notifSection.availableHeight - notifSection.height - Config.bar.popupOffset - Math.round(16 * Config.scale)
        readonly property real _contentH: popupCol.implicitHeight + Math.round(16 * Config.scale)

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    notifSection.openPopupReq("notif");
                else
                    notifSection.exitPopupReq();
            }
        }

        PopupScrollView {
            id: scrollView
            anchors.fill: parent
            leftMargin: Math.round(12 * Config.scale)
            contentColumn: popupCol

            HoverHandler {
                onHoveredChanged: {
                    if (hovered)
                        notifSection.openPopupReq("notif");
                }
            }

            Column {
                id: popupCol
                width: scrollView.contentWidth
                spacing: Math.round(6 * Config.scale)
                y: -scrollView.scrollY

                PopupSectionHeader {
                    text: "Notifications"
                    width: parent.width
                }

                Repeater {
                    model: notifSection.notifHistory

                    delegate: NotificationsCard {
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
