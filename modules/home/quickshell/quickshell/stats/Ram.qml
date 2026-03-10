pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io

import ".."
import "../components"

// RAM usage panel — fills the content area.
Item {
    id: root

    property real ramUsedGb: 0
    property real ramTotalGb: 0
    property real ramCachedGb: 0
    readonly property real ramPercent: ramTotalGb > 0 ? ramUsedGb / ramTotalGb : 0
    readonly property real cachedPercent: ramTotalGb > 0 ? ramCachedGb / ramTotalGb : 0

    property Process _ramProc: Process {
        command: ["cat", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                let total = 0, available = 0, cached = 0, buffers = 0
                for (const line of this.text.split("\n")) {
                    if (line.startsWith("MemTotal:"))
                        total = parseInt(line.split(/\s+/)[1]) || 0
                    else if (line.startsWith("MemAvailable:"))
                        available = parseInt(line.split(/\s+/)[1]) || 0
                    else if (line.startsWith("Cached:"))
                        cached = parseInt(line.split(/\s+/)[1]) || 0
                    else if (line.startsWith("Buffers:"))
                        buffers = parseInt(line.split(/\s+/)[1]) || 0
                }
                root.ramTotalGb  = total / 1048576
                root.ramUsedGb   = (total - available) / 1048576
                root.ramCachedGb = (cached + buffers) / 1048576
            }
        }
    }

    property Timer _ramTimer: Timer {
        interval: 2000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: root._ramProc.running = true
    }

    readonly property int pad: Math.round(20 * Config.scale)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: Math.round(16 * Config.scale)

        // Big used / total label
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(4 * Config.scale)

            Text {
                text: "RAM"
                color: Config.colors.textMuted
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeSm
                font.weight: Font.Medium
            }

            Text {
                text: root.ramUsedGb.toFixed(2) + " GB"
                color: root.ramPercent > 0.85 ? Config.colors.danger
                     : root.ramPercent > 0.65 ? Config.colors.warning
                     : Config.colors.accent
                font.family: Config.font.family
                font.pixelSize: Math.round(Config.font.sizeSm * 2.8)
                font.weight: Font.Bold
            }

            Text {
                text: "of " + root.ramTotalGb.toFixed(1) + " GB"
                color: Config.colors.textMuted
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeSm
            }
        }

        // Stacked bar: used (solid) + cached (dimmer)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(6 * Config.scale)

            // Used bar
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.round(3 * Config.scale)

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Used"
                        color: Config.colors.textMuted
                        font.family: Config.font.family
                        font.pixelSize: Config.font.sizeSm
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: Math.round(root.ramPercent * 100) + "%"
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
                    barHeight: Math.round(8 * Config.scale)
                }
            }

            // Cached bar
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.round(3 * Config.scale)

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Cached + Buffers"
                        color: Config.colors.textMuted
                        font.family: Config.font.family
                        font.pixelSize: Config.font.sizeSm
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.ramCachedGb.toFixed(1) + " GB"
                        color: Config.colors.textMuted
                        font.family: Config.font.family
                        font.pixelSize: Config.font.sizeSm
                    }
                }
                // Dimmer bar for cached
                Item {
                    Layout.fillWidth: true
                    height: Math.round(8 * Config.scale)
                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Qt.rgba(1, 1, 1, 0.08)
                    }
                    Rectangle {
                        width: parent.width * Math.min(1, root.cachedPercent)
                        height: parent.height
                        radius: height / 2
                        color: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.35)
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
