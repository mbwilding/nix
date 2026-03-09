pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io

import ".."

// Network speed section for the top menu drawer.
// Fills whatever space its parent gives it.
ColumnLayout {
    id: root

    spacing: Math.round(8 * Config.scale)

    property real rxBytesPerSec: 0
    property real txBytesPerSec: 0
    property var _prevRx: null
    property var _prevTx: null
    property var _prevTime: null

    function formatSpeed(bps) {
        if (bps >= 1048576)
            return (bps / 1048576).toFixed(1) + " MB/s";
        if (bps >= 1024)
            return Math.round(bps / 1024) + " KB/s";
        return Math.round(bps) + " B/s";
    }

    function _sumInterface(text, col) {
        let total = 0;
        for (const line of text.split("\n")) {
            const trimmed = line.trim();
            if (!trimmed || trimmed.startsWith("Inter") || trimmed.startsWith("face"))
                continue;
            const parts = trimmed.split(/\s+/);
            if (parts[0].replace(":", "") === "lo") continue;
            total += parseInt(parts[col]) || 0;
        }
        return total;
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
                        root.rxBytesPerSec = Math.max(0, (rx - root._prevRx) / dt);
                        root.txBytesPerSec = Math.max(0, (tx - root._prevTx) / dt);
                    }
                }
                root._prevRx = rx;
                root._prevTx = tx;
                root._prevTime = now;
            }
        }
    }

    property Timer _netTimer: Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root._netProc.running = true
    }

    // ── UI ───────────────────────────────────────────────────────────────────

    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(8 * Config.scale)
        Text {
            text: "\u2193"
            color: Config.colors.accent
            font.family: Config.font.family
            font.pixelSize: Config.font.sizeMd
            font.weight: Font.Bold
        }
        Text {
            text: "Down"
            color: Config.colors.textMuted
            font.family: Config.font.family
            font.pixelSize: Config.font.sizeSm
        }
        Item { Layout.fillWidth: true }
        Text {
            text: root.formatSpeed(root.rxBytesPerSec)
            color: Config.colors.textPrimary
            font.family: Config.font.family
            font.pixelSize: Config.font.sizeSm
            font.weight: Font.Medium
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(8 * Config.scale)
        Text {
            text: "\u2191"
            color: Config.colors.accentAlt
            font.family: Config.font.family
            font.pixelSize: Config.font.sizeMd
            font.weight: Font.Bold
        }
        Text {
            text: "Up"
            color: Config.colors.textMuted
            font.family: Config.font.family
            font.pixelSize: Config.font.sizeSm
        }
        Item { Layout.fillWidth: true }
        Text {
            text: root.formatSpeed(root.txBytesPerSec)
            color: Config.colors.textPrimary
            font.family: Config.font.family
            font.pixelSize: Config.font.sizeSm
            font.weight: Font.Medium
        }
    }

    Item { Layout.fillHeight: true }
}
