/*
 * AppController.j
 * CPTabViewBindings
 *
 * Created by You on February 25, 2015.
 * Copyright 2015, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

CPLogRegister(CPLogConsole);

var ITEM_NUMBER = 0;

@implementation ArrayController : CPArrayController

- (id)newObject
{
    var n = ITEM_NUMBER++;
    var item = [[CPTabViewItem alloc] initWithIdentifier:@"Item" + n];
    [item setLabel:@"Item " + n];
    var view = [[CPView alloc] initWithFrame:CGRectMake(0,0,100,100)];
    [view setBackgroundColor:[CPColor randomColor]];
    [item setView:view];

    return item;
}

@end

@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow;
    @outlet CPTabView   tabView;
    @outlet ArrayController   arrayController;
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

    [tabView bind:CPContentBinding toObject:arrayController withKeyPath:@"arrangedObjects" options:nil];
    [tabView bind:CPSelectionIndexesBinding toObject:arrayController withKeyPath:@"selectionIndexes" options:nil];
    [tabView bind:CPSelectedIndexBinding toObject:arrayController withKeyPath:@"selectedIndex" options:nil];
    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];
}

- (@action)preserveSelection:(id)sender
{
    [arrayController setPreservesSelection:[sender state]];
}

- (@action)avoidsEmpty:(id)sender
{
    [arrayController setAvoidsEmptySelection:[sender state]];
}

- (@action)selectsInserted:(id)sender
{
    [arrayController setSelectsInsertedObjects:[sender state]];
}

- (@action)usesMultipleValuesMarker:(id)sender
{
    [arrayController setAlwaysUsesMultipleValuesMarker:[sender state]];
}

@end
