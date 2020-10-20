@LAZYGLOBAL off.

global simulationLib to ({
    local function getCalcAccRetroThrustFunction {
        parameter currentBody, shipThrust.

        local bodyAngularVel to currentBody:angularvel.
        local bodyMu to currentBody:mu.

        return {
            parameter pos, vel, massParam.

            return (-pos:normalized) * (bodyMu / pos:sqrmagnitude) +    // gravity
                   (-2 * vcrs(bodyAngularVel, vel)) +                   // coriolis
                   vcrs(bodyAngularVel, vcrs(bodyAngularVel, -pos)) +   // centrifugal
                   (-vel:normalized) * (shipThrust / massParam).        // thrust
        }.
    }

    local function getCalcAccFixedDirThrustFunction {
        parameter currentBody, shipThrust, thrustVector.

        local bodyAngularVel to currentBody:angularvel.
        local bodyMu to currentBody:mu.
        set thrustVector to thrustVector:normalized.

        return {
            parameter pos, vel, massParam.

            return (-pos:normalized) * (bodyMu / pos:sqrmagnitude) +    // gravity
                   (-2 * vcrs(bodyAngularVel, vel)) +                   // coriolis
                   vcrs(bodyAngularVel, vcrs(bodyAngularVel, -pos)) +   // centrifugal
                   thrustVector * (shipThrust / massParam).             // thrust
        }.
    }

    local function getCalcAccNoThrustFunction {
        parameter currentBody.

        local bodyAngularVel to currentBody:angularvel.
        local bodyMu to currentBody:mu.

        return {
            parameter pos, vel, massParam.

            return (-pos:normalized) * (bodyMu / pos:sqrmagnitude) +    // gravity
                   (-2 * vcrs(bodyAngularVel, vel)) +                   // coriolis
                   vcrs(bodyAngularVel, vcrs(bodyAngularVel, -pos)).    // centrifugal
        }.
    }

    local function simulateToZeroVelocity {
        parameter startTime, startPos, startVelocity, startMass, shipThrust, engineIsp, currentBody, minDt.

        local calculateAcceleration to getCalcAccRetroThrustFunction(currentBody, shipThrust).

        local loopCondition to {
            parameter simState, simPreviousState.
            return not (simState[2]:mag > 0.1 and simState[2]:mag <= simPreviousState[2]:mag and vang(simState[2], simPreviousState[2]) <= 5).
        }.

        local refineCondition to {
            parameter simState.
            return simState[2]:mag >= 0.1.
        }.

        return simulate(lexicon("startTime", startTime, "startPos", startPos, "startVelocity", startVelocity, "startMass", startMass),
                        lexicon("shipThrust", shipThrust, "engineIsp", engineIsp),
                        lexicon("minDt", minDt, "calculateAcceleration", calculateAcceleration, "loopCondition", loopCondition, "refineCondition", refineCondition)).
    }

    local function simulateThrust {
        parameter startTime, startPos, startVelocity, startMass, thrustVector, endTime, shipThrust, engineIsp, currentBody, minDt, maxDt.

        local calculateAcceleration to getCalcAccFixedDirThrustFunction(currentBody, shipThrust, thrustVector).

        local function loopCondition {
            parameter simState, simPreviousState.
            return simState[0] >= endTime.
        }

        local function refineCondition {
            parameter simState.
            return abs(simState[0] - endTime) >= 0.01.
        }

        return simulate(lexicon("startTime", startTime, "startPos", startPos, "startVelocity", startVelocity, "startMass", startMass),
                        lexicon("shipThrust", shipThrust, "engineIsp", engineIsp),
                        lexicon("minDt", minDt, "maxDt", maxDt, "calculateAcceleration", calculateAcceleration@, "loopCondition", loopCondition@, "refineCondition", refineCondition@)).

    }

    local function simulateCoasting {
        parameter startTime, startPos, startVelocity, startMass, endTime, currentBody, minDt.

        local calculateAcceleration to getCalcAccNoThrustFunction(currentBody).

        local function loopCondition {
            parameter simState, simPreviousState.
            return simState[0] >= endTime.
        }

        local function refineCondition {
            parameter simState.
            return abs(simState[0] - endTime) >= 0.01.
        }

        return simulate(lexicon("startTime", startTime, "startPos", startPos, "startVelocity", startVelocity, "startMass", startMass),
                        lexicon("shipThrust", 0, "engineIsp", 1),
                        lexicon("minDt", minDt, "calculateAcceleration", calculateAcceleration@, "loopCondition", loopCondition@, "refineCondition", refineCondition@)).

    }

    local function simulate {
        parameter startState, shipInfo, simulationSettings.

        local minDt to simulationSettings:minDt.
        local maxDt to choose simulationSettings:maxDt if simulationSettings:haskey("maxDt") else minDt * 5.
        local dt to minDt.
        local hdt to dt / 2.
        local simTime to startState:startTime.
        local simMass to startState:startMass.
        local pos1 to startState:startPos.
        local vel1 to startState:startVelocity.
        local acc1 to V(0,0,0).
        local acc2 to V(0,0,0).
        local pos2 to V(0,0,0).
        local vel2 to V(0,0,0).
        local simState to list(simTime, pos1, vel1, simMass).
        local simPreviousState to simState.
        local simHistory to list(simState).

        local massFlowRate to shipInfo:shipThrust / (shipInfo:engineIsp * constant:g0).
        local mfrdt to massFlowRate * dt.

        local adaptiveDt to true.
        local stepError to 0.

        local calculateAcceleration to simulationSettings:calculateAcceleration.
        local loopCondition to simulationSettings:loopCondition.
        local refineCondition to simulationSettings:refineCondition.

        local function repeatLastStep {
            if simHistory:length > 1 {
                simHistory:remove(simHistory:length - 1).
                set simState to simHistory[simHistory:length - 1].
                set simTime to simState[0].
                set pos1 to simState[1].
                set vel1 to simState[2].
                set simMass to simState[3].
                if simHistory:length > 1 {
                    set simPreviousState to simHistory[simHistory:length - 2].
                }
            }
        }

        until false {
            until loopCondition(simState, simPreviousState) {
                set simPreviousState to simState.

                // calculate accelerations
                set acc1 to calculateAcceleration(pos1, vel1, simMass).
                set pos2 to pos1 + (dt * vel1).
                set vel2 to vel1 + (dt * acc1).
                set simMass to simMass - mfrdt.
                set acc2 to calculateAcceleration(pos2, vel2, simMass).

                // calculate new position and velocity
                set pos1 to pos1 + hdt * (vel1 + vel2).
                set vel1 to vel1 + hdt * (acc1 + acc2).

                set simTime to simTime + dt.

                // save history
                set simState to list(simTime, pos1, vel1, simMass).
                simHistory:add(simState).

                // dt correction
                if adaptiveDt {
                    set stepError to (hdt * (pos2 - pos1)):mag.
                    if (stepError < 0.1 and dt < maxDt) or (stepError > 1 and dt > minDt) {
                        if stepError < 0.1 {
                            set dt to round(min(dt*1.5, maxDt), 2).
                        }
                        else {
                            set dt to round(max(dt*0.75, minDt), 2).
                            repeatLastStep().
                        }
                        set hdt to dt / 2.
                        set mfrdt to massFlowRate * dt.
                    }
                }
            }
            if refineCondition(simState) and (dt > 0.02) {
                set dt to round(max(dt*0.75, 0.02), 2).
                set hdt to dt / 2.
                set mfrdt to massFlowRate * dt.
                set adaptiveDt to false.
                repeatLastStep().
            }
            else {
                break.
            }
        }

        return simHistory.
    }

    return lexicon(
        "simulateToZeroVelocity", simulateToZeroVelocity@,
        "simulateThrust", simulateThrust@,
        "simulateCoasting", simulateCoasting@
    ).
}):call().