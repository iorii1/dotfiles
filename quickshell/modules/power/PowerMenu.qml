import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../common"
import "../../services"

PanelWindow {
    id: powerWindow

    visible: UiState.powerMenuOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"
    WlrLayershell.keyboardFocus: UiState.powerMenuOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }

    IpcHandler {
        target: "power"
        function toggle(): void { UiState.powerMenuOpen = !UiState.powerMenuOpen }
        function open(): void { UiState.powerMenuOpen = true }
        function close(): void { UiState.powerMenuOpen = false }
    }

    Process { id: runner }
    function run(cmd) {
        UiState.powerMenuOpen = false
        runner.command = ["bash", "-c", cmd]
        runner.running = true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: UiState.powerMenuOpen = false
    }

    PopupCard {
        id: card
        anchors.centerIn: parent
        width: layout.implicitWidth + Appearance.spacingLarge * 2
        height: layout.implicitHeight + Appearance.spacingLarge * 2

        opacity: UiState.powerMenuOpen ? 1 : 0
        scale: UiState.powerMenuOpen ? 1 : 0.9
        Behavior on opacity { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Appearance.animNormal; easing.type: Easing.OutBack; easing.overshoot: Appearance.overshootCard } }

        MouseArea { anchors.fill: parent }

        RowLayout {
            id: layout
            anchors.centerIn: parent
            spacing: Appearance.spacingNormal

            FillButton {
                label: "Lock"
                icon: "\uf023"
                accentColor: Colors.primary
                active: UiState.powerMenuOpen
                entranceDelay: 0
                onTriggered: powerWindow.run("loginctl lock-session")
            }

            FillButton {
                label: "Suspend"
                icon: "\uf186"
                accentColor: Colors.primary
                active: UiState.powerMenuOpen
                entranceDelay: 60
                onTriggered: powerWindow.run("systemctl suspend")
            }

            FillButton {
                label: "Logout"
                icon: "\uf08b"
                accentColor: Colors.primary
                active: UiState.powerMenuOpen
                entranceDelay: 120
                onTriggered: powerWindow.run("hyprctl dispatch exit")
            }

            FillButton {
                label: "Reboot"
                icon: "\uf021"
                accentColor: Colors.error
                onAccentColor: Colors.errorText
                requireConfirm: true
                active: UiState.powerMenuOpen
                entranceDelay: 180
                onTriggered: powerWindow.run("systemctl reboot")
            }

            FillButton {
                label: "Shutdown"
                icon: "\uf011"
                accentColor: Colors.error
                onAccentColor: Colors.errorText
                requireConfirm: true
                active: UiState.powerMenuOpen
                entranceDelay: 240
                onTriggered: powerWindow.run("systemctl poweroff")
            }
        }
    }
}
