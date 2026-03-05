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

    // Height is fixed once latched — only collapses after slide-out completes
    property real latchedHeight: 0
    implicitHeight: latchedHeight
    implicitWidth: 360

    clip: false

    Component.onCompleted: Qt.callLater(() => {
        latchedHeight = card.implicitHeight + 8;
        visible_ = true;
    })

    function animateOut() {
        if (!root.visible_) return;
        dismissTimer.stop();
        exitAnim.start();
    }

    Timer {
        id: dismissTimer
        interval: root.timeout
        running: root.visible_
        onTriggered: root.animateOut()
    }

    SequentialAnimation {
        id: exitAnim

        // Step 1: slide card out to the right + fade (height stays stable)
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

        // Step 2: collapse height so cards below shuffle up smoothly
        NumberAnimation {
            target: root
            property: "latchedHeight"
            to: 0
            duration: root.animateSpeed
            easing.type: Easing.InOutQuad
        }

        // Step 3: notify server the notification is gone
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
            topMargin: 4
        }

        implicitHeight: cardContent.implicitHeight + 20
        radius: 12
        color: Config.colors.background

        border.color: Config.colors.border
        border.width: 1

        transform: Translate {
            id: slideTranslate
            x: root.visible_ ? 0 : card.width + 20
            Behavior on x {
                enabled: root.visible_
                NumberAnimation {
                    duration: root.animateSpeed
                    easing.type: Easing.InOutQuad
                }
            }
        }

        opacity: root.visible_ ? 1 : 0
        Behavior on opacity {
            enabled: root.visible_
            NumberAnimation {
                duration: root.animateSpeed
                easing.type: Easing.InOutQuad
            }
        }

        // Card tap — invoke default action or launch desktop entry
        TapHandler {
            onTapped: {
                const n = root.notification;
                if (!n) return;
                const def = (n.actions ?? []).find(a => a.identifier === "default");
                if (def) {
                    def.invoke();
                } else if (n.desktopEntry && n.desktopEntry !== "") {
                    const entry = DesktopEntries.byId(n.desktopEntry);
                    if (entry) entry.launch();
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
                topMargin: 6
                bottomMargin: 6
            }
            width: 3
            radius: 2
            color: Config.colors.accent
        }

        ColumnLayout {
            id: cardContent

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 16
                rightMargin: 12
                topMargin: 10
            }

            spacing: 4

            // Header: app icon + app name + timestamp + close button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                IconImage {
                    implicitSize: 18
                    source: {
                        const n = root.notification;
                        if (!n) return "";
                        if (n.appIcon !== "") return Quickshell.iconPath(n.appIcon);
                        if (n.desktopEntry !== "" && n.desktopEntry !== null) {
                            const entry = DesktopEntries.byId(n.desktopEntry);
                            if (entry && entry.icon !== "") return Quickshell.iconPath(entry.icon);
                        }
                        return Quickshell.iconPath("applications-other-symbolic");
                    }
                    visible: source !== ""
                }

                Text {
                    text: root.notification?.appName ?? ""
                    color: Config.colors.accent
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: Qt.formatTime(new Date(), "hh:mm")
                    color: Config.colors.textMuted
                    font.pixelSize: 10
                }

                // Close button
                Rectangle {
                    implicitWidth: 18
                    implicitHeight: 18
                    radius: 9
                    color: closeHover.containsMouse ? Config.colors.border : "transparent"

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: Config.colors.textMuted
                        font.pixelSize: 10
                    }

                    HoverHandler { id: closeHover }
                    TapHandler {
                        onTapped: root.animateOut()
                    }
                }
            }

            // Summary
            Text {
                text: root.notification?.summary ?? ""
                color: Config.colors.textPrimary
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }

            // Body
            Text {
                text: root.notification?.body ?? ""
                color: Config.colors.textSecondary
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.bottomMargin: 2
                visible: text !== ""
                maximumLineCount: 4
                elide: Text.ElideRight
            }

            // Actions
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 2
                spacing: 6
                visible: (root.notification?.actions?.length ?? 0) > 0

                Repeater {
                    model: root.notification?.actions ?? []

                    delegate: Rectangle {
                        required property NotificationAction modelData

                        implicitHeight: 24
                        implicitWidth: actionLabel.implicitWidth + 16
                        radius: 6
                        color: actionHover.containsMouse ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.3) : Config.colors.border
                        border.color: Config.colors.border
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: modelData.text
                            color: Config.colors.textPrimary
                            font.pixelSize: 11
                        }

                        HoverHandler { id: actionHover }
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
