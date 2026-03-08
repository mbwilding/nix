pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "components"

Scope {
    id: root

    property bool pamAuthenticating: false
    property bool pamIsError: false
    property string bgImagePath: ""
    property string pamMessage: ""
    property var notifHistory: []

    signal clearPasswordField
    signal focusPasswordField
    signal shakePasswordField

    Process {
        id: grimProc
        command: ["grim", "/tmp/qs-lock-bg.png"]
        onExited: (code, status) => {
            if (code === 0) {
                root.bgImagePath = "";
                root.bgImagePath = "file:///tmp/qs-lock-bg.png";
            }
            sessionLock.locked = true;
            root.pamMessage = "";
            root.pamIsError = false;
            root.clearPasswordField();
            pam.start();
        }
    }

    PamContext {
        id: pam
        config: "login"

        onPamMessage: {
            root.pamIsError = pam.messageIsError;
            // Only show the message if it's an error — plain prompts like "Password: " are redundant
            root.pamMessage = pam.messageIsError ? pam.message : "";
            if (pam.responseRequired) {
                root.pamAuthenticating = true;
                root.focusPasswordField();
            }
        }

        onCompleted: result => {
            root.pamAuthenticating = false;
            if (result === PamResult.Success) {
                sessionLock.locked = false;
            } else {
                root.pamIsError = true;
                root.pamMessage = result === PamResult.MaxTries ? "Too many attempts" : (pam.message !== "" ? pam.message : "Authentication failed");
                root.clearPasswordField();
                root.shakePasswordField();
                pamRetryTimer.restart();
            }
        }

        onError: error => {
            root.pamAuthenticating = false;
            root.pamIsError = true;
            root.pamMessage = "PAM error: " + PamError.toString(error);
            root.clearPasswordField();
            root.shakePasswordField();
            pamRetryTimer.restart();
        }
    }

    Timer {
        id: pamRetryTimer
        interval: 1200
        onTriggered: {
            root.pamMessage = "";
            root.pamIsError = false;
            pam.start();
        }
    }

    IpcHandler {
        target: "lockscreen"
        function lock() {
            grimProc.running = true;
        }
        function unlock() {
            sessionLock.locked = false;
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: false

        surface: WlSessionLockSurface {
            id: lockSurface

            Item {
                anchors.fill: parent

                Connections {
                    target: root
                    function onFocusPasswordField() {
                        passwordInput.forceActiveFocus();
                    }
                    function onShakePasswordField() {
                        shakeAnim.restart();
                    }
                    function onClearPasswordField() {
                        passwordInput.text = "";
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "#ff0d0d18"
                    visible: root.bgImagePath === ""
                }

                Image {
                    id: bgImage
                    anchors.fill: parent
                    source: root.bgImagePath
                    fillMode: Image.PreserveAspectCrop
                    visible: root.bgImagePath !== ""
                    smooth: true
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: 1.0
                        blurMax: 64
                        blurMultiplier: 1.0
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "#aa0d0d18"
                    visible: root.bgImagePath !== ""
                }

                Column {
                    anchors.centerIn: parent
                    spacing: Math.round(32 * Config.scale)

                    Item {
                        id: passwordArea
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.round(360 * Config.scale)
                        height: passwordCol.implicitHeight

                        SequentialAnimation {
                            id: shakeAnim
                            property real restX: 0
                            ScriptAction {
                                script: {
                                    shakeAnim.restX = passwordArea.x;
                                }
                            }
                            NumberAnimation {
                                target: passwordArea
                                property: "x"
                                to: shakeAnim.restX - Math.round(10 * Config.scale)
                                duration: 50
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: passwordArea
                                property: "x"
                                to: shakeAnim.restX + Math.round(18 * Config.scale)
                                duration: 70
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: passwordArea
                                property: "x"
                                to: shakeAnim.restX - Math.round(14 * Config.scale)
                                duration: 60
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: passwordArea
                                property: "x"
                                to: shakeAnim.restX + Math.round(10 * Config.scale)
                                duration: 60
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: passwordArea
                                property: "x"
                                to: shakeAnim.restX - Math.round(6 * Config.scale)
                                duration: 50
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: passwordArea
                                property: "x"
                                to: shakeAnim.restX
                                duration: 40
                                easing.type: Easing.InOutQuad
                            }
                        }

                        Column {
                            id: passwordCol
                            width: parent.width
                            spacing: Math.round(10 * Config.scale)

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: root.pamMessage !== ""
                                text: root.pamMessage
                                color: root.pamIsError ? Config.colors.danger : Config.colors.textMuted
                                font.family: Config.font.family
                                font.pixelSize: Math.round(11 * Config.scale)
                                opacity: 0.9
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: Math.round(44 * Config.scale)
                                radius: Math.round(12 * Config.scale)
                                color: Config.colors.surface
                                border.width: passwordInput.activeFocus ? Math.round(1.5 * Config.scale) : Config.panelBorder.width
                                border.color: root.pamIsError ? Qt.rgba(Config.colors.danger.r, Config.colors.danger.g, Config.colors.danger.b, passwordInput.activeFocus ? 0.9 : 0.5) : passwordInput.activeFocus ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.8) : Config.panelBorder.color
                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: "transparent"
                                    border.width: Math.round(4 * Config.scale)
                                    border.color: root.pamIsError ? Qt.rgba(Config.colors.danger.r, Config.colors.danger.g, Config.colors.danger.b, 0.12) : Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.12)
                                    opacity: passwordInput.activeFocus ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Math.round(14 * Config.scale)
                                    anchors.rightMargin: Math.round(14 * Config.scale)
                                    spacing: Math.round(10 * Config.scale)

                                    Text {
                                        text: root.pamAuthenticating ? "\uF13E" : "\uF023"
                                        color: root.pamIsError ? Config.colors.danger : passwordInput.activeFocus ? Config.colors.accent : Config.colors.textMuted
                                        font.family: Config.font.family
                                        font.pixelSize: Math.round(14 * Config.scale)
                                        opacity: 0.8
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                            }
                                        }
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        height: Math.round(20 * Config.scale)

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: passwordInput.text.length === 0
                                            text: "Enter password…"
                                            color: Config.colors.textMuted
                                            font.family: Config.font.family
                                            font.pixelSize: Math.round(13 * Config.scale)
                                            opacity: 0.45
                                        }

                                        Row {
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: passwordInput.text.length > 0
                                            spacing: Math.round(5 * Config.scale)

                                            Repeater {
                                                model: Math.min(passwordInput.text.length, 32)
                                                delegate: Rectangle {
                                                    required property int index
                                                    width: Math.round(7 * Config.scale)
                                                    height: width
                                                    radius: width / 2
                                                    color: root.pamIsError ? Config.colors.danger : Config.colors.accent
                                                    opacity: 0.85
                                                }
                                            }

                                            Text {
                                                visible: passwordInput.text.length > 32
                                                text: "+" + (passwordInput.text.length - 32)
                                                color: Config.colors.textMuted
                                                font.family: Config.font.family
                                                font.pixelSize: Math.round(10 * Config.scale)
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        TextInput {
                                            id: passwordInput
                                            anchors.fill: parent
                                            opacity: 0
                                            echoMode: TextInput.Password
                                            focus: true

                                            Keys.onReturnPressed: {
                                                if (text.length > 0 && pam.responseRequired) {
                                                    pam.respond(text);
                                                    text = "";
                                                }
                                            }
                                            Keys.onEnterPressed: {
                                                if (text.length > 0 && pam.responseRequired) {
                                                    pam.respond(text);
                                                    text = "";
                                                }
                                            }
                                            Keys.onEscapePressed: {
                                                text = "";
                                            }
                                        }
                                    }

                                    Text {
                                        visible: pam.active && !pam.responseRequired
                                        text: "\uF110"
                                        color: Config.colors.accent
                                        font.family: Config.font.family
                                        font.pixelSize: Math.round(14 * Config.scale)
                                        opacity: 0.7

                                        RotationAnimator on rotation {
                                            from: 0
                                            to: 360
                                            duration: 900
                                            loops: Animation.Infinite
                                            running: pam.active && !pam.responseRequired
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        id: notifContainer
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.notifHistory.length > 0
                        width: Math.round(360 * Config.scale)
                        height: Math.min(notifInnerCol.implicitHeight, lockSurface.height - passwordArea.height - Math.round(160 * Config.scale))
                        clip: true

                        property real scrollY: 0
                        readonly property real maxScrollY: Math.max(0, notifInnerCol.implicitHeight - notifContainer.height)

                        WheelHandler {
                            target: null
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: event => {
                                const step = Math.round(36 * Config.scale);
                                notifContainer.scrollY = Math.max(0, Math.min(notifContainer.maxScrollY, notifContainer.scrollY - event.angleDelta.y / 120 * step));
                            }
                        }

                        Column {
                            id: notifInnerCol
                            width: notifContainer.width - Math.round(6 * Config.scale)
                            spacing: Math.round(6 * Config.scale)
                            y: -notifContainer.scrollY

                            RowLayout {
                                width: parent.width

                                Text {
                                    text: "\uF0F3  Notifications"
                                    color: Config.colors.textMuted
                                    font.family: Config.font.family
                                    font.pixelSize: Config.font.sizeLg
                                    font.weight: Font.Medium
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: root.notifHistory.length > 99 ? "99+" : String(root.notifHistory.length)
                                    color: Config.colors.accentAlt
                                    font.family: Config.font.family
                                    font.pixelSize: Config.font.sizeLg
                                    font.weight: Font.Bold
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Config.colors.border
                                opacity: 0.4
                            }

                            Repeater {
                                model: root.notifHistory
                                delegate: LockNotificationCard {
                                    id: lockNotifD
                                    required property var modelData
                                    snapshot: lockNotifD.modelData
                                    width: notifInnerCol.width
                                }
                            }
                        }

                        Rectangle {
                            visible: notifContainer.maxScrollY > 0
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.round(3 * Config.scale)
                            radius: width / 2
                            color: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18)

                            Rectangle {
                                readonly property real _h: notifContainer.maxScrollY <= 0 ? parent.height : Math.max(Math.round(28 * Config.scale), parent.height * (notifContainer.height / notifInnerCol.implicitHeight))
                                readonly property real _y: notifContainer.maxScrollY <= 0 ? 0 : (parent.height - _h) * (notifContainer.scrollY / notifContainer.maxScrollY)
                                y: _y
                                width: parent.width
                                height: _h
                                radius: width / 2
                                color: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.55)
                            }
                        }
                    }
                }
            }
        }
    }
}
