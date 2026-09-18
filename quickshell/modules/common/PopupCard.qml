import QtQuick
import QtQuick.Effects
import "../../config"

// A floating surface: rounded, lifted off the desktop by a soft shadow, and
// translucent so the compositor's blur behind the layer shows through. Rows
// and tiles placed inside one should stay well below full opacity themselves
// (Appearance.layerOpacity), or they mud the blur straight back out.
Item {
    id: root

    default property alias content: bg.data

    property color surfaceColor: Colors.surfaceContainer
    property real surfaceOpacity: Appearance.surfaceOpacity
    property alias radius: bg.radius

    // 1 is the standard lift. Raise it for a surface floating above another
    // one, drop it to 0 for a card that should sit flat with no shadow.
    property real elevation: 1.0

    MultiEffect {
        anchors.fill: bg
        source: bg
        shadowEnabled: root.elevation > 0
        shadowColor: Appearance.shadowColor
        shadowOpacity: Appearance.elevationOpacity * root.elevation
        shadowBlur: Appearance.elevationBlur
        shadowHorizontalOffset: 0
        shadowVerticalOffset: Math.round(Appearance.elevationOffset * root.elevation)
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Appearance.radiusLarge
        color: Colors.alpha(root.surfaceColor, root.surfaceOpacity)
        border.width: 1
        border.color: Colors.alpha(Colors.outline, 0.22)
        clip: true
    }
}
