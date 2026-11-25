/*
 * MainWindowController.j
 * People
 *
 * Owns the full-platform (bridge) main window. Instantiates the sidebar and
 * people view controllers and hands them to MainSplitViewController, the window's
 * content view controller, which lays out the three panes. Exercises:
 *   - CPWindowController created in code, window delegate + responder chain
 *     target for menu / toolbar / button bar actions (sent to nil)
 *   - CPToolbar with standard image items, whose glyphs come from the asset
 *     catalog with a dark variant, and a view item (CPSearchField)
 *   - CPWindow content view controller
 *   - one -validateUserInterfaceItem: for the menus and the toolbar items
 *   - CPAlert as a sheet
 *   - CPPasteboard copy / paste
 */

@import <AppKit/AppKit.j>
@import "../../Library/Library.j"
@import "../../Library/Navigation/SourceListViewController.j"
@import "../../Library/ContentViewer/PeopleViewController.j"
@import "../MainWindowSplitView/MainSplitViewController.j"
@import "../../Library/Navigation/SmartFolderEditor/SmartFolderEditorController.j"
@import "../../Library/Navigation/GroupNameSheet/NameSheetController.j"
@import "../../ApplicationLifecycle/Settings/SettingsWindowController.j"

var ToolbarSidebarIdentifier    = @"SidebarItem",
    ToolbarNewFolderIdentifier  = @"NewSmartFolderItem",
    ToolbarNewGroupIdentifier   = @"NewGroupItem",
    ToolbarEditIdentifier       = @"EditFolderItem",
    ToolbarDetailIdentifier     = @"DetailItem",
    ToolbarSearchIdentifier     = @"SearchItem",
    ToolbarNewPersonIdentifier  = @"NewPersonItem",
    ToolbarAllPeopleIdentifier  = @"ShowAllPeopleItem",
    ToolbarItemImageSize        = CGSizeMake(32.0, 32.0),
    ResetAlertResetTag          = 1001,
    ResetAlertCancelTag         = 1002;

@implementation MainWindowController : CPWindowController
{
    Library                     _library;

    MainSplitViewController     _splitViewController;
    SourceListViewController    _sourceListController;
    PeopleViewController        _peopleController;
    SmartFolderEditorController _folderEditor;
    NameSheetController         _nameSheet;

    CPSearchField               _searchField;
    CPPredicate                 _searchPredicate;
    id                          _selectedItem;
}

- (id)initWithLibrary:(Library)aLibrary
{
    var window = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];

    if (self = [super initWithWindow:window])
    {
        _library = aLibrary;

        [window setDelegate:self];
        [window setTitle:@"Smart Folders Demo"];

        _sourceListController = [[SourceListViewController alloc] initWithLibrary:_library];
        [_sourceListController setDelegate:self];

        _peopleController = [[PeopleViewController alloc] initWithLibrary:_library];

        _splitViewController = [[MainSplitViewController alloc] initWithSourceListController:_sourceListController peopleController:_peopleController];

        [self _buildToolbar];
        [window setContentViewController:_splitViewController];

        [[CPNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(libraryDidChange:)
                                                     name:LibraryDidChangeNotification
                                                   object:_library];

        [self _selectSourceItem:[_library allPeopleItem]];
    }

    return self;
}

// ---------------------------------------------------------------- Interface

- (void)_buildToolbar
{
    _searchField = [[CPSearchField alloc] initWithFrame:CGRectMake(0, 0, 220, 30)];
    [_searchField setPlaceholderString:@"Search people"];
    [_searchField setTarget:self];
    [_searchField setAction:@selector(searchFieldDidChange:)];
    [_searchField setSendsSearchStringImmediately:YES];
    [_searchField setRecentsAutosaveName:@"People.RecentSearches"];
    [_searchField setSearchMenuTemplate:[_searchField defaultSearchMenuTemplate]];

    var toolbar = [[CPToolbar alloc] initWithIdentifier:@"PeopleToolbar"];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDelegate:self];
    [toolbar setVisible:YES];
    [[self window] setToolbar:toolbar];
}

- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)aToolbar
{
    return [ToolbarSidebarIdentifier, ToolbarNewFolderIdentifier, ToolbarNewGroupIdentifier, ToolbarEditIdentifier,
            ToolbarNewPersonIdentifier, ToolbarAllPeopleIdentifier, ToolbarDetailIdentifier, ToolbarSearchIdentifier,
            CPToolbarShowColorsItemIdentifier, CPToolbarShowFontsItemIdentifier, CPToolbarPrintItemIdentifier,
            CPToolbarCustomizeToolbarItemIdentifier,
            CPToolbarFlexibleSpaceItemIdentifier, CPToolbarSpaceItemIdentifier, CPToolbarSeparatorItemIdentifier];
}

- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)aToolbar
{
    return [ToolbarSidebarIdentifier, CPToolbarSpaceItemIdentifier,
            ToolbarNewFolderIdentifier, ToolbarNewGroupIdentifier, ToolbarEditIdentifier,
            CPToolbarFlexibleSpaceItemIdentifier,
            CPToolbarShowColorsItemIdentifier, ToolbarDetailIdentifier, ToolbarSearchIdentifier];
}

- (CPToolbarItem)toolbar:(CPToolbar)aToolbar itemForItemIdentifier:(CPString)anIdentifier willBeInsertedIntoToolbar:(BOOL)aFlag
{
    var item = [[CPToolbarItem alloc] initWithItemIdentifier:anIdentifier];

    switch (anIdentifier)
    {
        case ToolbarSidebarIdentifier:
            [self _configureItem:item label:@"Sidebar" imageName:@"ToolbarSidebar" action:@selector(toggleSidebar:) toolTip:@"Show or hide the sidebar"];
            break;

        case ToolbarNewFolderIdentifier:
            [self _configureItem:item label:@"New Smart Folder" imageName:@"ToolbarNewSmartFolder" action:@selector(newSmartFolder:) toolTip:@"Create a smart folder from a predicate"];
            break;

        case ToolbarNewGroupIdentifier:
            [self _configureItem:item label:@"New Group" imageName:@"ToolbarNewGroup" action:@selector(newGroup:) toolTip:@"Create an empty group (or drop people on GROUPS)"];
            break;

        case ToolbarEditIdentifier:
            [self _configureItem:item label:@"Edit" imageName:@"ToolbarEdit" action:@selector(editSelectedSmartFolder:) toolTip:@"Edit the selected smart folder"];
            break;

        case ToolbarNewPersonIdentifier:
            [self _configureItem:item label:@"New Person" imageName:@"ToolbarNewPerson" action:@selector(newPerson:) toolTip:@"Add a person to the library"];
            break;

        case ToolbarAllPeopleIdentifier:
            [self _configureItem:item label:@"All People" imageName:@"ToolbarShowAllPeople" action:@selector(showAllPeople:) toolTip:@"Show all people"];
            break;

        case ToolbarDetailIdentifier:
            [self _configureItem:item label:@"Details" imageName:@"ToolbarDetails" action:@selector(toggleDetail:) toolTip:@"Show or hide the detail pane"];
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

/*
    Makes anItem a standard image item. The image comes from the asset catalog, which holds a
    light and a dark glyph, so the glyph follows the appearance. The size is given, because an
    asset image may not have loaded when the item is made. The item validates with the menus
    (-validateToolbarItem:).
*/
- (void)_configureItem:(CPToolbarItem)anItem label:(CPString)aLabel imageName:(CPString)anImageName action:(SEL)anAction toolTip:(CPString)aToolTip
{
    [anItem setLabel:aLabel];
    [anItem setPaletteLabel:aLabel];
    [anItem setToolTip:aToolTip];
    [anItem setImage:[CPImage imageNamed:anImageName]];
    [anItem setMinSize:ToolbarItemImageSize];
    [anItem setMaxSize:ToolbarItemImageSize];
    [anItem setTarget:self];
    [anItem setAction:anAction];
}

// ---------------------------------------------------------------- Panes

- (BOOL)isSidebarVisible
{
    return [_splitViewController isSidebarVisible];
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
        _searchPredicate = [CPPredicate predicateWithFormat:@"(firstName CONTAINS[cd] %@) OR (lastName CONTAINS[cd] %@) OR (email CONTAINS[cd] %@) OR (city CONTAINS[cd] %@) OR (department CONTAINS[cd] %@) OR (notesText CONTAINS[cd] %@)",
                            searchString, searchString, searchString, searchString, searchString, searchString];

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

    // A new person is filled in at once, so adding one turns on edit mode.
    [_library setEditable:YES];
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
    [_splitViewController toggleSidebar:sender];
}

- (void)toggleDetail:(id)sender
{
    [_splitViewController toggleDetail:sender];
}

- (void)showAllPeople:(id)sender
{
    [self _selectSourceItem:[_library allPeopleItem]];
}

- (void)resetApplication:(id)sender
{
    if ([self _isSheetVisible])
        return;

    var alert = [[CPAlert alloc] init];

    [alert setAlertStyle:CPWarningAlertStyle];
    [alert setMessageText:@"Reset the application?"];
    [alert setInformativeText:@"All people, groups and smart folders will be replaced by the sample data. The toolbar, the sidebar, the detail pane, the recent searches and the appearance return to their defaults. This cannot be undone."];
    [alert addButtonWithTitle:@"Reset"];
    [alert addButtonWithTitle:@"Cancel"];

    /*
        CPAlert reports the clicked button's tag as the return code. The application gives its
        own tags, found by title. -[CPAlert buttons] lists the buttons in the reverse order of
        addition, unlike AppKit, so tags given by index went to the wrong buttons: Reset did
        nothing and Cancel reset the application.
    */
    [[alert buttons] enumerateObjectsUsingBlock:function(aButton)
    {
        [aButton setTag:[aButton title] === @"Reset" ? ResetAlertResetTag : ResetAlertCancelTag];
    }];

    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(resetAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:nil];
}

- (void)resetAlertDidEnd:(CPAlert)anAlert returnCode:(int)aReturnCode contextInfo:(id)aContext
{
    if (aReturnCode !== ResetAlertResetTag)
        return;

    [_searchField setStringValue:@""];
    [_searchField setRecentSearches:[]];
    _searchPredicate = nil;
    _selectedItem = [_library allPeopleItem];

    [_library resetToSampleData];

    var toolbar = [[self window] toolbar];

    [toolbar setConfigurationFromDictionary:@{
        @"TB Item Identifiers": [self toolbarDefaultItemIdentifiers:toolbar],
        @"TB Display Mode": CPToolbarDisplayModeDefault,
        @"TB Size Mode": CPToolbarSizeModeDefault
    }];
    [toolbar setVisible:YES];

    [_splitViewController restoreDefaultLayout];

    [SettingsWindowController resetAppearance];
}

// ---------------------------------------------------------------- Validation

/*
    Decides for the menus and the toolbar items together whether an action is enabled, so a
    toolbar item and the menu item with the same action always agree.
*/
- (BOOL)validateUserInterfaceItem:(id)anItem
{
    var action = [anItem action],
        sheet = [self _isSheetVisible],
        hasPeopleSelection = [[_peopleController selectedPeople] count] > 0;

    switch (action)
    {
        case @selector(newSmartFolder:):
        case @selector(newGroup:):
        case @selector(resetApplication:):
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
    }

    return YES;
}

/*
    A menu item also shows the state of a toggle in its title.
*/
- (BOOL)validateMenuItem:(CPMenuItem)anItem
{
    switch ([anItem action])
    {
        case @selector(toggleSidebar:):
            [anItem setTitle:[self isSidebarVisible] ? @"Hide Sidebar" : @"Show Sidebar"];
            break;

        case @selector(toggleDetail:):
            [anItem setTitle:[_splitViewController isDetailVisible] ? @"Hide Details" : @"Show Details"];
            break;
    }

    return [self validateUserInterfaceItem:anItem];
}

- (BOOL)validateToolbarItem:(CPToolbarItem)anItem
{
    return [self validateUserInterfaceItem:anItem];
}

@end
