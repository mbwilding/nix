pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris

import ".."
import "../components"

// Music/media section — square album art on top, details below.
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

    // ── Layout: art (square, top) + detail panel (below) ─────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Square album art ──────────────────────────────────────────────────
        Item {
            // 1:1 square, but never taller than ~55% of the drawer content area
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(width, Math.round(root.height * 0.52))

            // Art image — cropped to fill the square
            Image {
                id: artImage
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: root.artUrl !== "" && status === Image.Ready
                cache: false
            }

            // Fallback — no art
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(
                    Config.colors.surface.r,
                    Config.colors.surface.g,
                    Config.colors.surface.b, 1)
                visible: root.artUrl === "" || artImage.status !== Image.Ready

                Text {
                    anchors.centerIn: parent
                    text: "\u266b"
                    color: Config.colors.textMuted
                    font.pixelSize: Math.round(40 * Config.scale)
                }
            }

            // Subtle bottom fade to blend into the panel below
            Rectangle {
                anchors.left:   parent.left
                anchors.right:  parent.right
                anchors.bottom: parent.bottom
                height: Math.round(32 * Config.scale)
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Config.colors.surface }
                }
            }
        }

        // ── Detail panel ──────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Math.round(6 * Config.scale)

            // Padding applied via inner layout margins
            Item { Layout.preferredHeight: Math.round(2 * Config.scale) }

            // Track info
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin:  Math.round(12 * Config.scale)
                Layout.rightMargin: Math.round(12 * Config.scale)
                spacing: Math.round(2 * Config.scale)

                Text {
                    Layout.fillWidth: true
                    text: root.trackTitle
                    color: Config.colors.textPrimary
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeMd
                    font.weight: Font.SemiBold
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
                Text {
                    Layout.fillWidth: true
                    text: root.trackAlbum
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeSm
                    elide: Text.ElideRight
                    visible: root.trackAlbum !== ""
                }
            }

            // Playback controls
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin:  Math.round(12 * Config.scale)
                Layout.rightMargin: Math.round(12 * Config.scale)
                Layout.alignment: Qt.AlignHCenter
                spacing: Math.round(16 * Config.scale)

                // Previous
                Rectangle {
                    implicitWidth:  Math.round(28 * Config.scale)
                    implicitHeight: Math.round(28 * Config.scale)
                    radius: implicitWidth / 2
                    color: prevMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : "transparent"
                    opacity: root.player ? 1 : Config.bar.disabledOpacity
                    Behavior on color { ColorAnimation { duration: 80 } }
                    Text {
                        anchors.centerIn: parent
                        text: "\u23ee"
                        color: Config.colors.textSecondary
                        font.pixelSize: Config.font.sizeSm
                    }
                    MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.player) root.player.previous() }
                }

                // Play/Pause
                Rectangle {
                    implicitWidth:  Math.round(36 * Config.scale)
                    implicitHeight: Math.round(36 * Config.scale)
                    radius: implicitWidth / 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.rgba(Config.colors.accent.r,    Config.colors.accent.g,    Config.colors.accent.b,    playMouse.containsMouse ? 0.65 : 0.45) }
                        GradientStop { position: 1.0; color: Qt.rgba(Config.colors.accentAlt.r, Config.colors.accentAlt.g, Config.colors.accentAlt.b, playMouse.containsMouse ? 0.55 : 0.35) }
                    }
                    border.color: Config.colors.accent
                    border.width: 1
                    opacity: root.player ? 1 : Config.bar.disabledOpacity
                    Text {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: root.isPlaying ? 0 : Math.round(1 * Config.scale)
                        text: root.isPlaying ? "\u23f8" : "\u25b6"
                        color: "white"
                        font.pixelSize: Config.font.sizeSm
                        font.weight: Font.Medium
                    }
                    MouseArea { id: playMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.player) root.player.togglePlaying() }
                }

                // Next
                Rectangle {
                    implicitWidth:  Math.round(28 * Config.scale)
                    implicitHeight: Math.round(28 * Config.scale)
                    radius: implicitWidth / 2
                    color: nextMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : "transparent"
                    opacity: root.player ? 1 : Config.bar.disabledOpacity
                    Behavior on color { ColorAnimation { duration: 80 } }
                    Text {
                        anchors.centerIn: parent
                        text: "\u23ed"
                        color: Config.colors.textSecondary
                        font.pixelSize: Config.font.sizeSm
                    }
                    MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.player) root.player.next() }
                }
            }

            // Seek bar
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin:  Math.round(12 * Config.scale)
                Layout.rightMargin: Math.round(12 * Config.scale)
                spacing: Math.round(6 * Config.scale)
                opacity: root.player ? 1 : Config.bar.disabledOpacity

                IconImage {
                    implicitSize: Math.round(Config.font.sizeSm * 1.1)
                    source: Quickshell.iconPath("media-seek-forward-symbolic")
                    layer.enabled: true
                    layer.effect: MultiEffect { colorization: 1.0; colorizationColor: Config.colors.textMuted }
                }

                Item {
                    id: seekTrack
                    Layout.fillWidth: true
                    height: Math.round(20 * Config.scale)
                    readonly property real frac: root.progress

                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: Math.round(3 * Config.scale); radius: height/2; color: Config.colors.sliderRail }
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
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeXxs
                }
            }

            // Volume bar
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin:  Math.round(12 * Config.scale)
                Layout.rightMargin: Math.round(12 * Config.scale)
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
                    layer.effect: MultiEffect { colorization: 1.0; colorizationColor: Config.colors.textMuted }
                }

                Item {
                    id: volTrack
                    Layout.fillWidth: true
                    height: Math.round(20 * Config.scale)
                    readonly property real frac: root.volume

                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: Math.round(3 * Config.scale); radius: height/2; color: Config.colors.sliderRail }
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

            Item { Layout.fillHeight: true }
        }
    }
}
