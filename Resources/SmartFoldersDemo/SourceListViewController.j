/*
 * SourceListViewController.j
 * SmartFoldersDemo
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
 *   - CPButtonBar with plus / minus / action pop-up and a split view
 *     resize control
 */

@import <AppKit/AppKit.j>
@import "Library.j"

var SourceCellIdentifier = @"SourceCell",
    SourceRowHeight      = 26.0;

// Tags of the action pop-up items.
SourceActionNewGroup        = 1;
SourceActionNewSmartFolder  = 2;
SourceActionEdit            = 3;
SourceActionRename          = 4;
SourceActionDelete          = 5;


// --------------------------------------------------------------------------------
// SourceIconView – small vector icon drawn with CPBezierPath
// --------------------------------------------------------------------------------

@implementation SourceIconView : CPView
{
    CPString    _iconKind;
    BOOL        _isHighlighted;
}

- (void)setKind:(CPString)aKind
{
    if (_iconKind === aKind)
        return;

    _iconKind = aKind;
    [self setNeedsDisplay:YES];
}

- (void)setSelected:(BOOL)aFlag
{
    if (_isHighlighted === aFlag)
        return;

    _isHighlighted = aFlag;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(CGRect)aRect
{
    var bounds = [self bounds],
        w = CGRectGetWidth(bounds),
        h = CGRectGetHeight(bounds);

    if (_iconKind === @"all")
    {
        var color = _isHighlighted ? [CPColor whiteColor] : [CPColor colorWithRed:0.33 green:0.45 blue:0.62 alpha:1.0],
            head = [CPBezierPath bezierPath],
            body = [CPBezierPath bezierPath];

        [color set];
        [head appendBezierPathWithOvalInRect:CGRectMake(w / 2 - 3.5, 1.5, 7, 7)];
        [head fill];
        [body appendBezierPathWithRoundedRect:CGRectMake(w / 2 - 6.5, 9.5, 13, 6) xRadius:3 yRadius:3];
        [body fill];
        return;
    }

    // Folder shape for groups and smart folders.
    var fill = _isHighlighted ? [CPColor whiteColor] :
               (_iconKind === @"smart" ? [CPColor colorWithRed:0.55 green:0.42 blue:0.78 alpha:1.0]
                                   : [CPColor colorWithRed:0.38 green:0.62 blue:0.88 alpha:1.0]),
        folder = [CPBezierPath bezierPath];

    [folder moveToPoint:CGPointMake(1, 3)];
    [folder lineToPoint:CGPointMake(6, 3)];
    [folder lineToPoint:CGPointMake(8, 5)];
    [folder lineToPoint:CGPointMake(w - 1, 5)];
    [folder lineToPoint:CGPointMake(w - 1, h - 2)];
    [folder lineToPoint:CGPointMake(1, h - 2)];
    [folder closePath];

    [fill set];
    [folder fill];

    if (_iconKind === @"smart")
    {
        // Gear-ish dot to distinguish smart folders.
        var mark = [CPBezierPath bezierPath],
            markColor = _isHighlighted ? [CPColor colorWithRed:0.55 green:0.42 blue:0.78 alpha:1.0] : [CPColor whiteColor];

        [markColor set];
        [mark appendBezierPathWithOvalInRect:CGRectMake(w / 2 - 2.5, 7.5, 5, 5)];
        [mark fill];
    }
}

@end


// --------------------------------------------------------------------------------
// SourceBadgeView – rounded count badge
// --------------------------------------------------------------------------------

var BadgeFont       = nil,
    BadgeHeight     = 16.0,
    BadgeMinWidth   = 24.0,
    BadgeHPadding   = 7.0;

@implementation SourceBadgeView : CPView
{
    CPTextField _badgeLabel;
    int         _badgeCount;
    BOOL        _isHighlighted;
}

+ (void)initialize
{
    if (self !== [SourceBadgeView class])
        return;

    BadgeFont = [CPFont boldSystemFontOfSize:11.0];
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        // A plain, inset-free label that is positioned by hand: the text field's
        // own vertical centering includes theme insets and ends up a pixel or two low.
        _badgeLabel = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
        [_badgeLabel setFont:BadgeFont];
        [_badgeLabel setAlignment:CPCenterTextAlignment];
        [_badgeLabel setEditable:NO];
        [_badgeLabel setSelectable:NO];
        [_badgeLabel setBezeled:NO];
        [_badgeLabel setBordered:NO];
        [_badgeLabel setDrawsBackground:NO];
        [_badgeLabel setValue:CGInsetMakeZero() forThemeAttribute:@"content-inset"];
        [self addSubview:_badgeLabel];

        [self _updateColors];
    }

    return self;
}

+ (CPString)stringForCount:(int)aCount
{
    // Keep badges compact: 1234 -> "1.2k", 12345 -> "12k"
    if (aCount >= 10000)
        return Math.round(aCount / 1000) + "k";

    if (aCount >= 1000)
        return (Math.round(aCount / 100) / 10) + "k";

    return String(aCount);
}

- (void)setCount:(int)aCount
{
    _badgeCount = aCount;

    var hidden = aCount === CPNotFound || aCount === nil || aCount === undefined;

    [self setHidden:hidden];

    if (!hidden)
    {
        [_badgeLabel setStringValue:[SourceBadgeView stringForCount:aCount]];
        [self _layoutLabel];
    }

    [self setNeedsDisplay:YES];
}

- (void)setSelected:(BOOL)aFlag
{
    if (_isHighlighted === aFlag)
        return;

    _isHighlighted = aFlag;
    [self _updateColors];
    [self setNeedsDisplay:YES];
}

- (float)preferredWidth
{
    var size = [[_badgeLabel stringValue] sizeWithFont:BadgeFont];
    return MAX(BadgeMinWidth, Math.ceil(size.width) + 2 * BadgeHPadding);
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    [self _layoutLabel];
}

- (void)_layoutLabel
{
    var bounds = [self bounds],
        textHeight = Math.ceil([[_badgeLabel stringValue] sizeWithFont:BadgeFont].height);

    [_badgeLabel setFrame:CGRectMake(0, Math.round((CGRectGetHeight(bounds) - textHeight) / 2), CGRectGetWidth(bounds), textHeight)];
}

- (void)_updateColors
{
    [_badgeLabel setTextColor:_isHighlighted ? [CPColor colorWithRed:0.29 green:0.54 blue:0.82 alpha:1.0] : [CPColor whiteColor]];
}

- (void)drawRect:(CGRect)aRect
{
    var bounds = [self bounds],
        radius = CGRectGetHeight(bounds) / 2,
        path = [CPBezierPath bezierPath];

    [path appendBezierPathWithRoundedRect:bounds xRadius:radius yRadius:radius];

    [(_isHighlighted ? [CPColor whiteColor] : [CPColor colorWithRed:0.56 green:0.63 blue:0.76 alpha:1.0]) set];
    [path fill];
}

@end


// --------------------------------------------------------------------------------
// SourceListCellView – view-based outline cell
// --------------------------------------------------------------------------------

@implementation SourceListCellView : CPTableCellView
{
    SourceIconView  _iconView;
    CPTextField     _titleField;
    SourceBadgeView _badgeView;
    BOOL            _isHeader;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        var height = CGRectGetHeight(aFrame);

        _iconView = [[SourceIconView alloc] initWithFrame:CGRectMake(2, (height - 16) / 2, 18, 16)];
        [_iconView setAutoresizingMask:CPViewMinYMargin | CPViewMaxYMargin];
        [self addSubview:_iconView];

        _titleField = [[CPTextField alloc] initWithFrame:CGRectMake(24, 0, CGRectGetWidth(aFrame) - 24, height)];
        [_titleField setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [_titleField setVerticalAlignment:CPCenterVerticalTextAlignment];
        [_titleField setLineBreakMode:CPLineBreakByTruncatingTail];
        [_titleField setEditable:NO];
        [_titleField setBezeled:NO];
        [_titleField setDrawsBackground:NO];
        [self addSubview:_titleField];

        _badgeView = [[SourceBadgeView alloc] initWithFrame:CGRectMake(CGRectGetWidth(aFrame) - 30, (height - BadgeHeight) / 2, BadgeMinWidth, BadgeHeight)];
        [_badgeView setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin | CPViewMaxYMargin];
        [self addSubview:_badgeView];

        [self setIdentifier:SourceCellIdentifier];
    }

    return self;
}

- (void)configureWithItem:(SourceItem)anItem count:(int)aCount
{
    _isHeader = [anItem isSection];

    var bounds = [self bounds],
        width = CGRectGetWidth(bounds),
        height = CGRectGetHeight(bounds);

    [_titleField setStringValue:[anItem name]];

    if (_isHeader)
    {
        [_iconView setHidden:YES];
        [_badgeView setHidden:YES];
        [_titleField setFont:[CPFont boldSystemFontOfSize:11.0]];
        [_titleField setFrame:CGRectMake(0, 0, width, height)];
    }
    else
    {
        var kind = [anItem isKindOfClass:[SmartFolder class]] ? @"smart" :
                   [anItem isKindOfClass:[LibraryGroup class]] ? @"group" : @"all";

        [_iconView setHidden:NO];
        [_iconView setKind:kind];
        [_titleField setFont:[CPFont systemFontOfSize:12.0]];

        [_badgeView setCount:aCount];

        var badgeWidth = [_badgeView isHidden] ? 0 : [_badgeView preferredWidth];

        [_badgeView setFrame:CGRectMake(width - badgeWidth - 8, Math.round((height - BadgeHeight) / 2), badgeWidth, BadgeHeight)];
        [_titleField setFrame:CGRectMake(24, 0, MAX(0, width - 24 - badgeWidth - 14), height)];
    }

    [self _updateSelectionAppearance];
}

- (void)setThemeState:(ThemeState)aState
{
    [super setThemeState:aState];
    [self _updateSelectionAppearance];
}

- (void)unsetThemeState:(ThemeState)aState
{
    [super unsetThemeState:aState];
    [self _updateSelectionAppearance];
}

- (void)_updateSelectionAppearance
{
    // CPTableView marks data views of selected rows with CPThemeStateSelectedDataView
    // and, only while the table is focused (first responder in the key window),
    // additionally with CPThemeStateFirstResponder. The unfocused selection colour
    // is a light gray, so white text is only legible in the focused case.
    var selected = [self hasThemeState:CPThemeStateSelectedDataView],
        emphasized = selected && [self hasThemeState:CPThemeStateFirstResponder];

    [_iconView setSelected:emphasized];
    [_badgeView setSelected:emphasized];

    if (_isHeader)
        [_titleField setTextColor:[CPColor colorWithWhite:0.45 alpha:1.0]];
    else
        [_titleField setTextColor:emphasized ? [CPColor whiteColor] : [CPColor colorWithWhite:0.15 alpha:1.0]];
}

@end


// --------------------------------------------------------------------------------
// SourceListViewController
// --------------------------------------------------------------------------------

@implementation SourceListViewController : CPViewController
{
    Library         _library;
    CPOutlineView   _outlineView;
    CPButtonBar     _buttonBar;
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
    [_outlineView setBackgroundColor:[CPColor colorWithRed:212.0 / 255.0 green:221.0 / 255.0 blue:230.0 / 255.0 alpha:1.0]];
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

    // --- Button bar
    _buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(frame) - barHeight, CGRectGetWidth(frame), barHeight)];
    [_buttonBar setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];

    if ([_buttonBar respondsToSelector:@selector(setHasResizeControl:)])
        [_buttonBar setHasResizeControl:YES];

    if ([_buttonBar respondsToSelector:@selector(setResizeControlIsLeftAligned:)])
        [_buttonBar setResizeControlIsLeftAligned:NO];

    var plusButton = [CPButtonBar plusButton];
    [plusButton setTarget:self];
    [plusButton setAction:@selector(_plusClicked:)];
    [plusButton setToolTip:@"New smart folder"];

    var minusButton = [CPButtonBar minusButton];
    [minusButton setTarget:self];
    [minusButton setAction:@selector(_minusClicked:)];
    [minusButton setToolTip:@"Delete the selected group or smart folder"];

    var actionButton = [CPButtonBar actionPopupButton];

    if (![[actionButton itemArray] count])
        [actionButton addItemWithTitle:@""];

    [self _addActionItem:@"New Group…" tag:SourceActionNewGroup to:actionButton];
    [self _addActionItem:@"New Smart Folder…" tag:SourceActionNewSmartFolder to:actionButton];
    [[actionButton menu] addItem:[CPMenuItem separatorItem]];
    [self _addActionItem:@"Edit Smart Folder…" tag:SourceActionEdit to:actionButton];
    [self _addActionItem:@"Rename Group…" tag:SourceActionRename to:actionButton];
    [self _addActionItem:@"Delete" tag:SourceActionDelete to:actionButton];
    [actionButton setTarget:self];
    [actionButton setAction:@selector(_actionPopupChosen:)];

    [_buttonBar setButtons:[plusButton, minusButton, actionButton]];
    [view addSubview:_buttonBar];

    [self setView:view];

    [_outlineView reloadData];
    [self _expandSections];
}

- (void)_addActionItem:(CPString)aTitle tag:(int)aTag to:(CPPopUpButton)aPopUp
{
    [aPopUp addItemWithTitle:aTitle];
    [[aPopUp lastItem] setTag:aTag];
}

- (void)_expandSections
{
    var sections = [_library sections];

    for (var i = 0; i < sections.length; i++)
        [_outlineView expandItem:sections[i]];
}

// ---------------------------------------------------------------- Public

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

- (void)_actionPopupChosen:(id)sender
{
    var selector = nil;

    switch ([[sender selectedItem] tag])
    {
        case SourceActionNewGroup:          selector = @selector(newGroup:); break;
        case SourceActionNewSmartFolder:    selector = @selector(newSmartFolder:); break;
        case SourceActionEdit:              selector = @selector(editSelectedSmartFolder:); break;
        case SourceActionRename:            selector = @selector(renameSelectedGroup:); break;
        case SourceActionDelete:            selector = @selector(deleteSelectedSourceItem:); break;
    }

    if (selector)
        [CPApp sendAction:selector to:nil from:sender];
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
