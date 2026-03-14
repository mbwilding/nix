pragma Singleton

import QtQuick
import "bar"

QtObject {
    id: root

    readonly property real scale: 1.0
    readonly property real fontSize: 1.4
    readonly property bool soundEnabled: true
    readonly property int monitor: 0

    readonly property QtObject panelBorder: QtObject {
        readonly property int width: 2
        readonly property color color: "#80c0aaff"
    }

    readonly property QtObject font: QtObject {
        readonly property string family: "JetBrainsMono Nerd Font Mono"
        readonly property int sizeXxs: Math.round(8 * root.fontSize)
        readonly property int sizeSm: Math.round(10 * root.fontSize)
        readonly property int sizeXs: Math.round(11 * root.fontSize)
        readonly property int sizeMd: Math.round(12 * root.fontSize)
        readonly property int sizeLg: Math.round(13 * root.fontSize)
        readonly property int sizeXl: Math.round(15 * root.fontSize)
        readonly property int sizeXxl: Math.round(17 * root.fontSize)
        readonly property int sizeXxxl: Math.round(20 * root.fontSize)
    }

    readonly property QtObject colors: QtObject {
        readonly property color background: "#d0171728"
        readonly property color backgroundAlt: "#b8101020"
        readonly property color backgroundBar: "#30ffffff"

        readonly property color surface: Qt.rgba(0.09, 0.08, 0.17, 0.96)
        readonly property color surfaceAlt: Qt.rgba(1, 1, 1, 0.06)
        readonly property color surfaceHover: Qt.rgba(1, 1, 1, 0.10)
        readonly property color rowHover: Qt.rgba(0, 0.96, 1, 0.09)

        readonly property color accent: "#c0aaff"
        readonly property color accentAlt: "#ff9ff3"
        readonly property color accentGlow: "#7060ff"

        readonly property color textPrimary: "#f0f0ff"
        readonly property color textSecondary: "#bbbbd8"
        readonly property color textMuted: "#7878aa"
        readonly property color badgeText: "#1a1a2e"

        readonly property color sliderThumb: "#e0e0ff"
        readonly property color sliderRail: Qt.rgba(0, 0.96, 1, 0.07)

        readonly property color border: "#44a8a8ff"
        readonly property color borderBright: "#80b8b8ff"

        readonly property color danger: "#ff6878"
        readonly property color warning: "#ffb060"
        readonly property color success: "#80ffb0"

        readonly property color glowAccent: "#48c0aaff"
        readonly property color glowAlt: "#48ff9ff3"
        readonly property color glowDanger: "#48ff6878"
        readonly property color shadowDark: "#c8000018"
    }

    readonly property QtObject osd: QtObject {
        readonly property int animateSpeed: 220
        readonly property int hideDelay: 1800
        readonly property int rowHeight: Math.round(52 * root.scale)
        readonly property int panelWidth: Math.round(420 * root.scale)
        readonly property int iconSize: Math.round(28 * root.scale)
        readonly property int barHeight: Math.round(8 * root.scale)
        readonly property int radius: Math.round(16 * root.scale)
    }

    readonly property QtObject notifications: QtObject {
        readonly property int animateSpeed: 200
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
        readonly property int animateSpeed: 200
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
        readonly property bool clockShowTime: true
        readonly property bool clockShowDate: true
        readonly property string clockTimeFormat: clock24h ? "HH:mm" : "h:mm AP"
        readonly property string clockDateFormat: "ddd dd MMM"
        readonly property real disabledOpacity: 0.35
        readonly property int popupRadius: Math.round(14 * root.scale)
        readonly property real triggerStart: 1 / 3   // fraction of screen width where trigger strip begins
        readonly property real triggerEnd: 2 / 3   // fraction of screen width where trigger strip ends
        readonly property int edgeHotspotSize: 4     // px tall strip at screen bottom that shows the bar on hover
        readonly property var layout: [BarItems.tray, BarItems.separator, BarItems.system, BarItems.separator, BarItems.clock, BarItems.separator, BarItems.pin]
        readonly property var systemLayout: [SystemItems.wifi, SystemItems.bluetooth, SystemItems.volume, SystemItems.brightness, SystemItems.power, SystemItems.ethernet, SystemItems.notifications]
    }

    readonly property QtObject stats: QtObject {
        readonly property int animateSpeed: 220
        readonly property int hideDelay: 2000
        readonly property int radius: 18
        readonly property int height: 360             // drawer height in px (pre-scale)
        readonly property int maxWidth: 1200          // max drawer width in px (pre-scale)
        readonly property int musicWidth: 188  // matches inner card height (stats.height - 2*drawerPad) for a square card
        readonly property int clockWidth: 200
        readonly property int rightWidth: 260
        readonly property int fontSizeTime: Math.round(root.font.sizeMd * 2.6)
        readonly property int fontSizeDate: Math.round(root.font.sizeMd * 1.2)
        readonly property real triggerStart: 1 / 3   // fraction of screen width where trigger strip begins
        readonly property real triggerEnd: 2 / 3   // fraction of screen width where trigger strip ends
        readonly property int edgeHotspotSize: 4     // px tall strip at screen top that shows the stats drawer on hover
    }

    readonly property QtObject lockscreen: QtObject {
        readonly property int dvdCount: 3
        readonly property int orbCount: 2
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
