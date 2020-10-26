@LAZYGLOBAL off.

global guiLib to ({
    local function createGuiHandler {
        parameter size, title is "", startPos is list(-1,-1).

        local mainGui IS GUI(size[0], size[1]).
        local messageQueue to queue().
        local messageHandlers to lexicon().
        local exitLoop to false.

        addTitleBar().
        moveGui(startPos).

        local function addTitleBar {
            local titleBox to mainGui:addhlayout().
            set titleBox:style:align to "right".
            local titleLabel to titleBox:addlabel("<b>" + title + "</b>").
            set titleLabel:style:textcolor to rgb(1,0.5,0).
            local closeButton to titleBox:addbutton("x").
            set closeButton:style:width to 25.
            set closeButton:style:height to 25.
            set closeButton:style:padding:left to 7.

            set closeButton:onclick to { postMessage("exit"). }.
        }

        local function moveGui {
            parameter position.
            
            if position[0] >= 0 {
                set mainGui:X to position[0].
            }
            if position[1] >= 0 {
                set mainGui:Y to position[1].
            }
        }

        local function addMessageHandler {
            parameter messageName, handler.
            
            if not messageHandlers:haskey(messageName) {
                messageHandlers:add(messageName, handler).
            }
            else {
                set messageHandlers[messageName] to handler.
            }
        }

        local function postMessage {
            parameter messageName, parameters is list().
            // stop accepting messages if the queue is too long
            if messageQueue:length < 10 {
                messageQueue:push(list(messageName, parameters)).
            }
        }

        local function addSpecialHandlers {
            addMessageHandler("exit", { set exitLoop to true. }).
        }

        local function start {
            addSpecialHandlers().

            // show the gui
            mainGui:show().

            // message loop
            until exitLoop {
                wait until messageQueue:length > 0.
                
                local messageItem to messageQueue:pop().
                local messageName to messageItem[0].
                local messageParams to messageItem[1].
                // if there's a handler for the message then call it
                if messageHandlers:haskey(messageName) {
                    handleMessage(messageHandlers[messageName], messageParams).
                }
            }

            // destroy the gui
            mainGui:hide().
            mainGui:dispose().
        }

        local function handleMessage {
            parameter handler, messageParams.

            local paramCount to messageParams:length.
            if paramCount = 0 {
                handler().
            }
            else if paramCount = 1 {
                handler(messageParams[0]).
            }
            else if paramCount = 2 {
                handler(messageParams[0], messageParams[1]).
            }
            else if paramCount = 3 {
                handler(messageParams[0], messageParams[1], messageParams[2]).
            }
            else if paramCount = 4 {
                handler(messageParams[0], messageParams[1], messageParams[2], messageParams[3]).
            }
            else if paramCount = 5 {
                handler(messageParams[0], messageParams[1], messageParams[2], messageParams[3], messageParams[4]).
            }
        }

        return lexicon(
            "mainGui", mainGui,
            "addMessageHandler", addMessageHandler@,
            "postMessage", postMessage@,
            "start", start@
        ).
    }

    return lexicon(
        "createGuiHandler", createGuiHandler@
    ).
}):call().