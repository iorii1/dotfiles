pragma Singleton
import QtQuick

QtObject {
    id: root

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property string fontFamilyMono: "JetBrainsMono Nerd Font Mono"

    readonly property int fontSizeSmall: 11
    readonly property int fontSizeNormal: 13
    readonly property int fontSizeLarge: 16

    readonly property int radiusSmall: 8
    readonly property int radiusNormal: 12
    readonly property int radiusLarge: 18

    readonly property int spacingSmall: 6
    readonly property int spacingNormal: 10
    readonly property int spacingLarge: 16

    readonly property int barHeight: 34
    readonly property int barMargin: 6

    readonly property int animFast: 150
    readonly property int animNormal: 250
    readonly property int animSlow: 400

    readonly property int easingStandard: Easing.OutCubic
    readonly property int easingPop: Easing.OutBack

    readonly property real overshootCard: 1.15
    readonly property color shadowColor: "#66000000"
}
