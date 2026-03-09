pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import ".."
import "../components"

Item {
    id: root

    property real displayValue: 0
    property real value: 0
    property string iconName: ""
    property string label: ""
    property real iconOffset: 0     // vertical nudge for the icon

    implicitHeight: Config.osd.rowHeight
    implicitWidth: Config.osd.panelWidth
    onValueChanged: displayValue = value

    Behavior on displayValue {
        NumberAnimation {
            duration: Config.osd.animateSpeed
            easing.type: Easing.OutCubic
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Math.round(14 * Config.scale)
            rightMargin: Math.round(16 * Config.scale)
        }
        spacing: Math.round(10 * Config.scale)

        Item {
                implicitWidth: Config.osd.iconSize
                implicitHeight: Config.osd.iconSize

                IconImage {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: root.iconOffset
                    implicitSize: Config.osd.iconSize
                    source: Quickshell.iconPath(root.iconName)
                }
            }

        GradientProgressBar {
            Layout.fillWidth: true
            barHeight: Config.osd.barHeight
            value: root.displayValue
        }

        Text {
            text: root.label
            color: Config.colors.textPrimary
            font.family: Config.font.family
            font.bold: true
            font.pixelSize: Config.font.sizeXl
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: labelMetrics.boundingRect.width

            TextMetrics {
                id: labelMetrics
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeXl
                text: "100%"
            }
        }
    }
}
