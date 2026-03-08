pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "components"
import "services"

Scope {
    id: root

    property bool anyVisible: false
    property bool kbdVisible: false
    property bool screenVisible: false
    property bool volumeVisible: false
    property real _volumeRaw: -1

    readonly property bool kbdAvailable: BrightnessService.kbdAvailable
    readonly property bool screenAvailable: BrightnessService.screenAvailable
    readonly property bool volumeAvailable: Pipewire.defaultAudioSink !== null
    readonly property int panelHeight: root.rowCount * Config.osd.rowHeight + Math.round(16 * Config.scale)
    readonly property int rowCount: (root.volumeVisible ? 1 : 0) + (root.screenVisible ? 1 : 0) + (root.kbdVisible ? 1 : 0)

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

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    // Reset suppression counter whenever the default sink itself changes, so the
    // first volume reading from the new device is silently swallowed (PW often
    // fires volumeChanged with NaN or an uninitialized value during the switch).
    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() {
            root._volumeRaw = -1;
        }
    }

    Connections {
        target: root.volumeAvailable ? Pipewire.defaultAudioSink.audio : null

        function onVolumeChanged() {
            const v = Pipewire.defaultAudioSink.audio.volume;
            // Discard NaN / undefined readings that PW emits transiently during
            // device switches — they must never reach the OSD or be written back.
            if (v === undefined || isNaN(v)) return;
            if (root._volumeRaw < 0) {
                // First valid reading after startup or a sink switch — baseline only.
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

    property bool _screenFirstRead: true
    property bool _kbdFirstRead: true
    Connections {
        target: BrightnessService

        function onScreenBrightnessChanged() {
            if (root._screenFirstRead) {
                root._screenFirstRead = false;
                return;
            }

            if (root.screenAvailable)
                root.show();
        }

        function onKbdBrightnessChanged() {
            if (root._kbdFirstRead) {
                root._kbdFirstRead = false;
                return;
            }

            if (root.kbdAvailable)
                root.show();
        }
    }

    // Panel
    PanelWindow {
        WlrLayershell.layer: WlrLayer.Overlay
        anchors.top: true
        exclusiveZone: 0
        color: "transparent"
        mask: Region {}

        implicitWidth: Config.osd.panelWidth
        implicitHeight: root.panelHeight

        Item {
            id: panelWrapper
            width: parent.width
            height: root.panelHeight

            transform: Translate {
                y: root.anyVisible ? 0 : -panelWrapper.height - Math.round(12 * Config.scale)
                Behavior on y {
                    NumberAnimation {
                        duration: Config.osd.animateSpeed
                        easing.type: Easing.InOutCubic
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
                    easing.type: Easing.InOutCubic
                }
            }

            // Panel card
            PopupCard {
                anchors.fill: parent
                popupRadius: Config.osd.radius
                showShine: false

                Column {
                    anchors {
                        fill: parent
                        topMargin: Math.round(8 * Config.scale)
                        bottomMargin: Math.round(8 * Config.scale)
                    }

                    OsdRow {
                        visible: root.volumeVisible
                        iconName: {
                            const audio = Pipewire.defaultAudioSink?.audio;
                            if (!audio || audio.muted)
                                return "audio-volume-muted-symbolic";
                            const vol = audio.volume;
                            if (isNaN(vol) || vol === undefined)
                                return "audio-volume-muted-symbolic";
                            if (vol <= 0.33)
                                return "audio-volume-low-symbolic";
                            if (vol <= 0.66)
                                return "audio-volume-medium-symbolic";
                            return "audio-volume-high-symbolic";
                        }
                        value: {
                            const v = Pipewire.defaultAudioSink?.audio?.volume ?? 0;
                            return (isNaN(v) || v === undefined) ? 0 : v;
                        }
                        label: {
                            const v = Pipewire.defaultAudioSink?.audio?.volume;
                            return (v === undefined || v === null || isNaN(v)) ? "0%" : Math.round(v * 100) + "%";
                        }
                    }

                    OsdRow {
                        visible: root.screenVisible
                        iconName: "video-display-brightness-symbolic"
                        value: BrightnessService.screenBrightness
                        label: Math.round(BrightnessService.screenBrightness * 100) + "%"
                    }

                    OsdRow {
                        visible: root.kbdVisible
                        iconName: "input-keyboard-brightness"
                        value: BrightnessService.kbdBrightness
                        label: Math.round(BrightnessService.kbdBrightness * 100) + "%"
                    }
                }
            }
        }
    }
}
