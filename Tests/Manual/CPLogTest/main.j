/*
 * AppController.j
 * CPLogTest
 *
 * Created by Aparajita Fishman on September 3, 2010.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "AppController.j"

function formatter(aString, aLevel, aTitle)
{
    return aString;
}

function fancyFormatter(aString, aLevel, aTitle)
{
    return aTitle + ": [" + aLevel + "] " + CPLogColorize(aString, aLevel);
}

function warningFormatter(aString, aLevel, aTitle)
{
    return aString + " (you have been warned!)";
}

function main(args, namedArgs)
{
    CPLogRegister(CPLogPopup, "info");
    CPLogRegister(CPLogConsole, null, formatter);
    CPLogRegisterRange(CPLogConsole, "trace", "trace");
    CPLogRegisterRange(CPLogConsole, "fatal", "warn", warningFormatter);

    CPApplicationMain(args, namedArgs);
}
