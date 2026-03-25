pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import "../services"

// Spawns one WallpaperWindow per screen using Quickshell's Variants.
// Each window sits on the background layer and crossfades between wallpapers
// whenever WallpaperService signals a transition.
Scope {
    id: root

    Variants {
        model: Quickshell.screens

        delegate: WallpaperWindow {
            required property var modelData
            screen: modelData
        }
    }
}
