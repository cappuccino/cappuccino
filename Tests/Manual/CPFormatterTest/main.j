/*
 * AppController.j
 * CPFormatterTest
 *
 * Created by aparajita on June 30, 2011.
 * Copyright 2011, Victory-Heart Productions All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "AppController.j"

function formatter(aString, aLevel, aTitle)
{
    return aString;
}

function main(args, namedArgs)
{
    CPLogRegister(CPLogConsole, null, formatter);
    CPApplicationMain(args, namedArgs);
}
