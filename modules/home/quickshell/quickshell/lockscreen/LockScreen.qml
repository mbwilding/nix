pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

import "."
import ".."
import "../components"

Scope {
    id: root

    property bool pamAuthenticating: false
    property bool pamIsError: false
    property string pamMessage: ""
    property var notifHistory: []

    signal clearPasswordField
    signal focusPasswordField
    signal shakePasswordField

    IpcHandler {
        target: "lockscreen"
        function lock() {
            sessionLock.locked = true;
            root.pamMessage = "";
            root.pamIsError = false;
            root.clearPasswordField();
            pam.start();
        }
        function unlock() {
            sessionLock.locked = false;
        }
    }

    PamContext {
        id: pam
        config: "login"

        onPamMessage: {
            root.pamIsError = pam.messageIsError;
            root.pamMessage = pam.messageIsError ? pam.message : "";
            if (pam.responseRequired) {
                root.pamAuthenticating = true;
                root.focusPasswordField();
            }
        }

        onCompleted: result => {
            root.pamAuthenticating = false;
            if (result === PamResult.Success) {
                sessionLock.locked = false;
            } else {
                root.pamIsError = true;
                root.pamMessage = result === PamResult.MaxTries ? "Too many attempts" : (pam.message !== "" ? pam.message : "Authentication failed");
                root.clearPasswordField();
                root.shakePasswordField();
                pamRetryTimer.restart();
            }
        }

        onError: error => {
            root.pamAuthenticating = false;
            root.pamIsError = true;
            root.pamMessage = "PAM error: " + PamError.toString(error);
            root.clearPasswordField();
            root.shakePasswordField();
            pamRetryTimer.restart();
        }
    }

    Timer {
        id: pamRetryTimer
        interval: 1200
        onTriggered: {
            root.pamMessage = "";
            root.pamIsError = false;
            pam.start();
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    WlSessionLock {
        id: sessionLock
        locked: false

        surface: WlSessionLockSurface {
            id: lockSurface

            Item {
                anchors.fill: parent
                clip: true

                Connections {
                    target: root
                    function onFocusPasswordField() {
                        passwordInput.forceActiveFocus();
                    }
                    function onShakePasswordField() {
                        shakeAnim.restart();
                    }
                    function onClearPasswordField() {
                        passwordInput.text = "";
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "#0d0d18"

                    Canvas {
                        id: bgCanvas
                        anchors.fill: parent

                        // Each orb: {x, y} in normalized [0,1] coords
                        property var orbPos: []
                        // Each orb: {vx, vy} in normalized units/s
                        property var orbVel: []

                        // Orb colour stops — cycles across orbs
                        readonly property var orbColors: [
                            ["rgba(192, 170, 255, 0.30)", "rgba(192, 170, 255, 0.00)"],
                            ["rgba(255, 159, 243, 0.25)", "rgba(255, 159, 243, 0.00)"],
                            ["rgba(137, 220, 235, 0.22)", "rgba(137, 220, 235, 0.00)"],
                            ["rgba(166, 227, 161, 0.20)", "rgba(166, 227, 161, 0.00)"],
                            ["rgba(243, 139, 168, 0.22)", "rgba(243, 139, 168, 0.00)"],
                        ]
                        // Orb radii as fraction of min(w,h) — cycles across orbs
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
                            running: true
                            onTriggered: {
                                const dt = Math.min(frameTime, 0.05);
                                const count = bgCanvas.orbPos.length;
                                if (count === 0) return;
                                let pos = bgCanvas.orbPos.map(p => ({ x: p.x, y: p.y }));
                                let vel = bgCanvas.orbVel.map(v => ({ vx: v.vx, vy: v.vy }));
                                for (let i = 0; i < count; i++) {
                                    pos[i].x += vel[i].vx * dt;
                                    pos[i].y += vel[i].vy * dt;
                                    if (pos[i].x < 0) { pos[i].x = 0; vel[i].vx =  Math.abs(vel[i].vx); }
                                    else if (pos[i].x > 1) { pos[i].x = 1; vel[i].vx = -Math.abs(vel[i].vx); }
                                    if (pos[i].y < 0) { pos[i].y = 0; vel[i].vy =  Math.abs(vel[i].vy); }
                                    else if (pos[i].y > 1) { pos[i].y = 1; vel[i].vy = -Math.abs(vel[i].vy); }
                                }
                                bgCanvas.orbPos = pos;
                                bgCanvas.orbVel = vel;
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

                    // DVD bouncer — supports multiple logos bouncing off walls and each other
                    Item {
                        id: dvdBouncer
                        anchors.fill: parent

                        readonly property int logoW: 220
                        readonly property int logoH: Math.round(220 * 465.84 / 1058.4)
                        readonly property real dvdSpeed: 120
                        readonly property var dvdColors: [Config.colors.accent, Config.colors.accentAlt, "#89dceb", "#a6e3a1", "#f38ba8", "#fab387", "#f9e2af"]

                        // Flat state arrays — one entry per logo.
                        // We store them as plain JS arrays and reassign the whole array to
                        // trigger Repeater delegate bindings via the model array property.
                        property var positions: []   // [{x, y}, ...]
                        property var velocities: []  // [{vx, vy}, ...]
                        property var colorIdxs: []   // [int, ...]
                        property bool initialized: false

                        function initLogos() {
                            if (initialized || width <= 0 || height <= 0) return;
                            initialized = true;
                            const count = Config.lockscreen.dvdCount;
                            const maxX = width - logoW;
                            const maxY = height - logoH;
                            let pos = [], vel = [], cidx = [];
                            for (let i = 0; i < count; i++) {
                                let candidate = { x: 0, y: 0 };
                                for (let attempt = 0; attempt < 30; attempt++) {
                                    candidate = { x: Math.random() * maxX, y: Math.random() * maxY };
                                    let ok = true;
                                    for (let j = 0; j < pos.length; j++) {
                                        // AABB overlap check — same as runtime collision
                                        if (candidate.x < pos[j].x + logoW && candidate.x + logoW > pos[j].x &&
                                            candidate.y < pos[j].y + logoH && candidate.y + logoH > pos[j].y) {
                                            ok = false; break;
                                        }
                                    }
                                    if (ok) break;
                                }
                                pos.push(candidate);
                                vel.push({
                                    vx: (Math.random() < 0.5 ? 1 : -1) * dvdSpeed,
                                    vy: (Math.random() < 0.5 ? 1 : -1) * dvdSpeed
                                });
                                cidx.push((Math.floor(Math.random() * dvdColors.length) + i) % dvdColors.length);
                            }
                            positions = pos;
                            velocities = vel;
                            colorIdxs = cidx;
                        }

                        Component.onCompleted: initLogos()
                        onWidthChanged: initLogos()
                        onHeightChanged: initLogos()

                        FrameAnimation {
                            id: dvdTimer
                            running: true
                            onTriggered: {
                                const dt = Math.min(frameTime, 0.05);
                                const count = dvdBouncer.positions.length;
                                if (count === 0) return;

                                const lW = dvdBouncer.logoW;
                                const lH = dvdBouncer.logoH;
                                const maxX = dvdBouncer.width - lW;
                                const maxY = dvdBouncer.height - lH;
                                const colors = dvdBouncer.dvdColors;

                                // Deep-copy mutable state
                                let pos  = dvdBouncer.positions.map(p => ({ x: p.x, y: p.y }));
                                let vel  = dvdBouncer.velocities.map(v => ({ vx: v.vx, vy: v.vy }));
                                let cidx = dvdBouncer.colorIdxs.slice();

                                // Integrate positions
                                for (let i = 0; i < count; i++) {
                                    pos[i].x += vel[i].vx * dt;
                                    pos[i].y += vel[i].vy * dt;
                                }

                                // Wall collisions
                                for (let i = 0; i < count; i++) {
                                    let bounced = false;
                                    if (pos[i].x <= 0)    { pos[i].x = 0;    vel[i].vx =  Math.abs(vel[i].vx); bounced = true; }
                                    else if (pos[i].x >= maxX) { pos[i].x = maxX; vel[i].vx = -Math.abs(vel[i].vx); bounced = true; }
                                    if (pos[i].y <= 0)    { pos[i].y = 0;    vel[i].vy =  Math.abs(vel[i].vy); bounced = true; }
                                    else if (pos[i].y >= maxY) { pos[i].y = maxY; vel[i].vy = -Math.abs(vel[i].vy); bounced = true; }
                                    if (bounced)
                                        cidx[i] = (cidx[i] + 1) % colors.length;
                                }

                                // Logo-logo AABB collisions using SAT on the two rectangle axes.
                                // For each overlapping pair, find the axis of minimum penetration,
                                // separate along it, and swap the velocity component on that axis.
                                for (let i = 0; i < count; i++) {
                                    for (let j = i + 1; j < count; j++) {
                                        const overlapX = (pos[i].x + lW) - pos[j].x;
                                        const overlapXr = (pos[j].x + lW) - pos[i].x;
                                        const overlapY = (pos[i].y + lH) - pos[j].y;
                                        const overlapYr = (pos[j].y + lH) - pos[i].y;

                                        // No overlap on either axis → no collision
                                        if (overlapX <= 0 || overlapXr <= 0 || overlapY <= 0 || overlapYr <= 0)
                                            continue;

                                        // Minimum penetration depth and direction on each axis
                                        const penX = Math.min(overlapX, overlapXr);
                                        const penY = Math.min(overlapY, overlapYr);
                                        const signX = overlapX < overlapXr ? 1 : -1;
                                        const signY = overlapY < overlapYr ? 1 : -1;

                                        if (penX < penY) {
                                            // Separate and reflect on X axis
                                            const half = penX / 2;
                                            pos[i].x -= signX * half;
                                            pos[j].x += signX * half;
                                            if ((vel[i].vx - vel[j].vx) * signX > 0) {
                                                const tmp = vel[i].vx;
                                                vel[i].vx = vel[j].vx;
                                                vel[j].vx = tmp;
                                                cidx[i] = (cidx[i] + 1) % colors.length;
                                                cidx[j] = (cidx[j] + 1) % colors.length;
                                            }
                                        } else {
                                            // Separate and reflect on Y axis
                                            const half = penY / 2;
                                            pos[i].y -= signY * half;
                                            pos[j].y += signY * half;
                                            if ((vel[i].vy - vel[j].vy) * signY > 0) {
                                                const tmp = vel[i].vy;
                                                vel[i].vy = vel[j].vy;
                                                vel[j].vy = tmp;
                                                cidx[i] = (cidx[i] + 1) % colors.length;
                                                cidx[j] = (cidx[j] + 1) % colors.length;
                                            }
                                        }
                                    }
                                }

                                // Re-clamp after separation pushes
                                for (let i = 0; i < count; i++) {
                                    pos[i].x = Math.max(0, Math.min(maxX, pos[i].x));
                                    pos[i].y = Math.max(0, Math.min(maxY, pos[i].y));
                                }

                                // Write back — reassign to trigger bindings
                                dvdBouncer.positions  = pos;
                                dvdBouncer.velocities = vel;
                                dvdBouncer.colorIdxs  = cidx;
                            }
                        }

                        Repeater {
                            model: dvdBouncer.positions.length

                            Item {
                                required property int index
                                x: dvdBouncer.positions[index]?.x ?? 0
                                y: dvdBouncer.positions[index]?.y ?? 0
                                width: dvdBouncer.logoW
                                height: dvdBouncer.logoH
                                opacity: 0.55

                                Shape {
                                    anchors.fill: parent
                                    transform: Scale {
                                        xScale: dvdBouncer.logoW / 1058.4
                                        yScale: dvdBouncer.logoH / 465.84
                                    }

                                    ShapePath {
                                        fillColor: dvdBouncer.dvdColors[dvdBouncer.colorIdxs[index] ?? 0] ?? dvdBouncer.dvdColors[0]
                                        strokeColor: "transparent"
                                        strokeWidth: 0
                                        Behavior on fillColor {
                                            ColorAnimation {
                                                duration: 200
                                            }
                                        }

                                        PathSvg {
                                            path: "m91.053 0-13.719 57.707 102.28 0.039063h24c65.747 0 105.91 26.44 94.746 73.4-12.147 51.133-69.613 73.4-130.67 73.4h-22.947l29.787-125.45h-102.27l-43.521 183.2h145.05c109.07 0 212.76-57.573 231.01-131.15 3.3467-13.507 2.8806-47.253-5.3594-67.359-0.21299-0.787-0.42594-1.4-1.1855-3-0.293-0.653-0.56012-3.6412 1.1465-4.2812 0.947-0.36 2.7069 1.4944 2.9336 2.041 0.853 2.24 1.5059 3.9062 1.5059 3.9062l92.293 260.6 234.97-265.21 99.535-0.089844h24c65.76 0 106.25 26.44 95.092 73.4-12.147 51.133-69.947 73.4-131 73.4h-22.959l29.799-125.47h-102.27l-43.533 183.21h145.07c109.05 0 213.48-57.4 231-131.15 17.52-73.75-59.107-131.15-168.69-131.15h-216.4s-57.319 67.88-67.959 80.693c-57.12 68.787-67.241 87.226-68.961 91.986 0.24-4.8-1.8138-23.412-26.174-92.959-6.48-18.52-27.359-79.721-27.359-79.721h-389.25zm408.77 324.16c-276.04 0-499.83 31.72-499.83 70.84s223.79 70.84 499.83 70.84c276.04 0 499.83-31.72 499.83-70.84s-223.79-70.84-499.83-70.84zm-18.094 48.627c63.04 0 114.13 10.573 114.13 23.613s-51.095 23.613-114.13 23.613c-63.027 0-114.13-10.573-114.13-23.613s51.106-23.613 114.13-23.613z"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: Math.round(32 * Config.scale)

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Math.round(4 * Config.scale)

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Config.bar.clock24h ? Qt.formatTime(clock.date, "HH:mm") : Qt.formatTime(clock.date, "hh:mm") + " " + Qt.formatTime(clock.date, "AP")
                            color: Config.colors.accent
                            font.family: Config.font.family
                            font.pixelSize: Math.round(Config.bar.fontSizeClock * 2.2)
                            font.weight: Font.Light
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDate(clock.date, "dddd, MMMM d, yyyy")
                            color: Config.colors.textSecondary
                            font.family: Config.font.family
                            font.pixelSize: Math.round(Config.bar.fontSizeStatus * 0.85)
                            font.weight: Font.Normal
                        }
                    }

                    Item {
                        id: passwordArea
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.round(360 * Config.scale)
                        height: passwordCol.implicitHeight

                        SequentialAnimation {
                            id: shakeAnim
                            property real restX: 0
                            ScriptAction {
                                script: {
                                    shakeAnim.restX = passwordArea.x;
                                }
                            }
                            NumberAnimation {
                                target: passwordArea
                                property: "x"
                                to: shakeAnim.restX - Math.round(10 * Config.scale)
                                duration: 50
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: passwordArea
                                property: "x"
                                to: shakeAnim.restX + Math.round(18 * Config.scale)
                                duration: 70
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: passwordArea
                                property: "x"
                                to: shakeAnim.restX - Math.round(14 * Config.scale)
                                duration: 60
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: passwordArea
                                property: "x"
                                to: shakeAnim.restX + Math.round(10 * Config.scale)
                                duration: 60
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: passwordArea
                                property: "x"
                                to: shakeAnim.restX - Math.round(6 * Config.scale)
                                duration: 50
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: passwordArea
                                property: "x"
                                to: shakeAnim.restX
                                duration: 40
                                easing.type: Easing.InOutQuad
                            }
                        }

                        Column {
                            id: passwordCol
                            width: parent.width
                            spacing: Math.round(10 * Config.scale)

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: root.pamMessage !== ""
                                text: root.pamMessage
                                color: root.pamIsError ? Config.colors.danger : Config.colors.textMuted
                                font.family: Config.font.family
                                font.pixelSize: Math.round(11 * Config.scale)
                                opacity: 0.9
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: Math.round(44 * Config.scale)
                                radius: Math.round(12 * Config.scale)
                                color: Config.colors.surface
                                border.width: passwordInput.activeFocus ? Math.round(1.5 * Config.scale) : Config.panelBorder.width
                                border.color: root.pamIsError ? Qt.rgba(Config.colors.danger.r, Config.colors.danger.g, Config.colors.danger.b, passwordInput.activeFocus ? 0.9 : 0.5) : passwordInput.activeFocus ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.8) : Config.panelBorder.color
                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: "transparent"
                                    border.width: Math.round(4 * Config.scale)
                                    border.color: root.pamIsError ? Qt.rgba(Config.colors.danger.r, Config.colors.danger.g, Config.colors.danger.b, 0.12) : Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.12)
                                    opacity: passwordInput.activeFocus ? 1.0 : 0.0
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 150
                                        }
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Math.round(14 * Config.scale)
                                    anchors.rightMargin: Math.round(14 * Config.scale)
                                    spacing: Math.round(10 * Config.scale)

                                    Text {
                                        text: root.pamAuthenticating ? "\uF13E" : "\uF023"
                                        color: root.pamIsError ? Config.colors.danger : passwordInput.activeFocus ? Config.colors.accent : Config.colors.textMuted
                                        font.family: Config.font.family
                                        font.pixelSize: Math.round(14 * Config.scale)
                                        opacity: 0.8
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                            }
                                        }
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        height: Math.round(20 * Config.scale)

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: passwordInput.text.length === 0
                                            text: "Enter password…"
                                            color: Config.colors.textMuted
                                            font.family: Config.font.family
                                            font.pixelSize: Math.round(13 * Config.scale)
                                            opacity: 0.45
                                        }

                                        Row {
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: passwordInput.text.length > 0
                                            spacing: Math.round(5 * Config.scale)

                                            Repeater {
                                                model: Math.min(passwordInput.text.length, 32)
                                                delegate: Rectangle {
                                                    required property int index
                                                    width: Math.round(7 * Config.scale)
                                                    height: width
                                                    radius: width / 2
                                                    color: root.pamIsError ? Config.colors.danger : Config.colors.accent
                                                    opacity: 0.85
                                                }
                                            }

                                            Text {
                                                visible: passwordInput.text.length > 32
                                                text: "+" + (passwordInput.text.length - 32)
                                                color: Config.colors.textMuted
                                                font.family: Config.font.family
                                                font.pixelSize: Math.round(10 * Config.scale)
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        TextInput {
                                            id: passwordInput
                                            anchors.fill: parent
                                            opacity: 0
                                            echoMode: TextInput.Password
                                            focus: true

                                            Keys.onReturnPressed: {
                                                if (text.length > 0 && pam.responseRequired) {
                                                    pam.respond(text);
                                                    text = "";
                                                }
                                            }
                                            Keys.onEnterPressed: {
                                                if (text.length > 0 && pam.responseRequired) {
                                                    pam.respond(text);
                                                    text = "";
                                                }
                                            }
                                            Keys.onEscapePressed: {
                                                text = "";
                                            }
                                        }
                                    }

                                    Text {
                                        visible: pam.active && !pam.responseRequired
                                        text: "\uF110"
                                        color: Config.colors.accent
                                        font.family: Config.font.family
                                        font.pixelSize: Math.round(14 * Config.scale)
                                        opacity: 0.7

                                        RotationAnimator on rotation {
                                            from: 0
                                            to: 360
                                            duration: 900
                                            loops: Animation.Infinite
                                            running: pam.active && !pam.responseRequired
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        id: notifContainer
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.notifHistory.length > 0
                        width: Math.round(360 * Config.scale)
                        height: Math.min(notifInnerCol.implicitHeight, lockSurface.height - passwordArea.height - Math.round(160 * Config.scale))
                        clip: true

                        property real scrollY: 0
                        readonly property real maxScrollY: Math.max(0, notifInnerCol.implicitHeight - notifContainer.height)

                        WheelHandler {
                            target: null
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: event => {
                                const step = Math.round(36 * Config.scale);
                                notifContainer.scrollY = Math.max(0, Math.min(notifContainer.maxScrollY, notifContainer.scrollY - event.angleDelta.y / 120 * step));
                            }
                        }

                        Column {
                            id: notifInnerCol
                            width: notifContainer.width - Math.round(6 * Config.scale)
                            spacing: Math.round(6 * Config.scale)
                            y: -notifContainer.scrollY

                            RowLayout {
                                width: parent.width

                                Text {
                                    text: "\uF0F3  Notifications"
                                    color: Config.colors.textMuted
                                    font.family: Config.font.family
                                    font.pixelSize: Config.font.sizeLg
                                    font.weight: Font.Medium
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: root.notifHistory.length > 99 ? "99+" : String(root.notifHistory.length)
                                    color: Config.colors.accentAlt
                                    font.family: Config.font.family
                                    font.pixelSize: Config.font.sizeLg
                                    font.weight: Font.Bold
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Config.colors.border
                                opacity: 0.4
                            }

                            Repeater {
                                model: root.notifHistory
                                delegate: LockNotificationsCard {
                                    id: lockNotifD
                                    required property var modelData
                                    snapshot: lockNotifD.modelData
                                    width: notifInnerCol.width
                                }
                            }
                        }

                        Rectangle {
                            visible: notifContainer.maxScrollY > 0
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.round(3 * Config.scale)
                            radius: width / 2
                            color: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18)

                            Rectangle {
                                readonly property real _h: notifContainer.maxScrollY <= 0 ? parent.height : Math.max(Math.round(28 * Config.scale), parent.height * (notifContainer.height / notifInnerCol.implicitHeight))
                                readonly property real _y: notifContainer.maxScrollY <= 0 ? 0 : (parent.height - _h) * (notifContainer.scrollY / notifContainer.maxScrollY)
                                y: _y
                                width: parent.width
                                height: _h
                                radius: width / 2
                                color: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.55)
                            }
                        }
                    }
                }
            }
        }
    }
}
