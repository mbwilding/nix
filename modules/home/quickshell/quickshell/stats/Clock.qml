pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import ".."

// Large clock + date display for the top menu drawer.
// Distinct from the bottom bar clock — bigger, centred, shown permanently.
Item {
    id: root

    implicitWidth: col.implicitWidth + Math.round(40 * Config.scale)
    implicitHeight: col.implicitHeight + Math.round(28 * Config.scale)

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        spacing: Math.round(4 * Config.scale)

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(clock.date, Config.bar.clockTimeFormat)
            color: Config.colors.accent
            font.family: Config.font.family
            font.pixelSize: Config.stats.fontSizeTime
            font.weight: Font.Medium
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDate(clock.date, Config.bar.clockDateFormat)
            color: Config.colors.textSecondary
            font.family: Config.font.family
            font.pixelSize: Config.stats.fontSizeDate
        }
    }
}
