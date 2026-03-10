pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.Mpris

import ".."
import "../components"

// Music/media section for the top menu drawer.
// Square card: album art fills the entire background,
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
    readonly property string trackAlbum: player ? (player.trackAlbum || "") : ""
    readonly property string artUrl: player ? (player.trackArtUrl || "") : ""
    // Optional-chain so this re-evaluates when the player's own isPlaying changes
    readonly property bool isPlaying: player?.isPlaying ?? false
    readonly property real progress: (player && player.length > 0) ? Math.max(0, Math.min(1, player.position / player.length)) : 0
    readonly property real volume: player ? Math.max(0, Math.min(1, player.volume)) : 0

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
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: parent.height * 0.82
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, 0.50) }
            GradientStop { position: 1.0;  color: Qt.rgba(0, 0, 0, 0.90) }
        }
    }

    // ── Text + controls column ───────────────────────────────────────────────
    ColumnLayout {
        id: contentCol
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: Math.round(10 * Config.scale)
            rightMargin: Math.round(10 * Config.scale)
            bottomMargin: Math.round(9 * Config.scale)
        }
        spacing: Math.round(5 * Config.scale)

        // Track title
        Item {
            Layout.fillWidth: true
            implicitHeight: titleText.implicitHeight

            Text {
                id: titleText
                width: parent.width
                text: root.trackTitle
                color: "white"
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeMd
                font.weight: Font.SemiBold
                elide: Text.ElideRight
            }

            MultiEffect {
                source: titleText
                anchors.fill: titleText
                shadowEnabled: true
                shadowColor: "black"
                shadowBlur: 0.8
                shadowOpacity: 0.9
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 1
            }
        }

        // Artist
        Item {
            Layout.fillWidth: true
            implicitHeight: artistText.implicitHeight
            visible: root.trackArtist !== ""

            Text {
                id: artistText
                width: parent.width
                text: root.trackArtist
                color: Qt.rgba(1, 1, 1, 0.85)
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeSm
                elide: Text.ElideRight
            }

            MultiEffect {
                source: artistText
                anchors.fill: artistText
                shadowEnabled: true
                shadowColor: "black"
                shadowBlur: 0.8
                shadowOpacity: 0.85
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 1
            }
        }

        // Album
        Item {
            Layout.fillWidth: true
            implicitHeight: albumText.implicitHeight
            visible: root.trackAlbum !== ""

            Text {
                id: albumText
                width: parent.width
                text: root.trackAlbum
                color: Qt.rgba(1, 1, 1, 0.62)
                font.family: Config.font.family
                font.pixelSize: Math.round(Config.font.sizeSm * 0.88)
                elide: Text.ElideRight
            }

            MultiEffect {
                source: albumText
                anchors.fill: albumText
                shadowEnabled: true
                shadowColor: "black"
                shadowBlur: 0.8
                shadowOpacity: 0.80
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 1
            }
        }

        // Progress bar
        GradientProgressBar {
            Layout.fillWidth: true
            value: root.progress
            barHeight: Math.round(3 * Config.scale)
            visible: root.player !== null
        }

        // Playback controls (centred)
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Math.round(12 * Config.scale)

            // Previous
            Rectangle {
                implicitWidth: Math.round(28 * Config.scale)
                implicitHeight: Math.round(28 * Config.scale)
                radius: implicitWidth / 2
                color: prevMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : "transparent"
                opacity: root.player ? 1 : Config.bar.disabledOpacity
                Behavior on color { ColorAnimation { duration: 80 } }

                Text {
                    anchors.fill: parent
                    text: "\u23ee"
                    color: "white"
                    font.pixelSize: Config.font.sizeSm
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
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
                        color: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, playMouse.containsMouse ? 0.60 : 0.40)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(Config.colors.accentAlt.r, Config.colors.accentAlt.g, Config.colors.accentAlt.b, playMouse.containsMouse ? 0.50 : 0.30)
                    }
                }
                border.color: Config.colors.accent
                border.width: 1
                opacity: root.player ? 1 : Config.bar.disabledOpacity

                Text {
                    anchors.fill: parent
                    // ⏸ U+23F8 when playing, ▶ U+25B6 when paused/stopped
                    text: root.isPlaying ? "\u23f8" : "\u25b6"
                    color: "white"
                    font.pixelSize: Config.font.sizeSm
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.player) root.player.togglePlaying()
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
                    anchors.fill: parent
                    text: "\u23ed"
                    color: "white"
                    font.pixelSize: Config.font.sizeSm
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
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

        // Volume slider — full width across the bottom
        Item {
            Layout.fillWidth: true
            implicitHeight: Math.round(20 * Config.scale)
            opacity: root.player ? 1 : Config.bar.disabledOpacity

            readonly property real frac: root.volume

            // Rail
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: Math.round(3 * Config.scale)
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.25)
            }

            // Fill
            Rectangle {
                id: volFill
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * parent.frac
                height: Math.round(3 * Config.scale)
                radius: height / 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Config.colors.accent }
                    GradientStop { position: 1.0; color: Config.colors.accentAlt }
                }
                Behavior on width { NumberAnimation { duration: 60; easing.type: Easing.OutQuart } }
            }

            // Thumb glow
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: parent.width * parent.frac - width / 2
                width: Math.round(14 * Config.scale)
                height: width
                radius: width / 2
                color: Config.colors.glowAccent
                opacity: 0.5
                Behavior on x { NumberAnimation { duration: 60; easing.type: Easing.OutQuart } }
            }

            // Thumb
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: parent.width * parent.frac - width / 2
                width: Math.round(10 * Config.scale)
                height: width
                radius: width / 2
                color: "white"
                Behavior on x { NumberAnimation { duration: 60; easing.type: Easing.OutQuart } }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.SizeHorCursor

                function applyX(mx) {
                    if (!root.player || !root.player.volumeSupported) return
                    root.player.volume = Math.max(0, Math.min(1, mx / width))
                }

                onPressed:         mouse => applyX(mouse.x)
                onPositionChanged: mouse => { if (pressed) applyX(mouse.x) }
                onWheel:           wheel => {
                    if (!root.player || !root.player.volumeSupported) return
                    root.player.volume = Math.max(0, Math.min(1, root.player.volume + wheel.angleDelta.y / 1200))
                }
            }
        }
    }
}
