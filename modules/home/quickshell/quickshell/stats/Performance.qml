pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io

import ".."
import "../components"

// Per-core CPU boxes with overall average bar — fills the entire content area.
Item {
    id: root

    property var corePercents: []
    property var _prevCores: []
    property string cpuName: ""

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
                const lines = this.text.split("\n")
                const newPercents = []
                const newPrev = []
                let totalPct = 0
                let coreCount = 0
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
                    totalPct += pct
                    coreCount++
                }
                root._prevCores = newPrev
                root.corePercents = newPercents
                root.avgPercent = coreCount > 0 ? Math.round(totalPct / coreCount) : 0
            }
        }
    }

    property Timer _cpuTimer: Timer {
        interval: 2000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: root._cpuProc.running = true
    }

    property int avgPercent: 0

    readonly property color avgColor:
        avgPercent > 80 ? Config.colors.danger  :
        avgPercent > 50 ? Config.colors.warning :
                          Config.colors.accent

    // Compute a nice column count: aim for roughly square cells
    readonly property int coreCount: root.corePercents.length
    readonly property int cols: coreCount <= 4  ? 2
                              : coreCount <= 8  ? 4
                              : coreCount <= 16 ? 4
                              : 8
    readonly property int rows: coreCount > 0 ? Math.ceil(coreCount / cols) : 1

    readonly property int pad: Math.round(12 * Config.scale)
    readonly property int gap: Math.round(6 * Config.scale)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: Math.round(10 * Config.scale)

        // ── Overall CPU average bar ───────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(4 * Config.scale)

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "CPU"
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeMd
                    font.weight: Font.Medium
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.cpuName
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeSm
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.avgPercent + "%"
                    color: root.avgColor
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeMd
                    font.weight: Font.Medium
                    Behavior on color { ColorAnimation { duration: 400 } }
                }
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

            readonly property real cellW: (width  - (root.cols - 1) * root.gap) / Math.max(root.cols, 1)
            readonly property real cellH: (height - (root.rows - 1) * root.gap) / Math.max(root.rows, 1)

            Repeater {
                model: root.corePercents.length

                delegate: Item {
                    required property int index
                    readonly property int pct: root.corePercents[index] ?? 0
                    readonly property int col: index % root.cols
                    readonly property int row: Math.floor(index / root.cols)

                    // Access parent dimensions via the containing Item's properties
                    readonly property real _cellW: parent.width > 0
                        ? (parent.width - (root.cols - 1) * root.gap) / Math.max(root.cols, 1)
                        : 0
                    readonly property real _cellH: parent.height > 0
                        ? (parent.height - (root.rows - 1) * root.gap) / Math.max(root.rows, 1)
                        : 0

                    x: col * (_cellW + root.gap)
                    y: row * (_cellH + root.gap)
                    width: _cellW
                    height: _cellH

                    readonly property color barColor:
                        pct > 80 ? Config.colors.danger  :
                        pct > 50 ? Config.colors.warning :
                                   Config.colors.accent

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.round(8 * Config.scale)
                        color: Config.colors.surface
                        border.color: Qt.rgba(barColor.r, barColor.g, barColor.b, pct > 50 ? 0.6 : 0.20)
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
                                GradientStop { position: 1.0; color: Qt.rgba(barColor.r, barColor.g, barColor.b, 0.30) }
                            }
                            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        }

                        // Core number (top-left)
                        Text {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.topMargin: Math.round(3 * Config.scale)
                            anchors.leftMargin: Math.round(4 * Config.scale)
                            text: "C" + index
                            color: Qt.rgba(1, 1, 1, 0.38)
                            font.family: Config.font.family
                            font.pixelSize: Config.font.sizeSm
                        }

                        // Percentage label (centred)
                        Text {
                            anchors.centerIn: parent
                            text: pct + "%"
                            color: "white"
                            font.family: Config.font.family
                            font.pixelSize: Config.font.sizeMd
                            font.weight: Font.Medium
                        }
                    }
                }
            }
        }
    }
}
