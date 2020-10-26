@LAZYGLOBAL off.

parameter standalone is true.

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
//local mainGui IS GUI(200).
local guiHandler to guiLib:createGuiHandler(list(200,0), "Menu").
local mainGui to guiHandler:mainGui.
local containerBox to mainGui:addvlayout().

local rowBox1 to containerBox:addhlayout().
local dockButton to rowBox1:addbutton("Dock").
set dockButton:onclick to { guiHandler:postMessage("dockButton:onclick"). }.
local landButton to rowBox1:addbutton("Land").
set landButton:onclick to { guiHandler:postMessage("landButton:onclick"). }.
local transButton to rowBox1:addbutton("Trans").
set transButton:onclick to { guiHandler:postMessage("transButton:onclick"). }.

// add handlers
on abort {
    guiHandler:postMessage("exit").
}

function getChildWindowPos {
    //return list(mainGui:X, mainGui:Y + mainGui:height + 10).
    return list(mainGui:X, mainGui:Y + 85).
}

guiHandler:addMessageHandler("dockButton:onclick", {
    set containerBox:enabled to false.
    runpath("/gui/dock", false, getChildWindowPos()).
    set containerBox:enabled to true.
}).
guiHandler:addMessageHandler("landButton:onclick", {
    set containerBox:enabled to false.
    runpath("/gui/land", false, getChildWindowPos()).
    set containerBox:enabled to true.
}).
guiHandler:addMessageHandler("transButton:onclick", {
    set containerBox:enabled to false.
    runpath("/gui/translate", false, getChildWindowPos()).
    set containerBox:enabled to true.
}).


// start handling events
guiHandler:start().