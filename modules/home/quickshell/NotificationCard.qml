pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Item {
    id: root

    required property Notification notification
    property int animateSpeed: 250

    // Slide in from the right
    property bool visible_: false

    implicitHeight: visible_ ? card.implicitHeight + 8 : 0
    implicitWidth: 360

    Behavior on implicitHeight {
        NumberAnimation {
            duration: root.animateSpeed
            easing.type: Easing.InOutQuad
        }
    }

    clip: true

    Rectangle {
        id: card

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: 4
            bottomMargin: 4
        }

        implicitHeight: cardContent.implicitHeight + 20
        radius: 12
        color: "#cc1a1a2e"

        border.color: "#30ffffff"
        border.width: 1

        // Slide in transform
        transform: Translate {
            x: root.visible_ ? 0 : card.width + 20
            Behavior on x {
                NumberAnimation {
                    duration: root.animateSpeed
                    easing.type: Easing.InOutQuad
                }
            }
        }

        opacity: root.visible_ ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: root.animateSpeed
                easing.type: Easing.InOutQuad
            }
        }

        // Left accent bar
        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                topMargin: 6
                bottomMargin: 6
                leftMargin: 0
            }
            width: 3
            radius: 2
            color: "#a0a0ff"
        }

        ColumnLayout {
            id: cardContent

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 16
                rightMargin: 12
                topMargin: 10
            }

            spacing: 4

            // Header: app icon + app name + close button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // App icon
                IconImage {
                    id: appIcon
                    implicitSize: 18
                    source: {
                        const n = root.notification;
                        if (!n) return "";
                        if (n.appIcon !== "") return Quickshell.iconPath(n.appIcon);
                        if (n.desktopEntry !== "" && n.desktopEntry !== null) {
                            const entry = DesktopEntries.byId(n.desktopEntry);
                            if (entry && entry.icon !== "") return Quickshell.iconPath(entry.icon);
                        }
                        return Quickshell.iconPath("applications-other-symbolic");
                    }
                    visible: source !== ""
                }

                // App name
                Text {
                    text: root.notification?.appName ?? ""
                    color: "#a0a0ff"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Timestamp
                Text {
                    text: {
                        const n = root.notification;
                        if (!n) return "";
                        const d = new Date();
                        return Qt.formatTime(d, "hh:mm");
                    }
                    color: "#60ffffff"
                    font.pixelSize: 10
                }

                // Close button
                Item {
                    implicitWidth: 18
                    implicitHeight: 18

                    Rectangle {
                        anchors.fill: parent
                        radius: 9
                        color: closeHover.containsMouse ? "#40ffffff" : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: "#80ffffff"
                        font.pixelSize: 10
                    }

                    HoverHandler { id: closeHover }
                    TapHandler {
                        onTapped: root.notification?.dismiss()
                    }
                }
            }

            // Summary (title)
            Text {
                text: root.notification?.summary ?? ""
                color: "white"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }

            // Body
            Text {
                text: root.notification?.body ?? ""
                color: "#ccffffff"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.bottomMargin: 2
                visible: text !== ""
                maximumLineCount: 4
                elide: Text.ElideRight
            }

            // Actions
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 2
                spacing: 6
                visible: root.notification?.actions?.length > 0

                Repeater {
                    model: root.notification?.actions ?? []

                    delegate: Rectangle {
                        required property NotificationAction modelData

                        implicitHeight: 24
                        implicitWidth: actionLabel.implicitWidth + 16
                        radius: 6
                        color: actionHover.containsMouse ? "#50a0a0ff" : "#30ffffff"
                        border.color: "#30ffffff"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: modelData.text
                            color: "white"
                            font.pixelSize: 11
                        }

                        HoverHandler { id: actionHover }
                        TapHandler {
                            onTapped: modelData.invoke()
                        }
                    }
                }
            }
        }
    }
}
