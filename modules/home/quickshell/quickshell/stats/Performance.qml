pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io

import ".."

// Per-core CPU boxes — fills the entire content area, no title.
Item {
    id: root

    property var corePercents: []
    property var _prevCores: []

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
                    const idx = parseInt(parts[0].slice(3))
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
                        const dTotal = total - prev[1]
                        if (dTotal > 0)
                            pct = Math.round((1 - dIdle / dTotal) * 100)
                    }
                    newPercents[idx] = pct
                    newPrev[idx] = [idleTotal, total]
                }
                root._prevCores = newPrev
                root.corePercents = newPercents
            }
        }
    }

    property Timer _cpuTimer: Timer {
        interval: 2000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: root._cpuProc.running = true
    }

    // Compute a nice column count: aim for roughly square cells
    readonly property int coreCount: root.corePercents.length
    readonly property int cols: coreCount <= 4  ? 2
                              : coreCount <= 8  ? 4
                              : coreCount <= 16 ? 4
                              : 8
    readonly property int rows: coreCount > 0 ? Math.ceil(coreCount / cols) : 1

    readonly property int pad: Math.round(12 * Config.scale)
    readonly property int gap: Math.round(6 * Config.scale)
    readonly property real cellW: (width  - 2 * pad - (cols - 1) * gap) / Math.max(cols, 1)
    readonly property real cellH: (height - 2 * pad - (rows - 1) * gap) / Math.max(rows, 1)

    // Grid of boxes using a Repeater inside a fixed-position Item grid
    Item {
        anchors.fill: parent
        anchors.margins: root.pad

        Repeater {
            model: root.corePercents.length

            delegate: Item {
                required property int index
                readonly property int pct: root.corePercents[index] ?? 0
                readonly property int col: index % root.cols
                readonly property int row: Math.floor(index / root.cols)

                x: col * (root.cellW + root.gap)
                y: row * (root.cellH + root.gap)
                width: root.cellW
                height: root.cellH

                readonly property color barColor:
                    pct > 80 ? Config.colors.danger
                  : pct > 50 ? Config.colors.warning
                  : Config.colors.accent

                Rectangle {
                    anchors.fill: parent
                    radius: Math.round(8 * Config.scale)
                    color: Config.colors.surface
                    border.color: Qt.rgba(barColor.r, barColor.g, barColor.b, pct > 50 ? 0.6 : 0.25)
                    border.width: 1

                    // Fill rises from bottom
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 2
                        height: Math.max(0, (parent.height - 4) * (pct / 100))
                        radius: Math.round(6 * Config.scale)
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: Qt.rgba(barColor.r, barColor.g, barColor.b, 0.80) }
                            GradientStop { position: 1.0; color: Qt.rgba(barColor.r, barColor.g, barColor.b, 0.35) }
                        }
                        Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    }

                    // Percentage label
                    Text {
                        anchors.centerIn: parent
                        text: pct + "%"
                        color: "white"
                        font.family: Config.font.family
                        font.pixelSize: Math.round(Config.font.sizeSm * 0.85)
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }
}
