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
    signal rawAvailableClicked(var modelData)
    signal rawConnectedClicked(var modelData)
    signal hoverOpen
    signal hoverExit

    // ── Width — TextMetrics over all labels, one shot, no circular dep ────────

    readonly property real _iconSize: Config.bar.fontSizeStatus + Math.round(4 * Config.scale)
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
        NumberAnimation { duration: 150; easing.type: Easing.InOutCubic }
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
        font.pixelSize: Config.bar.fontSizeStatus
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered) root.hoverOpen()
            else root.hoverExit()
        }
    }

    // Scroll state
    property real scrollY: 0
    readonly property real maxScrollY: Math.max(0, col.implicitHeight - viewport.height)
    onMaxScrollYChanged: {
        if (root.scrollY > root.maxScrollY)
            root.scrollY = root.maxScrollY;
    }

    WheelHandler {
        target: null
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const step = Math.round(40 * Config.scale);
            root.scrollY = Math.max(0,
                Math.min(root.maxScrollY,
                    root.scrollY - event.angleDelta.y / 120 * step));
        }
    }

    // Viewport
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
            id: col
            width: viewport.width
            spacing: Math.round(2 * Config.scale)
            y: -root.scrollY

            // ── Empty placeholder ─────────────────────────────────────────
            Text {
                visible: root.availableItems.length === 0 && root.connectedItems.length === 0
                         && (root.rawModel === null)
                text: root.emptyText
                color: Config.colors.textMuted
                font.family: Config.font.family
                font.pixelSize: Config.bar.fontSizeStatus
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
                font.pixelSize: Math.round(Config.bar.fontSizeStatus * 0.78)
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

                    width: parent.width
                    height: availRowLayout.implicitHeight + Math.round(8 * Config.scale)
                    radius: Math.round(6 * Config.scale)
                    color: availMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
                    Behavior on color { ColorAnimation { duration: 80 } }

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
                            font.pixelSize: Config.bar.fontSizeStatus
                        }
                    }

                    Rectangle {
                        visible: !!availRow.modelData.saved
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: Math.round(8 * Config.scale)
                        width: Math.round(6 * Config.scale)
                        height: width
                        radius: width / 2
                        color: Config.colors.textMuted
                    }

                    MouseArea {
                        id: availMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.hoverOpen()
                        onClicked: root.availableClicked(availRow.index)
                    }
                }
            }

            // ── Separator — only when both JS lists non-empty ─────────────
            Rectangle {
                visible: root.rawModel === null
                         && root.availableItems.length > 0
                         && root.connectedItems.length > 0
                width: parent.width
                height: Math.round(1 * Config.scale)
                color: Config.colors.border
            }

            // ── Connected header ──────────────────────────────────────────
            Text {
                visible: root.rawModel === null && root.connectedItems.length > 0
                text: "Connected"
                color: Config.colors.textMuted
                font.family: Config.font.family
                font.pixelSize: Math.round(Config.bar.fontSizeStatus * 0.78)
                width: parent.width
                leftPadding: Math.round(4 * Config.scale)
                topPadding: Math.round(4 * Config.scale)
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
                           ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.28)
                           : Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18)
                    Behavior on color { ColorAnimation { duration: 80 } }

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
                            font.pixelSize: Config.bar.fontSizeStatus
                        }
                    }

                    Rectangle {
                        visible: !!connRow.modelData.saved
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: Math.round(8 * Config.scale)
                        width: Math.round(6 * Config.scale)
                        height: width
                        radius: width / 2
                        color: Config.colors.accent
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
                font.pixelSize: Math.round(Config.bar.fontSizeStatus * 0.78)
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

                    visible: !_isConn
                    width: parent.width
                    height: visible ? rawAvailLayout.implicitHeight + Math.round(8 * Config.scale) : 0
                    radius: Math.round(6 * Config.scale)
                    color: rawAvailMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
                    Behavior on color { ColorAnimation { duration: 80 } }

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
                            font.pixelSize: Config.bar.fontSizeStatus
                        }
                    }

                    Rectangle {
                        visible: root.rawSavedFn ? root.rawSavedFn(rawAvailRow.modelData) : false
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: Math.round(8 * Config.scale)
                        width: Math.round(6 * Config.scale)
                        height: width
                        radius: width / 2
                        color: Config.colors.textMuted
                    }

                    MouseArea {
                        id: rawAvailMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.hoverOpen()
                        onClicked: root.rawAvailableClicked(rawAvailRow.modelData)
                    }
                }
            }

            // ── Raw separator ─────────────────────────────────────────────
            // Shown when rawModel is active and there's at least one device
            // of each kind. Counts are derived from rawModel.values reactively.
            Rectangle {
                visible: root.rawModel !== null
                         && root._rawAvailableCount > 0
                         && root._rawConnectedCount > 0
                width: parent.width
                height: Math.round(1 * Config.scale)
                color: Config.colors.border
            }

            // ── Raw connected header ──────────────────────────────────────
            Text {
                visible: root.rawModel !== null && root._rawConnectedCount > 0
                text: "Connected"
                color: Config.colors.textMuted
                font.family: Config.font.family
                font.pixelSize: Math.round(Config.bar.fontSizeStatus * 0.78)
                width: parent.width
                leftPadding: Math.round(4 * Config.scale)
                topPadding: Math.round(4 * Config.scale)
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

                    visible: _isConn
                    width: parent.width
                    height: visible ? rawConnLayout.implicitHeight + Math.round(8 * Config.scale) : 0
                    radius: Math.round(6 * Config.scale)
                    color: rawConnMouse.containsMouse
                           ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.28)
                           : Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.18)
                    Behavior on color { ColorAnimation { duration: 80 } }

                    RowLayout {
                        id: rawConnLayout
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Math.round(8 * Config.scale)
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
                            font.pixelSize: Config.bar.fontSizeStatus
                        }
                    }

                    Rectangle {
                        visible: root.rawSavedFn ? root.rawSavedFn(rawConnRow.modelData) : false
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: Math.round(8 * Config.scale)
                        width: Math.round(6 * Config.scale)
                        height: width
                        radius: width / 2
                        color: Config.colors.accent
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
                font.pixelSize: Config.bar.fontSizeStatus
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
                topPadding: Math.round(8 * Config.scale)
                bottomPadding: Math.round(8 * Config.scale)
            }
        }
    }

    // Scrollbar — always reserves space so viewport width is stable
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
            visible: root.maxScrollY > 0
        }

        Rectangle {
            readonly property real ratio: viewport.height / Math.max(col.implicitHeight, 1)
            readonly property real thumbH: Math.max(Math.round(20 * Config.scale), scrollbarItem.height * ratio)
            readonly property real travel: scrollbarItem.height - thumbH
            readonly property real scrollRatio: root.maxScrollY > 0 ? root.scrollY / root.maxScrollY : 0

            width: parent.width
            height: thumbH
            y: travel * scrollRatio
            radius: width / 2
            color: Config.colors.textMuted
            visible: root.maxScrollY > 0
            Behavior on y { NumberAnimation { duration: 60 } }
        }
    }
}
