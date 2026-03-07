pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import "components"

// Volume / PipeWire audio configurator section.
//
// Bar icon: shows default sink volume / mute state.
//   Click  → toggle mute on default sink
//   Scroll → adjust volume on default sink
//
// Popup: lists all audio sinks and sources with per-device
//   volume sliders and mute toggles. Clicking a non-default
//   device sets it as the preferred default.
//
// Bar.qml binds activePopup and wires popup-manager signals.
Item {
    id: volumeSection

    // ── Public API ────────────────────────────────────────────────────────────

    property string activePopup: ""     // bound to root.activePopup

    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq
    signal keepAliveReq

    // Expose the popup rectangle so Bar.qml can include it in the input mask
    property alias popup: volumePopup

    // Screen height passed in from Bar.qml so the popup can cap itself.
    property real availableHeight: 800

    // ── State ─────────────────────────────────────────────────────────────────

    readonly property bool popupOpen: activePopup === "volume"
    readonly property var defaultSink:   Pipewire.defaultAudioSink
    readonly property var defaultSource: Pipewire.defaultAudioSource
    readonly property var audio: volumeSection.defaultSink?.audio ?? null

    // Filter nodes: real (non-stream) audio sinks and sources only
    readonly property var sinkNodes: {
        void Pipewire.nodes.valuesChanged;
        const vals = Pipewire.nodes.values;
        const result = [];
        for (let i = 0; i < vals.length; i++) {
            const n = vals[i];
            if (n && n.audio !== null && n.isSink && !n.isStream)
                result.push(n);
        }
        return result;
    }

    readonly property var sourceNodes: {
        void Pipewire.nodes.valuesChanged;
        const vals = Pipewire.nodes.values;
        const result = [];
        for (let i = 0; i < vals.length; i++) {
            const n = vals[i];
            if (n && n.audio !== null && !n.isSink && !n.isStream)
                result.push(n);
        }
        return result;
    }

    visible: volumeSection.defaultSink !== null

    // ── Geometry ──────────────────────────────────────────────────────────────

    implicitWidth: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    implicitHeight: Config.bar.batteryIconSize + Math.round(10 * Config.scale)

    containmentMask: Item {
        x: volumeSection.popupOpen ? -Math.max(0, (volumePopup.width - volumeSection.width) / 2) : 0
        y: volumeSection.popupOpen ? -volumePopup.height - Config.bar.popupOffset : 0
        width: volumeSection.popupOpen ? Math.max(volumeSection.width, volumePopup.width) : volumeSection.width
        height: volumeSection.popupOpen ? volumePopup.height + Config.bar.popupOffset + volumeSection.height : volumeSection.height
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    function volumeIcon() {
        const a = volumeSection.audio;
        if (!a || a.muted)
            return "audio-volume-muted-symbolic";
        const v = a.volume;
        if (v <= 0.33)
            return "audio-volume-low-symbolic";
        if (v <= 0.66)
            return "audio-volume-medium-symbolic";
        return "audio-volume-high-symbolic";
    }

    function nodeVolumeIcon(node) {
        if (!node || !node.audio) return "audio-volume-muted-symbolic";
        const a = node.audio;
        if (a.muted) return "audio-volume-muted-symbolic";
        const v = a.volume;
        if (v <= 0.33) return "audio-volume-low-symbolic";
        if (v <= 0.66) return "audio-volume-medium-symbolic";
        return "audio-volume-high-symbolic";
    }

    function sourceIcon(node) {
        if (!node || !node.audio) return "microphone-sensitivity-muted-symbolic";
        const a = node.audio;
        if (a.muted) return "microphone-sensitivity-muted-symbolic";
        const v = a.volume;
        if (v <= 0.33) return "microphone-sensitivity-low-symbolic";
        if (v <= 0.66) return "microphone-sensitivity-medium-symbolic";
        return "microphone-sensitivity-high-symbolic";
    }

    function nodeName(node) {
        if (!node) return "Unknown";
        return node.description || node.nickname || node.name || "Unknown";
    }

    function isDefaultSink(node) {
        const def = volumeSection.defaultSink;
        return def !== null && node !== null && def.id === node.id;
    }

    function isDefaultSource(node) {
        const def = volumeSection.defaultSource;
        return def !== null && node !== null && def.id === node.id;
    }

    // ── Trigger ───────────────────────────────────────────────────────────────

    MouseArea {
        id: triggerArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: volumeSection.openPopupReq("volume")
        onExited: volumeSection.keepPopupReq()
        onClicked: {
            const a = volumeSection.audio;
            if (a)
                a.muted = !a.muted;
        }
        onWheel: wheel => {
            const a = volumeSection.audio;
            if (a)
                a.volume = Math.max(0, Math.min(1.0, a.volume + (wheel.angleDelta.y / 120) * 0.05));
            volumeSection.keepAliveReq();
        }
    }

    BarButton {
        id: triggerButton
        anchors.fill: parent
        hovered: triggerArea.containsMouse
        popupOpen: volumeSection.popupOpen

        IconImage {
            anchors.centerIn: parent
            implicitSize: Config.bar.batteryIconSize
            source: Quickshell.iconPath(volumeSection.volumeIcon())
            opacity: (volumeSection.audio && volumeSection.audio.muted) ? Config.bar.disabledOpacity : 1.0
            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
        }
    }

    // ── Popup ─────────────────────────────────────────────────────────────────

    // Measure node names so the popup is wide enough to show the longest one
    // without truncation. Recomputed whenever the node lists change.
    TextMetrics {
        id: nameTm
        font.family: Config.font.family
        font.pixelSize: Config.bar.fontSizeStatus
    }

    // icon(~fontSizeStatus) + iconSpacing(6) + label + dot(6+4) + muteBtn(22) + nameRowMargins(16)
    readonly property real _nameRowOverhead: Math.round(
        Config.bar.fontSizeStatus + 6 + 6 + 4 + 22 + 16, 0)
    // slider row: label width(38) + gap(6) + scrollbar(3+3) + viewportMargins(8+4) + outerMargins(8+8)
    readonly property real _sliderRowOverhead: Math.round(38 * Config.scale + 6 + 3 + 3 + 8 + 4 + 8 + 8, 0)
    readonly property real _popupOverhead: Math.max(_nameRowOverhead, _sliderRowOverhead)

    readonly property real _maxNodeNameWidth: {
        // depend on both lists
        void volumeSection.sinkNodes;
        void volumeSection.sourceNodes;
        const all = volumeSection.sinkNodes.concat(volumeSection.sourceNodes);
        let maxW = 0;
        for (let i = 0; i < all.length; i++) {
            nameTm.text = volumeSection.nodeName(all[i]);
            const w = nameTm.advanceWidth;
            if (w > maxW) maxW = w;
        }
        return maxW;
    }

    PopupContainer {
        id: volumePopup
        popupOpen: volumeSection.popupOpen

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        z: 20

        readonly property real _maxHeight: volumeSection.availableHeight
                                           - volumeSection.height
                                           - Config.bar.popupOffset
                                           - Math.round(16 * Config.scale)
        readonly property real _contentH: popupCol.implicitHeight + Math.round(16 * Config.scale)

        // Minimum 260px, grows to fit the longest device name
        width: Math.max(Math.round(260 * Config.scale),
                        volumeSection._maxNodeNameWidth + volumeSection._popupOverhead)
        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.InOutCubic } }
        height: Math.min(_contentH, _maxHeight)

        // ── Hover ─────────────────────────────────────────────────────────
        HoverHandler {
            onHoveredChanged: {
                if (hovered) volumeSection.openPopupReq("volume")
                else         volumeSection.exitPopupReq()
            }
        }

        // ── Scroll to pan if content taller than popup ─────────────────────
        property real scrollY: 0
        readonly property real maxScrollY: Math.max(0, popupCol.implicitHeight - viewport.height)
        onMaxScrollYChanged: {
            if (volumePopup.scrollY > volumePopup.maxScrollY)
                volumePopup.scrollY = volumePopup.maxScrollY;
        }

        WheelHandler {
            target: null
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                const step = Math.round(40 * Config.scale);
                volumePopup.scrollY = Math.max(0,
                    Math.min(volumePopup.maxScrollY,
                        volumePopup.scrollY - event.angleDelta.y / 120 * step));
            }
        }

        // ── Viewport ───────────────────────────────────────────────────────
        Item {
            id: viewport
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.right: scrollbarItem.left
            anchors.topMargin: Math.round(8 * Config.scale)
            anchors.bottomMargin: Math.round(8 * Config.scale)
            anchors.leftMargin: Math.round(8 * Config.scale)
            anchors.rightMargin: Math.round(4 * Config.scale)
            clip: true

            Column {
                id: popupCol
                width: viewport.width
                spacing: Math.round(2 * Config.scale)
                y: -volumePopup.scrollY

                // ── Output section header ──────────────────────────────────
                Text {
                    visible: volumeSection.sinkNodes.length > 0
                    text: "Output"
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Math.round(Config.bar.fontSizeStatus * 0.78)
                    width: parent.width
                    leftPadding: Math.round(4 * Config.scale)
                    topPadding: Math.round(4 * Config.scale)
                    bottomPadding: Math.round(2 * Config.scale)
                }

                // ── Sink rows ──────────────────────────────────────────────
                Repeater {
                    model: volumeSection.sinkNodes
                    delegate: AudioDeviceRow {
                        id: sinkRow
                        required property var modelData
                        width: parent.width
                        node: sinkRow.modelData
                        isDefault: volumeSection.isDefaultSink(sinkRow.modelData)
                        isSinkDevice: true
                        volumeSection: volumeSection
                    }
                }

                // ── Input section header ───────────────────────────────────
                Text {
                    visible: volumeSection.sourceNodes.length > 0
                    text: "Input"
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Math.round(Config.bar.fontSizeStatus * 0.78)
                    width: parent.width
                    leftPadding: Math.round(4 * Config.scale)
                    topPadding: volumeSection.sinkNodes.length > 0
                               ? Math.round(12 * Config.scale) : Math.round(4 * Config.scale)
                    bottomPadding: Math.round(2 * Config.scale)
                }

                // ── Source rows ────────────────────────────────────────────
                Repeater {
                    model: volumeSection.sourceNodes
                    delegate: AudioDeviceRow {
                        id: sourceRow
                        required property var modelData
                        width: parent.width
                        node: sourceRow.modelData
                        isDefault: volumeSection.isDefaultSource(sourceRow.modelData)
                        isSinkDevice: false
                        volumeSection: volumeSection
                    }
                }

                // ── Empty placeholder ──────────────────────────────────────
                Text {
                    visible: volumeSection.sinkNodes.length === 0
                             && volumeSection.sourceNodes.length === 0
                    text: "No audio devices"
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizeStatus
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                    topPadding: Math.round(8 * Config.scale)
                    bottomPadding: Math.round(8 * Config.scale)
                }
            }
        }

        // ── Scrollbar ──────────────────────────────────────────────────────
        Item {
            id: scrollbarItem
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: Math.round(8 * Config.scale)
            anchors.bottomMargin: Math.round(8 * Config.scale)
            anchors.rightMargin: Math.round(3 * Config.scale)
            width: Math.round(3 * Config.scale)

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Config.colors.border
                visible: volumePopup.maxScrollY > 0
            }

            Rectangle {
                readonly property real ratio: viewport.height / Math.max(popupCol.implicitHeight, 1)
                readonly property real thumbH: Math.max(Math.round(20 * Config.scale), scrollbarItem.height * ratio)
                readonly property real travel: scrollbarItem.height - thumbH
                readonly property real scrollRatio: volumePopup.maxScrollY > 0
                                                    ? volumePopup.scrollY / volumePopup.maxScrollY : 0

                width: parent.width
                height: thumbH
                y: travel * scrollRatio
                radius: width / 2
                color: Config.colors.textMuted
                visible: volumePopup.maxScrollY > 0
                Behavior on y { NumberAnimation { duration: 60 } }
            }
        }
    }

    // ── Audio device row (inline component) ───────────────────────────────────
    // Each row: device name + volume slider + mute button.
    // Clicking the row body on a non-default device sets it as preferred default.
    component AudioDeviceRow: Rectangle {
        id: deviceRow

        property var node: null
        property bool isDefault: false
        property bool isSinkDevice: true
        // Reference back so we can call openPopupReq
        property var volumeSection: null

        readonly property var nodeAudio: deviceRow.node?.audio ?? null

        implicitHeight: rowContent.implicitHeight + Math.round(12 * Config.scale)
        radius: Math.round(6 * Config.scale)

        // Default device gets accent tint; hover lightens it slightly
        color: {
            if (deviceRow.isDefault) {
                return rowMouse.containsMouse
                    ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.28)
                    : Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18);
            }
            return rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent";
        }
        Behavior on color { ColorAnimation { duration: 80 } }

        // ── Mouse: click body to set as preferred default ──────────────────
        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            // Don't propagate to parent wheel handler (popup scroll)
            onEntered: {
                if (deviceRow.volumeSection)
                    deviceRow.volumeSection.openPopupReq("volume");
            }
            onClicked: {
                if (!deviceRow.isDefault && deviceRow.node) {
                    if (deviceRow.isSinkDevice)
                        Pipewire.preferredDefaultAudioSink = deviceRow.node;
                    else
                        Pipewire.preferredDefaultAudioSource = deviceRow.node;
                }
            }
        }

        ColumnLayout {
            id: rowContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Math.round(8 * Config.scale)
            anchors.rightMargin: Math.round(8 * Config.scale)
            spacing: Math.round(4 * Config.scale)

            // ── Top row: icon + name + mute button ─────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * Config.scale)

                // Device type icon
                IconImage {
                    implicitSize: Math.round(Config.bar.fontSizeStatus * 0.9)
                    source: {
                        if (!deviceRow.node) return "";
                        if (deviceRow.isSinkDevice)
                            return Quickshell.iconPath(deviceRow.volumeSection.nodeVolumeIcon(deviceRow.node));
                        return Quickshell.iconPath(deviceRow.volumeSection.sourceIcon(deviceRow.node));
                    }
                    opacity: (deviceRow.nodeAudio && deviceRow.nodeAudio.muted)
                             ? Config.bar.disabledOpacity : 1.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                // Device name
                Text {
                    Layout.fillWidth: true
                    text: deviceRow.volumeSection.nodeName(deviceRow.node)
                    color: deviceRow.isDefault ? Config.colors.accent : Config.colors.textPrimary
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizeStatus
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                // Default indicator dot
                Rectangle {
                    visible: deviceRow.isDefault
                    width: Math.round(6 * Config.scale)
                    height: width
                    radius: width / 2
                    color: Config.colors.accent
                }

                // Mute toggle button
                Rectangle {
                    id: muteBtn
                    implicitWidth: Math.round(22 * Config.scale)
                    implicitHeight: Math.round(22 * Config.scale)
                    radius: Math.round(5 * Config.scale)
                    color: muteBtnMouse.containsMouse
                        ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.25)
                        : Qt.rgba(1, 1, 1, 0.06)
                    border.color: muteBtnMouse.containsMouse
                        ? Config.colors.accent : Config.colors.border
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 80 } }
                    Behavior on border.color { ColorAnimation { duration: 80 } }

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: Math.round(Config.bar.fontSizeStatus * 0.85)
                        source: {
                            if (!deviceRow.nodeAudio) return "";
                            if (deviceRow.nodeAudio.muted) {
                                return deviceRow.isSinkDevice
                                    ? Quickshell.iconPath("audio-volume-muted-symbolic")
                                    : Quickshell.iconPath("microphone-sensitivity-muted-symbolic");
                            }
                            if (deviceRow.isSinkDevice)
                                return Quickshell.iconPath(deviceRow.volumeSection.nodeVolumeIcon(deviceRow.node));
                            return Quickshell.iconPath(deviceRow.volumeSection.sourceIcon(deviceRow.node));
                        }
                        opacity: (deviceRow.nodeAudio && deviceRow.nodeAudio.muted)
                                 ? Config.bar.disabledOpacity : 1.0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: muteBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            if (deviceRow.volumeSection)
                                deviceRow.volumeSection.openPopupReq("volume");
                        }
                        onClicked: {
                            mouse.accepted = true;
                            if (deviceRow.nodeAudio)
                                deviceRow.nodeAudio.muted = !deviceRow.nodeAudio.muted;
                        }
                    }
                }
            }

            // ── Slider row ─────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: Math.round(18 * Config.scale)

                readonly property real frac: deviceRow.nodeAudio
                    ? Math.max(0, Math.min(1, deviceRow.nodeAudio.volume))
                    : 0

                // Label is fixed-width and right-anchored; track fills everything to its left
                readonly property real _labelW: Math.round(38 * Config.scale)
                readonly property real _gap: Math.round(6 * Config.scale)
                readonly property real _trackW: width - _labelW - _gap

                GradientProgressBar {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    width: parent._trackW
                    value: parent.frac
                    barHeight: Math.round(5 * Config.scale)
                }

                // Thumb glow — clamped so it never overlaps the label
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.min(parent._trackW, Math.max(0,
                           parent._trackW * parent.frac)) - width / 2
                    width: Math.round(14 * Config.scale)
                    height: width
                    radius: width / 2
                    color: Config.colors.glowAccent
                    opacity: 0.5
                    Behavior on x { NumberAnimation { duration: 60; easing.type: Easing.OutQuart } }
                }

                // Thumb
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.min(parent._trackW, Math.max(0,
                           parent._trackW * parent.frac)) - width / 2
                    width: Math.round(10 * Config.scale)
                    height: width
                    radius: width / 2
                    color: "#e0e0ff"
                    Behavior on x { NumberAnimation { duration: 60; easing.type: Easing.OutQuart } }
                }

                // Slider mouse area — only over the track, not the label
                MouseArea {
                    id: sliderMouse
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    width: parent._trackW
                    hoverEnabled: true
                    cursorShape: Qt.SizeHorCursor
                    onEntered: {
                        if (deviceRow.volumeSection)
                            deviceRow.volumeSection.openPopupReq("volume");
                    }
                    function setFromX(mx) {
                        if (!deviceRow.nodeAudio) return;
                        const v = Math.max(0, Math.min(1.0, mx / parent._trackW));
                        deviceRow.nodeAudio.volume = v;
                        if (deviceRow.volumeSection)
                            deviceRow.volumeSection.openPopupReq("volume");
                    }
                    onPressed: mouse => { mouse.accepted = true; setFromX(mouse.x); }
                    onPositionChanged: mouse => { if (pressed) setFromX(mouse.x); }
                    onWheel: wheel => {
                        if (!deviceRow.nodeAudio) return;
                        deviceRow.nodeAudio.volume = Math.max(0,
                            Math.min(1.0, deviceRow.nodeAudio.volume + (wheel.angleDelta.y / 120) * 0.05));
                        wheel.accepted = true;
                        if (deviceRow.volumeSection)
                            deviceRow.volumeSection.openPopupReq("volume");
                    }
                }

                // Volume percentage label — fixed width, right-anchored
                Text {
                    id: volLabel
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    text: deviceRow.nodeAudio ? Math.round(deviceRow.nodeAudio.volume * 100) + "%" : "0%"
                    color: deviceRow.isDefault ? Config.colors.accent : Config.colors.textSecondary
                    font.family: Config.font.family
                    font.pixelSize: Math.round(Config.bar.fontSizeStatus * 0.85)
                    horizontalAlignment: Text.AlignRight
                    width: parent._labelW
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
            }
        }
    }
}
