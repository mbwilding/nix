pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    property string iconName: ""
    property real value: 0
    property string label: ""
    property string maxLabel: "100%"

    implicitHeight: 50
    implicitWidth: 400

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 15
        }

        IconImage {
            implicitSize: 30
            source: Quickshell.iconPath(root.iconName)
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 10
            radius: 20
            color: "#50ffffff"

            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                property real excessRatio: Math.min(1.0, Math.max(0.0, (root.value - 1.0) / 0.5))
                implicitWidth: Math.min(parent.width, parent.width * root.value)
                radius: parent.radius
                color: Qt.rgba(1, 1 - excessRatio, 1 - excessRatio, 1)
            }
        }

        Text {
            text: root.label
            color: "white"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: labelMetrics.boundingRect.width
            Layout.leftMargin: parent.spacing

            TextMetrics {
                id: labelMetrics
                font: parent.font
                text: root.maxLabel
            }
        }
    }
}
