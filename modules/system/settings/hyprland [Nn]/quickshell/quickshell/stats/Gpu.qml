pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io

import ".."
import "../components"

// AMD GPU stats page — utilization, clocks, VRAM, temp, power, state.
Item {
    id: root

    // Set to false (bound to Stats.qml's visible_) to pause polling
    property bool active: true

    // ── Raw data ──────────────────────────────────────────────────────────────
    property int gpuPercent: 0
    property int vcnPercent: 0
    property real vramUsedBytes: 0
    property real vramTotalBytes: 0
    property int sclkHz: 0      // precise core clock from hwmon
    property int mclkMhz: 0      // active memory clock from pp_dpm_mclk
    property int tempMilliC: 0
    property real powerUw: 0      // microwatts
    property string perfLevel: ""     // power_dpm_force_performance_level
    property string dpmState: ""     // power_dpm_state
    property string pciState: ""     // power_state (D0/D3/…)

    // ── Derived ───────────────────────────────────────────────────────────────
    readonly property int tempC: Math.round(root.tempMilliC / 1000)
    readonly property real powerW: root.powerUw / 1000000
    readonly property real vramUsedGb: root.vramUsedBytes / 1073741824
    readonly property real vramTotalGb: root.vramTotalBytes / 1073741824
    readonly property real vramFrac: root.vramTotalBytes > 0 ? root.vramUsedBytes / root.vramTotalBytes : 0
    readonly property string sclkText: root.sclkHz > 0 ? (root.sclkHz / 1000000).toFixed(0) + " MHz" : "—"
    readonly property string mclkText: root.mclkMhz > 0 ? root.mclkMhz + " MHz" : "—"

    // ── Ring-buffer history ───────────────────────────────────────────────────
    readonly property int historyLen: 60

    // Exposed snapshot arrays (plain JS, oldest→newest) for Canvas bindings.
    property var gpuHistory:   []
    property var vramHistory:  []
    property var tempHistory:  []
    property var powerHistory: []
    property var sclkHistory:  []
    property var mclkHistory:  []
    property var vcnHistory:   []

    // Internal ring structs — one per metric.
    property var _ringGpu:   ({ buf: new Float32Array(60), head: 0, count: 0 })
    property var _ringVram:  ({ buf: new Float32Array(60), head: 0, count: 0 })
    property var _ringTemp:  ({ buf: new Float32Array(60), head: 0, count: 0 })
    property var _ringPower: ({ buf: new Float32Array(60), head: 0, count: 0 })
    property var _ringSclk:  ({ buf: new Float32Array(60), head: 0, count: 0 })
    property var _ringMclk:  ({ buf: new Float32Array(60), head: 0, count: 0 })
    property var _ringVcn:   ({ buf: new Float32Array(60), head: 0, count: 0 })

    // Push a value into a ring and return an ordered JS array snapshot (oldest→newest).
    function _ringPush(ring, val) {
        ring.buf[ring.head] = val;
        ring.head = (ring.head + 1) % root.historyLen;
        if (ring.count < root.historyLen) ring.count++;
        const snap = [];
        const start = ring.count < root.historyLen ? 0 : ring.head;
        for (let i = 0; i < ring.count; i++)
            snap.push(ring.buf[(start + i) % root.historyLen]);
        return snap;
    }

    // ── Colours ───────────────────────────────────────────────────────────────
    readonly property color gpuColor: root.gpuPercent > 85 ? Config.colors.danger : root.gpuPercent > 55 ? Config.colors.warning : Config.colors.accent

    readonly property color vramColor: root.vramFrac > 0.85 ? Config.colors.danger : root.vramFrac > 0.65 ? Config.colors.warning : Config.colors.accent

    readonly property color tempColor: root.tempC >= 90 ? Config.colors.danger : root.tempC >= 70 ? Config.colors.warning : Config.colors.accent

    readonly property color powerColor: root.powerW >= 35 ? Config.colors.danger : root.powerW >= 20 ? Config.colors.warning : Config.colors.accent

    readonly property color perfLevelColor: root.perfLevel === "high" ? Config.colors.danger : root.perfLevel === "low" ? Config.colors.textMuted : root.perfLevel === "manual" ? Config.colors.warning : Config.colors.accent

    readonly property color dpmStateColor: root.dpmState === "performance" ? Config.colors.accentAlt : root.dpmState === "battery" ? Config.colors.textMuted : Config.colors.accent

    // ── Processes ─────────────────────────────────────────────────────────────
    property Process _utilProc: Process {
        command: ["cat", "/sys/class/drm/card1/device/gpu_busy_percent", "/sys/class/drm/card1/device/vcn_busy_percent"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                root.gpuPercent = parseInt(lines[0]) || 0;
                root.vcnPercent = parseInt(lines[1]) || 0;
                root.gpuHistory = root._ringPush(root._ringGpu, root.gpuPercent);
                root.vcnHistory = root._ringPush(root._ringVcn, root.vcnPercent);
            }
        }
    }

    property Process _vramProc: Process {
        command: ["cat", "/sys/class/drm/card1/device/mem_info_vram_used", "/sys/class/drm/card1/device/mem_info_vram_total"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                root.vramUsedBytes  = parseFloat(lines[0]) || 0;
                root.vramTotalBytes = parseFloat(lines[1]) || 0;
                root.vramHistory = root._ringPush(root._ringVram, root.vramFrac);
            }
        }
    }

    property Process _hwmonProc: Process {
        command: ["sh", "-c", "cat /sys/class/hwmon/hwmon7/freq1_input " + "/sys/class/hwmon/hwmon7/temp1_input " + "/sys/class/hwmon/hwmon7/power1_input 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                root.sclkHz     = parseInt(lines[0])   || 0;
                root.tempMilliC = parseInt(lines[1])   || 0;
                root.powerUw    = parseFloat(lines[2]) || 0;
                root.tempHistory  = root._ringPush(root._ringTemp,  root.tempC);
                root.powerHistory = root._ringPush(root._ringPower, root.powerW);
                root.sclkHistory  = root._ringPush(root._ringSclk,  root.sclkHz > 0 ? root.sclkHz / 1000000 : 0);
            }
        }
    }

    property Process _mclkProc: Process {
        command: ["cat", "/sys/class/drm/card1/device/pp_dpm_mclk"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of this.text.split("\n")) {
                    if (line.includes("*")) {
                        const m = line.match(/(\d+)Mhz/);
                        if (m) {
                            root.mclkMhz = parseInt(m[1]);
                            root.mclkHistory = root._ringPush(root._ringMclk, root.mclkMhz);
                            break;
                        }
                    }
                }
            }
        }
    }

    property Process _stateProc: Process {
        command: ["sh", "-c", "cat /sys/class/drm/card1/device/power_dpm_force_performance_level " + "/sys/class/drm/card1/device/power_dpm_state " + "/sys/class/drm/card1/device/power_state 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                root.perfLevel = (lines[0] || "").trim();
                root.dpmState  = (lines[1] || "").trim();
                root.pciState  = (lines[2] || "").trim();
            }
        }
    }

    property Timer _timer: Timer {
        interval: 2000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: {
            root._utilProc.running = true;
            root._vramProc.running = true;
            root._hwmonProc.running = true;
            root._mclkProc.running = true;
            root._stateProc.running = true;
        }
    }

    // ── Sizing helpers ────────────────────────────────────────────────────────
    readonly property int pad:   Math.round(14 * Config.scale)
    readonly property int gap:   Math.round(8  * Config.scale)
    readonly property int cardR: Math.round(10 * Config.scale)

    // ── Layout ────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: root.gap

        // ══ Header: GPU% · state · temp ══════════════════════════════════════
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(5 * Config.scale)

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * Config.scale)

                Text {
                    text: "GPU"
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeMd
                    font.weight: Font.Medium
                }
                Text {
                    text: root.gpuPercent + "%"
                    color: root.gpuColor
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeMd
                    font.weight: Font.Medium
                    Behavior on color { ColorAnimation { duration: 400 } }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.dpmState
                    color: root.dpmStateColor
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeMd
                    font.capitalization: Font.Capitalize
                    visible: root.dpmState !== ""
                    Behavior on color { ColorAnimation { duration: 400 } }
                }
                Text {
                    text: "·"
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeMd
                    visible: root.dpmState !== "" && root.perfLevel !== ""
                }
                Text {
                    text: root.perfLevel
                    color: root.perfLevelColor
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeMd
                    font.capitalization: Font.Capitalize
                    visible: root.perfLevel !== ""
                    Behavior on color { ColorAnimation { duration: 400 } }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.tempC + "°C"
                    color: root.tempColor
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeMd
                    font.weight: Font.Medium
                    visible: root.tempC > 0
                    Behavior on color { ColorAnimation { duration: 400 } }
                }
            }

            // ── GPU utilisation sparkline ─────────────────────────────────────
            SparkGraph {
                id: gpuGraph
                Layout.fillWidth: true
                height: Math.round(52 * Config.scale)
                history: root.gpuHistory
                maxHistory: root.historyLen
                currentVal: root.gpuPercent
                peak: 100
                lineColor: root.gpuColor
                label: "GPU"
                formatFn: function(v) { return Math.round(v) + "%" }
            }
        }

        // ── Divider ──────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Config.panelBorder.color
            opacity: 0.30
        }

        // ══ Metric cards — 2×2 grid, fills available height ══════════════════
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            columnSpacing: root.gap
            rowSpacing: root.gap

            MetricCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                label: "Core Clock"
                value: root.sclkText
                valueColor: Config.colors.accentAlt
                history: root.sclkHistory
                maxHistory: root.historyLen
                formatFn: function(v) { return v > 0 ? v.toFixed(0) + " MHz" : "—" }
            }
            MetricCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                label: "Mem Clock"
                value: root.mclkText
                valueColor: Config.colors.accent
                history: root.mclkHistory
                maxHistory: root.historyLen
                formatFn: function(v) { return v > 0 ? Math.round(v) + " MHz" : "—" }
            }
            MetricCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                label: "Power"
                value: root.powerUw > 0 ? root.powerW.toFixed(1) + " W" : "—"
                valueColor: root.powerColor
                history: root.powerHistory
                maxHistory: root.historyLen
                formatFn: function(v) { return v > 0 ? v.toFixed(1) + " W" : "—" }
            }
            MetricCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                label: "VCN"
                value: root.vcnPercent + "%"
                valueColor: root.vcnPercent > 60 ? Config.colors.warning : Config.colors.textSecondary
                history: root.vcnHistory
                maxHistory: root.historyLen
                formatFn: function(v) { return Math.round(v) + "%" }
            }
        }

        // ── Divider ──────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Config.panelBorder.color
            opacity: 0.30
        }

        // ══ VRAM ══════════════════════════════════════════════════════════════
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(5 * Config.scale)

            // Label row: VRAM XX% · used/total · PCI pill
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * Config.scale)

                Text {
                    text: "VRAM"
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeMd
                    font.weight: Font.Medium
                }
                Text {
                    text: Math.round(root.vramFrac * 100) + "%"
                    color: root.vramColor
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeMd
                    font.weight: Font.Medium
                    Behavior on color { ColorAnimation { duration: 400 } }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.vramUsedGb.toFixed(2) + " / " + root.vramTotalGb.toFixed(1) + " GB"
                    color: Config.colors.textSecondary
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeMd
                }

                // PCI state pill tucked right
                Rectangle {
                    height: Math.round(18 * Config.scale)
                    width: pciLabel.implicitWidth + Math.round(12 * Config.scale)
                    radius: height / 2
                    color: root.pciState === "D0" ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.15) : Qt.rgba(Config.colors.textMuted.r, Config.colors.textMuted.g, Config.colors.textMuted.b, 0.12)
                    border.color: root.pciState === "D0" ? Config.colors.accent : Config.colors.textMuted
                    border.width: 1
                    visible: root.pciState !== ""

                    Text {
                        id: pciLabel
                        anchors.centerIn: parent
                        text: root.pciState
                        color: root.pciState === "D0" ? Config.colors.accent : Config.colors.textMuted
                        font.family: Config.font.family
                        font.pixelSize: Config.font.sizeSm
                        font.weight: Font.Medium
                    }
                }
            }

            // ── VRAM sparkline ────────────────────────────────────────────────
            SparkGraph {
                id: vramGraph
                Layout.fillWidth: true
                height: Math.round(52 * Config.scale)
                history: root.vramHistory
                maxHistory: root.historyLen
                currentVal: root.vramFrac
                peak: 1
                lineColor: root.vramColor
                label: "VRAM"
                formatFn: function(v) { return Math.round(v * 100) + "%" }
            }
        }
    }

    // ── SparkGraph component ──────────────────────────────────────────────────
    // A full-width canvas sparkline with hover crosshair + floating pill label.
    component SparkGraph: Item {
        id: sg

        property var    history:    []
        property int    maxHistory: 60
        property real   currentVal: 0
        property real   peak:       100
        property color  lineColor:  Config.colors.accent
        property string label:      ""
        property var    formatFn:   null

        // Internal hover state
        property bool hovered:    false
        property int  hoverIndex: -1

        readonly property real hoverVal: (hoverIndex >= 0 && hoverIndex < history.length) ? history[hoverIndex] : currentVal

        // Dot position mirrors canvas paint formula
        readonly property real _pad:     Math.round(4 * Config.scale)
        readonly property real _gw:      width  - _pad * 2
        readonly property real _gh:      height - _pad * 2
        readonly property real _step:    maxHistory > 1 ? _gw / (maxHistory - 1) : _gw
        readonly property real _xOffset: (maxHistory - history.length) * _step
        readonly property real dotX: hoverIndex >= 0
            ? _pad + _xOffset + hoverIndex * _step
            : -1
        readonly property real dotY: (hoverIndex >= 0 && hoverIndex < history.length && peak > 0)
            ? _pad + _gh - (history[hoverIndex] / peak) * _gh
            : -1

        onHistoryChanged:    canvas.requestPaint()
        onPeakChanged:       canvas.requestPaint()
        onHoverIndexChanged: canvas.requestPaint()
        onHoveredChanged:    canvas.requestPaint()
        onLineColorChanged:  canvas.requestPaint()

        Canvas {
            id: canvas
            anchors.fill: parent

            readonly property var    hist:   sg.history
            readonly property bool   hov:    sg.hovered
            readonly property int    hovIdx: sg.hoverIndex
            readonly property color  lc:     sg.lineColor
            readonly property real   pk:     sg.peak

            onHistChanged:   requestPaint()
            onHovChanged:    requestPaint()
            onHovIdxChanged: requestPaint()
            onLcChanged:     requestPaint()
            onPkChanged:     requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                const buf = hist;
                const n   = buf ? buf.length : 0;
                if (n < 2) return;

                const pad  = Math.round(4 * Config.scale);
                const w    = width  - pad * 2;
                const h    = height - pad * 2;
                const step = (sg.maxHistory - 1) > 0 ? w / (sg.maxHistory - 1) : w;
                const xOff = (sg.maxHistory - n) * step;
                const peak = pk > 0 ? pk : 1;

                // Grid lines at 25 / 50 / 75%
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.06).toString();
                ctx.lineWidth = 1;
                ctx.setLineDash([]);
                for (let g = 1; g <= 3; g++) {
                    const gy = pad + h * (1 - g / 4);
                    ctx.beginPath();
                    ctx.moveTo(pad, gy);
                    ctx.lineTo(pad + w, gy);
                    ctx.stroke();
                }

                // Build points
                const pts = [];
                for (let i = 0; i < n; i++) {
                    pts.push({
                        x: pad + xOff + i * step,
                        y: pad + h - (buf[i] / peak) * h
                    });
                }

                // Filled area
                ctx.beginPath();
                ctx.moveTo(pts[0].x, pad + h);
                ctx.lineTo(pts[0].x, pts[0].y);
                for (let i = 1; i < n; i++) {
                    const cpx = (pts[i-1].x + pts[i].x) / 2;
                    ctx.bezierCurveTo(cpx, pts[i-1].y, cpx, pts[i].y, pts[i].x, pts[i].y);
                }
                ctx.lineTo(pts[n-1].x, pad + h);
                ctx.closePath();
                ctx.fillStyle = Qt.rgba(lc.r, lc.g, lc.b, 0.18).toString();
                ctx.fill();

                // Line
                ctx.beginPath();
                ctx.moveTo(pts[0].x, pts[0].y);
                for (let i = 1; i < n; i++) {
                    const cpx = (pts[i-1].x + pts[i].x) / 2;
                    ctx.bezierCurveTo(cpx, pts[i-1].y, cpx, pts[i].y, pts[i].x, pts[i].y);
                }
                ctx.strokeStyle = Qt.rgba(lc.r, lc.g, lc.b, 0.85).toString();
                ctx.lineWidth   = Math.round(1.5 * Config.scale);
                ctx.lineJoin    = "round";
                ctx.setLineDash([]);
                ctx.stroke();

                // Crosshair + dot on hover
                if (hov && hovIdx >= 0 && hovIdx < n) {
                    const hx = pts[hovIdx].x;
                    const hy = pts[hovIdx].y;

                    ctx.beginPath();
                    ctx.moveTo(hx, pad);
                    ctx.lineTo(hx, pad + h);
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.25).toString();
                    ctx.lineWidth   = 1;
                    ctx.setLineDash([Math.round(3 * Config.scale), Math.round(3 * Config.scale)]);
                    ctx.stroke();
                    ctx.setLineDash([]);

                    ctx.beginPath();
                    ctx.arc(hx, hy, Math.round(3.5 * Config.scale), 0, Math.PI * 2);
                    ctx.fillStyle   = lc.toString();
                    ctx.fill();
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.80).toString();
                    ctx.lineWidth   = Math.round(1.5 * Config.scale);
                    ctx.stroke();
                }
            }
        }

        // Direction tag — top-left, always fixed
        Text {
            id: sgDirTag
            anchors.left:    parent.left
            anchors.top:     parent.top
            anchors.margins: Math.round(6 * Config.scale)
            text:            sg.label
            color:           sg.lineColor
            font.family:     Config.font.family
            font.pixelSize:  Config.font.sizeLg
            font.weight:     Font.Bold
            opacity:         0.85
            Behavior on color { ColorAnimation { duration: 400 } }
        }

        // Floating rate label — rests below tag when idle, floats beside dot when hovered
        Item {
            id: sgRateLabel

            readonly property bool floating: sg.hovered && sg.dotX >= 0
            readonly property real _restX:   sgDirTag.x
            readonly property real _restY:   sgDirTag.y + sgDirTag.implicitHeight + Math.round(2 * Config.scale)
            readonly property real dotGap:   Math.round(6 * Config.scale)
            readonly property bool flipLeft: sg.dotX > sg.width / 2
            readonly property real _hPad:    Math.round(6 * Config.scale)
            readonly property real _vPad:    Math.round(3 * Config.scale)

            width:  sgRateLabelText.implicitWidth  + (floating ? _hPad * 2 : 0)
            height: sgRateLabelText.implicitHeight + (floating ? _vPad * 2 : 0)

            x: floating
               ? (flipLeft
                  ? sg.dotX - dotGap - width
                  : sg.dotX + dotGap)
               : _restX

            y: floating
               ? Math.max(0, Math.min(sg.height - height, sg.dotY - height / 2))
               : _restY

            Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }

            // Pill background
            Rectangle {
                anchors.fill:   parent
                radius:         Math.round(5 * Config.scale)
                color:          Qt.rgba(0.05, 0.04, 0.12, 0.88)
                border.color:   Qt.rgba(sg.lineColor.r, sg.lineColor.g, sg.lineColor.b, 0.35)
                border.width:   1
                opacity:        sgRateLabel.floating ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            Text {
                id: sgRateLabelText
                anchors.centerIn: parent
                text: sg.formatFn
                      ? sg.formatFn(sg.hovered && sg.hoverIndex >= 0 ? sg.hoverVal : sg.currentVal)
                      : ""
                color:           sg.lineColor
                font.family:     Config.font.family
                font.pixelSize:  sgRateLabel.floating ? Config.font.sizeXl : Config.font.sizeLg
                font.weight:     Font.Bold
                Behavior on font.pixelSize { NumberAnimation { duration: 80 } }
                Behavior on color { ColorAnimation { duration: 200 } }

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled:        true
                    shadowColor:          "#ee000000"
                    shadowBlur:           1.0
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 2
                }
            }
        }

        // ── Mouse handler ─────────────────────────────────────────────────────
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton

            onPositionChanged: mouse => {
                const n = sg.history.length;
                if (n === 0) return;
                const pad  = Math.round(4 * Config.scale);
                const gw   = width - pad * 2;
                const step = gw / (sg.maxHistory - 1);
                const xOff = (sg.maxHistory - n) * step;
                const relX = Math.max(0, Math.min(gw, mouse.x - pad - xOff));
                sg.hovered    = true;
                sg.hoverIndex = Math.max(0, Math.min(n - 1, Math.round(relX / step)));
            }
            onExited: {
                sg.hovered    = false;
                sg.hoverIndex = -1;
            }
        }
    }

    // ── MetricCard ────────────────────────────────────────────────────────────
    component MetricCard: Rectangle {
        id: card
        property string label:      ""
        property string value:      "—"
        property color  valueColor: Config.colors.accent
        property var    history:    []
        property int    maxHistory: 60
        property var    formatFn:   null

        // Internal hover state
        property bool hovered:    false
        property int  hoverIndex: -1

        readonly property real hoverVal: (hoverIndex >= 0 && hoverIndex < history.length) ? history[hoverIndex] : 0

        radius: root.cardR
        color:  Config.colors.surfaceAlt
        border.color: Qt.rgba(card.valueColor.r, card.valueColor.g, card.valueColor.b, 0.20)
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: 400 } }

        // ── Sparkline canvas ─────────────────────────────────────────────────
        Canvas {
            id: cardCanvas
            anchors.fill:    parent
            anchors.margins: Math.round(2 * Config.scale)

            readonly property var   hist:   card.history
            readonly property bool  hov:    card.hovered
            readonly property int   hovIdx: card.hoverIndex
            readonly property color lc:     card.valueColor

            onHistChanged:   requestPaint()
            onHovChanged:    requestPaint()
            onHovIdxChanged: requestPaint()
            onLcChanged:     requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                const buf = hist;
                const n   = buf ? buf.length : 0;
                if (n < 2) return;

                const w    = width;
                const h    = height;
                const step = (card.maxHistory - 1) > 0 ? w / (card.maxHistory - 1) : w;
                const xOff = (card.maxHistory - n) * step;

                // Find value range for auto-scaling
                let lo = buf[0], hi = buf[0];
                for (let i = 1; i < n; i++) {
                    if (buf[i] < lo) lo = buf[i];
                    if (buf[i] > hi) hi = buf[i];
                }
                const range = hi - lo > 0 ? hi - lo : 1;
                const expand = range * 0.15;
                const yMin = lo - expand;
                const yMax = hi + expand;
                const yRange = yMax - yMin;

                function py(v) { return h - ((v - yMin) / yRange) * h; }

                // Build points
                const pts = [];
                for (let i = 0; i < n; i++) {
                    pts.push({ x: xOff + i * step, y: py(buf[i]) });
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
                ctx.fillStyle = Qt.rgba(lc.r, lc.g, lc.b, 0.10).toString();
                ctx.fill();

                // Line
                ctx.beginPath();
                ctx.moveTo(pts[0].x, pts[0].y);
                for (let i = 1; i < n; i++) {
                    const cpx = (pts[i-1].x + pts[i].x) / 2;
                    ctx.bezierCurveTo(cpx, pts[i-1].y, cpx, pts[i].y, pts[i].x, pts[i].y);
                }
                ctx.strokeStyle = Qt.rgba(lc.r, lc.g, lc.b, 0.40).toString();
                ctx.lineWidth   = Math.round(1.5 * Config.scale);
                ctx.lineJoin    = "round";
                ctx.setLineDash([]);
                ctx.stroke();

                // Crosshair + dot on hover
                if (hov && hovIdx >= 0 && hovIdx < n) {
                    const hx = pts[hovIdx].x;
                    const hy = pts[hovIdx].y;

                    ctx.beginPath();
                    ctx.moveTo(hx, 0);
                    ctx.lineTo(hx, h);
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.20).toString();
                    ctx.lineWidth   = 1;
                    ctx.setLineDash([Math.round(3 * Config.scale), Math.round(3 * Config.scale)]);
                    ctx.stroke();
                    ctx.setLineDash([]);

                    ctx.beginPath();
                    ctx.arc(hx, hy, Math.round(3.5 * Config.scale), 0, Math.PI * 2);
                    ctx.fillStyle   = lc.toString();
                    ctx.fill();
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.80).toString();
                    ctx.lineWidth   = Math.round(1.5 * Config.scale);
                    ctx.stroke();
                }
            }
        }

        // ── Dot position (mirrors cardCanvas formula) ─────────────────────────
        readonly property real _cw:      width  - Math.round(2 * Config.scale) * 2
        readonly property real _ch:      height - Math.round(2 * Config.scale) * 2
        readonly property real _step:    maxHistory > 1 ? _cw / (maxHistory - 1) : _cw
        readonly property real _xOff:    (maxHistory - history.length) * _step
        readonly property real _cardMargin: Math.round(2 * Config.scale)

        // Compute y using same auto-scale as canvas
        readonly property real _histLo: {
            let lo = history.length > 0 ? history[0] : 0;
            for (let i = 1; i < history.length; i++) if (history[i] < lo) lo = history[i];
            return lo;
        }
        readonly property real _histHi: {
            let hi = history.length > 0 ? history[0] : 1;
            for (let i = 1; i < history.length; i++) if (history[i] > hi) hi = history[i];
            return hi;
        }
        readonly property real _yRange: {
            const range = _histHi - _histLo > 0 ? _histHi - _histLo : 1;
            const exp   = range * 0.15;
            return (_histHi + exp) - (_histLo - exp);
        }
        readonly property real _yMin: _histLo - (_histHi - _histLo > 0 ? (_histHi - _histLo) * 0.15 : 0.15);

        readonly property real dotX: (hovered && hoverIndex >= 0 && hoverIndex < history.length)
            ? _cardMargin + _xOff + hoverIndex * _step
            : -1
        readonly property real dotY: (hovered && hoverIndex >= 0 && hoverIndex < history.length && _yRange > 0)
            ? _cardMargin + _ch - ((history[hoverIndex] - _yMin) / _yRange) * _ch
            : -1

        // ── Value label — floats beside dot, parks centre when idle ───────────
        Item {
            id: cardValLabel

            readonly property bool floating: card.hovered && card.dotX >= 0
            readonly property real dotGap:   Math.round(6 * Config.scale)
            readonly property bool flipLeft:  card.dotX > card.width / 2
            readonly property real _hPad:    Math.round(5 * Config.scale)
            readonly property real _vPad:    Math.round(2 * Config.scale)

            width:  cardValText.implicitWidth  + (floating ? _hPad * 2 : 0)
            height: cardValText.implicitHeight + (floating ? _vPad * 2 : 0)

            x: floating
               ? (flipLeft
                  ? card.dotX - dotGap - width
                  : card.dotX + dotGap)
               : (card.width - cardValText.implicitWidth) / 2

            y: floating
               ? Math.max(0, Math.min(card.height - height, card.dotY - height / 2))
               : (card.height - cardValText.implicitHeight) / 2 - Math.round(10 * Config.scale)

            Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }

            // Pill background
            Rectangle {
                anchors.fill:  parent
                radius:        Math.round(5 * Config.scale)
                color:         Qt.rgba(0.05, 0.04, 0.12, 0.88)
                border.color:  Qt.rgba(card.valueColor.r, card.valueColor.g, card.valueColor.b, 0.35)
                border.width:  1
                opacity:       cardValLabel.floating ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            Text {
                id: cardValText
                anchors.centerIn: parent
                text: card.formatFn && card.hovered && card.hoverIndex >= 0
                      ? card.formatFn(card.hoverVal)
                      : card.value
                color:          card.valueColor
                font.family:    Config.font.family
                font.pixelSize: cardValLabel.floating ? Config.font.sizeXl : Config.font.sizeXxxl
                font.weight:    Font.SemiBold
                Behavior on font.pixelSize { NumberAnimation { duration: 80 } }
                Behavior on color { ColorAnimation { duration: 400 } }

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled:          true
                    shadowColor:            "#ee000000"
                    shadowBlur:             1.0
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset:   2
                }
            }
        }

        // ── Sub-label — bottom centre, hides when floating ────────────────────
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom:           parent.bottom
            anchors.bottomMargin:     Math.round(8 * Config.scale)
            text:           card.label
            color:          Config.colors.textMuted
            font.family:    Config.font.family
            font.pixelSize: Config.font.sizeLg
            opacity:        cardValLabel.floating ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        // ── Mouse handler ─────────────────────────────────────────────────────
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton

            onPositionChanged: mouse => {
                const n = card.history.length;
                if (n === 0) return;
                const margin = Math.round(2 * Config.scale);
                const cw   = card.width - margin * 2;
                const step = cw / (card.maxHistory - 1);
                const xOff = (card.maxHistory - n) * step;
                const relX = Math.max(0, Math.min(cw, mouse.x - margin - xOff));
                card.hovered    = true;
                card.hoverIndex = Math.max(0, Math.min(n - 1, Math.round(relX / step)));
            }
            onExited: {
                card.hovered    = false;
                card.hoverIndex = -1;
            }
        }
    }
}
