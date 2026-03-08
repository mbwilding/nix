pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "components"

// Combined brightness popup: stacked screen + keyboard slider rows inside
// one PopupContainer card. Only rows whose device is available are shown.
// Height adjusts automatically based on visible row count.
PopupContainer {
    id: root

    // ── Public API ────────────────────────────────────────────────────────────

    property string popupName: "brightness"
    property string activePopup: ""

    // Screen brightness
    property real screenFraction: 0
    property bool screenAvailable: false

    // Keyboard brightness
    property real kbdFraction: 0
    property bool kbdAvailable: false

    // Shared fixed width for percentage labels (bound to root.sliderLabelWidth)
    property int labelWidth: 0

    signal openPopupReq(string name)
    signal exitPopupReq
    signal setScreenFraction(real v)
    signal setKbdFraction(real v)
    signal scrollScreenDelta(real delta)
    signal scrollKbdDelta(real delta)

    // ── Geometry ──────────────────────────────────────────────────────────────

    popupOpen: root.activePopup === root.popupName

    readonly property int rowH: Math.round(58 * Config.scale)
    readonly property int visibleRows: (root.screenAvailable ? 1 : 0) + (root.kbdAvailable ? 1 : 0)

    width: Math.round(250 * Config.scale)
    height: root.visibleRows * root.rowH

    z: 20

    // ── Hover ─────────────────────────────────────────────────────────────────

    HoverHandler {
        onHoveredChanged: {
            if (hovered)
                root.openPopupReq(root.popupName);
            else
                root.exitPopupReq();
        }
    }

    // ── Rows ──────────────────────────────────────────────────────────────────

    Column {
        anchors.fill: parent

        // ── Screen brightness row ─────────────────────────────────────────────
        Item {
            width: parent.width
            height: root.rowH
            visible: root.screenAvailable

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
                        anchors.verticalCenterOffset: -3
                        implicitSize: Config.bar.batteryIconSize
                        source: Quickshell.iconPath("video-display-brightness-symbolic")
                    }
                }

                Item {
                    id: screenTrack
                    Layout.fillWidth: true
                    height: Math.round(20 * Config.scale)

                    readonly property real frac: Math.max(0, Math.min(1, root.screenFraction))

                    GradientProgressBar {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        width: screenTrack.width
                        value: screenTrack.frac
                    }

                    // Glow blob behind thumb
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: screenTrack.width * screenTrack.frac - width / 2
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
                        x: screenTrack.width * screenTrack.frac - width / 2
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
                        onEntered: root.openPopupReq(root.popupName)

                        function setFromX(mx) {
                            const v = Math.max(0, Math.min(1, mx / screenTrack.width));
                            root.setScreenFraction(v);
                            root.openPopupReq(root.popupName);
                        }

                        onPressed: mouse => setFromX(mouse.x)
                        onPositionChanged: mouse => { if (pressed) setFromX(mouse.x); }
                        onWheel: wheel => {
                            root.scrollScreenDelta(wheel.angleDelta.y / 120);
                            root.openPopupReq(root.popupName);
                        }
                    }
                }

                Text {
                    text: Math.round(root.screenFraction * 100) + "%"
                    color: Config.colors.textPrimary
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizePopup
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: root.labelWidth
                    Layout.fillWidth: false
                }
            }
        }

        // ── Keyboard brightness row ───────────────────────────────────────────
        Item {
            width: parent.width
            height: root.rowH
            visible: root.kbdAvailable

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
                        implicitSize: Config.bar.batteryIconSize
                        source: Quickshell.iconPath("input-keyboard-brightness")
                    }
                }

                Item {
                    id: kbdTrack
                    Layout.fillWidth: true
                    height: Math.round(20 * Config.scale)

                    readonly property real frac: Math.max(0, Math.min(1, root.kbdFraction))

                    GradientProgressBar {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        width: kbdTrack.width
                        value: kbdTrack.frac
                    }

                    // Glow blob behind thumb
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: kbdTrack.width * kbdTrack.frac - width / 2
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
                        x: kbdTrack.width * kbdTrack.frac - width / 2
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
                        onEntered: root.openPopupReq(root.popupName)

                        function setFromX(mx) {
                            const v = Math.max(0, Math.min(1, mx / kbdTrack.width));
                            root.setKbdFraction(v);
                            root.openPopupReq(root.popupName);
                        }

                        onPressed: mouse => setFromX(mouse.x)
                        onPositionChanged: mouse => { if (pressed) setFromX(mouse.x); }
                        onWheel: wheel => {
                            root.scrollKbdDelta(wheel.angleDelta.y / 120);
                            root.openPopupReq(root.popupName);
                        }
                    }
                }

                Text {
                    text: Math.round(root.kbdFraction * 100) + "%"
                    color: Config.colors.textPrimary
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizePopup
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: root.labelWidth
                    Layout.fillWidth: false
                }
            }
        }
    }
}
