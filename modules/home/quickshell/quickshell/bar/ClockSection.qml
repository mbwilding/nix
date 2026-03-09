pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import ".."

Item {
    id: clockSection
    implicitWidth: clockRow.implicitWidth
    implicitHeight: clockRow.implicitHeight

    property date clockDate

    function timeText(d) {
        if (!d)
            return "--:--";
        if (Config.bar.clock24h)
            return Qt.formatTime(d, "HH:mm");
        return Qt.formatTime(d, "h:mm") + " " + Qt.formatTime(d, "AP");
    }

    function dateText(d) {
        if (!d)
            return "";
        return Qt.formatDate(d, "ddd dd MMM");
    }

    Row {
        id: clockRow
        spacing: Math.round(8 * Config.scale)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: clockSection.dateText(clockSection.clockDate)
            color: Config.colors.textSecondary
            font.family: Config.font.family
            font.pixelSize: Math.round(Config.bar.fontSizeClock * 0.62)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "·"
            color: Config.colors.textMuted
            font.family: Config.font.family
            font.pixelSize: Config.bar.fontSizeClock
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: clockSection.timeText(clockSection.clockDate)
            color: Config.colors.accent
            font.family: Config.font.family
            font.pixelSize: Config.bar.fontSizeClock
            font.weight: Font.Medium
        }
    }
}
