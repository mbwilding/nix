pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import "bar"
import "lockscreen"
import "notifications"
import "osd"
import "stats"

ShellRoot {
    id: root

    Bar {
        id: bar
        notifHistory: notifs.notifHistory
        onRemoveHistoryEntry: entryId => notifs.removeHistoryEntry(entryId)
        onDismissAllNotifs: notifs.dismissAll()
    }

    // Stats {}

    Osd {}

    Notifications {
        id: notifs
    }

    LockScreen {
        id: lockScreen
        notifHistory: notifs.notifHistory
    }

    Connections {
        target: notifs

        function onAnimateOutHistoryEntry(snapId) {
            bar.animateOutHistoryEntry(snapId);
        }
    }
}
