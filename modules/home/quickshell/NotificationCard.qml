pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Item {
    id: root

    required property Notification notification
    property int animateSpeed: Config.notifications.animateSpeed
    property int timeout: Config.notifications.timeout
    property bool visible_: false
    property real latchedHeight: 0
    property bool _pendingExit: false
    readonly property bool atTop: y === 0

    onYChanged: {
        if (_pendingExit && atTop)
            exitAnim.start();
    }

    clip: false
    implicitHeight: latchedHeight
    implicitWidth: Config.notifications.cardWidth

    Component.onCompleted: Qt.callLater(() => {
        root.latchedHeight = card.implicitHeight + Math.round(8 * Config.scale);
        visible_ = true;
        slideTranslate.x = 0;
        card.opacity = 1;
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
        dismissTimer.stop();
        if (root.atTop) {
            exitAnim.start();
        } else {
            root._pendingExit = true;
            root.animateSpeed = Math.round(Config.notifications.animateSpeed / 3);
        }
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
                to: card.width + 20
                duration: root.animateSpeed
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: card
                property: "opacity"
                to: 0
                duration: root.animateSpeed
                easing.type: Easing.InOutQuad
            }
        }

        NumberAnimation {
            target: root
            property: "latchedHeight"
            to: 0
            duration: root.animateSpeed
            easing.type: Easing.InOutQuad
        }

        ScriptAction {
            script: {
                root.visible_ = false;
                root.notification?.dismiss();
            }
        }
    }

    Rectangle {
        id: card

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: Math.round(4 * Config.scale)
        }

        implicitHeight: cardContent.implicitHeight + Math.round(20 * Config.scale)
        radius: Config.notifications.radius
        color: Config.colors.background

        border.color: Config.colors.border
        border.width: 1

        transform: Translate {
            id: slideTranslate
            x: card.width + 20
            Behavior on x {
                NumberAnimation {
                    duration: root.animateSpeed
                    easing.type: Easing.InOutQuad
                }
            }
        }

        opacity: 0
        Behavior on opacity {
            NumberAnimation {
                duration: root.animateSpeed
                easing.type: Easing.InOutQuad
            }
        }

        // Card tap
        TapHandler {
            onTapped: {
                const n = root.notification;
                if (!n)
                    return;
                const def = (n.actions ?? []).find(a => a.identifier === "default");
                if (def) {
                    def.invoke();
                } else if (n.desktopEntry && n.desktopEntry !== "") {
                    const entry = DesktopEntries.byId(n.desktopEntry);
                    if (entry)
                        entry.launch();
                }
                root.animateOut();
            }
        }

        // Left accent bar
        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                topMargin: Math.round(6 * Config.scale)
                bottomMargin: Math.round(6 * Config.scale)
            }
            width: Config.notifications.accentBar
            radius: Config.notifications.accentBar
            color: Config.colors.accent
        }

        ColumnLayout {
            id: cardContent

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: Math.round(16 * Config.scale)
                rightMargin: Math.round(12 * Config.scale)
                topMargin: Math.round(10 * Config.scale)
            }

            spacing: Math.round(4 * Config.scale)

            // Header: app icon + app name + timestamp + close button
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
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: Qt.formatTime(new Date(), "hh:mm")
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.notifications.fontSizeTimestamp
                }

                // Close button
                Rectangle {
                    implicitWidth: Math.round(18 * Config.scale)
                    implicitHeight: Math.round(18 * Config.scale)
                    radius: Math.round(9 * Config.scale)
                    color: closeHover.containsMouse ? Config.colors.border : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: Config.colors.textMuted
                        font.family: Config.font.family
                        font.pixelSize: Config.notifications.fontSizeTimestamp
                    }

                    HoverHandler {
                        id: closeHover
                    }
                    TapHandler {
                        onTapped: root.animateOut()
                    }
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
                Layout.bottomMargin: Math.round(2 * Config.scale)
                spacing: Math.round(6 * Config.scale)
                visible: (root.notification?.actions?.length ?? 0) > 0

                Repeater {
                    model: root.notification?.actions ?? []

                    delegate: Rectangle {
                        required property NotificationAction modelData

                        implicitHeight: Math.round(24 * Config.scale)
                        implicitWidth: actionLabel.implicitWidth + Math.round(16 * Config.scale)
                        radius: Math.round(6 * Config.scale)
                        color: actionHover.containsMouse ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.3) : Config.colors.border
                        border.color: Config.colors.border
                        border.width: 1

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: modelData.text
                            color: Config.colors.textPrimary
                            font.family: Config.font.family
                            font.pixelSize: Config.notifications.fontSizeAction
                        }

                        HoverHandler {
                            id: actionHover
                        }
                        TapHandler {
                            onTapped: {
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
