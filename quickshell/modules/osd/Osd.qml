import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../common"

PanelWindow {
    id: osdWindow

    property bool shown: false
    property string kind: "volume"
    property real level: 0.0
    property bool muted: false
    property real popScale: 0.85

    visible: shown
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"

    anchors { bottom: true }
    margins.bottom: 90

    implicitWidth: 240
    implicitHeight: 70

    IpcHandler {
        target: "osd"
        function volume(): void { osdWindow.queryVolume() }
        function brightness(): void { osdWindow.queryBrightness() }
    }

    function queryVolume() {
        osdWindow.kind = "volume"
        volumeProc.running = true
    }

    function queryBrightness() {
        osdWindow.kind = "brightness"
        brightnessProc.running = true
    }

    Process {
        id: volumeProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/Volume:\s*([\d.]+)/)
                osdWindow.level = m ? Math.min(1, parseFloat(m[1])) : 0
                osdWindow.muted = text.indexOf("MUTED") !== -1
                osdWindow._show()
            }
        }
    }

    Process {
        id: brightnessProc
        command: ["bash", "-c", "brightnessctl -m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                const pct = parts.length >= 4 ? parseInt(parts[3]) : 0
                osdWindow.level = (isNaN(pct) ? 0 : pct) / 100
                osdWindow.muted = false
                osdWindow._show()
            }
        }
    }

    function _show() {
        osdWindow.shown = true
        hideTimer.restart()
        popAnim.restart()
    }

    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: osdWindow.shown = false
    }

    SequentialAnimation {
        id: popAnim
        NumberAnimation { target: osdWindow; property: "popScale"; to: 1.05; duration: 140; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
        NumberAnimation { target: osdWindow; property: "popScale"; to: 1.0; duration: 160; easing.type: Easing.OutQuad }
    }

    PopupCard {
        id: card
        anchors.centerIn: parent
        width: osdWindow.implicitWidth
        height: osdWindow.implicitHeight

        scale: osdWindow.popScale
        opacity: osdWindow.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.spacingNormal
            spacing: Appearance.spacingNormal

            Text {
                text: {
                    if (osdWindow.kind === "brightness") return "\uf185"
                    if (osdWindow.muted) return "\uf026"
                    if (osdWindow.level > 0.5) return "\uf028"
                    if (osdWindow.level > 0) return "\uf027"
                    return "\uf026"
                }
                color: Colors.primary
                font.family: Appearance.fontFamilyIcons
                font.pixelSize: Appearance.fontSizeLarge
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 10
                radius: 5
                color: Colors.surfaceContainerHigh

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    radius: parent.radius
                    width: parent.width * (osdWindow.muted ? 0 : osdWindow.level)
                    color: Colors.primary
                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
