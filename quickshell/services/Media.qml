pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Which player the bar widget and the media popup are talking about.
//
// Both files used to contain the same loop -- "the first player in Playing
// state, else the first player at all" -- copied between them. With a browser
// and a music player both open you got whichever the loop happened to reach,
// there was no way to choose, and because the logic lived in two places the
// widget and the popup could disagree about what was playing.
Singleton {
    id: root

    // Players worth offering. A player with no title is usually one that has
    // registered on the bus but has not loaded anything yet.
    readonly property var players: {
        const out = []
        const list = Mpris.players.values
        for (let i = 0; i < list.length; i++) {
            if (list[i].trackTitle && list[i].trackTitle !== "") out.push(list[i])
        }
        return out
    }

    // A pinned choice, by bus name. Empty means "follow whatever is playing",
    // which is the old behaviour and stays the default.
    property string pinned: ""

    readonly property var active: {
        const list = root.players
        if (list.length === 0) return null

        // A pin holds even while that player is paused -- that is the point of
        // pinning. It is ignored rather than cleared if the player goes away,
        // so it takes effect again should the same one come back.
        if (root.pinned !== "") {
            for (let i = 0; i < list.length; i++) {
                if (list[i].dbusName === root.pinned) return list[i]
            }
        }

        for (let i = 0; i < list.length; i++) {
            if (list[i].playbackState === MprisPlaybackState.Playing) return list[i]
        }
        return list[0]
    }

    readonly property bool hasActive: root.active !== null
    readonly property bool playing: root.hasActive
        && root.active.playbackState === MprisPlaybackState.Playing

    // True once there is an actual choice to make.
    readonly property bool hasChoice: root.players.length > 1

    function select(player) {
        root.pinned = player ? player.dbusName : ""
    }

    function clearSelection() {
        root.pinned = ""
    }

    function isActive(player) {
        return !!player && root.active === player
    }

    // "Firefox", "Spotify". identity is what the player calls itself; the bus
    // name is the fallback for one that does not say.
    function displayName(player) {
        if (!player) return ""
        return player.identity || player.dbusName || "Unknown player"
    }
}
