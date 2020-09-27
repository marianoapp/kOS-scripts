@LAZYGLOBAL off.

global guiLib to ({
    local function createBaseGui {
        local messageQueue to queue().
        local messageHandlers to lexicon().
        local exitLoop to false.

        local function addHandler {
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
            addHandler("exit", { set exitLoop to true. }).
        }

        local function start {
            addSpecialHandlers().

            // message loop
            until exitLoop {
                wait until messageQueue:length > 0.
                
                local messageItem to messageQueue:pop().
                local messageName to messageItem[0].
                local messageParams to messageItem[1].
                // if there's a handler for the message then call it
                if messageHandlers:haskey(messageName) {
                    handleMessage(messageParams, messageHandlers[messageName]).
                }
            }
        }

        local function handleMessage {
            parameter messageParams, handler.

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
            "addHandler", addHandler@,
            "postMessage", postMessage@,
            "start", start@
        ).
    }

    return lexicon(
        "createBaseGui", createBaseGui@
    ).
}):call().