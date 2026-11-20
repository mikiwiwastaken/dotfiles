import QtQuick

QtObject {
    id: root

    readonly property var constants: ({
            pi: Math.PI,
            e: Math.E,
            tau: 2 * Math.PI
        })

    readonly property var functions: ({
            sqrt: Math.sqrt,
            abs: Math.abs,
            round: Math.round,
            floor: Math.floor,
            ceil: Math.ceil,
            sin: Math.sin,
            cos: Math.cos,
            tan: Math.tan,
            log: Math.log10,
            ln: Math.log,
            exp: Math.exp
        })

    // Returns the numeric result, or null if the text is not a calculation
    function evaluate(src) {
        const s = src.toLowerCase().replace(/×/g, "*").replace(/÷/g, "/").replace(/,/g, ".");

        const tokens = [];
        let i = 0;
        while (i < s.length) {
            const c = s[i];
            if (c === " ") {
                i++;
                continue;
            }

            const rest = s.slice(i);
            let m = /^(\d+\.?\d*|\.\d+)/.exec(rest);
            if (m) {
                tokens.push({
                    t: "num",
                    v: parseFloat(m[1])
                });
                i += m[1].length;
                continue;
            }

            m = /^[a-z]+/.exec(rest);
            if (m) {
                tokens.push({
                    t: "id",
                    v: m[0]
                });
                i += m[0].length;
                continue;
            }

            if ("+-*/%^()".includes(c)) {
                tokens.push({
                    t: c
                });
                i++;
                continue;
            }

            return null;
        }

        // Plain numbers and bare words are not calculations
        const hasOp = tokens.some(tk => "+-*/%^".includes(tk.t) || (tk.t === "id" && root.functions[tk.v] !== undefined));
        if (tokens.length < 2 || !hasOp)
            return null;

        let p = 0;
        const peek = () => tokens[p];
        const isOp = (...ops) => peek() !== undefined && ops.includes(peek().t);

        function expr() {
            let v = term();
            while (isOp("+", "-")) {
                const op = tokens[p++].t;
                const r = term();
                v = op === "+" ? v + r : v - r;
            }
            return v;
        }

        function term() {
            let v = unary();
            while (isOp("*", "/", "%")) {
                const op = tokens[p++].t;
                const r = unary();
                v = op === "*" ? v * r : op === "/" ? v / r : v % r;
            }
            return v;
        }

        function unary() {
            if (isOp("-")) {
                p++;
                return -unary();
            }
            if (isOp("+")) {
                p++;
                return unary();
            }
            return power();
        }

        function power() {
            const base = primary();
            if (isOp("^")) {
                p++;
                return Math.pow(base, unary());
            }
            return base;
        }

        function primary() {
            const tk = tokens[p++];
            if (!tk)
                throw "end";

            if (tk.t === "num")
                return tk.v;

            if (tk.t === "(") {
                const v = expr();
                if (!isOp(")"))
                    throw "paren";
                p++;
                return v;
            }

            if (tk.t === "id") {
                if (root.constants[tk.v] !== undefined)
                    return root.constants[tk.v];

                const f = root.functions[tk.v];
                if (!f || !isOp("("))
                    throw "id";
                p++;
                const v = expr();
                if (!isOp(")"))
                    throw "paren";
                p++;
                return f(v);
            }

            throw "token";
        }

        try {
            const v = expr();
            if (p !== tokens.length || !isFinite(v))
                return null;
            return v === 0 ? 0 : v;
        } catch (e) {
            return null;
        }
    }

    function format(v) {
        return String(parseFloat(v.toPrecision(12)));
    }
}
