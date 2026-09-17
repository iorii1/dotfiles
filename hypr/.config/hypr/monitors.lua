-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
--
-- The two entries below are this machine's outputs -- replace them with your
-- own (`hyprctl monitors` lists the names). The catch-all first means any
-- output not named here still comes up at its preferred mode instead of
-- being left unconfigured.

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1920x1080@180",
    position = "0x0",
    scale    = 1,
})

hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@60",
    position = "1920x0",
    scale    = 1.25,
})
