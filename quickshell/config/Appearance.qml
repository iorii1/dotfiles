pragma Singleton
import QtQuick

QtObject {
    id: root

    // Resolved against what is actually installed, best match first, so
    // dropping SF Pro into ~/.local/share/fonts is picked up on next reload
    // with no edit here -- and nothing breaks before that happens.
    readonly property var fontPrefsUi: ["SF Pro Text", "SF Pro Display", "SF Pro", "Inter", "JetBrainsMono Nerd Font"]
    readonly property var fontPrefsMono: ["SF Mono", "JetBrainsMono Nerd Font Mono", "JetBrainsMono Nerd Font"]

    readonly property string fontFamily: _resolveFont(fontPrefsUi)
    readonly property string fontFamilyMono: _resolveFont(fontPrefsMono)

    // Bar and popup icons are Nerd Font glyphs in the private use area. They
    // must stay on a font that actually has them regardless of what the UI
    // font is, otherwise every icon in the shell renders as a tofu box.
    readonly property string fontFamilyIcons: "JetBrainsMono Nerd Font"

    function _resolveFont(prefs) {
        const available = Qt.fontFamilies()
        for (let i = 0; i < prefs.length; i++) {
            if (available.indexOf(prefs[i]) !== -1) return prefs[i]
        }
        return prefs[prefs.length - 1]
    }

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
