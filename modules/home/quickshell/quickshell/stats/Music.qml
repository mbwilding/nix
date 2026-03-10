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
        void Mpris.players.valuesChanged;
        let playing = null;
        let first = null;
        const vals = Mpris.players.values;
        for (let i = 0; i < vals.length; i++) {
            const p = vals[i];
            if (!first)
                first = p;
            if (p.isPlaying && !playing)
                playing = p;
        }
        return playing ?? first ?? null;
    }

    readonly property string trackTitle: player ? (player.trackTitle || "Nothing playing") : "Nothing playing"
    readonly property string trackArtist: player ? (player.trackArtist || "") : ""
    readonly property string trackAlbum: player ? (player.trackAlbum || "") : ""
    readonly property string artUrl: player ? (player.trackArtUrl || "") : ""
    readonly property bool isPlaying: player?.isPlaying ?? false
    readonly property real trackLength: (player && player.lengthSupported && player.length > 0) ? player.length : 0
    readonly property real volume: player ? Math.max(0, Math.min(1, player.volume)) : 0

    property real livePosition: 0

    Timer {
        interval: 1000
        repeat: true
        running: root.player !== null && root.isPlaying
        onTriggered: if (root.player)
            root.livePosition = root.player.position
    }

    onPlayerChanged: root.livePosition = root.player ? root.player.position : 0
    Connections {
        target: root.player
        function onTrackChanged() {
            root.livePosition = root.player ? root.player.position : 0;
        }
    }

    readonly property real progress: root.trackLength > 0 ? Math.max(0, Math.min(1, root.livePosition / root.trackLength)) : 0

    function formatTime(secs) {
        const s = Math.max(0, Math.floor(secs));
        const m = Math.floor(s / 60);
        const r = s % 60;
        return m + ":" + (r < 10 ? "0" : "") + r;
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
    HoverHandler {
        id: cardHover
    }

    // ── Persistent bottom scrim + song info ───────────────────────────────────
    Item {
        id: infoStrip
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Math.round(130 * Config.scale)

        // Scrim — tall, starts dark early, fully opaque at bottom
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                    position: 0.0
                    color: "transparent"
                }
                GradientStop {
                    position: 0.30
                    color: Qt.rgba(0, 0, 0, 0.55)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(0, 0, 0, 0.92)
                }
            }
        }

        // Song info pinned to the very bottom-left
        ColumnLayout {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: Math.round(14 * Config.scale)
                rightMargin: Math.round(14 * Config.scale)
                bottomMargin: Math.round(12 * Config.scale)
            }
            spacing: Math.round(3 * Config.scale)

            Text {
                Layout.fillWidth: true
                text: root.trackTitle
                color: "white"
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeXl
                font.weight: Font.Bold
                elide: Text.ElideRight
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#cc000000"
                    shadowBlur: 0.7
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 2
                }
            }
            Text {
                Layout.fillWidth: true
                text: root.trackArtist
                color: Qt.rgba(1, 1, 1, 0.90)
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeMd
                elide: Text.ElideRight
                visible: root.trackArtist !== ""
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#cc000000"
                    shadowBlur: 0.7
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 2
                }
            }
            Text {
                Layout.fillWidth: true
                text: root.trackAlbum
                color: Qt.rgba(1, 1, 1, 0.60)
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeSm
                elide: Text.ElideRight
                visible: root.trackAlbum !== ""
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#cc000000"
                    shadowBlur: 0.7
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 2
                }
            }
        }

        // ── Time display + inline seek — bottom-right corner ─────────────────
        Item {
            id: timeArea
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: Math.round(14 * Config.scale)
            anchors.bottomMargin: Math.round(12 * Config.scale)
            width: timeHover.hovered ? Math.round(160 * Config.scale) : timeLabel.implicitWidth
            height: timeLabel.implicitHeight

            HoverHandler {
                id: timeHover
            }

            Behavior on width {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            // "00:00 / 00:00" label — fades out when slider is shown
            Text {
                id: timeLabel
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.formatTime(root.livePosition) + " / " + root.formatTime(root.trackLength)
                color: Qt.rgba(1, 1, 1, 0.55)
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeLg
                opacity: timeHover.hovered ? 0.0 : 1.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#cc000000"
                    shadowBlur: 0.7
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 2
                }
            }

            // Inline seek slider — fades in on hover
            Item {
                id: inlineSeek
                anchors.fill: parent
                opacity: timeHover.hovered ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

                // Frosted pill background
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.rgba(0, 0, 0, 0.55)
                    border.color: Qt.rgba(1, 1, 1, 0.22)
                    border.width: 1
                }

                Item {
                    id: inlineSeekTrack
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Math.round(10 * Config.scale)
                    anchors.rightMargin: Math.round(10 * Config.scale)
                    anchors.verticalCenter: parent.verticalCenter
                    height: Math.round(16 * Config.scale)
                    readonly property real frac: root.progress

                    // Rail
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: Math.round(3 * Config.scale)
                        radius: height / 2
                        color: Qt.rgba(1, 1, 1, 0.22)
                    }
                    // Fill
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * inlineSeekTrack.frac
                        height: Math.round(3 * Config.scale)
                        radius: height / 2
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop {
                                position: 0.0
                                color: Config.colors.accent
                            }
                            GradientStop {
                                position: 1.0
                                color: Config.colors.accentAlt
                            }
                        }
                        Behavior on width {
                            NumberAnimation {
                                duration: 80
                                easing.type: Easing.OutQuart
                            }
                        }
                    }
                    // Thumb
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: inlineSeekTrack.width * inlineSeekTrack.frac - width / 2
                        width: Math.round(9 * Config.scale)
                        height: width
                        radius: width / 2
                        color: "white"
                        Behavior on x {
                            NumberAnimation {
                                duration: 80
                                easing.type: Easing.OutQuart
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeHorCursor
                        function applyX(mx) {
                            if (!root.player || !root.player.positionSupported || root.trackLength <= 0)
                                return;
                            const t = Math.max(0, Math.min(1, mx / inlineSeekTrack.width)) * root.trackLength;
                            root.player.position = t;
                            root.livePosition = t;
                        }
                        onPressed: mouse => applyX(mouse.x)
                        onPositionChanged: mouse => {
                            if (pressed)
                                applyX(mouse.x);
                        }
                        onWheel: wheel => {
                            if (!root.player || !root.player.positionSupported || root.trackLength <= 0)
                                return;
                            const t = Math.max(0, Math.min(root.trackLength, root.livePosition + wheel.angleDelta.y / 120 * 5));
                            root.player.position = t;
                            root.livePosition = t;
                        }
                    }
                }
            }
        }
    }

    // ── Controls overlay — depth-push effect on hover ────────────────────────
    Item {
        id: controlsOverlay
        anchors.fill: parent

        // Art zone — used only to size the scrim correctly above the info strip.
        Item {
            id: artZone
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height - infoStrip.height
        }

        // Controls column — direct child of controlsOverlay so anchors.centerIn
        // parent resolves to controlsOverlay (full card), giving true visual centre.
        ColumnLayout {
            id: controlsColumn
            anchors.centerIn: parent
            width: parent.width - Math.round(24 * Config.scale)

            transformOrigin: Item.Center
            readonly property bool fits: implicitHeight <= artZone.height
            scale: (cardHover.hovered && fits) ? 1.0 : 0.72
            opacity: (cardHover.hovered && fits) ? 1.0 : 0.0
            Behavior on scale {
                NumberAnimation {
                    duration: 320
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.4
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            spacing: Math.round(14 * Config.scale)

            // ── Transport — frosted-glass pill: prev · play · next ────────
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: transportRow.implicitWidth + Math.round(28 * Config.scale)
                implicitHeight: transportRow.implicitHeight + Math.round(16 * Config.scale)
                opacity: root.player ? 1 : Config.bar.disabledOpacity

                // Frosted pill background
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.rgba(0, 0, 0, 0.55)
                    border.color: Qt.rgba(1, 1, 1, 0.22)
                    border.width: 1
                }

                RowLayout {
                    id: transportRow
                    anchors.centerIn: parent
                    spacing: Math.round(6 * Config.scale)

                    // Prev
                    Item {
                        implicitWidth: Math.round(34 * Config.scale)
                        implicitHeight: implicitWidth
                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: prevMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.28) : "transparent"
                            Behavior on color {
                                ColorAnimation {
                                    duration: 80
                                }
                            }
                        }
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
                            onClicked: if (root.player)
                                root.player.previous()
                        }
                    }

                    // Play / Pause — larger accent circle
                    Item {
                        implicitWidth: Math.round(48 * Config.scale)
                        implicitHeight: implicitWidth
                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop {
                                    position: 0.0
                                    color: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, playMouse.containsMouse ? 1.0 : 0.95)
                                }
                                GradientStop {
                                    position: 1.0
                                    color: Qt.rgba(Config.colors.accentAlt.r, Config.colors.accentAlt.g, Config.colors.accentAlt.b, playMouse.containsMouse ? 1.0 : 0.85)
                                }
                            }
                            border.color: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.70)
                            border.width: 1
                        }
                        Text {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: root.isPlaying ? 0 : Math.round(1 * Config.scale)
                            text: root.isPlaying ? "\u23f8" : "\u25b6"
                            color: "white"
                            font.pixelSize: Config.font.sizeLg
                            font.weight: Font.SemiBold
                        }
                        MouseArea {
                            id: playMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.player)
                                root.player.togglePlaying()
                        }
                    }

                    // Next
                    Item {
                        implicitWidth: Math.round(34 * Config.scale)
                        implicitHeight: implicitWidth
                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: nextMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.28) : "transparent"
                            Behavior on color {
                                ColorAnimation {
                                    duration: 80
                                }
                            }
                        }
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
                            onClicked: if (root.player)
                                root.player.next()
                        }
                    }
                }
            }
        }
    }

    // ── Volume display + inline slider — top-left corner ─────────────────────
    Item {
        id: volArea
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: Math.round(14 * Config.scale)
        anchors.topMargin: Math.round(12 * Config.scale)
        width: volHover.hovered ? Math.round(160 * Config.scale) : volIconLabel.implicitWidth + Math.round(4 * Config.scale)
        height: Math.max(volIconLabel.implicitHeight, Math.round(20 * Config.scale))

        HoverHandler {
            id: volHover
        }

        Behavior on width {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        // Volume icon — fades out when slider is shown
        IconImage {
            id: volIconLabel
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: Config.font.sizeLg
            source: {
                const v = root.volume;
                if (!root.player || v <= 0)
                    return Quickshell.iconPath("audio-volume-muted-symbolic");
                if (v <= 0.33)
                    return Quickshell.iconPath("audio-volume-low-symbolic");
                if (v <= 0.66)
                    return Quickshell.iconPath("audio-volume-medium-symbolic");
                return Quickshell.iconPath("audio-volume-high-symbolic");
            }
            opacity: volHover.hovered ? 0.0 : 1.0
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }

        // Inline volume slider — fades in on hover
        Item {
            id: inlineVol
            anchors.fill: parent
            opacity: volHover.hovered ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

            // Frosted pill background
            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Qt.rgba(0, 0, 0, 0.55)
                border.color: Qt.rgba(1, 1, 1, 0.22)
                border.width: 1
            }

            Item {
                id: inlineVolTrack
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Math.round(10 * Config.scale)
                anchors.rightMargin: Math.round(10 * Config.scale)
                anchors.verticalCenter: parent.verticalCenter
                height: Math.round(16 * Config.scale)
                readonly property real frac: root.volume

                // Rail
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: Math.round(3 * Config.scale)
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.22)
                }
                // Fill
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * inlineVolTrack.frac
                    height: Math.round(3 * Config.scale)
                    radius: height / 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0.0
                            color: Config.colors.accent
                        }
                        GradientStop {
                            position: 1.0
                            color: Config.colors.accentAlt
                        }
                    }
                    Behavior on width {
                        NumberAnimation {
                            duration: 60
                            easing.type: Easing.OutQuart
                        }
                    }
                }
                // Thumb
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: inlineVolTrack.width * inlineVolTrack.frac - width / 2
                    width: Math.round(9 * Config.scale)
                    height: width
                    radius: width / 2
                    color: "white"
                    Behavior on x {
                        NumberAnimation {
                            duration: 60
                            easing.type: Easing.OutQuart
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.SizeHorCursor
                    function applyX(mx) {
                        if (!root.player || !root.player.volumeSupported)
                            return;
                        root.player.volume = Math.max(0, Math.min(1, mx / inlineVolTrack.width));
                    }
                    onPressed: mouse => applyX(mouse.x)
                    onPositionChanged: mouse => {
                        if (pressed)
                            applyX(mouse.x);
                    }
                    onWheel: wheel => {
                        if (!root.player || !root.player.volumeSupported)
                            return;
                        root.player.volume = Math.max(0, Math.min(1, root.player.volume + wheel.angleDelta.y / 1200));
                    }
                }
            }
        }
    }
}
