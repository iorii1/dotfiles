import QtQuick
import "../../config"

Item {
    id: root
    implicitHeight: 32

    property var options: []
    property string currentValue: ""
    signal selected(string value)

    readonly property int segCount: options.length
    readonly property real segWidth: segCount > 0 ? width / segCount : 0
    readonly property int currentIndex: {
        for (let i = 0; i < options.length; i++) {
            if (options[i].value === root.currentValue) return i
        }
        return 0
    }

    // One tab stop for the whole control, with Left/Right moving between the
    // segments inside it -- tabbing through every segment individually would
    // make a three-option control cost three tab presses to get past.
    activeFocusOnTab: root.segCount > 0

    function _step(delta) {
        if (root.segCount === 0) return
        const next = Math.max(0, Math.min(root.segCount - 1, root.currentIndex + delta))
        if (next !== root.currentIndex) root.selected(root.options[next].value)
    }

    Keys.onPressed: (event) => {
        switch (event.key) {
        case Qt.Key_Left:  root._step(-1); break
        case Qt.Key_Right: root._step(1); break
        case Qt.Key_Home:  if (root.segCount > 0) root.selected(root.options[0].value); break
        case Qt.Key_End:   if (root.segCount > 0) root.selected(root.options[root.segCount - 1].value); break
        default: return
        }
        event.accepted = true
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radiusNormal
        color: Colors.alpha(Colors.surfaceContainerHigh, Appearance.layerOpacity)
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radiusNormal
        color: "transparent"
        border.width: 2
        border.color: Colors.primary
        opacity: root.activeFocus ? 1 : 0
        visible: opacity > 0
        z: 1
        Behavior on opacity { Anim { duration: Appearance.animFast } }
    }

    Rectangle {
        id: highlight
        width: root.segWidth - 4
        height: parent.height - 4
        y: 2
        x: root.currentIndex * root.segWidth + 2
        radius: Appearance.radiusSmall
        color: Colors.primary

        Behavior on x { PopAnim { duration: Appearance.animSlow; easing.overshoot: Appearance.overshootPop } }
        Behavior on color { ColorAnimation { duration: Appearance.animFast } }

        Rectangle {
            id: flash
            anchors.fill: parent
            radius: parent.radius
            color: "#ffffff"
            opacity: 0

            PropertyAnimation {
                id: flashAnim
                target: flash
                property: "opacity"
                to: 0
                duration: Appearance.animSlow
                easing.type: Easing.Bezier
                easing.bezierCurve: Appearance.easeAccelerate
            }
        }
    }

    onSelected: {
        flash.opacity = 0.4
        flashAnim.restart()
    }

    Row {
        anchors.fill: parent

        Repeater {
            model: root.options

            Item {
                id: seg
                required property var modelData
                required property int index
                width: root.segWidth
                height: root.height

                readonly property bool isCurrent: seg.index === root.currentIndex

                scale: fx.pressed ? Appearance.pressScaleSubtle : 1.0
                Behavior on scale { Anim { duration: Appearance.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: seg.modelData.label
                    color: seg.isCurrent ? Colors.primaryText : Colors.textSecondary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                    font.bold: seg.isCurrent
                    Behavior on color { ColorAnimation { duration: Appearance.animFast } }
                }

                MouseArea {
                    id: fx
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selected(seg.modelData.value)
                }
            }
        }
    }
}
