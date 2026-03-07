pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

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

    Connections {
        target: notifs
        function onAnimateOutHistoryEntry(snapId) { bar.animateOutHistoryEntry(snapId) }
    }
}

