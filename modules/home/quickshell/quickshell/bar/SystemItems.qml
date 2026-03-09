pragma Singleton

import QtQuick

// Enum-like constants for items within the System section of the bar.
// Use these values in Config.bar.systemLayout to control which system
// indicators appear and in what order. Separator can appear multiple times.
QtObject {
    // Wi-Fi indicator + popup
    readonly property int wifi: 0
    // Wired ethernet indicator + popup
    readonly property int ethernet: 1
    // Bluetooth indicator + popup
    readonly property int bluetooth: 2
    // Speaker / microphone volume + popup
    readonly property int volume: 3
    // Screen & keyboard brightness + popup
    readonly property int brightness: 4
    // Power / session menu (shows battery level when on laptop)
    readonly property int power: 5
    // Notification history
    readonly property int notifications: 7
    // A vertical separator line — can be placed multiple times
    readonly property int separator: 8
}
