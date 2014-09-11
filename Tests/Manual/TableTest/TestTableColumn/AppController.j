/*
 * AppController.j
 * TestTableColumn
 *
 * Created by You on April 16, 2013.
 * Copyright 2013, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "../../CPTrace.j"

@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow;
    @outlet CPTableView tableView;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
    CPTrace("CPTableView", "_unloadDataViewsInRows:columns:");
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];

    [self _initializeSpreadSheetColumns];
}

- (void)_initializeSpreadSheetColumns
{
    var itemIndex = 0,
        items = [@"Colonne1", @"Colonne2", @"Colonne3", @"Colonne4"];

    for (itemIndex ; itemIndex < [items count]; itemIndex++)
    {
        var item = [items objectAtIndex:itemIndex],
            column = [[CPTableColumn alloc] initWithIdentifier:itemIndex];
        [column setEditable:YES];
        [column setMinWidth:50];
        [[column headerView] setStringValue:item];
        [tableView addTableColumn:column];
    }
}

- (@action)click:(id)sender
{
    console.log("Before NumberOfColumns : " + [[tableView tableColumns] count]);

    [tableView removeTableColumn:[[tableView tableColumns] firstObject]];

    console.log("After NumberOfColumns : " + [[tableView tableColumns] count]);
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return 15;
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aColumn row:(int)aRowIndex
{
    return 10;
}

@end
