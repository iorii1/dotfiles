pragma Singleton
import QtQuick
import Quickshell

// A small arithmetic evaluator for the launcher.
//
// Deliberately a real tokeniser and recursive-descent parser rather than
// handing the string to eval(): eval would happily run anything typed into the
// launcher, and it also accepts JavaScript that is not arithmetic at all
// (`[]+{}`, assignments, property access) and returns nonsense for it rather
// than saying "that is not a sum".
//
// caelestia uses qalc, which is better -- it does units and currency. If qalc
// is installed the launcher prefers it and this is the fallback; see
// Launcher.qml. This exists so a calculator works with no extra package.
Singleton {
    id: root

    readonly property var constants: ({ pi: Math.PI, e: Math.E, tau: Math.PI * 2 })

    readonly property var functions: ({
        sqrt: Math.sqrt, cbrt: Math.cbrt, abs: Math.abs,
        sin: Math.sin, cos: Math.cos, tan: Math.tan,
        asin: Math.asin, acos: Math.acos, atan: Math.atan,
        log: Math.log10, ln: Math.log, log2: Math.log2,
        exp: Math.exp, floor: Math.floor, ceil: Math.ceil,
        round: Math.round, sign: Math.sign
    })

    // Returns a formatted string, or "" when the input is not arithmetic.
    function evaluate(input) {
        const src = (input || "").trim().replace(/^=\s*/, "")
        if (src === "") return ""

        try {
            const tokens = root._tokenise(src)
            if (tokens.length === 0) return ""

            const state = { tokens: tokens, pos: 0 }
            const value = root._parseExpression(state)

            // Trailing junk means this was not an expression after all.
            if (state.pos !== tokens.length) return ""
            if (typeof value !== "number" || !isFinite(value)) return ""

            return root._format(value)
        } catch (e) {
            return ""
        }
    }

    // Worth showing as a result at all: needs a digit and an operator, so a
    // bare "5" or an app name never looks like a sum.
    function looksLikeMath(input) {
        const src = (input || "").trim()
        if (src === "") return false
        if (src.startsWith("=")) return true
        if (!/[0-9]/.test(src)) return false
        return /[-+*/%^()]/.test(src)
    }

    function _format(v) {
        if (Number.isInteger(v)) return String(v)
        // Kill floating-point dust (0.1+0.2) without truncating real precision.
        const rounded = parseFloat(v.toPrecision(12))
        return String(rounded)
    }

    // ---- Tokeniser ---------------------------------------------------------

    function _tokenise(src) {
        const out = []
        let i = 0
        while (i < src.length) {
            const c = src[i]

            if (c === " " || c === "\t" || c === ",") { i++; continue }

            if (c >= "0" && c <= "9" || c === ".") {
                let j = i
                while (j < src.length && (src[j] >= "0" && src[j] <= "9" || src[j] === ".")) j++
                const n = parseFloat(src.substring(i, j))
                if (isNaN(n)) throw new Error("bad number")
                out.push({ t: "num", v: n })
                i = j
                continue
            }

            if (/[a-zA-Z]/.test(c)) {
                let j = i
                while (j < src.length && /[a-zA-Z0-9_]/.test(src[j])) j++
                out.push({ t: "name", v: src.substring(i, j).toLowerCase() })
                i = j
                continue
            }

            if ("+-*/%^()".indexOf(c) !== -1) {
                out.push({ t: c })
                i++
                continue
            }

            // Anything else is not arithmetic.
            throw new Error("unexpected " + c)
        }
        return out
    }

    // ---- Parser ------------------------------------------------------------
    //
    // expression := term (('+' | '-') term)*
    // term       := power (('*' | '/' | '%') power)*
    // power      := unary ('^' power)?          -- right associative
    // unary      := ('-' | '+') unary | primary
    // primary    := number | name | name '(' expression ')' | '(' expression ')'

    function _peek(s) { return s.pos < s.tokens.length ? s.tokens[s.pos] : null }
    function _take(s) { return s.tokens[s.pos++] }

    function _parseExpression(s) {
        let left = root._parseTerm(s)
        for (;;) {
            const t = root._peek(s)
            if (!t || (t.t !== "+" && t.t !== "-")) return left
            root._take(s)
            const right = root._parseTerm(s)
            left = t.t === "+" ? left + right : left - right
        }
    }

    function _parseTerm(s) {
        let left = root._parsePower(s)
        for (;;) {
            const t = root._peek(s)
            if (!t || (t.t !== "*" && t.t !== "/" && t.t !== "%")) return left
            root._take(s)
            const right = root._parsePower(s)
            if (t.t === "*") left = left * right
            else if (t.t === "/") left = left / right
            else left = left % right
        }
    }

    function _parsePower(s) {
        const base = root._parseUnary(s)
        const t = root._peek(s)
        if (t && t.t === "^") {
            root._take(s)
            return Math.pow(base, root._parsePower(s))
        }
        return base
    }

    function _parseUnary(s) {
        const t = root._peek(s)
        if (t && (t.t === "-" || t.t === "+")) {
            root._take(s)
            const v = root._parseUnary(s)
            return t.t === "-" ? -v : v
        }
        return root._parsePrimary(s)
    }

    function _parsePrimary(s) {
        const t = root._take(s)
        if (!t) throw new Error("unexpected end")

        if (t.t === "num") return t.v

        if (t.t === "(") {
            const v = root._parseExpression(s)
            const close = root._take(s)
            if (!close || close.t !== ")") throw new Error("unclosed (")
            return v
        }

        if (t.t === "name") {
            if (t.v in root.constants) return root.constants[t.v]

            const fn = root.functions[t.v]
            if (!fn) throw new Error("unknown name " + t.v)

            const open = root._take(s)
            if (!open || open.t !== "(") throw new Error("expected (")
            const arg = root._parseExpression(s)
            const close = root._take(s)
            if (!close || close.t !== ")") throw new Error("unclosed (")
            return fn(arg)
        }

        throw new Error("unexpected token")
    }
}
