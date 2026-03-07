pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

// Singleton brightness state for screen backlight and keyboard backlight.
// Both the bar sections and the OSD read from here — no duplicated polling.
QtObject {
    id: root

    // ── Screen ────────────────────────────────────────────────────────────────

    property string screenDevice: ""
    property int _screenMax: 1
    property int _screenRaw: -1
    property real screenBrightness: 0       // 0..1
    readonly property bool screenAvailable: _screenMax > 1

    // ── Keyboard ─────────────────────────────────────────────────────────────

    property string kbdDevice: ""
    property int _kbdMax: 1
    property int _kbdRaw: -1
    property real kbdBrightness: 0          // 0..1
    readonly property bool kbdAvailable: _kbdMax > 1

    // ── Device discovery ─────────────────────────────────────────────────────

    property Process _screenDiscoverProc: Process {
        command: ["sh", "-c", "ls /sys/class/backlight/ | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const dev = this.text.trim();
                if (dev)
                    root.screenDevice = "/sys/class/backlight/" + dev;
            }
        }
    }

    property Process _screenMaxProc: Process {
        command: ["cat", root.screenDevice + "/max_brightness"]
        running: root.screenDevice !== ""
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v > 0)
                    root._screenMax = v;
            }
        }
    }

    property Process _kbdDiscoverProc: Process {
        command: ["sh", "-c", "ls /sys/class/leds/ | grep kbd_backlight | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const dev = this.text.trim();
                if (dev)
                    root.kbdDevice = "/sys/class/leds/" + dev;
            }
        }
    }

    property Process _kbdMaxProc: Process {
        command: ["cat", root.kbdDevice + "/max_brightness"]
        running: root.kbdDevice !== ""
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v > 0)
                    root._kbdMax = v;
            }
        }
    }

    // ── Polling ───────────────────────────────────────────────────────────────

    property Process _screenPollProc: Process {
        id: screenPollProc
        command: ["cat", root.screenDevice + "/brightness"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v !== root._screenRaw) {
                    root._screenRaw = v;
                    root.screenBrightness = root._screenMax > 0 ? v / root._screenMax : 0;
                }
            }
        }
    }

    property Timer _screenPollTimer: Timer {
        interval: 200
        repeat: true
        running: root.screenDevice !== ""
        onTriggered: root._screenPollProc.running = true
    }

    property Process _kbdPollProc: Process {
        id: kbdPollProc
        command: ["cat", root.kbdDevice + "/brightness"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v !== root._kbdRaw) {
                    root._kbdRaw = v;
                    root.kbdBrightness = root._kbdMax > 0 ? v / root._kbdMax : 0;
                }
            }
        }
    }

    property Timer _kbdPollTimer: Timer {
        interval: 200
        repeat: true
        running: root.kbdDevice !== ""
        onTriggered: root._kbdPollProc.running = true
    }

    // ── Write helpers ─────────────────────────────────────────────────────────

    property Process _screenWriteProc: Process {}
    property Process _kbdWriteProc: Process {}

    function setScreenBrightness(frac) {
        const raw = Math.round(frac * root._screenMax);
        root._screenWriteProc.command = [
            "brightnessctl",
            "--device=" + root.screenDevice.split("/").pop(),
            "set",
            String(raw)
        ];
        root._screenWriteProc.running = true;
    }

    function setKbdBrightness(frac) {
        const raw = Math.round(frac * root._kbdMax);
        root._kbdWriteProc.command = [
            "brightnessctl",
            "--device=" + root.kbdDevice.split("/").pop(),
            "set",
            String(raw)
        ];
        root._kbdWriteProc.running = true;
    }
}
