/*
 * AppController.j
 * CPTextFielMultine
 *
 * Created by You on November 12, 2014.
 * Copyright 2014, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>


@implementation AppController : CPObject
{
    @outlet CPTextField field1;
    @outlet CPTextField field2;
    @outlet CPTextField field3;
    @outlet CPWindow    theWindow;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var s = [field1 frameSize];
    s.height = 83;
    [field1 setFrameSize:s]

    var s = [field2 frameSize];
    s.height = 83;
    [field2 setFrameSize:s]

    var s = [field3 frameSize];
    s.height = 83;
    [field3 setFrameSize:s]
}

- (void)awakeFromCib
{
    [theWindow setFullPlatformWindow:YES];
}

- (IBAction)actionSent:(id)aSender
{
    CPLog.debug("action sent from " + aSender);
}

@end
