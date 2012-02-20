/*
 * test.j
 * CPLogTest
 *
 * Created by Aparajita Fishman on September 3, 2010.
 */

function formatter(aString, aLevel, aTitle)
{
    return aString;
}

function debugFormatter(aString, aLevel, aTitle)
{
    return CPLogColorize(aString, aLevel);
}

function warningFormatter(aString, aLevel, aTitle)
{
    return "[" + aLevel + "] " + aString;
}

function main(args)
{
    CPLogRegister(CPLogPrint, null, formatter);
    CPLogRegisterRange(CPLogPrint, "trace", "trace");
    CPLogRegisterRange(CPLogPrint, "debug", "debug", debugFormatter);
    CPLogRegisterRange(CPLogPrint, "fatal", "warn", warningFormatter);

    CPLog.fatal("I have to go now...");
    CPLog.error("Doh! An error occurred");
    CPLog.warn("Danger, Will Robinson! Danger!");
    CPLog.info("For your information, you can now provide your own formatter");
    CPLog.debug("A colorized debug message");
    CPLog.trace("Using the default CPLog formatter");
    CPLog("The default logging level");
}
