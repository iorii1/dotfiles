import QtQuick
import QtQuick.Layouts
import "../../config"
import "../common"

// One measurement: an icon, what it is, what it reads, and a bar.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property string value: ""

    // 0..1, or negative for a reading with no meaningful ceiling (a transfer
    // rate), which shows the number without a bar.
    property real fraction: 0
    property bool showBar: root.fraction >= 0

    // Crossing this tints the bar and the value, for the readings where "high"
    // is a problem rather than just information.
    property real warnAbove: 1.1

    readonly property bool warning: root.showBar && root.fraction >= root.warnAbove
    readonly property color tint: root.warning ? Colors.error : Colors.primary

    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingSmall

            Text {
                Layout.preferredWidth: 16
                text: root.icon
                color: root.warning ? Colors.error : Colors.textSecondary
                font.family: Appearance.fontFamilyIcons
                font.pixelSize: Appearance.fontSizeSmall
                Behavior on color { ColorAnimation { duration: Appearance.animFast } }
            }

            Text {
                Layout.fillWidth: true
                text: root.label
                color: Colors.textSecondary
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSizeSmall
            }

            Text {
                text: root.value
                color: root.warning ? Colors.error : Colors.textPrimary
                font.family: Appearance.fontFamilyMono
                font.pixelSize: Appearance.fontSizeSmall
                Behavior on color { ColorAnimation { duration: Appearance.animFast } }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: root.showBar
            height: 4
            radius: 2
            color: Colors.alpha(Colors.surfaceContainerHigh, Appearance.layerOpacity)

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                radius: parent.radius
                width: parent.width * Math.max(0, Math.min(1, root.fraction))
                color: root.tint
                Behavior on width { Anim { duration: Appearance.animNormal } }
                Behavior on color { ColorAnimation { duration: Appearance.animFast } }
            }
        }
    }
}
