@LAZYGLOBAL off.

global simulationLib to ({
    local function simulateToZeroVelocity {
        parameter startTime, startPos, startVelocity, startMass, shipThrust, engineIsp, currentBody, minDt.

        local maxDt to minDt * 5.
        local dt to maxDt.
        local hdt to dt / 2.
        local simTime to startTime.
        local simMass to startMass.
        local simOldVel to startVelocity.
        local pos1 to startPos.
        local vel1 to startVelocity.
        local acc1 to V(0,0,0).
        local acc2 to V(0,0,0).
        local pos2 to V(0,0,0).
        local vel2 to V(0,0,0).
        local simState to list(simTime, pos1, vel1, simMass).
        local simHistory to list(simState).

        local bodyAngularVel to currentBody:angularvel.
        local bodyMu to currentBody:mu.
        local massFlowRate to shipThrust / (engineIsp * constant:g0).
        local mfrdt to massFlowRate * dt.

        local adaptiveDt to true.
        local stepError to 0.

        local function calculateAcceleration {
            parameter pos, vel, massTemp.

            return (-pos:normalized) * (bodyMu / pos:sqrmagnitude) +    // gravity
                   (-vel:normalized) * (shipThrust / massTemp) +        // thrust
                   (-2 * vcrs(bodyAngularVel, vel)) +                   // coriolis acceleration
                   vcrs(bodyAngularVel, vcrs(bodyAngularVel, -pos)).    // centrifugal acceleration
        }

        local function repeatLastStep {
            if simHistory:length > 1 {
                simHistory:remove(simHistory:length - 1).
                set simState to simHistory[simHistory:length - 1].
                set simTime to simState[0].
                set pos1 to simState[1].
                set vel1 to simState[2].
                set simMass to simState[3].
                if simHistory:length > 1 {
                    set simOldVel to simHistory[simHistory:length - 2][2].
                }
            }
        }

        until false {
            until vel1:mag < 0.1 or (vel1:mag > simOldVel:mag) or abs(vang(vel1, simOldVel)) > 5 {
                set simOldVel to vel1.

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
                            set dt to round(min(dt*1.5, 2), maxDt).
                        }
                        else {
                            set dt to round(max(dt*0.75, minDt), 2).
                            // repeat last step with new dt
                            repeatLastStep().
                        }
                        set hdt to dt / 2.
                        set mfrdt to massFlowRate * dt.
                    }
                }
            }
            if (vel1:mag >= 0.1) and (dt > 0.02) {
                set dt to round(max(dt*0.75, 0.02), 2).
                set hdt to dt / 2.
                set mfrdt to massFlowRate * dt.
                set adaptiveDt to false.
                // repeat last step with new dt
                repeatLastStep().
            }
            else {
                break.
            }
        }

        return simHistory.
    }

    return lexicon(
        "simulateToZeroVelocity", simulateToZeroVelocity@
    ).
}):call().