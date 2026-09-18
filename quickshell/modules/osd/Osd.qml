import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../../services"
import "../common"

PanelWindow {
    id: osdWindow

    property bool shown: false
    property string kind: "volume"
    property real popScale: 0.85

    visible: shown

    // Same treatment as the toasts: pinned to the focused output.
    screen: FocusedScreen.screen

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
        function volume(): void { osdWindow.showVolume() }
        function brightness(): void { osdWindow.queryBrightness() }
        function mic(): void { osdWindow.showMic() }
    }

    // Volume and mute now come straight off the Audio service, so the OSD
    // appears whatever moved them -- a media key, pavucontrol, a game, the
    // shell's own mixer. It used to run `wpctl get-volume` once per keybind
    // and scrape stdout, which meant anything else changing the volume showed
    // nothing at all.
    readonly property real level: {
        if (osdWindow.kind === "brightness") return osdWindow.brightnessLevel
        if (osdWindow.kind === "mic") return Audio.micVolume
        return Audio.volume
    }

    readonly property bool muted: {
        if (osdWindow.kind === "brightness") return false
        if (osdWindow.kind === "mic") return Audio.micMuted
        return Audio.muted
    }

    property real brightnessLevel: 0

    function showVolume() {
        osdWindow.kind = "volume"
        osdWindow._show()
    }

    function showMic() {
        osdWindow.kind = "mic"
        osdWindow._show()
    }

    function queryBrightness() {
        osdWindow.kind = "brightness"
        brightnessProc.running = true
    }

    // Nothing should pop up just because the shell started and the bindings
    // settled for the first time, so changes only count once this is armed.
    property bool armed: false
    Timer { interval: 1500; running: true; onTriggered: osdWindow.armed = true }

    Connections {
        target: Audio
        enabled: osdWindow.armed

        function onVolumeChanged() { osdWindow._auto("volume") }
        function onMutedChanged() { osdWindow._auto("volume") }
        function onMicMutedChanged() { osdWindow._auto("mic") }
    }

    // Dragging the shell's own volume slider already shows the value under the
    // cursor; echoing it in an OSD as well is just noise.
    function _auto(which) {
        if (UiState.audioOpen) return
        osdWindow.kind = which
        osdWindow._show()
    }

    Process {
        id: brightnessProc
        command: ["bash", "-c", "brightnessctl -m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                const pct = parts.length >= 4 ? parseInt(parts[3]) : 0
                osdWindow.brightnessLevel = (isNaN(pct) ? 0 : pct) / 100
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
        NumberAnimation { target: osdWindow; property: "popScale"; to: 1.05; duration: Appearance.animFast; easing.type: Easing.OutBack; easing.overshoot: Appearance.overshootPop }
        NumberAnimation { target: osdWindow; property: "popScale"; to: 1.0; duration: Appearance.animFast; easing.type: Easing.Bezier; easing.bezierCurve: Appearance.easeStandard }
    }

    PopupCard {
        id: card
        anchors.centerIn: parent
        width: osdWindow.implicitWidth
        height: osdWindow.implicitHeight

        scale: osdWindow.popScale
        opacity: osdWindow.shown ? 1 : 0
        Behavior on opacity { Anim {} }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.spacingNormal
            spacing: Appearance.spacingNormal

            Text {
                text: {
                    if (osdWindow.kind === "brightness") return "\uf185"
                    if (osdWindow.kind === "mic") return Audio.micIconFor(osdWindow.muted)
                    return Audio.iconFor(osdWindow.level, osdWindow.muted)
                }
                color: Colors.primary
                font.family: Appearance.fontFamilyIcons
                font.pixelSize: Appearance.fontSizeLarge
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 10
                radius: 5
                color: Colors.alpha(Colors.surfaceContainerHigh, Appearance.layerOpacity)

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    radius: parent.radius
                    width: parent.width * (osdWindow.muted ? 0 : osdWindow.level)
                    color: Colors.primary
                    Behavior on width { Anim {} }
                }
            }
        }
    }
}
