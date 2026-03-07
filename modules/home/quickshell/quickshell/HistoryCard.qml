pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "components"

// A notification card that displays a plain JS snapshot object (no live Notification).
// Used in the notification history popup.
Item {
    id: root

    // Snapshot object: { id, appName, appIcon, desktopEntry, summary, body,
    //                    actions[{identifier,text}], receivedAt (Date) }
    required property var snapshot

    signal dismissRequested

    implicitWidth: Config.notifications.cardWidth
    implicitHeight: card.implicitHeight

    PopupCard {
        id: card

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        popupRadius: Config.notifications.radius
        implicitHeight: cardContent.implicitHeight + Math.round(22 * Config.scale)

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
                anchors.margins: -3
                radius: width / 2
                color: Config.colors.glowAccent
                opacity: 0.55
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

        // Dismiss (×) button — top-right corner
        Rectangle {
            id: dismissBtn
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: Math.round(6 * Config.scale)
            anchors.rightMargin: Math.round(6 * Config.scale)
            width: Math.round(20 * Config.scale)
            height: Math.round(20 * Config.scale)
            radius: Math.round(5 * Config.scale)
            color: dismissMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
            Behavior on color { ColorAnimation { duration: 80 } }
            z: 10

            Text {
                anchors.centerIn: parent
                text: "\u00d7"
                color: dismissMouse.containsMouse ? Config.colors.textPrimary : Config.colors.textMuted
                font.family: Config.font.family
                font.pixelSize: Config.bar.fontSizeStatus
                Behavior on color { ColorAnimation { duration: 80 } }
            }

            MouseArea {
                id: dismissMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.dismissRequested()
            }
        }

        ColumnLayout {
            id: cardContent

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: Math.round(18 * Config.scale)
                rightMargin: Math.round(30 * Config.scale)   // leave room for × button
                topMargin: Math.round(12 * Config.scale)
            }

            spacing: Math.round(5 * Config.scale)

            // Header: icon + app name + timestamp
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * Config.scale)

                IconImage {
                    implicitSize: Config.notifications.iconSize
                    source: {
                        const snap = root.snapshot;
                        if (!snap) return "";
                        if (snap.appIcon !== "") {
                            const p = Quickshell.iconPath(snap.appIcon);
                            if (p !== "") return p;
                        }
                        if (snap.desktopEntry !== "" && snap.desktopEntry !== null) {
                            const entry = DesktopEntries.byId(snap.desktopEntry);
                            if (entry && entry.icon !== "")
                                return Quickshell.iconPath(entry.icon);
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
                        if (!d) return "";
                        return Qt.formatTime(d, "hh:mm");
                    }
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.notifications.fontSizeTimestamp
                }
            }

            // Summary
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

            // Body
            Text {
                text: root.snapshot?.body ?? ""
                color: Config.colors.textSecondary
                font.family: Config.font.family
                font.pixelSize: Config.notifications.fontSizeBody
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.bottomMargin: Math.round(2 * Config.scale)
                visible: text !== ""
                maximumLineCount: Config.notifications.bodyMaxLines === 0 ? Number.MAX_VALUE : Config.notifications.bodyMaxLines
                elide: Text.ElideRight
            }

            // Actions — inert labels (no invoke, just dismiss the history card)
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: Math.round(4 * Config.scale)
                spacing: Math.round(6 * Config.scale)
                visible: (root.snapshot?.actions?.length ?? 0) > 0

                Repeater {
                    model: root.snapshot?.actions ?? []

                    delegate: Item {
                        id: histActionDelegate
                        required property var modelData

                        implicitHeight: Math.round(28 * Config.scale)
                        implicitWidth: histActionBg.implicitWidth

                        Rectangle {
                            id: histActionBg
                            anchors.fill: parent
                            implicitWidth: histActionLabel.implicitWidth + Math.round(18 * Config.scale)
                            radius: Math.round(8 * Config.scale)
                            color: Qt.rgba(1, 1, 1, 0.05)
                            border.color: Config.colors.border
                            border.width: 1

                            Text {
                                id: histActionLabel
                                anchors.centerIn: parent
                                text: histActionDelegate.modelData.text ?? ""
                                color: Config.colors.textMuted
                                font.family: Config.font.family
                                font.pixelSize: Config.notifications.fontSizeAction
                            }
                        }
                    }
                }
            }
        }
    }
}
