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

    readonly property color usageColor: ramPercent > 0.85 ? Config.colors.danger : ramPercent > 0.65 ? Config.colors.warning : Config.colors.accent

    property Process _ramProc: Process {
        command: ["cat", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                let total = 0, available = 0, cached = 0, buffers = 0;
                for (const line of this.text.split("\n")) {
                    if (line.startsWith("MemTotal:"))
                        total = parseInt(line.split(/\s+/)[1]) || 0;
                    else if (line.startsWith("MemAvailable:"))
                        available = parseInt(line.split(/\s+/)[1]) || 0;
                    else if (line.startsWith("Cached:"))
                        cached = parseInt(line.split(/\s+/)[1]) || 0;
                    else if (line.startsWith("Buffers:"))
                        buffers = parseInt(line.split(/\s+/)[1]) || 0;
                }
                root.ramTotalGb = total / 1048576;
                root.ramUsedGb = (total - available) / 1048576;
                root.ramCachedGb = (cached + buffers) / 1048576;
            }
        }
    }

    property Timer _ramTimer: Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root._ramProc.running = true
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.round(20 * Config.scale)
        spacing: Math.round(20 * Config.scale)

        // ── Arc gauge + centre text ───────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Arc drawn on a Canvas
            Canvas {
                id: arcCanvas
                anchors.fill: parent

                readonly property real pct: root.ramPercent
                readonly property color arcColor: root.usageColor
                onPctChanged: requestPaint()
                onArcColorChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    const lw = Math.round(10 * Config.scale);
                    // Pad all sides by the max glow bleed so nothing is clipped
                    const bleed = Math.ceil(lw * 1.5);
                    const cx = width / 2;
                    const cy = height / 2;
                    const r = Math.min(width - bleed * 2, height - bleed * 2) / 2 - Math.round(2 * Config.scale);

                    // Arc spans from 210° to 330° (240° sweep), bottom-left to bottom-right
                    const startAngle = 210 * Math.PI / 180;
                    const endAngle = (210 + 240) * Math.PI / 180;
                    const fillAngle = startAngle + (arcCanvas.pct * 240 * Math.PI / 180);

                    // ── Track (background arc) ────────────────────────────────
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, startAngle, endAngle);
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.07).toString();
                    ctx.lineWidth = lw;
                    ctx.lineCap = "round";
                    ctx.stroke();

                    if (arcCanvas.pct <= 0)
                        return;

                    // ── Glow (wider, semi-transparent) ────────────────────────
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, startAngle, fillAngle);
                    ctx.strokeStyle = Qt.rgba(arcCanvas.arcColor.r, arcCanvas.arcColor.g, arcCanvas.arcColor.b, 0.25).toString();
                    ctx.lineWidth = lw * 2.5;
                    ctx.lineCap = "round";
                    ctx.stroke();

                    // ── Fill arc ──────────────────────────────────────────────
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, startAngle, fillAngle);
                    ctx.strokeStyle = arcCanvas.arcColor.toString();
                    ctx.lineWidth = lw;
                    ctx.lineCap = "round";
                    ctx.stroke();

                    // ── Tip dot glow ──────────────────────────────────────────
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

            // ── Centre text ───────────────────────────────────────────────────
            ColumnLayout {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -Math.round(6 * Config.scale)
                spacing: Math.round(2 * Config.scale)

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Math.round(root.ramPercent * 100) + "%"
                    color: root.usageColor
                    font.family: Config.font.family
                    font.pixelSize: Math.round(44 * Config.scale)
                    font.weight: Font.Bold

                    Behavior on color {
                        ColorAnimation {
                            duration: 400
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.ramUsedGb.toFixed(1) + " / " + root.ramTotalGb.toFixed(0) + " GB"
                    color: Config.colors.textSecondary
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeLg
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "RAM"
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.font.sizeMd
                    font.weight: Font.Medium
                    opacity: 0.7
                }
            }
        }

        // ── Stat rows ─────────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(10 * Config.scale)

            // Used
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.round(4 * Config.scale)

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Used"
                        color: Config.colors.textMuted
                        font.family: Config.font.family
                        font.pixelSize: Config.font.sizeLg
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.ramUsedGb.toFixed(2) + " GB"
                        color: root.usageColor
                        font.family: Config.font.family
                        font.pixelSize: Config.font.sizeLg
                        font.weight: Font.Medium
                        Behavior on color {
                            ColorAnimation {
                                duration: 400
                            }
                        }
                    }
                }
                GradientProgressBar {
                    Layout.fillWidth: true
                    value: root.ramPercent
                    barHeight: Math.round(6 * Config.scale)
                }
            }

            // Cached + Buffers
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.round(4 * Config.scale)

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Cached"
                        color: Config.colors.textMuted
                        font.family: Config.font.family
                        font.pixelSize: Config.font.sizeLg
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.ramCachedGb.toFixed(2) + " GB"
                        color: Config.colors.textSecondary
                        font.family: Config.font.family
                        font.pixelSize: Config.font.sizeLg
                    }
                }
                Item {
                    Layout.fillWidth: true
                    height: Math.round(6 * Config.scale)
                    // Rail
                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Config.colors.sliderRail
                    }
                    // Fill
                    Rectangle {
                        width: parent.width * Math.min(1, root.cachedPercent)
                        height: parent.height
                        radius: height / 2
                        color: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.35)
                        Behavior on width {
                            NumberAnimation {
                                duration: 400
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }
    }
}
