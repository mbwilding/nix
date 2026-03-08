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
        readonly property int sizeXl: Math.round(15 * root.fontSize)  // bumped for hierarchy
    }

    readonly property QtObject colors: QtObject {
        // ── Original navy/periwinkle palette — tweaked for richness ──────────
        // Backgrounds: deep navy-purple, a touch richer/more saturated than before
        readonly property color background: "#d0171728"       // 82% opaque deep navy (slightly more blue)
        readonly property color backgroundAlt: "#b8101020"    // deeper card layer
        readonly property color backgroundBar: "#30ffffff"     // OSD rail — frosted white

        // Card / pill surface — used by PopupCard and the bar pill
        readonly property color surface: Qt.rgba(0.09, 0.08, 0.17, 0.96)
        readonly property color surfaceAlt: Qt.rgba(1, 1, 1, 0.06)   // subtle inset/well color
        readonly property color surfaceHover: Qt.rgba(1, 1, 1, 0.10) // hovered inset
        readonly property color rowHover: Qt.rgba(0, 0.96, 1, 0.09)  // cyan-tinted hover row

        // Accents: original periwinkle + pink, nudged ~10% more vivid
        readonly property color accent: "#c0aaff"             // periwinkle-violet
        readonly property color accentAlt: "#ff9ff3"          // pink — kept as-is
        readonly property color accentGlow: "#7060ff"         // deep blue-violet glow core

        // Text
        readonly property color textPrimary: "#f0f0ff"        // slightly tinted white
        readonly property color textSecondary: "#bbbbd8"      // lavender-grey
        readonly property color textMuted: "#7878aa"          // lifted from #6666aa
        readonly property color badgeText: "#1a1a2e"          // dark navy — text on bright badge/chip

        // Slider thumb / rail
        readonly property color sliderThumb: "#e0e0ff"        // near-white periwinkle
        readonly property color sliderRail: Qt.rgba(0, 0.96, 1, 0.07) // very faint cyan rail

        // Chrome
        readonly property color border: "#44a8a8ff"           // subtle accent-tinted
        readonly property color borderBright: "#80b8b8ff"     // brighter hover/focus

        // Status
        readonly property color danger: "#ff6878"
        readonly property color warning: "#ffb060"
        readonly property color success: "#80ffb0"

        // Glow / shadow helpers
        readonly property color glowAccent: "#48c0aaff"       // periwinkle glow
        readonly property color glowAlt: "#48ff9ff3"          // pink glow
        readonly property color glowDanger: "#48ff6878"
        readonly property color shadowDark: "#c8000018"
    }

    readonly property QtObject osd: QtObject {
        readonly property int animateSpeed: 220              // snappier slide
        readonly property int hideDelay: 1800
        readonly property int rowHeight: Math.round(52 * root.scale)
        readonly property int panelWidth: Math.round(420 * root.scale)
        readonly property int iconSize: Math.round(28 * root.scale)
        readonly property int barHeight: Math.round(8 * root.scale)
        readonly property int radius: Math.round(16 * root.scale)
    }

    readonly property QtObject notifications: QtObject {
        readonly property int animateSpeed: 200              // snappier spring entrance
        readonly property int timeout: 10000
        readonly property int cardWidth: Math.round(400 * root.scale)
        readonly property int iconSize: Math.round(18 * root.scale)
        readonly property int radius: Math.round(12 * root.scale)
        readonly property int accentBar: Math.round(3 * root.scale)
        readonly property int bodyMaxLines: 0
        readonly property int fontSizeAppName: root.font.sizeLg
        readonly property int fontSizeTimestamp: root.font.sizeLg
        readonly property int fontSizeSummary: root.font.sizeMd
        readonly property int fontSizeBody: root.font.sizeMd
        readonly property int fontSizeAction: root.font.sizeXs
    }

    readonly property QtObject bar: QtObject {
        readonly property int animateSpeed: 200              // snappier pill slide
        readonly property int hideDelay: 1500
        readonly property int radius: Math.round(24 * root.scale)
        readonly property int iconSize: Math.round(36 * root.scale)
        readonly property int powerIconSize: Math.round(28 * root.scale)
        readonly property int batteryIconSize: Math.round(28 * root.scale)
        readonly property int spacing: Math.round(14 * root.scale)
        readonly property int padding: Math.round(28 * root.scale)
        readonly property int sectionSpacing: Math.round(20 * root.scale)
        readonly property int fontSizeClock: Math.round(root.font.sizeMd * 1.8)
        readonly property int fontSizeStatus: Math.round(root.font.sizeSm * 1.8)
        readonly property int fontSizePopup: root.font.sizeXl
        readonly property int popupOffset: Math.round(10 * root.scale)
        readonly property bool clock24h: true
        readonly property real disabledOpacity: 0.35
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
