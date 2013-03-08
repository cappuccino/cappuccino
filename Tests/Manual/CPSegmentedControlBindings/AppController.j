/*
 * AppController.j
 * CPSegmentedControlBindings
 *
 * Created by You on November 24, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>

@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
}

- (void)awakeFromCib
{
    [theWindow setFullPlatformWindow:YES];
}

@end

@implementation ArrayController : CPArrayController
{
}

- (id)newObject
{
    var randIndex = FLOOR(RAND()*3),
        randLabel = ["un", "deux", "trois", nil][FLOOR(RAND()*4)],
        randTag = FLOOR(RAND()*3);
        
    return [CPDictionary dictionaryWithObjectsAndKeys:randIndex, @"index", randLabel, @"label", randTag, @"tag"];
}

@end