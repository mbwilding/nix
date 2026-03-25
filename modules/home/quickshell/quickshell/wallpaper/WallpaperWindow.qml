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

    // Both sources are tracked locally so we control exactly when they change.
    // _current: the image currentImg shows — only updated while nextImg is fully opaque.
    // _next:    the image nextImg shows — only cleared after nextImg is back at opacity 0.
    property string _current: WallpaperService.currentWallpaper
    property string _next: ""

    // When a transition starts, latch the incoming path into _next.
    Connections {
        target: WallpaperService
        function onTransitioningChanged() {
            if (WallpaperService.transitioning)
                win._next = WallpaperService.nextWallpaper;
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
    }

    // ── Next wallpaper layer (fades in, then back out, during transition) ─────

    Image {
        id: nextImg
        anchors.fill: parent
        source: win._next ? ("file://" + win._next) : ""
        fillMode: win.fillModeEnum(Config.wallpaper.fillMode)
        asynchronous: true
        cache: false
        smooth: true
        opacity: WallpaperService.transitioning ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: Config.wallpaper.fadeDuration
                easing.type: Easing.InOutQuad
                onFinished: {
                    if (nextImg.opacity === 1.0) {
                        // nextImg fully covers currentImg — swap the backing source
                        win._current = win._next;
                    } else {
                        // nextImg has faded back to 0 — safe to clear its source
                        win._next = "";
                    }
                }
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
