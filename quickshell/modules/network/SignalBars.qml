import QtQuick
import "../../config"

// Four rising bars, filled by signal strength. The strength was already known
// -- it sorted the list -- but was never shown, so every network looked equally
// good until you tried it.
Item {
    id: root

    property real strength: 0     // 0..1
    property bool active: false

    implicitWidth: 14
    implicitHeight: 12

    Row {
        anchors.centerIn: parent
        spacing: 1.5

        Repeater {
            model: 4

            Rectangle {
                required property int index
                width: 2
                height: 3 + index * 2.5
                anchors.bottom: parent.bottom
                radius: 1
                color: root.active ? Colors.primary : Colors.textSecondary
                // Each bar lights at the quarter it represents.
                opacity: root.strength >= (index + 1) / 4 ? 1 : 0.22
                Behavior on opacity { NumberAnimation { duration: Appearance.animFast } }
            }
        }
    }
}
