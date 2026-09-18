import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Polkit
import "../../config"
import "../../services"
import "../common"

// The shell's own authentication prompt.
//
// autostart.lua used to launch /usr/lib/xfce-polkit/xfce-polkit, so every
// `pkexec` or "Authentication is required…" dialog arrived as a stock GTK box
// in the middle of an otherwise Material You desktop -- unthemed, and the only
// part of the session that never followed the wallpaper.
ShellPanel {
    id: polkitWindow

    // Driven by polkit rather than by UiState: this is not a panel the user
    // opens, so it has no name and no IPC handler.
    readonly property var flow: agent.flow
    open: !!polkitWindow.flow && !polkitWindow.flow.isCompleted

    // An auth prompt is the one thing entitled to take over the screen.
    onOpenChanged: {
        if (!open) return
        UiState.hideAll()
        password.clear()
        password.forceActiveFocus()
    }

    PolkitAgent {
        id: agent

        onAuthenticationRequestStarted: {
            password.clear()
        }
    }

    function _submit() {
        if (!polkitWindow.flow) return
        polkitWindow.flow.submit(password.text)
        password.clear()
    }

    function _cancel() {
        if (polkitWindow.flow) polkitWindow.flow.cancelAuthenticationRequest()
    }

    // Escape cancels the request properly rather than just hiding the window,
    // which would leave the caller waiting forever.
    onEscapePressed: polkitWindow._cancel()

    // Same for clicking away, and for the focus grab being cleared.
    onDismissed: polkitWindow._cancel()

    PopupCard {
        id: card
        anchors.centerIn: parent
        width: 380
        height: content.implicitHeight + Appearance.spacingLarge * 2
        elevation: 2

        opacity: polkitWindow.open ? 1 : 0
        scale: polkitWindow.open ? 1 : Appearance.popupFromScale
        Behavior on opacity { Anim {} }
        Behavior on scale { PopAnim {} }
        Behavior on height { Anim {} }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.spacingLarge
            spacing: Appearance.spacingNormal

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingNormal

                Item {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    Layout.alignment: Qt.AlignTop

                    Image {
                        id: actionIcon
                        anchors.fill: parent
                        visible: status === Image.Ready
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        source: (polkitWindow.flow && polkitWindow.flow.iconName)
                            ? "image://icon/" + polkitWindow.flow.iconName : ""
                    }

                    // Not every action carries an icon name, and not every icon
                    // name resolves in the current theme.
                    Text {
                        anchors.centerIn: parent
                        visible: !actionIcon.visible
                        text: ""
                        color: Colors.primary
                        font.family: Appearance.fontFamilyIcons
                        font.pixelSize: 26
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: "Authentication required"
                        color: Colors.textPrimary
                        font.family: Appearance.fontFamily
                        font.bold: true
                        font.pixelSize: Appearance.fontSizeNormal
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: polkitWindow.flow ? (polkitWindow.flow.message || "") : ""
                        color: Colors.textSecondary
                        font.family: Appearance.fontFamily
                        font.pixelSize: Appearance.fontSizeSmall
                        wrapMode: Text.Wrap
                    }
                }
            }

            TextField {
                id: password
                Layout.fillWidth: true
                visible: !!polkitWindow.flow && polkitWindow.flow.isResponseRequired
                password: polkitWindow.flow ? !polkitWindow.flow.responseVisible : true
                placeholder: (polkitWindow.flow && polkitWindow.flow.inputPrompt)
                    ? polkitWindow.flow.inputPrompt : "Password"
                icon: ""
                error: !!polkitWindow.flow && polkitWindow.flow.supplementaryIsError

                onAccepted: polkitWindow._submit()
                onCancelled: polkitWindow._cancel()
            }

            // Where polkit reports "Authentication failure" and the retries it
            // is willing to give you.
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: polkitWindow.flow ? (polkitWindow.flow.supplementaryMessage || "") : ""
                color: (polkitWindow.flow && polkitWindow.flow.supplementaryIsError)
                    ? Colors.error : Colors.textSecondary
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSizeSmall
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacingSmall
                spacing: Appearance.spacingNormal

                Item { Layout.fillWidth: true }

                PolkitButton {
                    label: "Cancel"
                    onActivated: polkitWindow._cancel()
                }

                PolkitButton {
                    label: "Authenticate"
                    accent: true
                    enabled: !!polkitWindow.flow && polkitWindow.flow.isResponseRequired
                    onActivated: polkitWindow._submit()
                }
            }
        }
    }
}
