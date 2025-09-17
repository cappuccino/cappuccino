/*
 * AppController.j
 * ThemeKitchenSink
 *
 * Created by Alexander Ljungberg on May 11, 2014.
 * Copyright 2014, SlevenBits, Ltd. All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>


@implementation AppController : CPObject
{
    @outlet CPWindow    window1;
    @outlet CPWindow    window2;
    @outlet CPTableView tableView;
    @outlet CPOutlineView outlineView;
    @outlet CPTokenField tokenField;
    @outlet CPArrayController arrayController1;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.
    [arrayController1 setContent:@[
        @{'animal': 'cat', 'legs': 4},
        @{'animal': 'duck', 'legs': 2},
        @{'animal': 'centipede', 'legs': 100},
    ]];
}

@end
