@LAZYGLOBAL off.

// #EXTERNAL_IDS guidanceLib, calculusLib, rcsLib, pidLib
// import libraries
runoncepath("/lib/calculusLib").
runoncepath("/lib/rcsLib").
runoncepath("/lib/pidLib").

global guidanceLib to ({
    local function APN {
        parameter targetVessel.
        
        local stopFlag to false.

        local engineList to list().
        list engines in engineList.
        local shipEngine to engineList[0].
    

        local function start {
            // variables
            local LOS to targetVessel:position:direction.
            local thrustAcc to 0.    
            local currentTime to 0.
            local shipPosBody to V(0,0,0).
            local targetPos to targetVessel:position.
            local targetPosBody to targetPos - body:position.
            local relVel to V(0,0,0).
            local rotVector to V(0,0,0).
            local maneuverAcceleration to V(0,0,0).
            local vectorZ to V(0,0,1).
            local pids to pidLib:pidVectorXY(1.5, 0.01, 0).
            local offsetAnglesSin to V(0,0,0).
            local steeringDirection to ship:facing.

            local targetVelocity to V(0,0,0).
            local targetAcc to V(0,0,0).
            local targetAccObj to calculusLib:vectorDerivative().
            local bodyMu to body:mu.

            local shipVelocity to V(0,0,0).
            local shipAcc to V(0,0,0).
            local shipAccObj to calculusLib:vectorDerivative().

            local N to 3.
            local halfN to N / 2.

            set stopFlag to false.
            
            pids:setpoint(V(0,0,0)).

            // steering
            lock steering to steeringDirection.
            
            // delegates
            local pids_setScalarBounds to pids:setScalarBounds.
            local pids_update to pids:update.
            local targetAcc_calculate to targetAccObj:calculate.
            local shipAcc_calculate to shipAccObj:calculate.

            wait 0.01.
                    
            until stopFlag {
                set currentTime to time:seconds.
            
                set targetPos to targetVessel:position.
                set targetPosBody to targetPos - body:position.
                set shipPosBody to -body:position.

                if vang(targetPos, facing:forevector) < 90 {
                    // update the LOS
                    set LOS to targetPos:direction.

                    set targetVelocity to targetVessel:velocity:orbit.
                    set shipVelocity to ship:velocity:orbit.

                    // WORKAROUND: if the ship is landed and not loaded the orbital velocity is reported as zero.
                    if targetVelocity:mag = 0 {
                        set targetVelocity to -targetVessel:velocity:surface.
                    }

                    set relVel to targetVelocity - shipVelocity.
                    set rotVector to vcrs(targetPos, relVel) / targetPos:sqrmagnitude.

                    set targetAcc to targetAcc_calculate(currentTime, targetVelocity) +                   // total acceleration
                                    (targetPosBody:normalized) * (bodyMu / targetPosBody:sqrmagnitude).  // add gravity

                    // desired maneuver acceleration
                    set maneuverAcceleration to (-N * relVel:mag * vcrs(targetPos:normalized, rotVector)) + halfN*targetAcc.

                    set shipAcc to shipAcc_calculate(currentTime, shipVelocity) +                   // total acceleration
                                (shipPosBody:normalized) * (bodyMu / shipPosBody:sqrmagnitude).  // add gravity

                    // remove the current acceleration from the requested by the maneuver
                    // and convert to the LOS ref frame
                    set maneuverAcceleration to (-LOS) * (maneuverAcceleration - shipAcc).

                    // update available ship acceleration
                    set thrustAcc to max(shipEngine:thrust / ship:mass, 1).

                    pids_setScalarBounds(-thrustAcc, thrustAcc).

                    // the acceleration is negated because the setpoint is set to 0.
                    set offsetAnglesSin to pids_update(currentTime, -maneuverAcceleration) / thrustAcc.

                    set steeringDirection to lookdirup(
                        LOS * R(-arcsin(offsetAnglesSin:Y), arcsin(offsetAnglesSin:X), 0) * vectorZ,
                        facing:topvector
                    ).
                }
                else {
                    set steeringDirection to lookdirup(targetPos, facing:topvector).
                }
                
                wait 0.01.
            }
            
            unlock steering.
        }
        
        local function stop {
            set stopFlag to true.
        }
                
        return lex(
            "start", start@,
            "stop", stop@
        ).
    }


    return lex(
        "APN", APN@
    ).
}):call().