/*
 * SourceListViewController.j
 * People
 *
 * Sidebar. Exercises:
 *   - CPViewController with a programmatic -loadView
 *   - view-based CPOutlineView (outlineView:viewForTableColumn:item:,
 *     makeViewWithIdentifier:owner:, CPTableCellView subclass)
 *   - source list highlight style, expand/collapse, non-selectable headers
 *   - custom drawing (CPBezierPath) for icons and count badges
 *   - drag & drop: reordering groups / smart folders inside their section,
 *     dropping people (from the table) onto a group, or onto the GROUPS
 *     header to create a new group
 *   - CPButtonBar with plus / minus buttons and a split view resize control
 *   - a button on the right of the button bar that pops up copies of the
 *     main menu's menus
 *   - a search field at the top, shown only while the toolbar is hidden; the
 *     window controller gives it its target and action
 */

@import <AppKit/AppKit.j>

@import "../Library.j"
@import "../MainMenuButton.j"
@import "SourceItemCell/SourceListCellView.j"

var SourceRowHeight         = 26.0,
    SearchFieldTopMargin    = 28.0,
    SearchFieldMargin       = 6.0;


@implementation SourceListViewController : CPViewController
{
    Library         _library;
    CPOutlineView   _outlineView;
    CPButtonBar     _buttonBar;
    MainMenuButton  _mainMenuButton;
    CPSearchField   _searchField;
    CPScrollView    _scrollView;
    BOOL            _suppressSelectionCallbacks;

    id              _sourceListDelegate   @accessors(property=delegate);
}

- (id)initWithLibrary:(Library)aLibrary
{
    if (self = [super initWithCibName:nil bundle:nil])
        _library = aLibrary;

    return self;
}

- (CPButtonBar)buttonBar
{
    [self view];
    return _buttonBar;
}

- (void)loadView
{
    var frame = CGRectMake(0, 0, 230, 500),
        view = [[CPView alloc] initWithFrame:frame],
        barHeight = 26.0;

    [view setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    // --- Outline in scroll view
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame) - barHeight)];
    [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setBorderType:CPNoBorder];

    _outlineView = [[CPOutlineView alloc] initWithFrame:[[scrollView contentView] bounds]];

    var column = [[CPTableColumn alloc] initWithIdentifier:@"source"];
    [column setWidth:CGRectGetWidth(frame) - 20];
    [column setResizingMask:CPTableColumnAutoresizingMask];
    [column setEditable:NO];
    [_outlineView addTableColumn:column];
    [_outlineView setOutlineTableColumn:column];

    [_outlineView setHeaderView:nil];
    [_outlineView setCornerView:nil];
    [_outlineView setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_outlineView setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleSourceList];
    [_outlineView setRowHeight:SourceRowHeight];
    [_outlineView setAllowsMultipleSelection:NO];
    [_outlineView setAllowsEmptySelection:YES];

    [_outlineView setTarget:self];
    [_outlineView setDoubleAction:@selector(outlineViewDoubleClicked:)];

    [_outlineView registerForDraggedTypes:[PeopleDragType, SourceItemDragType]];
    [_outlineView setDraggingSourceOperationMask:CPDragOperationMove forLocal:YES];

    [_outlineView setDataSource:self];
    [_outlineView setDelegate:self];

    [scrollView setDocumentView:_outlineView];
    [view addSubview:scrollView];
    _scrollView = scrollView;

    // --- Search field, hidden until the toolbar is hidden
    _searchField = [[CPSearchField alloc] initWithFrame:CGRectMakeZero()];
    [_searchField sizeToFit];
    [_searchField setFrame:CGRectMake(SearchFieldMargin, SearchFieldTopMargin, CGRectGetWidth(frame) - 2 * SearchFieldMargin, CGRectGetHeight([_searchField frame]))];
    [_searchField setAutoresizingMask:CPViewWidthSizable];
    [_searchField setPlaceholderString:@"Search people"];
    [_searchField setSendsSearchStringImmediately:YES];
    [_searchField setRecentsAutosaveName:@"People.RecentSearches"];
    [_searchField setSearchMenuTemplate:[_searchField defaultSearchMenuTemplate]];
    [_searchField setHidden:YES];
    [view addSubview:_searchField];

    // --- Button bar
    _buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(frame) - barHeight, CGRectGetWidth(frame), barHeight)];
    [_buttonBar setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];

    [_buttonBar setHasResizeControl:YES];
    [_buttonBar setResizeControlIsLeftAligned:NO];

    var plusButton = [CPButtonBar plusButton];
    [plusButton setTarget:self];
    [plusButton setAction:@selector(_plusClicked:)];
    [plusButton setToolTip:@"New smart folder"];

    var minusButton = [CPButtonBar minusButton];
    [minusButton setTarget:self];
    [minusButton setAction:@selector(_minusClicked:)];
    [minusButton setToolTip:@"Delete the selected group or smart folder"];

    [_buttonBar setButtons:[plusButton, minusButton]];

    _mainMenuButton = [[MainMenuButton alloc] initWithButtonBar:_buttonBar];
    [_buttonBar setRightButtons:[[_mainMenuButton button]]];

    [view addSubview:_buttonBar];

    [self setView:view];

    [_outlineView reloadData];
    [self _expandSections];
}

- (void)_expandSections
{
    var sections = [_library sections];

    for (var i = 0; i < sections.length; i++)
        [_outlineView expandItem:sections[i]];
}

// ---------------------------------------------------------------- Public

- (CPSearchField)searchField
{
    [self view];
    return _searchField;
}

/*
    Shows or hides the search field. While it shows, the source list starts below it.
*/
- (void)setShowsSearchField:(BOOL)shouldShow
{
    [self view];

    if ([_searchField isHidden] === !shouldShow)
        return;

    var scrollFrame = [_scrollView frame],
        top = shouldShow ? CGRectGetMaxY([_searchField frame]) + SearchFieldMargin : 0.0;

    scrollFrame.size.height += CGRectGetMinY(scrollFrame) - top;
    scrollFrame.origin.y = top;

    [_scrollView setFrame:scrollFrame];
    [_searchField setHidden:!shouldShow];
}

- (id)selectedItem
{
    var row = [_outlineView selectedRow];
    return row >= 0 ? [_outlineView itemAtRow:row] : nil;
}

- (void)selectItem:(id)anItem
{
    var row = [_outlineView rowForItem:anItem];

    if (row === CPNotFound || row < 0)
        return;

    [_outlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [_outlineView scrollRowToVisible:row];
}

// Reloads the outline (names, order, badges) without emitting selection callbacks.
- (void)reloadAndSelectItem:(id)anItem
{
    _suppressSelectionCallbacks = YES;

    [_outlineView reloadData];
    [self _expandSections];

    var row = anItem ? [_outlineView rowForItem:anItem] : CPNotFound;

    if (row !== CPNotFound && row >= 0)
        [_outlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    else
        [_outlineView deselectAll:nil];

    _suppressSelectionCallbacks = NO;
}

- (void)focus
{
    [[_outlineView window] makeFirstResponder:_outlineView];
}

// ---------------------------------------------------------------- Actions

- (void)_plusClicked:(id)sender
{
    [CPApp sendAction:@selector(newSmartFolder:) to:nil from:sender];
}

- (void)_minusClicked:(id)sender
{
    [CPApp sendAction:@selector(deleteSelectedSourceItem:) to:nil from:sender];
}

- (void)outlineViewDoubleClicked:(id)sender
{
    var row = [_outlineView clickedRow];

    if (row < 0)
        return;

    var item = [_outlineView itemAtRow:row];

    if ([item isKindOfClass:[SmartFolder class]])
        [CPApp sendAction:@selector(editSelectedSmartFolder:) to:nil from:self];
    else if ([item isKindOfClass:[LibraryGroup class]])
        [CPApp sendAction:@selector(renameSelectedGroup:) to:nil from:self];
}

// ---------------------------------------------------------------- Data source

- (int)outlineView:(CPOutlineView)anOutlineView numberOfChildrenOfItem:(id)anItem
{
    return [[_library childrenOfItem:anItem] count];
}

- (id)outlineView:(CPOutlineView)anOutlineView child:(int)anIndex ofItem:(id)anItem
{
    return [[_library childrenOfItem:anItem] objectAtIndex:anIndex];
}

- (BOOL)outlineView:(CPOutlineView)anOutlineView isItemExpandable:(id)anItem
{
    return [anItem isSection];
}

- (id)outlineView:(CPOutlineView)anOutlineView objectValueForTableColumn:(CPTableColumn)aColumn byItem:(id)anItem
{
    return anItem;
}

// ---------------------------------------------------------------- Delegate (view based)

- (CPView)outlineView:(CPOutlineView)anOutlineView viewForTableColumn:(CPTableColumn)aColumn item:(id)anItem
{
    var cell = [anOutlineView makeViewWithIdentifier:SourceCellIdentifier owner:self];

    if (!cell)
        cell = [[SourceListCellView alloc] initWithFrame:CGRectMake(0, 0, [aColumn width], SourceRowHeight)];

    [cell configureWithItem:anItem count:[_library countForItem:anItem]];

    return cell;
}

- (BOOL)outlineView:(CPOutlineView)anOutlineView shouldSelectItem:(id)anItem
{
    return [anItem isSelectable];
}

- (void)outlineViewSelectionDidChange:(CPNotification)aNotification
{
    if (_suppressSelectionCallbacks)
        return;

    var item = [self selectedItem];

    if (item && [_sourceListDelegate respondsToSelector:@selector(sourceListViewController:didSelectItem:)])
        [_sourceListDelegate sourceListViewController:self didSelectItem:item];
}

// ---------------------------------------------------------------- Drag & drop

- (BOOL)outlineView:(CPOutlineView)anOutlineView writeItems:(CPArray)theItems toPasteboard:(CPPasteboard)aPasteboard
{
    var item = [theItems firstObject];

    if ([theItems count] !== 1 || ![item isUserItem])
        return NO;

    [aPasteboard declareTypes:[SourceItemDragType] owner:self];
    [aPasteboard setString:[item uid] forType:SourceItemDragType];

    return YES;
}

- (CPDragOperation)outlineView:(CPOutlineView)anOutlineView validateDrop:(id)theInfo proposedItem:(id)anItem proposedChildIndex:(int)anIndex
{
    var pasteboard = [theInfo draggingPasteboard],
        types = [pasteboard types];

    // People from the table
    if ([types containsObject:PeopleDragType])
    {
        if ([anItem isKindOfClass:[LibraryGroup class]] && anIndex === CPOutlineViewDropOnItemIndex)
            return CPDragOperationCopy;

        // Anywhere on/inside the GROUPS section: create a new group.
        if (anItem === [_library groupsSection])
        {
            [anOutlineView setDropItem:anItem dropChildIndex:CPOutlineViewDropOnItemIndex];
            return CPDragOperationCopy;
        }

        return CPDragOperationNone;
    }

    // Reordering of groups / smart folders
    if ([types containsObject:SourceItemDragType])
    {
        var dragged = [_library itemWithUID:[pasteboard stringForType:SourceItemDragType]],
            section = [_library sectionForItem:dragged];

        if (!dragged || !section)
            return CPDragOperationNone;

        if (anItem === section && anIndex !== CPOutlineViewDropOnItemIndex)
            return CPDragOperationMove;

        // Dropped onto a sibling: retarget to "insert above sibling".
        if (anIndex === CPOutlineViewDropOnItemIndex && [_library sectionForItem:anItem] === section)
        {
            [anOutlineView setDropItem:section dropChildIndex:[[section children] indexOfObjectIdenticalTo:anItem]];
            return CPDragOperationMove;
        }
    }

    return CPDragOperationNone;
}

- (BOOL)outlineView:(CPOutlineView)anOutlineView acceptDrop:(id)theInfo item:(id)anItem childIndex:(int)anIndex
{
    var pasteboard = [theInfo draggingPasteboard],
        types = [pasteboard types];

    if ([types containsObject:PeopleDragType])
    {
        var uids = [CPKeyedUnarchiver unarchiveObjectWithData:[pasteboard dataForType:PeopleDragType]],
            people = [_library peopleWithUIDs:uids || []];

        if (![people count])
            return NO;

        if ([anItem isKindOfClass:[LibraryGroup class]])
        {
            [_library addPeople:people toGroup:anItem];
            return YES;
        }

        if (anItem === [_library groupsSection])
        {
            var name = [people count] === 1 ? [people[0] fullName] : [CPString stringWithFormat:@"%d People", [people count]],
                group = [_library addGroupWithName:name people:people];

            [self selectItem:group];
            return YES;
        }

        return NO;
    }

    if ([types containsObject:SourceItemDragType])
    {
        var dragged = [_library itemWithUID:[pasteboard stringForType:SourceItemDragType]];

        if (!dragged)
            return NO;

        [_library moveItem:dragged toIndex:anIndex];
        return YES;
    }

    return NO;
}

@end
