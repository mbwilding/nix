pragma ComponentBehavior: Bound

import QtQuick
import ".."

// Animated popup wrapper — wraps PopupCard with snappy show/hide animation.
// Snappier than before: 100ms fade with InOutQuart easing.
// Set popupOpen to true/false to show/hide.
PopupCard {
    id: root

    property bool popupOpen: false

    visible: opacity > 0
    opacity: root.popupOpen ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuart
        }
    }
}
