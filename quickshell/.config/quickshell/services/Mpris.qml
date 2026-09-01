pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    readonly property MprisPlayer activePlayer: {
        const players = Mpris.players.values
        const playing = players.find(p => p.isPlaying)
        if (playing) return playing
        const controllable = players.find(p => p.canControl)
        if (controllable) return controllable
        return players.length > 0 ? players[0] : null
    }

    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: activePlayer ? activePlayer.isPlaying : false
    readonly property string title: activePlayer ? (activePlayer.trackTitle || "") : ""
    readonly property string artist: activePlayer ? (activePlayer.trackArtist || "") : ""
    readonly property string artUrl: activePlayer ? (activePlayer.trackArtUrl || "") : ""
    readonly property string identity: activePlayer ? (activePlayer.identity || "") : ""
    readonly property string desktopEntry: activePlayer ? (activePlayer.desktopEntry || "") : ""
    readonly property real position: activePlayer ? activePlayer.position : 0
    readonly property real length: activePlayer ? activePlayer.length : 0
    readonly property bool canGoNext: activePlayer ? activePlayer.canGoNext : false
    readonly property bool canGoPrevious: activePlayer ? activePlayer.canGoPrevious : false

    // Keep position ticking while playing so a progress bar could bind to it.
    Timer {
        interval: 1000
        repeat: true
        running: root.hasPlayer && root.isPlaying
        onTriggered: if (root.activePlayer) root.activePlayer.positionChanged()
    }

    function playPause() {
        if (activePlayer && activePlayer.canTogglePlaying) activePlayer.togglePlaying()
    }
    function next() {
        if (activePlayer && activePlayer.canGoNext) activePlayer.next()
    }
    function previous() {
        if (activePlayer && activePlayer.canGoPrevious) activePlayer.previous()
    }
}
