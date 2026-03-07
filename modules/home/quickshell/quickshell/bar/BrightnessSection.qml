pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import ".."
import "../components"

// Generic brightness bar section: trigger icon + horizontal slider popup.
// Reads state from BrightnessService singleton; no internal polling.
//
// Set popupName to "screen" or "kbd", iconName to the appropriate icon,
// and bind brightness/available/setBrightness to the relevant service properties.
//
// Bar.qml instantiates this twice — once for screen, once for keyboard.
Item {
    id: brightnessSection

    // ── Public API ────────────────────────────────────────────────────────────

    property string popupName: ""           // "screen" | "kbd"
    property string iconName: ""            // icon shown in trigger + popup
    property string activePopup: ""         // bound to root.activePopup
    property int sliderLabelWidth: 0        // bound to root.sliderLabelWidth

    // Brightness state — callers bind to BrightnessService.*
    property real brightness: 0            // 0..1
    property bool available: false

    // Optional vertical offset for the trigger icon (positive = down, negative = up)
    property real iconOffset: 0
    // Optional vertical offset for the icon inside the popup
    property real popupIconOffset: 0

    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq
    signal keepAliveReq
    signal setBrightnessReq(real frac)      // emitted when user moves slider

    // Expose the popup rectangle so Bar.qml can include it in the input mask
    property alias popup: brightnessPopup

    readonly property bool popupOpen: activePopup === popupName

    // ── Geometry ──────────────────────────────────────────────────────────────

    implicitWidth: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    implicitHeight: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    visible: available

    containmentMask: Item {
        x: brightnessSection.popupOpen ? -Math.max(0, (brightnessPopup.width - brightnessSection.width) / 2) : 0
        y: brightnessSection.popupOpen ? -brightnessPopup.height - Config.bar.popupOffset : 0
        width: brightnessSection.popupOpen ? Math.max(brightnessSection.width, brightnessPopup.width) : brightnessSection.width
        height: brightnessSection.popupOpen ? brightnessPopup.height + Config.bar.popupOffset + brightnessSection.height : brightnessSection.height
    }

    // ── Trigger ───────────────────────────────────────────────────────────────

    MouseArea {
        id: triggerArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: brightnessSection.openPopupReq(brightnessSection.popupName)
        onExited: brightnessSection.keepPopupReq()
        onWheel: wheel => {
            brightnessSection.setBrightnessReq(
                Math.max(0, Math.min(1, brightnessSection.brightness + (wheel.angleDelta.y / 120) * 0.05))
            );
            brightnessSection.keepAliveReq();
        }
    }

    IconImage {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: brightnessSection.iconOffset
        implicitSize: Config.bar.batteryIconSize
        source: Quickshell.iconPath(brightnessSection.iconName)
    }

    // ── Popup ─────────────────────────────────────────────────────────────────

    BarSliderPopup {
        id: brightnessPopup
        popupName: brightnessSection.popupName
        iconName: brightnessSection.iconName
        fraction: brightnessSection.brightness
        activePopup: brightnessSection.activePopup
        labelWidth: brightnessSection.sliderLabelWidth
        iconOffset: brightnessSection.popupIconOffset

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        onOpenPopupReq: name => brightnessSection.openPopupReq(name)
        onExitPopupReq: brightnessSection.exitPopupReq()

        onSetFraction: v => brightnessSection.setBrightnessReq(v)
        onScrollDelta: delta => brightnessSection.setBrightnessReq(
            Math.max(0, Math.min(1, brightnessSection.brightness + delta * 0.05))
        )
    }
}
