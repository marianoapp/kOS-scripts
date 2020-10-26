@LAZYGLOBAL off.

// import libraries
runoncepath("/commonlib/calculusLib").
runoncepath("/commonlib/rcsLib").
runoncepath("/commonlib/pidLib").

global guidanceLib to ({
    
    local function PN {
        parameter targetVessel, useRCS is false, useSteering to false.
        
        local stopFlag to false.
        local shipThrust to V(0,0,0).
        local distanceToTarget to V(10000,10000,10000).
        local closingSpeed to 0.
        
        if useRCS {
            // assuming the craft has symmetric thrust
            set shipThrust to rcsLib:getTotalThrustList()[1].
        }
        
        if useSteering {
            // TODO: make sure we can read "mainthrottle"
            set shipThrust to V(0,0,shipControl:mainthrottle * ship:availableThrust).
        }
        
        local function start {
            // variables
            local REF to targetVessel:position:direction.
            local xAxisREF to REF:starvector.
            local yAxisREF to REF:topvector.
            local shipAcc to V(0,0,0).
            local angleRateObj to calculusLib:vectorErrorDerivative(V(90,90,0)).
            local closingSpeedObj to calculusLib:scalarDerivative().        
            local currentTime to 0.
            local pos to V(0,0,0).
            local angleRef to V(0,0,0).
            local maneuverAcceleration to V(0,0,0).
            local vectorZ to V(0,0,1).
            local pids to pidLib:pidVectorXY(0.03, 0.0002, 0).
            local offsetAnglesSin to V(0,0,0).
            local steeringDirection to ship:facing.
            local shipControl to ship:control.
            
            set stopFlag to false.
            
            if useSteering {
                pids:setpoint(V(0,0,0)).
            }
            
            // steering
            lock steering to steeringDirection.
            
            // delegates
            local closingSpeedObj_calculate to closingSpeedObj:calculate@.
            local angleRateObj_calculate to angleRateObj:calculate@.
            local pids_setScalarBounds to pids:setScalarBounds@.
            local pids_update to pids:update@.
                    
            wait 0.01.
                    
            until stopFlag {
                set currentTime to time:seconds.
            
                // position error workaround
                // set pos to targetVessel:position.
                if targetVessel:unpacked {
                    set pos to targetVessel:position.
                }
                else {
                    set pos to targetVessel:position - (choose targetVessel:velocity:surface if altitude <= 100e3 else targetVessel:velocity:orbit) * 0.02.
                }
                set distanceToTarget to pos:mag.
                
                // closing speed
                set closingSpeed to -closingSpeedObj_calculate(currentTime, distanceToTarget).
                // if we are moving away from the target invert the value so the maneuvers have the correct direction
                if closingSpeed < 0 {
                    set closingSpeed to -closingSpeed.
                }
              
                // LOS rate
                set angleREF to V(
                    vang(xAxisREF, vxcl(yAxisREF, pos)),
                    vang(yAxisREF, vxcl(xAxisREF, pos)),
                    0
                ).
                // maneuvers (in REF frame)
                set maneuverAcceleration to 3 * closingSpeed * -angleRateObj_calculate(currentTime, angleREF).
                
                // update available ship acceleration
                set shipAcc to shipThrust / ship:mass.
                
                if useRCS {
                    // maneuvers (in SHIP frame)
                    set maneuverAcceleration to (-facing) * REF * maneuverAcceleration.
                    set shipControl:translation to V(
                        maneuverAcceleration:X / shipAcc:X,
                        maneuverAcceleration:Y / shipAcc:Y,
                        maneuverAcceleration:Z / shipAcc:Z
                    ).
                    set steeringDirection to lookdirup(pos, facing:topvector).
                }
                
                if useSteering {
                    local thrustAcc to shipAcc:Z.
                    pids_setScalarBounds(-thrustAcc, thrustAcc).
                    set offsetAnglesSin to pids_update(currentTime, -maneuverAcceleration) / thrustAcc.
                    
                    set steeringDirection to lookdirup(
                        REF * R(-arcsin(offsetAnglesSin:Y), arcsin(offsetAnglesSin:X), 0) * vectorZ,
                        facing:topvector
                    ).
                }
                            
                // update the REF
                set REF to pos:direction.
                set xAxisREF to REF:starvector.
                set yAxisREF to REF:topvector.

                wait 0.01.
            }
            
            set shipControl:neutralize to true.
            unlock steering.
        }
        
        local function stop {
            set stopFlag to true.
        }
        
        local function distance {
            return distanceToTarget.
        }
        
        local function speed {
            return closingSpeed.
        }
        
        local function resetAll {
            set distanceToTarget to V(10000,10000,10000).
        }
        
        return lexicon(
            "start", start@,
            "stop", stop@,
            "distance", distance@,
            "speed", speed@,
            "resetAll", resetAll@
        ).
    }

    return lexicon(
        "PN", PN@
    ).
}):call().