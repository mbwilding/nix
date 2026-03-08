pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import ".."

Item {
    id: clockSection
    implicitWidth: clockCol.implicitWidth
    implicitHeight: clockCol.implicitHeight

    property date clockDate

    function timeText(d) {
        if (!d)
            return "--:--";
        if (Config.bar.clock24h)
            return Qt.formatTime(d, "HH:mm");
        return Qt.formatTime(d, "hh") + ":" + Qt.formatTime(d, "mm") + " " + Qt.formatTime(d, "AP");
    }

    function dateText(d) {
        if (!d)
            return "";
        return Qt.formatDate(d, "dddd, dd-MM-yy");
    }

    Column {
        id: clockCol
        spacing: Math.round(1 * Config.scale)

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: timeBaseTxt.implicitWidth
            implicitHeight: timeBaseTxt.implicitHeight

            Text {
                id: timeBaseTxt
                text: clockSection.timeText(clockSection.clockDate)
                color: Config.colors.accent
                font.family: Config.font.family
                font.pixelSize: Config.bar.fontSizeClock
                font.weight: Font.Medium
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: clockSection.dateText(clockSection.clockDate)
            color: Config.colors.textSecondary
            font.family: Config.font.family
            font.pixelSize: Math.round(Config.bar.fontSizeStatus * 0.8)
        }
    }
}
