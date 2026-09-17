import QtQuick
import "../../config"

Item {
    id: root
    implicitWidth: 34
    implicitHeight: 34

    property real value: 0.5
    property color accentColor: Colors.primary
    property string icon: ""

    Canvas {
        id: canvas
        anchors.fill: parent
        property real animValue: root.value

        Behavior on animValue {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        onAnimValueChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            const cx = width / 2
            const cy = height / 2
            const r = Math.min(width, height) / 2 - 2.5

            ctx.lineWidth = 3
            ctx.lineCap = "round"
            ctx.strokeStyle = Colors.surfaceContainerHigh.toString()
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.stroke()

            if (canvas.animValue > 0.002) {
                ctx.strokeStyle = root.accentColor.toString()
                ctx.beginPath()
                ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + canvas.animValue * Math.PI * 2)
                ctx.stroke()
            }
        }

        Connections {
            target: Colors
            function onPrimaryChanged() { canvas.requestPaint() }
        }
    }

    onValueChanged: canvas.animValue = value

    Rectangle {
        anchors.centerIn: parent
        width: parent.width - 11
        height: width
        radius: width / 2
        color: Colors.surfaceContainer
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: Colors.textPrimary
        font.family: Appearance.fontFamilyIcons
        font.pixelSize: Appearance.fontSizeNormal
    }
}
