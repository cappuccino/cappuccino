/*
 * MainWindowController.j
 * SmartFoldersDemo
 *
 * Owns the full-platform (bridge) main window. Instantiates the sidebar and
 * people view controllers and loads their views into a vertical CPSplitView.
 * Exercises:
 *   - CPWindowController created in code, window delegate + responder chain
 *     target for menu / toolbar / button bar actions (sent to nil)
 *   - CPToolbar with view items (buttons, CPSearchField)
 *   - CPSplitView delegate API: min/max constraints, collapsing, custom
 *     resizeSubviewsWithOldSize:, autosave, button bar resize control
 *   - menu validation (-validateMenuItem:)
 *   - CPAlert as a sheet
 *   - CPPasteboard copy / paste
 */

@import <AppKit/AppKit.j>
@import "Library.j"
@import "SourceListViewController.j"
@import "PeopleViewController.j"
@import "SmartFolderEditorController.j"
@import "NameSheetController.j"

var ToolbarSidebarIdentifier    = @"SidebarItem",
    ToolbarNewFolderIdentifier  = @"NewSmartFolderItem",
    ToolbarNewGroupIdentifier   = @"NewGroupItem",
    ToolbarEditIdentifier       = @"EditFolderItem",
    ToolbarDetailIdentifier     = @"DetailItem",
    ToolbarSearchIdentifier     = @"SearchItem",
    SidebarDefaultWidth         = 230.0,
    SidebarMinWidth             = 160.0,
    SidebarMaxWidth             = 420.0;

@implementation MainWindowController : CPWindowController
{
    Library                     _library;

    CPSplitView                 _splitView;
    SourceListViewController    _sourceListController;
    PeopleViewController        _peopleController;
    SmartFolderEditorController _folderEditor;
    NameSheetController         _nameSheet;

    CPSearchField               _searchField;
    CPPredicate                 _searchPredicate;
    id                          _selectedItem;
    float                       _lastSidebarWidth;
}

- (id)initWithLibrary:(Library)aLibrary
{
    var window = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];

    if (self = [super initWithWindow:window])
    {
        _library = aLibrary;
        _lastSidebarWidth = SidebarDefaultWidth;

        [window setDelegate:self];
        [window setTitle:@"Smart Folders Demo"];

        _sourceListController = [[SourceListViewController alloc] initWithLibrary:_library];
        [_sourceListController setDelegate:self];

        _peopleController = [[PeopleViewController alloc] initWithLibrary:_library];

        [self _buildToolbar];
        [self _buildSplitView];

        [[CPNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(libraryDidChange:)
                                                     name:LibraryDidChangeNotification
                                                   object:_library];

        [self _selectSourceItem:[_library allPeopleItem]];
    }

    return self;
}

// ---------------------------------------------------------------- Interface

- (void)_buildSplitView
{
    var contentView = [[self window] contentView],
        bounds = [contentView bounds];

    _splitView = [[CPSplitView alloc] initWithFrame:bounds];
    [_splitView setVertical:YES];
    [_splitView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_splitView setDelegate:self];

    var sidebar = [_sourceListController view],
        people = [_peopleController view];

    [sidebar setFrame:CGRectMake(0, 0, SidebarDefaultWidth, CGRectGetHeight(bounds))];
    [people setFrame:CGRectMake(SidebarDefaultWidth + 1, 0, MAX(0, CGRectGetWidth(bounds) - SidebarDefaultWidth - 1), CGRectGetHeight(bounds))];

    [_splitView addSubview:sidebar];
    [_splitView addSubview:people];
    [contentView addSubview:_splitView];

    if ([_splitView respondsToSelector:@selector(setButtonBar:forDividerAtIndex:)])
        [_splitView setButtonBar:[_sourceListController buttonBar] forDividerAtIndex:0];

    if ([_splitView respondsToSelector:@selector(setAutosaveName:)])
        [_splitView setAutosaveName:@"SmartFoldersDemo.MainSplit"];
}

- (void)_buildToolbar
{
    _searchField = [[CPSearchField alloc] initWithFrame:CGRectMake(0, 0, 220, 30)];
    [_searchField setPlaceholderString:@"Search people"];
    [_searchField setTarget:self];
    [_searchField setAction:@selector(searchFieldDidChange:)];
    [_searchField setSendsSearchStringImmediately:YES];
    [_searchField setRecentsAutosaveName:@"SmartFoldersDemo.RecentSearches"];
    [_searchField setSearchMenuTemplate:[_searchField defaultSearchMenuTemplate]];

    var toolbar = [[CPToolbar alloc] initWithIdentifier:@"SmartFoldersDemoToolbar"];
    [toolbar setDelegate:self];

    // Buttons carry their own titles, so labels below them would be redundant.
    if (typeof CPToolbarDisplayModeIconOnly !== "undefined")
        [toolbar setDisplayMode:CPToolbarDisplayModeIconOnly];

    [toolbar setVisible:YES];
    [[self window] setToolbar:toolbar];
}

- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)aToolbar
{
    return [ToolbarSidebarIdentifier, ToolbarNewFolderIdentifier, ToolbarNewGroupIdentifier, ToolbarEditIdentifier,
            ToolbarDetailIdentifier, ToolbarSearchIdentifier,
            CPToolbarFlexibleSpaceItemIdentifier, CPToolbarSpaceItemIdentifier, CPToolbarSeparatorItemIdentifier];
}

- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)aToolbar
{
    return [ToolbarSidebarIdentifier, CPToolbarSpaceItemIdentifier,
            ToolbarNewFolderIdentifier, ToolbarNewGroupIdentifier, ToolbarEditIdentifier,
            CPToolbarFlexibleSpaceItemIdentifier,
            ToolbarDetailIdentifier, ToolbarSearchIdentifier];
}

- (CPToolbarItem)toolbar:(CPToolbar)aToolbar itemForItemIdentifier:(CPString)anIdentifier willBeInsertedIntoToolbar:(BOOL)aFlag
{
    var item = [[CPToolbarItem alloc] initWithItemIdentifier:anIdentifier];

    switch (anIdentifier)
    {
        case ToolbarSidebarIdentifier:
            [self _configureItem:item label:@"Sidebar" buttonTitle:@"Sidebar" action:@selector(toggleSidebar:) toolTip:@"Show or hide the sidebar"];
            break;

        case ToolbarNewFolderIdentifier:
            [self _configureItem:item label:@"New Smart Folder" buttonTitle:@"New Smart Folder" action:@selector(newSmartFolder:) toolTip:@"Create a smart folder from a predicate"];
            break;

        case ToolbarNewGroupIdentifier:
            [self _configureItem:item label:@"New Group" buttonTitle:@"New Group" action:@selector(newGroup:) toolTip:@"Create an empty group (or drop people on GROUPS)"];
            break;

        case ToolbarEditIdentifier:
            [self _configureItem:item label:@"Edit" buttonTitle:@"Edit…" action:@selector(editSelectedSmartFolder:) toolTip:@"Edit the selected smart folder"];
            break;

        case ToolbarDetailIdentifier:
            [self _configureItem:item label:@"Details" buttonTitle:@"Details" action:@selector(toggleDetail:) toolTip:@"Show or hide the detail pane"];
            break;

        case ToolbarSearchIdentifier:
            [item setLabel:@"Search"];
            [item setPaletteLabel:@"Search"];
            [item setView:_searchField];
            [item setMinSize:CGSizeMake(140, 30)];
            [item setMaxSize:CGSizeMake(260, 30)];
            break;
    }

    return item;
}

- (void)_configureItem:(CPToolbarItem)anItem label:(CPString)aLabel buttonTitle:(CPString)aTitle action:(SEL)anAction toolTip:(CPString)aToolTip
{
    var button = [CPButton buttonWithTitle:aTitle];

    [button setBezelStyle:CPRoundedBezelStyle];
    [button setTarget:self];
    [button setAction:anAction];
    [button sizeToFit];

    var size = CGSizeMake(MAX(CGRectGetWidth([button frame]), 40), 25);

    [anItem setLabel:aLabel];
    [anItem setPaletteLabel:aLabel];
    [anItem setToolTip:aToolTip];
    [anItem setTarget:self];
    [anItem setAction:anAction];
    [anItem setView:button];
    [anItem setMinSize:size];
    [anItem setMaxSize:size];
}

// ---------------------------------------------------------------- Split view delegate (sidebar)

- (BOOL)splitView:(CPSplitView)aSplitView canCollapseSubview:(CPView)aSubview
{
    return aSubview === [_sourceListController view];
}

- (float)splitView:(CPSplitView)aSplitView constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)anIndex
{
    return SidebarMinWidth;
}

- (float)splitView:(CPSplitView)aSplitView constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)anIndex
{
    return MIN(SidebarMaxWidth, CGRectGetWidth([aSplitView bounds]) - 300.0);
}

- (void)splitView:(CPSplitView)aSplitView resizeSubviewsWithOldSize:(CGSize)oldSize
{
    // Sidebar keeps its width, the people pane takes up the rest.
    var subviews = [aSplitView subviews],
        sidebar = subviews[0],
        main = subviews[1],
        size = [aSplitView bounds].size,
        divider = [aSplitView dividerThickness],
        sidebarWidth = [aSplitView isSubviewCollapsed:sidebar] ? 0 : CGRectGetWidth([sidebar frame]);

    [sidebar setFrame:CGRectMake(0, 0, sidebarWidth, size.height)];
    [main setFrame:CGRectMake(sidebarWidth + divider, 0, MAX(0, size.width - sidebarWidth - divider), size.height)];

    // Custom layout bypasses CPSplitView's own pass: redraw the divider.
    [aSplitView setNeedsDisplay:YES];
}

- (BOOL)isSidebarVisible
{
    var sidebar = [_sourceListController view];
    return ![_splitView isSubviewCollapsed:sidebar] && CGRectGetWidth([sidebar frame]) > 0;
}

// ---------------------------------------------------------------- Source list delegate

- (void)sourceListViewController:(SourceListViewController)aController didSelectItem:(id)anItem
{
    _selectedItem = anItem;
    [self _refreshPeople];
}

- (void)_selectSourceItem:(id)anItem
{
    _selectedItem = anItem;
    [_sourceListController reloadAndSelectItem:anItem];
    [self _refreshPeople];
}

// ---------------------------------------------------------------- Model -> view

- (void)libraryDidChange:(CPNotification)aNotification
{
    var kind = [[aNotification userInfo] objectForKey:LibraryChangeKindKey];

    if (![_library containsItem:_selectedItem])
        _selectedItem = [_library allPeopleItem];

    // Names, order and badges are all rendered by the outline.
    [_sourceListController reloadAndSelectItem:_selectedItem];

    if (kind === LibraryChangeStructural)
        [self _refreshPeople];
    else
        [_peopleController rearrange];
}

- (CPPredicate)_combinedPredicate
{
    var subpredicates = [],
        folderPredicate = [_library predicateForItem:_selectedItem];

    if (folderPredicate)
        subpredicates.push(folderPredicate);

    if (_searchPredicate)
        subpredicates.push(_searchPredicate);

    if (subpredicates.length === 0)
        return nil;

    if (subpredicates.length === 1)
        return subpredicates[0];

    return [CPCompoundPredicate andPredicateWithSubpredicates:subpredicates];
}

- (void)_refreshPeople
{
    var item = _selectedItem || [_library allPeopleItem];

    [_peopleController setPeople:[_library baseContentForItem:item]
                 filterPredicate:[self _combinedPredicate]
                           title:[item name]];
}

// ---------------------------------------------------------------- Search

- (void)searchFieldDidChange:(id)sender
{
    var searchString = [[_searchField stringValue] stringByTrimmingWhitespace];

    if (![searchString length])
        _searchPredicate = nil;
    else
        _searchPredicate = [CPPredicate predicateWithFormat:@"(firstName CONTAINS[cd] %@) OR (lastName CONTAINS[cd] %@) OR (email CONTAINS[cd] %@) OR (city CONTAINS[cd] %@) OR (department CONTAINS[cd] %@)",
                            searchString, searchString, searchString, searchString, searchString];

    [self _refreshPeople];
}

- (void)focusSearchField:(id)sender
{
    [[self window] makeFirstResponder:_searchField];
}

// ---------------------------------------------------------------- Source item actions

- (SmartFolderEditorController)_folderEditor
{
    if (!_folderEditor)
        _folderEditor = [[SmartFolderEditorController alloc] initWithLibrary:_library];

    return _folderEditor;
}

- (NameSheetController)_nameSheet
{
    if (!_nameSheet)
        _nameSheet = [[NameSheetController alloc] init];

    return _nameSheet;
}

- (BOOL)_isSheetVisible
{
    return !![[self window] attachedSheet];
}

- (void)newSmartFolder:(id)sender
{
    if ([self _isSheetVisible])
        return;

    [[self _folderEditor] beginEditingFolder:nil modalForWindow:[self window] completion:function(folder)
    {
        [self _selectSourceItem:folder];
    }];
}

- (void)editSelectedSmartFolder:(id)sender
{
    if (![_selectedItem isKindOfClass:[SmartFolder class]] || [self _isSheetVisible])
        return;

    var folder = _selectedItem;

    [[self _folderEditor] beginEditingFolder:folder modalForWindow:[self window] completion:function(aFolder)
    {
        [self _selectSourceItem:aFolder];
    }];
}

- (void)newGroup:(id)sender
{
    if ([self _isSheetVisible])
        return;

    [[self _nameSheet] beginWithTitle:@"New Group" name:@"Untitled Group" okTitle:@"Create" modalForWindow:[self window] completion:function(name)
    {
        var group = [_library addGroupWithName:name people:[]];
        [self _selectSourceItem:group];
    }];
}

- (void)renameSelectedGroup:(id)sender
{
    if (![_selectedItem isKindOfClass:[LibraryGroup class]] || [self _isSheetVisible])
        return;

    var group = _selectedItem;

    [[self _nameSheet] beginWithTitle:@"Rename Group" name:[group name] okTitle:@"Rename" modalForWindow:[self window] completion:function(name)
    {
        [_library renameItem:group to:name];
    }];
}

- (void)deleteSelectedSourceItem:(id)sender
{
    if (![_selectedItem isUserItem])
        return;

    [_library removeItem:_selectedItem];
}

// ---------------------------------------------------------------- People actions

- (void)newPerson:(id)sender
{
    // A new person would be invisible in a smart folder or a filtered list.
    if ([_selectedItem isKindOfClass:[SmartFolder class]])
        _selectedItem = [_library allPeopleItem];

    if (_searchPredicate)
    {
        [_searchField setStringValue:@""];
        _searchPredicate = nil;
    }

    var group = [_selectedItem isKindOfClass:[LibraryGroup class]] ? _selectedItem : nil,
        person = [_library createPerson];

    if (group)
        [_library addPeople:[person] toGroup:group];

    [_peopleController selectPerson:person edit:YES];
}

- (void)removeSelectedPeople:(id)sender
{
    var people = [_peopleController selectedPeople];

    if (![people count])
        return;

    if ([_selectedItem isKindOfClass:[LibraryGroup class]])
        [_library removePeople:people fromGroup:_selectedItem];
    else
        [_library removePeople:people];
}

- (void)delete:(id)sender
{
    [self removeSelectedPeople:sender];
}

- (void)copy:(id)sender
{
    [_peopleController copySelectionToPasteboard:[CPPasteboard generalPasteboard]];
}

- (void)cut:(id)sender
{
    [self copy:sender];
    [self removeSelectedPeople:sender];
}

- (void)paste:(id)sender
{
    var pasteboard = [CPPasteboard generalPasteboard],
        people = [_peopleController peopleFromTabSeparatedString:[pasteboard stringForType:CPStringPboardType]];

    if (![people count])
        return;

    if ([_selectedItem isKindOfClass:[SmartFolder class]])
        _selectedItem = [_library allPeopleItem];

    [_library addPeople:people];

    if ([_selectedItem isKindOfClass:[LibraryGroup class]])
        [_library addPeople:people toGroup:_selectedItem];

    [[_peopleController arrayController] setSelectedObjects:people];
}

// ---------------------------------------------------------------- View actions

- (void)toggleSidebar:(id)sender
{
    if ([self isSidebarVisible])
    {
        _lastSidebarWidth = CGRectGetWidth([[_sourceListController view] frame]);
        [_splitView setPosition:0 ofDividerAtIndex:0];
    }
    else
        [_splitView setPosition:MAX(_lastSidebarWidth, SidebarMinWidth) ofDividerAtIndex:0];
}

- (void)toggleDetail:(id)sender
{
    [_peopleController toggleDetail];
}

- (void)showAllPeople:(id)sender
{
    [self _selectSourceItem:[_library allPeopleItem]];
}

- (void)resetLibrary:(id)sender
{
    if ([self _isSheetVisible])
        return;

    var alert = [[CPAlert alloc] init];

    [alert setAlertStyle:CPWarningAlertStyle];
    [alert setMessageText:@"Reset the library?"];
    [alert setInformativeText:@"All people, groups and smart folders will be replaced by the sample data. This cannot be undone."];
    [alert addButtonWithTitle:@"Reset"];
    [alert addButtonWithTitle:@"Cancel"];

    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(resetAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:nil];
}

- (void)resetAlertDidEnd:(CPAlert)anAlert returnCode:(int)aReturnCode contextInfo:(id)aContext
{
    // First button: 0 in classic Cappuccino, CPAlertFirstButtonReturn where defined.
    var firstButton = (typeof CPAlertFirstButtonReturn !== "undefined") ? CPAlertFirstButtonReturn : 0;

    if (aReturnCode !== firstButton && aReturnCode !== 0)
        return;

    [_searchField setStringValue:@""];
    _searchPredicate = nil;
    _selectedItem = [_library allPeopleItem];

    [_library resetToSampleData];
}

// ---------------------------------------------------------------- Validation

- (BOOL)validateMenuItem:(CPMenuItem)anItem
{
    var action = [anItem action],
        sheet = [self _isSheetVisible],
        hasPeopleSelection = [[_peopleController selectedPeople] count] > 0;

    switch (action)
    {
        case @selector(newSmartFolder:):
        case @selector(newGroup:):
        case @selector(resetLibrary:):
            return !sheet;

        case @selector(editSelectedSmartFolder:):
            return !sheet && [_selectedItem isKindOfClass:[SmartFolder class]];

        case @selector(renameSelectedGroup:):
            return !sheet && [_selectedItem isKindOfClass:[LibraryGroup class]];

        case @selector(deleteSelectedSourceItem:):
            return !sheet && [_selectedItem isUserItem];

        case @selector(copy:):
        case @selector(cut:):
        case @selector(delete:):
        case @selector(removeSelectedPeople:):
            return !sheet && hasPeopleSelection;

        case @selector(paste:):
            return !sheet && [[[CPPasteboard generalPasteboard] types] containsObject:CPStringPboardType];

        case @selector(toggleSidebar:):
            [anItem setTitle:[self isSidebarVisible] ? @"Hide Sidebar" : @"Show Sidebar"];
            return YES;

        case @selector(toggleDetail:):
            [anItem setTitle:[_peopleController isDetailVisible] ? @"Hide Details" : @"Show Details"];
            return YES;
    }

    return YES;
}

@end
