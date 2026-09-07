import QtQuick
import QtQuick.Effects
import "../../config"

Item {
    id: root

    default property alias content: bg.data

    MultiEffect {
        anchors.fill: bg
        source: bg
        shadowEnabled: true
        shadowColor: Appearance.shadowColor
        shadowOpacity: 0.28
        shadowBlur: 0.4
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 5
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Appearance.radiusLarge
        color: Colors.surfaceContainer
        border.width: 1
        border.color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.22)
        clip: true
    }
}
