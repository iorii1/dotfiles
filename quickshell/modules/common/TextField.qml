import QtQuick
import "../../config"

// The shell's text input: a themed TextInput with a placeholder, an optional
// leading glyph, and a focus underline that picks up the accent colour.
//
// Panels that want a password field set `password: true`; ones that want
// search-as-you-type just read `text`. Return emits accepted(), Escape emits
// cancelled() -- neither is handled here, because what they mean (launch,
// connect, dismiss) belongs to the caller.
//
// Arrow keys are deliberately left alone: a field inside a list (the launcher,
// clipboard search) needs Up/Down to drive the list, not the cursor, so callers
// attach their own Keys handlers and those run first.
Item {
    id: root

    property alias text: input.text
    property alias echoMode: input.echoMode
    property alias inputFocus: input.activeFocus
    property alias horizontalAlignment: input.horizontalAlignment

    property string placeholder: ""
    property string icon: ""
    property bool password: false
    property color accentColor: Colors.primary

    // Set true to show the field as having failed -- a wrong Wi-Fi key, a
    // rejected polkit password. Clears itself as soon as the text changes.
    property bool error: false

    signal accepted(string text)
    signal cancelled()

    implicitHeight: Math.max(input.implicitHeight, 24) + 8

    function clear() {
        input.text = ""
        root.error = false
    }

    function forceActiveFocus() {
        input.forceActiveFocus()
    }

    Row {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Appearance.spacingSmall

        Text {
            visible: root.icon !== ""
            text: root.icon
            color: root.error ? Colors.error : (input.activeFocus ? root.accentColor : Colors.textSecondary)
            font.family: Appearance.fontFamilyIcons
            font.pixelSize: Appearance.fontSizeNormal
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: Appearance.animFast } }
        }

        Item {
            width: row.width - (root.icon !== "" ? parent.spacing + Appearance.fontSizeNormal : 0)
            height: Math.max(input.implicitHeight, 24)

            Text {
                visible: input.text === ""
                anchors.verticalCenter: parent.verticalCenter
                text: root.placeholder
                color: Colors.textSecondary
                opacity: 0.7
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSizeNormal
                elide: Text.ElideRight
                width: parent.width
            }

            TextInput {
                id: input
                anchors.fill: parent
                verticalAlignment: TextInput.AlignVCenter
                font.family: Appearance.fontFamily
                font.pixelSize: Appearance.fontSizeNormal
                color: Colors.textPrimary
                selectionColor: Colors.alpha(root.accentColor, 0.4)
                selectedTextColor: Colors.textPrimary
                selectByMouse: true
                clip: true
                echoMode: root.password ? TextInput.Password : TextInput.Normal

                onTextChanged: root.error = false
                onAccepted: root.accepted(input.text)
                Keys.onEscapePressed: root.cancelled()
            }
        }
    }

    // Underline rather than a full ring: these sit inside popup cards that are
    // already outlined, and a second box around the field muddies that.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: input.activeFocus || root.error ? 2 : 1
        radius: height / 2
        color: root.error ? Colors.error
                          : (input.activeFocus ? root.accentColor : Colors.outline)
        opacity: input.activeFocus || root.error ? 1 : 0.4
        Behavior on color { ColorAnimation { duration: Appearance.animFast } }
        Behavior on opacity { Anim { duration: Appearance.animFast } }
        Behavior on height { Anim { duration: Appearance.animFast } }
    }
}
