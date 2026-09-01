pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property real volume: sink?.audio?.volume !== undefined ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool isMuted: sink?.audio?.muted ?? false

    readonly property real inputVolume: source?.audio?.volume !== undefined ? Math.round(source.audio.volume * 100) : 0
    readonly property bool isInputMuted: source?.audio?.muted ?? false

    readonly property var sinks: Pipewire.ready
        ? Pipewire.nodes.values.filter(n => n.audio && !n.isStream
            && (n.type & PwNodeType.AudioSink) === PwNodeType.AudioSink)
        : []

    readonly property var sources: Pipewire.ready
        ? Pipewire.nodes.values.filter(n => n.audio && !n.isStream
            && (n.type & PwNodeType.AudioSource) === PwNodeType.AudioSource
            && !n.name.endsWith(".monitor"))
        : []

    function deviceLabel(node) {
        return node.description || node.nickname || node.name
    }

    function setVolume(pct) {
        if (sink?.audio) sink.audio.volume = Math.max(0, Math.min(150, pct)) / 100
    }

    function toggleMute() {
        if (sink?.audio) sink.audio.muted = !sink.audio.muted
    }

    function setInputVolume(pct) {
        if (source?.audio) source.audio.volume = Math.max(0, Math.min(150, pct)) / 100
    }

    function toggleInputMute() {
        if (source?.audio) source.audio.muted = !source.audio.muted
    }

    function setSink(node) {
        if (node) Pipewire.preferredDefaultAudioSink = node
    }

    function setSource(node) {
        if (node) Pipewire.preferredDefaultAudioSource = node
    }
}
