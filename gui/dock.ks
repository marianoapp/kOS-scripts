@LAZYGLOBAL off.

// import libraries
runoncepath("commonlib/dockingLib").

abort off.
clearguis().

local exitGui to false.
local startDocking to false.

on abort {
    set exitGui to true.
}

local dockGui IS GUI(200).
local containerBox to dockGui:addvlayout().

// roll mode option group
containerBox:addlabel("Roll matching mode").
local rollModeBox to containerBox:addvbox().
for rollMode in dockingLib:rollMatchModeEnum:keys {
    rollModeBox:addRadioButton(rollMode).
}
// TODO: set default

// max speed
local maxSpeedBox to containerBox:addvlayout().
local maxSpeedLabel to maxSpeedBox:addlabel("Max speed").
local speedSlider to maxSpeedBox:addhslider(0, 0.2, 5).
set speedSlider:onchange to { 
    parameter currentValue.
    set maxSpeedLabel:text to "Max speed [" + round(currentValue, 2) + "]".
}.
set speedSlider:value to 1.

// dock button
local dockButton to containerBox:addbutton("Dock").
set dockButton:onclick to { set startDocking to true. }.

// show the gui
dockGui:show().

until exitGui {
    wait until startDocking.
    set startDocking to false.

    set containerBox:enabled to false.

    local rollMatchMode to dockingLib:rollMatchModeEnum[rollModeBox:radiovalue].
    local dockingSuccessful to dockingHandler(rollMatchMode, speedSlider:value).
    if dockingSuccessful {
        set exitGui to true.
    }
    else {
        set containerBox:enabled to true.
    }
}

dockGui:hide().

local function dockingHandler {
    parameter rollMatchMode, maxSpeed.

    local returnValue to false.

    if hastarget {
        local ownPort to false.
        local targetPort to false.
        
        // TODO: compare the size of the docking ports

        // own port
        if ship:controlpart:istype("DockingPort") {
            set ownPort to ship:controlpart.
        }
        else {
            local ports to ship:dockingports.
            if ports:length > 0 {
                set ownPort to ports[0].
            }
            else {
                hudtext("No docking ports on this vessel", 2, 2, 20, red, false).
            }
        }

        // target port
        if target:istype("DockingPort") {
            // target is a docking port
            set targetPort to target.
        }
        else {
            // target is a ship
            set targetPort to dockingLib:findDockingPort(target).
        }

        sas off.
        rcs on.

        // dock with the target
        dockingLib:dock(ownPort, targetPort, rollMatchMode, maxSpeed).
        set returnValue to true.

        rcs off.
        sas on.
    }
    else {
        hudtext("No target selected", 2, 2, 20, red, true).
    }

    return returnValue.
}
