pragma ComponentBehavior: Bound

import QtQuick
import ".."

// Scrollable list with a custom thin scrollbar.
// Place list content (e.g. a Column + Repeater) inside via the default property.
// The content is measured via implicitHeight for scroll math.
Item {
    id: root

    // Children are reparented into the content container inside the Flickable.
    default property alias content: contentContainer.data

    // How much padding inside the flickable (excluding the scrollbar)
    property int topPadding: Math.round(8 * Config.scale)
    property int bottomPadding: Math.round(8 * Config.scale)
    property int leftPadding: Math.round(8 * Config.scale)

    // Optional thumb color override (defaults to accent)
    property color thumbColor: Config.colors.accent

    Flickable {
        id: flickable
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.right: scrollBar.left
        anchors.topMargin: root.topPadding
        anchors.bottomMargin: root.bottomPadding
        anchors.leftMargin: root.leftPadding
        anchors.rightMargin: Math.round(4 * Config.scale)
        contentWidth: width
        contentHeight: contentContainer.implicitHeight
        clip: true

        Item {
            id: contentContainer
            width: flickable.width
            implicitHeight: childrenRect.height
        }
    }

    ThinScrollBar {
        id: scrollBar
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        scrollY:   flickable.contentY
        maxScrollY: Math.max(0, flickable.contentHeight - flickable.height)
        contentH:  flickable.contentHeight
        viewportH: flickable.height
        thumbColor: root.thumbColor
    }
}
