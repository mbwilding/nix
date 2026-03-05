pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    property real value: 0
    property string iconName: ""
    property string label: ""
    property int animateSpeed: 150

    // Animated proxy — bar and colour bind to this, not value directly
    property real displayValue: 0
    onValueChanged: displayValue = value
    Behavior on displayValue {
        NumberAnimation { duration: root.animateSpeed; easing.type: Easing.OutQuad }
    }

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
                property real excessRatio: Math.min(1.0, Math.max(0.0, (root.displayValue - 1.0) / 0.5))
                implicitWidth: Math.min(parent.width, parent.width * root.displayValue)
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
                font.pixelSize: 14
                text: "100%"
            }
        }
    }
}
