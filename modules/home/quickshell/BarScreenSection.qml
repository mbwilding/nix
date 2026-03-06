pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

// Screen brightness bar section: trigger icon + horizontal slider popup.
// Discovers the backlight device, polls it every 200 ms, and writes via brightnessctl.
//
// Bar.qml binds activePopup, sliderLabelWidth, and wires the popup-manager signals.
Item {
    id: screenSection

    // ── Public API ────────────────────────────────────────────────────────────

    property string activePopup: ""     // bound to root.activePopup
    property int sliderLabelWidth: 0 // bound to root.sliderLabelWidth

    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq
    signal keepAliveReq

    // Expose the popup rectangle so Bar.qml can include it in the input mask
    property alias popup: screenPopup

    // ── State ─────────────────────────────────────────────────────────────────

    property string device: ""
    property int _max: 1
    property int _raw: -1
    property real brightness: 0       // 0..1

    readonly property bool available: _max > 1

    // ── Geometry ──────────────────────────────────────────────────────────────

    implicitWidth: screenRow.implicitWidth
    implicitHeight: screenRow.implicitHeight
    visible: available

    // ── Processes ─────────────────────────────────────────────────────────────

    Process {
        command: ["sh", "-c", "ls /sys/class/backlight/ | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const dev = this.text.trim();
                if (dev)
                    screenSection.device = "/sys/class/backlight/" + dev;
            }
        }
    }

    Process {
        command: ["cat", screenSection.device + "/max_brightness"]
        running: screenSection.device !== ""
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v > 0)
                    screenSection._max = v;
            }
        }
    }

    Timer {
        interval: 200
        repeat: true
        running: screenSection.device !== ""
        onTriggered: screenPollProc.running = true
    }

    Process {
        id: screenPollProc
        command: ["cat", screenSection.device + "/brightness"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v !== screenSection._raw) {
                    screenSection._raw = v;
                    screenSection.brightness = screenSection._max > 0 ? v / screenSection._max : 0;
                }
            }
        }
    }

    Process {
        id: screenWriteProc
    }

    function setBrightness(frac) {
        const raw = Math.round(frac * screenSection._max);
        screenWriteProc.command = ["brightnessctl", "--device=" + screenSection.device.split("/").pop(), "set", String(raw)];
        screenWriteProc.running = true;
    }

    // ── Trigger ───────────────────────────────────────────────────────────────

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: screenSection.openPopupReq("screen")
        onExited: screenSection.keepPopupReq()
        onWheel: wheel => {
            screenSection.setBrightness(Math.max(0, Math.min(1, screenSection.brightness + (wheel.angleDelta.y / 120) * 0.05)));
            screenSection.keepAliveReq();
        }
    }

    RowLayout {
        id: screenRow
        spacing: Math.round(6 * Config.scale)

        IconImage {
            implicitSize: Config.bar.batteryIconSize
            source: Quickshell.iconPath("video-display-brightness-symbolic")
        }
    }

    // ── Popup ─────────────────────────────────────────────────────────────────

    BarSliderPopup {
        id: screenPopup
        popupName: "screen"
        iconName: "video-display-brightness-symbolic"
        fraction: screenSection.brightness
        activePopup: screenSection.activePopup
        labelWidth: screenSection.sliderLabelWidth

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        onOpenPopupReq: name => screenSection.openPopupReq(name)
        onExitPopupReq: screenSection.exitPopupReq()

        onSetFraction: v => screenSection.setBrightness(v)
        onScrollDelta: delta => screenSection.setBrightness(Math.max(0, Math.min(1, screenSection.brightness + delta * 0.05)))
    }
}
