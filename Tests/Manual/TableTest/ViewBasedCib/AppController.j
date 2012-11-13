/*
 * AppController.j
 * CPTableViewLionCibTest
 *
 * Created by You on March 8, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPGraphicsContext.j>

@import "../CPTrace.j"

var TABLE_DRAG_TYPE = @"TABLE_DRAG_TYPE",
    tracing = NO;

@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    @outlet CPTableView tableView;

    CPArray content   @accessors;
    float   avgPerRow @accessors;
}

- (void)applicationDidFinishLaunching:(CPNotification)note
{
    content = [CPArray new];
    avgPerRow = 0;

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

// TRACE UTILITY
- (IBAction)trace:(id)sender
{
    if ([sender state] == CPOnState)
    {
        var tlr = 0;
        var f = function(a,b,c,d,e,f,g)
        {
            var lr = [c[0] count];
            if (d > 0)
                tlr += lr;

            var avg = (ROUND(100 * e/tlr) / 100);
            console.log(b + " " + lr + " rows in " + d + " ms ; avg/row = " + avg + " ms");
            [self setAvgPerRow:avg];
        }

        CPTrace(@"CPTableView", @"_loadDataViewsInRows:columns:", f);
    }
    else
        CPTraceStop(@"CPTableView", @"_loadDataViewsInRows:columns:");
}

@end

@implementation TableViewDelegate : CPObject
{
    @outlet CPView externalView;
    @outlet CPView personView;
    @outlet CPView placeView;
    @outlet CPArrayController contentController;
}

- (CPView)makeOrangeView
{
    var view = [[CustomView alloc] initWithFrame:CGRectMakeZero()];
    [view setIdentifier:@"Orange"];

    return view;
}

// DELEGATE METHODS FOR THE TABLE VIEW
- (void)tableView:(CPTableView)aTableView dataViewForTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
{
    var identifier = [aTableColumn identifier],
        content = [[CPApp delegate] content];

    if (identifier == @"multiple")
        identifier = [[content objectAtIndex:aRow] objectForKey:@"identifier"];

    var view = [aTableView makeViewWithIdentifier:identifier owner:self];

    if (identifier == "Orange")
    {
        if (view == nil)
            view = [self makeOrangeView];
        [[view textField] setStringValue:aRow];
    }

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
    var content = [[CPApp delegate] content],
        pboard = [info draggingPasteboard],
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
    // self is the owner parameter specified in -makeViewWithIdentifier:owner:
    // This method is called each time a cib containing a CPTableCellView is instantiated.
    // Outlets are now connected and available.
    // If the view has its own xib, only the view will be instantiated and connected to the owner.
    CPLogConsole(_cmd + " externalView=" + externalView);
    [[externalView textField] setTextColor:[CPColor greenColor]];
}

// CELL VIEWS ACTIONS
- (IBAction)_sliderAction:(id)sender
{
    // Action sent from a cellView subview to its target.
    CPLogConsole(_cmd);
}

- (IBAction)_textFieldNotBezeledAction:(id)sender
{
    CPLogConsole(_cmd + " value=" + [sender stringValue]);
}

- (IBAction)_textFieldBezeledAction:(id)sender
{
    CPLogConsole(_cmd + " value=" + [sender stringValue]);
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
