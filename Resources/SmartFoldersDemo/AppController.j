/*
 * AppController.j
 * SmartFoldersDemo
 *
 * Non-document-based Cappuccino integration test / demo, built entirely in
 * code (no cib/xib). The application delegate only creates the model, the
 * main menu and the main window controller; everything else lives in the
 * view controllers.
 *
 *   AppController
 *     └─ MainWindowController            (CPWindowController, bridge window, toolbar)
 *          ├─ SourceListViewController   (view-based CPOutlineView, badges, DnD target)
 *          ├─ PeopleViewController       (bound CPTableView, CPArrayController, DnD source)
 *          │    └─ PersonDetailViewController (selection bindings)
 *          ├─ SmartFolderEditorController (sheet, CPPredicateEditor)
 *          └─ NameSheetController         (sheet)
 *
 * Data (people, groups, smart folders) is persisted in CPUserDefaults.
 * Use File ▸ Reset Library… to return to the deterministic sample data.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "Library.j"
@import "MainWindowController.j"

@implementation AppController : CPObject
{
    Library                 _library;
    MainWindowController    _mainWindowController;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    _library = [[Library alloc] init];

    [self _buildMainMenu];
    [CPMenu setMenuBarVisible:YES];

    _mainWindowController = [[MainWindowController alloc] initWithLibrary:_library];
    [_mainWindowController showWindow:self];
}

// ---------------------------------------------------------------- Menu

- (CPMenuItem)_addItem:(CPString)aTitle action:(SEL)anAction key:(CPString)aKey modifiers:(unsigned)aMask to:(CPMenu)aMenu
{
    var item = [aMenu addItemWithTitle:aTitle action:anAction keyEquivalent:aKey || @""];

    if (aMask)
        [item setKeyEquivalentModifierMask:aMask];

    return item;
}

- (CPMenu)_addSubmenu:(CPString)aTitle to:(CPMenu)aMainMenu
{
    var item = [aMainMenu addItemWithTitle:aTitle action:nil keyEquivalent:@""],
        menu = [[CPMenu alloc] initWithTitle:aTitle];

    [aMainMenu setSubmenu:menu forItem:item];

    return menu;
}

- (void)_buildMainMenu
{
    var mainMenu = [CPApp mainMenu];

    while ([mainMenu numberOfItems] > 0)
        [mainMenu removeItemAtIndex:0];

    var commandOption = CPCommandKeyMask | CPAlternateKeyMask;

    // File
    var fileMenu = [self _addSubmenu:@"File" to:mainMenu];
    [self _addItem:@"New Smart Folder…" action:@selector(newSmartFolder:) key:@"n" modifiers:commandOption to:fileMenu];
    [self _addItem:@"New Group…" action:@selector(newGroup:) key:@"g" modifiers:commandOption to:fileMenu];
    [self _addItem:@"New Person" action:@selector(newPerson:) key:@"p" modifiers:commandOption to:fileMenu];
    [fileMenu addItem:[CPMenuItem separatorItem]];
    [self _addItem:@"Edit Smart Folder…" action:@selector(editSelectedSmartFolder:) key:@"e" modifiers:commandOption to:fileMenu];
    [self _addItem:@"Rename Group…" action:@selector(renameSelectedGroup:) key:nil modifiers:0 to:fileMenu];
    [self _addItem:@"Delete Group or Smart Folder" action:@selector(deleteSelectedSourceItem:) key:nil modifiers:0 to:fileMenu];
    [fileMenu addItem:[CPMenuItem separatorItem]];
    [self _addItem:@"Reset Library…" action:@selector(resetLibrary:) key:nil modifiers:0 to:fileMenu];

    // Edit
    var editMenu = [self _addSubmenu:@"Edit" to:mainMenu];
    [self _addItem:@"Undo" action:@selector(undo:) key:@"z" modifiers:0 to:editMenu];
    [self _addItem:@"Redo" action:@selector(redo:) key:@"Z" modifiers:0 to:editMenu];
    [editMenu addItem:[CPMenuItem separatorItem]];
    [self _addItem:@"Cut" action:@selector(cut:) key:@"x" modifiers:0 to:editMenu];
    [self _addItem:@"Copy" action:@selector(copy:) key:@"c" modifiers:0 to:editMenu];
    [self _addItem:@"Paste" action:@selector(paste:) key:@"v" modifiers:0 to:editMenu];
    [self _addItem:@"Delete" action:@selector(delete:) key:nil modifiers:0 to:editMenu];
    [self _addItem:@"Select All" action:@selector(selectAll:) key:@"a" modifiers:0 to:editMenu];
    [editMenu addItem:[CPMenuItem separatorItem]];
    [self _addItem:@"Find" action:@selector(focusSearchField:) key:@"f" modifiers:0 to:editMenu];

    // View
    var viewMenu = [self _addSubmenu:@"View" to:mainMenu];
    [self _addItem:@"Hide Sidebar" action:@selector(toggleSidebar:) key:@"s" modifiers:CPCommandKeyMask | CPControlKeyMask to:viewMenu];
    [self _addItem:@"Hide Details" action:@selector(toggleDetail:) key:@"d" modifiers:CPCommandKeyMask | CPControlKeyMask to:viewMenu];
    [viewMenu addItem:[CPMenuItem separatorItem]];
    [self _addItem:@"Show All People" action:@selector(showAllPeople:) key:@"1" modifiers:0 to:viewMenu];
}

@end
