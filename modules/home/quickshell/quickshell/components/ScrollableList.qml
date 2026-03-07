pragma ComponentBehavior: Bound

import QtQuick
import ".."

// Scrollable list with a custom thin scrollbar.
// Place list content (e.g. a Column + Repeater) inside via the default property.
// The content is measured via contentHeight / contentWidth for scroll math.
Item {
    id: root

    // The inner content item — callers place a Column (or similar) here
    default property alias content: flickable.contentItem

    // How much padding inside the flickable (excluding the scrollbar)
    property int topPadding: Math.round(8 * Config.scale)
    property int bottomPadding: Math.round(8 * Config.scale)
    property int leftPadding: Math.round(8 * Config.scale)

    Flickable {
        id: flickable
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.right: scrollbar.left
        anchors.topMargin: root.topPadding
        anchors.bottomMargin: root.bottomPadding
        anchors.leftMargin: root.leftPadding
        anchors.rightMargin: Math.round(4 * Config.scale)
        contentWidth: width
        contentHeight: contentItem ? contentItem.implicitHeight : 0
        clip: true
    }

    // Thin scrollbar (only shown when content overflows)
    Item {
        id: scrollbar
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: Math.round(8 * Config.scale)
        anchors.bottomMargin: Math.round(8 * Config.scale)
        anchors.rightMargin: Math.round(3 * Config.scale)
        width: Math.round(3 * Config.scale)

        readonly property bool needed: flickable.contentHeight > flickable.height
        visible: needed

        // Rail
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Config.colors.border
        }

        // Thumb
        Rectangle {
            readonly property real ratio: flickable.height / Math.max(flickable.contentHeight, 1)
            readonly property real thumbH: Math.max(Math.round(20 * Config.scale), scrollbar.height * ratio)
            readonly property real travel: scrollbar.height - thumbH
            readonly property real scrollRatio: flickable.contentHeight > flickable.height ? flickable.contentY / (flickable.contentHeight - flickable.height) : 0
            width: parent.width
            height: thumbH
            y: travel * scrollRatio
            radius: width / 2
            color: Config.colors.textMuted
            Behavior on y {
                NumberAnimation {
                    duration: 60
                }
            }
        }
    }
}
