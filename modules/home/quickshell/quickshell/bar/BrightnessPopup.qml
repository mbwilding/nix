pragma ComponentBehavior: Bound

import QtQuick

import ".."
import "../components"

PopupContainer {
    id: root

    property bool kbdAvailable: false
    property bool screenAvailable: false
    property int labelWidth: 0
    property real kbdFraction: 0
    property real screenFraction: 0
    property string activePopup: ""
    property string popupName: "brightness"

    readonly property int rowH: Math.round(58 * Config.scale)
    readonly property int visibleRows: (root.screenAvailable ? 1 : 0) + (root.kbdAvailable ? 1 : 0)

    signal exitPopupReq
    signal openPopupReq(string name)
    signal scrollKbdDelta(real delta)
    signal scrollScreenDelta(real delta)
    signal setKbdFraction(real v)
    signal setScreenFraction(real v)

    height: root.visibleRows * root.rowH
    popupOpen: root.activePopup === root.popupName
    width: Math.round(250 * Config.scale)
    z: 20

    HoverHandler {
        onHoveredChanged: {
            if (hovered)
                root.openPopupReq(root.popupName);
            else
                root.exitPopupReq();
        }
    }

    Column {
        anchors.fill: parent

        SliderRow {
            width: parent.width
            height: root.rowH
            visible: root.screenAvailable

            iconName: "video-display-brightness-symbolic"
            iconOffset: -3
            fraction: root.screenFraction
            labelWidth: root.labelWidth

            onSetFraction: v => root.setScreenFraction(v)
            onScrollDelta: d => root.scrollScreenDelta(d)
            onEntered: root.openPopupReq(root.popupName)
        }

        SliderRow {
            width: parent.width
            height: root.rowH
            visible: root.kbdAvailable

            iconName: "input-keyboard-brightness"
            fraction: root.kbdFraction
            labelWidth: root.labelWidth

            onSetFraction: v => root.setKbdFraction(v)
            onScrollDelta: d => root.scrollKbdDelta(d)
            onEntered: root.openPopupReq(root.popupName)
        }
    }
}
