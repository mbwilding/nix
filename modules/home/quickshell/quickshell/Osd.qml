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

    // Show OSD when screen brightness changes (skip the first read)
    property bool _screenFirstRead: true
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
            if (root._screenFirstRead)
                return;
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
