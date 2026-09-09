/*
 * AppController.j
 * CPTimeZone
 *
 * Created by You on April 16, 2013.
 * Copyright 2013, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>


@implementation AppController : CPObject
{
    @outlet CPWindow        theWindow;
    @outlet CPDatePicker    datePicker;
    @outlet CPPopUpButton   popUpButton;
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
    [datePicker setDateValue:[CPDate date]];
    [popUpButton addItemsWithTitles:[CPTimeZone knownTimeZoneNames]];
    [datePicker setTimeZone:[CPTimeZone timeZoneWithName:[[CPTimeZone knownTimeZoneNames] firstObject]]];
}

- (@action)changedTimeZone:(id)sender
{
    [datePicker setTimeZone:[CPTimeZone timeZoneWithName:[[CPTimeZone knownTimeZoneNames] objectAtIndex:[sender selectedIndex ]]]];
}

@end
