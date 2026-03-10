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

    // Live position — polled every second while playing.
    property real livePosition: 0

    Timer {
        id: positionTimer
        interval: 1000
        repeat: true
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

    // ── Album art background ─────────────────────────────────────────────────
    Image {
        id: artImage
        anchors.fill: parent
        source: root.artUrl
        fillMode: Image.PreserveAspectCrop
        visible: root.artUrl !== "" && status === Image.Ready
        cache: false
    }

    // Fallback when no art
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

    // ── Gradient scrim — covers the full card height so text always has contrast
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0;  color: "transparent" }
            GradientStop { position: 0.30; color: Qt.rgba(0, 0, 0, 0.25) }
            GradientStop { position: 1.0;  color: Qt.rgba(0, 0, 0, 0.88) }
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

        // ── Track info block with dark pill background for readability ────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: textCol.implicitHeight + Math.round(8 * Config.scale)
            radius: Math.round(6 * Config.scale)
            color: Qt.rgba(0, 0, 0, 0.45)

            ColumnLayout {
                id: textCol
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: Math.round(7 * Config.scale)
                    rightMargin: Math.round(7 * Config.scale)
                }
                spacing: Math.round(2 * Config.scale)

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
                    color: Qt.rgba(1, 1, 1, 0.80)
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeSm
                    elide: Text.ElideRight
                    visible: root.trackArtist !== ""
                }

                Text {
                    Layout.fillWidth: true
                    text: root.trackAlbum
                    color: Qt.rgba(1, 1, 1, 0.58)
                    font.family: Config.font.family
                    font.pixelSize: Math.round(Config.font.sizeSm * 0.88)
                    elide: Text.ElideRight
                    visible: root.trackAlbum !== ""
                }
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
                    // ▶ is optically left-heavy; nudge 1px right when in play state
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

            IconImage {
                implicitSize: Math.round(Config.font.sizeSm * 1.1)
                source: Quickshell.iconPath("media-seek-forward-symbolic")
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: "white"
                }
            }

            Item {
                id: seekTrack
                Layout.fillWidth: true
                height: Math.round(20 * Config.scale)

                readonly property real frac: root.progress

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: Math.round(3 * Config.scale)
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.25)
                }
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
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: seekTrack.width * seekTrack.frac - width / 2
                    width: Math.round(14 * Config.scale)
                    height: width; radius: width / 2
                    color: Config.colors.glowAccent; opacity: 0.5
                    Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutQuart } }
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: seekTrack.width * seekTrack.frac - width / 2
                    width: Math.round(10 * Config.scale)
                    height: width; radius: width / 2; color: "white"
                    Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutQuart } }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.SizeHorCursor
                    function applyX(mx) {
                        if (!root.player || !root.player.positionSupported || root.trackLength <= 0) return
                        const t = Math.max(0, Math.min(1, mx / seekTrack.width)) * root.trackLength
                        root.player.position = t
                        root.livePosition = t
                    }
                    onPressed:         mouse => applyX(mouse.x)
                    onPositionChanged: mouse => { if (pressed) applyX(mouse.x) }
                    onWheel: wheel => {
                        if (!root.player || !root.player.positionSupported || root.trackLength <= 0) return
                        const t = Math.max(0, Math.min(root.trackLength, root.livePosition + wheel.angleDelta.y / 120 * 5))
                        root.player.position = t
                        root.livePosition = t
                    }
                }
            }

            Text {
                text: root.formatTime(root.livePosition) + " / " + root.formatTime(root.trackLength)
                color: Qt.rgba(1, 1, 1, 0.75)
                font.family: Config.font.family
                font.pixelSize: Math.round(Config.font.sizeSm * 0.82)
            }
        }

        // ── Volume row: icon · slider ────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(6 * Config.scale)
            opacity: root.player ? 1 : Config.bar.disabledOpacity

            IconImage {
                implicitSize: Math.round(Config.font.sizeSm * 1.1)
                source: {
                    const v = root.volume
                    if (v <= 0)    return Quickshell.iconPath("audio-volume-muted-symbolic")
                    if (v < 0.34)  return Quickshell.iconPath("audio-volume-low-symbolic")
                    if (v < 0.67)  return Quickshell.iconPath("audio-volume-medium-symbolic")
                    return Quickshell.iconPath("audio-volume-high-symbolic")
                }
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: "white"
                }
            }

            Item {
                id: volTrack
                Layout.fillWidth: true
                height: Math.round(20 * Config.scale)

                readonly property real frac: root.volume

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: Math.round(3 * Config.scale)
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.25)
                }
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
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: volTrack.width * volTrack.frac - width / 2
                    width: Math.round(14 * Config.scale)
                    height: width; radius: width / 2
                    color: Config.colors.glowAccent; opacity: 0.5
                    Behavior on x { NumberAnimation { duration: 60; easing.type: Easing.OutQuart } }
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: volTrack.width * volTrack.frac - width / 2
                    width: Math.round(10 * Config.scale)
                    height: width; radius: width / 2; color: "white"
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
                    onWheel: wheel => {
                        if (!root.player || !root.player.volumeSupported) return
                        root.player.volume = Math.max(0, Math.min(1, root.player.volume + wheel.angleDelta.y / 1200))
                    }
                }
            }
        }
    }

    // ── Border overlay — drawn last so it sits on top of the art and matches
    //    the other cards. The parent Rectangle uses layer.enabled for clipping
    //    but that hides its own border, so we redraw it here.
    Rectangle {
        anchors.fill: parent
        radius: Math.round(10 * Config.scale)
        color: "transparent"
        border.color: Config.colors.border
        border.width: 1
    }
}
