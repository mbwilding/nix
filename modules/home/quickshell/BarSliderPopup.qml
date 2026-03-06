pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// Horizontal slider popup pill used by volume, screen brightness, and keyboard
// brightness sections. Caller positions via anchors and binds fraction/iconName.
//
// Signals: openPopupReq / exitPopupReq bubble up to Bar.qml popup manager.
Rectangle {
    id: sliderPopup

    // ── Public API ────────────────────────────────────────────────────────────

    property string popupName: ""       // "volume" | "screen" | "kbd"
    property string iconName: ""        // icon to show inside the popup
    property real fraction: 0         // 0..1  current value
    property string activePopup: ""     // bound to root.activePopup

    property string label: Math.round(fraction * 100) + "%"

    // Fixed width for the label column so all sliders align consistently
    property int labelWidth: 0

    signal setFraction(real v)          // user dragged/clicked to value v
    signal scrollDelta(real delta)      // mouse-wheel notch (+/- 1 per notch)

    signal openPopupReq(string name)
    signal exitPopupReq

    // ── Geometry / appearance ─────────────────────────────────────────────────

    readonly property bool popupOpen: activePopup === popupName

    visible: opacity > 0
    opacity: popupOpen ? 1 : 0
    scale: popupOpen ? 1 : 0.92
    transformOrigin: Item.Bottom

    Behavior on opacity {
        NumberAnimation {
            duration: 120
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: 120
            easing.type: Easing.InOutQuad
        }
    }

    width: Math.round(240 * Config.scale)
    height: Math.round(56 * Config.scale)
    radius: Math.round(10 * Config.scale)

    color: Config.colors.background
    border.color: Config.colors.border
    border.width: 1
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

        IconImage {
            implicitSize: Config.bar.batteryIconSize
            source: Quickshell.iconPath(sliderPopup.iconName)
        }

        // Track (fills remaining space)
        Item {
            id: sliderTrack
            Layout.fillWidth: true
            height: Math.round(20 * Config.scale)

            readonly property real trackW: width
            readonly property real frac: Math.max(0, Math.min(1, sliderPopup.fraction))

            // Rail
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                width: sliderTrack.trackW
                height: Math.round(6 * Config.scale)
                radius: height / 2
                color: Config.colors.border
            }

            // Fill
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                width: sliderTrack.trackW * sliderTrack.frac
                height: Math.round(6 * Config.scale)
                radius: height / 2
                color: Config.colors.accent
            }

            // Thumb
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: sliderTrack.trackW * sliderTrack.frac - width / 2
                width: Math.round(14 * Config.scale)
                height: width
                radius: width / 2
                color: Config.colors.accent
                Behavior on x {
                    NumberAnimation {
                        duration: 60
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
            color: Config.colors.textSecondary
            font.family: Config.font.family
            font.pixelSize: Config.bar.fontSizeStatus
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: sliderPopup.labelWidth
            Layout.fillWidth: false
        }
    }
}
