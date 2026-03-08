pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "components"

// Horizontal slider popup pill used by volume, screen brightness, and keyboard
// brightness sections. Caller positions via anchors and binds fraction/iconName.
//
// Signals: openPopupReq / exitPopupReq bubble up to Bar.qml popup manager.
PopupContainer {
    id: sliderPopup

    // ── Public API ────────────────────────────────────────────────────────────

    property string popupName: ""       // "volume" | "screen" | "kbd"
    property string iconName: ""        // icon to show inside the popup
    property real fraction: 0         // 0..1  current value
    // activePopup drives popupOpen (declared in PopupContainer)
    property string activePopup: ""

    property string label: Math.round(fraction * 100) + "%"

    // Fixed width for the label column so all sliders align consistently
    property int labelWidth: 0

    // Optional vertical nudge for the icon inside the popup (positive = down)
    property real iconOffset: 0

    signal setFraction(real v)          // user dragged/clicked to value v
    signal scrollDelta(real delta)      // mouse-wheel notch (+/- 1 per notch)

    signal openPopupReq(string name)
    signal exitPopupReq

    // ── Geometry / appearance ─────────────────────────────────────────────────

    popupOpen: activePopup === popupName

    width: Math.round(250 * Config.scale)
    height: Math.round(58 * Config.scale)

    z: 20

    // ── Hover ─────────────────────────────────────────────────────────────────

    HoverHandler {
        onHoveredChanged: {
            if (hovered)
                sliderPopup.openPopupReq(sliderPopup.popupName);
            else
                sliderPopup.exitPopupReq();
        }
    }

    // ── Layout ────────────────────────────────────────────────────────────────

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Math.round(12 * Config.scale)
        anchors.rightMargin: Math.round(12 * Config.scale)
        spacing: Math.round(10 * Config.scale)

        Item {
            implicitWidth: Config.bar.batteryIconSize
            implicitHeight: Config.bar.batteryIconSize

            IconImage {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: sliderPopup.iconOffset
                implicitSize: Config.bar.batteryIconSize
                source: Quickshell.iconPath(sliderPopup.iconName)
            }
        }

        // Track (fills remaining space)
        Item {
            id: sliderTrack
            Layout.fillWidth: true
            height: Math.round(20 * Config.scale)

            readonly property real trackW: width
            readonly property real frac: Math.max(0, Math.min(1, sliderPopup.fraction))

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
                color: "#e0e0ff"
                Behavior on x {
                    NumberAnimation {
                        duration: 70
                        easing.type: Easing.OutQuart
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.SizeHorCursor
                onEntered: sliderPopup.openPopupReq(sliderPopup.popupName)

                function setFromX(mx) {
                    const v = Math.max(0, Math.min(1, mx / sliderTrack.trackW));
                    sliderPopup.setFraction(v);
                    sliderPopup.openPopupReq(sliderPopup.popupName);
                }

                onPressed: mouse => setFromX(mouse.x)
                onPositionChanged: mouse => {
                    if (pressed)
                        setFromX(mouse.x);
                }
                onWheel: wheel => {
                    sliderPopup.scrollDelta(wheel.angleDelta.y / 120);
                    sliderPopup.openPopupReq(sliderPopup.popupName);
                }
            }
        }

        // Percentage label
        Text {
            text: sliderPopup.label
            color: Config.colors.textPrimary
            font.family: Config.font.family
            font.pixelSize: Config.bar.fontSizePopup
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: sliderPopup.labelWidth
            Layout.fillWidth: false
        }
    }
}
