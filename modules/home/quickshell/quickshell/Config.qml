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
    }

    readonly property QtObject colors: QtObject {
        // Base backgrounds — deep navy with a purple tint, heavy blur-glass feel
        readonly property color background: "#d01a1a2e"       // 82% opaque deep navy
        readonly property color backgroundAlt: "#b8141428"    // slightly darker for layering
        readonly property color backgroundBar: "#38ffffff"     // OSD rail — frosted white

        // Accent — vivid violet-blue with a pink counterpart for gradients
        readonly property color accent: "#b09fff"             // main periwinkle-violet
        readonly property color accentAlt: "#ff9ff3"          // pink/magenta complement
        readonly property color accentGlow: "#6060ff"         // deep-blue glow core

        // Text
        readonly property color textPrimary: "#f0f0ff"        // slightly tinted white
        readonly property color textSecondary: "#bbbbd8"      // lavender-grey
        readonly property color textMuted: "#6666aa"          // muted purple-grey

        // Chrome
        readonly property color border: "#40a0a0ff"           // subtle accent-tinted border
        readonly property color borderBright: "#70b0b0ff"     // brighter border on focus/hover
        readonly property color separator: "#25ffffff"        // ultra-subtle separator

        // Status colours
        readonly property color danger: "#ff6070"
        readonly property color warning: "#ffaa60"
        readonly property color success: "#80ffb0"

        // Glow / shadow helpers (used as rect colours behind elements)
        readonly property color glowAccent: "#50b09fff"       // accent glow blob
        readonly property color glowDanger: "#50ff6070"
        readonly property color shadowDark: "#cc000010"       // drop-shadow layer
    }

    readonly property QtObject osd: QtObject {
        readonly property int animateSpeed: 320
        readonly property int hideDelay: 1800
        readonly property int rowHeight: Math.round(52 * root.scale)
        readonly property int panelWidth: Math.round(420 * root.scale)
        readonly property int iconSize: Math.round(28 * root.scale)
        readonly property int barHeight: Math.round(8 * root.scale)
        readonly property int radius: Math.round(16 * root.scale)
    }

    readonly property QtObject notifications: QtObject {
        readonly property int animateSpeed: 280
        readonly property int timeout: 10000
        readonly property int cardWidth: Math.round(400 * root.scale)
        readonly property int iconSize: Math.round(18 * root.scale)
        readonly property int radius: Math.round(14 * root.scale)
        readonly property int accentBar: Math.round(3 * root.scale)
        readonly property int bodyMaxLines: 0
        readonly property int fontSizeAppName: root.font.sizeLg
        readonly property int fontSizeTimestamp: root.font.sizeLg
        readonly property int fontSizeSummary: root.font.sizeMd
        readonly property int fontSizeBody: root.font.sizeMd
        readonly property int fontSizeAction: root.font.sizeXs
    }

    readonly property QtObject bar: QtObject {
        readonly property int animateSpeed: 240
        readonly property int hideDelay: 1500
        readonly property int radius: Math.round(22 * root.scale)
        readonly property int iconSize: Math.round(36 * root.scale)
        readonly property int powerIconSize: Math.round(28 * root.scale)
        readonly property int batteryIconSize: Math.round(28 * root.scale)
        readonly property int spacing: Math.round(14 * root.scale)
        readonly property int padding: Math.round(26 * root.scale)
        readonly property int sectionSpacing: Math.round(22 * root.scale)
        readonly property int fontSizeClock: Math.round(root.font.sizeMd * 1.8)
        readonly property int fontSizeStatus: Math.round(root.font.sizeSm * 1.8)
        readonly property int fontSizePopup: root.font.sizeXl
        readonly property int popupOffset: Math.round(8 * root.scale)
        readonly property bool clock24h: true
        readonly property real disabledOpacity: 0.45
        // Popup appearance
        readonly property int popupRadius: Math.round(14 * root.scale)
    }

    readonly property QtObject battery: QtObject {
        readonly property var chargeLevels: ({
                charging: {
                    title: "Charger Connected",
                    message: "Your device is now charging.",
                    icon: "battery-good-charging-symbolic"
                },
                discharging: {
                    title: "Charger Disconnected",
                    message: "Your device is now running on battery.",
                    icon: "battery-good-symbolic"
                },
                fullyCharged: {
                    title: "Battery Full",
                    message: "Your battery is fully charged. You can disconnect the charger.",
                    icon: "battery-full-symbolic"
                }
            })
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
