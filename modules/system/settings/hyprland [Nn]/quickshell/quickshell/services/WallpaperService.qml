pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import ".."

// Singleton wallpaper rotation service.
// Scans Config.wallpaper.directory for image files, maintains an ordered list,
// and advances the current index on a timer. WallpaperWindow instances observe
// currentWallpaper and animate a crossfade between the two Image layers.
QtObject {
    id: root

    // ── Public state ──────────────────────────────────────────────────────────

    // Full path to the currently displayed wallpaper
    property string currentWallpaper: ""
    // Full path to the next wallpaper (used during crossfade)
    property string nextWallpaper: ""
    // True while the fade-out/in transition is running
    property bool transitioning: false

    // Internal list of discovered wallpaper paths
    property var _files: []
    property int _currentIndex: -1

    // ── File discovery ────────────────────────────────────────────────────────

    property Process _discoverProc: Process {
        id: discoverProc

        property string _dir: Config.wallpaper.directory.replace(/^~/, Quickshell.env("HOME"))

        command: [
            "sh", "-c",
            "find '" + _dir + "' -maxdepth 1 -type f \\( " +
                Config.wallpaper.extensions.split(",").map(e => "-iname '*." + e.trim() + "'").join(" -o ") +
            " \\) | sort"
        ]

        running: Config.wallpaper.enabled

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n").filter(l => l.length > 0);
                if (lines.length === 0)
                    return;

                // Shuffle for a random starting order
                const shuffled = lines.slice().sort(() => Math.random() - 0.5);
                root._files = shuffled;

                // If we already had a wallpaper, try to preserve it in the list
                if (root.currentWallpaper) {
                    const idx = shuffled.indexOf(root.currentWallpaper);
                    root._currentIndex = idx >= 0 ? idx : 0;
                } else {
                    root._currentIndex = 0;
                    root.currentWallpaper = shuffled[0];
                }
            }
        }
    }

    // ── Rotation timer ────────────────────────────────────────────────────────

    property Timer _rotateTimer: Timer {
        interval: Config.wallpaper.rotateInterval
        repeat: true
        running: Config.wallpaper.enabled && root._files.length > 1
        onTriggered: root.advance()
    }

    // ── IPC ───────────────────────────────────────────────────────────────────

    property IpcHandler _ipc: IpcHandler {
        target: "wallpaper"

        function next() { root.advance(); }
        function prev() { root.previous(); }
    }

    // ── Public API ────────────────────────────────────────────────────────────

    function advance() {
        if (root._files.length === 0 || root.transitioning)
            return;
        const nextIndex = (root._currentIndex + 1) % root._files.length;
        root._currentIndex = nextIndex;
        root.nextWallpaper = root._files[nextIndex];
        root.transitioning = true;
    }

    function previous() {
        if (root._files.length === 0 || root.transitioning)
            return;
        const prevIndex = (root._currentIndex - 1 + root._files.length) % root._files.length;
        root._currentIndex = prevIndex;
        root.nextWallpaper = root._files[prevIndex];
        root.transitioning = true;
    }

    function setIndex(index) {
        if (index < 0 || index >= root._files.length || root.transitioning)
            return;
        root._currentIndex = index;
        root.nextWallpaper = root._files[index];
        root.transitioning = true;
    }

    // Called by WallpaperWindow once currentImg has finished loading the new image
    function completeTransition() {
        root.currentWallpaper = root.nextWallpaper;
        root.nextWallpaper = "";
        root.transitioning = false;
    }
}
