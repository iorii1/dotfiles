import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../config"
import "../common"
import "../../services"

ShellPanel {
    id: powerWindow

    name: "powerMenu"

    // Land on Lock. It is the safe one, and the two destructive buttons are at
    // the far end of the row behind a confirm, so nothing dangerous is one
    // keypress away from a menu that just opened.
    onOpenChanged: if (open) lockBtn.takeFocus()

    IpcHandler {
        target: "power"
        function toggle(): void { UiState.toggle("powerMenu") }
        function open(): void { UiState.show("powerMenu") }
        function close(): void { UiState.hide("powerMenu") }
    }

    // Hibernation writes RAM to swap, so it needs swap that survives losing
    // power. zram is compressed RAM -- hibernating to it cannot work, and
    // `systemctl hibernate` fails every time. This machine has only zram, so
    // the button would be permanently broken; it is hidden unless there is
    // real backing store to hibernate into.
    property bool canHibernate: false

    Process {
        id: hibernateCheck
        running: true
        command: ["bash", "-c",
            "swapon --show=NAME --noheadings 2>/dev/null "
            + "| grep -qv '^/dev/zram' && echo yes || echo no"]
        stdout: StdioCollector {
            onStreamFinished: powerWindow.canHibernate = (text.trim() === "yes")
        }
    }

    Process { id: runner }
    function run(cmd) {
        UiState.hide("powerMenu")
        runner.command = ["bash", "-c", cmd]
        runner.running = true
    }

    PopupCard {
        id: card
        anchors.centerIn: parent
        width: layout.implicitWidth + Appearance.spacingLarge * 2
        height: layout.implicitHeight + Appearance.spacingLarge * 2

        opacity: UiState.powerMenuOpen ? 1 : 0
        scale: UiState.powerMenuOpen ? 1 : Appearance.popupFromScale
        Behavior on opacity { Anim {} }
        Behavior on scale { PopAnim {} }

        MouseArea { anchors.fill: parent }

        RowLayout {
            id: layout
            anchors.centerIn: parent
            spacing: Appearance.spacingNormal

            FillButton {
                id: lockBtn
                prevFocus: null
                nextFocus: suspendBtn.focusItem
                label: "Lock"
                icon: "\uf023"
                accentColor: Colors.primary
                active: UiState.powerMenuOpen
                entranceDelay: 0
                onTriggered: powerWindow.run("loginctl lock-session")
            }

            FillButton {
                id: suspendBtn
                prevFocus: lockBtn.focusItem
                nextFocus: logoutBtn.focusItem
                label: "Suspend"
                icon: "\uf186"
                accentColor: Colors.primary
                active: UiState.powerMenuOpen
                entranceDelay: 60
                onTriggered: powerWindow.run("systemctl suspend")
            }

            FillButton {
                id: logoutBtn
                prevFocus: suspendBtn.focusItem
                nextFocus: powerWindow.canHibernate ? hibernateBtn.focusItem : rebootBtn.focusItem
                label: "Logout"
                icon: "\uf08b"
                accentColor: Colors.primary
                active: UiState.powerMenuOpen
                entranceDelay: 120
                onTriggered: powerWindow.run("hyprctl dispatch exit")
            }

            FillButton {
                id: hibernateBtn
                visible: powerWindow.canHibernate
                prevFocus: logoutBtn.focusItem
                nextFocus: rebootBtn.focusItem
                label: "Hibernate"
                icon: "\uf0f4"
                accentColor: Colors.primary
                active: UiState.powerMenuOpen
                entranceDelay: 150
                onTriggered: powerWindow.run("systemctl hibernate")
            }

            FillButton {
                id: rebootBtn
                prevFocus: hibernateBtn.focusItem
                nextFocus: shutdownBtn.focusItem
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
                id: shutdownBtn
                prevFocus: rebootBtn.focusItem
                nextFocus: null
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
