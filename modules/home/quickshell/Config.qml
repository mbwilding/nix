pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property real scale: 1.0
    readonly property real fontSize: 1.4
    readonly property bool soundEnabled: true

    readonly property QtObject font: QtObject {
        readonly property string family: "NeoSpleen Nerd Font"
        readonly property int sizeSm: Math.round(10 * root.fontSize)
        readonly property int sizeXs: Math.round(11 * root.fontSize)
        readonly property int sizeMd: Math.round(12 * root.fontSize)
        readonly property int sizeLg: Math.round(13 * root.fontSize)
        readonly property int sizeXl: Math.round(14 * root.fontSize)
        readonly property int sizeOsd: Math.round(14 * root.fontSize)
    }

    readonly property QtObject colors: QtObject {
        readonly property color background: "#cc1a1a2e"
        readonly property color backgroundBar: "#50ffffff"
        readonly property color accent: "#a0a0ff"
        readonly property color textPrimary: "#ffffff"
        readonly property color textSecondary: "#ccffffff"
        readonly property color textMuted: "#60ffffff"
        readonly property color border: "#30ffffff"
    }

    readonly property QtObject osd: QtObject {
        readonly property int animateSpeed: 250
        readonly property int hideDelay: 1500
        readonly property int rowHeight: Math.round(50 * root.scale)
        readonly property int panelWidth: Math.round(400 * root.scale)
        readonly property int iconSize: Math.round(30 * root.scale)
        readonly property int barHeight: Math.round(10 * root.scale)
        readonly property int radius: Math.round(12 * root.scale)
    }

    readonly property QtObject notifications: QtObject {
        readonly property int animateSpeed: 250
        readonly property int timeout: 7500
        readonly property int cardWidth: Math.round(400 * root.scale)
        readonly property int iconSize: Math.round(18 * root.scale)
        readonly property int radius: Math.round(12 * root.scale)
        readonly property int accentBar: Math.round(3 * root.scale)
        readonly property int bodyMaxLines: 0
        readonly property int fontSizeAppName: root.font.sizeLg
        readonly property int fontSizeTimestamp: root.font.sizeSm
        readonly property int fontSizeSummary: root.font.sizeMd
        readonly property int fontSizeBody: root.font.sizeMd
        readonly property int fontSizeAction: root.font.sizeMd
    }

    readonly property QtObject battery: QtObject {
        readonly property var warnLevels: [
            {
                level: 20,
                title: "Battery Level Low",
                message: "Please connect your device to a power source at your earliest convenience.",
                icon: "battery-low-symbolic",
                critical: false
            },
            {
                level: 10,
                title: "Battery Level Critically Low",
                message: "Immediate connection to a power source is strongly recommended.",
                icon: "battery-caution-symbolic",
                critical: false
            },
            {
                level: 5,
                title: "Battery Level Critical",
                message: "System shutdown is imminent. Please connect to a power source immediately.",
                icon: "battery-empty-symbolic",
                critical: true
            }
        ]
    }
}
