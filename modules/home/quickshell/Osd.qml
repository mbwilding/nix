pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Widgets

Scope {
    id: root

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

        function onVolumeChanged() {
            root.shouldShow = true;
            hideTimer.restart();
        }

        function onMutedChanged() {
            root.shouldShow = true;
            hideTimer.restart();
        }
    }

    property bool shouldShow: false

    Timer {
        id: hideTimer
        interval: 1000
        onTriggered: root.shouldShow = false
    }

    LazyLoader {
        active: root.shouldShow

        PanelWindow {
            anchors.bottom: true
            margins.bottom: screen.height / 5
            exclusiveZone: 0
            implicitWidth: 400
            implicitHeight: 50
            color: "transparent"
            mask: Region {}

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "#80000000"

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 15
                    }

                    IconImage {
                        implicitSize: 30
                        source: {
                            const audio = Pipewire.defaultAudioSink?.audio;
                            if (!audio || audio.muted)
                                return Quickshell.iconPath("audio-volume-muted-symbolic");
                            const vol = audio.volume;
                            if (vol <= 0.33)
                                return Quickshell.iconPath("audio-volume-low-symbolic");
                            if (vol <= 0.66)
                                return Quickshell.iconPath("audio-volume-medium-symbolic");
                            return Quickshell.iconPath("audio-volume-high-symbolic");
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 10
                        radius: 20
                        color: "#50ffffff"

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            property real vol: Pipewire.defaultAudioSink?.audio.volume ?? 0
                            property real excessRatio: Math.min(1.0, Math.max(0.0, (vol - 1.0) / 0.5))
                            implicitWidth: Math.min(parent.width, parent.width * vol)
                            radius: parent.radius
                            color: Qt.rgba(1, 1 - excessRatio, 1 - excessRatio, 1)
                        }
                    }

                    Text {
                        text: Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100) + "%"
                        color: "white"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: maxVolumeMetrics.boundingRect.width
                        Layout.leftMargin: parent.spacing

                        TextMetrics {
                            id: maxVolumeMetrics
                            font: parent.font
                            text: "100%"
                        }
                    }
                }
            }
        }
    }
}
