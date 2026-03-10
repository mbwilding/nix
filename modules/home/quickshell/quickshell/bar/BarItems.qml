pragma Singleton

import QtQuick

// Enum-like constants for top-level bar slots.
// Use these values in Config.bar.layout to control what appears on the bar
// and in what order. Separator can appear multiple times.
QtObject {
    // System tray (application icons)
    readonly property int tray: 0
    // The system indicators group (wifi, ethernet, bt, volume, brightness, power, battery, notif)
    readonly property int system: 1
    // Clock / date display
    readonly property int clock: 2
    // A vertical separator line — can be placed multiple times
    readonly property int separator: 3
    // Pin button — toggles the bar's pinned (always-visible) state
    readonly property int pin: 4
}
