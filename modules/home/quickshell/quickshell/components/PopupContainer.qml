pragma ComponentBehavior: Bound

import QtQuick
import ".."

// Animated popup wrapper — wraps PopupCard with the standard show/hide
// opacity + scale animation used by all bar section popups.
//
// Set popupOpen to true/false to show/hide.
// Use anchors to position relative to the trigger item.
// Place content inside via the default property.
PopupCard {
    id: root

    property bool popupOpen: false

    visible: opacity > 0
    opacity: root.popupOpen ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: 150
            easing.type: Easing.InOutCubic
        }
    }
}
