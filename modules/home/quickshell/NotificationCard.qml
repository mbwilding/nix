pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Item {
    id: root

    required property Notification notification
    property int animateSpeed: 250
    property int timeout: 5000

    property bool visible_: false
    property bool exiting: false

    implicitHeight: exiting ? 0 : (card.implicitHeight + 8)
    implicitWidth: 360

    Behavior on implicitHeight {
        enabled: root.exiting
        NumberAnimation {
            duration: root.animateSpeed
            easing.type: Easing.InOutQuad
        }
    }

    clip: true

    // Call this instead of notification.dismiss() directly —
    // plays the exit animation first, then dismisses after
    function animateOut() {
        if (root.exiting) return;
        dismissTimer.stop();
        visible_ = false;
        collapseTimer.start();
    }

    Component.onCompleted: Qt.callLater(() => { visible_ = true; })

    Timer {
        id: dismissTimer
        interval: root.timeout
        running: root.visible_
        onTriggered: root.animateOut()
    }

    Timer {
        id: collapseTimer
        interval: root.animateSpeed
        onTriggered: {
            root.exiting = true;
            root.notification?.dismiss();
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
        color: "#cc1a1a2e"

        border.color: "#30ffffff"
        border.width: 1

        transform: Translate {
            x: root.visible_ ? 0 : card.width + 20
            Behavior on x {
                NumberAnimation {
                    duration: root.animateSpeed
                    easing.type: Easing.InOutQuad
                }
            }
        }

        opacity: root.visible_ ? 1 : 0
        Behavior on opacity {
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
            color: "#a0a0ff"
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

            // Header: app icon + app name + timestamp
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
                    color: "#a0a0ff"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: Qt.formatTime(new Date(), "hh:mm")
                    color: "#60ffffff"
                    font.pixelSize: 10
                }

                // Close button
                Rectangle {
                    implicitWidth: 18
                    implicitHeight: 18
                    radius: 9
                    color: closeHover.containsMouse ? "#50ffffff" : "transparent"

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: "#80ffffff"
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
                color: "white"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }

            // Body
            Text {
                text: root.notification?.body ?? ""
                color: "#ccffffff"
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
                        color: actionHover.containsMouse ? "#50a0a0ff" : "#30ffffff"
                        border.color: "#30ffffff"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: modelData.text
                            color: "white"
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
