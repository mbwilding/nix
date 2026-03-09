pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import ".."

// Shared popup for bar sections (wifi, bluetooth).
//
// Two rendering modes:
//
// 1. JS-array mode (wifi): set availableItems / connectedItems as {label, icon} arrays.
//    Signals: availableClicked(int index), connectedClicked(int index)
//
// 2. Raw-model mode (bluetooth): set rawModel to the QML ObjectModel, plus
//    rawIsConnectedFn / rawLabelFn / rawIconFn as functions over modelData.
//    Signals: rawAvailableClicked(var modelData), rawConnectedClicked(var modelData)
//    Also set availableItems / connectedItems for width measurement.
PopupContainer {
    id: root

    property real availableHeight: 800
    property var availableItems: []
    property var connectedItems: []
    property string emptyText: ""

    // Raw-model mode
    property var rawModel: null
    property var rawIsConnectedFn: null
    property var rawSavedFn: null
    property var rawLabelFn: null
    property var rawIconFn: null
    // Optional: return battery 0.0-1.0 or -1 if unavailable, for connected rows
    property var rawBatteryFn: null

    // Internal counts for raw mode, derived from rawModel.values reactively.
    readonly property int _rawConnectedCount: {
        if (!root.rawModel || !root.rawIsConnectedFn) return 0;
        void root.rawModel.valuesChanged;
        const vals = root.rawModel.values;
        let n = 0;
        for (let i = 0; i < vals.length; i++) if (root.rawIsConnectedFn(vals[i])) n++;
        return n;
    }
    readonly property int _rawAvailableCount: {
        if (!root.rawModel || !root.rawIsConnectedFn) return 0;
        void root.rawModel.valuesChanged;
        const vals = root.rawModel.values;
        let n = 0;
        for (let i = 0; i < vals.length; i++) if (!root.rawIsConnectedFn(vals[i])) n++;
        return n;
    }

    signal availableClicked(int index)
    signal connectedClicked(int index)
    signal availableForgetClicked(int index)
    signal rawAvailableClicked(var modelData)
    signal rawConnectedClicked(var modelData)
    signal rawAvailableForgetClicked(var modelData)
    signal hoverOpen
    signal hoverExit

    // ── Width — TextMetrics over all labels, one shot, no circular dep ────────

    readonly property real _iconSize: Config.bar.fontSizePopup + Math.round(4 * Config.scale)
    // overhead for item rows: viewportLeft(8) + rowLeftMargin(8) + iconSpacing(8)
    //   + viewportRight(4) + scrollbarWidth(3) + scrollbarRightMargin(3) + breathing(8) = 42
    readonly property real _rowOverhead: Math.round(42 * Config.scale)
    // overhead for the empty-text placeholder: viewportLeft(8) + viewportRight(4)
    //   + scrollbarWidth(3) + scrollbarRightMargin(3) + breathing(8) = 26
    readonly property real _emptyOverhead: Math.round(26 * Config.scale)

    property real _maxLabelWidth: 0
    property real _emptyTextWidth: 0

    function _recomputeMaxLabelWidth() {
        let maxW = 0;
        const lists = [root.availableItems, root.connectedItems];
        for (let l = 0; l < lists.length; l++) {
            const items = lists[l];
            for (let i = 0; i < items.length; i++) {
                tm.text = items[i].label;
                const w = tm.advanceWidth;
                if (w > maxW) maxW = w;
            }
        }
        root._maxLabelWidth = maxW;
        tm.text = root.emptyText;
        root._emptyTextWidth = tm.advanceWidth;
    }

    onAvailableItemsChanged: root._recomputeMaxLabelWidth()
    onConnectedItemsChanged: root._recomputeMaxLabelWidth()
    onEmptyTextChanged: root._recomputeMaxLabelWidth()
    Component.onCompleted: root._recomputeMaxLabelWidth()

    width: Math.max(
        root._emptyTextWidth + root._emptyOverhead,
        root._maxLabelWidth + root._iconSize + root._rowOverhead
    )
    Behavior on width {
        NumberAnimation { duration: 100; easing.type: Easing.InOutQuart }
    }

    // ── Height ────────────────────────────────────────────────────────────────

    readonly property real _maxHeight: root.availableHeight - Math.round(16 * Config.scale)
    readonly property real _contentPadded: col.implicitHeight + Math.round(16 * Config.scale)
    height: Math.min(root._contentPadded, root._maxHeight)

    // ── Internals ─────────────────────────────────────────────────────────────

    z: 20

    TextMetrics {
        id: tm
        font.family: Config.font.family
        font.pixelSize: Config.bar.fontSizePopup
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered) root.hoverOpen()
            else root.hoverExit()
        }
    }

    // ── Scrollable content ────────────────────────────────────────────────────
    PopupScrollView {
        id: scrollView
        anchors.fill: parent
        contentColumn: col
        thumbColor: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.6)

        Column {
            id: col
            width: scrollView.contentWidth
            spacing: Math.round(2 * Config.scale)
            y: -scrollView.scrollY

            // ── Empty placeholder ─────────────────────────────────────────
            Text {
                visible: root.availableItems.length === 0 && root.connectedItems.length === 0
                         && (root.rawModel === null)
                text: root.emptyText
                color: Config.colors.textMuted
                font.family: Config.font.family
                font.pixelSize: Config.bar.fontSizePopup
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
                topPadding: Math.round(8 * Config.scale)
                bottomPadding: Math.round(8 * Config.scale)
            }

            // ══ JS-array mode (wifi) ══════════════════════════════════════

            // ── Available header ──────────────────────────────────────────
            Text {
                visible: root.rawModel === null && root.availableItems.length > 0
                text: "Available"
                color: Config.colors.textMuted
                font.family: Config.font.family
                font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.78)
                width: parent.width
                leftPadding: Math.round(4 * Config.scale)
                topPadding: Math.round(4 * Config.scale)
                bottomPadding: Math.round(2 * Config.scale)
            }

            // ── Available rows ────────────────────────────────────────────
            Repeater {
                model: root.rawModel === null ? root.availableItems : []
                delegate: Rectangle {
                    id: availRow
                    required property var modelData
                    required property int index

                    readonly property bool _saved: !!availRow.modelData.saved
                    readonly property real _btnWidth: availRow.height

                    width: parent.width
                    height: availRowLayout.implicitHeight + Math.round(8 * Config.scale)
                    radius: Math.round(6 * Config.scale)
                    color: availMouse.containsMouse ? Config.colors.rowHover : "transparent"
                    Behavior on color { ColorAnimation { duration: 60 } }

                    RowLayout {
                        id: availRowLayout
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Math.round(8 * Config.scale)
                        spacing: Math.round(8 * Config.scale)

                        IconImage {
                            implicitSize: root._iconSize
                            source: Quickshell.iconPath(availRow.modelData.icon)
                        }
                        Text {
                            text: availRow.modelData.label
                            color: Config.colors.textPrimary
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.fontSizePopup
                        }
                    }

                    // Row mouse — stops before the forget button when saved
                    MouseArea {
                        id: availMouse
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: availRow._saved ? forgetBtnArea.left : parent.right
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.hoverOpen()
                        onClicked: root.availableClicked(availRow.index)
                    }

                    // Forget button — only for saved networks
                    Rectangle {
                        id: forgetBtnArea
                        visible: availRow._saved
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        width: availRow._btnWidth
                        radius: Math.round(8 * Config.scale)
                        z: 1

                        color: forgetMouse.containsMouse
                            ? Qt.rgba(Config.colors.danger.r, Config.colors.danger.g, Config.colors.danger.b, 0.12)
                            : "transparent"
                        border.color: forgetMouse.containsMouse
                            ? Qt.rgba(Config.colors.danger.r, Config.colors.danger.g, Config.colors.danger.b, 0.70)
                            : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 80 } }
                        Behavior on border.color { ColorAnimation { duration: 80 } }

                        // Outer glow ring
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -3
                            radius: parent.radius + 3
                            color: "transparent"
                            border.color: Config.colors.danger
                            border.width: 2
                            opacity: forgetMouse.containsMouse ? 0.35 : 0
                            Behavior on opacity { NumberAnimation { duration: 80 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "\u00d7"
                            color: forgetMouse.containsMouse ? Config.colors.danger : Config.colors.textMuted
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.fontSizePopup
                            Behavior on color { ColorAnimation { duration: 80 } }
                        }

                        MouseArea {
                            id: forgetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.hoverOpen()
                            onClicked: root.availableForgetClicked(availRow.index)
                        }
                    }
                }
            }

            // ── Connected header ──────────────────────────────────────────
            Text {
                visible: root.rawModel === null && root.connectedItems.length > 0
                text: "Connected"
                color: Config.colors.textMuted
                font.family: Config.font.family
                font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.78)
                width: parent.width
                leftPadding: Math.round(4 * Config.scale)
                topPadding: root.availableItems.length > 0 ? Math.round(12 * Config.scale) : Math.round(4 * Config.scale)
                bottomPadding: Math.round(2 * Config.scale)
            }

            // ── Connected rows ────────────────────────────────────────────
            Repeater {
                model: root.rawModel === null ? root.connectedItems : []
                delegate: Rectangle {
                    id: connRow
                    required property var modelData
                    required property int index

                    width: parent.width
                    height: connRowLayout.implicitHeight + Math.round(8 * Config.scale)
                    radius: Math.round(6 * Config.scale)
                    color: connMouse.containsMouse
                           ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.22)
                           : Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.10)
                    border.color: connMouse.containsMouse
                           ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.70)
                           : Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.30)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 60 } }
                    Behavior on border.color { ColorAnimation { duration: 60 } }

                    RowLayout {
                        id: connRowLayout
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Math.round(8 * Config.scale)
                        spacing: Math.round(8 * Config.scale)

                        IconImage {
                            implicitSize: root._iconSize
                            source: Quickshell.iconPath(connRow.modelData.icon)
                        }
                        Text {
                            text: connRow.modelData.label
                            color: Config.colors.accent
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.fontSizePopup
                        }
                    }

                    MouseArea {
                        id: connMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.hoverOpen()
                        onClicked: root.connectedClicked(connRow.index)
                    }
                }
            }

            // ══ Raw-model mode (bluetooth) ════════════════════════════════
            // Uses the QML model directly in a Repeater so Qt handles
            // reactivity natively. visible: filtering separates connected
            // from available rows; a separator is shown between them.

            // ── Raw available header ──────────────────────────────────────
            Text {
                visible: root.rawModel !== null && root._rawAvailableCount > 0
                text: "Available"
                color: Config.colors.textMuted
                font.family: Config.font.family
                font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.78)
                width: parent.width
                leftPadding: Math.round(4 * Config.scale)
                topPadding: Math.round(4 * Config.scale)
                bottomPadding: Math.round(2 * Config.scale)
            }

            // ── Raw available rows ────────────────────────────────────────
            Repeater {
                model: root.rawModel
                delegate: Rectangle {
                    id: rawAvailRow
                    required property var modelData

                    readonly property bool _isConn: root.rawIsConnectedFn
                                                    ? root.rawIsConnectedFn(rawAvailRow.modelData)
                                                    : false
                    readonly property bool _saved: root.rawSavedFn
                                                    ? root.rawSavedFn(rawAvailRow.modelData)
                                                    : false
                    readonly property real _btnWidth: rawAvailRow.height

                    visible: !_isConn
                    width: parent.width
                    height: visible ? rawAvailLayout.implicitHeight + Math.round(8 * Config.scale) : 0
                    radius: Math.round(6 * Config.scale)
                    color: rawAvailMouse.containsMouse ? Config.colors.rowHover : "transparent"
                    Behavior on color { ColorAnimation { duration: 60 } }

                    RowLayout {
                        id: rawAvailLayout
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Math.round(8 * Config.scale)
                        spacing: Math.round(8 * Config.scale)

                        IconImage {
                            implicitSize: root._iconSize
                            source: Quickshell.iconPath(
                                root.rawIconFn ? root.rawIconFn(rawAvailRow.modelData) : "")
                        }
                        Text {
                            text: root.rawLabelFn ? root.rawLabelFn(rawAvailRow.modelData) : ""
                            color: Config.colors.textPrimary
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.fontSizePopup
                        }
                    }

                    // Row mouse — stops before the forget button when saved
                    MouseArea {
                        id: rawAvailMouse
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: rawAvailRow._saved ? rawForgetBtnArea.left : parent.right
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.hoverOpen()
                        onClicked: root.rawAvailableClicked(rawAvailRow.modelData)
                    }

                    // Forget button — only for saved networks
                    Rectangle {
                        id: rawForgetBtnArea
                        visible: rawAvailRow._saved
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        width: rawAvailRow._btnWidth
                        radius: Math.round(8 * Config.scale)
                        z: 1

                        color: rawForgetMouse.containsMouse
                            ? Qt.rgba(Config.colors.danger.r, Config.colors.danger.g, Config.colors.danger.b, 0.12)
                            : "transparent"
                        border.color: rawForgetMouse.containsMouse
                            ? Qt.rgba(Config.colors.danger.r, Config.colors.danger.g, Config.colors.danger.b, 0.70)
                            : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 80 } }
                        Behavior on border.color { ColorAnimation { duration: 80 } }

                        // Outer glow ring
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -3
                            radius: parent.radius + 3
                            color: "transparent"
                            border.color: Config.colors.danger
                            border.width: 2
                            opacity: rawForgetMouse.containsMouse ? 0.35 : 0
                            Behavior on opacity { NumberAnimation { duration: 80 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "\u00d7"
                            color: rawForgetMouse.containsMouse ? Config.colors.danger : Config.colors.textMuted
                            font.family: Config.font.family
                            font.pixelSize: Config.bar.fontSizePopup
                            Behavior on color { ColorAnimation { duration: 80 } }
                        }

                        MouseArea {
                            id: rawForgetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.hoverOpen()
                            onClicked: root.rawAvailableForgetClicked(rawAvailRow.modelData)
                        }
                    }
                }
            }

            // ── Raw connected header ──────────────────────────────────────
            Text {
                visible: root.rawModel !== null && root._rawConnectedCount > 0
                text: "Connected"
                color: Config.colors.textMuted
                font.family: Config.font.family
                font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.78)
                width: parent.width
                leftPadding: Math.round(4 * Config.scale)
                topPadding: root._rawAvailableCount > 0 ? Math.round(12 * Config.scale) : Math.round(4 * Config.scale)
                bottomPadding: Math.round(2 * Config.scale)
            }

            // ── Raw connected rows ────────────────────────────────────────
            Repeater {
                model: root.rawModel
                delegate: Rectangle {
                    id: rawConnRow
                    required property var modelData

                    readonly property bool _isConn: root.rawIsConnectedFn
                                                    ? root.rawIsConnectedFn(rawConnRow.modelData)
                                                    : false
                    readonly property real _battery: (root.rawBatteryFn && rawConnRow._isConn)
                                                     ? root.rawBatteryFn(rawConnRow.modelData)
                                                     : -1
                    readonly property bool _hasBattery: rawConnRow._battery >= 0

                    visible: _isConn
                    width: parent.width
                    height: visible ? rawConnInner.implicitHeight + Math.round(8 * Config.scale) : 0
                    radius: Math.round(6 * Config.scale)
                    color: rawConnMouse.containsMouse
                           ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.22)
                           : Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.10)
                    border.color: rawConnMouse.containsMouse
                           ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.70)
                           : Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.30)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 60 } }
                    Behavior on border.color { ColorAnimation { duration: 60 } }

                    Column {
                        id: rawConnInner
                        anchors.top: parent.top
                        anchors.topMargin: Math.round(4 * Config.scale)
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Math.round(8 * Config.scale)
                        anchors.rightMargin: Math.round(8 * Config.scale)
                        spacing: Math.round(3 * Config.scale)

                        RowLayout {
                            id: rawConnLayout
                            width: parent.width
                            spacing: Math.round(8 * Config.scale)

                            IconImage {
                                implicitSize: root._iconSize
                                source: Quickshell.iconPath(
                                    root.rawIconFn ? root.rawIconFn(rawConnRow.modelData) : "")
                            }
                            Text {
                                text: root.rawLabelFn ? root.rawLabelFn(rawConnRow.modelData) : ""
                                color: Config.colors.accent
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizePopup
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                visible: rawConnRow._hasBattery
                                text: rawConnRow._hasBattery ? Math.round(rawConnRow._battery * 100) + "%" : ""
                                color: {
                                    const pct = rawConnRow._battery * 100;
                                    if (pct <= 15) return Config.colors.danger;
                                    if (pct <= 30) return Config.colors.warning;
                                    return Config.colors.success;
                                }
                                font.family: Config.font.family
                                font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.85)
                                font.weight: Font.Medium
                            }
                        }

                        // Battery progress bar — only shown when battery data is available
                        Item {
                            visible: rawConnRow._hasBattery
                            width: parent.width
                            height: visible ? Math.round(4 * Config.scale) : 0

                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: Config.colors.sliderRail
                            }

                            Rectangle {
                                width: Math.max(height, parent.width * Math.max(0, Math.min(1, rawConnRow._battery)))
                                height: parent.height
                                radius: height / 2
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop {
                                        position: 0.0
                                        color: rawConnRow._battery <= 0.15 ? Config.colors.danger
                                             : rawConnRow._battery <= 0.30 ? Config.colors.warning
                                             : Config.colors.success
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: rawConnRow._battery <= 0.15 ? Qt.rgba(1, 0.41, 0.47, 0.7)
                                             : rawConnRow._battery <= 0.30 ? Qt.rgba(1, 0.69, 0.38, 0.7)
                                             : Config.colors.accent
                                    }
                                }
                                Behavior on width {
                                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: rawConnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.hoverOpen()
                        onClicked: root.rawConnectedClicked(rawConnRow.modelData)
                    }
                }
            }

            // ── Raw empty placeholder ─────────────────────────────────────
            Text {
                visible: root.rawModel !== null
                         && root._rawAvailableCount === 0
                         && root._rawConnectedCount === 0
                text: root.emptyText
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
