pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
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
            if (n && n.audio !== null && !n.isSink && !n.isStream
                    && n.properties["device.class"] !== "monitor")
                result.push(n);
        }
        return result;
    }

    visible: volumeSection.defaultSink !== null

    // ── Suspend/resume state ───────────────────────────────────────────────────
    // PipeWire node state doesn't update live in node.properties, so we track
    // suspended nodes locally as a JS object keyed by node.name.
    property var suspendedNodes: ({})

    // Shared pactl process — commands are fire-and-forget, so one instance is fine.
    Process {
        id: pactlProc
    }

    function toggleSuspend(node, isSink) {
        if (!node) return;
        const name = node.name;
        const wasSuspended = !!volumeSection.suspendedNodes[name];
        const newState = !wasSuspended;
        // Update local tracking (must reassign for QML binding to fire)
        const copy = Object.assign({}, volumeSection.suspendedNodes);
        if (newState) copy[name] = true;
        else delete copy[name];
        volumeSection.suspendedNodes = copy;
        // Fire pactl
        const subcmd = isSink ? "suspend-sink" : "suspend-source";
        pactlProc.command = ["pactl", subcmd, name, newState ? "1" : "0"];
        pactlProc.running = true;
    }

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
            if (a) {
                const cur = a.volume;
                if (!isNaN(cur) && cur !== undefined)
                    a.volume = Math.max(0, Math.min(1.0, cur + (wheel.angleDelta.y / 120) * 0.05));
            }
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

    // Overhead = everything in a name row except the name text itself.
    // RowLayout margins: left(8) + right(8) = 16 scaled
    // RowLayout children (spacing=6 each gap, 3 gaps between 4 items):
    //   muteBtn(22) + spacing + [name] + spacing + suspendBtn(22)
    // = muteBtn + suspendBtn + 2*spacing + 2*margin
    readonly property real _nameRowOverhead: Math.round(
        Math.round(22 * Config.scale)                  // mute icon button
        + Math.round(6 * Config.scale)                 // muteBtn→name spacing
        + Math.round(6 * Config.scale)                 // name→suspendBtn spacing
        + Math.round(22 * Config.scale)                // suspend button
        + Math.round(8 * Config.scale)                 // left margin
        + Math.round(8 * Config.scale))                // right margin

    // Slider row overhead: label(38) + gap(6) + thumbR(7) + scrollbar track(3) + scrollbar rightMargin(3)
    //                    + viewport leftMargin(8) + viewport rightMargin(4) + card border(1+1)
    readonly property real _sliderRowOverhead: Math.round(
        Math.round(38 * Config.scale)                  // label column
        + Math.round(6 * Config.scale)                 // track→label gap
        + Math.round(7 * Config.scale)                 // half glow thumb (baked into _trackW)
        + Math.round(3 * Config.scale)                 // scrollbar width
        + Math.round(3 * Config.scale)                 // scrollbar rightMargin
        + Math.round(8 * Config.scale)                 // viewport leftMargin
        + Math.round(4 * Config.scale)                 // viewport rightMargin (to scrollbar)
        + 2)                                           // PopupCard border (1px each side)

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

        // Dim suspended devices so they're visually distinct,
        // but only the content — the suspend button stays at full opacity.
        readonly property bool isSuspended: deviceRow.volumeSection
            ? !!deviceRow.volumeSection.suspendedNodes[deviceRow.node ? deviceRow.node.name : ""]
            : false

        implicitHeight: rowContent.implicitHeight + Math.round(12 * Config.scale)
        radius: Math.round(6 * Config.scale)

        // Default device gets accent tint; hover lightens it slightly
        color: {
            if (deviceRow.isDefault) {
                return rowMouse.containsMouse
                    ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.28)
                    : Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18);
            }
            return (rowMouse.containsMouse && !deviceRow.isSuspended) ? Qt.rgba(1, 1, 1, 0.07) : "transparent";
        }
        Behavior on color { ColorAnimation { duration: 80 } }

        // ── Mouse: click body to set as preferred default ──────────────────
        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: (!deviceRow.isDefault && !deviceRow.isSuspended)
                         ? Qt.PointingHandCursor : Qt.ArrowCursor
            // Don't propagate to parent wheel handler (popup scroll)
            onEntered: {
                if (deviceRow.volumeSection)
                    deviceRow.volumeSection.openPopupReq("volume");
            }
            onClicked: {
                if (!deviceRow.isDefault && deviceRow.node && !deviceRow.isSuspended) {
                    if (deviceRow.isSinkDevice)
                        Pipewire.preferredDefaultAudioSink = deviceRow.node;
                    else
                        Pipewire.preferredDefaultAudioSource = deviceRow.node;
                }
            }
        }

        // Suspend button — always full opacity, anchored independently
        ColumnLayout {
            id: rowContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Math.round(8 * Config.scale)
            anchors.rightMargin: Math.round(8 * Config.scale)
            spacing: Math.round(4 * Config.scale)

            // ── Top row: mute-icon button + name + suspend button ───────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * Config.scale)

                // Icon doubles as mute toggle button
                Rectangle {
                    id: muteBtn
                    implicitWidth: Math.round(22 * Config.scale)
                    implicitHeight: Math.round(22 * Config.scale)
                    radius: Math.round(5 * Config.scale)
                    color: (muteBtnMouse.containsMouse && !deviceRow.isSuspended)
                        ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.25)
                        : (deviceRow.nodeAudio && deviceRow.nodeAudio.muted
                            ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.12)
                            : Qt.rgba(1, 1, 1, 0.06))
                    border.color: (muteBtnMouse.containsMouse && !deviceRow.isSuspended)
                        ? Config.colors.accent
                        : (deviceRow.nodeAudio && deviceRow.nodeAudio.muted
                            ? Config.colors.accent : Config.colors.border)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 80 } }
                    Behavior on border.color { ColorAnimation { duration: 80 } }

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: Math.round(Config.bar.fontSizeStatus * 0.85)
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

                    MouseArea {
                        id: muteBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: deviceRow.isSuspended ? Qt.ArrowCursor : Qt.PointingHandCursor
                        onEntered: {
                            if (deviceRow.volumeSection)
                                deviceRow.volumeSection.openPopupReq("volume");
                        }
                        onClicked: {
                            mouse.accepted = true;
                            if (!deviceRow.isSuspended && deviceRow.nodeAudio)
                                deviceRow.nodeAudio.muted = !deviceRow.nodeAudio.muted;
                        }
                    }
                }

                // Device name — dims when suspended
                Text {
                    Layout.fillWidth: true
                    text: deviceRow.volumeSection.nodeName(deviceRow.node)
                    color: deviceRow.isDefault ? Config.colors.accent : Config.colors.textPrimary
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizeStatus
                    elide: Text.ElideRight
                    opacity: deviceRow.isSuspended ? 0.45 : 1.0
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                // Suspend / resume toggle button — always full opacity
                Rectangle {
                    id: suspendBtn
                    readonly property bool isSuspended: deviceRow.volumeSection
                        ? !!deviceRow.volumeSection.suspendedNodes[deviceRow.node ? deviceRow.node.name : ""]
                        : false

                    implicitWidth: Math.round(22 * Config.scale)
                    implicitHeight: Math.round(22 * Config.scale)
                    radius: Math.round(5 * Config.scale)
                    color: suspendBtnMouse.containsMouse
                        ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.25)
                        : (suspendBtn.isSuspended ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.12)
                                                  : Qt.rgba(1, 1, 1, 0.06))
                    border.color: suspendBtnMouse.containsMouse
                        ? Config.colors.accent
                        : (suspendBtn.isSuspended ? Config.colors.accent : Config.colors.border)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 80 } }
                    Behavior on border.color { ColorAnimation { duration: 80 } }

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: Math.round(Config.bar.fontSizeStatus * 0.85)
                        source: suspendBtn.isSuspended
                            ? Quickshell.iconPath("media-playback-start-symbolic")
                            : Quickshell.iconPath("media-playback-pause-symbolic")
                    }

                    MouseArea {
                        id: suspendBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            if (deviceRow.volumeSection)
                                deviceRow.volumeSection.openPopupReq("volume");
                        }
                        onClicked: {
                            mouse.accepted = true;
                            if (deviceRow.volumeSection && deviceRow.node)
                                deviceRow.volumeSection.toggleSuspend(deviceRow.node, deviceRow.isSinkDevice);
                        }
                    }
                }
            }

            // ── Slider row — dims when suspended ───────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: Math.round(18 * Config.scale)
                opacity: deviceRow.isSuspended ? 0.45 : 1.0
                Behavior on opacity { NumberAnimation { duration: 150 } }

                readonly property real frac: {
                    if (!deviceRow.nodeAudio) return 0;
                    const v = deviceRow.nodeAudio.volume;
                    return (isNaN(v) || v === undefined) ? 0 : Math.max(0, Math.min(1, v));
                }

                // Label is fixed-width and right-anchored; track fills everything to its left.
                // Clamp to 1 so we never divide by zero or go negative during layout.
                // _thumbR: half the glow diameter — the track stops here so the thumb
                // never overlaps the label even at 100%.
                readonly property real _labelW: Math.round(38 * Config.scale)
                readonly property real _gap: Math.round(6 * Config.scale)
                readonly property real _thumbR: Math.round(7 * Config.scale)   // half of 14px glow
                readonly property real _trackW: Math.max(1, width - _labelW - _gap - _thumbR)

                GradientProgressBar {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    // Give the bar the same width as the usable track so fill matches thumb
                    width: parent._trackW
                    value: parent.frac
                    barHeight: Math.round(5 * Config.scale)
                }

                // Thumb glow
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent._trackW * parent.frac - width / 2
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
                    x: parent._trackW * parent.frac - width / 2
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
                    cursorShape: deviceRow.isSuspended ? Qt.ArrowCursor : Qt.SizeHorCursor
                    onEntered: {
                        if (deviceRow.volumeSection)
                            deviceRow.volumeSection.openPopupReq("volume");
                    }
                    function setFromX(mx) {
                        if (deviceRow.isSuspended || !deviceRow.nodeAudio) return;
                        const tw = parent._trackW;
                        if (tw <= 0) return;
                        const v = Math.max(0, Math.min(1.0, mx / tw));
                        if (isNaN(v)) return;
                        deviceRow.nodeAudio.volume = v;
                        if (deviceRow.volumeSection)
                            deviceRow.volumeSection.openPopupReq("volume");
                    }
                    onPressed: mouse => { mouse.accepted = true; setFromX(mouse.x); }
                    onPositionChanged: mouse => { if (pressed) setFromX(mouse.x); }
                    onWheel: wheel => {
                        if (deviceRow.isSuspended || !deviceRow.nodeAudio) return;
                        const cur = deviceRow.nodeAudio.volume;
                        if (isNaN(cur) || cur === undefined) return;
                        deviceRow.nodeAudio.volume = Math.max(0,
                            Math.min(1.0, cur + (wheel.angleDelta.y / 120) * 0.05));
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
                    text: {
                        if (!deviceRow.nodeAudio) return "0%";
                        const v = deviceRow.nodeAudio.volume;
                        return (isNaN(v) || v === undefined) ? "0%" : Math.round(v * 100) + "%";
                    }
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
