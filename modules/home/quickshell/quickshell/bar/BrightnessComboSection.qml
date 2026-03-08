pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import ".."
import "../components"

// Combined brightness bar section: a single sun-icon trigger that opens one
// popup containing stacked screen + keyboard brightness slider rows.
//
// Visible whenever at least one of screen/kbd backlight is available.
// Bar.qml instantiates this once instead of two separate BrightnessSection items.
Item {
    id: brightnessCombo

    // ── Public API ────────────────────────────────────────────────────────────

    property string activePopup: ""         // bound to root.activePopup
    property int sliderLabelWidth: 0        // bound to root.sliderLabelWidth

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

    // ── Geometry ──────────────────────────────────────────────────────────────

    implicitWidth: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    implicitHeight: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    visible: brightnessCombo.screenAvailable || brightnessCombo.kbdAvailable

    containmentMask: Item {
        x: brightnessCombo.popupOpen ? -Math.max(0, (brightnessPopup.width - brightnessCombo.width) / 2) : 0
        y: brightnessCombo.popupOpen ? -brightnessPopup.height - Config.bar.popupOffset : 0
        width: brightnessCombo.popupOpen ? Math.max(brightnessCombo.width, brightnessPopup.width) : brightnessCombo.width
        height: brightnessCombo.popupOpen ? brightnessPopup.height + Config.bar.popupOffset + brightnessCombo.height : brightnessCombo.height
    }

    // ── Trigger ───────────────────────────────────────────────────────────────

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: brightnessCombo.openPopupReq("brightness")
        onExited: brightnessCombo.keepPopupReq()
        onWheel: wheel => {
            // Scroll on the icon adjusts screen brightness (primary)
            brightnessCombo.setScreenBrightnessReq(
                Math.max(0, Math.min(1, brightnessCombo.screenBrightness + (wheel.angleDelta.y / 120) * 0.05))
            );
            brightnessCombo.keepAliveReq();
        }
    }

    IconImage {
        anchors.centerIn: parent
        implicitSize: Config.bar.batteryIconSize
        source: Quickshell.iconPath("high-brightness-symbolic")
    }

    // ── Popup ─────────────────────────────────────────────────────────────────

    BarBrightnessPopup {
        id: brightnessPopup
        activePopup: brightnessCombo.activePopup
        labelWidth: brightnessCombo.sliderLabelWidth

        screenFraction: brightnessCombo.screenBrightness
        screenAvailable: brightnessCombo.screenAvailable
        kbdFraction: brightnessCombo.kbdBrightness
        kbdAvailable: brightnessCombo.kbdAvailable

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        onOpenPopupReq: name => brightnessCombo.openPopupReq(name)
        onExitPopupReq: brightnessCombo.exitPopupReq()

        onSetScreenFraction: v => brightnessCombo.setScreenBrightnessReq(v)
        onSetKbdFraction: v => brightnessCombo.setKbdBrightnessReq(v)
        onScrollScreenDelta: delta => brightnessCombo.setScreenBrightnessReq(
            Math.max(0, Math.min(1, brightnessCombo.screenBrightness + delta * 0.05))
        )
        onScrollKbdDelta: delta => brightnessCombo.setKbdBrightnessReq(
            Math.max(0, Math.min(1, brightnessCombo.kbdBrightness + delta * 0.05))
        )
    }
}
