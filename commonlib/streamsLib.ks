@LAZYGLOBAL off.

global streamsLib to ({
    local function initConsoleStreams {
        parameter override is false.

        if not (defined stdout) or (stdout:isdead) or override {
            global stdout to {
                parameter message.
                print message.
            }.
        }
        if not (defined stderr) or (stderr:isdead) or override {
            global stderr to {
                parameter message.
                print "ERR: " + message.
            }.
        }
    }

    local function initGuiStreams {
        parameter override is false.

        // TODO: use better colors, a darker green and an orange instead of red
        if not (defined stdout) or (stdout:isdead) or override {
            global stdout to {
                parameter message.
                hudtext(message, 2, 2, 22, green, false).
            }.
        }
        if not (defined stderr) or (stderr:isdead) or override {
            global stderr to {
                parameter message.
                hudtext(message, 2, 2, 22, red, false).
            }.
        }
    }
    
    return lexicon(
        "initConsoleStreams", initConsoleStreams@,
        "initGuiStreams", initGuiStreams@
    ).
}):call().