/*
 * AppController.j
 * CappDoc
 *
 * Created by You on May 24, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import "Document.j"
@import "DocumentController.j"

@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)applicationWillFinishLaunching:(CPNotification)aNotification
{
    // instantiate a subclass of DocumentController
    [[DocumentController alloc] init];
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.
}

@end
