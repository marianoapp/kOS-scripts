@LAZYGLOBAL off.

// import libraries
runoncepath("/commonlib/translationLib").
runoncepath("/commonlib/rotationLib").
runoncepath("/commonlib/steeringLib").
runoncepath("/commonlib/asyncLib").
runoncepath("/commonlib/grapplerLib").

global grapplerDockingLib to ({
    local function dock
    {
        parameter grappler,             // grappler part
                  targetVessel,         // vessel to grapple
                  targetPositionRel,    // position to grapple, in target vessel coordinates
                  topVector is ship:facing:topvector,
                  speedBounds is list(0, 0).
        
        // arm the grappler
        grapplerLib:arm(grappler).
        
        // control from the grappler
        grapplerLib:controlfrom(grappler).
        
        lock targetPositionRaw to targetVessel:facing * targetPositionRel.
        
        // turn the ship in the desired direction
        local steerTask to steeringLib:steerToDelegateAsync({ return lookdirup(-targetPositionRaw, topVector). }).

        // position the vessel above the targetPosition
        local positionOffset to V(0,0,4).
        local targetPositionDel to { return targetVessel:position + targetPositionRaw + (targetPositionRaw:direction * positionOffset). }.
        
        local translateObj to translationLib:translateToPosition(targetPositionDel, rotationLib:rawToShip() * grappler:position).
        translateObj:setSpeedBounds(0.2, 2).
        if speedBounds[1] > 0 {
            translateObj:setSpeedBounds(speedBounds[0], speedBounds[1]).
        }
        // when close enough approach and grab
        when translateObj:isDone() then {
            set positionOffset to V(0,0,0).
            local grabTask to grapplerLib:grabDoneAsync(grappler).
            when asyncLib:taskDone(grabTask) then {
                translateObj:stop().
            }
        }
        asyncLib:await(steerTask).
        translateObj:start().
        
        unlock steering.
    }
    
    return lexicon(
        "dock", dock@
    ).
}):call().