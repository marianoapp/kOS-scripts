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

local translationModesEnum to lexicon(
    "Cancel velocity", 1,
    "Maintain position", 2
).

// draw gui
local guiHandler to guiLib:createGuiHandler(list(200,0), "Translation", startPos).
local mainGui to guiHandler:mainGui.
local containerBox to mainGui:addvlayout().

// mode option group
containerBox:addlabel("Mode").
local modeBox to containerBox:addvbox().
local defaultMode to "Cancel velocity".
for mode in translationModesEnum:keys {
    modeBox:addRadioButton(mode, (mode = defaultMode)).
}

// execute button
local execButton to containerBox:addbutton("Execute").
set execButton:onclick to { guiHandler:postMessage("execButton:onclick"). }.

// stop button
local stopButton to mainGui:addbutton("Stop").
set stopButton:onclick to { ag10 on. }.
set stopButton:enabled to false.


// add handlers
on abort {
    guiHandler:postMessage("exit").
    set exitCode to 1.
}

guiHandler:addMessageHandler("execButton:onclick", {
    set containerBox:enabled to false.
    set stopButton:enabled to true.

    local translationMode to translationModesEnum[modeBox:radiovalue].
    runpath("/translate", translationMode).

    set containerBox:enabled to true.
    set stopButton:enabled to false.
}).


// start handling events
guiHandler:start().
