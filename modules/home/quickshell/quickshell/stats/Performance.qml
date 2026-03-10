pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io

import ".."
import "../components"

// CPU (per-core boxes) + RAM bar for the stats drawer.
ColumnLayout {
    id: root

    spacing: Math.round(10 * Config.scale)

    // ── Per-core CPU state ────────────────────────────────────────────────────
    // corePercents: array of 0-100 integers, one per logical CPU
    property var corePercents: []
    property var _prevCores: []   // array of [idleTotal, total] per core

    // ── RAM state ─────────────────────────────────────────────────────────────
    property real ramUsedGb: 0
    property real ramTotalGb: 0
    readonly property real ramPercent: ramTotalGb > 0 ? ramUsedGb / ramTotalGb : 0

    // ── /proc/stat reader ─────────────────────────────────────────────────────
    property Process _cpuProc: Process {
        command: ["cat", "/proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n")
                const newPercents = []
                const newPrev = []

                for (const line of lines) {
                    if (!line.startsWith("cpu") || line.startsWith("cpu ")) continue
                    const parts = line.trim().split(/\s+/)
                    const idx   = parseInt(parts[0].slice(3))
                    if (isNaN(idx)) continue

                    const user    = parseInt(parts[1]) || 0
                    const nice    = parseInt(parts[2]) || 0
                    const system  = parseInt(parts[3]) || 0
                    const idle    = parseInt(parts[4]) || 0
                    const iowait  = parseInt(parts[5]) || 0
                    const irq     = parseInt(parts[6]) || 0
                    const sirq    = parseInt(parts[7]) || 0
                    const idleTotal = idle + iowait
                    const total   = idleTotal + user + nice + system + irq + sirq

                    let pct = 0
                    const prev = root._prevCores[idx]
                    if (prev) {
                        const dIdle  = idleTotal - prev[0]
                        const dTotal = total     - prev[1]
                        if (dTotal > 0)
                            pct = Math.round((1 - dIdle / dTotal) * 100)
                    }
                    newPercents[idx] = pct
                    newPrev[idx]     = [idleTotal, total]
                }

                root._prevCores  = newPrev
                root.corePercents = newPercents
            }
        }
    }

    property Timer _cpuTimer: Timer {
        interval: 2000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: root._cpuProc.running = true
    }

    // ── /proc/meminfo reader ──────────────────────────────────────────────────
    property Process _ramProc: Process {
        command: ["cat", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                let total = 0, available = 0
                for (const line of this.text.split("\n")) {
                    if (line.startsWith("MemTotal:"))
                        total = parseInt(line.split(/\s+/)[1]) || 0
                    else if (line.startsWith("MemAvailable:"))
                        available = parseInt(line.split(/\s+/)[1]) || 0
                }
                root.ramTotalGb = total / 1048576
                root.ramUsedGb  = (total - available) / 1048576
            }
        }
    }

    property Timer _ramTimer: Timer {
        interval: 3000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: root._ramProc.running = true
    }

    // ── UI ────────────────────────────────────────────────────────────────────

    // Section label
    Text {
        text: "CPU"
        color: Config.colors.textMuted
        font.family: Config.font.family
        font.pixelSize: Config.font.sizeSm
    }

    // Per-core grid — wraps automatically
    Flow {
        Layout.fillWidth: true
        spacing: Math.round(5 * Config.scale)

        Repeater {
            model: root.corePercents.length

            delegate: Rectangle {
                required property int index
                readonly property int pct: root.corePercents[index] ?? 0
                readonly property color barColor:
                    pct > 80 ? Config.colors.danger
                  : pct > 50 ? Config.colors.warning
                  : Config.colors.accent

                readonly property int boxW: Math.round(38 * Config.scale)
                readonly property int boxH: Math.round(46 * Config.scale)

                width: boxW
                height: boxH
                radius: Math.round(6 * Config.scale)
                color: Config.colors.surface
                border.color: Qt.rgba(
                    barColor.r, barColor.g, barColor.b,
                    pct > 50 ? 0.55 : 0.22)
                border.width: 1

                // Fill bar rising from the bottom
                Rectangle {
                    id: fillBar
                    anchors.bottom: parent.bottom
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    anchors.margins: 2
                    height: Math.max(0, (parent.height - 4) * (parent.pct / 100))
                    radius: Math.round(4 * Config.scale)
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.rgba(barColor.r, barColor.g, barColor.b, 0.85) }
                        GradientStop { position: 1.0; color: Qt.rgba(barColor.r, barColor.g, barColor.b, 0.40) }
                    }
                    Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                }

                // Percentage label
                Text {
                    anchors.centerIn: parent
                    text: parent.pct + "%"
                    color: "white"
                    font.family: Config.font.family
                    font.pixelSize: Math.round(Config.font.sizeSm * 0.82)
                    font.weight: Font.Medium
                }
            }
        }
    }

    // RAM row
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Math.round(4 * Config.scale)

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "RAM"
                color: Config.colors.textMuted
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeSm
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.ramUsedGb.toFixed(1) + " / " + root.ramTotalGb.toFixed(1) + " GB"
                color: root.ramPercent > 0.85 ? Config.colors.danger
                     : root.ramPercent > 0.65 ? Config.colors.warning
                     : Config.colors.accent
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeSm
                font.weight: Font.Medium
            }
        }

        GradientProgressBar {
            Layout.fillWidth: true
            value: root.ramPercent
            barHeight: Math.round(5 * Config.scale)
        }
    }

    Item { Layout.fillHeight: true }
}
