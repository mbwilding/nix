pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

// Keyboard backlight bar section: trigger icon + horizontal slider popup.
// Discovers the kbd_backlight led device, polls it every 200 ms, writes via brightnessctl.
//
// Bar.qml binds activePopup, sliderLabelWidth, and wires the popup-manager signals.
Item {
    id: kbdSection

    // ── Public API ────────────────────────────────────────────────────────────

    property string activePopup: ""     // bound to root.activePopup
    property int sliderLabelWidth: 0 // bound to root.sliderLabelWidth

    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq
    signal keepAliveReq

    // Expose the popup rectangle so Bar.qml can include it in the input mask
    property alias popup: kbdPopup

    // ── State ─────────────────────────────────────────────────────────────────

    property string device: ""
    property int _max: 1
    property int _raw: -1
    property real brightness: 0       // 0..1

    readonly property bool available: _max > 1

    // ── Geometry ──────────────────────────────────────────────────────────────

    implicitWidth: kbdRow.implicitWidth
    implicitHeight: kbdRow.implicitHeight
    visible: available

    // ── Processes ─────────────────────────────────────────────────────────────

    Process {
        command: ["sh", "-c", "ls /sys/class/leds/ | grep kbd_backlight | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const dev = this.text.trim();
                if (dev)
                    kbdSection.device = "/sys/class/leds/" + dev;
            }
        }
    }

    Process {
        command: ["cat", kbdSection.device + "/max_brightness"]
        running: kbdSection.device !== ""
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v > 0)
                    kbdSection._max = v;
            }
        }
    }

    Timer {
        interval: 200
        repeat: true
        running: kbdSection.device !== ""
        onTriggered: kbdPollProc.running = true
    }

    Process {
        id: kbdPollProc
        command: ["cat", kbdSection.device + "/brightness"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text);
                if (!isNaN(v) && v !== kbdSection._raw) {
                    kbdSection._raw = v;
                    kbdSection.brightness = kbdSection._max > 0 ? v / kbdSection._max : 0;
                }
            }
        }
    }

    Process {
        id: kbdWriteProc
    }

    function setBrightness(frac) {
        const raw = Math.round(frac * kbdSection._max);
        kbdWriteProc.command = ["brightnessctl", "--device=" + kbdSection.device.split("/").pop(), "set", String(raw)];
        kbdWriteProc.running = true;
    }

    // ── Trigger ───────────────────────────────────────────────────────────────

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: kbdSection.openPopupReq("kbd")
        onExited: kbdSection.keepPopupReq()
        onWheel: wheel => {
            kbdSection.setBrightness(Math.max(0, Math.min(1, kbdSection.brightness + (wheel.angleDelta.y / 120) * 0.05)));
            kbdSection.keepAliveReq();
        }
    }

    RowLayout {
        id: kbdRow
        spacing: Math.round(6 * Config.scale)

        IconImage {
            implicitSize: Config.bar.batteryIconSize
            source: Quickshell.iconPath("input-keyboard-brightness")
        }
    }

    // ── Popup ─────────────────────────────────────────────────────────────────

    BarSliderPopup {
        id: kbdPopup
        popupName: "kbd"
        iconName: "input-keyboard-brightness"
        fraction: kbdSection.brightness
        activePopup: kbdSection.activePopup
        labelWidth: kbdSection.sliderLabelWidth

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        onOpenPopupReq: name => kbdSection.openPopupReq(name)
        onExitPopupReq: kbdSection.exitPopupReq()

        onSetFraction: v => kbdSection.setBrightness(v)
        onScrollDelta: delta => kbdSection.setBrightness(Math.max(0, Math.min(1, kbdSection.brightness + delta * 0.05)))
    }
}
