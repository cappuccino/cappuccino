/*
 * AppController.j
 * CPDictionaryControllerTest
 *
 * Created by Blair Duncan on February 17, 2013.
 * Copyright 2013, SGL Studio, BBDO Toronto All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPDictionaryController.j>


@implementation AppController : CPObject
{
    @outlet CPWindow        theWindow;
    CPDictionaryController  dictionaryController @accessors;
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
    [dictionaryController setContent:[CPDictionary dictionaryWithObjectsAndKeys:@"Blair", @"FirstName", @"Duncan", @"LastName", @"Toronto", @"City"]];
    [theWindow setFullPlatformWindow:YES];
}

@end
