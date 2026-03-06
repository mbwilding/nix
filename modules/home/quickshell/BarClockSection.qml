pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

// Clock/date bar section: time + date labels + calendar popup.
//
// Bar.qml passes the SystemClock date and wires the popup-manager signals.
Item {
    id: clockSection

    // ── Public API ────────────────────────────────────────────────────────────

    property string activePopup: ""     // bound to root.activePopup
    property date clockDate           // bound to clock.date from Bar.qml

    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq

    // Expose the popup rectangle so Bar.qml can include it in the input mask
    property alias popup: calendarPopup

    // ── Geometry ──────────────────────────────────────────────────────────────

    implicitWidth: clockCol.implicitWidth
    implicitHeight: clockCol.implicitHeight

    readonly property bool popupOpen: activePopup === "clock"

    // ── Helpers ───────────────────────────────────────────────────────────────

    function timeText(d) {
        if (!d)
            return "--:--";
        if (Config.bar.clock24h)
            return Qt.formatTime(d, "HH:mm");
        return Qt.formatTime(d, "hh") + ":" + Qt.formatTime(d, "mm") + " " + Qt.formatTime(d, "AP");
    }

    function dateText(d) {
        if (!d)
            return "";
        return Qt.formatDate(d, "dddd, dd-MM-yy");
    }

    // ── Trigger ───────────────────────────────────────────────────────────────

    HoverHandler {
        onHoveredChanged: {
            if (hovered)
                clockSection.openPopupReq("clock");
            else
                clockSection.keepPopupReq();
        }
    }

    Column {
        id: clockCol
        spacing: Math.round(1 * Config.scale)

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: clockSection.timeText(clockSection.clockDate)
            color: Config.colors.textPrimary
            font.family: Config.font.family
            font.pixelSize: Config.bar.fontSizeClock
            font.weight: Font.Medium
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: clockSection.dateText(clockSection.clockDate)
            color: Config.colors.textSecondary
            font.family: Config.font.family
            font.pixelSize: Math.round(Config.bar.fontSizeStatus * 0.8)
        }
    }

    // ── Popup (calendar) ─────────────────────────────────────────────────────

    Rectangle {
        id: calendarPopup
        visible: opacity > 0
        opacity: clockSection.popupOpen ? 1 : 0
        scale: clockSection.popupOpen ? 1 : 0.92
        transformOrigin: Item.Bottom

        Behavior on opacity {
            NumberAnimation {
                duration: 120
                easing.type: Easing.InOutQuad
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.InOutQuad
            }
        }

        anchors.right: parent.right
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        width: 7 * calendarGrid.cellSize + Math.round(32 * Config.scale)
        height: calHeaderRow.height + calDayNames.height + calendarGrid.height + Math.round(48 * Config.scale)

        radius: Math.round(10 * Config.scale)
        color: Config.colors.background
        border.color: Config.colors.border
        border.width: 1
        z: 20

        property int displayYear: new Date().getFullYear()
        property int displayMonth: new Date().getMonth() + 1

        onVisibleChanged: {
            if (visible) {
                const now = new Date();
                displayYear = now.getFullYear();
                displayMonth = now.getMonth() + 1;
            }
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    clockSection.openPopupReq("clock");
                else
                    clockSection.exitPopupReq();
            }
        }

        // Header: ‹  Month Year  ›
        RowLayout {
            id: calHeaderRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Math.round(8 * Config.scale)
            anchors.leftMargin: Math.round(8 * Config.scale)
            anchors.rightMargin: Math.round(8 * Config.scale)
            spacing: 0

            Item {
                width: Math.round(32 * Config.scale)
                height: Math.round(32 * Config.scale)
                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: prevMonthMouse.containsMouse ? Config.colors.accent : Config.colors.textSecondary
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizeStatus * 1.2
                    Behavior on color {
                        ColorAnimation {
                            duration: 80
                        }
                    }
                }
                MouseArea {
                    id: prevMonthMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: clockSection.openPopupReq("clock")
                    onClicked: {
                        if (calendarPopup.displayMonth === 1) {
                            calendarPopup.displayMonth = 12;
                            calendarPopup.displayYear -= 1;
                        } else {
                            calendarPopup.displayMonth -= 1;
                        }
                        clockSection.openPopupReq("clock");
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDate(new Date(calendarPopup.displayYear, calendarPopup.displayMonth - 1, 1), "MMMM yyyy")
                color: Config.colors.textPrimary
                font.family: Config.font.family
                font.pixelSize: Config.bar.fontSizeStatus
                font.weight: Font.Medium
            }

            Item {
                width: Math.round(32 * Config.scale)
                height: Math.round(32 * Config.scale)
                Text {
                    anchors.centerIn: parent
                    text: "›"
                    color: nextMonthMouse.containsMouse ? Config.colors.accent : Config.colors.textSecondary
                    font.family: Config.font.family
                    font.pixelSize: Config.bar.fontSizeStatus * 1.2
                    Behavior on color {
                        ColorAnimation {
                            duration: 80
                        }
                    }
                }
                MouseArea {
                    id: nextMonthMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: clockSection.openPopupReq("clock")
                    onClicked: {
                        if (calendarPopup.displayMonth === 12) {
                            calendarPopup.displayMonth = 1;
                            calendarPopup.displayYear += 1;
                        } else {
                            calendarPopup.displayMonth += 1;
                        }
                        clockSection.openPopupReq("clock");
                    }
                }
            }
        }

        // Day-of-week header row
        Row {
            id: calDayNames
            anchors.top: calHeaderRow.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: Math.round(8 * Config.scale)

            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                delegate: Text {
                    required property string modelData
                    width: calendarGrid.cellSize
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Config.colors.textMuted
                    font.family: Config.font.family
                    font.pixelSize: Math.round(Config.bar.fontSizeStatus * 0.8)
                }
            }
        }

        // Calendar grid (6 rows × 7 columns)
        Grid {
            id: calendarGrid
            anchors.top: calDayNames.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: Math.round(4 * Config.scale)

            columns: 7
            property int cellSize: Math.round(36 * Config.scale)

            property var cells: {
                const y = calendarPopup.displayYear;
                const m = calendarPopup.displayMonth;
                const firstDay = new Date(y, m - 1, 1).getDay();
                const offset = (firstDay + 6) % 7;
                const daysInMonth = new Date(y, m, 0).getDate();
                const arr = [];
                for (let i = 0; i < offset; i++)
                    arr.push(0);
                for (let d = 1; d <= daysInMonth; d++)
                    arr.push(d);
                while (arr.length < 42)
                    arr.push(0);
                return arr;
            }

            width: 7 * cellSize
            height: 6 * cellSize

            Repeater {
                model: calendarGrid.cells
                delegate: Item {
                    required property int modelData
                    required property int index
                    width: calendarGrid.cellSize
                    height: calendarGrid.cellSize

                    readonly property bool isToday: {
                        const now = new Date();
                        return modelData > 0 && calendarPopup.displayYear === now.getFullYear() && calendarPopup.displayMonth === (now.getMonth() + 1) && modelData === now.getDate();
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: calendarGrid.cellSize - Math.round(4 * Config.scale)
                        height: width
                        radius: width / 2
                        color: parent.isToday ? Qt.rgba(Config.colors.accent.r, Config.colors.accent.g, Config.colors.accent.b, 0.3) : "transparent"
                        border.color: parent.isToday ? Config.colors.accent : "transparent"
                        border.width: 1
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData > 0 ? modelData : ""
                        color: parent.isToday ? Config.colors.accent : Config.colors.textSecondary
                        font.family: Config.font.family
                        font.pixelSize: Math.round(Config.bar.fontSizeStatus * 0.85)
                        font.weight: parent.isToday ? Font.Medium : Font.Normal
                    }
                }
            }
        }
    }
}
