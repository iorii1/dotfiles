import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "../../config"
import "../common"

// The shell's own lock screen, over ext-session-lock.
//
// Read this before binding it to anything: while a session lock is held, the
// compositor shows ONLY these surfaces. If this process dies without
// unlocking, Hyprland keeps the session locked -- that is the protocol's
// security guarantee, not a bug -- and the way back in is a TTY
// (Ctrl+Alt+F2), not the desktop. hyprlock stays installed and bound to
// SUPER+Escape precisely so there is always a known-good path.
//
// Authentication is PAM, borrowing /etc/pam.d/hyprlock (which is just
// `auth include login`) so this needs no new file under /etc.
Scope {
    id: root

    property bool locked: false
    property string status: ""
    property bool failed: false
    readonly property bool busy: pam.active && !pam.responseRequired

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock() }
        function isLocked(): bool { return root.locked }
    }

    function lock() {
        if (root.locked) return
        root.status = ""
        root.failed = false
        root.locked = true
        // PAM is started fresh for each attempt rather than held open.
        pam.start()
    }

    function submit(password) {
        if (!pam.responseRequired) return
        root.status = "Checking…"
        root.failed = false
        pam.respond(password)
    }

    PamContext {
        id: pam
        config: "hyprlock"

        onPamMessage: {
            // PAM drives the conversation: it asks, we relay what it said.
            if (pam.responseRequired) root.status = ""
            else if (pam.message !== "") root.status = pam.message
            root.failed = pam.messageIsError
        }

        onCompleted: (result) => {
            if (result === PamResult.Success) {
                root.status = ""
                root.failed = false
                root.locked = false
                return
            }
            root.failed = true
            root.status = result === PamResult.MaxTries
                ? "Too many attempts"
                : "Wrong password"
            // A failed attempt ends the PAM transaction, so the next try needs
            // a new one or respond() goes nowhere.
            pam.start()
        }

        onError: (err) => {
            root.failed = true
            root.status = "Authentication unavailable (" + PamError.toString(err) + ")"
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: root.locked

        surface: WlSessionLockSurface {
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: Colors.background

                // A touch of the accent so the lock still reads as part of
                // this desktop rather than a generic black screen.
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Colors.alpha(Colors.primary, 0.10) }
                        GradientStop { position: 0.55; color: "transparent" }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(360, parent.width - Appearance.spacingLarge * 2)
                    spacing: Appearance.spacingLarge

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: Colors.textPrimary
                        font.family: Appearance.fontFamily
                        font.pixelSize: 72
                        font.bold: true
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: -Appearance.spacingLarge
                        text: Qt.formatDateTime(clock.date, "dddd d MMMM")
                        color: Colors.textSecondary
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSizeNormal
                    }

                    PopupCard {
                        Layout.fillWidth: true
                        Layout.topMargin: Appearance.spacingLarge
                        implicitHeight: form.implicitHeight + Appearance.spacingLarge * 2
                        elevation: 2

                        ColumnLayout {
                            id: form
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Appearance.spacingLarge
                            spacing: Appearance.spacingNormal

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: Quickshell.env("USER") || "Locked"
                                color: Colors.textPrimary
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.fontSizeNormal
                                font.bold: true
                            }

                            TextField {
                                id: field
                                Layout.fillWidth: true
                                placeholder: "Password"
                                icon: ""
                                password: true
                                error: root.failed

                                // The lock surface takes all input by protocol,
                                // so the field can simply always hold focus.
                                Component.onCompleted: forceActiveFocus()
                                onVisibleChanged: if (visible) forceActiveFocus()

                                onTextChanged: if (root.failed) { root.failed = false; root.status = "" }

                                onAccepted: (text) => {
                                    root.submit(text)
                                    field.clear()
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: root.status !== ""
                                horizontalAlignment: Text.AlignHCenter
                                text: root.status
                                color: root.failed ? Colors.error : Colors.textSecondary
                                font.family: Appearance.fontFamily
                                font.pixelSize: Appearance.fontSizeSmall
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                // Refocus whenever the lock appears, including on a second
                // monitor that was plugged in while locked.
                Connections {
                    target: root
                    function onLockedChanged() { if (root.locked) field.forceActiveFocus() }
                }
            }
        }
    }

    // Only ticks while locked; a clock nobody can see is wasted wakeups.
    SystemClock {
        id: clock
        enabled: root.locked
        precision: SystemClock.Minutes
    }
}
