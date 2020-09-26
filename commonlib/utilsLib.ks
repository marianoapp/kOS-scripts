@LAZYGLOBAL off.

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

    local function calculateBurnTime {
        parameter totalDeltaV, engineIsp, shipThrust, shipMass is ship:mass.
        
        local Ispg to engineIsp * constant:g0.
        local finalMass to shipMass / (constant:e^(totalDeltaV / Ispg)).
        local massFlowRate to shipThrust / Ispg.
        local burnTime to (shipMass - finalMass) / massFlowRate.

        return burnTime.
    }

    local function calculateThrustValue {
        parameter totalDeltaV, engineIsp, burnTime, shipMass is ship:mass.
        
        local Ispg to engineIsp * constant:g0.
        local finalMass to shipMass / (constant:e^(totalDeltaV / Ispg)).
        local shipThrust to ((shipMass - finalMass) * Ispg) / burnTime.

        return shipThrust.
    }

    return lexicon(
        "getOrbitRot", getOrbitRot@,
        "getFixRotFunction", getFixRotFunction@,
        "calculateBurnTime", calculateBurnTime@,
        "calculateThrustValue", calculateThrustValue@
    ).
}):call().