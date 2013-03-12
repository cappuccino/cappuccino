/*
 * AppController.j
 * CPTableViewLionCibTest
 *
 * Created by You on March 8, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPGraphicsContext.j>

var TABLE_DRAG_TYPE = @"TABLE_DRAG_TYPE";

CPLogRegister(CPLogConsole)

@implementation AppController : CPObject
{
    CPWindow theWindow; //this "outlet" is connected automatically by the Cib
    @outlet CPTableView tableView @accessors(getter=tableView);

    CPArray content           @accessors;
}

- (IBAction)reload:(id)sender
{
    [tableView reloadData];
}

- (void)applicationDidFinishLaunching:(CPNotification)note
{
    content = [CPArray new];

    var path = [[CPBundle mainBundle] pathForResource:@"Data.plist"],
        request = [CPURLRequest requestWithURL:path],
        connection = [CPURLConnection connectionWithRequest:request delegate:self];

    [tableView registerForDraggedTypes:[CPArray arrayWithObject:TABLE_DRAG_TYPE]];
}

- (void)awakeFromCib
{
    [theWindow setFullPlatformWindow:YES];
}

- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)dataString
{
    if (!dataString)
        return;

    var data = [[CPData alloc] initWithRawString:dataString],
        theRows = [CPPropertyListSerialization propertyListFromData:data format:CPPropertyListXMLFormat_v1_0];

    [self setContent:theRows];
}

@end

@implementation TableViewDelegate : CPObject
{
    @outlet CPView externalView;
    @outlet CPView personView;
    @outlet CPView placeView;
    @outlet CPArrayController contentController;

    @outlet CPTableCellView view;
    @outlet CPImageView imageView;
    @outlet CPTextField textField;

    CPTableView tableView;
    CPArray     content;
    CPArray     images            @accessors;
    BOOL        variableRowHeight @accessors;
}

- (id)init
{
    self = [super init];

    images = [
                [CPDictionary dictionaryWithObjectsAndKeys:@"Brad",  @"name", @"Resources/brad.jpg"  ,@"path"],
                [CPDictionary dictionaryWithObjectsAndKeys:@"George",@"name", @"Resources/george.jpg",@"path"],
                [CPDictionary dictionaryWithObjectsAndKeys:@"John",  @"name", @"Resources/john.jpg"  ,@"path"]
             ];

    variableRowHeight = NO;

    return self;
}

- (CPView)makeOrangeView
{
    var orangeView = [[CustomView alloc] initWithFrame:CGRectMakeZero()];
    [orangeView setIdentifier:@"Orange"];

    return orangeView;
}

- (CPArray)content
{
    if (!content)
        content = [[CPApp delegate] content];

    return content;
}

- (CPTableView)tableView
{
    if (!tableView)
        tableView = [[CPApp delegate] tableView];

    return tableView;
}

// DELEGATE METHODS FOR THE TABLE VIEW
- (void)tableView:(CPTableView)aTableView viewForTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
{
    var identifier = [aTableColumn identifier];

    if (identifier == @"multiple")
        identifier = [[[self content] objectAtIndex:aRow] objectForKey:@"identifier"];

    var aView = [aTableView makeViewWithIdentifier:identifier owner:self];

    if (identifier == "Orange")
    {
        if (aView == nil)
            aView = [self makeOrangeView];

        [[aView textField] setStringValue:aRow];
    }

    return aView;
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

- (int)tableView:(CPTableView)aTableView heightOfRow:(int)aRow
{
    var height;

    if (!variableRowHeight || !(height = [[[self content] objectAtIndex:aRow] objectForKey:@"slider"]))
        return [aTableView rowHeight];

    return [height intValue];
}

- (void)awakeFromCib
{
    // self is the owner parameter specified in -makeViewWithIdentifier:owner:
    // This method is called each time a cib containing a CPTableCellView is instantiated.
    // Outlets are now connected and available.
    // If the view has its own xib, only the view will be instantiated and connected to the owner.
    if (externalView)
    {
        CPLog.debug(_cmd + " loaded externalView : " + externalView);
        [[externalView textField] setTextColor:[CPColor greenColor]];
    }
}

// CELL VIEWS ACTIONS
- (IBAction)_sliderAction:(id)sender
{
    if (variableRowHeight)
    {
        var table = [self tableView],
            row = [table rowForView:sender];

        [table noteHeightOfRowsWithIndexesChanged:[CPIndexSet indexSetWithIndex:row]];
        [table reloadData];
    }

    // Action sent from a cellView subview to its target.
    CPLog.debug(_cmd + " value=" + [sender intValue]);
}

- (IBAction)_textFieldNotBezeledAction:(id)sender
{
    CPLog.debug(_cmd + " value=" + [sender stringValue]);
}

- (IBAction)_textFieldBezeledAction:(id)sender
{
    CPLog.debug(_cmd + " value=" + [sender stringValue]);
}

@end

@implementation CustomView : CPView
{
    id objectValue @accessors;
    CPTextField textField @accessors;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:CGRectMake(0, 0, 50, 50)];

    textField = [[CPTextField alloc] initWithFrame:CGRectMake(5, 5, 40, 40)];
    [textField setFont:[CPFont systemFontOfSize:30]];
    [textField setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [self addSubview:textField];

    return self;
}

- (void)drawRect:(CGRect)aRect
{
    [[CPColor orangeColor] set];

    var ctx = [[CPGraphicsContext currentContext] graphicsPort];
    CGContextFillRect(ctx, aRect);
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
