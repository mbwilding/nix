pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property Process procVolume: Process {}
    function playVolume() {
        if (Config.soundEnabled) {
            procVolume.command = ["pw-play", "@volumeSound@"];
            procVolume.running = true;
        }
    }
}
