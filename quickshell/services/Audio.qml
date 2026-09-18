pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Audio, over PipeWire.
//
// The shell had no audio service at all: the OSD shelled out to `wpctl
// get-volume` and scraped stdout, once, *after* a Hyprland keybind had already
// changed the value. That meant no volume widget, no device switching, no
// per-app mixer, and no OSD at all when something other than those keybinds
// moved the volume.
//
// Node categories, from the two flags PipeWire gives us:
//   isSink && !isStream  -> an output device   (speakers, headphones)
//  !isSink && !isStream  -> an input device    (microphones)
//   isSink &&  isStream  -> something playing  (Firefox, a music player)
//  !isSink &&  isStream  -> something recording (cava, a call)
//
// `volume` here is the same 0..1 linear scale `wpctl` prints, so a percentage
// shown in the bar matches what every other tool on the system reports.
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property bool ready: Pipewire.ready

    readonly property real volume: (root.sink && root.sink.audio) ? root.sink.audio.volume : 0
    readonly property bool muted: (root.sink && root.sink.audio) ? root.sink.audio.muted : true

    readonly property real micVolume: (root.source && root.source.audio) ? root.source.audio.volume : 0
    readonly property bool micMuted: (root.source && root.source.audio) ? root.source.audio.muted : true

    readonly property var sinks: root._select(true, false)
    readonly property var sources: root._select(false, false)
    readonly property var streams: root._select(true, true)

    function _select(wantSink, wantStream) {
        const out = []
        const nodes = Pipewire.nodes.values
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i]
            if (!n.audio) continue
            if (n.isSink !== wantSink || n.isStream !== wantStream) continue
            out.push(n)
        }
        return out
    }

    // Binding the sub-objects is not optional: without a tracker holding them,
    // a node's `audio` properties never update and the mixer sits frozen at
    // whatever it read first.
    PwObjectTracker {
        objects: {
            const list = []
            if (root.sink) list.push(root.sink)
            if (root.source) list.push(root.source)
            return list
                .concat(root.sinks)
                .concat(root.sources)
                .concat(root.streams)
        }
    }

    // ---- Naming -----------------------------------------------------------

    // A device's nickname ("ALC3246 Analog") reads better in a menu than its
    // full description ("Built-in Audio Analog Stereo"); a stream has neither
    // and has to be named after the app that owns it.
    function deviceName(node) {
        if (!node) return ""
        return node.nickname || node.description || node.name || "Unknown device"
    }

    function streamName(node) {
        if (!node) return ""
        const p = node.properties || ({})
        return p["application.name"]
            || p["media.name"]
            || node.description
            || node.name
            || "Unknown"
    }

    // ---- Output -----------------------------------------------------------

    function setVolume(v) {
        if (!root.sink || !root.sink.audio) return
        root.sink.audio.volume = Math.max(0, Math.min(1, v))
    }

    function stepVolume(delta) {
        root.setVolume(root.volume + delta)
    }

    function setMuted(m) {
        if (!root.sink || !root.sink.audio) return
        root.sink.audio.muted = m
    }

    function toggleMute() {
        root.setMuted(!root.muted)
    }

    function setDefaultSink(node) {
        if (node) Pipewire.preferredDefaultAudioSink = node
    }

    // ---- Input ------------------------------------------------------------

    function setMicVolume(v) {
        if (!root.source || !root.source.audio) return
        root.source.audio.volume = Math.max(0, Math.min(1, v))
    }

    function setMicMuted(m) {
        if (!root.source || !root.source.audio) return
        root.source.audio.muted = m
    }

    function toggleMicMute() {
        root.setMicMuted(!root.micMuted)
    }

    function setDefaultSource(node) {
        if (node) Pipewire.preferredDefaultAudioSource = node
    }

    // ---- Per-stream -------------------------------------------------------

    function setStreamVolume(node, v) {
        if (!node || !node.audio) return
        node.audio.volume = Math.max(0, Math.min(1, v))
    }

    function toggleStreamMute(node) {
        if (!node || !node.audio) return
        node.audio.muted = !node.audio.muted
    }

    // ---- Presentation -----------------------------------------------------

    // The glyph the bar and the OSD both show, so they never disagree.
    // Only these three speaker glyphs exist in JetBrainsMono Nerd Font -- there
    // is no separate "muted" speaker (U+F6A9 is absent, checked against the
    // installed font), so volume-off doubles as it.
    function iconFor(level, isMuted) {
        if (isMuted || level <= 0.001) return ""
        if (level < 0.5) return ""
        return ""
    }

    function micIconFor(isMuted) {
        return isMuted ? "" : ""
    }
}
