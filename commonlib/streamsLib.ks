@LAZYGLOBAL off.

global streamsLib to ({
    local function initConsoleStdout {
        parameter override is false.

        if not (defined stdout) or (stdout:isdead) or override {
            global stdout to {
                parameter message, col is -1, line is -1.
                if col >= 0 and line >= 0 {
                    print message at (col, line).
                }
                else {
                    print message.
                }
            }.
        }
    }

    local function initConsoleStreams {
        parameter override is false.

        initConsoleStdout(override).

        if not (defined stderr) or (stderr:isdead) or override {
            global stderr to {
                parameter message.
                print "ERR: " + message.
            }.
        }
    }

    local function initGuiStreams {
        parameter override is false.

        initConsoleStdout(override).

        // TODO: use better colors, an orange instead of red
        if not (defined stderr) or (stderr:isdead) or override {
            global stderr to {
                parameter message.
                hudtext(message, 2, 2, 22, red, true).
            }.
        }
    }

    return lexicon(
        "initConsoleStreams", initConsoleStreams@,
        "initGuiStreams", initGuiStreams@
    ).
}):call().