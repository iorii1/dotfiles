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

    // ---- Shape ------------------------------------------------------------

    // Multiplier over every corner in the shell. 0 gives square corners,
    // 1.5 gives a much softer, more rounded look, with no other edits.
    //
    // Writable, and driven from the settings app via BarConfig -- it was always
    // documented as a knob, it just had no way to turn it.
    property real roundingScale: 1.0

    readonly property int radiusSmall: Math.round(8 * roundingScale)
    readonly property int radiusNormal: Math.round(12 * roundingScale)
    readonly property int radiusLarge: Math.round(18 * roundingScale)

    readonly property int spacingSmall: 6
    readonly property int spacingNormal: 10
    readonly property int spacingLarge: 16

    // The bar's *design default*. The live values are BarConfig.barHeight and
    // BarConfig.barMargin, which start from these and are then editable at
    // runtime from the settings app -- so widgets read BarConfig, not this.
    readonly property int barHeight: 34
    readonly property int barMargin: 6

    // ---- Motion -----------------------------------------------------------

    // Every duration below derives from this. Raise it to slow the whole
    // shell down, lower it to make it snap; nothing animates off-token.
    // Writable for the same reason as roundingScale above.
    property real animScale: 1.0

    // Sub-perceptual feedback: press-down, ripple, cursor-follow.
    readonly property int animInstant: Math.round(90 * animScale)
    // Hover, colour and small position changes.
    readonly property int animFast: Math.round(150 * animScale)
    // The default: anything entering, leaving or resizing.
    readonly property int animNormal: Math.round(250 * animScale)
    // Large surfaces, and settles that follow an overshoot.
    readonly property int animSlow: Math.round(400 * animScale)
    // Ambient motion that runs on its own: a spinner, a charging sweep.
    readonly property int animAmbient: Math.round(700 * animScale)
    // The slow breath of a glow or a pulse ring, so they all breathe together.
    readonly property int animPulse: Math.round(1100 * animScale)
    //
    // Between them these cover *interaction* motion: anything answering the
    // pointer, a state change, or a surface arriving. The decorative loops --
    // weather particles, the battery gauge filling, a marquee scrolling --
    // keep their own timings on purpose. They are choreography, not response,
    // and forcing them onto these would only make them wrong.

    // Material 3's easing set as bezier control points, for
    // `easing.type: Easing.Bezier; easing.bezierCurve: Appearance.easeStandard`.
    // Standard for anything that starts and ends on screen, decelerate for
    // things arriving, accelerate for things leaving.
    readonly property var easeStandard: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var easeDecelerate: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    readonly property var easeAccelerate: [0.3, 0.0, 0.8, 0.15, 1.0, 1.0]

    // Gesture feedback, in two tiers: the plain tokens for icon-sized targets,
    // the subtle ones for anything card- or row-sized, where the same
    // percentage of a much larger box reads as a lurch.
    readonly property real hoverScale: 1.08
    readonly property real pressScale: 0.88
    readonly property real hoverScaleSubtle: 1.02
    readonly property real pressScaleSubtle: 0.96

    // Distinct from pressScale: that is the steady size while a target is held
    // down, this is the dip of the click animation that plays on release, and
    // the two multiply.
    readonly property real pressDip: 0.92

    // Entrances. A popup card scales up from popupFromScale; the items inside
    // it pop from popFromScale and stagger, capped so a long list still
    // finishes arriving in about a fifth of a second.
    readonly property real popupFromScale: 0.94
    readonly property real popFromScale: 0.85
    readonly property real overshootCard: 1.15
    readonly property real overshootPop: 1.4
    readonly property int staggerStep: 22
    readonly property int staggerMax: 200

    // A delegate's index goes to -1 while it is being destroyed, hence the floor.
    function staggerDelay(index) {
        return Math.max(0, Math.min(index * root.staggerStep, root.staggerMax))
    }

    // ---- Surfaces ---------------------------------------------------------

    // Hyprland blurs the shell's own layers (see the layer rules in
    // hyprland.lua), which only shows if the surfaces let it through: base is
    // a card's own background, layer is for the rows and tiles stacked on top
    // of it, which at full opacity would mud the blur back out.
    readonly property real surfaceOpacity: 0.85
    readonly property real layerOpacity: 0.4

    readonly property color shadowColor: "#66000000"
    readonly property real elevationOpacity: 0.28
    readonly property real elevationBlur: 0.4
    readonly property int elevationOffset: 5
}
