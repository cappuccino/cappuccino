/*
 * PeopleViewController.j
 * People
 *
 * Middle pane of the main window: the people table. Exercises:
 *   - CPArrayController with content, filterPredicate, sortDescriptors and
 *     selection (incl. setSelectedObjects: across content changes)
 *   - cell-based CPTableView fully driven by bindings (value, selection,
 *     sort descriptors), editable columns, formatters (CPDateFormatter,
 *     CPNumberFormatter), checkbox data views, column reordering/resizing,
 *     autosaved column state, alternating rows, grid lines
 *   - the table as drag source (rows -> source list groups)
 *   - CPPasteboard (copy / paste as tab separated text)
 *   - a notes column: a CPImageView data view bound to hasNotes through a named
 *     CPValueTransformer, with an image in its header instead of a title
 *
 * The editable columns take edits only while the library is editable; the controller observes
 * the library's "editable" key and sets each column's editable state.
 *
 * The array controller's selection is what the detail pane shows; the main split view
 * controller connects the two.
 */

@import <AppKit/AppKit.j>
@import "../Library.j"
@import "../MaskImage.j"

/*
    The notes column's icon, a page with lines, 16 by 16:
      <path d="M3.5 1.5h6l3 3v10h-9zM9.5 1.5v3h3M5.5 8h5M5.5 10.5h5M5.5 13h3"
            stroke="black" stroke-width="1.2" fill="none"/>
*/
var NotesMask           = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNiAxNiI+PHBhdGggZD0iTTMuNSAxLjVoNmwzIDN2MTBoLTl6TTkuNSAxLjV2M2gzTTUuNSA4aDVNNS41IDEwLjVoNU01LjUgMTNoMyIgc3Ryb2tlPSJibGFjayIgc3Ryb2tlLXdpZHRoPSIxLjIiIGZpbGw9Im5vbmUiLz48L3N2Zz4=')",
    NotesIconSize       = CGSizeMake(14, 14),
    NotesIconTransformerName = @"NotesIconTransformer";

/*
    Turns a person's hasNotes value into the notes icon, or into no image. The table's notes
    column binds through it, by name, with CPValueTransformerNameBindingOption.
*/
@implementation NotesIconTransformer : CPValueTransformer
{
    CPImage     _icon;
}

+ (Class)transformedValueClass
{
    return [CPImage class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)aValue
{
    if (!aValue)
        return nil;

    if (!_icon)
        _icon = MaskImage(NotesMask, NotesIconSize, [CPColor secondaryLabelColor]);

    return _icon;
}

@end

@implementation PeopleViewController : CPViewController
{
    Library                     _library;
    CPArrayController           _arrayController;
    CPTableView                 _tableView;
    CPTextField                 _statusField;
    CPString                    _contentTitle;
    CPArray                     _editableColumns;
}

- (id)initWithLibrary:(Library)aLibrary
{
    if (self = [super initWithCibName:nil bundle:nil])
    {
        _library = aLibrary;
        _contentTitle = @"";
        _editableColumns = [];

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
        [_library addObserver:self forKeyPath:@"editable" options:0 context:@"editable"];

        if (![CPValueTransformer valueTransformerForName:NotesIconTransformerName])
            [CPValueTransformer setValueTransformer:[[NotesIconTransformer alloc] init] forName:NotesIconTransformerName];
    }

    return self;
}

- (Library)library
{
    return _library;
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
    [self setView:[self _buildTablePane:CGRectMake(0, 0, 800, 600)]];
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

    // Notes: an icon when the person has notes, nothing when not.
    var notesView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
    [notesView setImageScaling:CPImageScaleNone];
    [notesView setImageAlignment:CPImageAlignCenter];

    var notesColumn = [self _addColumn:@"hasNotes" title:@"" width:28 editable:NO dataView:notesView
                                options:@{ CPValueTransformerNameBindingOption: NotesIconTransformerName }];
    [notesColumn setResizingMask:CPTableColumnNoResizing];
    [notesColumn setHeaderToolTip:@"Notes"];
    [[[notesColumn headerView] textField] setImage:MaskImage(NotesMask, NotesIconSize, [CPColor secondaryLabelColor])];
    [[[notesColumn headerView] textField] setImagePosition:CPImageOnly];
    [[notesColumn headerView] setAlignment:CPCenterTextAlignment];

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

    [_tableView setAutosaveName:@"People.PeopleTable"];
    [_tableView setAutosaveTableColumns:YES];

    [scrollView setDocumentView:_tableView];
    [pane addSubview:scrollView];

    // --- Button bar with status text
    var buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(aFrame) - barHeight, CGRectGetWidth(aFrame), barHeight)];
    [buttonBar setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];

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
    [_statusField setTextColor:[CPColor secondaryLabelColor]];
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
    return [self _addColumn:aKey title:aTitle width:aWidth editable:isEditable dataView:aDataView options:nil];
}

/*
    Adds a column for aKey and binds its value to arrangedObjects.<aKey> with the binding
    options in someOptions.
*/
- (CPTableColumn)_addColumn:(CPString)aKey title:(CPString)aTitle width:(float)aWidth editable:(BOOL)isEditable dataView:(CPView)aDataView options:(CPDictionary)someOptions
{
    var column = [[CPTableColumn alloc] initWithIdentifier:aKey],
        selector = [@"firstName", @"lastName", @"department", @"city", @"email"].indexOf(aKey) !== -1 ? @selector(caseInsensitiveCompare:) : @selector(compare:);

    [[column headerView] setStringValue:aTitle];
    [column setWidth:aWidth];
    [column setMinWidth:36];
    [column setEditable:isEditable && [_library isEditable]];

    if (isEditable)
        [_editableColumns addObject:column];
    [column setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:aKey ascending:YES selector:selector]];

    if (!aDataView)
    {
        aDataView = [self _textDataViewWithFormatter:nil alignment:CPLeftTextAlignment];
        [aDataView setEditable:isEditable];
    }

    [column setDataView:aDataView];
    [_tableView addTableColumn:column];
    [column bind:CPValueBinding toObject:_arrayController withKeyPath:@"arrangedObjects." + aKey options:someOptions];

    return column;
}

// ---------------------------------------------------------------- Content

- (void)setPeople:(CPArray)thePeople filterPredicate:(CPPredicate)aPredicate title:(CPString)aTitle
{
    var selected = [_arrayController selectedObjects] || [];

    _contentTitle = aTitle || @"";

    [_arrayController setFilterPredicate:aPredicate];
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

    if (shouldEdit && [_library isEditable])
    {
        [[_tableView window] makeFirstResponder:_tableView];
        [_tableView editColumn:[_tableView columnWithIdentifier:@"firstName"] row:row withEvent:nil select:YES];
    }
}

- (void)focus
{
    [[_tableView window] makeFirstResponder:_tableView];
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
    if (aContext === @"editable")
        [self _libraryEditableDidChange];
    else
        [self _updateStatus];
}

/*
    Gives the editable columns the library's edit mode. Leaving edit mode first ends an edit in
    progress in a cell, so its value reaches the person.
*/
- (void)_libraryEditableDidChange
{
    var isEditable = [_library isEditable];

    if (!isEditable && [_tableView editedRow] !== CPNotFound)
        [[_tableView window] makeFirstResponder:_tableView];

    for (var i = 0, count = [_editableColumns count]; i < count; i++)
        [_editableColumns[i] setEditable:isEditable];
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
