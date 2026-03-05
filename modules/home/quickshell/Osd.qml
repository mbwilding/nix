pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

Scope {
    id: root

    readonly property int hideDelay: 1500

    // Ordered list of slot keys in activation order — first triggered is index
    // 0 (top), newest is last (bottom). Cleared when the panel hides so the
    // next session starts fresh.
    property var slotOrder: []

    function activate(key) {
        if (root.slotOrder.indexOf(key) === -1) {
            root.slotOrder = root.slotOrder.concat(key);
        }
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: root.hideDelay
        onTriggered: root.anyVisible = false
        // slotOrder is cleared by the slide animation's onFinished so the
        // panel height stays intact for the full duration of the slide-out.
    }

    Timer {
        id: clearTimer
        interval: 250  // matches slide animation duration
        onTriggered: root.slotOrder = []
    }

    property bool anyVisible: false

    // Slot data looked up by key in the Repeater delegate
    function slotIcon(key) {
        if (key === "volume") {
            const audio = Pipewire.defaultAudioSink?.audio;
            if (!audio || audio.muted) return "audio-volume-muted-symbolic";
            const vol = audio.volume;
            if (vol <= 0.33) return "audio-volume-low-symbolic";
            if (vol <= 0.66) return "audio-volume-medium-symbolic";
            return "audio-volume-high-symbolic";
        }
        if (key === "screen") return "video-display-brightness-symbolic";
        if (key === "kbd")    return "input-keyboard-brightness";
        return "";
    }

    function slotValue(key) {
        if (key === "volume") return Pipewire.defaultAudioSink?.audio.volume ?? 0;
        if (key === "screen") return root.screenBrightness;
        if (key === "kbd")    return root.kbdBrightness;
        return 0;
    }

    function slotLabel(key) {
        return Math.round(root.slotValue(key) * 100) + "%";
    }

    function slotMaxLabel(key) {
        return key === "volume" ? "150%" : "100%";
    }

    // ── Volume ────────────────────────────────────────────────────────────────
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

        function onVolumeChanged() {
            root.anyVisible = true;
            root.activate("volume");
        }

        function onMutedChanged() {
            root.anyVisible = true;
            root.activate("volume");
        }
    }

    // ── Screen brightness ─────────────────────────────────────────────────────
    property real screenBrightness: 0
    property int _screenRaw: -1
    property int _screenMax: 1

    Process {
        command: ["cat", "/sys/class/backlight/amdgpu_bl1/max_brightness"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v > 0) root._screenMax = v;
            }
        }
    }

    Timer {
        interval: 200
        repeat: true
        running: true
        onTriggered: screenPollProc.running = true
    }

    Process {
        id: screenPollProc
        command: ["cat", "/sys/class/backlight/amdgpu_bl1/brightness"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v !== root._screenRaw) {
                    root._screenRaw = v;
                    root.screenBrightness = v / root._screenMax;
                    root.anyVisible = true;
                    root.activate("screen");
                }
            }
        }
    }

    // ── Keyboard brightness ───────────────────────────────────────────────────
    property real kbdBrightness: 0
    property int _kbdRaw: -1
    property int _kbdMax: 1

    Process {
        command: ["cat", "/sys/class/leds/platform::kbd_backlight/max_brightness"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v > 0) root._kbdMax = v;
            }
        }
    }

    Timer {
        interval: 200
        repeat: true
        running: true
        onTriggered: kbdPollProc.running = true
    }

    Process {
        id: kbdPollProc
        command: ["cat", "/sys/class/leds/platform::kbd_backlight/brightness"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v !== root._kbdRaw) {
                    root._kbdRaw = v;
                    root.kbdBrightness = v / root._kbdMax;
                    root.anyVisible = true;
                    root.activate("kbd");
                }
            }
        }
    }

    // ── Panel ─────────────────────────────────────────────────────────────────
    readonly property int panelHeight: root.slotOrder.length * 50 + 16

    PanelWindow {
        anchors.bottom: true
        exclusiveZone: 0
        color: "transparent"
        mask: Region {}

        implicitWidth: 400
        implicitHeight: root.panelHeight

        Rectangle {
            id: panel
            width: parent.width
            height: root.panelHeight
            radius: 12
            color: "#80000000"

            transform: Translate {
                y: root.anyVisible ? 0 : panel.height
                Behavior on y {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.InOutQuad
                        onFinished: if (!root.anyVisible) clearTimer.start()
                    }
                }
            }

            opacity: root.anyVisible ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
            }

            Column {
                anchors {
                    fill: parent
                    topMargin: 8
                    bottomMargin: 8
                }

                Repeater {
                    model: root.slotOrder

                    OsdRow {
                        required property string modelData
                        width: parent.width
                        iconName: root.slotIcon(modelData)
                        value: root.slotValue(modelData)
                        label: root.slotLabel(modelData)
                        maxLabel: root.slotMaxLabel(modelData)
                    }
                }
            }
        }
    }
}
