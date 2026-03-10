pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris

import ".."
import "../components"

// Music/media section — full-bleed art with persistent info overlay at bottom.
// Controls slide up into the centre on hover.
Item {
    id: root

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: roundMask
    }

    // Mask shape — bottom corners rounded, top corners square.
    // Two overlapping rectangles: a full-width plain rect covers the top half
    // (squaring off the rounded top corners of the rounded rect beneath it).
    Item {
        id: roundMask
        width: root.width
        height: root.height
        visible: false

        readonly property real r: Math.round(Config.stats.radius * Config.scale)

        // Rounded rect — gives us the bottom two rounded corners
        Rectangle {
            width: parent.width
            height: parent.height
            radius: roundMask.r
            color: "white"
        }
        // Plain rect over the top — kills the top two rounded corners
        Rectangle {
            width: parent.width
            height: roundMask.r
            color: "white"
        }
    }

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

    readonly property string trackTitle: player ? (player.trackTitle || "") : ""
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

    // Fallback — dark background with animated orbs when nothing is playing
    Rectangle {
        id: fallbackBg
        anchors.fill: parent
        color: "#0d0d18"
        // Fade out when real art is available
        opacity: (root.artUrl === "" || artImage.status !== Image.Ready) ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation { duration: 350; easing.type: Easing.InOutCubic }
        }

        Canvas {
            id: idleOrbCanvas
            anchors.fill: parent

            // Spring in when the fallback becomes visible
            opacity: fallbackBg.opacity
            scale: fallbackBg.opacity > 0.01 ? 1.0 : 1.08
            transformOrigin: Item.Center
            Behavior on scale {
                NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
            }

            // Only run the frame loop when actually visible
            readonly property bool active: fallbackBg.visible

            property var orbPos: []
            property var orbVel: []

            readonly property var orbColors: [
                ["rgba(192, 170, 255, 0.30)", "rgba(192, 170, 255, 0.00)"],
                ["rgba(255, 159, 243, 0.25)", "rgba(255, 159, 243, 0.00)"],
                ["rgba(137, 220, 235, 0.22)", "rgba(137, 220, 235, 0.00)"],
                ["rgba(166, 227, 161, 0.20)", "rgba(166, 227, 161, 0.00)"],
                ["rgba(243, 139, 168, 0.22)", "rgba(243, 139, 168, 0.00)"],
            ]
            readonly property var orbRadii: [0.60, 0.55, 0.50, 0.58, 0.52]

            Component.onCompleted: {
                const count = Config.lockscreen.orbCount;
                let pos = [], vel = [];
                for (let i = 0; i < count; i++) {
                    pos.push({ x: Math.random(), y: Math.random() });
                    const speed = 0.018 + Math.random() * 0.012;
                    const angle = Math.random() * Math.PI * 2;
                    vel.push({ vx: Math.cos(angle) * speed, vy: Math.sin(angle) * speed });
                }
                orbPos = pos;
                orbVel = vel;
            }

            FrameAnimation {
                running: idleOrbCanvas.active
                onTriggered: {
                    const dt = Math.min(frameTime, 0.05);
                    const count = idleOrbCanvas.orbPos.length;
                    if (count === 0) return;
                    let pos = idleOrbCanvas.orbPos.map(p => ({ x: p.x, y: p.y }));
                    let vel = idleOrbCanvas.orbVel.map(v => ({ vx: v.vx, vy: v.vy }));
                    for (let i = 0; i < count; i++) {
                        pos[i].x += vel[i].vx * dt;
                        pos[i].y += vel[i].vy * dt;
                        if (pos[i].x < 0) { pos[i].x = 0; vel[i].vx = Math.abs(vel[i].vx); }
                        else if (pos[i].x > 1) { pos[i].x = 1; vel[i].vx = -Math.abs(vel[i].vx); }
                        if (pos[i].y < 0) { pos[i].y = 0; vel[i].vy = Math.abs(vel[i].vy); }
                        else if (pos[i].y > 1) { pos[i].y = 1; vel[i].vy = -Math.abs(vel[i].vy); }
                    }
                    idleOrbCanvas.orbPos = pos;
                    idleOrbCanvas.orbVel = vel;
                }
            }

            onOrbPosChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                const w = width, h = height;
                ctx.clearRect(0, 0, w, h);
                ctx.fillStyle = "#0d0d18";
                ctx.fillRect(0, 0, w, h);
                const count = orbPos.length;
                for (let i = 0; i < count; i++) {
                    const p = orbPos[i];
                    const colIdx = i % orbColors.length;
                    const radFrac = orbRadii[i % orbRadii.length];
                    const r = Math.min(w, h) * radFrac;
                    const cx = p.x * w;
                    const cy = p.y * h;
                    const g = ctx.createRadialGradient(cx, cy, 0, cx, cy, r);
                    g.addColorStop(0, orbColors[colIdx][0]);
                    g.addColorStop(1, orbColors[colIdx][1]);
                    ctx.fillStyle = g;
                    ctx.fillRect(0, 0, w, h);
                }
            }
        }

        // Centered idle label — music note + text, fades/scales out when a player appears
        Column {
            anchors.centerIn: parent
            spacing: Math.round(8 * Config.scale)
            opacity: root.player === null ? 1.0 : 0.0
            scale: root.player === null ? 1.0 : 0.85
            transformOrigin: Item.Center
            Behavior on opacity {
                NumberAnimation { duration: 280; easing.type: Easing.InOutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
            }

            Text {
                id: idleNote
                anchors.horizontalCenter: parent.horizontalCenter
                text: "\u266b"
                color: Qt.rgba(Config.colors.textMuted.r, Config.colors.textMuted.g, Config.colors.textMuted.b, 0.55)
                font.family: Config.font.family
                font.pixelSize: Math.round(40 * Config.scale)
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Nothing playing"
                color: Qt.rgba(Config.colors.textMuted.r, Config.colors.textMuted.g, Config.colors.textMuted.b, 0.60)
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeMd
            }
        }
    }

    // Hover detector over entire card
    HoverHandler {
        id: cardHover
    }

    // ── Persistent bottom song info ───────────────────────────────────────────
    Item {
        id: infoStrip
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Math.round(130 * Config.scale)
        opacity: root.player !== null ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.InOutCubic }
        }

        // Song info pill — bottom-left, shrink-wraps content
        Item {
            id: infoPill
            anchors {
                left: parent.left
                bottom: parent.bottom
                leftMargin: Math.round(14 * Config.scale)
                bottomMargin: Math.round(12 * Config.scale)
            }

            // Pill sizes to inner content; animates smoothly on track change
            width: infoPillBg.implicitWidth
            height: infoPillBg.implicitHeight
            Behavior on width {
                NumberAnimation { duration: 380; easing.type: Easing.InOutCubic }
            }
            Behavior on height {
                NumberAnimation { duration: 320; easing.type: Easing.InOutCubic }
            }

            Rectangle {
                id: infoPillBg
                anchors.fill: parent
                implicitWidth: infoColInner.implicitWidth + Math.round(20 * Config.scale)
                implicitHeight: infoColInner.implicitHeight + Math.round(12 * Config.scale)
                radius: Math.round(10 * Config.scale)
                color: Qt.rgba(0.05, 0.04, 0.12, 0.72)
                border.color: Qt.rgba(1, 1, 1, 0.10)
                border.width: 1

                // Subtle scale pulse on track change
                property string watchKey: root.trackTitle + root.trackArtist
                onWatchKeyChanged: pulseAnim.restart()
                SequentialAnimation {
                    id: pulseAnim
                    NumberAnimation { target: infoPillBg; property: "scale"; to: 1.03; duration: 120; easing.type: Easing.OutCubic }
                    NumberAnimation { target: infoPillBg; property: "scale"; to: 1.0;  duration: 200; easing.type: Easing.OutElastic; easing.overshoot: 1.5 }
                }

                ColumnLayout {
                    id: infoColInner
                    anchors {
                        left: parent.left
                        top: parent.top
                        leftMargin: Math.round(10 * Config.scale)
                        rightMargin: Math.round(10 * Config.scale)
                        topMargin: Math.round(6 * Config.scale)
                    }
                    // Width drives pill width — max out at card width minus margins
                    width: Math.min(implicitWidth, root.width - Math.round(28 * Config.scale))
                    spacing: Math.round(3 * Config.scale)

                    Text {
                        id: titleText
                        Layout.fillWidth: true
                        text: root.trackTitle
                        color: "white"
                        font.family: Config.font.family
                        font.pixelSize: Config.font.sizeXl
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                        // Cross-fade on track change
                        Behavior on text {
                            SequentialAnimation {
                                NumberAnimation { target: titleText; property: "opacity"; to: 0; duration: 100; easing.type: Easing.InCubic }
                                PropertyAction  { target: titleText; property: "text" }
                                NumberAnimation { target: titleText; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
                            }
                        }
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: "#e6000000"
                            shadowBlur: 1.0
                            shadowHorizontalOffset: 0
                            shadowVerticalOffset: 1
                            shadowScale: 1.04
                        }
                    }
                    Text {
                        id: artistText
                        Layout.fillWidth: true
                        text: root.trackArtist
                        color: Qt.rgba(1, 1, 1, 0.90)
                        font.family: Config.font.family
                        font.pixelSize: Config.font.sizeMd
                        elide: Text.ElideRight
                        visible: root.trackArtist !== ""
                        Behavior on text {
                            SequentialAnimation {
                                NumberAnimation { target: artistText; property: "opacity"; to: 0; duration: 100; easing.type: Easing.InCubic }
                                PropertyAction  { target: artistText; property: "text" }
                                NumberAnimation { target: artistText; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
                            }
                        }
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: "#e6000000"
                            shadowBlur: 1.0
                            shadowHorizontalOffset: 0
                            shadowVerticalOffset: 1
                            shadowScale: 1.04
                        }
                    }
                    Text {
                        id: albumText
                        Layout.fillWidth: true
                        text: root.trackAlbum
                        color: Qt.rgba(1, 1, 1, 0.60)
                        font.family: Config.font.family
                        font.pixelSize: Config.font.sizeSm
                        elide: Text.ElideRight
                        visible: root.trackAlbum !== ""
                        Behavior on text {
                            SequentialAnimation {
                                NumberAnimation { target: albumText; property: "opacity"; to: 0; duration: 100; easing.type: Easing.InCubic }
                                PropertyAction  { target: albumText; property: "text" }
                                NumberAnimation { target: albumText; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
                            }
                        }
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: "#e6000000"
                            shadowBlur: 1.0
                            shadowHorizontalOffset: 0
                            shadowVerticalOffset: 1
                            shadowScale: 1.04
                        }
                    }
                }
            }
        }
    }

    // ── Time display + inline seek — bottom-right corner ─────────────────────
    Item {
        id: timeArea
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Math.round(14 * Config.scale)
        anchors.bottomMargin: Math.round(8 * Config.scale)
        readonly property real pillPad: Math.round(12 * Config.scale)
        width: timeHover.hovered ? Math.round(200 * Config.scale) : timeLabelCollapsed.implicitWidth + pillPad * 2
        height: Math.round(28 * Config.scale)

        HoverHandler {
            id: timeHover
        }

        // Snap open; animate closed
        Behavior on width {
            enabled: !timeHover.hovered
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        // Always visible when a player exists; expands on hover
        scale: (root.player && (cardHover.hovered || timeHover.hovered)) ? 1.0 : (root.player ? 0.95 : 0.72)
        opacity: root.player ? 1.0 : 0.0
        transformOrigin: Item.Right
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

        // Frosted pill — always rendered, just wider on hover
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Qt.rgba(0, 0, 0, 0.55)
            border.color: Qt.rgba(1, 1, 1, 0.22)
            border.width: 1
        }

        // Collapsed label — right-aligned inside pill, hidden when expanded
        Text {
            id: timeLabelCollapsed
            anchors.right: parent.right
            anchors.rightMargin: timeArea.pillPad
            anchors.verticalCenter: parent.verticalCenter
            text: root.formatTime(root.livePosition) + " / " + root.formatTime(root.trackLength)
            color: Qt.rgba(1, 1, 1, 0.85)
            font.family: Config.font.family
            font.pixelSize: Config.font.sizeSm
            visible: !timeHover.hovered
        }

        // Current time label — left side inside pill, only when expanded
        Text {
            id: timeLabelInline
            anchors.left: parent.left
            anchors.leftMargin: timeArea.pillPad
            anchors.verticalCenter: parent.verticalCenter
            text: root.formatTime(root.livePosition)
            color: Qt.rgba(1, 1, 1, 0.85)
            font.family: Config.font.family
            font.pixelSize: Config.font.sizeSm
            visible: timeHover.hovered
        }

        // Total time label — right side inside pill, only when expanded
        Text {
            id: timeLabelTotal
            anchors.right: parent.right
            anchors.rightMargin: timeArea.pillPad
            anchors.verticalCenter: parent.verticalCenter
            text: root.formatTime(root.trackLength)
            color: Qt.rgba(1, 1, 1, 0.85)
            font.family: Config.font.family
            font.pixelSize: Config.font.sizeSm
            visible: timeHover.hovered
        }

        // Seek track — fills space between the two time labels
        Item {
            id: inlineSeekTrack
            anchors.left: timeLabelInline.right
            anchors.right: timeLabelTotal.left
            anchors.leftMargin: Math.round(8 * Config.scale)
            anchors.rightMargin: Math.round(8 * Config.scale)
            anchors.verticalCenter: parent.verticalCenter
            height: Math.round(16 * Config.scale)
            visible: timeHover.hovered
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
            }
            // Thumb
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: inlineSeekTrack.width * inlineSeekTrack.frac - width / 2
                width: Math.round(9 * Config.scale)
                height: width
                radius: width / 2
                color: "white"
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

    // ── Volume — top-left corner of the card ─────────────────────────────────
    Item {
        id: volArea
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: Math.round(22 * Config.scale)
        anchors.topMargin: Math.round(22 * Config.scale)
        // Collapsed width = icon + pill padding on both sides
        readonly property real pillPad: Math.round(10 * Config.scale)
        width: volHover.hovered ? Math.round(200 * Config.scale) : volIcon.implicitWidth + pillPad * 2
        height: Math.round(28 * Config.scale)

        HoverHandler {
            id: volHover
        }

        // Snap open; animate closed
        Behavior on width {
            enabled: !volHover.hovered
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        // Spring-in on card hover; hidden entirely when nothing is playing
        scale: (root.player && (cardHover.hovered || volHover.hovered)) ? 1.0 : 0.72
        opacity: (root.player && (cardHover.hovered || volHover.hovered)) ? 1.0 : 0.0
        transformOrigin: Item.Left
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

        // Frosted pill — always rendered, just wider on hover
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Qt.rgba(0, 0, 0, 0.55)
            border.color: Qt.rgba(1, 1, 1, 0.22)
            border.width: 1
        }

        // Icon — pinned left inside pill
        IconImage {
            id: volIcon
            anchors.left: parent.left
            anchors.leftMargin: volArea.pillPad
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
        }

        // Percentage label — right side, only shown when expanded
        Text {
            id: volPctLabel
            anchors.right: parent.right
            anchors.rightMargin: Math.round(12 * Config.scale)
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.volume * 100) + "%"
            color: Qt.rgba(1, 1, 1, 0.85)
            font.family: Config.font.family
            font.pixelSize: Config.font.sizeSm
            visible: volHover.hovered
        }

        // Slider track — fills between icon and % label
        Item {
            id: inlineVolTrack
            anchors.left: volIcon.right
            anchors.right: volPctLabel.visible ? volPctLabel.left : parent.right
            anchors.leftMargin: Math.round(6 * Config.scale)
            anchors.rightMargin: Math.round(8 * Config.scale)
            anchors.verticalCenter: parent.verticalCenter
            height: Math.round(16 * Config.scale)
            visible: volHover.hovered
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
            }
            // Thumb
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: inlineVolTrack.width * inlineVolTrack.frac - width / 2
                width: Math.round(9 * Config.scale)
                height: width
                radius: width / 2
                color: "white"
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

    // ── Controls overlay ──────────────────────────────────────────────────────
    Item {
        id: controlsOverlay
        anchors.fill: parent

        // Art zone — used only to size controls correctly above the info strip.
        Item {
            id: artZone
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height - infoStrip.height
        }

        // Controls column — centred in the full card overlay
        ColumnLayout {
            id: controlsColumn
            anchors.centerIn: parent
            width: parent.width - Math.round(24 * Config.scale)

            transformOrigin: Item.Center
            readonly property bool fits: implicitHeight <= artZone.height
            scale: (root.player && cardHover.hovered && fits) ? 1.0 : 0.72
            opacity: (root.player && cardHover.hovered && fits) ? 1.0 : 0.0
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
}
