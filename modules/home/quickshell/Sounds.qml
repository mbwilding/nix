pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property string _notification: ""
    property string _volume: ""

    function playNotification() {
        if (Config.soundEnabled && _notification !== "") {
            notificationProc.command = ["paplay", _notification];
            notificationProc.running = true;
        }
    }

    function playVolume() {
        if (Config.soundEnabled && _volume !== "") {
            volumeProc.command = ["paplay", _volume];
            volumeProc.running = true;
        }
    }

    property Process notificationProc: Process {}
    property Process volumeProc: Process {}

    property Process _resolveNotification: Process {
        command: ["sh", "-c", "IFS=:; for d in ${XDG_DATA_DIRS:-/usr/share}; do f=\"$d/sounds/freedesktop/stereo/message.oga\"; [ -f \"$f\" ] && echo \"$f\" && break; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const path = this.text.trim();
                if (path !== "")
                    root._notification = path;
            }
        }
    }

    property Process _resolveVolume: Process {
        command: ["sh", "-c", "IFS=:; for d in ${XDG_DATA_DIRS:-/usr/share}; do f=\"$d/sounds/freedesktop/stereo/audio-volume-change.oga\"; [ -f \"$f\" ] && echo \"$f\" && break; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const path = this.text.trim();
                if (path !== "")
                    root._volume = path;
            }
        }
    }
}
