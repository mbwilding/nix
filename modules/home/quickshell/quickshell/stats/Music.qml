pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris

import ".."
import "../components"

// Music/media section for the top menu drawer.
// Square card: album art fills the entire background,
// track info and controls sit over a dark gradient at the bottom.
Item {
    id: root

    // ── Player selection ─────────────────────────────────────────────────────
    // Prefer a currently-playing player, then first available, then null.
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
    readonly property bool isPlaying: player?.isPlaying ?? false
    readonly property real trackLength: (player && player.lengthSupported && player.length > 0) ? player.length : 0
    readonly property real volume: player ? Math.max(0, Math.min(1, player.volume)) : 0

    // Live position — polled by positionTimer so it stays current while playing.
    property real livePosition: 0

    // Polling timer: fires every second while playing to refresh livePosition.
    Timer {
        id: positionTimer
        interval: 1000
        repeat: true
        running: root.player !== null && root.isPlaying
        onTriggered: {
            if (root.player) root.livePosition = root.player.position
        }
    }

    // Also update immediately when the player/track changes.
    onPlayerChanged: root.livePosition = root.player ? root.player.position : 0
    Connections {
        target: root.player
        function onTrackChanged() { root.livePosition = root.player ? root.player.position : 0 }
    }

    readonly property real progress: root.trackLength > 0
        ? Math.max(0, Math.min(1, root.livePosition / root.trackLength)) : 0

    // Helper: format seconds → m:ss
    function formatTime(secs) {
        const s = Math.max(0, Math.floor(secs))
        const m = Math.floor(s / 60)
        const r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }

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
        height: parent.height * 0.85
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.40; color: Qt.rgba(0, 0, 0, 0.50) }
            GradientStop { position: 1.0;  color: Qt.rgba(0, 0, 0, 0.92) }
        }
    }

    // ── Text + controls column ───────────────────────────────────────────────
    ColumnLayout {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: Math.round(10 * Config.scale)
            rightMargin: Math.round(10 * Config.scale)
            bottomMargin: Math.round(9 * Config.scale)
        }
        spacing: Math.round(4 * Config.scale)

        // ── Track title ──────────────────────────────────────────────────────
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
                source: titleText; anchors.fill: titleText
                shadowEnabled: true; shadowColor: "black"
                shadowBlur: 1.0; shadowOpacity: 1.0
                shadowHorizontalOffset: 0; shadowVerticalOffset: 1
            }
        }

        // ── Artist ───────────────────────────────────────────────────────────
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
                source: artistText; anchors.fill: artistText
                shadowEnabled: true; shadowColor: "black"
                shadowBlur: 1.0; shadowOpacity: 1.0
                shadowHorizontalOffset: 0; shadowVerticalOffset: 1
            }
        }

        // ── Album ────────────────────────────────────────────────────────────
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
                source: albumText; anchors.fill: albumText
                shadowEnabled: true; shadowColor: "black"
                shadowBlur: 1.0; shadowOpacity: 1.0
                shadowHorizontalOffset: 0; shadowVerticalOffset: 1
            }
        }

        // ── Playback controls (centred) ──────────────────────────────────────
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
                    anchors.centerIn: parent
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

            // Play / Pause
            Rectangle {
                id: playBtn
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
                    anchors.centerIn: parent
                    // ▶ U+25B6 sits slightly left of optical centre in most fonts;
                    // nudge it 1 scaled px right when showing play so it looks centred.
                    anchors.horizontalCenterOffset: root.isPlaying ? 0 : Math.round(1 * Config.scale)
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
                    anchors.centerIn: parent
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

        // ── Seek row: icon · slider · elapsed / total ────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(6 * Config.scale)
            opacity: root.player ? 1 : Config.bar.disabledOpacity

            // Seek icon
            IconImage {
                implicitSize: Math.round(Config.font.sizeSm * 1.1)
                source: Quickshell.iconPath("media-seek-forward-symbolic")
                // tint white so it shows over the dark overlay
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: "white"
                }
            }

            // Seek track
            Item {
                id: seekTrack
                Layout.fillWidth: true
                height: Math.round(20 * Config.scale)

                readonly property real frac: root.progress

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
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * seekTrack.frac
                    height: Math.round(3 * Config.scale)
                    radius: height / 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Config.colors.accent }
                        GradientStop { position: 1.0; color: Config.colors.accentAlt }
                    }
                    Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutQuart } }
                }

                // Thumb glow
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: seekTrack.width * seekTrack.frac - width / 2
                    width: Math.round(14 * Config.scale)
                    height: width
                    radius: width / 2
                    color: Config.colors.glowAccent
                    opacity: 0.5
                    Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutQuart } }
                }

                // Thumb
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: seekTrack.width * seekTrack.frac - width / 2
                    width: Math.round(10 * Config.scale)
                    height: width
                    radius: width / 2
                    color: "white"
                    Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutQuart } }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.SizeHorCursor

                    function applyX(mx) {
                        if (!root.player || !root.player.positionSupported || root.trackLength <= 0) return
                        const target = Math.max(0, Math.min(1, mx / seekTrack.width)) * root.trackLength
                        root.player.position = target
                        root.livePosition = target
                    }

                    onPressed:         mouse => applyX(mouse.x)
                    onPositionChanged: mouse => { if (pressed) applyX(mouse.x) }
                    onWheel:           wheel => {
                        if (!root.player || !root.player.positionSupported || root.trackLength <= 0) return
                        const target = Math.max(0, Math.min(root.trackLength, root.livePosition + wheel.angleDelta.y / 120 * 5))
                        root.player.position = target
                        root.livePosition = target
                    }
                }
            }

            // Elapsed / Total timestamp
            Text {
                text: root.formatTime(root.livePosition) + " / " + root.formatTime(root.trackLength)
                color: Qt.rgba(1, 1, 1, 0.70)
                font.family: Config.font.family
                font.pixelSize: Math.round(Config.font.sizeSm * 0.82)
            }
        }

        // ── Volume row: icon · slider ────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(6 * Config.scale)
            opacity: root.player ? 1 : Config.bar.disabledOpacity

            // Volume icon — switches with level like the bar popup does
            IconImage {
                implicitSize: Math.round(Config.font.sizeSm * 1.1)
                source: {
                    const v = root.volume
                    if (v <= 0) return Quickshell.iconPath("audio-volume-muted-symbolic")
                    if (v < 0.34) return Quickshell.iconPath("audio-volume-low-symbolic")
                    if (v < 0.67) return Quickshell.iconPath("audio-volume-medium-symbolic")
                    return Quickshell.iconPath("audio-volume-high-symbolic")
                }
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: "white"
                }
            }

            // Volume track
            Item {
                id: volTrack
                Layout.fillWidth: true
                height: Math.round(20 * Config.scale)

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
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * volTrack.frac
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
                    x: volTrack.width * volTrack.frac - width / 2
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
                    x: volTrack.width * volTrack.frac - width / 2
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
                        root.player.volume = Math.max(0, Math.min(1, mx / volTrack.width))
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
}
