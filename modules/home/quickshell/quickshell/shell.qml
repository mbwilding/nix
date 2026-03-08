pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "bar"

ShellRoot {
    id: root

    Osd {}

    Notifications {
        id: notifs
    }

    Bar {
        id: bar
        notifHistory: notifs.notifHistory
        onRemoveHistoryEntry: entryId => notifs.removeHistoryEntry(entryId)
        onDismissAllNotifs: notifs.dismissAll()
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
