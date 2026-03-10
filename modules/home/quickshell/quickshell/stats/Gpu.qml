pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io

import ".."
import "../components"

// AMD GPU stats page — utilization, clocks, VRAM, temp, power, state.
Item {
    id: root

    // ── Raw data ──────────────────────────────────────────────────────────────
    property int    gpuPercent:     0
    property int    vcnPercent:     0
    property real   vramUsedBytes:  0
    property real   vramTotalBytes: 0
    property int    sclkHz:         0      // precise core clock from hwmon
    property int    mclkMhz:        0      // active memory clock from pp_dpm_mclk
    property int    tempMilliC:     0
    property real   powerUw:        0      // microwatts
    property string perfLevel:      ""     // power_dpm_force_performance_level
    property string dpmState:       ""     // power_dpm_state
    property string pciState:       ""     // power_state (D0/D3/…)

    // ── Derived ───────────────────────────────────────────────────────────────
    readonly property int    tempC:       Math.round(root.tempMilliC / 1000)
    readonly property real   powerW:      root.powerUw / 1000000
    readonly property real   vramUsedGb:  root.vramUsedBytes  / 1073741824
    readonly property real   vramTotalGb: root.vramTotalBytes / 1073741824
    readonly property real   vramFrac:    root.vramTotalBytes > 0 ? root.vramUsedBytes / root.vramTotalBytes : 0
    readonly property string sclkText:    root.sclkHz > 0  ? (root.sclkHz / 1000000).toFixed(0) + " MHz"  : "—"
    readonly property string mclkText:    root.mclkMhz > 0 ? root.mclkMhz + " MHz"                        : "—"

    // ── Colours — change at thresholds ───────────────────────────────────────
    readonly property color gpuColor:
        root.gpuPercent > 85 ? Config.colors.danger  :
        root.gpuPercent > 55 ? Config.colors.warning :
                               Config.colors.accent

    readonly property color vramColor:
        root.vramFrac > 0.85 ? Config.colors.danger  :
        root.vramFrac > 0.65 ? Config.colors.warning :
                               Config.colors.accent

    readonly property color tempColor:
        root.tempC >= 90 ? Config.colors.danger  :
        root.tempC >= 70 ? Config.colors.warning :
                           Config.colors.accent

    readonly property color powerColor:
        root.powerW >= 35 ? Config.colors.danger  :
        root.powerW >= 20 ? Config.colors.warning :
                            Config.colors.accent

    // perfLevel colour: high=danger, low=muted, auto/balanced=accent
    readonly property color perfLevelColor:
        root.perfLevel === "high"        ? Config.colors.danger     :
        root.perfLevel === "low"         ? Config.colors.textMuted  :
        root.perfLevel === "manual"      ? Config.colors.warning    :
                                          Config.colors.accent

    // dpmState colour: performance=accentAlt, battery=textMuted, else accent
    readonly property color dpmStateColor:
        root.dpmState === "performance"  ? Config.colors.accentAlt  :
        root.dpmState === "battery"      ? Config.colors.textMuted  :
                                           Config.colors.accent

    // ── Processes ─────────────────────────────────────────────────────────────
    property Process _utilProc: Process {
        command: ["cat",
            "/sys/class/drm/card1/device/gpu_busy_percent",
            "/sys/class/drm/card1/device/vcn_busy_percent"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                root.gpuPercent = parseInt(lines[0]) || 0
                root.vcnPercent = parseInt(lines[1]) || 0
            }
        }
    }

    property Process _vramProc: Process {
        command: ["cat",
            "/sys/class/drm/card1/device/mem_info_vram_used",
            "/sys/class/drm/card1/device/mem_info_vram_total"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                root.vramUsedBytes  = parseFloat(lines[0]) || 0
                root.vramTotalBytes = parseFloat(lines[1]) || 0
            }
        }
    }

    property Process _hwmonProc: Process {
        command: ["sh", "-c",
            "cat /sys/class/hwmon/hwmon7/freq1_input " +
                "/sys/class/hwmon/hwmon7/temp1_input " +
                "/sys/class/hwmon/hwmon7/power1_input 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                root.sclkHz    = parseInt(lines[0]) || 0
                root.tempMilliC = parseInt(lines[1]) || 0
                root.powerUw   = parseFloat(lines[2]) || 0
            }
        }
    }

    // Active memory clock: find the line ending with " *"
    property Process _mclkProc: Process {
        command: ["cat", "/sys/class/drm/card1/device/pp_dpm_mclk"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of this.text.split("\n")) {
                    if (line.includes("*")) {
                        const m = line.match(/(\d+)Mhz/)
                        if (m) { root.mclkMhz = parseInt(m[1]); break }
                    }
                }
            }
        }
    }

    // Power state: perfLevel + dpmState + pciState in one shot
    property Process _stateProc: Process {
        command: ["sh", "-c",
            "cat /sys/class/drm/card1/device/power_dpm_force_performance_level " +
                "/sys/class/drm/card1/device/power_dpm_state " +
                "/sys/class/drm/card1/device/power_state 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                root.perfLevel = (lines[0] || "").trim()
                root.dpmState  = (lines[1] || "").trim()
                root.pciState  = (lines[2] || "").trim()
            }
        }
    }

    property Timer _timer: Timer {
        interval: 2000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: {
            root._utilProc.running  = true
            root._vramProc.running  = true
            root._hwmonProc.running = true
            root._mclkProc.running  = true
            root._stateProc.running = true
        }
    }

    // ── Sizing helpers ────────────────────────────────────────────────────────
    readonly property int pad: Math.round(14 * Config.scale)
    readonly property int gap: Math.round(10 * Config.scale)
    readonly property int cardR: Math.round(10 * Config.scale)

    // ── Layout ────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: root.gap

        // ══ Header: GPU% bar ════════════════════════════════════════════════
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(5 * Config.scale)

            // Label row
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

                // DPM state badge (e.g. "performance")
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

                // Perf level badge (e.g. "auto")
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

                // Temperature
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

            GradientProgressBar {
                Layout.fillWidth: true
                value: root.gpuPercent / 100
                barHeight: Math.round(7 * Config.scale)
            }
        }

        // ── Divider ──────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Config.panelBorder.color
            opacity: 0.30
        }

        // ══ Metric cards grid (2 × 2) ════════════════════════════════════════
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: root.gap
            rowSpacing: root.gap

            // ── Core Clock ──────────────────────────────────────────────────
            MetricCard {
                Layout.fillWidth: true
                label: "Core Clock"
                value: root.sclkText
                valueColor: Config.colors.accentAlt
                icon: "cpu-symbolic"
            }

            // ── Mem Clock ───────────────────────────────────────────────────
            MetricCard {
                Layout.fillWidth: true
                label: "Mem Clock"
                value: root.mclkText
                valueColor: Config.colors.accent
                icon: "drive-harddisk-symbolic"
            }

            // ── Power ───────────────────────────────────────────────────────
            MetricCard {
                Layout.fillWidth: true
                label: "Power"
                value: root.powerUw > 0 ? root.powerW.toFixed(1) + " W" : "—"
                valueColor: root.powerColor
                icon: "battery-symbolic"
            }

            // ── VCN (video encode/decode) ────────────────────────────────
            MetricCard {
                Layout.fillWidth: true
                label: "VCN"
                value: root.vcnPercent + "%"
                valueColor: root.vcnPercent > 60 ? Config.colors.warning : Config.colors.textSecondary
                icon: "video-display-symbolic"
            }
        }

        // ── Divider ──────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Config.panelBorder.color
            opacity: 0.30
        }

        // ══ VRAM bar ═════════════════════════════════════════════════════════
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(5 * Config.scale)

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
            }

            // Segmented VRAM bar — used (solid) + free (ghost)
            Item {
                Layout.fillWidth: true
                height: Math.round(7 * Config.scale) + Math.round(4 * Config.scale)

                // Rail
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: Math.round(7 * Config.scale)
                    radius: height / 2
                    color: Config.colors.sliderRail
                }
                // Glow
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * Math.min(1, root.vramFrac)
                    height: Math.round(7 * Config.scale) + Math.round(4 * Config.scale)
                    radius: height / 2
                    opacity: 0.30
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: root.vramColor }
                        GradientStop { position: 1.0; color: Config.colors.accentAlt }
                    }
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                }
                // Fill
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * Math.min(1, root.vramFrac)
                    height: Math.round(7 * Config.scale)
                    radius: height / 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: root.vramColor }
                        GradientStop { position: 1.0; color: Config.colors.accentAlt }
                    }
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                }
            }
        }

        // ══ PCI power state pill ══════════════════════════════════════════════
        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(6 * Config.scale)

            Text {
                text: "PCI State"
                color: Config.colors.textMuted
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeSm
            }

            Rectangle {
                height: Math.round(18 * Config.scale)
                width: pciLabel.implicitWidth + Math.round(12 * Config.scale)
                radius: height / 2
                color: root.pciState === "D0"
                    ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.15)
                    : Qt.rgba(Config.colors.textMuted.r, Config.colors.textMuted.g, Config.colors.textMuted.b, 0.12)
                border.color: root.pciState === "D0" ? Config.colors.accent : Config.colors.textMuted
                border.width: 1

                Text {
                    id: pciLabel
                    anchors.centerIn: parent
                    text: root.pciState !== "" ? root.pciState : "—"
                    color: root.pciState === "D0" ? Config.colors.accent : Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeSm
                    font.weight: Font.Medium
                }
            }

            Item { Layout.fillWidth: true }
        }

        Item { Layout.fillHeight: true }
    }

    // ── Inline MetricCard component ───────────────────────────────────────────
    component MetricCard: Rectangle {
        id: card
        property string label:      ""
        property string value:      "—"
        property color  valueColor: Config.colors.accent
        property string icon:       ""

        implicitHeight: Math.round(58 * Config.scale)
        radius: root.cardR
        color: Config.colors.surfaceAlt
        border.color: Qt.rgba(card.valueColor.r, card.valueColor.g, card.valueColor.b, 0.20)
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: 400 } }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Math.round(3 * Config.scale)

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: card.value
                color: card.valueColor
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeLg
                font.weight: Font.SemiBold
                Behavior on color { ColorAnimation { duration: 400 } }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: card.label
                color: Config.colors.textMuted
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeSm
            }
        }
    }
}
