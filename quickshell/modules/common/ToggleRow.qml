import QtQuick
import QtQuick.Layouts
import "../../config"
import "../common"

Item {
    id: root
    implicitHeight: mainColumn.implicitHeight
    implicitWidth: mainColumn.implicitWidth

    property string icon: ""
    property string label: ""
    property bool checked: false
    property bool expanded: false
    property bool expandable: true
    property Component expandedContent: null
    property bool pulsing: false

    property bool active: false
    property int entranceDelay: 0
    property bool entered: false

    signal toggleRequested()
    signal expandRequested()

    Behavior on implicitHeight { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }

    onActiveChanged: {
        if (root.active) {
            root.entered = false
            entranceTimer.restart()
        } else {
            root.entered = false
        }
    }

    Timer {
        id: entranceTimer
        interval: root.entranceDelay
        onTriggered: root.entered = true
    }

    Column {
        id: mainColumn
        width: parent.width
        spacing: Appearance.spacingSmall

        RowLayout {
            id: headerRow
            width: parent.width
            spacing: Appearance.spacingSmall

            opacity: root.entered ? 1 : 0
            scale: root.entered ? 1 : 0.85
            transformOrigin: Item.Left
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
            Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }

            Item {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32

                Rectangle {
                    id: pulseRing
                    anchors.centerIn: parent
                    width: 32
                    height: 32
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: Colors.primary
                    scale: 1.0
                    opacity: 0.0

                    SequentialAnimation {
                        running: root.pulsing
                        loops: Animation.Infinite
                        ParallelAnimation {
                            NumberAnimation { target: pulseRing; property: "scale"; from: 1.0; to: 1.8; duration: 1100; easing.type: Easing.OutCubic }
                            NumberAnimation { target: pulseRing; property: "opacity"; from: 0.6; to: 0.0; duration: 1100; easing.type: Easing.OutCubic }
                        }
                        PropertyAction { target: pulseRing; property: "scale"; value: 1.0 }
                        PropertyAction { target: pulseRing; property: "opacity"; value: 0.0 }
                        PauseAnimation { duration: 400 }
                    }
                }

                Rectangle {
                    id: badgeBg
                    anchors.fill: parent
                    radius: width / 2
                    color: root.checked ? Colors.primary : Colors.surfaceContainerHigh
                    Behavior on color { ColorAnimation { duration: Appearance.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: root.icon
                        color: root.checked ? Colors.primaryText : Colors.textSecondary
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSizeNormal
                        Behavior on color { ColorAnimation { duration: Appearance.animFast } }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: labelText.implicitHeight

                Text {
                    id: labelText
                    anchors.fill: parent
                    text: root.label
                    color: Colors.textPrimary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeNormal
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.expandable
                    cursorShape: root.expandable ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.expandRequested()
                }
            }

            Toggle {
                checked: root.checked
                onToggled: root.toggleRequested()
            }
        }

        Loader {
            id: expandedLoader
            width: parent.width
            active: root.expandable && root.expanded
            sourceComponent: root.expandedContent
        }
    }
}
