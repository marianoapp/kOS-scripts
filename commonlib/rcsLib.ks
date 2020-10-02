@LAZYGLOBAL off.

// import libraries
runoncepath("/commonlib/rotationLib").

global rcsLib to ({
    local function getPartsMetadata {
        return lexicon(
            "RCSBlock.v2", lexicon(
                "thrust", 1,
                "thrustOffset", V(-0.135,0,0),
                "thrustVectors", list(
                    V(0,1,0), V(0,-1,0), V(0,0,1), V(0,0,-1)
                )
            ),
            "linearRCS", lexicon(
                "thrust", 2,
                "thrustOffset", V(0,0,0),
                "thrustVectors", list(
                    V(0,0,1)
                )
            ),
            "MEMLander", lexicon(
                "thrust", 2,
                "thrustOffset", V(0,0,0),   //TODO
                "thrustVectors", list(
                    V(0,1,0), V(0,-1,0), V(0,0,1), V(0,0,-1)
                )
            ),
            "vernierEngine", lexicon(
                "thrust", 12,
                "thrustOffset", V(0,0,0),   //TODO
                "thrustVectors", list(
                    V(0,0,1)
                )
            )
        ).
    }

    local function getEnabledActuations {
        parameter partModule.
        
        local actuations to V(0,0,0).
        // TODO: check if the game allows to tweak these values, they need to be enabled in the settings.
        //       if they are not present then assume all actuations are enabled
        local showToggles to partModule:hasevent("show actuation toggles").
        
        if showToggles {
            partModule:doevent("show actuation toggles").
        }
        if partModule:getfield("port/stbd") {
            set actuations:X to 1.
        }
        if partModule:getfield("dorsal/ventral") {
            set actuations:Y to 1.
        }
        if partModule:getfield("fore/aft") {
            set actuations:Z to 1.
        }
        if showToggles {
            partModule:doevent("hide actuation toggles").
        }
        
        return actuations.
    }

    local function getTotalThrust {
        local totalThrust to lexicon(
            "X+", 0,
            "X-", 0,
            "Y+", 0,
            "Y-", 0,
            "Z+", 0,
            "Z-", 0
        ).
        
        local function addTotalThrust {
            parameter axis, value.
            
            local axisName to axis + "+".
            if value < 0 {
                set axisName to axis + "-".
            }
            set totalThrust[axisName] to totalThrust[axisName] + value.
        }

        local partsMetadata to getPartsMetadata().
        
        for partName in partsMetadata:keys {
            local partData to partsMetadata[partName].
            for partItem in ship:partsnamed(partName) {
                local partModule to partItem:getmodule("ModuleRCSFX").
                if partModule:getfield("rcs") {
                    local thrustLimiter to partModule:getfield("thrust limiter") / 100.
                    local actuations to getEnabledActuations(partModule).
                    local PARTtoSHIP to rotationLib:partToShip(partItem).
                    for tv in partData:thrustVectors {
                        // negative because the effect is in the opposite direction of the thrust
                        local incidence to -((PARTtoSHIP*tv) * partData:thrust * thrustLimiter).
                        if actuations:X = 1 {
                            addTotalThrust("X", incidence:X).
                        }
                        if actuations:Y = 1 {
                            addTotalThrust("Y", incidence:Y).
                        }
                        if actuations:Z = 1 {
                            addTotalThrust("Z", incidence:Z).
                        }
                    }
                }
            }
        }
        
        set totalThrust["X-"] to abs(totalThrust["X-"]).
        set totalThrust["Y-"] to abs(totalThrust["Y-"]).
        set totalThrust["Z-"] to abs(totalThrust["Z-"]).

        return totalThrust.
    }

    local function getTotalThrustList {
        local totalThrust to getTotalThrust().
        
        return list(
            V(totalThrust["X-"], totalThrust["Y-"], totalThrust["Z-"]),
            V(totalThrust["X+"], totalThrust["Y+"], totalThrust["Z+"])
        ).
    }

    local function enableParts {
        parameter enable.
        
        local partsMetadata to getPartsMetadata().
        for partName in partsMetadata:keys {
            for partItem in ship:partsnamed(partName) {
                local partModule to partItem:getmodule("ModuleRCSFX").
                partModule:setfield("rcs", enable).
            }
        }
    }
    
    return lexicon(
        "getPartsMetadata", getPartsMetadata@,
        "getEnabledActuations", getEnabledActuations@,
        "getTotalThrust", getTotalThrust@,
        "getTotalThrustList", getTotalThrustList@,
        "enableParts", enableParts@
    ).
}):call().