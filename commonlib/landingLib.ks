@LAZYGLOBAL off.

// import libraries
runoncepath("commonlib/simulationLib").

global landingLib to ({
    local function findOrbitImpactPosition {
        local bodyRotationAxis to body:angularvel:normalized.
        local bodyRotationVel to constant:radtodeg * body:angularvel:mag.
        local fixRot to R(0,0,0).
        local deltaTime to 10.
        local startTime to time:seconds.
        local simTime to startTime.
        local simState to list(0, V(0,0,0), V(0,0,0), V(0,0,0)).
        local simHistory to list().

        // TODO: start the search from the intersection of the orbit with the sea level surface using orbit math
        until false {
            until simState[3]:mag > simState[1]:mag {
                // rotate the position and velocity vectors to compensate for the rotating frame of reference
                set fixRot to -angleaxis(bodyRotationVel*(simTime-startTime), bodyRotationAxis).
                set simState to list(simTime,
                                     fixRot * (positionat(ship, simTime) - body:position),
                                     fixRot * (velocityat(ship, simTime):surface)).
                simState:add(body:geopositionof(simState[1] + body:position):position - body:position).
                simHistory:add(simState).
                
                set simTime to simTime + deltaTime.
            }
            if (simState[3]:mag - simState[1]:mag) > 0.5 {
                simHistory:remove(simHistory:length - 1).
                set simState to simHistory[simHistory:length - 1].
                set simTime to simState[0].
                set deltaTime to deltaTime * 0.5.
            }
            else {
                break.
            }
        }
    
        return simHistory.
    }

    // TODO: refactorize and move to a different library
    local function calculateBurnTime {
        parameter totalDeltaV, engineIsp, shipThrust.
        
        local shipMass to ship:mass.
        local Ispg to engineIsp * constant:g0.
        local finalMass to shipMass / (constant:e^(totalDeltaV / Ispg)).
        local massFlowRate to shipThrust / Ispg.
        local burnTime to (shipMass - finalMass) / massFlowRate.

        return burnTime.
    }
    
    local function calculateLanding {
        parameter shipThrust, engineIsp, altitudeMargin is 0, progressUpdater is { parameter simInfo. }.
        
        // find impact time
        local impactSim to findOrbitImpactPosition().
        local impactData to impactSim[impactSim:length - 1].

        // burn time required to kill all the speed (ignoring gravity for now)
        local burnTime to calculateBurnTime(impactData[2]:mag, engineIsp, shipThrust).
        
        // SIMULATION
        local bodyRotationAxis to body:angularvel:normalized.
        local bodyRotationVel to constant:radtodeg * body:angularvel:mag.

        local fixRot to R(0,0,0).

        local startTime to time:seconds.

        local simBurnStartTime to (impactData[0] - burnTime).
        local simBurnStartDelay to 0.
        local simOldBurnStartDelay to 0.
        local simPos to V(0,0,0).
        local simVelocity to V(0,0,0).
        local simTerrainPos to V(0,0,0).
        local simHistory to list().
        local simEndState to list().
        
        // altitude correction
        local altitudeError to 0.
        local lastAltitudeError to 0.
        local simIsGoodEnough to false.

        local deltaTimeList to list(5, 1, 0.6, 0.1, 0.04).
        local deltaTimeIndex to 0.

        // align the burn start time to the game internal simulation step
        set simBurnStartTime to (round((simBurnStartTime-startTime)*50)/50) + startTime.

        until false {
            set fixRot to -angleaxis(bodyRotationVel * (simBurnStartTime - time:seconds), bodyRotationAxis).
            set simPos to fixRot * (positionat(ship, simBurnStartTime) - body:position).
            set simVelocity to fixRot * (velocityat(ship, simBurnStartTime):surface).
            
            set simHistory to simulationLib:simulateToZeroVelocity(simBurnStartTime, simPos, simVelocity, ship:mass, shipThrust, engineIsp, body, deltaTimeList[deltaTimeIndex]).
            set simEndState to simHistory[simHistory:length-1].
            set simPos to simEndState[1].
            set simTerrainPos to body:geopositionof(simPos + body:position):position - body:position + (simPos:normalized * altitudeMargin).            
            set altitudeError to simPos:mag - simTerrainPos:mag.
            
            if abs(altitudeError) > 1 {
                if simBurnStartDelay <> 0 {
                    set simBurnStartDelay to abs(simBurnStartDelay) * max(min(altitudeError / abs(altitudeError - lastAltitudeError), 1), -1).
                }
                else {
                    set simBurnStartDelay to (altitudeError/abs(altitudeError)) * max(min(abs(altitudeError)*0.01, 10), 0.02).
                }
                // align the delay to the game internal simulation step
                set simBurnStartDelay to round(simBurnStartDelay*50)/50.
                set simBurnStartTime to simBurnStartTime + simBurnStartDelay.
            }
            else {
                set simBurnStartDelay to 0.
            }

            progressUpdater(lexicon("dt", deltaTimeList[deltaTimeIndex],
                                    "steps", simHistory:length,
                                    "velocityError", round(simEndState[2]:mag, 4),
                                    "altitudeError", round(altitudeError, 2),
                                    "burnStartDelay", simBurnStartDelay)).

            if (simBurnStartDelay = 0) or ((simBurnStartDelay + simOldBurnStartDelay) = 0) {
                set simIsGoodEnough to (simBurnStartDelay = 0) and (abs(altitudeError - lastAltitudeError) < 0.5).
                if (not simIsGoodEnough) and (deltaTimeIndex < (deltaTimeList:length - 1)) {
                    set deltaTimeIndex to deltaTimeIndex + 1.
                }
                else {
                    break.
                }
            }

            set lastAltitudeError to altitudeError.
            set simOldBurnStartDelay to simBurnStartDelay.
        }

        local burnStartTime to simBurnStartTime.
        local burnEndTime to simEndState[0].
        // align the burn end time to the game internal simulation step
        set burnEndTime to (round((burnEndTime-startTime)*50)/50) + startTime.
        
        return lexicon(
            "burnStartTime", burnStartTime,
            "burnEndTime", burnEndTime,
            "landingPosition", simPos
        ).
    }
    
    return lexicon(
        "findOrbitImpactPosition", findOrbitImpactPosition@,
        "calculateLanding", calculateLanding@
    ).
}):call().