/*
 * AppController.j
 * performKeyEquivalentTest
 *
 * Created by aparajita on May 22, 2011.
 * Copyright 2011, Victory-Heart Productions All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "AppController.j"

var formatter = function(aString, aTitle, aLevel)
{
    return aString;
};

function main(args, namedArgs)
{
    CPLogRegister(CPLogConsole, nil, formatter);
    CPApplicationMain(args, namedArgs);
}
