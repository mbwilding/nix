pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    property real displayValue: 0
    property real value: 0
    property string iconName: ""
    property string label: ""

    onValueChanged: displayValue = value
    Behavior on displayValue {
        NumberAnimation {
            duration: Config.osd.animateSpeed
            easing.type: Easing.OutQuad
        }
    }

    implicitHeight: Config.osd.rowHeight
    implicitWidth: Config.osd.panelWidth

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Math.round(10 * Config.scale)
            rightMargin: Math.round(15 * Config.scale)
        }

        IconImage {
            implicitSize: Config.osd.iconSize
            source: Quickshell.iconPath(root.iconName)
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Config.osd.barHeight
            radius: Config.osd.barHeight
            color: Config.colors.backgroundBar

            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                property real excessRatio: Math.min(1.0, Math.max(0.0, (root.displayValue - 1.0) / 0.5))
                implicitWidth: Math.min(parent.width, parent.width * root.displayValue)
                radius: parent.radius
                color: Qt.rgba(
                    Config.colors.accent.r + (1 - Config.colors.accent.r) * excessRatio,
                    Config.colors.accent.g * (1 - excessRatio),
                    Config.colors.accent.b * (1 - excessRatio),
                    1
                )
            }
        }

        Text {
            text: root.label
            color: Config.colors.textPrimary
            font.family: Config.font.family
            font.pixelSize: Config.font.sizeOsd
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: labelMetrics.boundingRect.width
            Layout.leftMargin: parent.spacing

            TextMetrics {
                id: labelMetrics
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeOsd
                text: "100%"
            }
        }
    }
}
