/*
 * AppController.j
 * TestSheet
 *
 * Created by You on April 14, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>

@import "SheetWindowController.j"

@implementation AppController : CPObject
{
	SheetController _sheetController;
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

    // In this case, we want the window from Cib to become our full browser window
    //[theWindow setFullPlatformWindow:YES];
    
    _sheetController = [ [SheetWindowController alloc] initWithWindowCibName:@"Window"];
    [self newDocument:self];
}

- (void)newDocument:(id)sender
{
	 [_sheetController newWindow:self];
}

@end
