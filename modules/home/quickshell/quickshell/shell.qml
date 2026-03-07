pragma ComponentBehavior: Bound

import Quickshell

ShellRoot {
    id: root

    Osd {}

    Notifications {
        id: notifs
    }

    Bar {
        notifHistory: notifs.notifHistory
        onRemoveHistoryEntry: entryId => notifs.removeHistoryEntry(entryId)
        onAnimateOutHistoryEntry: snapId => notifs.animateOutHistoryEntry(snapId)
    }
}

