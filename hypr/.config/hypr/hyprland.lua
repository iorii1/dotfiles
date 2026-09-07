-- See https://wiki.hypr.land/Configuring/Start/

require("monitors")
require("autostart")
require("keybinds")

package.loaded["colors"] = nil
local colors = require("colors")

hl.config({
    general = {
        layout = "dwindle",

        gaps_in     = 6,
        gaps_out    = 6,
        border_size = 2,

        col = {
            active_border = "rgba(" .. colors.primary .. "ff)",
            inactive_border = "rgba(" .. colors.outline .. "ff)",
        },
    },

    decoration = {
        rounding         = 10,
        active_opacity   = 1.0,
        inactive_opacity = 0.85,

        blur = {
            enabled = true,
            size    = 8,
            passes  = 2,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.config({
    dwindle = {
        preserve_split = true,
    },
})

hl.curve("mangoOpen",    { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
hl.curve("mangoClose",   { type = "bezier", points = { {0.4, 0},  {1, 1} } })
hl.curve("mangoFocus",   { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
hl.curve("mangoFadeOut", { type = "bezier", points = { {0.4, 0},  {1, 1} } })

hl.animation({ leaf = "windows",    enabled = true, speed = 2.6, bezier = "mangoOpen",  style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.0, bezier = "mangoClose", style = "popin 80%" })
hl.animation({ leaf = "border",     enabled = true, speed = 1.4, bezier = "mangoFocus" })
hl.animation({ leaf = "fade",       enabled = true, speed = 2.6, bezier = "mangoOpen" })
hl.animation({ leaf = "fadeOut",    enabled = true, speed = 2.0, bezier = "mangoFadeOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.3, bezier = "mangoOpen",  style = "slide" })
hl.animation({ leaf = "layers",     enabled = true, speed = 2.6, bezier = "mangoOpen",  style = "popin 80%" })

-- Rofi and mako slide down from the bar edge instead of the default fade
hl.layer_rule({ name = "rofi-slide",          match = { namespace = "^rofi$" },          animation = "slide", blur = true })
hl.layer_rule({ name = "notifications-slide", match = { namespace = "^notifications$" }, animation = "slide", blur = true })
