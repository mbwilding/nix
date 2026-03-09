pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io

import ".."
import "../components"

// CPU and RAM performance section for the top menu drawer.
// Fills whatever space its parent gives it.
ColumnLayout {
    id: root

    spacing: Math.round(8 * Config.scale)

    // CPU state
    property real cpuPercent: 0
    property var _prevCpu: null

    // RAM state
    property real ramUsedGb: 0
    property real ramTotalGb: 0
    readonly property real ramPercent: ramTotalGb > 0 ? ramUsedGb / ramTotalGb : 0

    property Process _cpuProc: Process {
        command: ["cat", "/proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.split("\n")[0];
                const parts = line.trim().split(/\s+/);
                const user   = parseInt(parts[1]) || 0;
                const nice   = parseInt(parts[2]) || 0;
                const system = parseInt(parts[3]) || 0;
                const idle   = parseInt(parts[4]) || 0;
                const iowait = parseInt(parts[5]) || 0;
                const irq    = parseInt(parts[6]) || 0;
                const sirq   = parseInt(parts[7]) || 0;
                const idleTotal = idle + iowait;
                const total = idleTotal + user + nice + system + irq + sirq;
                if (root._prevCpu) {
                    const deltaIdle  = idleTotal - root._prevCpu[0];
                    const deltaTotal = total - root._prevCpu[1];
                    if (deltaTotal > 0)
                        root.cpuPercent = Math.round((1 - deltaIdle / deltaTotal) * 100);
                }
                root._prevCpu = [idleTotal, total];
            }
        }
    }

    property Timer _cpuTimer: Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root._cpuProc.running = true
    }

    property Process _ramProc: Process {
        command: ["cat", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                let total = 0, available = 0;
                for (const line of this.text.split("\n")) {
                    if (line.startsWith("MemTotal:"))
                        total = parseInt(line.split(/\s+/)[1]) || 0;
                    else if (line.startsWith("MemAvailable:"))
                        available = parseInt(line.split(/\s+/)[1]) || 0;
                }
                root.ramTotalGb = total / 1048576;
                root.ramUsedGb  = (total - available) / 1048576;
            }
        }
    }

    property Timer _ramTimer: Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root._ramProc.running = true
    }

    // ── UI ───────────────────────────────────────────────────────────────────

    // CPU
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Math.round(4 * Config.scale)

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "CPU"
                color: Config.colors.textMuted
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeSm
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.cpuPercent + "%"
                color: root.cpuPercent > 80 ? Config.colors.danger
                     : root.cpuPercent > 50 ? Config.colors.warning
                     : Config.colors.accent
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeSm
                font.weight: Font.Medium
            }
        }

        GradientProgressBar {
            Layout.fillWidth: true
            value: root.cpuPercent / 100
            barHeight: Math.round(5 * Config.scale)
        }
    }

    // RAM
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
