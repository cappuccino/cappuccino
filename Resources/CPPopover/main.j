/*
 * AppController.j
 * test
 *
 * Created by You on July 6, 2011.
 * Copyright 2011, Your Company All rights reserved.
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
