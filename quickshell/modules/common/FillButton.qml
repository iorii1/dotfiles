import QtQuick
import QtQuick.Layouts
import "../../config"

Item {
    id: root
    implicitWidth: 160
    implicitHeight: 64

    property string label: "HOLD"
    property string icon: ""
    property color accentColor: Colors.primary
    property color baseColor: Colors.surfaceContainer
    property color onAccentColor: Colors.primaryText
    property int fillDuration: 900
    property int autoResetTimeout: 1400

    // When true, a completed hold doesn't fire immediately -- it switches
    // the label to confirmLabel and arms a second hold as the real trigger.
    property bool requireConfirm: false
    property string confirmLabel: "Confirm?"
    property bool awaitingConfirm: false

    signal triggered()

    // The item that actually holds focus, so a row of these can be chained:
    //   FillButton { id: a; nextFocus: b.focusItem }
    // Focus lives on the inner MouseArea rather than on root, so neighbours
    // have to be wired to that and not to the FillButton itself.
    property alias focusItem: ma
    property var prevFocus: null
    property var nextFocus: null

    function takeFocus() {
        ma.forceActiveFocus()
    }

    property real fillLevel: 0.0
    property bool isTriggered: false
    readonly property bool hovered: ma.containsMouse

    property bool active: false
    property int entranceDelay: 0
    scale: 0.6
    opacity: 0.0

    onActiveChanged: {
        if (root.active) {
            entranceAnim.restart()
        } else {
            root.scale = 0.6
            root.opacity = 0.0
            root.reset()
        }
    }

    PopIn { id: entranceAnim; target: root; delay: root.entranceDelay; fromScale: 0.6 }

    function reset() {
        resetTimer.stop()
        confirmTimer.stop()
        root.isTriggered = false
        root.awaitingConfirm = false
        fillAnim.stop()
        drainAnim.restart()
    }

    Rectangle {
        id: shape
        anchors.fill: parent
        radius: Appearance.radiusNormal
        color: root.baseColor
        clip: true

        scale: (ma.pressed && !root.isTriggered) ? Appearance.pressScaleSubtle : (root.hovered ? Appearance.hoverScaleSubtle : 1.0)
        Behavior on scale { Anim { duration: Appearance.animFast } }

        border.color: root.awaitingConfirm ? root.accentColor : Colors.outline
        border.width: root.awaitingConfirm ? 2 : 1
        Behavior on border.color { ColorAnimation { duration: Appearance.animFast } }

        Canvas {
            id: waveCanvas
            anchors.fill: parent
            property real wavePhase: 0

            NumberAnimation on wavePhase {
                running: root.fillLevel > 0.001 && root.fillLevel < 0.999
                loops: Animation.Infinite
                from: 0; to: Math.PI * 2; duration: Appearance.animAmbient
            }

            onWavePhaseChanged: requestPaint()
            Connections { target: root; function onFillLevelChanged() { waveCanvas.requestPaint() } }

            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                if (root.fillLevel <= 0.001) return

                const r = shape.radius
                const fillW = width * root.fillLevel
                const amp = Math.min(8, Math.min(fillW, width - fillW)) * Math.sin(root.fillLevel * Math.PI)
                const crestX = fillW + Math.sin(waveCanvas.wavePhase) * amp

                ctx.save()
                ctx.beginPath()
                ctx.moveTo(0, 0)
                ctx.lineTo(Math.max(0, fillW - amp), 0)
                ctx.quadraticCurveTo(crestX, height / 2, Math.max(0, fillW - amp), height)
                ctx.lineTo(0, height)
                ctx.closePath()
                ctx.clip()

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

                const grad = ctx.createLinearGradient(0, 0, Math.max(fillW, 1), 0)
                grad.addColorStop(0, Qt.darker(root.accentColor, 1.2).toString())
                grad.addColorStop(1, root.accentColor.toString())
                ctx.fillStyle = grad
                ctx.fill()
                ctx.restore()
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#ffffff"
            opacity: root.isTriggered ? 0.45 : 0.0
            Behavior on opacity { Anim {} }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacingSmall

            Text {
                visible: root.icon !== ""
                text: root.icon
                color: root.fillLevel > 0.5 ? root.onAccentColor : Colors.textPrimary
                font.family: Appearance.fontFamilyIcons
                font.pixelSize: Appearance.fontSizeLarge
                Behavior on color { ColorAnimation { duration: Appearance.animFast } }
            }

            Text {
                text: root.awaitingConfirm ? root.confirmLabel : root.label
                color: root.fillLevel > 0.5 ? root.onAccentColor : Colors.textPrimary
                font.family: Appearance.fontFamily
                font.bold: true
                font.pixelSize: Appearance.fontSizeNormal
                Behavior on color { ColorAnimation { duration: Appearance.animFast } }
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            enabled: !root.isTriggered
            cursorShape: root.isTriggered ? Qt.ArrowCursor : Qt.PointingHandCursor
            activeFocusOnTab: !root.isTriggered
            KeyNavigation.left: root.prevFocus
            KeyNavigation.right: root.nextFocus

            onPressed: { drainAnim.stop(); fillAnim.restart() }
            onReleased: { if (!root.isTriggered) { fillAnim.stop(); drainAnim.restart() } }
            onCanceled: { if (!root.isTriggered) { fillAnim.stop(); drainAnim.restart() } }

            // Holding Space or Return drives the same fill the pointer does, so
            // the power menu is operable without a mouse.
            //
            // Auto-repeat has to be filtered on *both* edges: a held key arrives
            // as a stream of press/release pairs, and acting on them would
            // restart the fill several times a second and it would never finish.
            readonly property var _holdKeys: [Qt.Key_Space, Qt.Key_Return, Qt.Key_Enter]

            Keys.onPressed: (event) => {
                if (event.isAutoRepeat || root.isTriggered) return
                if (ma._holdKeys.indexOf(event.key) === -1) return
                drainAnim.stop()
                fillAnim.restart()
                event.accepted = true
            }

            Keys.onReleased: (event) => {
                if (event.isAutoRepeat) return
                if (ma._holdKeys.indexOf(event.key) === -1) return
                if (!root.isTriggered) { fillAnim.stop(); drainAnim.restart() }
                event.accepted = true
            }
        }

        // Above the wave canvas, so a focused button still reads as focused
        // once the fill has covered it.
        Rectangle {
            anchors.fill: parent
            radius: shape.radius
            color: "transparent"
            border.width: 2
            border.color: Colors.primary
            opacity: ma.activeFocus ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim { duration: Appearance.animFast } }
        }

        NumberAnimation {
            id: fillAnim
            target: root
            property: "fillLevel"
            to: 1.0
            duration: root.fillDuration * (1.0 - root.fillLevel)
            easing.type: Easing.InSine
            onFinished: {
                if (root.fillLevel >= 0.999) {
                    if (root.requireConfirm && !root.awaitingConfirm) {
                        root.awaitingConfirm = true
                        confirmTimer.restart()
                        drainAnim.restart()
                    } else {
                        root.isTriggered = true
                        root.awaitingConfirm = false
                        confirmTimer.stop()
                        root.triggered()
                        resetTimer.restart()
                    }
                }
            }
        }

        NumberAnimation {
            id: drainAnim
            target: root
            property: "fillLevel"
            to: 0.0
            duration: 500 * root.fillLevel
            easing.type: Easing.Bezier
            easing.bezierCurve: Appearance.easeStandard
        }

        Timer {
            id: resetTimer
            interval: root.autoResetTimeout
            onTriggered: root.reset()
        }

        Timer {
            id: confirmTimer
            interval: 3000
            onTriggered: root.awaitingConfirm = false
        }
    }
}
