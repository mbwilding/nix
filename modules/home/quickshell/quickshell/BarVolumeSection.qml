pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import "components"

// Volume bar section: trigger icon (mute toggle + scroll) + horizontal slider popup.
//
// Bar.qml binds activePopup, sliderLabelWidth, and wires the popup-manager signals.
Item {
    id: volumeSection

    // ── Public API ────────────────────────────────────────────────────────────

    property string activePopup: ""     // bound to root.activePopup
    property int sliderLabelWidth: 0 // bound to root.sliderLabelWidth

    signal openPopupReq(string name)
    signal keepPopupReq
    signal exitPopupReq
    signal keepAliveReq

    // Expose the popup rectangle so Bar.qml can include it in the input mask
    property alias popup: volumePopup

    // ── State ─────────────────────────────────────────────────────────────────

    readonly property bool popupOpen: activePopup === "volume"
    readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
    visible: Pipewire.defaultAudioSink !== null

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

    BarSliderPopup {
        id: volumePopup
        popupName: "volume"
        iconName: volumeSection.volumeIcon()
        fraction: Math.min(volumeSection.audio?.volume ?? 0, 1.0)
        activePopup: volumeSection.activePopup
        labelWidth: volumeSection.sliderLabelWidth

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: Config.bar.popupOffset

        onOpenPopupReq: name => volumeSection.openPopupReq(name)
        onExitPopupReq: volumeSection.exitPopupReq()

        onSetFraction: v => {
            const a = volumeSection.audio;
            if (a)
                a.volume = v;
        }
        onScrollDelta: delta => {
            const a = volumeSection.audio;
            if (a)
                a.volume = Math.max(0, Math.min(1.0, a.volume + delta * 0.05));
        }
    }
}
