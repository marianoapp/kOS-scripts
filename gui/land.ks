@LAZYGLOBAL off.

parameter standalone is true, startPos is list(-1,-1).

// import libraries
runoncepath("/commonlib/guiLib").
runoncepath("/commonlib/streamsLib").

if standalone {
    abort off.
    clearguis().
}

streamsLib:initGuiStreams().
global exitCode to 0.

// draw gui
local guiHandler to guiLib:createGuiHandler(list(200,0), "Landing", startPos).
local mainGui to guiHandler:mainGui.
local containerBox to mainGui:addvlayout().

// land mode option group
local landingModeBox to containerBox:addvlayout().
local optLandNow to landingModeBox:addRadioButton("Land now", false).
local optLandAtTarget to landingModeBox:addRadioButton("Land at target", false).
local optLandAtCoords to landingModeBox:addRadioButton("Land at coordinates", false).
set landingModeBox:onradiochange to {
    parameter selectedButton.
    set coordinatesBox:enabled to (selectedButton = optLandAtCoords).
}.

// landing coordinates
local coordinatesBox to containerBox:addvlayout().
local latBox to coordinatesBox:addhlayout().
latBox:addlabel("Lat").
local latField to latBox:addtextfield("0").
local lngBox to coordinatesBox:addhlayout().
lngBox:addlabel("Lng").
local lngField to lngBox:addtextfield("0").

// altitude margin
local altMarginBox to containerBox:addvlayout().
local altMarginLabel to altMarginBox:addlabel("Altitude margin").
local altSlider to altMarginBox:addhslider(0, 0, 30).
set altSlider:onchange to { 
    parameter currentValue.
    set altMarginLabel:text to "Altitude margin [" + round(currentValue, 2) + "]".
}.
set altSlider:value to 5.

// land button
local landButton to containerBox:addbutton("Land").
set landButton:onclick to { guiHandler:postMessage("landButton:onclick"). }.

// default settings
set optLandNow:pressed to true.


// add handlers
on abort {
    guiHandler:postMessage("exit").
    set exitCode to 1.
}

guiHandler:addMessageHandler("landButton:onclick", {
    local landingMode to 0.
    local targetLandingPosition to V(0,0,0).

    if optLandNow:pressed {
        set landingMode to 1.
    }
    else if optLandAtTarget:pressed {
        if hastarget {
            set landingMode to 2.
            set targetLandingPosition to target:position - body:position.
        }
        else {
            stderr("No target selected").
        }
    }
    else if optLandAtCoords:pressed {
        // TODO: validate coordinates: complete, within range and so on
        if true {
            set landingMode to 2.
            set targetLandingPosition to latlng(latField:text:toscalar(), lngField:text:toscalar()):position - body:position.
        }
        else {
            stderr("Invalid coordinates").
        }
    }
    
    if landingMode > 0 {
        set containerBox:enabled to false.

        runpath("/land", landingMode, altSlider:value, targetLandingPosition).
        if exitCode = 0 {
            guiHandler:postMessage("exit").
        }
        else {
            set containerBox:enabled to true.
        }
    }
}).


// start handling events
guiHandler:start().
