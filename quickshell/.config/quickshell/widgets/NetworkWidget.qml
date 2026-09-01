import QtQuick
import "../services/"

Item {
  id: root
  implicitWidth: label.implicitWidth + 12
  implicitHeight: label.implicitHeight + 6

  readonly property string icon: {
    if (!Network.connected) return "󰤭"
    if (Network.strength >= 67) return "󰤨"
    if (Network.strength >= 34) return "󰤢"
    if (Network.strength > 0) return "󰤟"
    return "󰤯"
  }

  Rectangle {
    anchors.fill: parent
    radius: 6
    color: hover.hovered ? "#26fab387" : "transparent"

    Behavior on color {
      ColorAnimation { duration: 220 }
    }
  }

  Text {
    id: label
    anchors.centerIn: parent
    text: root.icon
    color: !Network.connected ? "#f38ba8" : (hover.hovered ? "#fab387" : "#ffffff")
    font.pixelSize: 14
    font.family: "JetBrainsMono Nerd Font"

    Behavior on color {
      ColorAnimation { duration: 220 }
    }
  }

  HoverHandler { id: hover }
}
