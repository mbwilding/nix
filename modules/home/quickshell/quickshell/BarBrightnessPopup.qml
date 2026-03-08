pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "components"

// Combined brightness popup: stacked screen + keyboard slider rows inside
// one PopupContainer card. Only rows whose device is available are shown.
// Height adjusts automatically based on visible row count.
//
// Each row reuses BarSliderPopup for its icon + track + label layout,
// avoiding the inline slider track duplication from the old implementation.
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
        BarSliderPopup {
            width: parent.width
            height: root.rowH
            visible: root.screenAvailable

            // Override PopupContainer geometry — we're embedded, not floating
            popupOpen: true
            opacity: 1
            radius: 0

            popupName:  root.popupName
            activePopup: root.activePopup
            iconName:   "video-display-brightness-symbolic"
            iconOffset: -3
            fraction:   root.screenFraction
            labelWidth: root.labelWidth

            onSetFraction:    v     => root.setScreenFraction(v)
            onScrollDelta:    delta => root.scrollScreenDelta(delta)
            onOpenPopupReq:   name  => root.openPopupReq(name)
            onExitPopupReq:          root.exitPopupReq()
        }

        // ── Keyboard brightness row ───────────────────────────────────────────
        BarSliderPopup {
            width: parent.width
            height: root.rowH
            visible: root.kbdAvailable

            // Override PopupContainer geometry — we're embedded, not floating
            popupOpen: true
            opacity: 1
            radius: 0

            popupName:  root.popupName
            activePopup: root.activePopup
            iconName:   "input-keyboard-brightness"
            fraction:   root.kbdFraction
            labelWidth: root.labelWidth

            onSetFraction:    v     => root.setKbdFraction(v)
            onScrollDelta:    delta => root.scrollKbdDelta(delta)
            onOpenPopupReq:   name  => root.openPopupReq(name)
            onExitPopupReq:          root.exitPopupReq()
        }
    }
}
