/*
 * AppController.j
 * DragAndDrop
 *
 * Created by Mike Fellows on December 10, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <Foundation/CPIndexSet.j>
@import <Foundation/CPRange.j>

TableTestDragAndDropTableViewDataType = @"TableTestDragAndDropTableViewDataType";

@implementation AppController : CPObject
{
    CPArray rowList;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],
        scroll = [[CPScrollView alloc] initWithFrame:[contentView bounds]],
        count = 100;

    rowList = [];
    while (count--)
        rowList[count] = count;

    [scroll setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    var table = [[CPTableView alloc] initWithFrame:CGRectMakeZero()];
    [table setDataSource:self];
    [table setDelegate:self];
    [table setColumnAutoresizingStyle:CPTableViewUniformColumnAutoresizingStyle];
    [table setUsesAlternatingRowBackgroundColors:YES];
    [table registerForDraggedTypes:[CPArray arrayWithObjects:TableTestDragAndDropTableViewDataType]];

    [table setGridStyleMask:CPTableViewSolidVerticalGridLineMask | CPTableViewSolidHorizontalGridLineMask];
    [table setAllowsMultipleSelection:YES];

    [table setIntercellSpacing:CGSizeMake(0,0)];

    var columnIndex = [[CPTableColumn alloc] initWithIdentifier:"Row"];
    [table addTableColumn:columnIndex];
    [[columnIndex headerView] setStringValue:"Row"];
    [columnIndex setWidth:50];

    var columnA = [[CPTableColumn alloc] initWithIdentifier:"A"];
    [table addTableColumn:columnA];
    [[columnA headerView] setStringValue:"A"];
    [columnA setWidth:175];

    var columnB = [[CPTableColumn alloc] initWithIdentifier:"B"];
    [table addTableColumn:columnB];
    [[columnB headerView] setStringValue:"B"];
    [columnB setWidth:175];

    var columnC = [[CPTableColumn alloc] initWithIdentifier:"C"];
    [table addTableColumn:columnC];
    [[columnC headerView] setStringValue:"C"];
    [columnC setWidth:175];

    var columnD = [[CPTableColumn alloc] initWithIdentifier:"D"];
    [table addTableColumn:columnD];
    [[columnD headerView] setStringValue:"D"];
    [columnD setWidth:175];

    var columnE = [[CPTableColumn alloc] initWithIdentifier:"E"];
    [table addTableColumn:columnE];
    [[columnE headerView] setStringValue:"E"];
    [columnE setWidth:175];

    var columnF = [[CPTableColumn alloc] initWithIdentifier:"F"];
    [table addTableColumn:columnF];
    [[columnF headerView] setStringValue:"F"];
    [columnF setWidth:175];

    var columnG = [[CPTableColumn alloc] initWithIdentifier:"G"];
    [table addTableColumn:columnG];
    [[columnG headerView] setStringValue:"G"];
    [columnG setWidth:175];

    var columnH = [[CPTableColumn alloc] initWithIdentifier:"H"];
    [table addTableColumn:columnH];
    [[columnH headerView] setStringValue:"H"];
    [columnH setWidth:175];

    [scroll setDocumentView:table];

    [contentView addSubview:scroll];

    [theWindow orderFront:self];
}

- (int)numberOfRowsInTableView:(id)tableView
{
    return [rowList count];
}

- (id)tableView:(id)tableView objectValueForTableColumn:(CPTableColumn)aColumn row:(CPInteger)aRow
{
    if ([aColumn identifier] == "Row")
        return aRow;
    else
        return "Col " + [aColumn identifier] + ", Started as Row " + rowList[aRow];
}

// Drag and Drop methods.

- (BOOL)tableView:(CPTableView)aTableView writeRowsWithIndexes:(CPIndexSet)rowIndexes toPasteboard:(CPPasteboard)pasteboard
{
    var encodedData = [CPKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pasteboard declareTypes:[CPArray arrayWithObject:TableTestDragAndDropTableViewDataType] owner:self];
    [pasteboard setData:encodedData forType:TableTestDragAndDropTableViewDataType];

    return YES;
}

- (CPDragOperation)tableView:(CPTableView)aTableView validateDrop:(id)info proposedRow:(CPInteger)row proposedDropOperation:(CPTableViewDropOperation)operation
{
    [aTableView setDropRow:row dropOperation:CPTableViewDropAbove];
    return CPDragOperationMove;
}

- (BOOL)tableView:(CPTableView)aTableView acceptDrop:(id)info row:(CPInteger)row dropOperation:(CPTableViewDropOperation)operation
{
    var pasteboard = [info draggingPasteboard],
        encodedData = [pasteboard dataForType:TableTestDragAndDropTableViewDataType],
        sourceIndexes = [CPKeyedUnarchiver unarchiveObjectWithData:encodedData],
        firstDestinationObject,
        destinationRange,
        destinationIndexes;

    if (operation == CPTableViewDropAbove)
    {
        // Save the first object in the list so we can determine where the
        // beginning of the moved block begins once all the selected rows have
        // been moved.
        firstDestinationObject = [rowList objectAtIndex:[sourceIndexes
        firstIndex]];

        [rowList moveIndexes:sourceIndexes toIndex:row];

        // Select the rows we just moved.
        destinationRange = CPMakeRange([rowList indexOfObject:firstDestinationObject], [sourceIndexes count]);
        destinationIndexes = [CPIndexSet indexSetWithIndexesInRange:destinationRange];
        [aTableView selectRowIndexes:destinationIndexes byExtendingSelection:NO];
    }

    return YES;
}

@end


// Add a supporting helper method to CPArray to move a set of indexes to another index
// Used to implement drag-and-drop

@implementation CPArray (MoveIndexes)

- (void)moveIndexes:(CPIndexSet)indexes toIndex:(int)insertIndex
{
    var aboveCount = 0,
        object,
        removeIndex;

    var index = [indexes lastIndex];

    while (index != CPNotFound)
    {
        if (index >= insertIndex)
        {
            removeIndex = index + aboveCount;
            aboveCount ++;
        }
        else
        {
            removeIndex = index;
            insertIndex --;
        }

        object = [self objectAtIndex:removeIndex];
        [self removeObjectAtIndex:removeIndex];
        [self insertObject:object atIndex:insertIndex];

        index = [indexes indexLessThanIndex:index];
    }
}

@end
