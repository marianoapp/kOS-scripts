@LAZYGLOBAL off.

// #EXTERNAL_IDS maneuverLib

global maneuverLib to ({
    local function getCircularization {
        parameter UT.

        local pos to (positionat(ship, UT) - body:position).
        local vel to (velocityat(ship, UT):orbit).

        local speed to sqrt(body:mu / pos:mag).
        local desiredVel to vxcl(pos, vel):normalized * speed.

        return desiredVel - vel.
    }

    return lex(
        "getCircularization", getCircularization@
    ).
}):call().