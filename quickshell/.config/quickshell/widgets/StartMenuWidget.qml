import QtQuick
import Quickshell

Item {
  id: root

  implicitWidth: 24
  implicitHeight: 24

  Rectangle{
    id: button
    anchors.fill: parent
    radius: 6
    color: hoverHandler.hovered ? "#26fab387" : "transparent"

    Behavior on color {
      ColorAnimation { duration: 220}
    }

    Text {
      anchors.centerIn: parent
      text: "󰣇"
      color: hoverHandler.hovered ? "#fab387" : "#cdd6f4"
      font.pixelSize: 14
      font.family: "JetBrainsMono Nerd Font"
      renderType: Text.NativeRendering

      Behavior on color {
        ColorAnimation { duration: 220 }
      }
    }
  }

  HoverHandler {
    id: hoverHandler
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: Quickshell.execDetached(["rofi", "-show", "drun", "-location", "2", "-xoffset", "0", "-yoffset", "38"])
  }
}
