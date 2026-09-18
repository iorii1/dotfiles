import QtQuick
import QtQuick.Layouts
import "../../config"
import "../common"

Item {
    id: root
    implicitHeight: 48

    property string appName: ""
    property string appComment: ""
    property string appIcon: ""
    property bool active: false
    signal activated()

    scale: Appearance.popFromScale
    opacity: 0.0

    Component.onCompleted: entranceAnim.start()
    PopIn { id: entranceAnim; target: root; delay: Appearance.staggerDelay(index) }

    Rectangle {
        id: row
        anchors.fill: parent
        anchors.margins: 2
        radius: Appearance.radiusSmall
        clip: true
        color: root.active ? Colors.surfaceContainerHigh : (fx.containsMouse ? Colors.surfaceContainer : "transparent")
        Behavior on color { ColorAnimation { duration: Appearance.animFast } }

        scale: fx.gestureScale
        Behavior on scale { Anim { duration: Appearance.animFast } }

        Rectangle {
            anchors.fill: parent
            radius: row.radius
            color: "#ffffff"
            opacity: fx.flashOpacity
        }

        Rectangle {
            width: 3
            radius: 1.5
            color: Colors.primary
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.margins: 6
            scale: root.active ? 1 : 0
            transformOrigin: Item.Center
            Behavior on scale { PopAnim { duration: Appearance.animFast; easing.overshoot: Appearance.overshootPop } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.spacingNormal + 6
            anchors.rightMargin: Appearance.spacingNormal
            spacing: Appearance.spacingNormal

            Image {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                scale: root.active ? 1.12 : 1.0
                Behavior on scale { PopAnim { easing.overshoot: Appearance.overshootPop } }
                source: root.appIcon ? "image://icon/" + root.appIcon : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: root.appName
                    color: Colors.textPrimary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeNormal
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    visible: root.appComment !== ""
                    Layout.fillWidth: true
                    text: root.appComment
                    color: Colors.textSecondary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                    elide: Text.ElideRight
                }
            }
        }

        PressFx {
            id: fx
            hoverScale: 1.0
            pressScale: Appearance.pressScaleSubtle
            anchors.fill: parent
            onActivated: root.activated()
        }
    }
}
