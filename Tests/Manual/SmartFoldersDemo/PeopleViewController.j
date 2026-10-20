/*
 * PeopleViewController.j
 * SmartFoldersDemo
 *
 * Right hand side of the main split view. Exercises:
 *   - CPArrayController with content, filterPredicate, sortDescriptors and
 *     selection (incl. setSelectedObjects: across content changes)
 *   - cell-based CPTableView fully driven by bindings (value, selection,
 *     sort descriptors), editable columns, formatters (CPDateFormatter,
 *     CPNumberFormatter), checkbox data views, column reordering/resizing,
 *     autosaved column state, alternating rows, grid lines
 *   - the table as drag source (rows -> source list groups)
 *   - CPPasteboard (copy / paste as tab separated text)
 *   - nested CPSplitView hosting a child view controller (detail pane)
 */

@import <AppKit/AppKit.j>
@import "Library.j"
@import "PersonDetailViewController.j"

@implementation PeopleViewController : CPViewController
{
    Library                     _library;
    CPArrayController           _arrayController;
    CPTableView                 _tableView;
    CPSplitView                 _splitView;
    CPView                      _tablePane;
    CPTextField                 _statusField;
    PersonDetailViewController  _detailController;
    CPString                    _contentTitle;
    float                       _lastDetailHeight;
}

- (id)initWithLibrary:(Library)aLibrary
{
    if (self = [super initWithCibName:nil bundle:nil])
    {
        _library = aLibrary;
        _contentTitle = @"";
        _lastDetailHeight = PersonDetailPreferredHeight;

        _arrayController = [[CPArrayController alloc] init];
        [_arrayController setEditable:YES];
        [_arrayController setAvoidsEmptySelection:NO];
        [_arrayController setPreservesSelection:YES];
        [_arrayController setSelectsInsertedObjects:YES];
        [_arrayController setSortDescriptors:[
            [CPSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES selector:@selector(caseInsensitiveCompare:)],
            [CPSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES selector:@selector(caseInsensitiveCompare:)]
        ]];

        [_arrayController addObserver:self forKeyPath:@"arrangedObjects" options:0 context:nil];
        [_arrayController addObserver:self forKeyPath:@"selectionIndexes" options:0 context:nil];
    }

    return self;
}

- (CPArrayController)arrayController
{
    return _arrayController;
}

- (CPTableView)tableView
{
    [self view];
    return _tableView;
}

- (void)loadView
{
    var frame = CGRectMake(0, 0, 800, 600),
        view = [[CPView alloc] initWithFrame:frame];

    [view setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    _splitView = [[CPSplitView alloc] initWithFrame:frame];
    [_splitView setVertical:NO];
    [_splitView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_splitView setDelegate:self];

    _tablePane = [self _buildTablePane:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame) - _lastDetailHeight)];
    [_splitView addSubview:_tablePane];

    _detailController = [[PersonDetailViewController alloc] initWithArrayController:_arrayController];
    var detailView = [_detailController view];
    [detailView setFrame:CGRectMake(0, 0, CGRectGetWidth(frame), _lastDetailHeight)];
    [_splitView addSubview:detailView];

    [view addSubview:_splitView];
    [self setView:view];

    if ([_splitView respondsToSelector:@selector(setAutosaveName:)])
        [_splitView setAutosaveName:@"SmartFoldersDemo.PeopleSplit"];

    [self _updateStatus];
}

- (CPView)_buildTablePane:(CGRect)aFrame
{
    var pane = [[CPView alloc] initWithFrame:aFrame],
        barHeight = 26.0;

    [pane setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(aFrame), CGRectGetHeight(aFrame) - barHeight)];
    [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setBorderType:CPNoBorder];

    _tableView = [[CPTableView alloc] initWithFrame:[[scrollView contentView] bounds]];
    [_tableView setUsesAlternatingRowBackgroundColors:YES];
    [_tableView setAllowsMultipleSelection:YES];
    [_tableView setAllowsEmptySelection:YES];
    [_tableView setAllowsColumnReordering:YES];
    [_tableView setAllowsColumnResizing:YES];
    [_tableView setAllowsColumnSelection:NO];
    [_tableView setGridStyleMask:CPTableViewSolidVerticalGridLineMask];
    [_tableView setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_tableView setRowHeight:24.0];
    [_tableView setIntercellSpacing:CGSizeMake(6.0, 0.0)];

    var dateFormatter = [[CPDateFormatter alloc] init];
    [dateFormatter setDateStyle:CPDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:CPDateFormatterNoStyle];

    var numberFormatter = [[CPNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:CPNumberFormatterDecimalStyle];

    [self _addColumn:@"lastName"    title:@"Last Name"  width:120 editable:YES dataView:nil];
    [self _addColumn:@"firstName"   title:@"First Name" width:110 editable:YES dataView:nil];
    [self _addColumn:@"department"  title:@"Department" width:110 editable:YES dataView:nil];
    [self _addColumn:@"city"        title:@"City"       width:110 editable:YES dataView:nil];
    [self _addColumn:@"age"         title:@"Age"        width:46  editable:NO  dataView:[self _textDataViewWithFormatter:nil alignment:CPRightTextAlignment]];
    [self _addColumn:@"birthDate"   title:@"Born"       width:110 editable:NO  dataView:[self _textDataViewWithFormatter:dateFormatter alignment:CPRightTextAlignment]];
    [self _addColumn:@"salary"      title:@"Salary"     width:90  editable:YES dataView:[self _textDataViewWithFormatter:numberFormatter alignment:CPRightTextAlignment]];

    // Title-less checkbox, image centred in the cell.
    var checkBox = [CPCheckBox checkBoxWithTitle:@""];
    [checkBox setImagePosition:CPImageOnly];
    [checkBox setAlignment:CPCenterTextAlignment];

    var managerColumn = [self _addColumn:@"isManager" title:@"Manager" width:64 editable:YES dataView:checkBox];
    [[managerColumn headerView] setAlignment:CPCenterTextAlignment];
    [managerColumn setResizingMask:CPTableColumnNoResizing];

    [self _addColumn:@"email"       title:@"Email"      width:220 editable:YES dataView:nil];

    // Selection and sorting through bindings.
    [_tableView bind:CPSelectionIndexesBinding toObject:_arrayController withKeyPath:@"selectionIndexes" options:nil];
    [_tableView bind:@"sortDescriptors" toObject:_arrayController withKeyPath:@"sortDescriptors" options:nil];

    // The data source only provides drag & drop; content comes from the bindings
    // (the column value bindings above establish the table's content binding).
    [_tableView setDataSource:self];
    [_tableView setDelegate:self];
    [_tableView setDraggingSourceOperationMask:CPDragOperationCopy | CPDragOperationMove forLocal:YES];
    [_tableView setDraggingSourceOperationMask:CPDragOperationCopy forLocal:NO];

    if ([_tableView respondsToSelector:@selector(setAutosaveName:)])
    {
        [_tableView setAutosaveName:@"SmartFoldersDemo.PeopleTable"];

        if ([_tableView respondsToSelector:@selector(setAutosaveTableColumns:)])
            [_tableView setAutosaveTableColumns:YES];
    }

    [scrollView setDocumentView:_tableView];
    [pane addSubview:scrollView];

    // --- Button bar with status text
    var buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(aFrame) - barHeight, CGRectGetWidth(aFrame), barHeight)];
    [buttonBar setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];

    if ([buttonBar respondsToSelector:@selector(setHasResizeControl:)])
        [buttonBar setHasResizeControl:NO];

    var plusButton = [CPButtonBar plusButton];
    [plusButton setTarget:nil];
    [plusButton setAction:@selector(newPerson:)];
    [plusButton setToolTip:@"Add a person"];

    var minusButton = [CPButtonBar minusButton];
    [minusButton setTarget:nil];
    [minusButton setAction:@selector(removeSelectedPeople:)];
    [minusButton setToolTip:@"Remove the selected people (from the group, if a group is selected)"];
    [minusButton bind:CPEnabledBinding toObject:_arrayController withKeyPath:@"canRemove" options:nil];

    [buttonBar setButtons:[plusButton, minusButton]];

    _statusField = [CPTextField labelWithTitle:@""];
    [_statusField setFont:[CPFont systemFontOfSize:11.0]];
    [_statusField setTextColor:[CPColor colorWithWhite:0.35 alpha:1.0]];
    [_statusField setAlignment:CPRightTextAlignment];
    [_statusField setVerticalAlignment:CPCenterVerticalTextAlignment];
    [_statusField setFrame:CGRectMake(80, 0, CGRectGetWidth(aFrame) - 92, barHeight)];
    [_statusField setLineBreakMode:CPLineBreakByTruncatingHead];
    [_statusField setAutoresizingMask:CPViewWidthSizable];
    [buttonBar addSubview:_statusField];

    [pane addSubview:buttonBar];

    return pane;
}

- (CPTextField)_textDataViewWithFormatter:(CPFormatter)aFormatter alignment:(CPTextAlignment)anAlignment
{
    var field = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

    [field setAlignment:anAlignment];
    [field setVerticalAlignment:CPCenterVerticalTextAlignment];
    [field setLineBreakMode:CPLineBreakByTruncatingTail];

    if (aFormatter)
        [field setFormatter:aFormatter];

    return field;
}

- (CPTableColumn)_addColumn:(CPString)aKey title:(CPString)aTitle width:(float)aWidth editable:(BOOL)isEditable dataView:(CPView)aDataView
{
    var column = [[CPTableColumn alloc] initWithIdentifier:aKey],
        selector = [@"firstName", @"lastName", @"department", @"city", @"email"].indexOf(aKey) !== -1 ? @selector(caseInsensitiveCompare:) : @selector(compare:);

    [[column headerView] setStringValue:aTitle];
    [column setWidth:aWidth];
    [column setMinWidth:36];
    [column setEditable:isEditable];
    [column setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:aKey ascending:YES selector:selector]];

    if (!aDataView)
    {
        aDataView = [self _textDataViewWithFormatter:nil alignment:CPLeftTextAlignment];
        [aDataView setEditable:isEditable];
    }

    [column setDataView:aDataView];
    [_tableView addTableColumn:column];
    [column bind:CPValueBinding toObject:_arrayController withKeyPath:@"arrangedObjects." + aKey options:nil];

    return column;
}

// ---------------------------------------------------------------- Content

- (void)setPeople:(CPArray)thePeople filterPredicate:(CPPredicate)aPredicate title:(CPString)aTitle
{
    var selected = [_arrayController selectedObjects] || [];

    _contentTitle = aTitle || @"";

    try
    {
        [_arrayController setFilterPredicate:aPredicate];
    }
    catch (e)
    {
        CPLog.warn("SmartFoldersDemo: filter predicate failed: " + e);
        [_arrayController setFilterPredicate:nil];
    }

    [_arrayController setContent:[thePeople copy]];
    [_arrayController setSelectedObjects:selected];

    [self _updateStatus];
}

- (void)rearrange
{
    [_arrayController rearrangeObjects];
    [self _updateStatus];
}

- (CPArray)selectedPeople
{
    return [_arrayController selectedObjects] || [];
}

- (void)selectPerson:(Person)aPerson edit:(BOOL)shouldEdit
{
    [_arrayController setSelectedObjects:[aPerson]];

    var row = [[_arrayController arrangedObjects] indexOfObjectIdenticalTo:aPerson];

    if (row === CPNotFound)
        return;

    [_tableView scrollRowToVisible:row];

    if (shouldEdit)
    {
        [[_tableView window] makeFirstResponder:_tableView];
        [_tableView editColumn:[_tableView columnWithIdentifier:@"firstName"] row:row withEvent:nil select:YES];
    }
}

- (void)focus
{
    [[_tableView window] makeFirstResponder:_tableView];
}

// ---------------------------------------------------------------- Detail pane

- (BOOL)isDetailVisible
{
    var detailView = [[_splitView subviews] objectAtIndex:1];
    return ![_splitView isSubviewCollapsed:detailView] && CGRectGetHeight([detailView frame]) > 0;
}

- (void)toggleDetail
{
    var total = CGRectGetHeight([_splitView bounds]),
        divider = [_splitView dividerThickness];

    if ([self isDetailVisible])
    {
        _lastDetailHeight = CGRectGetHeight([[[_splitView subviews] objectAtIndex:1] frame]);
        [_splitView setPosition:total ofDividerAtIndex:0];
    }
    else
        [_splitView setPosition:total - divider - MAX(_lastDetailHeight, 150) ofDividerAtIndex:0];
}

// Split view delegate (detail pane)
- (BOOL)splitView:(CPSplitView)aSplitView canCollapseSubview:(CPView)aSubview
{
    return aSubview === [[aSplitView subviews] objectAtIndex:1];
}

- (float)splitView:(CPSplitView)aSplitView constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)anIndex
{
    return 120.0;
}

- (float)splitView:(CPSplitView)aSplitView constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)anIndex
{
    return CGRectGetHeight([aSplitView bounds]) - 150.0;
}

- (void)splitView:(CPSplitView)aSplitView resizeSubviewsWithOldSize:(CGSize)oldSize
{
    // Keep the detail pane at a fixed height while the window resizes.
    var subviews = [aSplitView subviews],
        top = subviews[0],
        bottom = subviews[1],
        size = [aSplitView bounds].size,
        divider = [aSplitView dividerThickness],
        bottomHeight = [aSplitView isSubviewCollapsed:bottom] ? 0 : CGRectGetHeight([bottom frame]);

    bottomHeight = MIN(bottomHeight, MAX(0, size.height - divider - 120));

    [top setFrame:CGRectMake(0, 0, size.width, MAX(0, size.height - bottomHeight - divider))];
    [bottom setFrame:CGRectMake(0, size.height - bottomHeight, size.width, bottomHeight)];

    // A custom resizeSubviewsWithOldSize: bypasses CPSplitView's own layout pass,
    // so the divider must be told to redraw at the new width.
    [aSplitView setNeedsDisplay:YES];
}

// ---------------------------------------------------------------- Pasteboard helpers

- (CPString)tabSeparatedStringForPeople:(CPArray)thePeople
{
    var lines = [[Person tabSeparatedHeader]];

    for (var i = 0; i < thePeople.length; i++)
        lines.push([thePeople[i] tabSeparatedRepresentation]);

    return lines.join("\n");
}

- (CPArray)peopleFromTabSeparatedString:(CPString)aString
{
    var lines = (aString || "").split(/\r?\n/),
        result = [];

    for (var i = 0; i < lines.length; i++)
    {
        var line = lines[i];

        if (!line || line === [Person tabSeparatedHeader])
            continue;

        var parts = line.split("\t");

        if (parts.length < 2)
            continue;

        var person = [[Person alloc] init];
        [person setFirstName:parts[0] || @""];
        [person setLastName:parts[1] || @""];
        [person setEmail:parts[2] || @""];
        [person setDepartment:parts[3] || LibraryDepartments[0]];
        [person setCity:parts[4] || @""];
        [person setSalary:parseInt(parts[5], 10) || 0];

        result.push(person);
    }

    return result;
}

- (void)copySelectionToPasteboard:(CPPasteboard)aPasteboard
{
    var people = [self selectedPeople];

    if (![people count])
        return;

    [aPasteboard declareTypes:[CPStringPboardType, PeopleDragType] owner:nil];
    [aPasteboard setString:[self tabSeparatedStringForPeople:people] forType:CPStringPboardType];
    [aPasteboard setData:[CPKeyedArchiver archivedDataWithRootObject:[people valueForKey:@"uid"]] forType:PeopleDragType];
}

// ---------------------------------------------------------------- Table data source: drag source

- (BOOL)tableView:(CPTableView)aTableView writeRowsWithIndexes:(CPIndexSet)theRows toPasteboard:(CPPasteboard)aPasteboard
{
    var people = [[_arrayController arrangedObjects] objectsAtIndexes:theRows];

    if (![people count])
        return NO;

    [aPasteboard declareTypes:[PeopleDragType, CPStringPboardType] owner:self];
    [aPasteboard setData:[CPKeyedArchiver archivedDataWithRootObject:[people valueForKey:@"uid"]] forType:PeopleDragType];
    [aPasteboard setString:[self tabSeparatedStringForPeople:people] forType:CPStringPboardType];

    return YES;
}

// ---------------------------------------------------------------- Table delegate

- (void)tableViewDeleteKeyPressed:(CPTableView)aTableView
{
    [CPApp sendAction:@selector(removeSelectedPeople:) to:nil from:aTableView];
}

// ---------------------------------------------------------------- KVO / status

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)aChange context:(id)aContext
{
    [self _updateStatus];
}

- (void)_updateStatus
{
    if (!_statusField)
        return;

    var shown = [[_arrayController arrangedObjects] count],
        total = [[_arrayController content] count],
        selected = [[_arrayController selectionIndexes] count],
        text = [CPString stringWithFormat:@"%@ — %d of %d people", _contentTitle, shown, total];

    if (selected)
        text += [CPString stringWithFormat:@", %d selected", selected];

    [_statusField setStringValue:text];
}

@end
