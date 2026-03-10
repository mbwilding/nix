pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io

import ".."

// Network history graphs for the stats drawer.
// Two Canvas graphs stacked vertically — download (accent) and upload (accentAlt).
// Mouse tracking is shared: hovering either graph shows the crosshair on both.
Item {
    id: root

    // Set to false (bound to Stats.qml's visible_) to pause polling
    property bool active: true

    // ── Data collection ───────────────────────────────────────────────────────

    readonly property int historyLen: 60   // samples to keep
    readonly property int interval: 1000   // ms between samples

    // Exposed snapshot arrays (plain JS, oldest→newest) for Canvas bindings.
    property var rxHistory: []
    property var txHistory: []

    property real rxBytesPerSec: 0
    property real txBytesPerSec: 0

    property var _prevRx: null
    property var _prevTx: null
    property var _prevTime: null

    // Internal ring structs
    property var _ringRx: ({ buf: new Float64Array(60), head: 0, count: 0 })
    property var _ringTx: ({ buf: new Float64Array(60), head: 0, count: 0 })

    // Push a value into a ring and return an ordered JS array snapshot (oldest→newest).
    // Float64Array is used for network rates which can exceed Float32 precision at high speeds.
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

    // ── Shared hover state (drives both graphs simultaneously) ────────────────
    property bool sharedHovered: false
    property int sharedHoverIndex: -1

    // ── Shared y-axis peak (so both graphs use identical scale) ───────────────
    readonly property real sharedPeak: {
        let peak = 1024;
        const rx = root.rxHistory;
        const tx = root.txHistory;
        for (let i = 0; i < rx.length; i++) if (rx[i] > peak) peak = rx[i];
        for (let i = 0; i < tx.length; i++) if (tx[i] > peak) peak = tx[i];
        return peak * 1.10;
    }

    function _sumInterface(text, col) {
        let total = 0;
        for (const line of text.split("\n")) {
            const trimmed = line.trim();
            if (!trimmed || trimmed.startsWith("Inter") || trimmed.startsWith("face"))
                continue;
            const parts = trimmed.split(/\s+/);
            if (parts[0].replace(":", "") === "lo")
                continue;
            total += parseInt(parts[col]) || 0;
        }
        return total;
    }

    function formatSpeed(bps) {
        if (bps >= 1048576)
            return (bps / 1048576).toFixed(2) + " MB/s";
        if (bps >= 1024)
            return (bps / 1024).toFixed(1) + " KB/s";
        return Math.round(bps) + " B/s";
    }

    property Process _netProc: Process {
        command: ["cat", "/proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                const now = Date.now();
                const rx = root._sumInterface(this.text, 1);
                const tx = root._sumInterface(this.text, 9);
                if (root._prevRx !== null && root._prevTime !== null) {
                    const dt = (now - root._prevTime) / 1000;
                    if (dt > 0) {
                        const rxRate = Math.max(0, (rx - root._prevRx) / dt);
                        const txRate = Math.max(0, (tx - root._prevTx) / dt);
                        root.rxBytesPerSec = rxRate;
                        root.txBytesPerSec = txRate;
                        root.rxHistory = root._ringPush(root._ringRx, rxRate);
                        root.txHistory = root._ringPush(root._ringTx, txRate);
                    }
                }
                root._prevRx = rx;
                root._prevTx = tx;
                root._prevTime = now;
            }
        }
    }

    property Timer _netTimer: Timer {
        interval: root.interval
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root._netProc.running = true
    }

    // ── Layout ────────────────────────────────────────────────────────────────

    ColumnLayout {
        id: graphColumn
        anchors.fill: parent
        spacing: 0

        // ── Upload graph ──────────────────────────────────────────────────────
        NetworkGraph {
            Layout.fillWidth: true
            Layout.fillHeight: true
            history: root.txHistory
            maxHistory: root.historyLen
            currentRate: root.txBytesPerSec
            sharedPeak: root.sharedPeak
            lineColor: Config.colors.accentAlt
            fillColor: Qt.rgba(Config.colors.accentAlt.r, Config.colors.accentAlt.g, Config.colors.accentAlt.b, 0.18)
            label: "UP"
            formatFn: root.formatSpeed
            hovered: root.sharedHovered
            hoverIndex: root.sharedHoverIndex
        }

        // ── Divider ───────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: Config.panelBorder.width
            color: Config.panelBorder.color
        }

        // ── Download graph ────────────────────────────────────────────────────
        NetworkGraph {
            Layout.fillWidth: true
            Layout.fillHeight: true
            history: root.rxHistory
            maxHistory: root.historyLen
            currentRate: root.rxBytesPerSec
            sharedPeak: root.sharedPeak
            lineColor: Config.colors.accent
            fillColor: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18)
            label: "DOWN"
            formatFn: root.formatSpeed
            hovered: root.sharedHovered
            hoverIndex: root.sharedHoverIndex
        }
    }

    // ── Shared mouse overlay (sits above both graphs, full column area) ────────
    MouseArea {
        anchors.fill: graphColumn
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        onPositionChanged: mouse => {
            // Map x into a history index using the graph geometry.
            // Both graphs have the same width and maxHistory so one calculation serves both.
            const pad = Math.round(4 * Config.scale);
            const gw = width - pad * 2;
            const n = root.rxHistory.length;
            if (n === 0)
                return;
            const step = gw / (root.historyLen - 1);
            const xOff = (root.historyLen - n) * step;
            const relX = Math.max(0, Math.min(gw, mouse.x - pad - xOff));
            const idx = Math.max(0, Math.min(n - 1, Math.round(relX / step)));
            root.sharedHovered = true;
            root.sharedHoverIndex = idx;
        }

        onExited: {
            root.sharedHovered = false;
            root.sharedHoverIndex = -1;
        }
    }

    // ── Graph component ───────────────────────────────────────────────────────
    component NetworkGraph: Item {
        id: graph

        property var history: []
        property int maxHistory: 60
        property real currentRate: 0
        property real sharedPeak: 1024
        property color lineColor: "white"
        property color fillColor: Qt.rgba(1, 1, 1, 0.15)
        property string label: ""
        property var formatFn: null

        // Driven externally by the shared mouse overlay
        property bool hovered: false
        property int hoverIndex: -1

        readonly property real hoverRate: (hoverIndex >= 0 && hoverIndex < history.length) ? history[hoverIndex] : currentRate

        // Dot position — mirrors the canvas paint formula so the QML label tracks the dot
        readonly property real _pad: Math.round(4 * Config.scale)
        readonly property real _gw: width - _pad * 2
        readonly property real _gh: height - _pad * 2
        readonly property real _step: maxHistory > 1 ? _gw / (maxHistory - 1) : _gw
        readonly property real _xOffset: (maxHistory - history.length) * _step
        readonly property real dotX: hoverIndex >= 0
            ? _pad + _xOffset + hoverIndex * _step
            : -1
        readonly property real dotY: (hoverIndex >= 0 && hoverIndex < history.length && sharedPeak > 0)
            ? _pad + _gh - (history[hoverIndex] / sharedPeak) * _gh
            : -1

        onHistoryChanged: graphCanvas.requestPaint()
        onSharedPeakChanged: graphCanvas.requestPaint()
        onHoverIndexChanged: graphCanvas.requestPaint()
        onHoveredChanged: graphCanvas.requestPaint()

        // ── Canvas graph ──────────────────────────────────────────────────────
        Canvas {
            id: graphCanvas
            anchors.fill: parent

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                const hist = graph.history;
                const peak = graph.sharedPeak;

                const pad = Math.round(4 * Config.scale);
                const gw = width - pad * 2;
                const gh = height - pad * 2;
                const n = hist.length;
                const step = gw / (graph.maxHistory - 1);
                const xOffset = (graph.maxHistory - n) * step;

                // ── Grid (3 horizontal lines at 25%, 50%, 75%) ────────────────
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.07).toString();
                ctx.lineWidth = 1;
                ctx.setLineDash([]);
                for (let g = 1; g <= 3; g++) {
                    const gy = pad + gh * (1 - g / 4);
                    ctx.beginPath();
                    ctx.moveTo(pad, gy);
                    ctx.lineTo(pad + gw, gy);
                    ctx.stroke();
                }

                // ── Vertical time ticks (every 15 samples) ────────────────────
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.05).toString();
                for (let t = 0; t < graph.maxHistory; t += 15) {
                    const tx = pad + t * step;
                    ctx.beginPath();
                    ctx.moveTo(tx, pad);
                    ctx.lineTo(tx, pad + gh);
                    ctx.stroke();
                }

                if (hist.length < 2)
                    return;

                // ── Curve ─────────────────────────────────────────────────────
                ctx.beginPath();
                for (let i = 0; i < n; i++) {
                    const x = pad + xOffset + i * step;
                    const y = pad + gh - (hist[i] / peak) * gh;
                    if (i === 0)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }
                ctx.strokeStyle = graph.lineColor.toString();
                ctx.lineWidth = Math.round(1.5 * Config.scale);
                ctx.lineJoin = "round";
                ctx.stroke();

                // Fill under curve
                const lastX = pad + xOffset + (n - 1) * step;
                const firstX = pad + xOffset;
                ctx.lineTo(lastX, pad + gh);
                ctx.lineTo(firstX, pad + gh);
                ctx.closePath();
                ctx.fillStyle = graph.fillColor.toString();
                ctx.fill();

                // ── Hover crosshair ───────────────────────────────────────────
                if (graph.hovered && graph.hoverIndex >= 0 && graph.hoverIndex < n) {
                    const hi = graph.hoverIndex;
                    const hx = pad + xOffset + hi * step;
                    const hy = pad + gh - (hist[hi] / peak) * gh;

                    // Dashed vertical guide
                    ctx.beginPath();
                    ctx.moveTo(hx, pad);
                    ctx.lineTo(hx, pad + gh);
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.25).toString();
                    ctx.lineWidth = 1;
                    ctx.setLineDash([Math.round(3 * Config.scale), Math.round(3 * Config.scale)]);
                    ctx.stroke();
                    ctx.setLineDash([]);

                    // Dot
                    ctx.beginPath();
                    ctx.arc(hx, hy, Math.round(3.5 * Config.scale), 0, Math.PI * 2);
                    ctx.fillStyle = graph.lineColor.toString();
                    ctx.fill();
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.8).toString();
                    ctx.lineWidth = Math.round(1.5 * Config.scale);
                    ctx.stroke();
                }
            }
        }

        // ── Labels ────────────────────────────────────────────────────────────
        // Direction tag — top-left, always fixed
        Text {
            id: dirTag
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: Math.round(6 * Config.scale)
            text: graph.label
            color: graph.lineColor
            font.family: Config.font.family
            font.pixelSize: Config.font.sizeLg
            font.weight: Font.Bold
            opacity: 0.85
        }

        // Rate value — rests below the tag when idle,
        // floats beside the crosshair dot when hovered.
        Item {
            id: rateLabel

            readonly property bool floating: graph.hovered && graph.dotX >= 0

            readonly property real _margin: Math.round(6 * Config.scale)
            readonly property real _restX: dirTag.x
            readonly property real _restY: dirTag.y + dirTag.implicitHeight + Math.round(2 * Config.scale)
            readonly property real dotGap: Math.round(6 * Config.scale)
            readonly property bool flipLeft: graph.dotX > graph.width / 2

            readonly property real _hPad: Math.round(6 * Config.scale)
            readonly property real _vPad: Math.round(3 * Config.scale)

            width: rateLabelText.implicitWidth + (floating ? _hPad * 2 : 0)
            height: rateLabelText.implicitHeight + (floating ? _vPad * 2 : 0)

            x: floating
               ? (flipLeft
                  ? graph.dotX - dotGap - width
                  : graph.dotX + dotGap)
               : _restX

            y: floating
               ? Math.max(0, Math.min(graph.height - height,
                     graph.dotY - height / 2))
               : _restY

            Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }

            // Pill background — only visible when floating
            Rectangle {
                anchors.fill: parent
                radius: Math.round(5 * Config.scale)
                color: Qt.rgba(0.05, 0.04, 0.12, 0.88)
                border.color: Qt.rgba(graph.lineColor.r, graph.lineColor.g, graph.lineColor.b, 0.35)
                border.width: 1
                opacity: rateLabel.floating ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            Text {
                id: rateLabelText
                anchors.centerIn: parent

                text: graph.formatFn
                      ? graph.formatFn(graph.hovered && graph.hoverIndex >= 0
                                       ? graph.hoverRate
                                       : graph.currentRate)
                      : ""

                color: graph.lineColor
                font.family: Config.font.family
                font.pixelSize: rateLabel.floating ? Config.font.sizeXl : Config.font.sizeLg
                font.weight: Font.Bold

                Behavior on font.pixelSize { NumberAnimation { duration: 80 } }

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#ee000000"
                    shadowBlur: 1.0
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 2
                }
            }
        }
    }
}
