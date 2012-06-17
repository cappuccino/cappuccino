/*
 * AppController.j
 * CPTableViewLionCibTest
 *
 * Created by You on March 8, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>

var TABLE_DRAG_TYPE = @"TABLE_DRAG_TYPE",
    tracing = NO;

@import "../CPTableView+Debug.j"

@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    @outlet CPTableView tableView;
    @outlet CPTextField textField;
    @outlet CPArrayController contentController;

    CPArray content @accessors;
}

- (void)applicationDidFinishLaunching:(CPNotification)note
{
    content = [CPArray new];

    var path = [[CPBundle mainBundle] pathForResource:@"Data.plist"],
        request = [CPURLRequest requestWithURL:path],
        connection = [CPURLConnection connectionWithRequest:request delegate:self];

    [theWindow setFullBridge:YES];
    [tableView registerForDraggedTypes:[CPArray arrayWithObject:TABLE_DRAG_TYPE]];
}

- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)dataString
{
    if (!dataString)
        return;

    var data = [[CPData alloc] initWithRawString:dataString],
        theRows = [CPPropertyListSerialization propertyListFromData:data format:CPPropertyListXMLFormat_v1_0];

    [self setContent:theRows];
}

- (void)tableView:(CPTableView)aTableView dataViewForTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
{
    var identifier = [aTableColumn identifier];

    if (identifier != @"Description")
        identifier = [[content objectAtIndex:aRow] objectForKey:@"identifier"];

    var view = [aTableView makeViewWithIdentifier:identifier owner:self];

    if (view == nil)
        view = [[CPTableCellView alloc] initWithFrame:CGRectMakeZero()];

    return view;
}

- (BOOL)tableView:(CPTableView)aTableView writeRowsWithIndexes:(CPIndexSet)rowIndexes toPasteboard:(CPPasteboard)pboard
{
    [pboard declareTypes:[CPArray arrayWithObject:TABLE_DRAG_TYPE] owner:self];
    [pboard setData:rowIndexes forType:TABLE_DRAG_TYPE];

    return YES;
}

- (CPDragOperation)tableView:(CPTableView)aTableView
                   validateDrop:(id)info
                   proposedRow:(CPInteger)row
                   proposedDropOperation:(CPTableViewDropOperation)operation
{

    [aTableView setDropRow:row dropOperation:CPTableViewDropAbove];

    return CPDragOperationMove;
}

- (BOOL)tableView:(CPTableView)aTableView acceptDrop:(id)info row:(int)row dropOperation:(CPTableViewDropOperation)operation
{
    var pboard = [info draggingPasteboard],
        sourceIndexes = [pboard dataForType:TABLE_DRAG_TYPE],
        firstObject = [content objectAtIndex:[sourceIndexes firstIndex]];

    [content moveIndexes:sourceIndexes toIndex:row];
    [contentController rearrangeObjects];

        // Select the rows we just moved.
    var destinationRange = CPMakeRange([content indexOfObject:firstObject], [sourceIndexes count]),
        selectIndexes = [CPIndexSet indexSetWithIndexesInRange:destinationRange];

    [aTableView selectRowIndexes:selectIndexes byExtendingSelection:NO];

    return YES;
}

- (void)awakeFromCib
{
    // Called each time a cib containing a CPTableCellView is instantiated because we set the owner to self. Certainly a better idea to have a separate table view delegate if you need awakeFromCib to do some initialization in the AppController.
    CPLogConsole(_cmd + textField);
}

- (IBAction)_sliderAction:(id)sender
{
    // Action sent from a cellView subview. You can access outlets (built-in or custom) defined in CPTableCellView or a subclass if you define the same outlets in the owner class.In this example, the owner is self.
    CPLogConsole(_cmd);
}

- (IBAction)trace:(id)sender
{
    if (tracing)
        return;

    [CPTableView profileViewLoading];
    tracing = YES;
}

@end

@implementation CPArray (MoveIndexes)

- (void)moveIndexes:(CPIndexSet)indexes toIndex:(int)insertIndex
{
    var aboveCount = 0,
        object,
        removeIndex,
        index = [indexes lastIndex];

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
