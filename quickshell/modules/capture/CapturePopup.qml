import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../config"
import "../../services"
import "../common"

// What a screenshot lands in: a preview with somewhere to go.
//
// The old script decided for you -- `full` saved and copied, `region-clip`
// only copied, `region-save` only saved -- so getting a shot into the other
// form meant taking it again. One capture path now, and the choice afterwards.
ShellPanel {
    id: captureWindow

    // No UiState name: this panel is raised by a capture completing, not by the
    // user toggling it, so `open` is driven directly like the polkit dialog.
    IpcHandler {
        target: "capture"
        function region(): void { Capture.region() }
        function output(): void { Capture.output() }
        function screen(): void { Capture.screen() }
        function window(): void { Capture.window() }
        function record(): void { Capture.toggleRecording() }

        // The preview's own buttons, reachable from a script too.
        function copy(): void { Capture.copyShot() }
        function save(): void { Capture.saveShot() }
        function annotate(): void { Capture.annotateShot() }
        function close(): void { Capture.discard() }
    }

    // Driven by there being a shot, not by the user opening anything.
    open: Capture.pending !== ""
    onDismissed: Capture.discard()

    PopupCard {
        id: card
        anchors.centerIn: parent
        // Sized from the image's *natural* size, not its painted size: painted
        // size depends on the layout, which depends on this width, which is a
        // binding loop -- and a card whose width never resolves never maps.
        readonly property int previewMax: 600
        width: Math.min(card.previewMax, Math.max(320, preview.implicitWidth))
            + Appearance.spacingLarge * 2
        height: content.implicitHeight + Appearance.spacingLarge * 2
        elevation: 2

        opacity: captureWindow.open ? 1 : 0
        scale: captureWindow.open ? 1 : Appearance.popupFromScale
        Behavior on opacity { Anim {} }
        Behavior on scale { PopAnim {} }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.spacingLarge
            spacing: Appearance.spacingNormal

            Image {
                id: preview
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: card.previewMax
                Layout.maximumHeight: 340
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
                source: Capture.pending ? "file://" + Capture.pending : ""

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 1
                    border.color: Colors.alpha(Colors.outline, 0.4)
                    radius: Appearance.radiusSmall
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingSmall

                CaptureButton {
                    label: "Copy"
                    icon: ""
                    accent: true
                    onActivated: Capture.copyShot()
                }

                CaptureButton {
                    label: "Save"
                    icon: ""
                    onActivated: Capture.saveShot()
                }

                CaptureButton {
                    label: "Annotate"
                    icon: ""
                    onActivated: Capture.annotateShot()
                }

                Item { Layout.fillWidth: true }

                CaptureButton {
                    label: "Discard"
                    icon: ""
                    danger: true
                    onActivated: Capture.discard()
                }
            }
        }
    }
}
