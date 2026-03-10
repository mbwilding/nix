pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io

import ".."
import "../components"

// Per-core CPU boxes with overall average bar — fills the entire content area.
Item {
    id: root

    // Set to false (bound to Stats.qml's visible_) to pause polling
    property bool active: true

    property var corePercents: []
    property var coreFreqsKhz: []
    property var _prevCores: []
    property string cpuName: ""
    property string powerProfile: ""
    property int cpuTempMilliC: 0
    property real sysPowerUw: 0      // µW from BAT1/power_now (total system draw)

    // ── Ring-buffer history ───────────────────────────────────────────────────
    // Each core's history is a Float32Array ring; metadata is stored alongside.
    // Layout per core: { buf: Float32Array(historyLen), head: int, count: int }
    readonly property int historyLen: 30

    // Exposed read-only snapshot arrays (plain JS arrays) rebuilt after each push
    // so Canvas bindings can diff-detect the change.
    property var coreHistory: []

    // Internal ring state — one entry per detected core.
    property var _rings: []

    // Push a value into a ring and return a fresh snapshot JS array (oldest→newest).
    function _ringPush(ring, val) {
        ring.buf[ring.head] = val;
        ring.head = (ring.head + 1) % root.historyLen;
        if (ring.count < root.historyLen) ring.count++;
        // Build ordered snapshot
        const snap = [];
        const start = ring.count < root.historyLen ? 0 : ring.head;
        for (let i = 0; i < ring.count; i++) {
            snap.push(ring.buf[(start + i) % root.historyLen]);
        }
        return snap;
    }

    function _ensureRings(n) {
        let rings = root._rings;
        while (rings.length < n) {
            rings.push({ buf: new Float32Array(root.historyLen), head: 0, count: 0 });
        }
        if (rings.length > n) rings = rings.slice(0, n);
        root._rings = rings;
    }

    property Process _cpuInfoProc: Process {
        command: ["sh", "-c", "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.cpuName = this.text.trim()
        }
    }

    property Process _cpuProc: Process {
        command: ["cat", "/proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n");
                const newPercents = [];
                const newPrev = [];
                let totalPct = 0;
                let coreCount = 0;
                for (const line of lines) {
                    if (!line.startsWith("cpu") || line.startsWith("cpu "))
                        continue;
                    const parts = line.trim().split(/\s+/);
                    const idx = parseInt(parts[0].slice(3));
                    if (isNaN(idx))
                        continue;
                    const user    = parseInt(parts[1]) || 0;
                    const nice    = parseInt(parts[2]) || 0;
                    const system  = parseInt(parts[3]) || 0;
                    const idle    = parseInt(parts[4]) || 0;
                    const iowait  = parseInt(parts[5]) || 0;
                    const irq     = parseInt(parts[6]) || 0;
                    const sirq    = parseInt(parts[7]) || 0;
                    const idleTotal = idle + iowait;
                    const total     = idleTotal + user + nice + system + irq + sirq;
                    let pct = 0;
                    const prev = root._prevCores[idx];
                    if (prev) {
                        const dIdle  = idleTotal - prev[0];
                        const dTotal = total     - prev[1];
                        if (dTotal > 0)
                            pct = Math.round((1 - dIdle / dTotal) * 100);
                    }
                    newPercents[idx] = pct;
                    newPrev[idx] = [idleTotal, total];
                    totalPct += pct;
                    coreCount++;
                }
                root._prevCores = newPrev;
                root.corePercents = newPercents;
                root.avgPercent = coreCount > 0 ? Math.round(totalPct / coreCount) : 0;

                // Update ring-buffer history for each core
                const n = newPercents.length;
                root._ensureRings(n);
                const rings = root._rings;
                const hist = [];
                for (let i = 0; i < n; i++) {
                    hist.push(root._ringPush(rings[i], newPercents[i] ?? 0));
                }
                root.coreHistory = hist;
            }
        }
    }

    // Read all core frequencies in one shot: outputs "khz0 khz1 khz2 ..." space-separated
    property Process _freqProc: Process {
        command: ["sh", "-c", "paste -s -d' ' /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(/\s+/);
                const freqs = [];
                for (let i = 0; i < parts.length; i++) {
                    const v = parseInt(parts[i]);
                    freqs.push(isNaN(v) ? 0 : v);
                }
                root.coreFreqsKhz = freqs;
            }
        }
    }

    property Process _profileProc: Process {
        command: ["cat", "/sys/firmware/acpi/platform_profile"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.powerProfile = this.text.trim()
        }
    }

    property Process _tempProc: Process {
        command: ["cat", "/sys/class/hwmon/hwmon1/temp1_input"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.cpuTempMilliC = parseInt(this.text.trim()) || 0
        }
    }

    property Process _sysPowerProc: Process {
        command: ["cat", "/sys/class/power_supply/BAT1/power_now"]
        stdout: StdioCollector {
            onStreamFinished: root.sysPowerUw = parseFloat(this.text.trim()) || 0
        }
    }

    property Timer _cpuTimer: Timer {
        interval: 2000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: {
            root._cpuProc.running = true;
            root._freqProc.running = true;
            root._profileProc.running = true;
            root._tempProc.running = true;
            root._sysPowerProc.running = true;
        }
    }

    property int avgPercent: 0

    readonly property color avgColor: avgPercent > 80 ? Config.colors.danger : avgPercent > 50 ? Config.colors.warning : Config.colors.accent

    readonly property color profileColor: powerProfile === "performance" ? Config.colors.accentAlt : powerProfile === "balanced" ? Config.colors.accent : Config.colors.textMuted

    readonly property int cpuTempC: Math.round(root.cpuTempMilliC / 1000)
    readonly property color tempColor: cpuTempC >= 90 ? Config.colors.danger : cpuTempC >= 70 ? Config.colors.warning : Config.colors.accent

    readonly property real sysPowerW: root.sysPowerUw / 1000000
    readonly property color powerColor: sysPowerW >= 50 ? Config.colors.danger : sysPowerW >= 30 ? Config.colors.warning : Config.colors.accent

    // Compute a balanced grid: find the smallest cols >= sqrt(N) that divides N exactly,
    // falling back to ceil(sqrt(N)) if N is prime or no clean divisor is found nearby.
    readonly property int coreCount: root.corePercents.length
    readonly property int cols: {
        const n = coreCount;
        if (n <= 1) return 1;
        const base = Math.ceil(Math.sqrt(n));
        // Search upward from base for an exact divisor (no wasted cells)
        for (let c = base; c <= n; c++) {
            if (n % c === 0) return c;
        }
        return base;
    }
    readonly property int rows: coreCount > 0 ? Math.ceil(coreCount / cols) : 1

    readonly property int pad: Math.round(12 * Config.scale)
    readonly property int gap: Math.round(5 * Config.scale)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: Math.round(10 * Config.scale)

        // ── Overall CPU average bar ───────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(4 * Config.scale)

            // ── Label row: CPU XX%  ·  Profile  ·  XX°C ─────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * Config.scale)

                Text {
                    text: "CPU"
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeMd
                    font.weight: Font.Medium
                }
                Text {
                    text: root.avgPercent + "%"
                    color: root.avgColor
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeMd
                    font.weight: Font.Medium
                    Behavior on color {
                        ColorAnimation {
                            duration: 400
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: root.powerProfile
                    color: root.profileColor
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeMd
                    font.capitalization: Font.Capitalize
                    visible: root.powerProfile !== ""
                    Behavior on color {
                        ColorAnimation {
                            duration: 400
                        }
                    }
                }

                Text {
                    text: "·"
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeMd
                    visible: root.powerProfile !== "" && root.sysPowerW > 0
                }

                Text {
                    text: root.sysPowerW.toFixed(1) + " W"
                    color: root.powerColor
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeMd
                    font.weight: Font.Medium
                    visible: root.sysPowerW > 0
                    Behavior on color {
                        ColorAnimation {
                            duration: 400
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: root.cpuTempC + "°C"
                    color: root.tempColor
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeMd
                    font.weight: Font.Medium
                    visible: root.cpuTempC > 0
                    Behavior on color {
                        ColorAnimation {
                            duration: 400
                        }
                    }
                }
            }

            // ── CPU name (centred, smaller, elides gracefully) ────────────────
            Text {
                Layout.fillWidth: true
                text: root.cpuName
                color: Config.colors.textMuted
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeSm
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                visible: root.cpuName !== ""
            }

            GradientProgressBar {
                Layout.fillWidth: true
                value: root.avgPercent / 100
                barHeight: Math.round(6 * Config.scale)
            }
        }

        // ── Divider ───────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Config.panelBorder.color
            opacity: 0.35
        }

        // ── Per-core grid ─────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Repeater {
                model: root.corePercents.length

                delegate: Item {
                    id: coreCell
                    required property int index
                    readonly property int pct: root.corePercents[index] ?? 0
                    readonly property int col: index % root.cols
                    readonly property int row: Math.floor(index / root.cols)
                    readonly property int freqKhz: root.coreFreqsKhz[index] ?? 0
                    readonly property string freqText: freqKhz > 0 ? (freqKhz / 1000000).toFixed(2) : ""
                    readonly property var history: root.coreHistory[index] ?? []

                    readonly property real _cellW: parent.width > 0 ? (parent.width - (root.cols - 1) * root.gap) / Math.max(root.cols, 1) : 0
                    readonly property real _cellH: parent.height > 0 ? (parent.height - (root.rows - 1) * root.gap) / Math.max(root.rows, 1) : 0

                    x: col * (_cellW + root.gap)
                    y: row * (_cellH + root.gap)
                    width: _cellW
                    height: _cellH

                    // Hover state for historical readout
                    property bool cellHovered: false
                    property int hoverIndex: -1
                    readonly property int hoverPct: (hoverIndex >= 0 && hoverIndex < history.length) ? history[hoverIndex] : pct

                    readonly property color barColor: pct > 80 ? Config.colors.danger : pct > 50 ? Config.colors.warning : Config.colors.accent

                    // Dot position — mirrors the sparkCanvas paint formula so the floating label tracks it.
                    // sparkCanvas has anchors.margins: 2, so its geometry is (width-4) × (height-4).
                    readonly property real _canvasMargin: 2
                    readonly property real _cw: Math.max(0, width - _canvasMargin * 2)
                    readonly property real _ch: Math.max(0, height - _canvasMargin * 2)
                    readonly property real _step: root.historyLen > 1 ? _cw / (root.historyLen - 1) : _cw
                    readonly property real _xOff: (root.historyLen - history.length) * _step
                    readonly property real dotX: (cellHovered && hoverIndex >= 0 && hoverIndex < history.length)
                        ? _canvasMargin + _xOff + hoverIndex * _step
                        : -1
                    readonly property real dotY: (cellHovered && hoverIndex >= 0 && hoverIndex < history.length)
                        ? _canvasMargin + _ch - (history[hoverIndex] / 100) * _ch
                        : -1

                    // Card background
                    Rectangle {
                        id: cardBg
                        anchors.fill: parent
                        radius: Math.round(7 * Config.scale)
                        color: Config.colors.surface
                        border.color: Qt.rgba(coreCell.barColor.r, coreCell.barColor.g, coreCell.barColor.b, coreCell.pct > 50 ? 0.45 : 0.14)
                        border.width: 1

                        Behavior on border.color {
                            ColorAnimation { duration: 600 }
                        }

                        // ── Vertical fill bar — rises from bottom ─────────────
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 2
                            height: Math.max(0, (parent.height - 4) * (coreCell.pct / 100))
                            radius: Math.round(6 * Config.scale)
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop {
                                    position: 0.0
                                    color: Qt.rgba(coreCell.barColor.r, coreCell.barColor.g, coreCell.barColor.b, 0.75)
                                }
                                GradientStop {
                                    position: 1.0
                                    color: Qt.rgba(coreCell.barColor.r, coreCell.barColor.g, coreCell.barColor.b, 0.28)
                                }
                            }
                            Behavior on height {
                                NumberAnimation {
                                    duration: 400
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        // ── Sparkline + crosshair (Canvas) ────────────────────
                        Canvas {
                            id: sparkCanvas
                            anchors.fill: parent
                            anchors.margins: 2

                            readonly property var hist: coreCell.history
                            readonly property bool hov: coreCell.cellHovered
                            readonly property int hovIdx: coreCell.hoverIndex
                            readonly property color lc: coreCell.barColor

                            onHistChanged: requestPaint()
                            onHovChanged: requestPaint()
                            onHovIdxChanged: requestPaint()
                            onLcChanged: requestPaint()

                            onPaint: {
                                const ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);

                                const buf = hist;
                                const n = buf ? buf.length : 0;
                                if (n < 2) return;

                                const w = width;
                                const h = height;
                                const step = w / (root.historyLen - 1);
                                const xOffset = (root.historyLen - n) * step;

                                // Grid lines at 25 / 50 / 75%
                                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.06).toString();
                                ctx.lineWidth = 1;
                                ctx.setLineDash([]);
                                for (let g = 1; g <= 3; g++) {
                                    const gy = h * (1 - g / 4);
                                    ctx.beginPath();
                                    ctx.moveTo(0, gy);
                                    ctx.lineTo(w, gy);
                                    ctx.stroke();
                                }

                                // Build points
                                const pts = [];
                                for (let i = 0; i < n; i++) {
                                    pts.push({
                                        x: xOffset + i * step,
                                        y: h - (buf[i] / 100) * h
                                    });
                                }

                                // Filled area
                                ctx.beginPath();
                                ctx.moveTo(pts[0].x, h);
                                ctx.lineTo(pts[0].x, pts[0].y);
                                for (let i = 1; i < n; i++) {
                                    const cpx = (pts[i-1].x + pts[i].x) / 2;
                                    ctx.bezierCurveTo(cpx, pts[i-1].y, cpx, pts[i].y, pts[i].x, pts[i].y);
                                }
                                ctx.lineTo(pts[n-1].x, h);
                                ctx.closePath();
                                ctx.fillStyle = Qt.rgba(lc.r, lc.g, lc.b, 0.15).toString();
                                ctx.fill();

                                // Line
                                ctx.beginPath();
                                ctx.moveTo(pts[0].x, pts[0].y);
                                for (let i = 1; i < n; i++) {
                                    const cpx = (pts[i-1].x + pts[i].x) / 2;
                                    ctx.bezierCurveTo(cpx, pts[i-1].y, cpx, pts[i].y, pts[i].x, pts[i].y);
                                }
                                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.22).toString();
                                ctx.lineWidth = Math.round(1.5 * Config.scale);
                                ctx.lineJoin = "round";
                                ctx.stroke();

                                // Crosshair + dot on hover
                                if (hov && hovIdx >= 0 && hovIdx < n) {
                                    const hx = pts[hovIdx].x;
                                    const hy = pts[hovIdx].y;

                                    ctx.beginPath();
                                    ctx.moveTo(hx, 0);
                                    ctx.lineTo(hx, h);
                                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.25).toString();
                                    ctx.lineWidth = 1;
                                    ctx.setLineDash([Math.round(3 * Config.scale), Math.round(3 * Config.scale)]);
                                    ctx.stroke();
                                    ctx.setLineDash([]);

                                    ctx.beginPath();
                                    ctx.arc(hx, hy, Math.round(3 * Config.scale), 0, Math.PI * 2);
                                    ctx.fillStyle = lc.toString();
                                    ctx.fill();
                                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.80).toString();
                                    ctx.lineWidth = Math.round(1.5 * Config.scale);
                                    ctx.stroke();
                                }
                            }
                        }

                        // ── Core index — top-left ─────────────────────────────
                        Text {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.topMargin: Math.round(4 * Config.scale)
                            anchors.leftMargin: Math.round(5 * Config.scale)
                            text: "C" + coreCell.index
                            color: Qt.rgba(1, 1, 1, 0.55)
                            font.family: Config.font.family
                            font.pixelSize: Config.font.sizeSm
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: "#cc000000"
                                shadowBlur: 0.8
                                shadowHorizontalOffset: 0
                                shadowVerticalOffset: 1
                            }
                        }

                        // ── Percentage — floats beside the crosshair dot when hovered,
                        //                falls back to static top-right when idle ────────
                        Item {
                            id: pctLabel

                            readonly property bool floating: coreCell.cellHovered && coreCell.dotX >= 0
                            readonly property real dotGap: Math.round(6 * Config.scale)
                            readonly property bool flipLeft: coreCell.dotX > coreCell.width / 2
                            readonly property real _hPad: Math.round(4 * Config.scale)
                            readonly property real _vPad: Math.round(2 * Config.scale)

                            width: pctLabelText.implicitWidth + (floating ? _hPad * 2 : 0)
                            height: pctLabelText.implicitHeight + (floating ? _vPad * 2 : 0)

                            // When hovered: float beside the dot.  When idle: park top-right.
                            x: floating
                               ? (flipLeft
                                  ? coreCell.dotX - dotGap - width
                                  : coreCell.dotX + dotGap)
                               : parent.width - pctLabelText.implicitWidth - Math.round(5 * Config.scale)

                            y: floating
                               ? Math.max(0, Math.min(parent.height - height,
                                     coreCell.dotY - height / 2))
                               : Math.round(4 * Config.scale)

                            Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                            Behavior on y { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }

                            // Pill background — only visible when floating
                            Rectangle {
                                anchors.fill: parent
                                radius: Math.round(4 * Config.scale)
                                color: Qt.rgba(0.05, 0.04, 0.12, 0.88)
                                border.color: Qt.rgba(coreCell.barColor.r, coreCell.barColor.g, coreCell.barColor.b, 0.35)
                                border.width: 1
                                opacity: pctLabel.floating ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                            }

                            Text {
                                id: pctLabelText
                                anchors.centerIn: parent
                                text: coreCell.hoverPct + "%"
                                color: coreCell.barColor
                                font.family: Config.font.family
                                font.pixelSize: pctLabel.floating ? Config.font.sizeXl : Config.font.sizeLg
                                font.weight: Font.SemiBold

                                Behavior on font.pixelSize { NumberAnimation { duration: 80 } }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: "#cc000000"
                                    shadowBlur: 0.8
                                    shadowHorizontalOffset: 0
                                    shadowVerticalOffset: 1
                                }
                            }
                        }

                        // ── Frequency — below core index, left ────────────────
                        Text {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.topMargin: Math.round(4 * Config.scale) + Config.font.sizeSm + Math.round(2 * Config.scale)
                            anchors.leftMargin: Math.round(5 * Config.scale)
                            text: coreCell.freqText
                            color: Qt.rgba(1, 1, 1, 0.75)
                            font.family: Config.font.family
                            font.pixelSize: Config.font.sizeSm
                            visible: coreCell.freqText !== ""
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: "#cc000000"
                                shadowBlur: 0.8
                                shadowHorizontalOffset: 0
                                shadowVerticalOffset: 1
                            }
                        }

                        // ── Mouse overlay for hover/crosshair ─────────────────
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton

                            onPositionChanged: mouse => {
                                const n = coreCell.history.length;
                                if (n === 0) return;
                                const step = width / (root.historyLen - 1);
                                const xOffset = (root.historyLen - n) * step;
                                const relX = Math.max(0, Math.min(width, mouse.x - xOffset));
                                const idx = Math.max(0, Math.min(n - 1, Math.round(relX / step)));
                                coreCell.cellHovered = true;
                                coreCell.hoverIndex = idx;
                            }

                            onExited: {
                                coreCell.cellHovered = false;
                                coreCell.hoverIndex = -1;
                            }
                        }
                    }
                }
            }
        }
    }
}
