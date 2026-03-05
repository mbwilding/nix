pragma Singleton

import QtQuick

QtObject {
    id: root

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
    }

    readonly property QtObject notifications: QtObject {
        readonly property int animateSpeed: 250
        readonly property int timeout: 5000
    }
}
