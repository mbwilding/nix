pragma ComponentBehavior: Bound

import QtQuick
import "components"

// Horizontal slider popup pill used by volume, screen brightness, and keyboard
// brightness sections. Caller positions via anchors and binds fraction/iconName.
//
// Signals: openPopupReq / exitPopupReq bubble up to Bar.qml popup manager.
PopupContainer {
    id: sliderPopup

    // ── Public API ────────────────────────────────────────────────────────────

    property string popupName: ""       // "volume" | "screen" | "kbd"
    property string iconName: ""
    property real   fraction: 0         // 0..1
    property string activePopup: ""

    property string label: Math.round(fraction * 100) + "%"
    property int    labelWidth: 0
    property real   iconOffset: 0

    signal setFraction(real v)
    signal scrollDelta(real delta)

    signal openPopupReq(string name)
    signal exitPopupReq

    // ── Geometry / appearance ─────────────────────────────────────────────────

    popupOpen: activePopup === popupName

    width:  Math.round(250 * Config.scale)
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

    // ── Content ───────────────────────────────────────────────────────────────

    SliderRow {
        anchors.fill: parent
        iconName:    sliderPopup.iconName
        fraction:    sliderPopup.fraction
        label:       sliderPopup.label
        labelWidth:  sliderPopup.labelWidth
        iconOffset:  sliderPopup.iconOffset

        onSetFraction:  v => sliderPopup.setFraction(v)
        onScrollDelta:  d => sliderPopup.scrollDelta(d)
        onEntered:          sliderPopup.openPopupReq(sliderPopup.popupName)
    }
}
