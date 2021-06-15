@LAZYGLOBAL off.

// #EXTERNAL_IDS utilsLib
global utilsLib to ({
    local function getOrbitRot {       
        parameter UT.

        local pos to (positionat(ship, UT) - body:position).
        local vel to (velocityat(ship, UT):orbit).
        return lookdirup(vel, vcrs(vel, pos)).
    }

    local function getFixRotFunction {
        local bodyRotationAxis to body:angularvel:normalized.
        local bodyRotationVel to constant:radtodeg * body:angularvel:mag.
        return {
            parameter UT, reference is time:seconds.
            return -angleaxis(bodyRotationVel * (UT - reference), bodyRotationAxis).
        }.
    }

    local function memoryLog {
        parameter fileName.

        local data to list().

        local function format {
            parameter value.
            
            if (value:istype("Vector")) {
                return list(value:X, value:Y, value:Z):join(",").
            }
            else {
                return value.
            }
        }

        local function append {
            parameter value.
            data:add(format(value)).
        }

        local function appendMany {
            parameter valueList.

            local lineData to list().
            
            for value in valueList {
                lineData:add(format(value)).
            }

            data:add(lineData:join(",")).
        }

        local function flush {
            log data:join(char(10)) to fileName.
        }

        return lexicon(
            "append", append@,
            "appendMany", appendMany@,
            "flush", flush@
        ).
    }

    return lexicon(
        "getOrbitRot", getOrbitRot@,
        "getFixRotFunction", getFixRotFunction@,
        "memoryLog", memoryLog@
    ).
}):call().