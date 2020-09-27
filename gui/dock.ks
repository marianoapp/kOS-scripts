@LAZYGLOBAL off.

parameter standalone is true.

// import libraries
runoncepath("/commonlib/guiLib").
runoncepath("/commonlib/dockingLib").
runoncepath("commonlib/streamsLib").

if standalone {
    abort off.
    clearguis().
}

streamsLib:initGuiStreams().
global exitCode to 0.

// draw gui
local baseGui to guiLib:createBaseGui().
local dockGui IS GUI(200).
local containerBox to dockGui:addvlayout().

// roll mode option group
containerBox:addlabel("Roll matching mode").
local rollModeBox to containerBox:addvbox().
local defaultRollMode to "Closest".
for rollMode in dockingLib:rollMatchModeEnum:keys {
    rollModeBox:addRadioButton(rollMode, (rollMode = defaultRollMode)).
}

// max speed
local maxSpeedBox to containerBox:addvlayout().
local maxSpeedLabel to maxSpeedBox:addlabel("Max speed").
local speedSlider to maxSpeedBox:addhslider(0, 0.1, 5).
set speedSlider:onchange to { 
    parameter currentValue.
    set maxSpeedLabel:text to "Max speed [" + round(currentValue, 2) + "]".
}.
set speedSlider:value to 1.

// dock button
local dockButton to containerBox:addbutton("Dock").
set dockButton:onclick to { baseGui:postMessage("dockButton:onclick"). }.



// add handlers
on abort {
    baseGui:postMessage("exit").
    set exitCode to 1.
}

baseGui:addHandler("dockButton:onclick", {
    set containerBox:enabled to false.

    local rollMatchMode to dockingLib:rollMatchModeEnum[rollModeBox:radiovalue].
    runpath("/dock", rollMatchMode, speedSlider:value).
    if exitCode = 0 {
        baseGui:postMessage("exit").
    }
    else {
        set containerBox:enabled to true.
    }
}).



// show the gui
dockGui:show().

// start handling events
baseGui:start().

// destroy the gui
dockGui:hide().
dockGui:dispose().
