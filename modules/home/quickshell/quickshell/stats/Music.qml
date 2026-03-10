pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris

import ".."
import "../components"

// Music/media section — full-bleed art with persistent info overlay at bottom.
// Controls slide up into the centre on hover.
Item {
    id: root

    // ── Player selection ──────────────────────────────────────────────────────
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

    readonly property string trackTitle:  player ? (player.trackTitle  || "Nothing playing") : "Nothing playing"
    readonly property string trackArtist: player ? (player.trackArtist || "")                : ""
    readonly property string trackAlbum:  player ? (player.trackAlbum  || "")                : ""
    readonly property string artUrl:      player ? (player.trackArtUrl || "")                : ""
    readonly property bool   isPlaying:   player?.isPlaying ?? false
    readonly property real   trackLength: (player && player.lengthSupported && player.length > 0) ? player.length : 0
    readonly property real   volume:      player ? Math.max(0, Math.min(1, player.volume)) : 0

    property real livePosition: 0

    Timer {
        interval: 1000; repeat: true
        running: root.player !== null && root.isPlaying
        onTriggered: if (root.player) root.livePosition = root.player.position
    }

    onPlayerChanged: root.livePosition = root.player ? root.player.position : 0
    Connections {
        target: root.player
        function onTrackChanged() { root.livePosition = root.player ? root.player.position : 0 }
    }

    readonly property real progress: root.trackLength > 0
        ? Math.max(0, Math.min(1, root.livePosition / root.trackLength)) : 0

    function formatTime(secs) {
        const s = Math.max(0, Math.floor(secs))
        const m = Math.floor(s / 60)
        const r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }

    // ── Art fills the entire content area ────────────────────────────────────
    Image {
        id: artImage
        anchors.fill: parent
        source: root.artUrl
        fillMode: Image.PreserveAspectCrop
        visible: root.artUrl !== "" && status === Image.Ready
        cache: false
    }

    // Fallback
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Config.colors.surface.r, Config.colors.surface.g, Config.colors.surface.b, 1)
        visible: root.artUrl === "" || artImage.status !== Image.Ready
        Text {
            anchors.centerIn: parent
            text: "\u266b"
            color: Config.colors.textMuted
            font.pixelSize: Math.round(48 * Config.scale)
        }
    }

    // Hover detector over entire card
    HoverHandler { id: cardHover }

    // ── Persistent bottom scrim + song info ───────────────────────────────────
    Item {
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height: Math.round(90 * Config.scale)

        // Scrim
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.80) }
            }
        }

        // Song info pinned to the very bottom
        ColumnLayout {
            anchors {
                left:         parent.left
                right:        parent.right
                bottom:       parent.bottom
                leftMargin:   Math.round(12 * Config.scale)
                rightMargin:  Math.round(12 * Config.scale)
                bottomMargin: Math.round(10 * Config.scale)
            }
            spacing: Math.round(1 * Config.scale)

            Text {
                Layout.fillWidth: true
                text: root.trackTitle
                color: "white"
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeMd
                font.weight: Font.SemiBold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: root.trackArtist
                color: Qt.rgba(1, 1, 1, 0.75)
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeSm
                elide: Text.ElideRight
                visible: root.trackArtist !== ""
            }
            Text {
                Layout.fillWidth: true
                text: root.trackAlbum
                color: Qt.rgba(1, 1, 1, 0.50)
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeSm
                elide: Text.ElideRight
                visible: root.trackAlbum !== ""
            }
        }
    }

    // ── Controls overlay — depth-push effect on hover ────────────────────────
    Item {
        id: controlsOverlay
        anchors.fill: parent

        // Scrim fades in alongside controls
        Rectangle {
            anchors.fill: parent
            opacity: cardHover.hovered ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0;  color: "transparent" }
                GradientStop { position: 0.25; color: Qt.rgba(0, 0, 0, 0.40) }
                GradientStop { position: 0.75; color: Qt.rgba(0, 0, 0, 0.40) }
                GradientStop { position: 1.0;  color: "transparent" }
            }
        }

        // Controls column — scales up from 0.72 with OutBack overshoot (depth push).
        ColumnLayout {
            id: controlsColumn
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter:   parent.verticalCenter
            anchors.verticalCenterOffset: -Math.round(30 * Config.scale)

            transformOrigin: Item.Center
            scale:   cardHover.hovered ? 1.0 : 0.72
            opacity: cardHover.hovered ? 1.0 : 0.0
            Behavior on scale   { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            spacing: Math.round(10 * Config.scale)

            // Prev / Play / Next
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Math.round(18 * Config.scale)

                Rectangle {
                    implicitWidth: Math.round(30 * Config.scale); implicitHeight: implicitWidth
                    radius: implicitWidth / 2
                    color: prevMouse.containsMouse ? Qt.rgba(1,1,1,0.22) : Qt.rgba(1,1,1,0.10)
                    opacity: root.player ? 1 : Config.bar.disabledOpacity
                    Behavior on color { ColorAnimation { duration: 80 } }
                    Text { anchors.centerIn: parent; text: "\u23ee"; color: "white"; font.pixelSize: Config.font.sizeSm }
                    MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.player) root.player.previous() }
                }

                Rectangle {
                    implicitWidth: Math.round(42 * Config.scale); implicitHeight: implicitWidth
                    radius: implicitWidth / 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.rgba(Config.colors.accent.r,    Config.colors.accent.g,    Config.colors.accent.b,    playMouse.containsMouse ? 0.85 : 0.65) }
                        GradientStop { position: 1.0; color: Qt.rgba(Config.colors.accentAlt.r, Config.colors.accentAlt.g, Config.colors.accentAlt.b, playMouse.containsMouse ? 0.75 : 0.55) }
                    }
                    border.color: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.85)
                    border.width: 1
                    opacity: root.player ? 1 : Config.bar.disabledOpacity
                    Text {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: root.isPlaying ? 0 : Math.round(1 * Config.scale)
                        text: root.isPlaying ? "\u23f8" : "\u25b6"
                        color: "white"; font.pixelSize: Config.font.sizeLg; font.weight: Font.Medium
                    }
                    MouseArea { id: playMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.player) root.player.togglePlaying() }
                }

                Rectangle {
                    implicitWidth: Math.round(30 * Config.scale); implicitHeight: implicitWidth
                    radius: implicitWidth / 2
                    color: nextMouse.containsMouse ? Qt.rgba(1,1,1,0.22) : Qt.rgba(1,1,1,0.10)
                    opacity: root.player ? 1 : Config.bar.disabledOpacity
                    Behavior on color { ColorAnimation { duration: 80 } }
                    Text { anchors.centerIn: parent; text: "\u23ed"; color: "white"; font.pixelSize: Config.font.sizeSm }
                    MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.player) root.player.next() }
                }
            }

            // Seek bar
            RowLayout {
                spacing: Math.round(6 * Config.scale)
                opacity: root.player ? 1 : Config.bar.disabledOpacity

                Item {
                    id: seekTrack
                    width: Math.round(220 * Config.scale)
                    height: Math.round(20 * Config.scale)
                    readonly property real frac: root.progress

                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: Math.round(3 * Config.scale); radius: height/2; color: Qt.rgba(1,1,1,0.28) }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * seekTrack.frac; height: Math.round(3 * Config.scale); radius: height/2
                        gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0.0; color: Config.colors.accent } GradientStop { position: 1.0; color: Config.colors.accentAlt } }
                        Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutQuart } }
                    }
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; x: seekTrack.width * seekTrack.frac - width/2; width: Math.round(14 * Config.scale); height: width; radius: width/2; color: Config.colors.accentGlow; opacity: 0.5; Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutQuart } } }
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; x: seekTrack.width * seekTrack.frac - width/2; width: Math.round(10 * Config.scale); height: width; radius: width/2; color: "white"; Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutQuart } } }

                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.SizeHorCursor
                        function applyX(mx) {
                            if (!root.player || !root.player.positionSupported || root.trackLength <= 0) return
                            const t = Math.max(0, Math.min(1, mx / seekTrack.width)) * root.trackLength
                            root.player.position = t; root.livePosition = t
                        }
                        onPressed: mouse => applyX(mouse.x)
                        onPositionChanged: mouse => { if (pressed) applyX(mouse.x) }
                        onWheel: wheel => {
                            if (!root.player || !root.player.positionSupported || root.trackLength <= 0) return
                            const t = Math.max(0, Math.min(root.trackLength, root.livePosition + wheel.angleDelta.y / 120 * 5))
                            root.player.position = t; root.livePosition = t
                        }
                    }
                }

                Text {
                    text: root.formatTime(root.livePosition) + " / " + root.formatTime(root.trackLength)
                    color: Qt.rgba(1,1,1,0.70)
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeXxs
                }
            }

            // Volume bar
            RowLayout {
                spacing: Math.round(6 * Config.scale)
                opacity: root.player ? 1 : Config.bar.disabledOpacity

                IconImage {
                    implicitSize: Math.round(Config.font.sizeSm * 1.1)
                    source: {
                        const v = root.volume
                        if (v <= 0)   return Quickshell.iconPath("audio-volume-muted-symbolic")
                        if (v < 0.34) return Quickshell.iconPath("audio-volume-low-symbolic")
                        if (v < 0.67) return Quickshell.iconPath("audio-volume-medium-symbolic")
                        return Quickshell.iconPath("audio-volume-high-symbolic")
                    }
                    layer.enabled: true
                    layer.effect: MultiEffect { colorization: 1.0; colorizationColor: "white" }
                }

                Item {
                    id: volTrack
                    width: Math.round(206 * Config.scale)
                    height: Math.round(20 * Config.scale)
                    readonly property real frac: root.volume

                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: Math.round(3 * Config.scale); radius: height/2; color: Qt.rgba(1,1,1,0.28) }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * volTrack.frac; height: Math.round(3 * Config.scale); radius: height/2
                        gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0.0; color: Config.colors.accent } GradientStop { position: 1.0; color: Config.colors.accentAlt } }
                        Behavior on width { NumberAnimation { duration: 60; easing.type: Easing.OutQuart } }
                    }
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; x: volTrack.width * volTrack.frac - width/2; width: Math.round(14 * Config.scale); height: width; radius: width/2; color: Config.colors.accentGlow; opacity: 0.5; Behavior on x { NumberAnimation { duration: 60; easing.type: Easing.OutQuart } } }
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; x: volTrack.width * volTrack.frac - width/2; width: Math.round(10 * Config.scale); height: width; radius: width/2; color: "white"; Behavior on x { NumberAnimation { duration: 60; easing.type: Easing.OutQuart } } }

                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.SizeHorCursor
                        function applyX(mx) {
                            if (!root.player || !root.player.volumeSupported) return
                            root.player.volume = Math.max(0, Math.min(1, mx / volTrack.width))
                        }
                        onPressed: mouse => applyX(mouse.x)
                        onPositionChanged: mouse => { if (pressed) applyX(mouse.x) }
                        onWheel: wheel => {
                            if (!root.player || !root.player.volumeSupported) return
                            root.player.volume = Math.max(0, Math.min(1, root.player.volume + wheel.angleDelta.y / 1200))
                        }
                    }
                }
            }
        }
    }
}
