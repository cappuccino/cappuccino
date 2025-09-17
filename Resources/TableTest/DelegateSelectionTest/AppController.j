/*
 * AppController.j
 * DelegateSelectionTest
 *
 * Created by You on October 16, 2013.
 * Copyright 2013, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>


@implementation AppController : CPObject
{
    CPArray _names;

    @outlet CPWindow    theWindow;
    @outlet CPTableView tableView;
    @outlet CPTableView secondTableView;
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
    _names = [@"Alexandre Wilhelm",  @"Alexander Ljungberg", @"Antoine Mercadal", @"Aparajita Fishman"];
    [tableView setAllowsMultipleSelection:YES];
    [tableView reloadData];

    [secondTableView setDelegate:[DelegateSecondTableView new]];
    [secondTableView reloadData];

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return [_names count];
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aColumn row:(CPInteger)aRowIndex
{
    return _names[aRowIndex];
}

- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    console.log(@"tableViewSelectionDidChange")
}

- (BOOL)selectionShouldChangeInTableView:(CPTableView)aTableView
{
    console.log(@"selectionShouldChangeInTableView")
    return YES;
}

- (BOOL)tableView:(CPTableView)aTableView shouldSelectRow:(CPInteger)rowIndex
{
    console.log(@"shouldSelectRow");
    return YES;
}

- (void)tableViewSelectionIsChanging:(CPNotification)aNotification
{
    console.log(@"tableViewSelectionIsChanging");
}

- (void)tableView:(CPTableView)tableView didClickTableColumn:(CPTableColumn)tableColumn;
{
    console.log(@"didClickTableColumn");
}

- (BOOL)tableView:(CPTableView)aTableView shouldSelectTableColumn:(CPTableColumn)aTableColumn
{
    console.log(@"shouldSelectTableColumn");
    return YES;
}

@end

@implementation DelegateSecondTableView : CPObject
{
}

- (id)init
{
    if (self = [super init])
    {
    }
    return self;
}

- (CPIndexSet)tableView:(CPTableView)tableView selectionIndexesForProposedSelection:(CPIndexSet)proposedSelectionIndexes
{
    console.log(@"selectionIndexesForProposedSelection")
    return proposedSelectionIndexes;
}

- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    console.log(@"tableViewSelectionDidChange")
}

- (BOOL)selectionShouldChangeInTableView:(CPTableView)aTableView
{
    console.log(@"selectionShouldChangeInTableView")
    return YES;
}

- (BOOL)tableView:(CPTableView)aTableView shouldSelectRow:(CPInteger)rowIndex
{
    console.log(@"shouldSelectRow");
    return YES;
}

- (BOOL)tableView:(CPTableView)aTableView shouldSelectTableColumn:(CPTableColumn)aTableColumn
{
    console.log(@"shouldSelectTableColumn");
    return YES;
}

- (void)tableViewSelectionIsChanging:(CPNotification)aNotification
{
    console.log(@"tableViewSelectionIsChanging");
}

- (void)tableView:(CPTableView)tableView didClickTableColumn:(CPTableColumn)tableColumn;
{
    console.log(@"didClickTableColumn");
}

@end
