pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io

import ".."

// Network history graphs for the stats drawer.
// Two Canvas graphs stacked vertically — download (accent) and upload (accentAlt).
// Mouseover shows the value at that point in history.
Item {
    id: root

    // ── Data collection ───────────────────────────────────────────────────────

    readonly property int historyLen: 60   // samples to keep
    readonly property int interval:   1000 // ms between samples

    property var rxHistory: []   // bytes/sec, newest last
    property var txHistory: []   // bytes/sec, newest last

    property real rxBytesPerSec: 0
    property real txBytesPerSec: 0

    property var _prevRx:   null
    property var _prevTx:   null
    property var _prevTime: null

    function _sumInterface(text, col) {
        let total = 0
        for (const line of text.split("\n")) {
            const trimmed = line.trim()
            if (!trimmed || trimmed.startsWith("Inter") || trimmed.startsWith("face"))
                continue
            const parts = trimmed.split(/\s+/)
            if (parts[0].replace(":", "") === "lo") continue
            total += parseInt(parts[col]) || 0
        }
        return total
    }

    function formatSpeed(bps) {
        if (bps >= 1048576) return (bps / 1048576).toFixed(2) + " MB/s"
        if (bps >= 1024)    return (bps / 1024).toFixed(1) + " KB/s"
        return Math.round(bps) + " B/s"
    }

    property Process _netProc: Process {
        command: ["cat", "/proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                const now  = Date.now()
                const rx   = root._sumInterface(this.text, 1)
                const tx   = root._sumInterface(this.text, 9)
                if (root._prevRx !== null && root._prevTime !== null) {
                    const dt = (now - root._prevTime) / 1000
                    if (dt > 0) {
                        const rxRate = Math.max(0, (rx - root._prevRx) / dt)
                        const txRate = Math.max(0, (tx - root._prevTx) / dt)
                        root.rxBytesPerSec = rxRate
                        root.txBytesPerSec = txRate

                        // Append and trim history
                        const rxH = root.rxHistory.concat([rxRate])
                        const txH = root.txHistory.concat([txRate])
                        root.rxHistory = rxH.length > root.historyLen ? rxH.slice(rxH.length - root.historyLen) : rxH
                        root.txHistory = txH.length > root.historyLen ? txH.slice(txH.length - root.historyLen) : txH
                    }
                }
                root._prevRx   = rx
                root._prevTx   = tx
                root._prevTime = now
            }
        }
    }

    property Timer _netTimer: Timer {
        interval: root.interval
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root._netProc.running = true
    }

    // ── Layout ────────────────────────────────────────────────────────────────

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.round(12 * Config.scale)
        spacing: Math.round(10 * Config.scale)

        // ── Download graph ────────────────────────────────────────────────────
        NetworkGraph {
            Layout.fillWidth: true
            Layout.fillHeight: true
            history: root.rxHistory
            maxHistory: root.historyLen
            currentRate: root.rxBytesPerSec
            lineColor: Config.colors.accent
            fillColor: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18)
            label: "DOWN"
            formatFn: root.formatSpeed
        }

        // ── Upload graph ──────────────────────────────────────────────────────
        NetworkGraph {
            Layout.fillWidth: true
            Layout.fillHeight: true
            history: root.txHistory
            maxHistory: root.historyLen
            currentRate: root.txBytesPerSec
            lineColor: Config.colors.accentAlt
            fillColor: Qt.rgba(Config.colors.accentAlt.r, Config.colors.accentAlt.g, Config.colors.accentAlt.b, 0.18)
            label: "UP"
            formatFn: root.formatSpeed
        }
    }

    // ── Graph component ───────────────────────────────────────────────────────
    component NetworkGraph: Item {
        id: graph

        property var    history:     []
        property int    maxHistory:  60
        property real   currentRate: 0
        property color  lineColor:   "white"
        property color  fillColor:   Qt.rgba(1, 1, 1, 0.15)
        property string label:       ""
        property var    formatFn:    null

        onHistoryChanged: graphCanvas.requestPaint()

        // Mouse state
        property bool   hovered:     false
        property int    hoverIndex:  -1   // index into history array under cursor
        readonly property real hoverRate: (hoverIndex >= 0 && hoverIndex < history.length)
                                          ? history[hoverIndex] : currentRate

        // ── Background card ───────────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            radius: Math.round(8 * Config.scale)
            color: Qt.rgba(0, 0, 0, 0.25)
        }

        // ── Canvas graph ──────────────────────────────────────────────────────
        Canvas {
            id: graphCanvas
            anchors.fill: parent
            anchors.margins: Math.round(1 * Config.scale)

            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                const hist = graph.history
                if (hist.length < 2) return

                // Peak for scaling — use rolling max with a floor of 1 KB/s
                let peak = 1024
                for (let i = 0; i < hist.length; i++)
                    if (hist[i] > peak) peak = hist[i]
                // Add 10% headroom
                peak *= 1.10

                const pad   = Math.round(4 * Config.scale)
                const gw    = width  - pad * 2
                const gh    = height - pad * 2
                const n     = hist.length
                const step  = gw / (graph.maxHistory - 1)

                // Offset so newest sample is always at right edge
                const xOffset = (graph.maxHistory - n) * step

                // Build path
                ctx.beginPath()
                for (let i = 0; i < n; i++) {
                    const x = pad + xOffset + i * step
                    const y = pad + gh - (hist[i] / peak) * gh
                    if (i === 0) ctx.moveTo(x, y)
                    else         ctx.lineTo(x, y)
                }

                // Stroke
                ctx.strokeStyle = graph.lineColor.toString()
                ctx.lineWidth   = Math.round(1.5 * Config.scale)
                ctx.lineJoin    = "round"
                ctx.stroke()

                // Fill under curve
                const lastX = pad + xOffset + (n - 1) * step
                const firstX = pad + xOffset
                ctx.lineTo(lastX,  pad + gh)
                ctx.lineTo(firstX, pad + gh)
                ctx.closePath()
                ctx.fillStyle = graph.fillColor.toString()
                ctx.fill()

                // Hover crosshair
                if (graph.hovered && graph.hoverIndex >= 0 && graph.hoverIndex < n) {
                    const hi = graph.hoverIndex
                    const hx = pad + xOffset + hi * step
                    const hy = pad + gh - (hist[hi] / peak) * gh

                    // Vertical guide line
                    ctx.beginPath()
                    ctx.moveTo(hx, pad)
                    ctx.lineTo(hx, pad + gh)
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.25).toString()
                    ctx.lineWidth   = 1
                    ctx.setLineDash([Math.round(3 * Config.scale), Math.round(3 * Config.scale)])
                    ctx.stroke()
                    ctx.setLineDash([])

                    // Dot on the line
                    ctx.beginPath()
                    ctx.arc(hx, hy, Math.round(3.5 * Config.scale), 0, Math.PI * 2)
                    ctx.fillStyle   = graph.lineColor.toString()
                    ctx.fill()
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.8).toString()
                    ctx.lineWidth   = Math.round(1.5 * Config.scale)
                    ctx.stroke()
                }
            }
        }

        // ── Labels ────────────────────────────────────────────────────────────
        // Top-left: graph label
        Text {
            anchors.left:    parent.left
            anchors.top:     parent.top
            anchors.margins: Math.round(6 * Config.scale)
            text:  graph.label
            color: graph.lineColor
            font.family:    Config.font.family
            font.pixelSize: Math.round(Config.font.sizeSm * 0.82)
            font.weight:    Font.Bold
            opacity: 0.85
        }

        // Top-right: current or hover value
        Text {
            anchors.right:   parent.right
            anchors.top:     parent.top
            anchors.margins: Math.round(6 * Config.scale)
            text:  graph.formatFn ? graph.formatFn(graph.hoverRate) : ""
            color: Config.colors.textPrimary
            font.family:    Config.font.family
            font.pixelSize: Math.round(Config.font.sizeSm * 0.88)
            font.weight:    Font.Medium
        }

        // ── Mouse tracking ────────────────────────────────────────────────────
        HoverHandler {
            id: hoverHandler
            onHoveredChanged: {
                graph.hovered = hovered
                if (!hovered) {
                    graph.hoverIndex = -1
                    graphCanvas.requestPaint()
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton

            onPositionChanged: mouse => {
                const hist = graph.history
                if (hist.length === 0) return
                const pad    = Math.round(4 * Config.scale)
                const gw     = graphCanvas.width - pad * 2
                const step   = gw / (graph.maxHistory - 1)
                const xOff   = (graph.maxHistory - hist.length) * step
                // Clamp to graph area
                const relX   = Math.max(0, Math.min(gw, mouse.x - pad - xOff))
                const idx    = Math.round(relX / step)
                const clamped = Math.max(0, Math.min(hist.length - 1, idx))
                if (graph.hoverIndex !== clamped) {
                    graph.hoverIndex = clamped
                    graphCanvas.requestPaint()
                }
            }

            onExited: {
                graph.hovered    = false
                graph.hoverIndex = -1
                graphCanvas.requestPaint()
            }
        }
    }
}
