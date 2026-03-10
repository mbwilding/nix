pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import ".."
import "../components"

// Brightness bar section: a single sun-icon trigger that opens one
// popup containing stacked screen + keyboard brightness slider rows.
//
// Visible whenever at least one of screen/kbd backlight is available.
BarSectionItem {
    id: brightnessSection

    // ── Public API ────────────────────────────────────────────────────────────

    property string activePopup: ""         // bound to root.activePopup
    property int sliderLabelWidth: 0        // bound to root.sliderLabelWidth
    property int statusLabelWidth: 0        // bound to root.statusLabelWidth
    // Screen state — bind to BrightnessService.*
    property real screenBrightness: 0
    property bool screenAvailable: false

    // Keyboard state — bind to BrightnessService.*
    property real kbdBrightness: 0
    property bool kbdAvailable: false

    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq
    signal keepAliveReq
    signal setScreenBrightnessReq(real frac)
    signal setKbdBrightnessReq(real frac)

    // Expose the popup rectangle so Bar.qml can include it in the input mask
    property alias popup: brightnessPopup

    readonly property bool popupOpen: activePopup === "brightness"
    popupItem: brightnessPopup

    // ── Geometry ──────────────────────────────────────────────────────────────

    property int statusButtonExtraWidth: Math.round(34 * Config.scale)

    implicitWidth: Config.bar.batteryIconSize + statusButtonExtraWidth
    implicitHeight: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    visible: brightnessSection.screenAvailable || brightnessSection.kbdAvailable

    // ── Trigger ───────────────────────────────────────────────────────────────

    MouseArea {
        id: brightnessTrigger
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: brightnessSection.openPopupReq("brightness")
        onExited: brightnessSection.keepPopupReq()
        onWheel: wheel => {
            // Scroll on the icon adjusts screen brightness (primary)
            brightnessSection.setScreenBrightnessReq(
                Math.max(0, Math.min(1, brightnessSection.screenBrightness + (wheel.angleDelta.y / 120) * 0.05))
            );
            brightnessSection.keepAliveReq();
        }
    }

    BarButton {
        anchors.fill: parent
        hovered: brightnessTrigger.containsMouse
        popupOpen: brightnessSection.popupOpen
        clickable: false

        Row {
            anchors.centerIn: parent
            spacing: Math.round(3 * Config.scale)

            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: Config.bar.batteryIconSize
                source: Quickshell.iconPath("high-brightness-symbolic")
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: brightnessSection.screenAvailable
                text: Math.round(brightnessSection.screenBrightness * 100) + "%"
                width: brightnessSection.statusLabelWidth > 0 ? brightnessSection.statusLabelWidth : implicitWidth
                horizontalAlignment: Text.AlignRight
                color: Config.colors.textPrimary
                font.family: Config.font.family
                font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.72)
            }
        }
    }

    // ── Popup ─────────────────────────────────────────────────────────────────

    BrightnessPopup {
        id: brightnessPopup
        activePopup: brightnessSection.activePopup
        labelWidth: brightnessSection.sliderLabelWidth

        screenFraction: brightnessSection.screenBrightness
        screenAvailable: brightnessSection.screenAvailable
        kbdFraction: brightnessSection.kbdBrightness
        kbdAvailable: brightnessSection.kbdAvailable

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        onOpenPopupReq: name => brightnessSection.openPopupReq(name)
        onExitPopupReq: brightnessSection.exitPopupReq()

        onSetScreenFraction: v => brightnessSection.setScreenBrightnessReq(v)
        onSetKbdFraction: v => brightnessSection.setKbdBrightnessReq(v)
        onScrollScreenDelta: delta => brightnessSection.setScreenBrightnessReq(
            Math.max(0, Math.min(1, brightnessSection.screenBrightness + delta * 0.05))
        )
        onScrollKbdDelta: delta => brightnessSection.setKbdBrightnessReq(
            Math.max(0, Math.min(1, brightnessSection.kbdBrightness + delta * 0.05))
        )
    }
}
