/*
 * AppController.j
 * CPColorWellBindings
 *
 * Created by You on January 27, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    CPArray     array;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        array = [CPArray arrayWithObjects:[CPDictionary dictionaryWithObject:[CPColor redColor] forKey:@"color"],  [CPDictionary dictionaryWithObject:[CPNull null] forKey:@"color"], [CPDictionary dictionaryWithObject:[CPColor greenColor] forKey:@"color"]];
    }

    return self;
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
    [theWindow setFullPlatformWindow:YES];
}

@end
