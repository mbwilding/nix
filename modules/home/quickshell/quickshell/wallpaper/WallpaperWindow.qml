pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import ".."
import "../services"

// A layer-shell PanelWindow that fills one screen with the current wallpaper.
// Two Image items are stacked; the "next" layer fades in over the "current"
// layer for a smooth crossfade, matching Config.wallpaper.fadeDuration.
PanelWindow {
    id: win

    required property var screen

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true

    // Place behind all other surfaces; -1 means don't affect exclusive zones
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "quickshell-wallpaper"

    implicitWidth: win.screen ? win.screen.width : 1920
    implicitHeight: win.screen ? win.screen.height : 1080

    color: "black"

    // Pass all pointer input through to windows above
    mask: Region {}

    property string _current: WallpaperService.currentWallpaper
    property string _next: ""

    Connections {
        target: WallpaperService
        function onTransitioningChanged() {
            if (WallpaperService.transitioning) {
                win._next = WallpaperService.nextWallpaper;
                fadeIn.start();
            }
        }
    }

    // ── Current wallpaper layer ───────────────────────────────────────────────

    Image {
        id: currentImg
        anchors.fill: parent
        source: win._current ? ("file://" + win._current) : ""
        fillMode: win.fillModeEnum(Config.wallpaper.fillMode)
        asynchronous: true
        cache: false
        smooth: true

        onStatusChanged: {
            if (status === Image.Ready && win._next !== "") {
                win._next = "";
                WallpaperService.completeTransition();
                nextImg.opacity = 0.0;
            }
        }
    }

    // ── Next wallpaper layer ──────────────────────────────────────────────────

    Image {
        id: nextImg
        anchors.fill: parent
        source: win._next ? ("file://" + win._next) : ""
        fillMode: win.fillModeEnum(Config.wallpaper.fillMode)
        asynchronous: true
        cache: false
        smooth: true
        opacity: 0.0
    }

    NumberAnimation {
        id: fadeIn
        target: nextImg
        property: "opacity"
        from: 0.0
        to: 1.0
        duration: Config.wallpaper.fadeDuration
        easing.type: Easing.InOutQuad
        onFinished: {
            win._current = win._next;
            if (currentImg.status === Image.Ready) {
                win._next = "";
                WallpaperService.completeTransition();
                nextImg.opacity = 0.0;
            }
        }
    }

    // ── Helper: map string fill mode to Image.FillMode enum ──────────────────

    function fillModeEnum(name) {
        switch (name) {
            case "PreserveAspectFit":  return Image.PreserveAspectFit;
            case "Stretch":            return Image.Stretch;
            case "PreserveAspectCrop":
            default:                   return Image.PreserveAspectCrop;
        }
    }
}
