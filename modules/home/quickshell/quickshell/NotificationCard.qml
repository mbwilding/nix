pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "components"

Item {
    id: root

    // In live mode: set this to the Notification object.
    // In history mode: leave null; set historyMode = true and snapshot = {...}.
    property Notification notification: null

    // History mode — display a static snapshot instead of a live notification.
    property bool historyMode: false
    property var snapshot: null   // { id, appName, appIcon, desktopEntry, summary, body, actions, receivedAt }

    property int timeout: Config.notifications.timeout
    property bool visible_: false
    property real latchedHeight: 0

    // Set to true by dismissTimer before animateOut() so we can suppress
    // the dismissed() signal (timeout = stay in history).
    property bool _timedOut: false

    // Emitted after the card has fully animated out.
    // In live mode: NOT emitted on timeout (so timed-out entries stay in history).
    // In history mode: emitted when the user interacts to remove the entry.
    signal dismissed
    signal hovered

    clip: false
    implicitHeight: latchedHeight
    implicitWidth: Config.notifications.cardWidth

    Component.onCompleted: {
        if (root.historyMode) {
            // Appear instantly — no slide-in animation
            root.latchedHeight = card.implicitHeight + Math.round(8 * Config.scale);
            root.visible_ = true;
            slideTranslate.x = 0;
            card.opacity = 1;
            card.scale = 1;
        } else {
            Qt.callLater(() => {
                root.latchedHeight = card.implicitHeight + Math.round(8 * Config.scale);
                visible_ = true;
                slideTranslate.x = 0;
                card.opacity = 1;
                card.scale = 1;
            });
        }
    }

    Connections {
        target: card
        function onImplicitHeightChanged() {
            if (!exitAnim.running && !historyExitAnim.running)
                root.latchedHeight = card.implicitHeight + Math.round(8 * Config.scale);
        }
    }

    function animateOut() {
        if (!root.visible_)
            return;
        root.visible_ = false;
        dismissTimer.stop();
        if (root.historyMode)
            historyExitAnim.start();
        else
            exitAnim.start();
    }

    Timer {
        id: dismissTimer
        interval: root.timeout
        running: root.visible_ && root.timeout > 0 && !root.historyMode
        onTriggered: {
            root._timedOut = true;
            root.animateOut();
        }
    }

    // Live exit: slide out + fade + height collapse
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
                if (!root._timedOut) {
                    root.notification?.dismiss();
                    root.dismissed();
                }
            }
        }
    }

    // History exit: height collapse only — cards above slide up, no slide/fade
    SequentialAnimation {
        id: historyExitAnim

        NumberAnimation {
            target: root
            property: "latchedHeight"
            to: 0
            duration: Config.notifications.animateSpeed
            easing.type: Easing.OutCubic
        }

        ScriptAction {
            script: root.dismissed()
        }
    }

    PopupCard {
        id: card

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: Math.round(4 * Config.scale)
        }

        popupRadius: Config.notifications.radius
        implicitHeight: cardContent.implicitHeight + Math.round(22 * Config.scale)

        transform: Translate {
            id: slideTranslate
            x: card.width + 24
            Behavior on x {
                enabled: !root.historyMode
                NumberAnimation {
                    duration: Config.notifications.animateSpeed
                    easing.type: Easing.OutCubic
                }
            }
        }

        opacity: 0
        scale: 0.92
        Behavior on opacity {
            enabled: !root.historyMode
            NumberAnimation {
                duration: Config.notifications.animateSpeed
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            enabled: !root.historyMode
            NumberAnimation {
                duration: Config.notifications.animateSpeed
                easing.type: Easing.OutBack
                easing.overshoot: 0.6
            }
        }

        // Card tap — dismiss (live) or collapse and remove from history
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.hovered()
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

            // Glow layer — wider neon halo behind the stripe
            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: width / 2
                color: Config.colors.glowAccent
                opacity: 0.45
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
                        const appIcon    = root.historyMode ? (root.snapshot?.appIcon    ?? "") : (root.notification?.appIcon    ?? "");
                        const deskEntry  = root.historyMode ? (root.snapshot?.desktopEntry ?? "") : (root.notification?.desktopEntry ?? "");
                        if (appIcon !== "") {
                            const path = Quickshell.iconPath(appIcon);
                            if (path !== "")
                                return path;
                        }
                        if (deskEntry !== "" && deskEntry !== null) {
                            const entry = DesktopEntries.byId(deskEntry);
                            if (entry && entry.icon !== "")
                                return Quickshell.iconPath(entry.icon);
                        }
                        return Quickshell.iconPath("applications-other-symbolic");
                    }
                    visible: source !== ""
                }

                Text {
                    text: root.historyMode ? (root.snapshot?.appName ?? "") : (root.notification?.appName ?? "")
                    color: Config.colors.accent
                    font.family: Config.font.family
                    font.pixelSize: Config.notifications.fontSizeAppName
                    font.weight: Font.SemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: {
                        if (root.historyMode) {
                            const d = root.snapshot?.receivedAt;
                            return d ? Qt.formatTime(d, "hh:mm") : "";
                        }
                        return Qt.formatTime(new Date(), "hh:mm");
                    }
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.notifications.fontSizeTimestamp
                }
            }

            // Summary
            Text {
                text: root.historyMode ? (root.snapshot?.summary ?? "") : (root.notification?.summary ?? "")
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
                text: root.historyMode ? (root.snapshot?.body ?? "") : (root.notification?.body ?? "")
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

                readonly property var _actions: root.historyMode
                    ? (root.snapshot?.actions ?? [])
                    : (root.notification?.actions ?? [])
                visible: _actions.length > 0

                Repeater {
                    model: parent._actions

                    delegate: Item {
                        id: actionDelegate
                        required property var modelData

                        implicitHeight: Math.round(28 * Config.scale)
                        implicitWidth: actionBg.implicitWidth

                        // Neon glow ring on hover
                        Rectangle {
                            anchors.fill: actionBg
                            anchors.margins: -3
                            radius: actionBg.radius + 3
                            color: "transparent"
                            border.color: Config.colors.accent
                            border.width: 2
                            opacity: actionArea.containsMouse ? 0.55 : 0
                            Behavior on opacity { NumberAnimation { duration: 80 } }
                        }

                        Rectangle {
                            id: actionBg
                            anchors.fill: parent
                            implicitWidth: actionLabel.implicitWidth + Math.round(18 * Config.scale)
                            radius: Math.round(8 * Config.scale)
                            color: actionArea.containsMouse
                                ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.28)
                                : Config.colors.surfaceAlt
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
                                // In live mode modelData is a NotificationAction object with .text
                                // In history mode modelData is a plain JS object {identifier, text}
                                text: actionDelegate.modelData.text ?? ""
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
                                actionDelegate.modelData.invoke();
                                root.animateOut();
                            }
                        }
                    }
                }
            }
        }
    }
}
