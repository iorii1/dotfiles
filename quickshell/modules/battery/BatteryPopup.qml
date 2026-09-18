import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../common"

PanelWindow {
    id: battWindow

    visible: UiState.batteryOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }

    IpcHandler {
        target: "battery"
        function toggle(): void { UiState.batteryOpen = !UiState.batteryOpen }
        function open(): void { UiState.batteryOpen = true }
        function close(): void { UiState.batteryOpen = false }
    }


    MouseArea {
        anchors.fill: parent
        onClicked: UiState.batteryOpen = false
    }

    PopupCard {
        id: card
        anchors.right: parent.right
        anchors.rightMargin: Appearance.spacingLarge
        readonly property int restY: BarConfig.barHeight + BarConfig.barMargin + Appearance.spacingSmall
        width: 260
        height: content.implicitHeight + Appearance.spacingNormal * 2

        opacity: UiState.batteryOpen ? 1 : 0
        y: UiState.batteryOpen ? restY : restY - 12
        scale: UiState.batteryOpen ? 1 : Appearance.popupFromScale
        transformOrigin: Item.TopRight
        Behavior on opacity { Anim {} }
        Behavior on y { Anim {} }
        Behavior on scale { PopAnim {} }
        Behavior on height { Anim {} }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.spacingNormal
            spacing: Appearance.spacingSmall

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Battery.percent + "%"
                color: Colors.textPrimary
                font.family: Appearance.fontFamily
                font.bold: true
                font.pixelSize: 34
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4
                visible: Battery.charging

                Text {
                    text: ""
                    color: Colors.primary
                    font.family: Appearance.fontFamilyIcons
                    font.pixelSize: Appearance.fontSizeSmall
                }
                Text {
                    text: "Charging"
                    color: Colors.primary
                    font.family: Appearance.fontFamily
                    font.pixelSize: Appearance.fontSizeSmall
                }
            }

            Item {
                id: gauge
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.spacingSmall
                Layout.bottomMargin: Appearance.spacingSmall
                implicitWidth: 176
                implicitHeight: 64

                readonly property real targetLevel: Battery.percent / 100
                readonly property color liquidColor: (Battery.percent <= 15 && !Battery.charging) ? Colors.error : Colors.primary
                property real displayLevel: 0

                Behavior on displayLevel { Anim { duration: Appearance.animSlow } }

                NumberAnimation {
                    id: fillInAnim
                    target: gauge
                    property: "displayLevel"
                    from: 0
                    to: gauge.targetLevel
                    duration: 1200
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Appearance.easeDecelerate
                }

                Connections {
                    target: UiState
                    function onBatteryOpenChanged() { if (UiState.batteryOpen) fillInAnim.restart() }
                }

                Rectangle {
                    id: body
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width - 10
                    radius: Appearance.radiusSmall
                    color: Colors.alpha(Colors.surfaceContainerHigh, Appearance.layerOpacity)
                    border.width: 2
                    border.color: Colors.outline
                    clip: true

                    Canvas {
                        id: liquid
                        anchors.fill: parent
                        property real wavePhase: 0

                        NumberAnimation on wavePhase {
                            running: gauge.displayLevel > 0.01 && gauge.displayLevel < 0.99
                            loops: Animation.Infinite
                            from: 0; to: Math.PI * 2; duration: 900
                        }

                        onWavePhaseChanged: requestPaint()
                        Connections { target: gauge; function onDisplayLevelChanged() { liquid.requestPaint() } }

                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            if (gauge.displayLevel <= 0.001) return

                            const r = body.radius
                            ctx.save()
                            ctx.beginPath()
                            ctx.moveTo(r, 0)
                            ctx.lineTo(width - r, 0)
                            ctx.arcTo(width, 0, width, r, r)
                            ctx.lineTo(width, height - r)
                            ctx.arcTo(width, height, width - r, height, r)
                            ctx.lineTo(r, height)
                            ctx.arcTo(0, height, 0, height - r, r)
                            ctx.lineTo(0, r)
                            ctx.arcTo(0, 0, r, 0, r)
                            ctx.closePath()
                            ctx.clip()

                            const fillW = width * gauge.displayLevel
                            const amp = Math.min(6, Math.min(fillW, width - fillW)) * Math.sin(gauge.displayLevel * Math.PI)
                            const crestX = fillW + Math.sin(liquid.wavePhase) * amp

                            ctx.beginPath()
                            ctx.moveTo(0, 0)
                            ctx.lineTo(Math.max(0, fillW - amp), 0)
                            ctx.quadraticCurveTo(crestX, height / 2, Math.max(0, fillW - amp), height)
                            ctx.lineTo(0, height)
                            ctx.closePath()

                            const grad = ctx.createLinearGradient(0, 0, Math.max(fillW, 1), 0)
                            grad.addColorStop(0, Qt.darker(gauge.liquidColor, 1.2).toString())
                            grad.addColorStop(1, Qt.lighter(gauge.liquidColor, 1.15).toString())
                            ctx.fillStyle = grad
                            ctx.fill()
                            ctx.restore()
                        }
                    }

                    Item {
                        id: bubbleArea
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: gauge.displayLevel * body.width
                        clip: true
                        visible: gauge.displayLevel > 0.08

                        Repeater {
                            model: 3
                            Rectangle {
                                id: bubble
                                required property int index
                                width: 4 + (index % 2) * 2
                                height: width
                                radius: width / 2
                                color: "#ffffff"
                                opacity: 0.4
                                x: 10 + index * 20
                                y: bubbleArea.height

                                SequentialAnimation {
                                    running: bubbleArea.visible
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: bubble.index * 420 }
                                    NumberAnimation { target: bubble; property: "y"; to: -8; duration: 1600 + bubble.index * 240; easing.type: Easing.Linear }
                                    PropertyAction { target: bubble; property: "y"; value: bubbleArea.height }
                                }
                            }
                        }
                    }
                }

                // battery nub
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: body.right
                    anchors.leftMargin: -1
                    width: 8
                    height: 26
                    radius: 2
                    color: Colors.outline
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: {
                    if (Battery.timeText !== "") return Battery.timeText
                    if (Battery.state === "pending-charge") return "Paused at " + Battery.chargeEndThreshold + "%"
                    if (Battery.state === "fully-charged") return "Fully charged"
                    return "Estimating…"
                }
                color: Colors.textSecondary
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSizeSmall
                elide: Text.ElideRight
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outline; opacity: 0.4; Layout.topMargin: Appearance.spacingSmall }

            Text {
                text: "Power Mode"
                color: Colors.textSecondary
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSizeSmall
            }

            SegmentedControl {
                Layout.fillWidth: true
                options: [
                    { value: "power-saver", label: "Saver" },
                    { value: "balanced", label: "Balanced" },
                    { value: "performance", label: "Performance" }
                ]
                currentValue: PowerProfile.current
                onSelected: (v) => PowerProfile.set(v)
            }
        }
    }
}
