pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import ".."

// Icon + gradient slider track + percentage label row.
// Pure layout — no card background, no border, no popup logic.
// Used by BrightnessPopup (embedded rows inside a shared card).
Item {
    id: root

    property string iconName: ""
    property real   fraction: 0         // 0..1
    property string label: Math.round(fraction * 100) + "%"
    property int    labelWidth: 0
    property real   iconOffset: 0       // vertical nudge for the icon

    signal setFraction(real v)
    signal scrollDelta(real delta)
    signal entered                      // pointer entered the track area

    implicitHeight: Math.round(58 * Config.scale)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin:  Math.round(12 * Config.scale)
        anchors.rightMargin: Math.round(12 * Config.scale)
        spacing: Math.round(10 * Config.scale)

        Item {
            implicitWidth:  Config.bar.batteryIconSize
            implicitHeight: Config.bar.batteryIconSize

            IconImage {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: root.iconOffset
                implicitSize: Config.bar.batteryIconSize
                source: Quickshell.iconPath(root.iconName)
            }
        }

        // Track
        Item {
            id: sliderTrack
            Layout.fillWidth: true
            height: Math.round(20 * Config.scale)

            readonly property real trackW: width
            readonly property real frac: Math.max(0, Math.min(1, root.fraction))

            GradientProgressBar {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                width: sliderTrack.trackW
                value: sliderTrack.frac
            }

            // Thumb glow
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: sliderTrack.trackW * sliderTrack.frac - width / 2
                width: Math.round(18 * Config.scale)
                height: width
                radius: width / 2
                color: Config.colors.glowAccent
                opacity: 0.55
                Behavior on x { NumberAnimation { duration: 70; easing.type: Easing.OutQuart } }
            }

            // Thumb
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: sliderTrack.trackW * sliderTrack.frac - width / 2
                width: Math.round(14 * Config.scale)
                height: width
                radius: width / 2
                color: Config.colors.sliderThumb
                Behavior on x { NumberAnimation { duration: 70; easing.type: Easing.OutQuart } }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.SizeHorCursor
                onEntered: root.entered()

                function setFromX(mx) {
                    root.setFraction(Math.max(0, Math.min(1, mx / sliderTrack.trackW)));
                    root.entered();
                }

                onPressed:        mouse => setFromX(mouse.x)
                onPositionChanged: mouse => { if (pressed) setFromX(mouse.x); }
                onWheel:          wheel => {
                    root.scrollDelta(wheel.angleDelta.y / 120);
                    root.entered();
                }
            }
        }

        // Percentage label
        Text {
            text: root.label
            color: Config.colors.textPrimary
            font.family: Config.font.family
            font.pixelSize: Config.bar.fontSizePopup
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: root.labelWidth
            Layout.fillWidth: false
        }
    }
}
