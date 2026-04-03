pragma ComponentBehavior: Bound

import QtQuick

import ".."

// Scrollable view for popup cards.
//
// Wraps the repeated pattern of:
//   - WheelHandler for mouse/touchpad scroll
//   - A clipping viewport Item
//   - A content Column (or other item) offset by scrollY
//   - A ThinScrollBar anchored to the right
//
// Usage:
//   PopupScrollView {
//       anchors.fill: parent
//       leftMargin:  Math.round(8 * Config.scale)  // optional overrides
//
//       contentColumn: myCol   // bind to the content Column's id
//
//       Column {
//           id: myCol
//           width: parent.contentWidth   // use contentWidth for correct sizing
//           ...
//       }
//   }
//
// The default property feeds children into the viewport so a bare Column
// inside PopupScrollView just works.
Item {
    id: root

    // Margins around the viewport (excluding the scrollbar side which is fixed)
    property int topMargin: Math.round(8 * Config.scale)
    property int bottomMargin: Math.round(8 * Config.scale)
    property int leftMargin: Math.round(8 * Config.scale)
    // rightMargin is between viewport and scrollbar — kept at 4px
    property int rightMargin: Math.round(4 * Config.scale)

    // Optional thumb color override
    property color thumbColor: Config.colors.textMuted

    // The Column (or Item) whose implicitHeight drives scroll math.
    // Bind this to the id of the content item placed inside PopupScrollView.
    property Item contentColumn: null

    // Expose scrollY so callers can bind col.y: -scrollView.scrollY
    // (the content item itself must set its own y binding)
    property real scrollY: 0

    // Read-only: usable width inside the viewport (accounts for scrollbar)
    readonly property real contentWidth: viewport.width

    readonly property real _contentH: root.contentColumn ? root.contentColumn.implicitHeight : 0
    readonly property real maxScrollY: Math.max(0, _contentH - viewport.height)

    onMaxScrollYChanged: {
        if (root.scrollY > root.maxScrollY)
            root.scrollY = root.maxScrollY;
    }

    default property alias viewportChildren: viewport.data

    WheelHandler {
        target: null
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const step = Math.round(40 * Config.scale);
            root.scrollY = Math.max(0, Math.min(root.maxScrollY, root.scrollY - event.angleDelta.y / 120 * step));
        }
    }

    Item {
        id: viewport
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.right: scrollBar.left
        anchors.topMargin: root.topMargin
        anchors.bottomMargin: root.bottomMargin
        anchors.leftMargin: root.leftMargin
        anchors.rightMargin: root.rightMargin
        clip: true
    }

    ThinScrollBar {
        id: scrollBar
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        scrollY: root.scrollY
        maxScrollY: root.maxScrollY
        contentH: root._contentH
        viewportH: viewport.height
        thumbColor: root.thumbColor
    }
}
