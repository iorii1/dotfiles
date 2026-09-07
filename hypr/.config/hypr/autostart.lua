-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
    hl.exec_cmd("quickshell")
    hl.exec_cmd("/usr/lib/xfce-polkit/xfce-polkit")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("hypridle")

    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
