pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Item {
    id: root

    required property Notification notification
    property int timeout: Config.notifications.timeout
    property bool visible_: false
    property real latchedHeight: 0

    clip: false
    implicitHeight: latchedHeight
    implicitWidth: Config.notifications.cardWidth

    Component.onCompleted: Qt.callLater(() => {
        root.latchedHeight = card.implicitHeight + Math.round(8 * Config.scale);
        visible_ = true;
        slideTranslate.x = 0;
        card.opacity = 1;
        card.scale = 1;
    })

    Connections {
        target: card
        function onImplicitHeightChanged() {
            if (!exitAnim.running)
                root.latchedHeight = card.implicitHeight + Math.round(8 * Config.scale);
        }
    }

    function animateOut() {
        if (!root.visible_)
            return;
        root.visible_ = false;
        dismissTimer.stop();
        exitAnim.start();
    }

    Timer {
        id: dismissTimer
        interval: root.timeout
        running: root.visible_ && root.timeout > 0
        onTriggered: root.animateOut()
    }

    SequentialAnimation {
        id: exitAnim

        ParallelAnimation {
            NumberAnimation {
                target: slideTranslate
                property: "x"
                to: card.width + 24
                duration: Config.notifications.animateSpeed
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: card
                property: "opacity"
                to: 0
                duration: Config.notifications.animateSpeed
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: root
                property: "latchedHeight"
                to: 0
                duration: Config.notifications.animateSpeed
                easing.type: Easing.OutCubic
            }
        }

        ScriptAction {
            script: {
                root.notification?.dismiss();
            }
        }
    }

    // ── Drop shadow blob ──────────────────────────────────────────────────────
    Rectangle {
        anchors.horizontalCenter: card.horizontalCenter
        anchors.top: card.bottom
        anchors.topMargin: -Math.round(6 * Config.scale)
        width: card.width * 0.75
        height: Math.round(16 * Config.scale)
        radius: height / 2
        color: "#000000"
        opacity: card.opacity * 0.22
        z: -1
    }

    Rectangle {
        id: card

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: Math.round(4 * Config.scale)
        }

        implicitHeight: cardContent.implicitHeight + Math.round(22 * Config.scale)
        radius: Config.notifications.radius
        color: Qt.rgba(0.12, 0.11, 0.22, 0.95)
        border.color: Config.colors.border
        border.width: 1
        clip: true

        // Top shine rim
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            radius: parent.radius
            color: "#28ffffff"
            z: 1
        }

        transform: Translate {
            id: slideTranslate
            x: card.width + 24
            Behavior on x {
                NumberAnimation {
                    duration: Config.notifications.animateSpeed
                    easing.type: Easing.OutCubic
                }
            }
        }

        opacity: 0
        scale: 0.94
        Behavior on opacity {
            NumberAnimation {
                duration: Config.notifications.animateSpeed
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Config.notifications.animateSpeed
                easing.type: Easing.OutBack
                easing.overshoot: 0.4
            }
        }

        // Card tap — dismiss only
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.animateOut()
        }

        // Left accent bar — gradient from accent to accentAlt
        Item {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                topMargin: Math.round(8 * Config.scale)
                bottomMargin: Math.round(8 * Config.scale)
            }
            width: Config.notifications.accentBar
            clip: true

            // Glow layer
            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: width / 2
                color: Config.colors.glowAccent
                opacity: 0.55
            }

            Rectangle {
                anchors.fill: parent
                radius: Config.notifications.accentBar
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Config.colors.accent }
                    GradientStop { position: 1.0; color: Config.colors.accentAlt }
                }
            }
        }

        ColumnLayout {
            id: cardContent

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: Math.round(18 * Config.scale)
                rightMargin: Math.round(14 * Config.scale)
                topMargin: Math.round(12 * Config.scale)
            }

            spacing: Math.round(5 * Config.scale)

            // Header: app icon + app name + timestamp
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * Config.scale)

                IconImage {
                    implicitSize: Config.notifications.iconSize
                    source: {
                        const n = root.notification;
                        if (!n)
                            return "";
                        if (n.appIcon !== "") {
                            const path = Quickshell.iconPath(n.appIcon);
                            if (path !== "")
                                return path;
                        }
                        if (n.desktopEntry !== "" && n.desktopEntry !== null) {
                            const entry = DesktopEntries.byId(n.desktopEntry);
                            if (entry && entry.icon !== "")
                                return Quickshell.iconPath(entry.icon);
                        }
                        return Quickshell.iconPath("applications-other-symbolic");
                    }
                    visible: source !== ""
                }

                Text {
                    text: root.notification?.appName ?? ""
                    color: Config.colors.accent
                    font.family: Config.font.family
                    font.pixelSize: Config.notifications.fontSizeAppName
                    font.weight: Font.SemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: Qt.formatTime(new Date(), "hh:mm")
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.notifications.fontSizeTimestamp
                }
            }

            // Summary
            Text {
                text: root.notification?.summary ?? ""
                color: Config.colors.textPrimary
                font.family: Config.font.family
                font.pixelSize: Config.notifications.fontSizeSummary
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }

            // Body
            Text {
                text: root.notification?.body ?? ""
                color: Config.colors.textSecondary
                font.family: Config.font.family
                font.pixelSize: Config.notifications.fontSizeBody
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.bottomMargin: Math.round(2 * Config.scale)
                visible: text !== ""
                maximumLineCount: Config.notifications.bodyMaxLines === 0 ? Number.MAX_VALUE : Config.notifications.bodyMaxLines
                elide: Text.ElideRight
            }

            // Actions
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: Math.round(4 * Config.scale)
                spacing: Math.round(6 * Config.scale)
                visible: (root.notification?.actions?.length ?? 0) > 0

                Repeater {
                    model: root.notification?.actions ?? []

                    delegate: Item {
                        required property NotificationAction modelData

                        implicitHeight: Math.round(28 * Config.scale)
                        implicitWidth: actionBg.implicitWidth

                        // Glow on hover
                        Rectangle {
                            anchors.fill: actionBg
                            anchors.margins: -3
                            radius: actionBg.radius + 3
                            color: "transparent"
                            border.color: Config.colors.accentGlow
                            border.width: 2
                            opacity: actionArea.containsMouse ? 0.45 : 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }

                        Rectangle {
                            id: actionBg
                            anchors.fill: parent
                            implicitWidth: actionLabel.implicitWidth + Math.round(18 * Config.scale)
                            radius: Math.round(8 * Config.scale)
                            color: actionArea.containsMouse
                                ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.28)
                                : Qt.rgba(1, 1, 1, 0.07)
                            border.color: actionArea.containsMouse ? Config.colors.accent : Config.colors.border
                            border.width: 1

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 120 }
                            }

                            Text {
                                id: actionLabel
                                anchors.centerIn: parent
                                text: modelData.text
                                color: actionArea.containsMouse ? Config.colors.accent : Config.colors.textPrimary
                                font.family: Config.font.family
                                font.pixelSize: Config.notifications.fontSizeAction

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }
                            }
                        }

                        MouseArea {
                            id: actionArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                modelData.invoke();
                                root.animateOut();
                            }
                        }
                    }
                }
            }
        }
    }
}
