pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire

import "."
import ".."
import "../components"
import "../services"

Scope {
    id: root

    property Item activeTrayMenuPopup: null
    property bool pillHovered: false
    property bool popupHovered: false
    property bool visible_: false
    property bool wifiPasswordDialogVisible: false
    property string activePopup: ""
    property string wifiPasswordPendingSsid: ""
    property var notifHistory: []

    readonly property bool anyPopupOpen: activePopup !== ""
    readonly property int sliderLabelWidth: Math.round(statusTextMetrics.boundingRect.width + 4 * Config.scale)

    signal removeHistoryEntry(var entryId)
    signal animateOutHistoryEntry(var snapId)
    signal dismissAllNotifs
    signal wifiConnectWithPassword(string ssid_, string password)

    function registerTrayPopup(item) {
        root.activeTrayMenuPopup = item;
    }

    function unregisterTrayPopup() {
        root.activeTrayMenuPopup = null;
    }

    function openPopup(name) {
        root.activePopup = name;
        quickCloseTimer.stop();
        popupCloseTimer.stop();
        root.keepAlive();
    }

    function enterPopup() {
        root.popupHovered = true;
        quickCloseTimer.stop();
        popupCloseTimer.stop();
        root.keepAlive();
    }

    function exitPopup() {
        root.popupHovered = false;
        if (root.activePopup !== "") {
            quickCloseTimer.restart();
            root.keepAlive();
        }
    }

    function keepPopup() {
        if (root.activePopup !== "") {
            quickCloseTimer.restart();
            root.keepAlive();
        }
    }

    function closePopup() {
        root.activePopup = "";
        root.popupHovered = false;
        popupCloseTimer.stop();
        quickCloseTimer.stop();
        root.keepAlive();
    }

    function show() {
        root.visible_ = true;
        hideTimer.restart();
    }

    function keepAlive() {
        hideTimer.restart();
    }

    // Helper: returns true if `value` appears in `arr`
    function inList(arr, value) {
        for (let i = 0; i < arr.length; i++) {
            if (arr[i] === value) return true;
        }
        return false;
    }

    Timer {
        id: popupCloseTimer
        interval: Config.bar.hideDelay
        onTriggered: root.closePopup()
    }

    Timer {
        id: quickCloseTimer
        interval: 600
        onTriggered: root.closePopup()
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
        onTriggered: if (root.activePopup === "" && !root.pillHovered)
            root.visible_ = false
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    PwObjectTracker {
        objects: {
            void Pipewire.nodes.valuesChanged;
            return Pipewire.nodes.values;
        }
    }

    TextMetrics {
        id: statusTextMetrics
        font.family: Config.font.family
        font.pixelSize: Config.bar.fontSizePopup
        text: "100%"
    }

    PanelWindow {
        id: passwordWin
        screen: Quickshell.screens[Config.monitor]
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.layer: WlrLayer.Overlay
        anchors.bottom: true
        color: "transparent"
        exclusiveZone: 0
        implicitHeight: passwordWin.screen ? passwordWin.screen.height : 1080
        implicitWidth: passwordWin.screen ? passwordWin.screen.width : 1920
        visible: root.wifiPasswordDialogVisible
        mask: Region {
            item: pwDialog
        }

        PopupCard {
            id: pwDialog

            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.round(72 * Config.scale)
            anchors.horizontalCenter: parent.horizontalCenter
            implicitHeight: pwDialogCol.implicitHeight + Math.round(36 * Config.scale)
            popupRadius: Math.round(16 * Config.scale)
            width: Math.round(290 * Config.scale)

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
                    font.pixelSize: Config.bar.fontSizePopup
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    Layout.fillWidth: true
                    text: root.wifiPasswordPendingSsid
                    color: Config.colors.accent
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizePopup
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(36 * Config.scale)

                    Rectangle {
                        anchors.fill: pwInputRect
                        anchors.margins: -3
                        radius: pwInputRect.radius + 3
                        color: "transparent"
                        border.color: Config.colors.accentGlow
                        border.width: 2
                        opacity: pwField.activeFocus ? 0.5 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                    }

                    Rectangle {
                        id: pwInputRect
                        anchors.fill: parent
                        radius: Math.round(8 * Config.scale)
                        color: Config.colors.surfaceAlt
                        border.color: pwField.activeFocus ? Config.colors.accent : Config.colors.border
                        border.width: 1
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 120
                            }
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
                                font.pixelSize: Config.bar.fontSizePopup
                                echoMode: pwShowBtn.showPw ? TextInput.Normal : TextInput.Password
                                passwordCharacter: "\u2022"
                                clip: true
                                selectByMouse: true
                                verticalAlignment: TextInput.AlignVCenter

                                Text {
                                    anchors.fill: parent
                                    text: "Password"
                                    color: Config.colors.textMuted
                                    font.family: Config.font.family
                                    font.pixelSize: Config.bar.fontSizePopup
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

                            Rectangle {
                                id: pwShowBtn
                                property bool showPw: false
                                implicitWidth: Math.round(24 * Config.scale)
                                implicitHeight: Math.round(24 * Config.scale)
                                radius: Math.round(6 * Config.scale)
                                color: pwShowMouse.containsMouse ? Config.colors.surfaceHover : "transparent"
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 80
                                    }
                                }

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

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(8 * Config.scale)

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.round(32 * Config.scale)
                        radius: Math.round(8 * Config.scale)
                        color: pwCancelMouse.containsMouse ? Config.colors.surfaceHover : Config.colors.surfaceAlt
                        border.color: Config.colors.border
                        border.width: 1
                        Behavior on color {
                            ColorAnimation {
                                duration: 80
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Config.colors.textPrimary
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.fontSizePopup
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

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.round(32 * Config.scale)
                        radius: Math.round(8 * Config.scale)
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop {
                                position: 0.0
                                color: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, pwConnectMouse.containsMouse ? 0.45 : 0.28)
                            }
                            GradientStop {
                                position: 1.0
                                color: Qt.rgba(Config.colors.accentAlt.r, Config.colors.accentAlt.g, Config.colors.accentAlt.b, pwConnectMouse.containsMouse ? 0.35 : 0.18)
                            }
                        }
                        border.color: Config.colors.accent
                        border.width: 1
                        opacity: pwField.text.length > 0 ? 1.0 : 0.35
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            color: Config.colors.accent
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.fontSizePopup
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

                Item {
                    implicitHeight: Math.round(4 * Config.scale)
                }
            }
        }

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

    PanelWindow {
        id: win

        screen: Quickshell.screens[Config.monitor]
        WlrLayershell.layer: WlrLayer.Overlay
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
                item: root.activePopup === "brightness" ? brightnessSection.popup : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "power" ? powerSection.popup : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "notif" ? notifSection.popup : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activeTrayMenuPopup
                intersection: Intersection.Combine
            }
        }

        Rectangle {
            id: pill

            implicitWidth: content.implicitWidth + Config.bar.padding * 2
            implicitHeight: content.implicitHeight + Math.round(12 * Config.scale) * 2

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.visible_ ? Math.round(8 * Config.scale) : -(pill.implicitHeight + Math.round(8 * Config.scale))

            containmentMask: Item {
                x: 0
                y: -win.implicitHeight
                width: pill.width
                height: win.implicitHeight + pill.height
            }

            radius: Config.bar.radius
            antialiasing: true
            color: Config.colors.surface
            border.width: Config.panelBorder.width
            border.color: Config.panelBorder.color
            opacity: root.visible_ ? 1 : 0

            Behavior on anchors.bottomMargin {
                NumberAnimation {
                    duration: Config.bar.animateSpeed
                    easing.type: Easing.InOutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Config.bar.animateSpeed
                    easing.type: Easing.InOutQuad
                }
            }

            HoverHandler {
                onHoveredChanged: {
                    root.pillHovered = hovered;
                    root.keepAlive();
                }
            }

            // ----------------------------------------------------------------
            // All named section instances live here, outside the layout, so
            // that popup masking + Connections always work regardless of
            // whether a section appears in Config.bar.layout / systemLayout.
            // They are positioned by the layout Repeater below via visible.
            // ----------------------------------------------------------------

            WifiSection {
                id: wifiSection
                visible: false
                activePopup: root.activePopup
                availableHeight: win.screen ? win.screen.height : 800
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

            Connections {
                target: root
                function onWifiConnectWithPassword(ssid_, password) {
                    wifiSection.connectWifiWithPassword(ssid_, password);
                }
            }

            EthernetSection {
                id: ethernetSection
                visible: false
                activePopup: root.activePopup
                availableHeight: win.screen ? win.screen.height : 800
                onOpenPopupReq: name => root.openPopup(name)
                onKeepPopupReq: root.keepPopup()
                onExitPopupReq: root.exitPopup()
                onKeepAliveReq: root.keepAlive()
            }

            BtSection {
                id: btSection
                visible: false
                activePopup: root.activePopup
                availableHeight: win.screen ? win.screen.height : 800
                onOpenPopupReq: name => root.openPopup(name)
                onKeepPopupReq: root.keepPopup()
                onExitPopupReq: root.exitPopup()
            }

            VolumeSection {
                id: volumeSection
                visible: false
                activePopup: root.activePopup
                availableHeight: win.screen ? win.screen.height : 800
                onOpenPopupReq: name => root.openPopup(name)
                onKeepPopupReq: root.keepPopup()
                onExitPopupReq: root.exitPopup()
                onKeepAliveReq: root.keepAlive()
            }

            BrightnessSection {
                id: brightnessSection
                visible: false
                activePopup: root.activePopup
                sliderLabelWidth: root.sliderLabelWidth
                screenBrightness: BrightnessService.screenBrightness
                screenAvailable: BrightnessService.screenAvailable
                kbdBrightness: BrightnessService.kbdBrightness
                kbdAvailable: BrightnessService.kbdAvailable
                onOpenPopupReq: name => root.openPopup(name)
                onKeepPopupReq: root.keepPopup()
                onExitPopupReq: root.exitPopup()
                onKeepAliveReq: root.keepAlive()
                onSetScreenBrightnessReq: v => BrightnessService.setScreenBrightness(v)
                onSetKbdBrightnessReq: v => BrightnessService.setKbdBrightness(v)
            }

            PowerSection {
                id: powerSection
                visible: false
                activePopup: root.activePopup
                onOpenPopupReq: name => root.openPopup(name)
                onKeepPopupReq: root.keepPopup()
                onExitPopupReq: root.exitPopup()
                onClosePopupReq: root.closePopup()
            }

            NotifSection {
                id: notifSection
                visible: false
                activePopup: root.activePopup
                availableHeight: win.screen ? win.screen.height : 800
                notifHistory: root.notifHistory
                onOpenPopupReq: name => root.openPopup(name)
                onKeepPopupReq: root.keepPopup()
                onExitPopupReq: root.exitPopup()
                onClosePopupReq: root.closePopup()
                onRemoveHistoryEntry: entryId => root.removeHistoryEntry(entryId)
                onDismissAll: root.dismissAllNotifs()

                Connections {
                    target: root
                    function onAnimateOutHistoryEntry(snapId) {
                        notifSection.animateOutEntry(snapId);
                    }
                }
            }

            // ----------------------------------------------------------------
            // Top-level bar layout — driven by Config.bar.layout
            // ----------------------------------------------------------------
            RowLayout {
                id: content
                anchors.centerIn: parent
                spacing: Config.bar.sectionSpacing

                containmentMask: Item {
                    x: 0
                    y: -win.implicitHeight
                    width: content.width
                    height: win.implicitHeight + content.height
                }

                Repeater {
                    model: Config.bar.layout
                    delegate: Loader {
                        id: barSlotLoader
                        required property int modelData
                        // Loader itself participates in the RowLayout
                        Layout.alignment: Qt.AlignVCenter

                        sourceComponent: {
                            switch (barSlotLoader.modelData) {
                            case BarItems.tray:      return trayComponent
                            case BarItems.system:    return systemComponent
                            case BarItems.clock:     return clockComponent
                            case BarItems.separator: return barSeparatorComponent
                            default:                 return null
                            }
                        }
                    }
                }
            }

            // ---- top-level slot components ----

            Component {
                id: trayComponent
                Row {
                    spacing: Config.bar.sectionSpacing
                    Repeater {
                        model: SystemTray.items
                        delegate: TrayItem {
                            id: trayDelegate
                            required property SystemTrayItem modelData
                            required property int index
                            trayItem: modelData
                            popupName: "tray-" + trayDelegate.index
                            availableHeight: win.screen ? win.screen.height : 800
                            activePopup: root.activePopup
                            onHovered: root.keepAlive()
                            onOpenPopupReq: name => {
                                root.openPopup(name);
                                root.registerTrayPopup(trayDelegate.menuPopup);
                            }
                            onKeepPopupReq: root.keepPopup()
                            onExitPopupReq: root.exitPopup()
                            onClosePopupReq: {
                                root.closePopup();
                                root.unregisterTrayPopup();
                            }
                            onPopupOpenChanged: {
                                if (!trayDelegate.popupOpen)
                                    root.unregisterTrayPopup();
                            }
                        }
                    }
                }
            }

            Component {
                id: clockComponent
                ClockSection {
                    clockDate: clock.date
                }
            }

            Component {
                id: barSeparatorComponent
                BarSeparator {}
            }

            // ---- System section: inner Repeater over Config.bar.systemLayout ----
            // Each entry in systemLayout maps to a named section instance above,
            // which gets reparented into this Row for layout purposes.
            Component {
                id: systemComponent
                Row {
                    id: systemRow
                    spacing: Config.bar.sectionSpacing

                    Repeater {
                        model: Config.bar.systemLayout
                        delegate: Loader {
                            id: sysSlotLoader
                            required property int modelData

                            sourceComponent: {
                                switch (sysSlotLoader.modelData) {
                                case SystemItems.wifi:          return sysWifiComponent
                                case SystemItems.ethernet:      return sysEthernetComponent
                                case SystemItems.bluetooth:     return sysBtComponent
                                case SystemItems.volume:        return sysVolumeComponent
                                case SystemItems.brightness:    return sysBrightnessComponent
                                case SystemItems.power:         return sysPowerComponent
                                case SystemItems.notifications: return sysNotifComponent
                                case SystemItems.separator:     return barSeparatorComponent
                                default:                        return null
                                }
                            }
                        }
                    }
                }
            }

            // Proxy components: reparent each named section into the system Row.
            // onCompleted  → move the section here and show it
            // onDestruction → hide it again (parent reverts when item is destroyed)
            Component {
                id: sysWifiComponent
                Item {
                    id: wifiProxy
                    implicitWidth: wifiSection.implicitWidth
                    implicitHeight: wifiSection.implicitHeight
                    Component.onCompleted: {
                        wifiSection.parent = wifiProxy;
                        wifiSection.visible = true;
                    }
                    Component.onDestruction: {
                        wifiSection.visible = false;
                        wifiSection.parent = pill;
                    }
                }
            }
            Component {
                id: sysEthernetComponent
                Item {
                    id: ethernetProxy
                    implicitWidth: ethernetSection.implicitWidth
                    implicitHeight: ethernetSection.implicitHeight
                    Component.onCompleted: {
                        ethernetSection.parent = ethernetProxy;
                        ethernetSection.visible = true;
                    }
                    Component.onDestruction: {
                        ethernetSection.visible = false;
                        ethernetSection.parent = pill;
                    }
                }
            }
            Component {
                id: sysBtComponent
                Item {
                    id: btProxy
                    implicitWidth: btSection.implicitWidth
                    implicitHeight: btSection.implicitHeight
                    Component.onCompleted: {
                        btSection.parent = btProxy;
                        btSection.visible = true;
                    }
                    Component.onDestruction: {
                        btSection.visible = false;
                        btSection.parent = pill;
                    }
                }
            }
            Component {
                id: sysVolumeComponent
                Item {
                    id: volumeProxy
                    implicitWidth: volumeSection.implicitWidth
                    implicitHeight: volumeSection.implicitHeight
                    Component.onCompleted: {
                        volumeSection.parent = volumeProxy;
                        volumeSection.visible = true;
                    }
                    Component.onDestruction: {
                        volumeSection.visible = false;
                        volumeSection.parent = pill;
                    }
                }
            }
            Component {
                id: sysBrightnessComponent
                Item {
                    id: brightnessProxy
                    implicitWidth: brightnessSection.implicitWidth
                    implicitHeight: brightnessSection.implicitHeight
                    Component.onCompleted: {
                        brightnessSection.parent = brightnessProxy;
                        brightnessSection.visible = true;
                    }
                    Component.onDestruction: {
                        brightnessSection.visible = false;
                        brightnessSection.parent = pill;
                    }
                }
            }
            Component {
                id: sysPowerComponent
                Item {
                    id: powerProxy
                    implicitWidth: powerSection.implicitWidth
                    implicitHeight: powerSection.implicitHeight
                    Component.onCompleted: {
                        powerSection.parent = powerProxy;
                        powerSection.visible = true;
                    }
                    Component.onDestruction: {
                        powerSection.visible = false;
                        powerSection.parent = pill;
                    }
                }
            }
            Component {
                id: sysNotifComponent
                Item {
                    id: notifProxy
                    implicitWidth: notifSection.implicitWidth
                    implicitHeight: notifSection.implicitHeight
                    Component.onCompleted: {
                        notifSection.parent = notifProxy;
                        notifSection.visible = true;
                    }
                    Component.onDestruction: {
                        notifSection.visible = false;
                        notifSection.parent = pill;
                    }
                }
            }
        }
    }

    component BarSeparator: Rectangle {
        implicitWidth: 1
        implicitHeight: Config.bar.batteryIconSize
        color: Config.colors.border
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop {
                position: 0.0
                color: "transparent"
            }
            GradientStop {
                position: 0.25
                color: Config.colors.borderBright
            }
            GradientStop {
                position: 0.75
                color: Config.colors.borderBright
            }
            GradientStop {
                position: 1.0
                color: "transparent"
            }
        }
    }
}
