pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "components"

// View-only notification card for the lock screen.
// No dismiss interaction, no action buttons, no auto-timeout.
Item {
    id: root

    property var snapshot: null

    clip: false
    implicitHeight: card.implicitHeight + Math.round(6 * Config.scale)
    implicitWidth: Config.notifications.cardWidth

    PopupCard {
        id: card

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: Math.round(3 * Config.scale)
        }

        popupRadius: Config.notifications.radius
        implicitHeight: cardContent.implicitHeight + Math.round(20 * Config.scale)

        // Left accent bar
        Item {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                topMargin: Math.round(8 * Config.scale)
                bottomMargin: Math.round(8 * Config.scale)
            }
            width: Config.notifications.accentBar
            clip: true

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: width / 2
                color: Config.colors.glowAccent
                opacity: 0.45
            }

            Rectangle {
                anchors.fill: parent
                radius: Config.notifications.accentBar
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Config.colors.accent }
                    GradientStop { position: 1.0; color: Config.colors.accentAlt }
                }
            }
        }

        // Lock icon overlay — signals this is view-only
        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: Math.round(8 * Config.scale)
            anchors.rightMargin: Math.round(10 * Config.scale)
            text: "\uF023"
            color: Config.colors.textMuted
            font.family: Config.font.family
            font.pixelSize: Math.round(10 * Config.scale)
            opacity: 0.4
        }

        ColumnLayout {
            id: cardContent
            spacing: Math.round(4 * Config.scale)

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: Math.round(18 * Config.scale)
                rightMargin: Math.round(24 * Config.scale)
                topMargin: Math.round(10 * Config.scale)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * Config.scale)

                IconImage {
                    implicitSize: Config.notifications.iconSize
                    source: {
                        const appIcon = root.snapshot?.appIcon ?? "";
                        const deskEntry = root.snapshot?.desktopEntry ?? "";
                        if (appIcon !== "") {
                            const path = Quickshell.iconPath(appIcon);
                            if (path !== "") return path;
                        }
                        if (deskEntry !== "" && deskEntry !== null) {
                            const entry = DesktopEntries.byId(deskEntry);
                            if (entry && entry.icon !== "") return Quickshell.iconPath(entry.icon);
                        }
                        return Quickshell.iconPath("applications-other-symbolic");
                    }
                    visible: source !== ""
                }

                Text {
                    text: root.snapshot?.appName ?? ""
                    color: Config.colors.accent
                    font.family: Config.font.family
                    font.pixelSize: Config.notifications.fontSizeAppName
                    font.weight: Font.SemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: {
                        const d = root.snapshot?.receivedAt;
                        return d ? Qt.formatTime(d, "hh:mm") : "";
                    }
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.notifications.fontSizeTimestamp
                }
            }

            Text {
                text: root.snapshot?.summary ?? ""
                color: Config.colors.textPrimary
                font.family: Config.font.family
                font.pixelSize: Config.notifications.fontSizeSummary
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }

            Text {
                text: root.snapshot?.body ?? ""
                color: Config.colors.textSecondary
                font.family: Config.font.family
                font.pixelSize: Config.notifications.fontSizeBody
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.bottomMargin: Math.round(2 * Config.scale)
                visible: text !== ""
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }
    }
}
