pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

import ".."
import "../components"

// Music/media section for the top menu drawer.
// Fills whatever space its parent gives it.
ColumnLayout {
    id: root

    spacing: Math.round(10 * Config.scale)

    readonly property MprisPlayer player: MprisController.currentPlayer

    readonly property string trackTitle: player ? (player.trackTitle || "Nothing playing") : "Nothing playing"
    readonly property string trackArtist: player ? (player.trackArtist || "") : ""
    readonly property bool isPlaying: player ? player.isPlaying : false
    readonly property real progress: (player && player.length > 0) ? Math.max(0, Math.min(1, player.position / player.length)) : 0

    // Track info
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Math.round(3 * Config.scale)

        Text {
            Layout.fillWidth: true
            text: root.trackTitle
            color: Config.colors.textPrimary
            font.family: Config.font.family
            font.pixelSize: Config.font.sizeMd
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: root.trackArtist
            color: Config.colors.textSecondary
            font.family: Config.font.family
            font.pixelSize: Config.font.sizeSm
            elide: Text.ElideRight
            visible: root.trackArtist !== ""
        }
    }

    // Spacer
    Item { Layout.fillHeight: true }

    // Progress bar
    GradientProgressBar {
        Layout.fillWidth: true
        value: root.progress
        barHeight: Math.round(4 * Config.scale)
        visible: root.player !== null
    }

    // Playback controls
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Math.round(16 * Config.scale)

        // Previous
        Rectangle {
            implicitWidth: Math.round(32 * Config.scale)
            implicitHeight: Math.round(32 * Config.scale)
            radius: implicitWidth / 2
            color: prevMouse.containsMouse ? Config.colors.surfaceHover : "transparent"
            opacity: root.player ? 1 : Config.bar.disabledOpacity
            Behavior on color { ColorAnimation { duration: 80 } }

            Text {
                anchors.centerIn: parent
                text: "\u23ee"
                color: Config.colors.textSecondary
                font.pixelSize: Config.font.sizeMd
            }

            MouseArea {
                id: prevMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.player) root.player.previous()
            }
        }

        // Play/Pause
        Rectangle {
            implicitWidth: Math.round(40 * Config.scale)
            implicitHeight: Math.round(40 * Config.scale)
            radius: implicitWidth / 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, playMouse.containsMouse ? 0.45 : 0.28)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(Config.colors.accentAlt.r, Config.colors.accentAlt.g, Config.colors.accentAlt.b, playMouse.containsMouse ? 0.35 : 0.18)
                }
            }
            border.color: Config.colors.accent
            border.width: 1
            opacity: root.player ? 1 : Config.bar.disabledOpacity

            Text {
                anchors.centerIn: parent
                text: root.isPlaying ? "\u23f8" : "\u25b6"
                color: Config.colors.accent
                font.pixelSize: Config.font.sizeMd
                font.weight: Font.Medium
            }

            MouseArea {
                id: playMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.player) root.player.playPause()
            }
        }

        // Next
        Rectangle {
            implicitWidth: Math.round(32 * Config.scale)
            implicitHeight: Math.round(32 * Config.scale)
            radius: implicitWidth / 2
            color: nextMouse.containsMouse ? Config.colors.surfaceHover : "transparent"
            opacity: root.player ? 1 : Config.bar.disabledOpacity
            Behavior on color { ColorAnimation { duration: 80 } }

            Text {
                anchors.centerIn: parent
                text: "\u23ed"
                color: Config.colors.textSecondary
                font.pixelSize: Config.font.sizeMd
            }

            MouseArea {
                id: nextMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.player) root.player.next()
            }
        }
    }
}
