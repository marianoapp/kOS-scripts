@LAZYGLOBAL off.

// import libraries
runoncepath("/commonlib/translationLib").
runoncepath("/commonlib/rotationLib").
runoncepath("/commonlib/steeringLib").
runoncepath("/commonlib/asyncLib").
runoncepath("/commonlib/grapplerLib").

// https://physics.stackexchange.com/questions/80542/calculating-torque-in-3d

global thrustBalanceLib to ({
    // adjust the thrust of all active engines to achieve rotational equilibrium
    // only works for engines in a single plane, and the plane must contain the CoM
    local function simpleThrustBalancer
    {
        parameter engineParts.      // list of engines to be balanced
    
        local planeNormal to vcrs(engineParts[0]:position, engineParts[1]:position).
        local thrustVector to -engineParts[0]:facing:forevector. // assumes all engines are parallel
        local RAWtoPLANE to -lookdirup(thrustVector, planeNormal). // assumes the thrust vector belongs to the plane
        local SHIPtoPLANE to RAWtoPLANE * ship:facing.
        local extremes to findExtremes().
        local lastEngineAdjusted to engineParts[0].

        // reset thrust limiter on all engines
        for engine in engineParts {
            set engine:thrustlimit to 100.
        }

        local function findExtremes {
            // calculate the lever arm of each engine and find the ones in the extremes
            local mostPositive to list(0, false).
            local mostNegative to list(0, false).
            
            for engine in engineParts {
                local relPos to RAWtoPLANE * engine:position.
                if relPos:X > mostPositive[0] {
                    set mostPositive[0] to relPos:X.
                    set mostPositive[1] to engine.
                }
                if relPos:X < mostNegative[0] {
                    set mostNegative[0] to relPos:X.
                    set mostNegative[1] to engine.
                }
            }
            return list(mostNegative[1], mostPositive[1]).
        }

        local function balance {
            local totalTorque to 0.
            // RAWtoPLANE = SHIPtoPLANE * RAWtoSHIP
            set RAWtoPLANE to SHIPtoPLANE * (-ship:facing).
            
            for engine in engineParts {
                set totalTorque to totalTorque + (RAWtoPLANE * engine:position):X * engine:maxthrust.
            }
            // adjust thrust if required
            if abs(totalTorque) > 0.1 {
                local engineToAdjust to false.
                if totalTorque > 0 {
                    set engineToAdjust to extremes[1].
                }
                else {
                    set engineToAdjust to extremes[0].
                }

                local limiter to 1 - ((totalTorque / (RAWtoPLANE * engineToAdjust:position):X) / engineToAdjust:maxthrust).
                set engineToAdjust:thrustlimit to limiter * 100.
                
                if engineToAdjust <> lastEngineAdjusted {
                    set lastEngineAdjusted:thrustlimit to 100.
                    set lastEngineAdjusted to engineToAdjust.
                }
            }
        }
        
        return lexicon(
            "balance", balance@
        ).
    }
    
    // adjust the thrust of all active engines to achieve rotational equilibrium
    local function thrustBalancer
    {
        list engines in allEngines.
        local activeEngines to list().
        for engine in allEngines {
            if engine:maxthrust > 0 {
                activeEngines:add(engine).
            }
        }
        
        local function balance {
            for engine in activeEngines {
            
            }
        }
        
        return lexicon(
            "balance", balance@
        ).
    }
    
    return lexicon(
        "simpleThrustBalancer", simpleThrustBalancer@,
        "thrustBalancer", thrustBalancer@
    ).
}):call().