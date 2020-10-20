@LAZYGLOBAL off.

// import libraries
runoncepath("/commonlib/orbitLib").
runoncepath("/commonlib/simulationLib").
runoncepath("/commonlib/timeLib").
runoncepath("/commonlib/nodesLib").
runoncepath("/commonlib/utilsLib").
runoncepath("/commonlib/optimizationLib").

global landingLib to ({
    local function findOrbitImpactPosition {
        local fixRotFunc to utilsLib:getFixRotFunction().
        local fixRot to R(0,0,0).
        local delay to 0.
        local startTime to time:seconds.
        local simTime to startTime + orbitLib:findOrbitAltitudeIntersectionTime(ship:orbit, ship:orbit:trueanomaly).
        local simPos to V(0,0,0).
        local simTerrainPos to V(0,0,0).
        local simVelocity to V(0,0,0).
        local altitudeError to 0.
        local errorMinimizer to optimizationLib:scalarErrorMinNR({
            parameter x1, y1.
            return (y1/abs(y1)) * max(min(abs(y1)*0.01, 20), 0.001).
        }).

        until false {
            // rotate the position vector to compensate for the rotating frame of reference
            set fixRot to fixRotFunc(simTime).
            set simPos to fixRot * (positionat(ship, simTime) - body:position).
            set simTerrainPos to body:geopositionof(simPos + body:position):position - body:position.
            set altitudeError to simPos:mag - simTerrainPos:mag.

            if abs(altitudeError) > 1 {
                set delay to errorMinimizer:updateGetDelta(simTime, altitudeError).
                set simTime to simTime + delay.
            }
            else {
                set simVelocity to fixRot * (velocityat(ship, simTime):surface).
                break.
            }
        }

        return list(simTime, simPos, simVelocity).
    }

    local function getPosVelAtTimeFromOrbit {
        local fixRotFunc to utilsLib:getFixRotFunction().

        return {
            parameter simTime.
            local fixRot to fixRotFunc(simTime).
            return list(fixRot * (positionat(ship, simTime) - body:position),
                        fixRot * (velocityat(ship, simTime):surface)).
        }.
    }

    local function getPositionErrorFromSurface {
        parameter altitudeMargin is 0.
        return {
            parameter simPos.
            local simTerrainPos to body:geopositionof(simPos + body:position):position - body:position + (simPos:normalized * altitudeMargin).
            return simPos:mag - simTerrainPos:mag.
        }.
    }

    local function calculateLanding {
        parameter shipThrust, engineIsp, altitudeMargin is 0, progressUpdater is { parameter simInfo. }.
        
        // find impact time
        local impactData to findOrbitImpactPosition().

        // burn time required to kill all the speed (ignoring gravity for now)
        local burnTime to utilsLib:calculateBurnTime(impactData[2]:mag, engineIsp, shipThrust).
        local simStartTime to impactData[0] - burnTime.
        
        local getPosVelAtTime to getPosVelAtTimeFromOrbit().
        local getPositionError to getPositionErrorFromSurface(altitudeMargin).

        local deltaTimeList to list(1, 0.6, 0.1, 0.04).
        return calculateLandingBase(simStartTime, shipThrust, engineIsp, ship:mass, deltaTimeList, 1, getPosVelAtTime@, getPositionError@, progressUpdater@).
    }

    local function sign {
        parameter value.
        return value/abs(value).
    }

    local function getSurfaceDistance {
        parameter v1, v2, RAWtoPLANE.

        local perimeterPerDegree to (2 * constant:pi * body:radius) / 360.
        local error to RAWtoPLANE * (v2 - v1).
        return V(sign(error:X) * vang(vxcl(RAWtoPLANE:topvector, v2), vxcl(RAWtoPLANE:topvector, v1)),
                 sign(error:Y) * vang(vxcl(RAWtoPLANE:starvector, v2), vxcl(RAWtoPLANE:starvector, v1)),
                 0) * perimeterPerDegree.
    }

    local function calculateDeorbitBurn {
        parameter shipThrust, engineIsp, targetPosition, progressUpdater is { parameter simInfo. }.

        // make sure all the following rotations are created in the same tick
        wait 0.

        // should be enough time for at least 10 loops
        // (add a constant because steering takes a fixed amount of time)
        local nodeUT to time:seconds + (25e3 / config:ipu) + 10.

        local fixRotFunc to utilsLib:getFixRotFunction().
        local fixRot to fixRotFunc(nodeUT).
        local nodePosition to fixRot * (positionat(ship, nodeUT) - body:position).

        local RAWtoNODE to -utilsLib:getOrbitRot(nodeUT).
        local RAWtoSURF to -lookdirup(targetPosition, vcrs(nodePosition, targetPosition)).
        local PROXYtoRAW to lookdirup(nodePosition, vcrs(nodePosition, targetPosition)).
        local SURFtoNODE to RAWtoNODE * PROXYtoRAW.
        local NODEtoSURF to -SURFtoNODE.

        local rotationsUT to time:seconds.
        local originalRAWtoSURF to RAWtoSURF.
        local originalSURFtoNODE to SURFtoNODE.

        // TODO: find a better way to come up with the initial value
        // TODO: use the vis-viva equation to calculate the dv required to bring the pe below the intersect altitude
        local deorbitNode to node(nodeUT, 0, 0, -100).
        add deorbitNode.

        local intersectTime to 0.
        local intersectPosition to V(0,0,0).
        local intersectAltitude to targetPosition:mag - body:radius.
        local error to V(1000,1000,0).

        local surfDV to V(0,0,0).
        local nodeDV to V(0, deorbitNode:normal, deorbitNode:prograde).
        local positionMargin to V(-500, 0, 0).

        local deltaCalcFallback to {
            parameter x1, y1.
            return min(max((-y1 * 0.001), -2), 2).
        }.
        local errorMinPrograde to optimizationLib:scalarErrorMinNR(deltaCalcFallback@).
        local errorMinNormal to optimizationLib:scalarErrorMinNR(deltaCalcFallback@).

        until abs(error:X) < 20 and abs(error:Y) < 5 {
            if deorbitNode:orbit:periapsis <= intersectAltitude {
                set intersectTime to nodeUT + orbitLib:findOrbitAltitudeIntersectionTime(deorbitNode:orbit, 180, intersectAltitude).
                set fixRot to fixRotFunc(intersectTime).
                set intersectPosition to fixRot * (positionat(ship, intersectTime) - body:position).
                //set error to RAWtoSURF * (intersectPosition - targetPosition + positionMargin).
                set error to getSurfaceDistance((targetPosition + positionMargin), intersectPosition, RAWtoSURF).
                //print "Intersect, " + round(error:X, 4).
            }
            else {
                set error to V((constant:pi * body:radius) + 10*(deorbitNode:orbit:periapsis - intersectAltitude),0,0).
                //print "NO Intersect, " + round(error:X, 4).
            }

            set surfDV to NODEtoSURF * nodeDV.
            set surfDV:X to errorMinPrograde:update(surfDV:X, error:X).
            // if the intersect position is too far from the target correcting the normal component can be detrimental
            if abs(error:X) < 10000 {
                set surfDV:Y to errorMinNormal:update(surfDV:Y, error:Y).
            }
            
            set nodeDV to SURFtoNODE * surfDV.
            set deorbitNode:prograde to nodeDV:Z.
            set deorbitNode:normal to nodeDV:Y.

            if deorbitNode:burnvector:mag > 1000 {
                // TODO: use stderr
                print "Something went wrong".
                remove nextnode.
                break.
            }
        }

        local burnVector to V(0,0,0).
        local simHistoryBurn to list().
        local burnEndState to list().
        local landingInfo to list().
        // errorMargin, burnMinDt, burnMaxDt, landingMinDtList, maxLandingAltitudeError
        local settingsList to list(
            list(500, 0.02, 0.06, list(1, 0.6), 5),
            list(5, 0.02, 0.02, list(1, 0.6, 0.1), 1)
        ).
        local settingsIndex to 0.
        local settings to settingsList[settingsIndex].
        local getPosVelAtTime to getPosVelAtTimeFromOrbit().
        local getPositionError to {
            parameter simPos.
            return simPos:mag - targetPosition:mag.
        }.

        remove deorbitNode.

        local virtualNode to nodesLib:virtualNodeFromNode(deorbitNode).
        local deorbitThrust to shipThrust.
        local nodeBurnTime to utilsLib:calculateBurnTime(virtualNode:getBurnVector():mag, engineIsp, shipThrust*0.9).
        local startTime to timeLib:alignTimestamp(nodeUT - (nodeBurnTime / 2)).
        local endTime to startTime + timeLib:alignOffset(nodeBurnTime).
        set nodeBurnTime to endTime - startTime.    // update the node burn time with the aligned time stamps
                
        set fixRot to fixRotFunc(startTime).
        local startPos to fixRot * (positionat(ship, startTime) - body:position).
        local startVelocity to fixRot * (velocityat(ship, startTime):surface).

        local simStartTime to 0.
        local loopCount to 0.

        local landingProgressUpdater to {
            parameter landingSimInfo.
            progressUpdater(lexicon("landingSimInfo", landingSimInfo)).
        }.

        until false {
            set loopCount to loopCount + 1.

            // remove all existing nodes
            for nodeItem in allnodes {
                remove nodeItem.
            }

            // simulate the node burn
            set fixRot to fixRotFunc(startTime).
            set burnVector to fixRot * virtualNode:getBurnVector().
            
            // calculate the thrust required to achieve the deltaV in the time alloted for the burn
            set deorbitThrust to utilsLib:calculateThrustValue(burnVector:mag, engineIsp, nodeBurnTime).

            set simHistoryBurn to simulationLib:simulateThrust(startTime, startPos, startVelocity, ship:mass, burnVector, endTime,
                                                               deorbitThrust, engineIsp, body, settings[1], settings[2]).
            set burnEndState to simHistoryBurn[simHistoryBurn:length - 1].

            // create new orbit matching the burn result
            nodesLib:pointsToNodes(ship:orbit, startTime, endTime, burnEndState[1], burnEndState[2]).

            // simulate the landing burn
            if simStartTime = 0 {
                set simStartTime to intersectTime - utilsLib:calculateBurnTime(burnEndState[2]:mag, engineIsp, shipThrust, burnEndState[3]).
            }
            set landingInfo to calculateLandingBase(simStartTime, shipThrust, engineIsp, burnEndState[3], settings[3], settings[4],
                                                    getPosVelAtTime, getPositionError, landingProgressUpdater).
            set simStartTime to landingInfo:burnStartTime.

            // refresh rotations
            set fixRot to fixRotFunc(landingInfo:burnEndTime, rotationsUT).
            set RAWtoSURF to fixRot * originalRAWtoSURF.
            set SURFtoNODE to fixRot * originalSURFtoNODE.
            set NODEtoSURF to -SURFtoNODE.

            // calculate error
            set error to RAWtoSURF * (landingInfo:landingPosition - targetPosition).

            progressUpdater(lexicon("progradeError", error:X,
                                    "normalError", error:Y,
                                    "nodeDV", nodeDV,
                                    "burnVector", burnVector,
                                    "deorbitThrust", deorbitThrust,
                                    "loopCount", loopCount)).

            if abs(error:X) > settings[0] or abs(error:Y) > (settings[0] / 2) {
                set surfDV to NODEtoSURF * nodeDV.
                set surfDV:X to errorMinPrograde:update(surfDV:X, error:X).
                set surfDV:Y to errorMinNormal:update(surfDV:Y, error:Y).

                set nodeDV to SURFtoNODE * surfDV.
                set nodeDV:X to 0.  // shouldn't be necessary, just in case
                virtualNode:setDeltaV(nodeDV).

                if nodeDV:mag > 1000 {
                    // TODO: use stderr
                    print "Something went wrong".
                    break.
                }
            }
            else {
                set settingsIndex to settingsIndex + 1.
                if settingsIndex < settingsList:length {
                    set settings to settingsList[settingsIndex].
                }
                else {
                    break.
                }
            }
        }

        //calculate the position and velocity along the orbit for fine tunning corrections after the burn
        local trajectoryData to list().
        local pointUT to 0.
        for timeDelta in range(1, 50, 1) {
            wait 0. // it's the only way to ensure the following section is executed in the same tick
            set pointUT to endTime + timeDelta. // no need to align pointUT since endTime is already aligned and the delta is an integer
            set fixRot to fixRotFunc(pointUT).
            trajectoryData:add(list(pointUT,
                                    fixRot * (positionat(ship, pointUT) - body:position),
                                    fixRot * (velocityat(ship, pointUT):surface))).
        }

        // remove all existing nodes
        for nodeItem in allnodes {
            remove nodeItem.
        }

        return lexicon(
            "burnVector", burnVector,
            "burnThrust", deorbitThrust,
            "burnStartTime", startTime,
            "burnEndTime", endTime,
            "landingInfo", landingInfo,
            "trajectoryData", trajectoryData
        ).
    }

    local function calculateLandingBase {
        parameter startTime, shipThrust, engineIsp, shipMass, deltaTimeList, maxAltitudeError, getPosVelAtTime, getPositionError, progressUpdater is { parameter simInfo. }.
        
        local posVelAtTime to list().
        local simBurnStartTime to timeLib:alignTimestamp(startTime).
        local simBurnStartDelay to 0.
        local simOldBurnStartDelay to 0.
        local simHistory to list().
        local simEndState to list().
        local errorMinimizer to optimizationLib:scalarErrorMinNR({
            parameter x1, y1.
            return (y1/abs(y1)) * max(min(abs(y1)*0.01, 10), 0.02).
        }).
        
        // altitude correction
        local altitudeError to 0.
        local lastAltitudeError to 0.
        local simIsGoodEnough to false.

        local deltaTimeIndex to 0.

        until false {
            set posVelAtTime to getPosVelAtTime(simBurnStartTime).
            set simHistory to simulationLib:simulateToZeroVelocity(simBurnStartTime, posVelAtTime[0], posVelAtTime[1], shipMass, shipThrust, engineIsp, body, deltaTimeList[deltaTimeIndex]).
            set simEndState to simHistory[simHistory:length-1].
            set altitudeError to getPositionError(simEndState[1]).
            
            if abs(altitudeError) > maxAltitudeError {
                set simBurnStartDelay to timeLib:alignOffset(errorMinimizer:updateGetDelta(simBurnStartTime, altitudeError)).
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
        local burnEndTime to timeLib:alignTimestamp(simEndState[0]).
        
        return lexicon(
            "burnStartTime", burnStartTime,
            "burnEndTime", burnEndTime,
            "landingPosition", simEndState[1]
        ).
    }
    
    return lexicon(
        "findOrbitImpactPosition", findOrbitImpactPosition@,
        "calculateLanding", calculateLanding@,
        "calculateDeorbitBurn", calculateDeorbitBurn@
    ).
}):call().