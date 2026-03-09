pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Pipewire

import ".."
import "../components"
import "../services"

Scope {
    id: root

    property bool _kbdFirstRead: true
    property bool _screenFirstRead: true
    property string activeRow: ""   // "volume" | "screen" | "kbd" | ""
    property string frozenRow: ""   // last non-empty activeRow — holds content during fade-out
    property real _volumeRaw: -1

    readonly property bool anyVisible: root.activeRow !== ""
    readonly property bool kbdAvailable: BrightnessService.kbdAvailable
    readonly property bool screenAvailable: BrightnessService.screenAvailable
    readonly property bool volumeAvailable: Pipewire.defaultAudioSink !== null

    onActiveRowChanged: if (root.activeRow !== "") root.frozenRow = root.activeRow

    // Animated display value — smoothly follows the active row's real value
    property real displayValue: 0
    readonly property real targetValue: {
        if (root.frozenRow === "volume") {
            const v = Pipewire.defaultAudioSink?.audio?.volume ?? 0;
            return (isNaN(v) || v === undefined) ? 0 : v;
        }
        if (root.frozenRow === "screen") return BrightnessService.screenBrightness;
        if (root.frozenRow === "kbd")    return BrightnessService.kbdBrightness;
        return 0;
    }
    onTargetValueChanged: displayValue = targetValue

    Behavior on displayValue {
        NumberAnimation {
            duration: Config.osd.animateSpeed
            easing.type: Easing.OutCubic
        }
    }

    function showVolume() {
        root.activeRow = "volume";
        if (Config.osd.hideDelay > 0)
            hideTimer.restart();
    }

    function showScreen() {
        root.activeRow = "screen";
        if (Config.osd.hideDelay > 0)
            hideTimer.restart();
    }

    function showKbd() {
        root.activeRow = "kbd";
        if (Config.osd.hideDelay > 0)
            hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: Config.osd.hideDelay
        onTriggered: root.activeRow = ""
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

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
            if (v === undefined || isNaN(v))
                return;
            if (root._volumeRaw < 0) {
                root._volumeRaw = v;
                return;
            }
            root._volumeRaw = v;
            root.showVolume();
            Sounds.playVolume();
        }

        function onMutedChanged() {
            if (root._volumeRaw < 0)
                return;
            root.showVolume();
        }
    }

    Connections {
        target: BrightnessService

        function onScreenBrightnessChanged() {
            if (root._screenFirstRead) {
                root._screenFirstRead = false;
                return;
            }
            if (root.screenAvailable)
                root.showScreen();
        }

        function onKbdBrightnessChanged() {
            if (root._kbdFirstRead) {
                root._kbdFirstRead = false;
                return;
            }
            if (root.kbdAvailable)
                root.showKbd();
        }
    }

    PanelWindow {
        screen: Quickshell.screens[Config.monitor]
        WlrLayershell.layer: WlrLayer.Overlay
        anchors.bottom: true
        margins.bottom: Math.round(screen.height / 7)
        exclusiveZone: 0
        color: "transparent"
        mask: Region {}

        implicitWidth: Config.osd.panelWidth
        implicitHeight: Config.osd.rowHeight + Math.round(16 * Config.scale)

        Item {
            id: panelWrapper
            width: parent.width
            height: Config.osd.rowHeight + Math.round(16 * Config.scale)

            opacity: root.anyVisible ? 1 : 0
            scale: root.anyVisible ? 1 : 0.85
            transformOrigin: Item.Center

            Behavior on opacity {
                NumberAnimation {
                    duration: Config.osd.animateSpeed
                    easing.type: Easing.InOutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Config.osd.animateSpeed
                    easing.type: Easing.OutCubic
                }
            }

            PopupCard {
                anchors.fill: parent
                popupRadius: Config.osd.radius

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: Math.round(14 * Config.scale)
                        rightMargin: Math.round(16 * Config.scale)
                    }
                    spacing: Math.round(10 * Config.scale)

                    // Icon
                    Item {
                        implicitWidth: Config.osd.iconSize
                        implicitHeight: Config.osd.iconSize

                        IconImage {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: root.frozenRow === "screen" ? -3 : 0
                            implicitSize: Config.osd.iconSize
                            source: Quickshell.iconPath({
                                "kbd": "input-keyboard-brightness",
                                "screen": "video-display-brightness-symbolic",
                                "volume": (() => {
                                    const audio = Pipewire.defaultAudioSink?.audio;
                                    if (!audio || audio.muted) return "audio-volume-muted-symbolic";
                                    const vol = audio.volume;
                                    if (isNaN(vol) || vol === undefined) return "audio-volume-muted-symbolic";
                                    if (vol <= 0.33) return "audio-volume-low-symbolic";
                                    if (vol <= 0.66) return "audio-volume-medium-symbolic";
                                    return "audio-volume-high-symbolic";
                                })()
                            }[root.frozenRow] ?? "")
                        }
                    }

                    // Progress bar
                    GradientProgressBar {
                        Layout.fillWidth: true
                        barHeight: Config.osd.barHeight
                        value: root.displayValue
                    }

                    // Label
                    Text {
                        text: Math.round(root.displayValue * 100) + "%"
                        color: Config.colors.textPrimary
                        font.family: Config.font.family
                        font.bold: true
                        font.pixelSize: Config.font.sizeXl
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: labelMetrics.boundingRect.width

                        TextMetrics {
                            id: labelMetrics
                            font.family: Config.font.family
                            font.pixelSize: Config.font.sizeXl
                            text: "100%"
                        }
                    }
                }
            }
        }
    }
}
