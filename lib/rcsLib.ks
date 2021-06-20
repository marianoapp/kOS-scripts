@LAZYGLOBAL off.

// #EXTERNAL_IDS rcsLib, rotationLib
// import libraries
runoncepath("/lib/rotationLib").

global rcsLib to ({
    local function getTotalThrust {
        local totalThrust to lex(
            "X+", 0,
            "X-", 0,
            "Y+", 0,
            "Y-", 0,
            "Z+", 0,
            "Z-", 0
        ).

        local function addTotalThrust {
            parameter axis, value.
            
            local axisName to axis + (choose "+" if value > 0 else "-").
            set totalThrust[axisName] to totalThrust[axisName] + abs(value).
        }

        local RAWtoSHIP to -ship:facing.
        local rcsPartList to list().
        list rcs in rcsPartList.

        for rcsPart in rcsPartList {
            if rcsPart:enabled {
                for tv in rcsPart:thrustVectors {
                    // negative because the effect is in the opposite direction of the thrust
                    local effect to -((RAWtoSHIP*tv) * rcsPart:availablethrust).
                    if rcsPart:starboardenabled {
                        addTotalThrust("X", effect:X).
                    }
                    if rcsPart:topenabled {
                        addTotalThrust("Y", effect:Y).
                    }
                    if rcsPart:foreenabled {
                        addTotalThrust("Z", effect:Z).
                    }    
                }
            }
        }

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
        
        local rcsModules to ship:modulesnamed("ModuleRCSFX").
        for module in rcsModules {
            module:setfield("rcs", enable).
        }
    }
    
    return lex(
        "getTotalThrust", getTotalThrust@,
        "getTotalThrustList", getTotalThrustList@,
        "enableParts", enableParts@
    ).
}):call().