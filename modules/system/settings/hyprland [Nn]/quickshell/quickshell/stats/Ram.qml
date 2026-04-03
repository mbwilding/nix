pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io

import ".."
import "../components"

// RAM usage panel — arc gauge + sparkline history graphs.
Item {
    id: root

    // Set to false (bound to Stats.qml's visible_) to pause polling
    property bool active: true

    property real ramUsedGb:   0
    property real ramTotalGb:  0
    property real ramCachedGb: 0
    readonly property real ramPercent:    ramTotalGb > 0 ? ramUsedGb   / ramTotalGb : 0
    readonly property real cachedPercent: ramTotalGb > 0 ? ramCachedGb / ramTotalGb : 0

    readonly property color usageColor: ramPercent > 0.85 ? Config.colors.danger
                                      : ramPercent > 0.65 ? Config.colors.warning
                                      : Config.colors.accent

    // ── Ring-buffer history ───────────────────────────────────────────────────
    readonly property int historyLen: 60

    // Exposed snapshot arrays (plain JS, oldest→newest) for Canvas bindings.
    property var usedHistory:   []
    property var cachedHistory: []

    // Internal ring structs
    property var _ringUsed:   ({ buf: new Float32Array(60), head: 0, count: 0 })
    property var _ringCached: ({ buf: new Float32Array(60), head: 0, count: 0 })

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

    // ── Data ─────────────────────────────────────────────────────────────────
    property Process _ramProc: Process {
        command: ["cat", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                let total = 0, available = 0, cached = 0, buffers = 0;
                for (const line of this.text.split("\n")) {
                    if      (line.startsWith("MemTotal:"))     total     = parseInt(line.split(/\s+/)[1]) || 0;
                    else if (line.startsWith("MemAvailable:")) available = parseInt(line.split(/\s+/)[1]) || 0;
                    else if (line.startsWith("Cached:"))       cached    = parseInt(line.split(/\s+/)[1]) || 0;
                    else if (line.startsWith("Buffers:"))      buffers   = parseInt(line.split(/\s+/)[1]) || 0;
                }
                root.ramTotalGb  = total / 1048576;
                root.ramUsedGb   = (total - available) / 1048576;
                root.ramCachedGb = (cached + buffers)  / 1048576;

                root.usedHistory   = root._ringPush(root._ringUsed,   root.ramUsedGb);
                root.cachedHistory = root._ringPush(root._ringCached,  root.ramCachedGb);
            }
        }
    }

    property Timer _ramTimer: Timer {
        interval: 2000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root._ramProc.running = true
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.round(14 * Config.scale)
        spacing: Math.round(10 * Config.scale)

        // ══ Arc gauge ═════════════════════════════════════════════════════════
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Arc canvas
            Canvas {
                id: arcCanvas
                anchors.fill: parent

                readonly property real pct:      root.ramPercent
                readonly property color arcColor: root.usageColor
                onPctChanged:      requestPaint()
                onArcColorChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    const lw    = Math.round(10 * Config.scale);
                    const bleed = Math.ceil(lw * 1.5);
                    const cx    = width  / 2;
                    const cy    = height / 2;
                    const r     = Math.min(width - bleed * 2, height - bleed * 2) / 2 - Math.round(2 * Config.scale);

                    const startAngle = 210 * Math.PI / 180;
                    const endAngle   = (210 + 240) * Math.PI / 180;
                    const fillAngle  = startAngle + (arcCanvas.pct * 240 * Math.PI / 180);

                    // Track
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, startAngle, endAngle);
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.07).toString();
                    ctx.lineWidth   = lw;
                    ctx.lineCap     = "round";
                    ctx.stroke();

                    if (arcCanvas.pct <= 0) return;

                    // Glow
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, startAngle, fillAngle);
                    ctx.strokeStyle = Qt.rgba(arcCanvas.arcColor.r, arcCanvas.arcColor.g, arcCanvas.arcColor.b, 0.25).toString();
                    ctx.lineWidth   = lw * 2.5;
                    ctx.lineCap     = "round";
                    ctx.stroke();

                    // Fill
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, startAngle, fillAngle);
                    ctx.strokeStyle = arcCanvas.arcColor.toString();
                    ctx.lineWidth   = lw;
                    ctx.lineCap     = "round";
                    ctx.stroke();

                    // Tip glow dot
                    const tipX = cx + r * Math.cos(fillAngle);
                    const tipY = cy + r * Math.sin(fillAngle);
                    const grad = ctx.createRadialGradient(tipX, tipY, 0, tipX, tipY, lw * 1.8);
                    grad.addColorStop(0, Qt.rgba(arcCanvas.arcColor.r, arcCanvas.arcColor.g, arcCanvas.arcColor.b, 0.7).toString());
                    grad.addColorStop(1, "transparent");
                    ctx.beginPath();
                    ctx.arc(tipX, tipY, lw * 1.8, 0, Math.PI * 2);
                    ctx.fillStyle = grad;
                    ctx.fill();
                }
            }

            // Centre text
            ColumnLayout {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -Math.round(6 * Config.scale)
                spacing: Math.round(2 * Config.scale)

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text:           Math.round(root.ramPercent * 100) + "%"
                    color:          root.usageColor
                    font.family:    Config.font.family
                    font.pixelSize: Math.round(44 * Config.scale)
                    font.weight:    Font.Bold
                    Behavior on color { ColorAnimation { duration: 400 } }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text:           root.ramUsedGb.toFixed(1) + " / " + root.ramTotalGb.toFixed(0) + " GB"
                    color:          Config.colors.textSecondary
                    font.family:    Config.font.family
                    font.pixelSize: Config.font.sizeLg
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text:           "RAM"
                    color:          Config.colors.textMuted
                    font.family:    Config.font.family
                    font.pixelSize: Config.font.sizeMd
                    font.weight:    Font.Medium
                    opacity:        0.7
                }
            }
        }

        // ── Divider ──────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color:  Config.panelBorder.color
            opacity: 0.30
        }

        // ══ Used sparkline ════════════════════════════════════════════════════
        RamGraph {
            Layout.fillWidth: true
            height: Math.round(66 * Config.scale)
            history:    root.usedHistory
            totalGb:    root.ramTotalGb
            currentVal: root.ramUsedGb
            lineColor:  root.usageColor
            label:      "Used"
            formatFn:   function(v) { return v.toFixed(2) + " GB" }
        }

        // ── Divider ──────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color:  Config.panelBorder.color
            opacity: 0.30
        }

        // ══ Cached sparkline ══════════════════════════════════════════════════
        RamGraph {
            Layout.fillWidth: true
            height: Math.round(66 * Config.scale)
            history:    root.cachedHistory
            totalGb:    root.ramTotalGb
            currentVal: root.ramCachedGb
            lineColor:  Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.55)
            label:      "Cached"
            formatFn:   function(v) { return v.toFixed(2) + " GB" }
        }
    }

    // ── RamGraph component ────────────────────────────────────────────────────
    // Sparkline graph with a fixed 0→totalGb y-axis, hover dot + floating pill label.
    component RamGraph: Item {
        id: rg

        property var    history:    []
        property real   totalGb:    1
        property real   currentVal: 0
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
        readonly property real _step:    root.historyLen > 1 ? _gw / (root.historyLen - 1) : _gw
        readonly property real _xOffset: (root.historyLen - history.length) * _step
        readonly property real dotX: hoverIndex >= 0
            ? _pad + _xOffset + hoverIndex * _step
            : -1
        readonly property real dotY: (hoverIndex >= 0 && hoverIndex < history.length && totalGb > 0)
            ? _pad + _gh - (history[hoverIndex] / totalGb) * _gh
            : -1

        onHistoryChanged:   rgCanvas.requestPaint()
        onTotalGbChanged:   rgCanvas.requestPaint()
        onHoverIndexChanged: rgCanvas.requestPaint()
        onHoveredChanged:   rgCanvas.requestPaint()
        onLineColorChanged: rgCanvas.requestPaint()

        Canvas {
            id: rgCanvas
            anchors.fill: parent

            readonly property var   hist:   rg.history
            readonly property bool  hov:    rg.hovered
            readonly property int   hovIdx: rg.hoverIndex
            readonly property color lc:     rg.lineColor
            readonly property real  total:  rg.totalGb

            onHistChanged:   requestPaint()
            onHovChanged:    requestPaint()
            onHovIdxChanged: requestPaint()
            onLcChanged:     requestPaint()
            onTotalChanged:  requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                const buf = hist;
                const n   = buf ? buf.length : 0;
                if (n < 2 || total <= 0) return;

                const pad  = Math.round(4 * Config.scale);
                const w    = width  - pad * 2;
                const h    = height - pad * 2;
                const step = (root.historyLen - 1) > 0 ? w / (root.historyLen - 1) : w;
                const xOff = (root.historyLen - n) * step;

                // Grid lines at 25 / 50 / 75% of total
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.06).toString();
                ctx.lineWidth   = 1;
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
                        y: pad + h - (buf[i] / total) * h
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

        // Direction tag — top-left, fixed
        Text {
            id: rgDirTag
            anchors.left:    parent.left
            anchors.top:     parent.top
            anchors.margins: Math.round(6 * Config.scale)
            text:            rg.label
            color:           rg.lineColor
            font.family:     Config.font.family
            font.pixelSize:  Config.font.sizeLg
            font.weight:     Font.Bold
            opacity:         0.85
            Behavior on color { ColorAnimation { duration: 400 } }
        }

        // Floating value label — rests below tag when idle, floats beside dot when hovered
        Item {
            id: rgValLabel

            readonly property bool floating: rg.hovered && rg.dotX >= 0
            readonly property real _restX:   rgDirTag.x
            readonly property real _restY:   rgDirTag.y + rgDirTag.implicitHeight + Math.round(2 * Config.scale)
            readonly property real dotGap:   Math.round(6 * Config.scale)
            readonly property bool flipLeft: rg.dotX > rg.width / 2
            readonly property real _hPad:    Math.round(6 * Config.scale)
            readonly property real _vPad:    Math.round(3 * Config.scale)

            width:  rgValText.implicitWidth  + (floating ? _hPad * 2 : 0)
            height: rgValText.implicitHeight + (floating ? _vPad * 2 : 0)

            x: floating
               ? (flipLeft
                  ? rg.dotX - dotGap - width
                  : rg.dotX + dotGap)
               : _restX

            y: floating
               ? Math.max(0, Math.min(rg.height - height, rg.dotY - height / 2))
               : _restY

            Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }

            // Pill background
            Rectangle {
                anchors.fill:  parent
                radius:        Math.round(5 * Config.scale)
                color:         Qt.rgba(0.05, 0.04, 0.12, 0.88)
                border.color:  Qt.rgba(rg.lineColor.r, rg.lineColor.g, rg.lineColor.b, 0.35)
                border.width:  1
                opacity:       rgValLabel.floating ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            Text {
                id: rgValText
                anchors.centerIn: parent
                text: rg.formatFn
                      ? rg.formatFn(rg.hovered && rg.hoverIndex >= 0 ? rg.hoverVal : rg.currentVal)
                      : ""
                color:          rg.lineColor
                font.family:    Config.font.family
                font.pixelSize: rgValLabel.floating ? Config.font.sizeXl : Config.font.sizeLg
                font.weight:    Font.Bold
                Behavior on font.pixelSize { NumberAnimation { duration: 80 } }
                Behavior on color { ColorAnimation { duration: 200 } }

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

        // Mouse handler
        MouseArea {
            anchors.fill:    parent
            hoverEnabled:    true
            acceptedButtons: Qt.NoButton

            onPositionChanged: mouse => {
                const n = rg.history.length;
                if (n === 0) return;
                const pad  = Math.round(4 * Config.scale);
                const gw   = width - pad * 2;
                const step = gw / (root.historyLen - 1);
                const xOff = (root.historyLen - n) * step;
                const relX = Math.max(0, Math.min(gw, mouse.x - pad - xOff));
                rg.hovered    = true;
                rg.hoverIndex = Math.max(0, Math.min(n - 1, Math.round(relX / step)));
            }
            onExited: {
                rg.hovered    = false;
                rg.hoverIndex = -1;
            }
        }
    }
}
