pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

Scope {
    id: root

    property bool anyVisible: false
    property bool kbdVisible: false
    property bool screenVisible: false
    property bool volumeVisible: false
    property int _kbdMax: 1
    property int _kbdRaw: -1
    property int _screenMax: 1
    property int _screenRaw: -1
    property real _volumeRaw: -1
    property real kbdBrightness: 0
    property real screenBrightness: 0
    property string kbdDevice: ""
    property string screenDevice: ""
    readonly property bool kbdAvailable: _kbdMax > 1
    readonly property bool screenAvailable: _screenMax > 1
    readonly property bool volumeAvailable: Pipewire.defaultAudioSink !== null
    readonly property int panelHeight: root.rowCount * Config.osd.rowHeight + Math.round(16 * Config.scale)
    readonly property int rowCount: (root.volumeVisible ? 1 : 0) + (root.screenVisible ? 1 : 0) + (root.kbdVisible ? 1 : 0)

    Process {
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

    Process {
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

    Timer {
        id: hideTimer
        interval: Config.osd.hideDelay
        onTriggered: root.anyVisible = false
    }

    function show() {
        root.volumeVisible = root.volumeAvailable;
        root.screenVisible = root.screenAvailable;
        root.kbdVisible = root.kbdAvailable;
        root.anyVisible = true;
        if (Config.osd.hideDelay > 0)
            hideTimer.restart();
    }

    // Volume
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: root.volumeAvailable ? Pipewire.defaultAudioSink.audio : null

        function onVolumeChanged() {
            const v = Pipewire.defaultAudioSink.audio.volume;
            if (root._volumeRaw < 0) {
                root._volumeRaw = v;
                return;
            }
            root._volumeRaw = v;
            root.show();
            Sounds.playVolume();
        }

        function onMutedChanged() {
            if (root._volumeRaw < 0)
                return;
            root.show();
        }
    }

    // Screen
    Process {
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

    Timer {
        interval: 200
        repeat: true
        running: root.screenDevice !== "" && (root.screenAvailable || root._screenMax === 1)
        onTriggered: screenPollProc.running = true
    }

    Process {
        id: screenPollProc
        command: ["cat", root.screenDevice + "/brightness"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v !== root._screenRaw) {
                    const firstRead = root._screenRaw === -1;
                    root._screenRaw = v;
                    root.screenBrightness = v / root._screenMax;
                    if (!firstRead && root.screenAvailable)
                        root.show();
                }
            }
        }
    }

    // Keyboard
    Process {
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

    Timer {
        interval: 200
        repeat: true
        running: root.kbdDevice !== "" && (root.kbdAvailable || root._kbdMax === 1)
        onTriggered: kbdPollProc.running = true
    }

    Process {
        id: kbdPollProc
        command: ["cat", root.kbdDevice + "/brightness"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v !== root._kbdRaw) {
                    const firstRead = root._kbdRaw === -1;
                    root._kbdRaw = v;
                    root.kbdBrightness = v / root._kbdMax;
                    if (!firstRead && root.kbdAvailable)
                        root.show();
                }
            }
        }
    }

    // Panel
    PanelWindow {
        WlrLayershell.layer: WlrLayer.Overlay
        anchors.bottom: true
        exclusiveZone: 0
        color: "transparent"
        mask: Region {}

        implicitWidth: Config.osd.panelWidth
        implicitHeight: root.panelHeight

        Rectangle {
            id: panel
            width: parent.width
            height: root.panelHeight
            radius: Config.osd.radius
            color: Config.colors.background

            transform: Translate {
                y: root.anyVisible ? 0 : panel.height
                Behavior on y {
                    NumberAnimation {
                        duration: Config.osd.animateSpeed
                        easing.type: Easing.InOutQuad
                        onFinished: if (!root.anyVisible) {
                            root.volumeVisible = false;
                            root.screenVisible = false;
                            root.kbdVisible = false;
                        }
                    }
                }
            }

            opacity: root.anyVisible ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Config.osd.animateSpeed
                    easing.type: Easing.InOutQuad
                }
            }

            Column {
                anchors {
                    fill: parent
                    topMargin: Math.round(8 * Config.scale)
                    bottomMargin: Math.round(8 * Config.scale)
                }

                OsdRow {
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
                }

                OsdRow {
                    iconName: "video-display-brightness-symbolic"
                    value: root.screenBrightness
                    label: Math.round(root.screenBrightness * 100) + "%"
                }

                OsdRow {
                    iconName: "input-keyboard-brightness"
                    value: root.kbdBrightness
                    label: Math.round(root.kbdBrightness * 100) + "%"
                }
            }
        }
    }
}
