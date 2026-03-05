pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

Scope {
    id: root

    readonly property int hideDelay: 1000

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    property bool volumeVisible: false

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

        function onVolumeChanged() {
            root.volumeVisible = true;
            volumeTimer.restart();
        }

        function onMutedChanged() {
            root.volumeVisible = true;
            volumeTimer.restart();
        }
    }

    Timer {
        id: volumeTimer
        interval: root.hideDelay
        onTriggered: root.volumeVisible = false
    }

    property bool screenBrightnessVisible: false
    property real screenBrightness: 0
    property int _screenRaw: -1
    property int _screenMax: 1

    Process {
        id: screenMaxProc
        command: ["cat", "/sys/class/backlight/amdgpu_bl1/max_brightness"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v > 0)
                    root._screenMax = v;
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
                    root.screenBrightnessVisible = true;
                    screenBrightnessTimer.restart();
                }
            }
        }
    }

    Timer {
        id: screenBrightnessTimer
        interval: root.hideDelay
        onTriggered: root.screenBrightnessVisible = false
    }

    property bool kbdBrightnessVisible: false
    property real kbdBrightness: 0
    property int _kbdRaw: -1
    property int _kbdMax: 1

    Process {
        id: kbdMaxProc
        command: ["cat", "/sys/class/leds/platform::kbd_backlight/max_brightness"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v > 0)
                    root._kbdMax = v;
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
                    root.kbdBrightnessVisible = true;
                    kbdBrightnessTimer.restart();
                }
            }
        }
    }

    Timer {
        id: kbdBrightnessTimer
        interval: root.hideDelay
        onTriggered: root.kbdBrightnessVisible = false
    }

    property bool anyVisible: root.volumeVisible || root.screenBrightnessVisible || root.kbdBrightnessVisible

    LazyLoader {
        active: root.anyVisible

        PanelWindow {
            anchors.bottom: true
            margins.bottom: screen.height / 5
            exclusiveZone: 0
            color: "transparent"
            mask: Region {}

            implicitWidth: 400
            implicitHeight: visibleColumn.implicitHeight + 16

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: "#80000000"

                Column {
                    id: visibleColumn
                    anchors {
                        fill: parent
                        topMargin: 8
                        bottomMargin: 8
                    }

                    OsdRow {
                        width: parent.width
                        visible: root.volumeVisible
                        iconName: {
                            const audio = Pipewire.defaultAudioSink?.audio;
                            if (!audio || audio.muted)
                                return "audio-volume-muted-symbolic";
                            const vol = audio.volume;
                            if (vol <= 0.33)
                                return "audio-volume-low-symbolic";
                            if (vol <= 0.66)
                                return "audio-volume-medium-symbolic";
                            return "audio-volume-high-symbolic";
                        }
                        value: Pipewire.defaultAudioSink?.audio.volume ?? 0
                        label: Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100) + "%"
                        maxLabel: "150%"
                    }

                    OsdRow {
                        width: parent.width
                        visible: root.screenBrightnessVisible
                        iconName: "display-brightness-symbolic"
                        value: root.screenBrightness
                        label: Math.round(root.screenBrightness * 100) + "%"
                    }

                    OsdRow {
                        width: parent.width
                        visible: root.kbdBrightnessVisible
                        iconName: "keyboard-brightness-symbolic"
                        value: root.kbdBrightness
                        label: Math.round(root.kbdBrightness * 100) + "%"
                    }
                }
            }
        }
    }
}
