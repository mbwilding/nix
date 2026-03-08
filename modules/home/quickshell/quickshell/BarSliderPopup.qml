pragma ComponentBehavior: Bound

import QtQuick
import "components"

PopupContainer {
    id: sliderPopup

    property int labelWidth: 0
    property real fraction: 0
    property real iconOffset: 0
    property string activePopup: ""
    property string iconName: ""
    property string label: Math.round(fraction * 100) + "%"
    property string popupName: ""

    signal exitPopupReq
    signal openPopupReq(string name)
    signal scrollDelta(real delta)
    signal setFraction(real v)

    popupOpen: activePopup === popupName
    width: Math.round(250 * Config.scale)
    height: Math.round(58 * Config.scale)
    z: 20

    HoverHandler {
        onHoveredChanged: {
            if (hovered)
                sliderPopup.openPopupReq(sliderPopup.popupName);
            else
                sliderPopup.exitPopupReq();
        }
    }

    SliderRow {
        anchors.fill: parent
        iconName: sliderPopup.iconName
        fraction: sliderPopup.fraction
        label: sliderPopup.label
        labelWidth: sliderPopup.labelWidth
        iconOffset: sliderPopup.iconOffset

        onSetFraction: v => sliderPopup.setFraction(v)
        onScrollDelta: d => sliderPopup.scrollDelta(d)
        onEntered: sliderPopup.openPopupReq(sliderPopup.popupName)
    }
}
