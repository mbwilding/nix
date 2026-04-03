pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import "bar"
import "lockscreen"
import "notifications"
import "osd"
import "stats"
import "wallpaper"

ShellRoot {
    id: root

    Wallpaper {}

    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen
            required property var modelData

            Bar {
                id: bar
                screen: perScreen.modelData
                notifHistory: notifs.notifHistory
                onRemoveHistoryEntry: entryId => notifs.removeHistoryEntry(entryId)
                onDismissAllNotifs: notifs.dismissAll()
            }

            // Stats {
            //     screen: perScreen.modelData
            // }

            Osd {
                screen: perScreen.modelData
            }

            Notifications {
                id: notifs
                screen: perScreen.modelData
            }

            Connections {
                target: notifs

                function onAnimateOutHistoryEntry(snapId) {
                    bar.animateOutHistoryEntry(snapId);
                }
            }
        }
    }

    LockScreen {
        id: lockScreen
        notifHistory: []
    }
}
