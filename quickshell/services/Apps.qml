pragma Singleton
import QtQuick
import Quickshell

// The launcher's index.
//
// Matching used to be `name.includes(q) || comment.includes(q)` over an
// alphabetically sorted list, which stayed alphabetical as you typed -- so the
// thing you wanted was rarely the thing Return would launch. This scores
// instead, over a wider set of fields, and remembers what you actually pick.
Singleton {
    id: root

    property var entries: []

    // id -> { count, last }. Kept small and written back debounced by Persist.
    property var usage: ({})

    Persist {
        id: store
        fileName: "launcher.json"
        defaults: ({ usage: {} })
        onLoaded: root.usage = store.value("usage") || ({})
    }

    // keywords and categories come back as string *lists* despite the type
    // info advertising QString, so everything that feeds the matcher goes
    // through here rather than assuming .toLowerCase() exists.
    function _text(v) {
        if (v === undefined || v === null) return ""
        if (Array.isArray(v)) return v.join(" ").toLowerCase()
        return String(v).toLowerCase()
    }

    function _refresh() {
        const list = []
        const apps = DesktopEntries.applications.values
        for (let i = 0; i < apps.length; i++) {
            const e = apps[i]
            if (e.noDisplay) continue

            list.push({
                id: e.id,
                name: e.name,
                comment: e.comment || "",
                icon: e.icon || "",
                entry: e,
                action: null,
                // Everything worth matching against, lowercased once here
                // rather than on every keystroke for every app.
                haystack: {
                    name: root._text(e.name),
                    generic: root._text(e.genericName),
                    keywords: root._text(e.keywords),
                    categories: root._text(e.categories),
                    comment: root._text(e.comment)
                }
            })

            // "New Private Window", "Open in new workspace" and friends. They
            // only surface once the query already matches, so they never pad
            // out the idle list.
            const actions = e.actions || []
            for (let a = 0; a < actions.length; a++) {
                const act = actions[a]
                list.push({
                    id: e.id + ":" + act.id,
                    name: act.name,
                    comment: e.name,
                    icon: act.icon || e.icon || "",
                    entry: e,
                    action: act,
                    haystack: {
                        name: root._text(act.name),
                        generic: root._text(e.name),
                        keywords: "",
                        categories: "",
                        comment: ""
                    }
                })
            }
        }
        list.sort((a, b) => a.name.localeCompare(b.name))
        root.entries = list
    }

    // Subsequence match: every character of the query must appear in order.
    // Returns a score, or -1 for no match. Contiguous runs and matches that
    // start a word score higher, which is what makes "fx" find Firefox and
    // "gimp" beat "GNOME Image Manipulation" on the same letters.
    function _scoreField(text, q) {
        if (!text || !q) return -1
        if (text === q) return 1000
        if (text.startsWith(q)) return 800 - Math.min(100, text.length)

        const idx = text.indexOf(q)
        if (idx === 0) return 700
        if (idx > 0) {
            // A whole-word hit in the middle beats a scattered subsequence.
            const boundary = text[idx - 1] === " " || text[idx - 1] === "-" || text[idx - 1] === "."
            return (boundary ? 600 : 400) - Math.min(100, idx)
        }

        let score = 0
        let ti = 0
        let run = 0
        for (let qi = 0; qi < q.length; qi++) {
            const c = q[qi]
            let found = -1
            while (ti < text.length) {
                if (text[ti] === c) { found = ti; break }
                ti++
            }
            if (found === -1) return -1

            const startsWord = found === 0
                || text[found - 1] === " " || text[found - 1] === "-" || text[found - 1] === "."
            score += startsWord ? 20 : 4
            run = (found === ti && qi > 0) ? run + 1 : 0
            score += run * 6
            ti = found + 1
        }
        return Math.max(1, score - Math.min(50, text.length))
    }

    // Field weights: what a thing is called matters far more than what its
    // .desktop file says about it.
    function score(item, q) {
        const h = item.haystack
        const candidates = [
            [h.name, 1.0],
            [h.generic, 0.6],
            [h.keywords, 0.5],
            [h.comment, 0.35],
            [h.categories, 0.25]
        ]

        let best = -1
        for (let i = 0; i < candidates.length; i++) {
            const s = root._scoreField(candidates[i][0], q)
            if (s >= 0) best = Math.max(best, s * candidates[i][1])
        }
        if (best < 0) return -1

        // An action can never outrank the app it belongs to on an equal match.
        if (item.action) best *= 0.9

        return best + root.frecencyBonus(item.id)
    }

    // Recently-and-often wins, with recency decaying over about a fortnight so
    // an app used heavily last month stops shadowing today's.
    function frecencyBonus(id) {
        const u = root.usage[id]
        if (!u) return 0
        const ageDays = (Date.now() - (u.last || 0)) / 86400000
        const recency = Math.max(0, 1 - ageDays / 14)
        return Math.min(300, (u.count || 0) * 25) * (0.4 + 0.6 * recency)
    }

    function filtered(query) {
        const q = (query || "").trim().toLowerCase()

        if (!q) {
            // Idle list: most-used first, then alphabetical. Actions stay out
            // of it -- they are a refinement of a search, not a starting point.
            const base = root.entries.filter(e => !e.action)
            return base.slice().sort((a, b) => {
                const d = root.frecencyBonus(b.id) - root.frecencyBonus(a.id)
                return d !== 0 ? d : a.name.localeCompare(b.name)
            })
        }

        const scored = []
        for (let i = 0; i < root.entries.length; i++) {
            const s = root.score(root.entries[i], q)
            if (s >= 0) scored.push({ item: root.entries[i], s: s })
        }
        scored.sort((a, b) => b.s !== a.s ? b.s - a.s : a.item.name.localeCompare(b.item.name))
        return scored.map(x => x.item)
    }

    // A desktop entry by its id, or null. Pins are stored as ids, so this is
    // how they are resolved back to something launchable.
    function entryById(id) {
        const apps = DesktopEntries.applications.values
        for (let i = 0; i < apps.length; i++) {
            if (apps[i].id === id) return apps[i]
        }
        return null
    }

    // The desktop entry a running window belongs to, or null.
    //
    // startupClass exists precisely for this and is what to trust when it is
    // set -- Spotify's window says "Spotify" while its entry id is
    // "spotify-launcher", and only startupClass connects the two. Everything
    // else falls back to the id, then to the name with spaces removed.
    function entryForAppId(appId) {
        if (!appId) return null
        const want = String(appId).toLowerCase()
        const apps = DesktopEntries.applications.values

        for (let i = 0; i < apps.length; i++) {
            const sc = apps[i].startupClass
            if (sc && String(sc).toLowerCase() === want) return apps[i]
        }
        for (let i = 0; i < apps.length; i++) {
            if (String(apps[i].id).toLowerCase() === want) return apps[i]
        }
        for (let i = 0; i < apps.length; i++) {
            if (String(apps[i].name).toLowerCase().replace(/ /g, "") === want.replace(/ /g, "")) return apps[i]
        }
        return null
    }

    function launchEntry(entry) {
        if (!entry) return
        root._recordUse(entry.id)
        if (typeof entry.execute === "function") entry.execute()
    }

    function launch(item) {
        if (!item) return
        root._recordUse(item.id)

        if (item.action && typeof item.action.execute === "function") {
            item.action.execute()
        } else if (item.entry && typeof item.entry.execute === "function") {
            item.entry.execute()
        }
    }

    function _recordUse(id) {
        const next = Object.assign({}, root.usage)
        const prev = next[id] || { count: 0, last: 0 }
        next[id] = { count: (prev.count || 0) + 1, last: Date.now() }
        root.usage = next
        store.set("usage", next)
    }

    Component.onCompleted: root._refresh()

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { root._refresh() }
    }
}
