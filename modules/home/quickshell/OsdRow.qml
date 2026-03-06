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
            easing.type: Easing.OutCubic
        }
    }

    implicitHeight: Config.osd.rowHeight
    implicitWidth: Config.osd.panelWidth

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Math.round(14 * Config.scale)
            rightMargin: Math.round(16 * Config.scale)
        }
        spacing: Math.round(10 * Config.scale)

        IconImage {
            implicitSize: Config.osd.iconSize
            source: Quickshell.iconPath(root.iconName)
        }

        // Progress track
        Item {
            Layout.fillWidth: true
            implicitHeight: Config.osd.barHeight + Math.round(4 * Config.scale)

            // Rail
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                width: parent.width
                height: Config.osd.barHeight
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.10)
            }

            // Gradient fill (accent → accentAlt, matching the volume slider)
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                width: Math.min(parent.width, parent.width * root.displayValue)
                height: Config.osd.barHeight
                radius: height / 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Config.colors.accent }
                    GradientStop { position: 1.0; color: Config.colors.accentAlt }
                }
            }
        }

        Text {
            text: root.label
            color: Config.colors.textPrimary
            font.family: Config.font.family
            font.bold: true
            font.pixelSize: Config.font.sizeOsd
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: labelMetrics.boundingRect.width

            TextMetrics {
                id: labelMetrics
                font.family: Config.font.family
                font.pixelSize: Config.font.sizeOsd
                text: "100%"
            }
        }
    }
}
