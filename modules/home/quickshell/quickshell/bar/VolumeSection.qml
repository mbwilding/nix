pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets

import ".."
import "../components"

BarSectionItem {
    id: volumeSection

    property alias popup: volumePopup
    property real availableHeight: 800
    property string activePopup: ""
    property var disabledNodes: ({})

    readonly property bool popupOpen: activePopup === "volume"
    readonly property var audio: volumeSection.defaultSink?.audio ?? null
    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var defaultSource: Pipewire.defaultAudioSource
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
            if (n && n.audio !== null && !n.isSink && !n.isStream && n.properties["device.class"] !== "monitor")
                result.push(n);
        }
        return result;
    }

    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq
    signal keepAliveReq

    implicitHeight: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    implicitWidth: Config.bar.batteryIconSize + Math.round(10 * Config.scale)
    popupItem: volumePopup
    visible: volumeSection.defaultSink !== null

    function isNodeDisabled(node) {
        if (!node)
            return false;
        return !!volumeSection.disabledNodes[node.id];
    }

    function setNodeDisabled(node, disabled) {
        if (!node)
            return;
        const map = Object.assign({}, volumeSection.disabledNodes);
        if (disabled) {
            map[node.id] = true;
            if (node.audio)
                node.audio.muted = true;
        } else {
            delete map[node.id];
            if (node.audio)
                node.audio.muted = false;
        }
        volumeSection.disabledNodes = map;
    }

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
        if (!node || !node.audio)
            return "audio-volume-muted-symbolic";
        const a = node.audio;
        if (a.muted)
            return "audio-volume-muted-symbolic";
        const v = a.volume;
        if (v <= 0.33)
            return "audio-volume-low-symbolic";
        if (v <= 0.66)
            return "audio-volume-medium-symbolic";
        return "audio-volume-high-symbolic";
    }

    function sourceIcon(node) {
        if (!node || !node.audio)
            return "microphone-sensitivity-muted-symbolic";
        const a = node.audio;
        if (a.muted)
            return "microphone-sensitivity-muted-symbolic";
        const v = a.volume;
        if (v <= 0.33)
            return "microphone-sensitivity-low-symbolic";
        if (v <= 0.66)
            return "microphone-sensitivity-medium-symbolic";
        return "microphone-sensitivity-high-symbolic";
    }

    function nodeName(node) {
        if (!node)
            return "Unknown";
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
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    TextMetrics {
        id: nameTm
        font.family: Config.font.family
        font.pixelSize: Config.bar.fontSizePopup
    }

    readonly property real _nameRowOverhead: Math.round(Math.round(22 * Config.scale) + Math.round(6 * Config.scale) + Math.round(8 * Config.scale) + Math.round(6 * Config.scale) + Math.round(22 * Config.scale) + Math.round(8 * Config.scale))

    readonly property real _sliderRowOverhead: Math.round(Math.round(38 * Config.scale) + Math.round(6 * Config.scale) + Math.round(9 * Config.scale) + Math.round(3 * Config.scale) + Math.round(3 * Config.scale) + Math.round(8 * Config.scale) + Math.round(4 * Config.scale) + 2)

    readonly property real _popupOverhead: Math.max(_nameRowOverhead, _sliderRowOverhead)

    readonly property real _maxNodeNameWidth: {
        void volumeSection.sinkNodes;
        void volumeSection.sourceNodes;
        const all = volumeSection.sinkNodes.concat(volumeSection.sourceNodes);
        let maxW = 0;
        for (let i = 0; i < all.length; i++) {
            nameTm.text = volumeSection.nodeName(all[i]);
            const w = nameTm.advanceWidth;
            if (w > maxW)
                maxW = w;
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

        readonly property real _maxHeight: volumeSection.availableHeight - volumeSection.height - Config.bar.popupOffset - Math.round(16 * Config.scale)
        readonly property real _contentH: popupCol.implicitHeight + Math.round(16 * Config.scale)

        width: Math.max(Math.round(260 * Config.scale), volumeSection._maxNodeNameWidth + volumeSection._popupOverhead)
        Behavior on width {
            NumberAnimation {
                duration: 150
                easing.type: Easing.InOutCubic
            }
        }

        height: Math.min(_contentH, _maxHeight)

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    volumeSection.openPopupReq("volume");
                else
                    volumeSection.exitPopupReq();
            }
        }

        PopupScrollView {
            id: scrollView
            anchors.fill: parent
            contentColumn: popupCol

            Column {
                id: popupCol
                width: scrollView.contentWidth
                spacing: Math.round(2 * Config.scale)
                y: -scrollView.scrollY

                Text {
                    visible: volumeSection.sinkNodes.length > 0
                    text: "Output"
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.78)
                    width: parent.width
                    leftPadding: Math.round(4 * Config.scale)
                    topPadding: Math.round(4 * Config.scale)
                    bottomPadding: Math.round(2 * Config.scale)
                }

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

                Text {
                    visible: volumeSection.sourceNodes.length > 0
                    text: "Input"
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.78)
                    width: parent.width
                    leftPadding: Math.round(4 * Config.scale)
                    topPadding: volumeSection.sinkNodes.length > 0 ? Math.round(12 * Config.scale) : Math.round(4 * Config.scale)
                    bottomPadding: Math.round(2 * Config.scale)
                }

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

                Text {
                    visible: volumeSection.sinkNodes.length === 0 && volumeSection.sourceNodes.length === 0
                    text: "No audio devices"
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizePopup
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                    topPadding: Math.round(8 * Config.scale)
                    bottomPadding: Math.round(8 * Config.scale)
                }
            }
        }
    }

    component AudioDeviceRow: Rectangle {
        id: deviceRow

        property var node: null
        property bool isDefault: false
        property bool isSinkDevice: true
        property var volumeSection: null

        readonly property var nodeAudio: deviceRow.node?.audio ?? null
        readonly property bool disabled: deviceRow.volumeSection ? deviceRow.volumeSection.isNodeDisabled(deviceRow.node) : false

        implicitHeight: rowContent.implicitHeight + Math.round(12 * Config.scale)
        radius: Math.round(6 * Config.scale)
        color: {
            if (deviceRow.isDefault) {
                return rowMouse.containsMouse ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.28) : Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18);
            }
            return rowMouse.containsMouse ? Config.colors.surfaceAlt : "transparent";
        }

        Behavior on color {
            ColorAnimation {
                duration: 80
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: !deviceRow.isDefault && !deviceRow.disabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onEntered: {
                if (deviceRow.volumeSection)
                    deviceRow.volumeSection.openPopupReq("volume");
            }
            onClicked: {
                if (!deviceRow.isDefault && !deviceRow.disabled && deviceRow.node) {
                    if (deviceRow.isSinkDevice)
                        Pipewire.preferredDefaultAudioSink = deviceRow.node;
                    else
                        Pipewire.preferredDefaultAudioSource = deviceRow.node;
                }
            }
        }

        Rectangle {
            id: disableBtn
            anchors.right: parent.right
            anchors.rightMargin: Math.round(8 * Config.scale)
            anchors.top: parent.top
            anchors.topMargin: Math.round(6 * Config.scale)
            implicitWidth: Math.round(22 * Config.scale)
            implicitHeight: Math.round(22 * Config.scale)
            radius: Math.round(5 * Config.scale)
            color: disableBtnMouse.containsMouse ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.25) : (deviceRow.disabled ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.12) : Config.colors.surfaceAlt)
            border.color: disableBtnMouse.containsMouse ? Config.colors.accent : (deviceRow.disabled ? Config.colors.accent : Config.colors.border)
            border.width: 1
            z: 2
            Behavior on color {
                ColorAnimation {
                    duration: 80
                }
            }
            Behavior on border.color {
                ColorAnimation {
                    duration: 80
                }
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: Math.round(Config.bar.fontSizePopup * 0.85)
                source: Quickshell.iconPath("system-shutdown-symbolic")
                opacity: deviceRow.disabled ? Config.bar.disabledOpacity : 1.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }
            }

            MouseArea {
                id: disableBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                    if (deviceRow.volumeSection)
                        deviceRow.volumeSection.openPopupReq("volume");
                }
                onClicked: {
                    mouse.accepted = true;
                    if (deviceRow.volumeSection)
                        deviceRow.volumeSection.setNodeDisabled(deviceRow.node, !deviceRow.disabled);
                }
            }
        }

        ColumnLayout {
            id: rowContent
            anchors.left: parent.left
            anchors.right: disableBtn.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Math.round(8 * Config.scale)
            anchors.rightMargin: Math.round(6 * Config.scale)
            spacing: Math.round(4 * Config.scale)

            opacity: deviceRow.disabled ? Config.bar.disabledOpacity : 1.0
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.InOutQuad
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * Config.scale)

                Rectangle {
                    id: muteBtn
                    implicitWidth: Math.round(22 * Config.scale)
                    implicitHeight: Math.round(22 * Config.scale)
                    radius: Math.round(5 * Config.scale)
                    color: muteBtnMouse.containsMouse && !deviceRow.disabled ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.25) : (deviceRow.nodeAudio && deviceRow.nodeAudio.muted ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.12) : Config.colors.surfaceAlt)
                    border.color: muteBtnMouse.containsMouse && !deviceRow.disabled ? Config.colors.accent : (deviceRow.nodeAudio && deviceRow.nodeAudio.muted ? Config.colors.accent : Config.colors.border)
                    border.width: 1

                    Behavior on color {
                        ColorAnimation {
                            duration: 80
                        }
                    }
                    Behavior on border.color {
                        ColorAnimation {
                            duration: 80
                        }
                    }

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: Math.round(Config.bar.fontSizePopup * 0.85)
                        source: {
                            if (!deviceRow.node)
                                return "";
                            if (deviceRow.isSinkDevice)
                                return Quickshell.iconPath(deviceRow.volumeSection.nodeVolumeIcon(deviceRow.node));
                            return Quickshell.iconPath(deviceRow.volumeSection.sourceIcon(deviceRow.node));
                        }
                        opacity: (deviceRow.nodeAudio && deviceRow.nodeAudio.muted) ? Config.bar.disabledOpacity : 1.0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }
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
                            if (deviceRow.disabled)
                                return;
                            if (deviceRow.nodeAudio)
                                deviceRow.nodeAudio.muted = !deviceRow.nodeAudio.muted;
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: deviceRow.volumeSection.nodeName(deviceRow.node)
                    color: deviceRow.isDefault ? Config.colors.accent : Config.colors.textPrimary
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizePopup
                    elide: Text.ElideRight
                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: Math.round(18 * Config.scale)

                readonly property real frac: {
                    if (!deviceRow.nodeAudio)
                        return 0;
                    const v = deviceRow.nodeAudio.volume;
                    return (isNaN(v) || v === undefined) ? 0 : Math.max(0, Math.min(1, v));
                }

                readonly property real _labelW: Math.round(38 * Config.scale)
                readonly property real _gap: Math.round(6 * Config.scale)
                readonly property real _thumbR: Math.round(9 * Config.scale)
                readonly property real _trackW: Math.max(1, width - _labelW - _gap - _thumbR)

                GradientProgressBar {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    width: parent._trackW
                    value: parent.frac
                    barHeight: Math.round(6 * Config.scale)
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent._trackW * parent.frac - width / 2
                    width: Math.round(18 * Config.scale)
                    height: width
                    radius: width / 2
                    color: Config.colors.glowAccent
                    opacity: 0.55
                    Behavior on x {
                        NumberAnimation {
                            duration: 60
                            easing.type: Easing.OutQuart
                        }
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent._trackW * parent.frac - width / 2
                    width: Math.round(14 * Config.scale)
                    height: width
                    radius: width / 2
                    color: Config.colors.sliderThumb
                    Behavior on x {
                        NumberAnimation {
                            duration: 60
                            easing.type: Easing.OutQuart
                        }
                    }
                }

                MouseArea {
                    id: sliderMouse
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    width: parent._trackW
                    hoverEnabled: true
                    cursorShape: deviceRow.disabled ? Qt.ArrowCursor : Qt.SizeHorCursor
                    onEntered: {
                        if (deviceRow.volumeSection)
                            deviceRow.volumeSection.openPopupReq("volume");
                    }
                    function setFromX(mx) {
                        if (deviceRow.disabled || !deviceRow.nodeAudio)
                            return;
                        const tw = parent._trackW;
                        if (tw <= 0)
                            return;
                        const v = Math.max(0, Math.min(1.0, mx / tw));
                        if (isNaN(v))
                            return;
                        deviceRow.nodeAudio.volume = v;
                        if (deviceRow.volumeSection)
                            deviceRow.volumeSection.openPopupReq("volume");
                    }
                    onPressed: mouse => {
                        mouse.accepted = true;
                        setFromX(mouse.x);
                    }
                    onPositionChanged: mouse => {
                        if (pressed)
                            setFromX(mouse.x);
                    }
                    onWheel: wheel => {
                        if (deviceRow.disabled || !deviceRow.nodeAudio)
                            return;
                        const cur = deviceRow.nodeAudio.volume;
                        if (isNaN(cur) || cur === undefined)
                            return;
                        deviceRow.nodeAudio.volume = Math.max(0, Math.min(1.0, cur + (wheel.angleDelta.y / 120) * 0.05));
                        wheel.accepted = true;
                        if (deviceRow.volumeSection)
                            deviceRow.volumeSection.openPopupReq("volume");
                    }
                }

                Text {
                    id: volLabel
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    text: {
                        if (!deviceRow.nodeAudio)
                            return "0%";
                        const v = deviceRow.nodeAudio.volume;
                        return (isNaN(v) || v === undefined) ? "0%" : Math.round(v * 100) + "%";
                    }
                    color: deviceRow.isDefault ? Config.colors.accent : Config.colors.textSecondary
                    font.family: Config.font.family
                    font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.85)
                    horizontalAlignment: Text.AlignRight
                    width: parent._labelW
                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                }
            }
        }
    }
}
