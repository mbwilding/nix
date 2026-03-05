pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Fusion
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.Pipewire
import Quickshell.Widgets

ShellRoot {
    id: root

    // IPC handle
    IpcHandler {
        target: "default"

        function lock() { lockscreen.active = true; }
        function toggleMixer() { mixer.active = !mixer.active; }
        function toggleWlogout() { wlogoutLoader.active = !wlogoutLoader.active; }
    }

    // Volume OSD
    Scope {
        id: volumeOsd

        PwObjectTracker {
            objects: [ Pipewire.defaultAudioSink ]
        }

        Connections {
            target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

            function onVolumeChanged() {
                volumeOsd.shouldShow = true;
                hideTimer.restart();
            }
        }

        property bool shouldShow: false

        Timer {
            id: hideTimer
            interval: 1000
            onTriggered: volumeOsd.shouldShow = false
        }

        LazyLoader {
            active: volumeOsd.shouldShow

            PanelWindow { // qmllint disable uncreatable-type
                anchors.bottom: true
                margins.bottom: screen.height / 5 // qmllint disable unqualified unresolved-type missing-property
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
                            source: Quickshell.iconPath("audio-volume-high-symbolic")
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

    // Lockscreen
    LazyLoader {
        id: lockscreen

        Scope {
            Scope {
                id: lockCtx
                signal unlocked()
                signal failed()
                property string currentText: ""
                property bool unlockInProgress: false
                property bool showFailure: false
                onCurrentTextChanged: showFailure = false

                function tryUnlock() {
                    if (currentText === "") return;
                    unlockInProgress = true;
                    pam.start();
                }

                PamContext {
                    id: pam
                    configDirectory: "@pamDir@"
                    config: "password.conf"

                    onPamMessage: if (this.responseRequired) this.respond(lockCtx.currentText)

                    onCompleted: result => {
                        if (result == PamResult.Success) {
                            lock.locked = false;
                            lockscreen.active = false;
                        } else {
                            lockCtx.currentText = "";
                            lockCtx.showFailure = true;
                        }
                        lockCtx.unlockInProgress = false;
                    }
                }
            }

            WlSessionLock {
                id: lock
                locked: true

                WlSessionLockSurface {
                    Rectangle {
                        anchors.fill: parent
                        color: Window.active ? palette.active.window : palette.inactive.window

                        Button {
                            text: "Its not working, let me out"
                            onClicked: { lock.locked = false; lockscreen.active = false; }
                        }

                        Label {
                            id: clock
                            property var date: new Date()
                            anchors {
                                horizontalCenter: parent.horizontalCenter
                                top: parent.top
                                topMargin: 100
                            }
                            renderType: Text.NativeRendering
                            font.pointSize: 80
                            Timer {
                                running: true; repeat: true; interval: 1000
                                onTriggered: clock.date = new Date()
                            }
                            text: {
                                const h = date.getHours().toString().padStart(2, "0");
                                const m = date.getMinutes().toString().padStart(2, "0");
                                return h + ":" + m;
                            }
                        }

                        ColumnLayout {
                            anchors {
                                horizontalCenter: parent.horizontalCenter
                                top: parent.verticalCenter
                            }

                            RowLayout {
                                TextField {
                                    id: passwordBox
                                    implicitWidth: 400
                                    padding: 10
                                    focus: true
                                    enabled: !lockCtx.unlockInProgress
                                    echoMode: TextInput.Password
                                    inputMethodHints: Qt.ImhSensitiveData
                                    onTextChanged: lockCtx.currentText = text
                                    onAccepted: lockCtx.tryUnlock()
                                    Connections {
                                        target: lockCtx
                                        function onCurrentTextChanged() { passwordBox.text = lockCtx.currentText; }
                                    }
                                }
                                Button {
                                    text: "Unlock"
                                    padding: 10
                                    focusPolicy: Qt.NoFocus
                                    enabled: !lockCtx.unlockInProgress && lockCtx.currentText !== ""
                                    onClicked: lockCtx.tryUnlock()
                                }
                            }

                            Label {
                                visible: lockCtx.showFailure
                                text: "Incorrect password"
                            }
                        }
                    }
                }
            }
        }
    }

    // Audio mixer
    LazyLoader {
        id: mixer

        FloatingWindow {
            color: contentItem.palette.active.window

            ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10

                    PwNodeLinkTracker {
                        id: linkTracker
                        node: Pipewire.defaultAudioSink
                    }

                    MixerEntry { node: Pipewire.defaultAudioSink }

                    Rectangle {
                        Layout.fillWidth: true
                        color: palette.active.text
                        implicitHeight: 1
                    }

                    Repeater {
                        model: linkTracker.linkGroups
                        delegate: MixerEntry {
                            id: mixerEntryDelegate
                            required property PwLinkGroup modelData
                            node: mixerEntryDelegate.modelData.source
                        }
                    }
                }
            }
        }
    }

    // MixerEntry
    component MixerEntry: ColumnLayout {
        id: mixerEntry
        required property PwNode node
        PwObjectTracker { objects: [ mixerEntry.node ] }

        RowLayout {
            Image {
                visible: source.toString() !== ""
                source: {
                    const icon = mixerEntry.node.properties["application.icon-name"] ?? "audio-volume-high-symbolic";
                    return "image://icon/" + icon;
                }
                sourceSize.width: 20
                sourceSize.height: 20
            }
            Label {
                text: {
                    const app = mixerEntry.node.properties["application.name"] ?? (mixerEntry.node.description !== "" ? mixerEntry.node.description : mixerEntry.node.name);
                    const media = mixerEntry.node.properties["media.name"];
                    return media !== undefined ? app + " - " + media : app;
                }
            }
            Button {
                text: mixerEntry.node.audio.muted ? "unmute" : "mute"
                onClicked: mixerEntry.node.audio.muted = !mixerEntry.node.audio.muted
            }
        }

        RowLayout {
            Label {
                Layout.preferredWidth: 50
                text: Math.floor(mixerEntry.node.audio.volume * 100) + "%"
            }
            Slider {
                Layout.fillWidth: true
                value: mixerEntry.node.audio.volume
                onValueChanged: mixerEntry.node.audio.volume = value
            }
        }
    }

    // WlogoutButton
    component WlogoutButton: QtObject {
        required property string text
        required property string icon
        required property var keybind
        required property string command
    }

    // Wlogout
    LazyLoader {
        id: wlogoutLoader

        Variants {
            model: Quickshell.screens

            delegate: PanelWindow {
                id: wlogoutWin
                required property var modelData
                screen: wlogoutWin.modelData

                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                color: "transparent"

                anchors { top: true; left: true; bottom: true; right: true }

                readonly property list<WlogoutButton> buttons: [
                    WlogoutButton {
                        text: "Lock"
                        icon: "󰌾"
                        keybind: Qt.Key_K
                        command: "loginctl lock-session"
                    },
                    WlogoutButton {
                        text: "Logout"
                        icon: "󰍃"
                        keybind: Qt.Key_E
                        command: "loginctl terminate-user $USER"
                    },
                    WlogoutButton {
                        text: "Suspend"
                        icon: "󰒲"
                        keybind: Qt.Key_U
                        command: "systemctl suspend"
                    },
                    WlogoutButton {
                        text: "Hibernate"
                        icon: "󰋊"
                        keybind: Qt.Key_H
                        command: "systemctl hibernate"
                    },
                    WlogoutButton {
                        text: "Shutdown"
                        icon: "󰐥"
                        keybind: Qt.Key_S
                        command: "systemctl poweroff"
                    },
                    WlogoutButton {
                        text: "Reboot"
                        icon: "󰑐"
                        keybind: Qt.Key_R
                        command: "systemctl reboot"
                    }
                ]

                contentItem {
                    focus: true
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            wlogoutLoader.active = false;
                        } else {
                            for (let b of wlogoutWin.buttons) {
                                if (event.key === b.keybind) wlogoutWin.runAndClose(b.command);
                            }
                        }
                    }
                }

                Process {
                    id: wlogoutProc
                    running: false
                }

                function runAndClose(cmd) {
                    wlogoutProc.command = ["sh", "-c", cmd];
                    wlogoutProc.running = true;
                    wlogoutLoader.active = false;
                }

                Rectangle {
                    color: "#e60c0c0c"
                    anchors.fill: parent

                    MouseArea {
                        anchors.fill: parent
                        onClicked: wlogoutLoader.active = false

                        GridLayout {
                            anchors.centerIn: parent
                            width: parent.width * 0.75
                            height: parent.height * 0.75
                            columns: 3
                            columnSpacing: 0
                            rowSpacing: 0

                            Repeater {
                                model: wlogoutWin.buttons
                                delegate: Rectangle {
                                    id: wlogoutBtn
                                    required property WlogoutButton modelData
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: ma.containsMouse ? "#3700b3" : "#1e1e1e"
                                    border.color: "black"
                                    border.width: ma.containsMouse ? 0 : 1

                                    MouseArea {
                                        id: ma
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: wlogoutWin.runAndClose(wlogoutBtn.modelData.command)
                                    }

                                    Text {
                                        id: btnIcon
                                        anchors.centerIn: parent
                                        text: wlogoutBtn.modelData.icon
                                        font.family: "NeoSpleen Nerd Font"
                                        font.pointSize: 48
                                        color: "white"
                                    }

                                    Text {
                                        anchors {
                                            top: btnIcon.bottom
                                            topMargin: 20
                                            horizontalCenter: parent.horizontalCenter
                                        }
                                        text: wlogoutBtn.modelData.text
                                        font.pointSize: 20
                                        color: "white"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
