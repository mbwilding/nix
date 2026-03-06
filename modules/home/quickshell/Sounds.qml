pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property Process procVolume: Process {}
    function playVolume() {
        if (Config.soundEnabled) {
            procVolume.command = ["paplay", "@volumeSound@"];
            procVolume.running = true;
        }
    }
}
