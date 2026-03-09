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
    // overhead for item rows: viewportLeft(8) + rowLeftMargin(8) + iconSpacing(8) * 5 cols
    //   + viewportRight(4) + scrollbarWidth(3) + scrollbarRightMargin(3) + breathing(8) = 66
    readonly property real _rowOverhead: Math.round(66 * Config.scale)
    // overhead for the empty-text placeholder: viewportLeft(8) + viewportRight(4)
    //   + scrollbarWidth(3) + scrollbarRightMargin(3) + breathing(8) = 26
    readonly property real _emptyOverhead: Math.round(26 * Config.scale)
    // gap between metadata columns
    readonly property real _colGap: Math.round(8 * Config.scale)

    property real _maxLabelWidth: 0
    property real _maxSignalWidth: 0
    property real _maxBandWidth: 0
    property real _maxSecWidth: 0
    property real _emptyTextWidth: 0

    // Whether any item has wifi metadata columns (signal/band/gen/sec)
    readonly property bool _hasWifiMeta: {
        const lists = [root.availableItems, root.connectedItems];
        for (let l = 0; l < lists.length; l++) {
            if (lists[l].length > 0 && lists[l][0].band !== undefined) return true;
        }
        return false;
    }

    // Whether any available item is saved — controls whether the indicator column is rendered at all
    readonly property bool _hasSaved: {
        // JS-array mode (wifi)
        for (let i = 0; i < root.availableItems.length; i++) {
            if (root.availableItems[i].saved) return true;
        }
        // Raw-model mode (bluetooth)
        if (root.rawModel && root.rawSavedFn) {
            void root.rawModel.valuesChanged;
            const vals = root.rawModel.values;
            for (let j = 0; j < vals.length; j++) {
                if (!root.rawIsConnectedFn || !root.rawIsConnectedFn(vals[j])) {
                    if (root.rawSavedFn(vals[j])) return true;
                }
            }
        }
        return false;
    }

    function _recomputeMaxLabelWidth() {
        let maxLabel = 0, maxSig = 0, maxBand = 0, maxSec = 0;
        const lists = [root.availableItems, root.connectedItems];
        for (let l = 0; l < lists.length; l++) {
            const items = lists[l];
            for (let i = 0; i < items.length; i++) {
                const it = items[i];
                tm.text = it.label || "";
                const lw = tm.advanceWidth;
                if (lw > maxLabel) maxLabel = lw;

                if (it.band !== undefined) {
                    tm.text = (it.signal !== undefined) ? it.signal + "%" : "";
                    const sw = tm.advanceWidth;
                    if (sw > maxSig) maxSig = sw;

                    tm.text = it.band ? it.band + " GHz" : "";
                    const bw = tm.advanceWidth;
                    if (bw > maxBand) maxBand = bw;

                    tm.text = it.security || "";
                    const secw = tm.advanceWidth;
                    if (secw > maxSec) maxSec = secw;
                }
            }
        }
        root._maxLabelWidth  = maxLabel;
        root._maxSignalWidth = maxSig;
        root._maxBandWidth   = maxBand;
        root._maxSecWidth    = maxSec;
        tm.text = root.emptyText;
        root._emptyTextWidth = tm.advanceWidth;
    }

    onAvailableItemsChanged: root._recomputeMaxLabelWidth()
    onConnectedItemsChanged: root._recomputeMaxLabelWidth()
    onEmptyTextChanged: root._recomputeMaxLabelWidth()
    Component.onCompleted: root._recomputeMaxLabelWidth()

    readonly property real _metaCols: _hasWifiMeta
        ? _maxSignalWidth + _maxBandWidth + _maxSecWidth + _colGap * 3
        : 0

    width: Math.max(
        root._emptyTextWidth + root._emptyOverhead,
        root._maxLabelWidth + root._iconSize + root._metaCols + root._rowOverhead
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
                    readonly property bool _hasMeta: availRow.modelData.band !== undefined

                    width: parent.width
                    height: availRowLayout.implicitHeight + Math.round(8 * Config.scale)
                    radius: Math.round(6 * Config.scale)
                    color: availMouse.containsMouse ? Config.colors.rowHover : "transparent"
                    Behavior on color { ColorAnimation { duration: 60 } }

                    // Row mouse — declared first so RowLayout children sit on top and receive events first
                    MouseArea {
                        id: availMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.hoverOpen()
                        onClicked: root.availableClicked(availRow.index)
                    }

                    RowLayout {
                        id: availRowLayout
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Math.round(8 * Config.scale)
                        anchors.right: parent.right
                        anchors.rightMargin: Math.round(4 * Config.scale)
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
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        // Signal %
                        Text {
                            visible: availRow._hasMeta
                            text: availRow._hasMeta && availRow.modelData.signal !== undefined
                                  ? availRow.modelData.signal + "%" : ""
                            color: Config.colors.textMuted
                            font.family: Config.font.family
                            font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.82)
                            Layout.preferredWidth: root._maxSignalWidth
                            horizontalAlignment: Text.AlignRight
                        }
                        // Band (2.4 GHz / 5 GHz / 6 GHz)
                        Text {
                            visible: availRow._hasMeta
                            text: availRow._hasMeta && availRow.modelData.band
                                  ? availRow.modelData.band + " GHz" : ""
                            color: Config.colors.textMuted
                            font.family: Config.font.family
                            font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.82)
                            Layout.preferredWidth: root._maxBandWidth
                            horizontalAlignment: Text.AlignRight
                        }
                        // Security (WPA2/WPA3/Open…)
                        Text {
                            visible: availRow._hasMeta
                            text: availRow._hasMeta ? (availRow.modelData.security || "") : ""
                            color: Config.colors.textMuted
                            font.family: Config.font.family
                            font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.82)
                            Layout.preferredWidth: root._maxSecWidth
                            horizontalAlignment: Text.AlignRight
                        }

                        // Saved-network indicator — only rendered when at least one row is saved
                        Item {
                            visible: root._hasSaved
                            implicitWidth: savedIndicatorRef.implicitWidth
                            implicitHeight: savedIndicatorRef.implicitHeight
                            Layout.preferredWidth: implicitWidth

                            Text {
                                id: savedIndicatorRef
                                visible: false
                                text: "\u2022"
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizePopup
                            }

                            Text {
                                id: savedIndicatorText
                                anchors.centerIn: parent
                                visible: availRow._saved
                                text: savedIndicatorMouse.containsMouse ? "\u00d7" : "\u2022"
                                color: savedIndicatorMouse.containsMouse ? Config.colors.danger : Config.colors.textMuted
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizePopup
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }

                            MouseArea {
                                id: savedIndicatorMouse
                                anchors.fill: parent
                                enabled: availRow._saved
                                hoverEnabled: availRow._saved
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    mouse.accepted = true
                                    root.availableForgetClicked(availRow.index)
                                }
                            }
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

                    readonly property bool _hasMeta: connRow.modelData.band !== undefined

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
                        anchors.right: parent.right
                        anchors.rightMargin: Math.round(4 * Config.scale)
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
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        // Signal %
                        Text {
                            visible: connRow._hasMeta
                            text: connRow._hasMeta && connRow.modelData.signal !== undefined
                                  ? connRow.modelData.signal + "%" : ""
                            color: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.7)
                            font.family: Config.font.family
                            font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.82)
                            Layout.preferredWidth: root._maxSignalWidth
                            horizontalAlignment: Text.AlignRight
                        }
                        // Band
                        Text {
                            visible: connRow._hasMeta
                            text: connRow._hasMeta && connRow.modelData.band
                                  ? connRow.modelData.band + " GHz" : ""
                            color: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.7)
                            font.family: Config.font.family
                            font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.82)
                            Layout.preferredWidth: root._maxBandWidth
                            horizontalAlignment: Text.AlignRight
                        }
                        // Security
                        Text {
                            visible: connRow._hasMeta
                            text: connRow._hasMeta ? (connRow.modelData.security || "") : ""
                            color: Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.7)
                            font.family: Config.font.family
                            font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.82)
                            Layout.preferredWidth: root._maxSecWidth
                            horizontalAlignment: Text.AlignRight
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

                    visible: !_isConn
                    width: parent.width
                    height: visible ? rawAvailLayout.implicitHeight + Math.round(8 * Config.scale) : 0
                    radius: Math.round(6 * Config.scale)
                    color: rawAvailMouse.containsMouse ? Config.colors.rowHover : "transparent"
                    Behavior on color { ColorAnimation { duration: 60 } }

                    // Row mouse — declared first so RowLayout children sit on top and receive events first
                    MouseArea {
                        id: rawAvailMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.hoverOpen()
                        onClicked: root.rawAvailableClicked(rawAvailRow.modelData)
                    }

                    RowLayout {
                        id: rawAvailLayout
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Math.round(8 * Config.scale)
                        anchors.right: parent.right
                        anchors.rightMargin: Math.round(4 * Config.scale)
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
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        // Saved indicator — only rendered when at least one row is saved
                        Item {
                            visible: root._hasSaved
                            implicitWidth: rawSavedIndicatorRef.implicitWidth
                            implicitHeight: rawSavedIndicatorRef.implicitHeight
                            Layout.preferredWidth: implicitWidth

                            Text {
                                id: rawSavedIndicatorRef
                                visible: false
                                text: "\u2022"
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizePopup
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: rawAvailRow._saved
                                text: rawSavedIndicatorMouse.containsMouse ? "\u00d7" : "\u2022"
                                color: rawSavedIndicatorMouse.containsMouse ? Config.colors.danger : Config.colors.textMuted
                                font.family: Config.font.family
                                font.pixelSize: Config.bar.fontSizePopup
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }

                            MouseArea {
                                id: rawSavedIndicatorMouse
                                anchors.fill: parent
                                enabled: rawAvailRow._saved
                                hoverEnabled: rawAvailRow._saved
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    mouse.accepted = true
                                    root.rawAvailableForgetClicked(rawAvailRow.modelData)
                                }
                            }
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
