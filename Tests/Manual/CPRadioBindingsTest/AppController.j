/*
 * AppController.j
 * CPRadioBindings
 *
 * Created by You on February 22, 2013.
 * Copyright 2013, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    @outlet CPWindow        theWindow;
    @outlet CPRadioGroup    radios @accessors;
    CPString                title @accessors;
    int                     index @accessors;
    int                     tag @accessors;
    BOOL                    enabled @accessors;
    BOOL                    visible @accessors;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    [self setTitle:@"Two"];
    [self setIndex:2];
    [self setTag:13];
    [self setEnabled:YES];
    [self setVisible:YES];
}

- (@action)deselectAll:(id)sender
{
    [radios selectRadioAtIndex:-1];
}

@end
