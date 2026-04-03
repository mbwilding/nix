import QtQuick

import ".."

// Shared section header for popups — matches the "Available" / "Connected"
// style used in BarSectionPopup. Place inside a Column and set `text`.
Text {
    color: Config.colors.textMuted
    font.family: Config.font.family
    font.pixelSize: Math.round(Config.bar.fontSizePopup * 0.78)
    leftPadding: Math.round(4 * Config.scale)
    topPadding: Math.round(4 * Config.scale)
    bottomPadding: Math.round(2 * Config.scale)
}
