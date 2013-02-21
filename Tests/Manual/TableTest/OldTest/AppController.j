@import <Foundation/CPObject.j>

tableTestDragType = @"CPTableViewTestDragType";

@implementation AppController : CPObject
{
    CPTableView tableView;
    CPTableView tableView2;
    CPTableView tableView3;
    CPImage     iconImage;
    CPArray     dataSet1;
    CPArray     dataSet2;
    CPArray     dataSet3;

    CPTableColumn randomColumn;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    dataSet1 = [],
    dataSet2 = [],
    dataSet3 = [];

    for (var i = 1; i < 10; i++)
    {
        dataSet1[i - 1] = [CPNumber numberWithInt:i];
        dataSet2[i - 1] = [CPNumber numberWithInt:i + 10];
        dataSet3[i - 1] = [CPNumber numberWithInt:i + 20];
    }

    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(50,50,700,500) styleMask:CPClosableWindowMask],
        contentView = [theWindow contentView],
        label = [CPTextField new];

    [label setStringValue:@"This table refuses to become the first responder but can still be interacted with."];
    [label sizeToFit];
    [label setFrameOrigin:CGPointMake(200, 10)]
    [contentView addSubview:label];

    tableView = [[CUTableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 400.0, 400.0)];

    [tableView setAllowsMultipleSelection:YES];
    [tableView setAllowsColumnSelection:YES];
    [tableView setUsesAlternatingRowBackgroundColors:YES];
    [tableView setAlternatingRowBackgroundColors:[[CPColor whiteColor], [CPColor colorWithHexString:@"e4e7ff"], [CPColor colorWithHexString:@"f4e7ff"]]];
    [tableView setGridStyleMask:CPTableViewSolidHorizontalGridLineMask | CPTableViewSolidVerticalGridLineMask];
    [tableView setVerticalMotionCanBeginDrag:NO];
    [tableView setDraggingDestinationFeedbackStyle:CPTableViewDropOn];
    [tableView registerForDraggedTypes:[CPArray arrayWithObject:tableTestDragType]];
    [tableView setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [tableView setDelegate:self];
    [tableView setSelectionHighlightColor:[CPColor redColor]];
    [tableView setDataSource:self];

    var iconView = [[CPImageView alloc] initWithFrame:CGRectMake(16, 16, 0, 0)];
    [iconView setImageScaling:CPImageScaleNone];

    var iconColumn = [[CPTableColumn alloc] initWithIdentifier:"icons"];
    [iconColumn setWidth:32.0];
    [iconColumn setMinWidth:32.0];
    [iconColumn setDataView:iconView];
    [tableView addTableColumn:iconColumn];
    iconImage = [[CPImage alloc] initWithContentsOfFile:"http://cappuccino-project.org/images/favicon.png" size:CGSizeMake(16,16)];


    var desc = [CPSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];

    for (var i = 1; i <= 5; i++)
    {
        var column = [[CPTableColumn alloc] initWithIdentifier:String(i)];
        [column setSortDescriptorPrototype:desc];
        [[column headerView] setStringValue:"Number " + i];

        [column setMinWidth:50.0];
        [column setMaxWidth:500.0];
        [column setWidth:75.0];

        [column setEditable:YES];
        [tableView addTableColumn:column];

        if (i === 2)
            randomColumn = column;
    }

    [tableView setAutosaveTableColumns:YES];
    [tableView setAutosaveName:@"TableTest"];

    // we offset this scrollview to make sure all the coordinates are calculated correctly
    // bad things can happen when the tableview doesn't sit at (0,0)
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(200, 50, CGRectGetWidth([contentView bounds]) - 200, CGRectGetHeight([contentView bounds]) -200)];

    [scrollView setDocumentView:tableView];
    [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    [contentView addSubview:scrollView];

    [theWindow orderFront:self];
    [self newWindow];
    [self sourceList];

    var button = [[CPButton alloc] initWithFrame:CGRectMake(10,10,100, 24)];
    [button setTitle:@"Remove Row"];
    [button setTarget:self];
    [button setAction:@selector(removeRow:)];
    [contentView addSubview:button];

    var button = [[CPButton alloc] initWithFrame:CGRectMake(10,40,100, 24)];
    [button setTitle:@"Add Row"];
    [button setTarget:self];
    [button setAction:@selector(addRow:)];
    [contentView addSubview:button];

    var button = [[CPButton alloc] initWithFrame:CGRectMake(10,70,100, 24)];
    [button setTitle:@"Switch Highlight"];
    [button setTarget:self];
    [button setAction:@selector(switchSelectionHighlightType:)];
    [contentView addSubview:button];

    var button = [[CPButton alloc] initWithFrame:CGRectMake(10,100,100, 24)];
    [button setTitle:@"Hide Column"];
    [button setTarget:self];
    [button setAction:@selector(hideColumn:)];
    [contentView addSubview:button];

    var button = [[CPButton alloc] initWithFrame:CGRectMake(10,130,100, 24)];
    [button setTitle:@"Remove Column"];
    [button setTarget:self];
    [button setAction:@selector(removeColumn:)];
    [contentView addSubview:button];

    var button = [[CPButton alloc] initWithFrame:CGRectMake(10,160,100, 24)];
    [button setTitle:@"Add Column"];
    [button setTarget:self];
    [button setAction:@selector(addColumn:)];
    [contentView addSubview:button];

    var sourceListActiveGradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [255.0 / 255.0, 153.0 / 255.0, 209.0 / 255.0, 1.0, 33.0 / 255.0, 94.0 / 255.0, 208.0 / 255.0, 1.0], [0, 1], 2),
        sourceListActiveTopLineColor = [CPColor colorWithCalibratedRed:(255.0 / 255.0) green:(123.0 / 255.0) blue:(218.0 / 255.0) alpha:1.0],
        sourceListActiveBottomLineColor = [CPColor colorWithCalibratedRed:(255.0 / 255.0) green:(92.0 / 255.0) blue:(207.0 / 255.0) alpha:1.0];
    [tableView setSelectionGradientColors:[CPDictionary dictionaryWithObjects:[sourceListActiveGradient, sourceListActiveTopLineColor, sourceListActiveBottomLineColor] forKeys:[CPSourceListGradient, CPSourceListTopLineColor, CPSourceListBottomLineColor]]];
}

- (void)switchSelectionHighlightType:(id)sender
{
    [tableView setSelectionHighlightStyle: ABS([tableView selectionHighlightStyle] - 1)];
}

- (void)removeRow:(id)sender
{
    [dataSet1 removeObjectAtIndex:0];
    [tableView reloadData];
}

- (void)addRow:(id)sender
{
    [dataSet1 addObject:[dataSet1 count] || 0];
    [tableView reloadData];
}

- (void)hideColumn:(id)sender
{
    [randomColumn setHidden:![randomColumn isHidden]];
}

- (void)removeColumn:(id)sender
{
   // if ([[tableView tableColumns] containsObject:randomColumn])
        [tableView removeTableColumn:randomColumn];
    //else
      //  [tableView addTableColumn:randomColumn];
}

- (void)addColumn:(id)sender
{
     var column = [[CPTableColumn alloc] initWithIdentifier:"NewColumn"];
    [[column headerView] setStringValue:"New Column"];

    [column setMinWidth:50.0];
    [column setMaxWidth:500.0];
    [column setWidth:75.0];

    [tableView addTableColumn:column];
}

- (void)newWindow
{
    var window2 = [[CPWindow alloc] initWithContentRect:CGRectMake(450, 50, 500, 400) styleMask:CPTitledWindowMask | CPResizableWindowMask];

    tableView2 = [[CPTableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 500.0, 500.0)];

    [tableView2 setAllowsMultipleSelection:YES];
    [tableView2 setUsesAlternatingRowBackgroundColors:YES];
    [tableView2 setGridStyleMask:CPTableViewSolidHorizontalGridLineMask | CPTableViewSolidVerticalGridLineMask];
    [tableView2 setVerticalMotionCanBeginDrag:NO];
    [tableView2 registerForDraggedTypes:[CPArray arrayWithObject:tableTestDragType]];
    [tableView2 setDraggingDestinationFeedbackStyle:CPTableViewDropAbove];
    [tableView2 setDelegate:self];
    [tableView2 setDataSource:self];

    var checkBox = [[CPCheckBox alloc] initWithFrame:CGRectMake(5,3,24,24)],
        checkBoxColumn = [[CPTableColumn alloc] initWithIdentifier:@"checkBox"];
    [checkBoxColumn setDataView:checkBox];

    [tableView2 addTableColumn:checkBoxColumn];

    var desc = [CPSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];

    for (var i = 1; i <= 3; i++)
    {
        var column = [[CPTableColumn alloc] initWithIdentifier:String(i)];
        [column setSortDescriptorPrototype:desc];
        [[column headerView] setStringValue:"Number "+i];

        [column setWidth:i * 75];
        [column setMinWidth:50.0];

        [column setEditable:YES];

        [tableView2 addTableColumn:column];
    }

    [tableView2 setColumnAutoresizingStyle:CPTableViewUniformColumnAutoresizingStyle];

    var scrollView = [[CPScrollView alloc] initWithFrame:[[window2 contentView] bounds]];
    [tableView2 setRowHeight:32.0];
    [scrollView setDocumentView:tableView2];
    [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    [[window2 contentView] addSubview:scrollView];

    //[scrollView setAutohidesScrollers:YES];

    [window2 orderFront:self];
}

- (void)sourceList
{
    var window3 = [[CPWindow alloc] initWithContentRect:CGRectMake(450, 250, 500, 400) styleMask:CPTitledWindowMask | CPResizableWindowMask];

    tableView3 = [[CPTableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 500.0)];

    [tableView3 setAllowsMultipleSelection:NO];
    [tableView3 setUsesAlternatingRowBackgroundColors:NO];
    [tableView3 setGridStyleMask:CPTableViewGridNone];
    [tableView3 setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleSourceList];
    [tableView3 setColumnAutoresizingStyle:CPTableViewUniformColumnAutoresizingStyle];
    [tableView3 setVerticalMotionCanBeginDrag:NO];
    [tableView3 setDelegate:self];
    [tableView3 setDataSource:self];

    var column = [[CPTableColumn alloc] initWithIdentifier:"sourcelist"];
    [[column headerView] setStringValue:"Source List"];

    [column setWidth:200.0];
    [column setMinWidth:50.0];
    [column setEditable:YES];
    [tableView3 addTableColumn:column];

    var column = [[CPTableColumn alloc] initWithIdentifier:"sourcelist2"];
    [[column headerView] setStringValue:"Source List 2"];
    [tableView3 addTableColumn:column];

    var scrollView3 = [[CPScrollView alloc] initWithFrame:[[window3 contentView] bounds]];
    [tableView3 setRowHeight:32.0];
    [scrollView3 setDocumentView:tableView3];
    [scrollView3 setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    var sourceListActiveGradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [255.0 / 255.0, 153.0 / 255.0, 209.0 / 255.0, 1.0, 33.0 / 255.0, 94.0 / 255.0, 208.0 / 255.0, 1.0], [0, 1], 2),
        sourceListActiveTopLineColor = [CPColor colorWithCalibratedRed:(255.0 / 255.0) green:(123.0 / 255.0) blue:(218.0 / 255.0) alpha:1.0],
        sourceListActiveBottomLineColor = [CPColor colorWithCalibratedRed:(255.0 / 255.0) green:(92.0 / 255.0) blue:(207.0 / 255.0) alpha:1.0];
    [tableView3 setSelectionGradientColors:[CPDictionary dictionaryWithObjects:[sourceListActiveGradient, sourceListActiveTopLineColor, sourceListActiveBottomLineColor] forKeys:[CPSourceListGradient, CPSourceListTopLineColor, CPSourceListBottomLineColor]]];

    [[window3 contentView] addSubview:scrollView3];

    [scrollView3 setAutohidesScrollers:YES];

    [window3 orderFront:self];
}

- (int)numberOfRowsInTableView:(CPTableView)atableView
{
    if (atableView === tableView)
        return dataSet1.length;
    else if (atableView === tableView2)
        return dataSet2.length;
    else if (atableView === tableView3)
        return dataSet3.length;
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aColumn row:(int)aRow
{
    if ([aColumn identifier] === "icons")
        return iconImage;

    if (aTableView === tableView)
        return String(dataSet1[aRow] * ([[aTableView tableColumns] indexOfObject:aColumn] + 1));
    else if (aTableView === tableView2)
        return String(dataSet2[aRow]);
    else if (aTableView === tableView3)
        return String(dataSet3[aRow]);
}

- (void)tableView:(CPTableView)aTableView sortDescriptorsDidChange:(CPArray)oldDescriptors
{
    //CPLogConsole(_cmd + [oldDescriptors description]);

    var newDescriptors = [aTableView sortDescriptors];

    [(aTableView === tableView) ? dataSet1:dataSet2 sortUsingDescriptors:newDescriptors];
    [aTableView reloadData];
}

- (BOOL)tableView:(CPTableView)aTableView shouldSelectRow:(int)rowIndex
{
    CPLog.debug(@"tableView:shouldSelectRow");
    return true;
}

- (BOOL)selectionShouldChangeInTableView:(CPTableView)aTableView
{
    //CPLog.debug(@"selectionShouldChangeInTableView");
    return YES;
}

- (void)tableViewSelectionDidChange:(id)notification
{
    CPLogConsole(_cmd + [notification description]);
}

- (void)tableViewSelectionIsChanging:(id)notification
{
    CPLogConsole(_cmd + [notification description]);
}

- (void)_tableViewColumnDidResize:(id)notification
{
    CPLogConsole(_cmd + [notification description]);
}

- (BOOL)tableView:(CPTableView)aTableView shouldEditTableColumn:(CPTableColumn)tableColumn row:(int)row
{
    if (aTableView === tableView3)
        return YES;
    else
        return NO;
}

- (void)tableView:(CPTableView)aTableView willDisplayView:(CPView)aView forTableColumn:(CPTableColumn)tableColumn row:(int)row
{
    //CPLogConsole(_cmd + " column: " + [tableColumn identifier] + " row:" + row)
}

- (void)tableView:(CPTableView)aTableView setObjectValue:(id)aValue forTableColumn:(CPTableColumn)tableColumn row:(int)row
{
    if (aTableView === tableView3)
        dataSet3[row] = aValue;
}

- (void)tableView:(CPTableView)aTableView sortDescriptorsDidChange:(CPArray)oldDescriptors
{
    //CPLogConsole(_cmd + [oldDescriptors description]);

    var newDescriptors = [aTableView sortDescriptors];

    [(aTableView === tableView) ? dataSet1:dataSet2 sortUsingDescriptors:newDescriptors];
    [aTableView reloadData];
}

- (BOOL)tableView:(CPTableView)aTableView writeRowsWithIndexes:(CPIndexSet)rowIndexes toPasteboard:(CPPasteboard)pboard
{
    if (aTableView === tableView3)
        return NO;

    var data = [rowIndexes, [aTableView UID]];

    var encodedData = [CPKeyedArchiver archivedDataWithRootObject:data];
    [pboard declareTypes:[CPArray arrayWithObject:tableTestDragType] owner:self];
    [pboard setData:encodedData forType:tableTestDragType];

    return YES;
}

- (CPDragOperation)tableView:(CPTableView)aTableView
                   validateDrop:(id)info
                   proposedRow:(CPInteger)row
                   proposedDropOperation:(CPTableViewDropOperation)operation
{

    [[aTableView window] orderFront:nil];

    if (aTableView === tableView)
        [aTableView setDropRow:row dropOperation:CPTableViewDropOn];
    else
        [aTableView setDropRow:row dropOperation:CPTableViewDropAbove];

    return CPDragOperationMove;
}

- (BOOL)tableView:(CPTableView)aTableView acceptDrop:(id)info row:(int)row dropOperation:(CPTableViewDropOperation)operation
{
    var pboard = [info draggingPasteboard],
        rowData = [pboard dataForType:tableTestDragType],
        tables = [tableView, tableView2],
        dataSets = [dataSet1, dataSet2];

    rowData = [CPKeyedUnarchiver unarchiveObjectWithData:rowData];

    var sourceIndexes = rowData[0],
        sourceTableUID = rowData[1];

    var index = (aTableView == tableView) ? 1 : 0;

    var destinationTable = tables[1 - index],
        sourceTable = tables[index],
        destinationDataSet = dataSets[1 - index],
        sourceDataSet = dataSets[index];

    if (operation & CPDragOperationMove)
    {
        if (sourceTableUID == [aTableView UID])
        {
            [destinationDataSet moveIndexes:sourceIndexes toIndex:row];
            [destinationTable reloadData];
            var destIndexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(row, [sourceIndexes count])];
            [destinationTable selectRowIndexes:destIndexes byExtendingSelection:NO];
        }
        else
        {
            var destIndexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(row, [sourceIndexes count])],
                sourceObjects = [sourceDataSet objectsAtIndexes:sourceIndexes];

            [destinationDataSet insertObjects:sourceObjects atIndexes:destIndexes];
            [destinationTable reloadData];
            [destinationTable selectRowIndexes:destIndexes byExtendingSelection:NO];

            [sourceDataSet removeObjectsAtIndexes:sourceIndexes];
            [sourceTable reloadData];
            [sourceTable selectRowIndexes:[CPIndexSet indexSet] byExtendingSelection:NO];
        }
    }

    return YES;
}

- (void)tableView:(CPTableView)aTableView didEndDraggedImage:(CPImage)anImage atPosition:(CGPoint)aPoint operation:(CPDragOperation)anOperation
{
    //for convenience
}

- (void)tableView:(CPTableView)aTableView didClickTableColumn:(CPTableColumn)aColumn
{
    //CPLog.debug("table: "+aTableView+" clicked column: "+aColumn);
}

@end

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


@implementation CUTableView : CPTableView
{

}

- (BOOL)acceptsFirstResponder
{
    return NO;
}

@end
