pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

import ".."
import "../components"

// Music/media section for the top menu drawer.
// Designed as a square card: album art fills the entire background,
// track info and controls sit over a dark gradient at the bottom.
Item {
    id: root

    // Pick the best available player:
    //   1. A player that is currently playing
    //   2. The first player in the list (paused/stopped)
    //   3. null if no players
    readonly property MprisPlayer player: {
        void Mpris.players.valuesChanged
        let playing = null
        let first = null
        const vals = Mpris.players.values
        for (let i = 0; i < vals.length; i++) {
            const p = vals[i]
            if (!first) first = p
            if (p.isPlaying && !playing) playing = p
        }
        return playing ?? first ?? null
    }

    readonly property string trackTitle: player ? (player.trackTitle || "Nothing playing") : "Nothing playing"
    readonly property string trackArtist: player ? (player.trackArtist || "") : ""
    readonly property string artUrl: player ? (player.trackArtUrl || "") : ""
    readonly property bool isPlaying: player ? player.isPlaying : false
    readonly property real progress: (player && player.length > 0) ? Math.max(0, Math.min(1, player.position / player.length)) : 0

    // ── Album art background ─────────────────────────────────────────────────
    Image {
        id: artImage
        anchors.fill: parent
        source: root.artUrl
        fillMode: Image.PreserveAspectCrop
        visible: root.artUrl !== "" && status === Image.Ready
        cache: false
    }

    // Solid fallback when no art is available
    Rectangle {
        anchors.fill: parent
        color: Config.colors.surface
        visible: root.artUrl === "" || artImage.status !== Image.Ready

        Text {
            anchors.centerIn: parent
            text: "\u266b"
            color: Config.colors.textMuted
            font.pixelSize: Math.round(40 * Config.scale)
        }
    }

    // ── Bottom gradient overlay ──────────────────────────────────────────────
    Rectangle {
        id: overlay
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: parent.height * 0.72
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.82) }
        }
    }

    // ── Content over the overlay ─────────────────────────────────────────────
    ColumnLayout {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: Math.round(10 * Config.scale)
            rightMargin: Math.round(10 * Config.scale)
            bottomMargin: Math.round(8 * Config.scale)
        }
        spacing: Math.round(6 * Config.scale)

        // Track title
        Text {
            Layout.fillWidth: true
            text: root.trackTitle
            color: "white"
            font.family: Config.font.family
            font.pixelSize: Config.font.sizeSm
            font.weight: Font.SemiBold
            elide: Text.ElideRight
            style: Text.Raised
            styleColor: Qt.rgba(0, 0, 0, 0.6)
        }

        // Artist
        Text {
            Layout.fillWidth: true
            text: root.trackArtist
            color: Qt.rgba(1, 1, 1, 0.72)
            font.family: Config.font.family
            font.pixelSize: Math.round(Config.font.sizeSm * 0.85)
            elide: Text.ElideRight
            visible: root.trackArtist !== ""
            style: Text.Raised
            styleColor: Qt.rgba(0, 0, 0, 0.5)
        }

        // Progress bar
        GradientProgressBar {
            Layout.fillWidth: true
            value: root.progress
            barHeight: Math.round(3 * Config.scale)
            visible: root.player !== null
        }

        // Playback controls
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Math.round(10 * Config.scale)

            // Previous
            Rectangle {
                implicitWidth: Math.round(28 * Config.scale)
                implicitHeight: Math.round(28 * Config.scale)
                radius: implicitWidth / 2
                color: prevMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : "transparent"
                opacity: root.player ? 1 : Config.bar.disabledOpacity
                Behavior on color { ColorAnimation { duration: 80 } }

                Text {
                    anchors.centerIn: parent
                    text: "\u23ee"
                    color: "white"
                    font.pixelSize: Config.font.sizeSm
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
                implicitWidth: Math.round(34 * Config.scale)
                implicitHeight: Math.round(34 * Config.scale)
                radius: implicitWidth / 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, playMouse.containsMouse ? 0.55 : 0.35)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(Config.colors.accentAlt.r, Config.colors.accentAlt.g, Config.colors.accentAlt.b, playMouse.containsMouse ? 0.45 : 0.25)
                    }
                }
                border.color: Config.colors.accent
                border.width: 1
                opacity: root.player ? 1 : Config.bar.disabledOpacity

                Text {
                    anchors.centerIn: parent
                    text: root.isPlaying ? "\u23f8" : "\u25b6"
                    color: "white"
                    font.pixelSize: Config.font.sizeSm
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
                implicitWidth: Math.round(28 * Config.scale)
                implicitHeight: Math.round(28 * Config.scale)
                radius: implicitWidth / 2
                color: nextMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : "transparent"
                opacity: root.player ? 1 : Config.bar.disabledOpacity
                Behavior on color { ColorAnimation { duration: 80 } }

                Text {
                    anchors.centerIn: parent
                    text: "\u23ed"
                    color: "white"
                    font.pixelSize: Config.font.sizeSm
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
}
