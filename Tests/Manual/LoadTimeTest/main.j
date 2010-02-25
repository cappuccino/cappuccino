/*
 * AppController.j
 * LoadTimeTest
 *
 * Created by You on February 23, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "AppController.j"

function main(args, namedArgs)
{
    endLoad = new Date();
    
    CPApplicationMain(args, namedArgs);
}
