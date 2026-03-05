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

    function playNotificationIfSilent(senderPid) {
        if (!Config.soundEnabled || _notification === "")
            return;
        if (senderPid <= 0) {
            playNotification();
            return;
        }
        _pidCheckProc.soundPath = _notification;
        _pidCheckProc.command = ["sh", "-c", `
            stream_pids=$(pw-dump 2>/dev/null | awk '
                /"type".*PipeWire:Interface:Node/ { pid=""; cls="" }
                /"application\\.process\\.id"/ { match($0, /[0-9]+/, a); pid=a[0] }
                /"media\\.class"/ { match($0, /"media\\.class": *"([^"]+)"/, a); cls=a[1] }
                /"media\\.class"/ && cls ~ /Stream\\/Output\\/Audio/ && pid { print pid }
            ')
            for pid in $stream_pids; do
                cur=$pid
                while [ "$cur" -gt 1 ] 2>/dev/null; do
                    [ "$cur" = "${senderPid}" ] && exit 0
                    cur=$(awk '/^PPid:/{print $2}' /proc/$cur/status 2>/dev/null)
                    [ -z "$cur" ] && break
                done
            done
            exit 1
        `];
        _pidCheckProc.running = true;
    }

    function playVolume() {
        if (Config.soundEnabled && _volume !== "") {
            volumeProc.command = ["paplay", _volume];
            volumeProc.running = true;
        }
    }

    property Process notificationProc: Process {}
    property Process volumeProc: Process {}

    property Process _pidCheckProc: Process {
        property string soundPath: ""
        onExited: exitCode => {
            // script exits 0 if sender has an active audio stream, 1 if not
            if (exitCode !== 0) {
                notificationProc.command = ["paplay", soundPath];
                notificationProc.running = true;
            }
        }
    }

    property Process _resolveNotification: Process {
        command: ["sh", "-c", "IFS=:; for d in ${XDG_DATA_DIRS:-/usr/share}; do f=\"$d/sounds/freedesktop/stereo/message-new-instant.oga\"; [ -f \"$f\" ] && echo \"$f\" && break; done"]
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
