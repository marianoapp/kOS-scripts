@LAZYGLOBAL off.

global optimizationLib to ({
    local function scalarErrorMinNR {
        parameter deltaFallbackFunc.

        local initialized to false.
        local x0 to 0.
        local y0 to 0.

        local function updateGetDelta {
            parameter x1, y1.

            local delta to 0.

            if initialized and x1 <> x0 and y1 <> y0 {
                // delta = -(y1 / yPrime)  ->  yPrime = (y1-y0)/(x1-x0)
                set delta to -(y1 / ((y1-y0)/(x1-x0))).
            }
            else {
                set initialized to true.
                set delta to deltaFallbackFunc(x1, y1).
            }

            set x0 to x1.
            set y0 to y1.

            return delta.
        }

        local function update {
            parameter x1, y1.
            return x1 + updateGetDelta(x1, y1).
        }

        local function reset {
            set x0 to 0.
            set y0 to 0.
            set initialized to false.
        }

        return lexicon(
            "updateGetDelta", updateGetDelta@,
            "update", update@,
            "reset", reset@
        ).
    }

    return lexicon(
        "scalarErrorMinNR", scalarErrorMinNR@
    ).
}):call().