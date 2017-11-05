// SUPER LOGGER
Anything(String) log =
        ifArg("debug", "d")
        then process.writeLine
        else noop;

