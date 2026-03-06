pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire

Scope {
    id: root

    property bool visible_: false

    // ── Shared popup manager ──────────────────────────────────────────────────
    // Only one popup open at a time. Sections call root.openPopup("name") on
    // hover-enter and root.keepPopup() on hover-exit. Timers only run while
    // the mouse is outside pill+popup; hovering either keeps everything alive.
    property string activePopup: ""   // "wifi"|"bt"|"volume"|"screen"|"kbd"|"battery"|"power"|"clock"|""

    readonly property bool anyPopupOpen: activePopup !== ""

    // True while the pointer is over the pill bar itself
    property bool pillHovered: false
    // True while the pointer is over the active popup rectangle
    property bool popupHovered: false

    // Tracks the currently visible tray popup Item for the input mask
    property Item activeTrayMenuPopup: null

    // ── WiFi password dialog state (hoisted so passwordWin can see it) ────────
    property bool wifiPasswordDialogVisible: false
    property string wifiPasswordPendingSsid: ""
    signal wifiConnectWithPassword(string ssid_, string password)

    function registerTrayPopup(item) {
        root.activeTrayMenuPopup = item;
    }
    function unregisterTrayPopup() {
        root.activeTrayMenuPopup = null;
    }

    // Called by trigger hover-enter OR popup hover-enter
    function openPopup(name) {
        root.activePopup = name;
        root.popupHovered = true;
        popupCloseTimer.stop();
        root.keepAlive();
    }

    // Called by popup hover-exit (mouse leaving the popup rect)
    function exitPopup() {
        root.popupHovered = false;
        if (root.activePopup !== "") {
            popupCloseTimer.restart();
            root.keepAlive();
        }
    }

    // Called by trigger hover-exit (mouse leaving the trigger, not the popup)
    function keepPopup() {
        if (root.activePopup !== "") {
            if (!root.popupHovered)
                popupCloseTimer.restart();
            root.keepAlive();
        }
    }

    function closePopup() {
        root.activePopup = "";
        root.popupHovered = false;
        popupCloseTimer.stop();
        root.keepAlive();
    }

    Timer {
        id: popupCloseTimer
        interval: Config.bar.hideDelay
        onTriggered: if (!root.popupHovered)
            root.closePopup()
    }

    // ── Bar show/hide ─────────────────────────────────────────────────────────

    function show() {
        root.visible_ = true;
        hideTimer.restart();
    }

    function keepAlive() {
        hideTimer.restart();
    }

    IpcHandler {
        target: "bar"
        function toggle() {
            if (root.visible_) {
                root.visible_ = false;
                hideTimer.stop();
                root.closePopup();
            } else {
                root.show();
            }
        }
    }

    Timer {
        id: hideTimer
        interval: Config.bar.hideDelay
        onTriggered: if (root.activePopup === "")
            root.visible_ = false
    }

    // ── Clock ─────────────────────────────────────────────────────────────────

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ── Audio ─────────────────────────────────────────────────────────────────

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    // ── Shared slider label width (so all sliders keep the same label column) ─

    TextMetrics {
        id: statusTextMetrics
        font.family: Config.font.family
        font.pixelSize: Config.bar.fontSizeStatus
        text: "100%"
    }

    readonly property int sliderLabelWidth: Math.round(statusTextMetrics.boundingRect.width + 4 * Config.scale)

    // ── WiFi password overlay window ──────────────────────────────────────────
    // Separate WlrLayer.Overlay window so TextInput receives keyboard events.
    // The bar PanelWindow (WlrLayer.Top, no keyboard interactivity) cannot host
    // a focusable TextInput, so we use a dedicated overlay here.

    PanelWindow {
        id: passwordWin

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        anchors.bottom: true
        exclusiveZone: 0
        color: "transparent"

        implicitWidth: passwordWin.screen ? passwordWin.screen.width : 1920
        implicitHeight: passwordWin.screen ? passwordWin.screen.height : 1080

        visible: root.wifiPasswordDialogVisible

        mask: Region {
            item: pwDialog
        }

        // Centred dialog card
        Rectangle {
            id: pwDialog

            width: Math.round(290 * Config.scale)
            implicitHeight: pwDialogCol.implicitHeight + Math.round(36 * Config.scale)

            anchors.horizontalCenter: parent.horizontalCenter
            // Sit just above the bar pill (roughly 100px from the bottom)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.round(72 * Config.scale)

            radius: Math.round(16 * Config.scale)
            // Glassmorphic gradient fill
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(0.15, 0.14, 0.28, 0.96) }
                GradientStop { position: 1.0; color: Qt.rgba(0.08, 0.08, 0.18, 0.92) }
            }
            border.color: Config.colors.border
            border.width: 1

            // Top shine rim
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                radius: parent.radius
                color: "#30ffffff"
            }

            // Soft drop-shadow blob
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: -Math.round(8 * Config.scale)
                width: parent.width * 0.8
                height: Math.round(20 * Config.scale)
                radius: height / 2
                color: Config.colors.shadowDark
                opacity: 0.7
                z: -1
            }

            ColumnLayout {
                id: pwDialogCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: Math.round(22 * Config.scale)
                anchors.leftMargin: Math.round(18 * Config.scale)
                anchors.rightMargin: Math.round(18 * Config.scale)
                spacing: Math.round(12 * Config.scale)

                Text {
                    Layout.fillWidth: true
                    text: "Connect to"
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizeStatus
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    Layout.fillWidth: true
                    text: root.wifiPasswordPendingSsid
                    color: Config.colors.accent
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizeStatus
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                }

                // Password input row
                Item {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(36 * Config.scale)

                    // Glow ring on focus
                    Rectangle {
                        anchors.fill: pwInputRect
                        anchors.margins: -3
                        radius: pwInputRect.radius + 3
                        color: "transparent"
                        border.color: Config.colors.accentGlow
                        border.width: 2
                        opacity: pwField.activeFocus ? 0.5 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    Rectangle {
                        id: pwInputRect
                        anchors.fill: parent
                        radius: Math.round(8 * Config.scale)
                        color: Qt.rgba(1, 1, 1, 0.06)
                        border.color: pwField.activeFocus ? Config.colors.accent : Config.colors.border
                        border.width: 1
                        Behavior on border.color {
                            ColorAnimation { duration: 120 }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Math.round(10 * Config.scale)
                            anchors.rightMargin: Math.round(6 * Config.scale)
                            spacing: Math.round(4 * Config.scale)

                            TextInput {
                                id: pwField
                                Layout.fillWidth: true
                                color: Config.colors.textPrimary
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizeStatus
                                echoMode: pwShowBtn.showPw ? TextInput.Normal : TextInput.Password
                                passwordCharacter: "\u2022"
                                clip: true
                                selectByMouse: true
                                verticalAlignment: TextInput.AlignVCenter

                                // Placeholder text
                                Text {
                                    anchors.fill: parent
                                    text: "Password"
                                    color: Config.colors.textMuted
                                    font.family: Config.font.family
                                    font.pixelSize: Config.bar.fontSizeStatus
                                    verticalAlignment: Text.AlignVCenter
                                    visible: pwField.text === "" && !pwField.activeFocus
                                }

                                Keys.onReturnPressed: {
                                    if (pwField.text.length > 0)
                                        root.wifiConnectWithPassword(root.wifiPasswordPendingSsid, pwField.text);
                                }
                                Keys.onEscapePressed: {
                                    root.wifiPasswordDialogVisible = false;
                                    root.wifiPasswordPendingSsid = "";
                                }
                            }

                            // Show/hide password toggle
                            Rectangle {
                                id: pwShowBtn
                                property bool showPw: false
                                implicitWidth: Math.round(24 * Config.scale)
                                implicitHeight: Math.round(24 * Config.scale)
                                radius: Math.round(6 * Config.scale)
                                color: pwShowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                                Behavior on color { ColorAnimation { duration: 80 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: pwShowBtn.showPw ? "\ud83d\ude48" : "\ud83d\udc41"
                                    font.pixelSize: Math.round(11 * Config.scale)
                                }

                                MouseArea {
                                    id: pwShowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: pwShowBtn.showPw = !pwShowBtn.showPw
                                }
                            }
                        }
                    }
                }

                // Buttons row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(8 * Config.scale)

                    // Cancel
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.round(32 * Config.scale)
                        radius: Math.round(8 * Config.scale)
                        color: pwCancelMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
                        border.color: Config.colors.border
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 80 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Config.colors.textPrimary
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.fontSizeStatus
                        }

                        MouseArea {
                            id: pwCancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.wifiPasswordDialogVisible = false;
                                root.wifiPasswordPendingSsid = "";
                            }
                        }
                    }

                    // Connect
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.round(32 * Config.scale)
                        radius: Math.round(8 * Config.scale)
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, pwConnectMouse.containsMouse ? 0.45 : 0.28) }
                            GradientStop { position: 1.0; color: Qt.rgba(Config.colors.accentAlt.r, Config.colors.accentAlt.g, Config.colors.accentAlt.b, pwConnectMouse.containsMouse ? 0.35 : 0.18) }
                        }
                        border.color: Config.colors.accent
                        border.width: 1
                        opacity: pwField.text.length > 0 ? 1.0 : 0.4
                        Behavior on opacity { NumberAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            color: Config.colors.accent
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.fontSizeStatus
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: pwConnectMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (pwField.text.length > 0)
                                    root.wifiConnectWithPassword(root.wifiPasswordPendingSsid, pwField.text);
                            }
                        }
                    }
                }

                // Bottom spacer
                Item { implicitHeight: Math.round(4 * Config.scale) }
            }
        }

        // Clear the field and grab focus whenever the dialog appears
        Connections {
            target: root
            function onWifiPasswordDialogVisibleChanged() {
                if (root.wifiPasswordDialogVisible) {
                    pwField.text = "";
                    pwShowBtn.showPw = false;
                    pwField.forceActiveFocus();
                }
            }
        }
    }

    // ── Window ────────────────────────────────────────────────────────────────

    PanelWindow {
        id: win

        WlrLayershell.layer: WlrLayer.Top
        anchors.bottom: true
        exclusiveZone: 0
        color: "transparent"

        implicitWidth: win.screen ? win.screen.width : 1920
        implicitHeight: win.screen ? win.screen.height : 1080

        mask: Region {
            Region {
                item: pill
            }
            Region {
                item: root.activePopup === "wifi" ? wifiSection.popup : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "bt" ? btSection.popup : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "volume" ? volumeSection.popup : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "screen" ? screenSection.popup : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "kbd" ? kbdSection.popup : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "battery" ? batterySection.popup : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "power" ? powerSection.popup : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "clock" ? clockSection.popup : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activeTrayMenuPopup
                intersection: Intersection.Combine
            }
        }

        // ── Drop-shadow glow blob (behind pill) ──────────────────────────────
        Rectangle {
            id: pillGlow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.visible_ ? Math.round(4 * Config.scale) : -(pill.implicitHeight + Math.round(40 * Config.scale))
            Behavior on anchors.bottomMargin {
                NumberAnimation { duration: Config.bar.animateSpeed; easing.type: Easing.InOutCubic }
            }

            width: pill.implicitWidth + Math.round(60 * Config.scale)
            height: Math.round(32 * Config.scale)
            radius: height / 2
            color: Config.colors.glowAccent
            opacity: root.visible_ ? 0.55 : 0
            Behavior on opacity {
                NumberAnimation { duration: Config.bar.animateSpeed; easing.type: Easing.InOutQuad }
            }
            // soften the glow with a second larger, more transparent layer
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + Math.round(40 * Config.scale)
                height: parent.height + Math.round(12 * Config.scale)
                radius: height / 2
                color: Config.colors.glowAccent
                opacity: 0.25
            }
        }

        Rectangle {
            id: pill

            implicitWidth: content.implicitWidth + Config.bar.padding * 2
            implicitHeight: content.implicitHeight + Math.round(12 * Config.scale) * 2

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.visible_ ? Math.round(8 * Config.scale) : -(pill.implicitHeight + Math.round(8 * Config.scale))

            Behavior on anchors.bottomMargin {
                NumberAnimation {
                    duration: Config.bar.animateSpeed
                    easing.type: Easing.InOutCubic
                }
            }

            radius: Config.bar.radius
            color: "transparent"
            border.color: Config.colors.border
            border.width: 1

            // Glassmorphic gradient fill
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.rgba(0.15, 0.14, 0.26, 0.94) }
                    GradientStop { position: 1.0; color: Qt.rgba(0.08, 0.08, 0.18, 0.88) }
                }
            }

            // Inner highlight rim (top edge shine)
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                radius: parent.radius
                color: "#35ffffff"
            }

            opacity: root.visible_ ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Config.bar.animateSpeed
                    easing.type: Easing.InOutQuad
                }
            }

            HoverHandler {
                onHoveredChanged: {
                    root.pillHovered = hovered;
                    if (hovered)
                        root.keepAlive();
                }
            }

            RowLayout {
                id: content
                anchors.centerIn: parent
                spacing: Config.bar.sectionSpacing

                // ── Tray ─────────────────────────────────────────────────────
                Repeater {
                    id: trayRepeater
                    model: SystemTray.items
                    delegate: BarTrayItem {
                        id: trayDelegate
                        required property SystemTrayItem modelData
                        required property int index
                        trayItem: modelData
                        popupName: "tray-" + trayDelegate.index
                        activePopup: root.activePopup
                        onHovered: root.keepAlive()
                        onOpenPopupReq: name => {
                            root.openPopup(name);
                            root.registerTrayPopup(trayDelegate.menuPopup);
                        }
                        onKeepPopupReq: root.keepPopup()
                        onExitPopupReq: root.exitPopup()
                        onPopupOpenChanged: {
                            if (!trayDelegate.popupOpen)
                                root.unregisterTrayPopup();
                        }
                    }
                }

                Rectangle {
                    implicitWidth: 1
                    implicitHeight: Config.bar.batteryIconSize
                    color: Config.colors.border
                    visible: trayRepeater.count > 0
                    // subtle gradient separator
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.3; color: Config.colors.border }
                        GradientStop { position: 0.7; color: Config.colors.border }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                // ── Wifi ─────────────────────────────────────────────────────
                BarWifiSection {
                    id: wifiSection
                    activePopup: root.activePopup
                    onOpenPopupReq: name => root.openPopup(name)
                    onKeepPopupReq: root.keepPopup()
                    onExitPopupReq: root.exitPopup()
                    onKeepAliveReq: root.keepAlive()
                    onShowPasswordDialogReq: ssid_ => {
                        root.wifiPasswordPendingSsid = ssid_;
                        root.wifiPasswordDialogVisible = true;
                    }
                    onHidePasswordDialogReq: {
                        root.wifiPasswordDialogVisible = false;
                        root.wifiPasswordPendingSsid = "";
                    }
                }

                // Wire root.wifiConnectWithPassword → wifiSection.connectWifiWithPassword
                Connections {
                    target: root
                    function onWifiConnectWithPassword(ssid_, password) {
                        wifiSection.connectWifiWithPassword(ssid_, password);
                    }
                }

                // ── Bluetooth ─────────────────────────────────────────────────
                BarBtSection {
                    id: btSection
                    activePopup: root.activePopup
                    onOpenPopupReq: name => root.openPopup(name)
                    onKeepPopupReq: root.keepPopup()
                    onExitPopupReq: root.exitPopup()
                }

                // ── Volume ────────────────────────────────────────────────────
                BarVolumeSection {
                    id: volumeSection
                    activePopup: root.activePopup
                    sliderLabelWidth: root.sliderLabelWidth
                    onOpenPopupReq: name => root.openPopup(name)
                    onKeepPopupReq: root.keepPopup()
                    onExitPopupReq: root.exitPopup()
                    onKeepAliveReq: root.keepAlive()
                }

                // ── Screen brightness ─────────────────────────────────────────
                BarScreenSection {
                    id: screenSection
                    activePopup: root.activePopup
                    sliderLabelWidth: root.sliderLabelWidth
                    onOpenPopupReq: name => root.openPopup(name)
                    onKeepPopupReq: root.keepPopup()
                    onExitPopupReq: root.exitPopup()
                    onKeepAliveReq: root.keepAlive()
                }

                // ── Keyboard brightness ───────────────────────────────────────
                BarKbdSection {
                    id: kbdSection
                    activePopup: root.activePopup
                    sliderLabelWidth: root.sliderLabelWidth
                    onOpenPopupReq: name => root.openPopup(name)
                    onKeepPopupReq: root.keepPopup()
                    onExitPopupReq: root.exitPopup()
                    onKeepAliveReq: root.keepAlive()
                }

                // ── Power profiles ────────────────────────────────────────────
                BarPowerSection {
                    id: powerSection
                    activePopup: root.activePopup
                    onOpenPopupReq: name => root.openPopup(name)
                    onKeepPopupReq: root.keepPopup()
                    onExitPopupReq: root.exitPopup()
                }

                // ── Battery ───────────────────────────────────────────────────
                BarBatterySection {
                    id: batterySection
                    activePopup: root.activePopup
                    onOpenPopupReq: name => root.openPopup(name)
                    onExitPopupReq: root.exitPopup()
                }

                Rectangle {
                    implicitWidth: 1
                    implicitHeight: Config.bar.batteryIconSize
                    color: Config.colors.border
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.3; color: Config.colors.border }
                        GradientStop { position: 0.7; color: Config.colors.border }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                // ── Clock / Date ──────────────────────────────────────────────
                BarClockSection {
                    id: clockSection
                    activePopup: root.activePopup
                    clockDate: clock.date
                    onOpenPopupReq: name => root.openPopup(name)
                    onKeepPopupReq: root.keepPopup()
                    onExitPopupReq: root.exitPopup()
                }
            }
        }
    }
}
