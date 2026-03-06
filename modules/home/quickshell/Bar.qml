pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire

Scope {
    id: root

    property bool visible_: false

    // ── Shared popup manager ──────────────────────────────────────────────────
    // Only one popup open at a time. Sections call root.openPopup("name") on
    // hover-enter and root.keepPopup() on hover-exit. Timers only run while
    // the mouse is outside pill+popup; hovering either keeps everything alive.
    property string activePopup: ""   // "wifi"|"bt"|"volume"|"screen"|"kbd"|"battery"|"power"|"clock"|""

    readonly property bool anyPopupOpen: activePopup !== ""

    // True while the pointer is over the pill bar itself
    property bool pillHovered: false
    // True while the pointer is over the active popup rectangle
    property bool popupHovered: false

    // Tracks the currently visible tray popup Item for the input mask
    property Item activeTrayMenuPopup: null

    function registerTrayPopup(item)  { root.activeTrayMenuPopup = item; }
    function unregisterTrayPopup()    { root.activeTrayMenuPopup = null; }

    // Called by trigger hover-enter OR popup hover-enter
    function openPopup(name) {
        root.activePopup = name;
        root.popupHovered = true;
        popupCloseTimer.stop();
        root.keepAlive();
    }

    // Called by popup hover-exit (mouse leaving the popup rect)
    function exitPopup() {
        root.popupHovered = false;
        if (root.activePopup !== "") {
            popupCloseTimer.restart();
            root.keepAlive();
        }
    }

    // Called by trigger hover-exit (mouse leaving the trigger, not the popup)
    function keepPopup() {
        if (root.activePopup !== "") {
            if (!root.popupHovered) popupCloseTimer.restart();
            root.keepAlive();
        }
    }

    function closePopup() {
        root.activePopup = "";
        root.popupHovered = false;
        popupCloseTimer.stop();
        root.keepAlive();
    }

    Timer {
        id: popupCloseTimer
        interval: Config.bar.hideDelay
        onTriggered: if (!root.popupHovered) root.closePopup()
    }

    // ── Bar show/hide ─────────────────────────────────────────────────────────

    function show() {
        root.visible_ = true;
        hideTimer.restart();
    }

    function keepAlive() {
        hideTimer.restart();
    }

    IpcHandler {
        target: "bar"
        function toggle() {
            if (root.visible_) {
                root.visible_ = false;
                hideTimer.stop();
                root.closePopup();
            } else {
                root.show();
            }
        }
    }

    Timer {
        id: hideTimer
        interval: Config.bar.hideDelay
        onTriggered: if (root.activePopup === "") root.visible_ = false
    }

    // ── Clock ─────────────────────────────────────────────────────────────────

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ── Audio ─────────────────────────────────────────────────────────────────

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    // ── Shared slider label width (so all sliders keep the same label column) ─

    TextMetrics {
        id: statusTextMetrics
        font.family:    Config.font.family
        font.pixelSize: Config.bar.fontSizeStatus
        text: "100%"
    }

    readonly property int sliderLabelWidth: Math.round(statusTextMetrics.boundingRect.width + 4 * Config.scale)

    // ── Window ────────────────────────────────────────────────────────────────

    PanelWindow {
        id: win

        WlrLayershell.layer: WlrLayer.Top
        anchors.bottom: true
        exclusiveZone: 0
        color: "transparent"

        implicitWidth:  win.screen ? win.screen.width  : 1920
        implicitHeight: win.screen ? win.screen.height : 1080

        mask: Region {
            Region { item: pill }
            Region {
                item: root.activePopup === "wifi"    ? wifiSection.popup    : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "bt"      ? btSection.popup      : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "volume"  ? volumeSection.popup  : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "screen"  ? screenSection.popup  : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "kbd"     ? kbdSection.popup     : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "battery" ? batterySection.popup : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "power"   ? powerSection.popup   : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activePopup === "clock"   ? clockSection.popup   : null
                intersection: Intersection.Combine
            }
            Region {
                item: root.activeTrayMenuPopup
                intersection: Intersection.Combine
            }
        }

        Rectangle {
            id: pill

            implicitWidth:  content.implicitWidth + Config.bar.padding * 2
            implicitHeight: content.implicitHeight + Math.round(12 * Config.scale) * 2

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.visible_
                ? Math.round(8 * Config.scale)
                : -(pill.implicitHeight + Math.round(8 * Config.scale))

            Behavior on anchors.bottomMargin {
                NumberAnimation { duration: Config.bar.animateSpeed; easing.type: Easing.InOutQuad }
            }

            radius: Config.bar.radius
            color:  Config.colors.background
            border.color: Config.colors.border
            border.width: 1

            opacity: root.visible_ ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: Config.bar.animateSpeed; easing.type: Easing.InOutQuad }
            }

            HoverHandler {
                onHoveredChanged: {
                    root.pillHovered = hovered;
                    if (hovered) root.keepAlive();
                }
            }

            RowLayout {
                id: content
                anchors.centerIn: parent
                spacing: Config.bar.sectionSpacing

                // ── Tray ─────────────────────────────────────────────────────
                Repeater {
                    id: trayRepeater
                    model: SystemTray.items
                    delegate: BarTrayItem {
                        id: trayDelegate
                        required property SystemTrayItem modelData
                        required property int index
                        trayItem:    modelData
                        popupName:   "tray-" + trayDelegate.index
                        activePopup: root.activePopup
                        onHovered:       root.keepAlive()
                        onOpenPopupReq: name => {
                            root.openPopup(name);
                            root.registerTrayPopup(trayDelegate.menuPopup);
                        }
                        onKeepPopupReq: root.keepPopup()
                        onExitPopupReq: root.exitPopup()
                        onPopupOpenChanged: {
                            if (!trayDelegate.popupOpen)
                                root.unregisterTrayPopup();
                        }
                    }
                }

                Rectangle {
                    implicitWidth:  1
                    implicitHeight: Config.bar.batteryIconSize
                    color: Config.colors.border
                    visible: trayRepeater.count > 0
                }

                // ── Wifi ─────────────────────────────────────────────────────
                BarWifiSection {
                    id: wifiSection
                    activePopup: root.activePopup
                    onOpenPopupReq: name => root.openPopup(name)
                    onKeepPopupReq: root.keepPopup()
                    onExitPopupReq: root.exitPopup()
                    onKeepAliveReq: root.keepAlive()
                }

                // ── Bluetooth ─────────────────────────────────────────────────
                BarBtSection {
                    id: btSection
                    activePopup: root.activePopup
                    onOpenPopupReq: name => root.openPopup(name)
                    onKeepPopupReq: root.keepPopup()
                    onExitPopupReq: root.exitPopup()
                }

                // ── Volume ────────────────────────────────────────────────────
                BarVolumeSection {
                    id: volumeSection
                    activePopup:     root.activePopup
                    sliderLabelWidth: root.sliderLabelWidth
                    onOpenPopupReq: name => root.openPopup(name)
                    onKeepPopupReq: root.keepPopup()
                    onExitPopupReq: root.exitPopup()
                    onKeepAliveReq: root.keepAlive()
                }

                // ── Screen brightness ─────────────────────────────────────────
                BarScreenSection {
                    id: screenSection
                    activePopup:     root.activePopup
                    sliderLabelWidth: root.sliderLabelWidth
                    onOpenPopupReq: name => root.openPopup(name)
                    onKeepPopupReq: root.keepPopup()
                    onExitPopupReq: root.exitPopup()
                    onKeepAliveReq: root.keepAlive()
                }

                // ── Keyboard brightness ───────────────────────────────────────
                BarKbdSection {
                    id: kbdSection
                    activePopup:     root.activePopup
                    sliderLabelWidth: root.sliderLabelWidth
                    onOpenPopupReq: name => root.openPopup(name)
                    onKeepPopupReq: root.keepPopup()
                    onExitPopupReq: root.exitPopup()
                    onKeepAliveReq: root.keepAlive()
                }

                // ── Power profiles ────────────────────────────────────────────
                BarPowerSection {
                    id: powerSection
                    activePopup: root.activePopup
                    onOpenPopupReq: name => root.openPopup(name)
                    onKeepPopupReq: root.keepPopup()
                    onExitPopupReq: root.exitPopup()
                }

                // ── Battery ───────────────────────────────────────────────────
                BarBatterySection {
                    id: batterySection
                    activePopup: root.activePopup
                    onOpenPopupReq: name => root.openPopup(name)
                    onExitPopupReq: root.exitPopup()
                }

                Rectangle {
                    implicitWidth:  1
                    implicitHeight: Config.bar.batteryIconSize
                    color: Config.colors.border
                }

                // ── Clock / Date ──────────────────────────────────────────────
                BarClockSection {
                    id: clockSection
                    activePopup: root.activePopup
                    clockDate:   clock.date
                    onOpenPopupReq: name => root.openPopup(name)
                    onKeepPopupReq: root.keepPopup()
                    onExitPopupReq: root.exitPopup()
                }
            }
        }
    }
}
