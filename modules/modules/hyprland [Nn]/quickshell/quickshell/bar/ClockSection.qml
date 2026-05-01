pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import ".."

Item {
    id: clockSection
    implicitWidth: clockRow.implicitWidth
    implicitHeight: clockRow.implicitHeight

    property date clockDate

    readonly property bool showDate: Config.bar.clockShowDate
    readonly property bool showTime: Config.bar.clockShowTime
    readonly property bool showSeparator: showDate && showTime

    Row {
        id: clockRow
        spacing: Math.round(8 * Config.scale)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: clockSection.showDate
            text: clockSection.clockDate ? Qt.formatDate(clockSection.clockDate, Config.bar.clockDateFormat) : ""
            color: Config.colors.textSecondary
            font.family: Config.font.family
            font.pixelSize: Math.round(Config.bar.fontSizeClock * 0.62)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: clockSection.showSeparator
            text: "·"
            color: Config.colors.textMuted
            font.family: Config.font.family
            font.pixelSize: Config.bar.fontSizeClock
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: clockSection.showTime
            text: clockSection.clockDate ? Qt.formatTime(clockSection.clockDate, Config.bar.clockTimeFormat) : "--:--"
            color: Config.colors.accent
            font.family: Config.font.family
            font.pixelSize: Config.bar.fontSizeClock
            font.weight: Font.Medium
        }
    }
}
