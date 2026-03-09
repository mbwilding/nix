pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io

import ".."

// Weather section for the top menu drawer.
// Fills whatever space its parent gives it.
ColumnLayout {
    id: root

    spacing: Math.round(4 * Config.scale)

    property string tempC: "--"
    property string feelsLike: "--"
    property string condition: ""
    property string location: ""
    property bool loading: true
    property bool error: false

    function weatherIcon(code) {
        const c = parseInt(code);
        if (c === 113) return "\u2600\ufe0f";
        if (c === 116) return "\u26c5";
        if (c === 119 || c === 122) return "\u2601\ufe0f";
        if (c >= 176 && c <= 186) return "\ud83c\udf27\ufe0f";
        if (c >= 200 && c <= 201) return "\u26a1";
        if (c >= 227 && c <= 230) return "\u2744\ufe0f";
        if (c >= 260 && c <= 266) return "\ud83c\udf2b\ufe0f";
        if (c >= 281 && c <= 284) return "\ud83c\udf27\ufe0f";
        if (c >= 293 && c <= 296) return "\ud83c\udf26\ufe0f";
        if (c >= 299 && c <= 314) return "\ud83c\udf27\ufe0f";
        if (c >= 317 && c <= 330) return "\ud83c\udf28\ufe0f";
        if (c >= 335 && c <= 350) return "\u2744\ufe0f";
        if (c >= 353 && c <= 359) return "\ud83c\udf26\ufe0f";
        if (c >= 362 && c <= 374) return "\ud83c\udf28\ufe0f";
        if (c >= 377 && c <= 395) return "\ud83c\udf27\ufe0f";
        return "\ud83c\udf21\ufe0f";
    }

    property Process _weatherProc: Process {
        command: ["sh", "-c", "curl -sf 'https://wttr.in/?format=j1'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                root.error = false;
                try {
                    const data = JSON.parse(this.text);
                    const cur  = data.current_condition[0];
                    root.tempC     = cur.temp_C;
                    root.feelsLike = cur.FeelsLikeC;
                    root.condition = root.weatherIcon(cur.weatherCode);
                    const area = data.nearest_area[0];
                    root.location  = area.areaName[0].value + ", " + area.country[0].value;
                } catch (e) {
                    root.error = true;
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.loading = false;
                root.error = true;
            }
        }
    }

    property Timer _weatherTimer: Timer {
        interval: 900000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root._weatherProc.running = true
    }

    // ── UI ───────────────────────────────────────────────────────────────────

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Math.round(8 * Config.scale)

        Text {
            text: root.condition
            font.pixelSize: Config.stats.fontSizeDate
            visible: root.condition !== "" && !root.loading && !root.error
        }

        Text {
            text: root.loading ? "..." : root.error ? "N/A" : root.tempC + "\u00b0C"
            color: Config.colors.textPrimary
            font.family: Config.font.family
            font.pixelSize: Config.stats.fontSizeDate
            font.weight: Font.Medium
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.loading || root.error ? "" : "Feels like " + root.feelsLike + "\u00b0C"
        color: Config.colors.textSecondary
        font.family: Config.font.family
        font.pixelSize: Config.font.sizeSm
        visible: !root.loading && !root.error
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.location
        color: Config.colors.textMuted
        font.family: Config.font.family
        font.pixelSize: Config.font.sizeSm
        elide: Text.ElideRight
        visible: !root.loading && !root.error && root.location !== ""
    }

    Item { Layout.fillHeight: true }
}
