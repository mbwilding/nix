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
        unreadCount: notifs.unreadCount
        onMarkHistoryRead: notifs.markHistoryRead()
        onRemoveHistoryEntry: entryId => notifs.removeHistoryEntry(entryId)
        onClearHistory: notifs.clearHistory()
    }
}

