pragma ComponentBehavior: Bound

import QtQuick
import ".."

// Base Item for bar sections that show a floating popup above the pill.
//
// Provides a containmentMask that expands upward to cover the popup when
// it is open, so that the transparent PanelWindow overlay still passes
// pointer events to both the bar icon and the popup above it.
//
// Usage:
//   BarSectionItem {
//       id: mySection
//       popupOpen: activePopup === "myName"
//       popupItem: myPopup       // the PopupContainer (or similar) for this section
//       ...
//   }
Item {
    id: root

    // Whether the section's popup is currently visible.
    property bool popupOpen: false

    // The popup Item whose width/height define the expanded mask area.
    // Bind to the PopupContainer id declared in the same file.
    property Item popupItem: null

    containmentMask: Item {
        readonly property real _popupW: root.popupItem ? root.popupItem.width  : 0
        readonly property real _popupH: root.popupItem ? root.popupItem.height : 0

        x:      root.popupOpen ? -Math.max(0, (_popupW - root.width) / 2) : 0
        y:      root.popupOpen ? -_popupH - Config.bar.popupOffset : 0
        width:  root.popupOpen ? Math.max(root.width, _popupW) : root.width
        height: root.popupOpen ? _popupH + Config.bar.popupOffset + root.height : root.height
    }
}
