@import <AppKit/CPMenu.j>
@import <AppKit/CPMenuItem.j>
@import <AppKit/CPApplication.j>
@import <AppKit/CPText.j>

@import "BuiltThemes.j"


@implementation CPMenuTest : OJTestCase
{
    CPMenu  menu;
    BOOL    escapeWasCalled;
    BOOL    escapeNoModifierWasCalled;
    BOOL    openDocumentWasCalled;
    BOOL    saveDocumentWasCalled;
    BOOL    saveDocumentAsWasCalled;
    BOOL    undoWasCalled;

    CPMenuItem anInstantiatedMenuItem;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    // Set up a fairly complete menu to have something to work with.
    menu = [[CPMenu alloc] initWithTitle:@"MainMenu"];

    var newMenuItem = [[CPMenuItem alloc] initWithTitle:@"New" action:@selector(newDocument:) keyEquivalent:@"n"];
    [menu addItem:newMenuItem];

    var openMenuItem = [[CPMenuItem alloc] initWithTitle:@"Open" action:@selector(openDocument:) keyEquivalent:@"o"];
    [menu addItem:openMenuItem];

    var saveMenu = [[CPMenu alloc] initWithTitle:@"Save"],
        saveMenuItem = [[CPMenuItem alloc] initWithTitle:@"Save" action:@selector(saveDocument:) keyEquivalent:nil];
    // S
    [saveMenu addItem:[[CPMenuItem alloc] initWithTitle:@"Save" action:@selector(saveDocument:) keyEquivalent:@"s"]];
    // ...vs Shift-S
    [saveMenu addItem:[[CPMenuItem alloc] initWithTitle:@"Save As" action:@selector(saveDocumentAs:) keyEquivalent:@"S"]];


    // Cmd-Escape
    [saveMenu addItem:[[CPMenuItem alloc] initWithTitle:@"Escape the monotonous" action:@selector(escape:) keyEquivalent:CPEscapeFunctionKey]];
    // Escape
    var pureEscape = [[CPMenuItem alloc] initWithTitle:@"Escape the cruel" action:@selector(escapeNoModifier:) keyEquivalent:CPEscapeFunctionKey];
    [pureEscape setKeyEquivalentModifierMask:0];
    [saveMenu addItem:pureEscape];

    [saveMenuItem setSubmenu:saveMenu];
    [menu addItem:saveMenuItem];

    var editMenuItem = [[CPMenuItem alloc] initWithTitle:@"Edit" action:nil keyEquivalent:nil],
        editMenu = [[CPMenu alloc] initWithTitle:@"Edit"],

        undoMenuItem = [[CPMenuItem alloc] initWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:CPUndoKeyEquivalent],
        redoMenuItem = [[CPMenuItem alloc] initWithTitle:@"Redo" action:@selector(redo:) keyEquivalent:CPRedoKeyEquivalent];

    [undoMenuItem setKeyEquivalentModifierMask:CPUndoKeyEquivalentModifierMask];
    [redoMenuItem setKeyEquivalentModifierMask:CPRedoKeyEquivalentModifierMask];

    [editMenu addItem:undoMenuItem];
    [editMenu addItem:redoMenuItem];

    [editMenu addItem:[[CPMenuItem alloc] initWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"]],
    [editMenu addItem:[[CPMenuItem alloc] initWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"]],
    [editMenu addItem:[[CPMenuItem alloc] initWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"]];

    [editMenuItem setSubmenu:editMenu];
    [editMenuItem setHidden:YES];

    [menu addItem:editMenuItem];
    [menu addItem:[CPMenuItem separatorItem]];

    // Test Issue 1899
    anInstantiatedMenuItem = [[CPMenuItem alloc] initWithTitle:@"Highlight" action:nil keyEquivalent:@""];
    [menu addItem:anInstantiatedMenuItem];
}

- (void)_retarget:(CPMenuItem)aMenu
{
    if (!aMenu)
        return;

    for (var i = 0; i < [aMenu numberOfItems]; i++)
    {
        var item = [aMenu itemAtIndex:i];
        [item setTarget:self];
        [self _retarget:[item submenu]];
    }
}

- (void)testRemoveAllItemsHighlighting
{
    // hack it so that this menu item is highlighted
    [menu _highlightItemAtIndex:[menu indexOfItem:anInstantiatedMenuItem]];

    // test both the public isHighlighted method, as well as the underlying view highlighting
    [self assertTrue:[anInstantiatedMenuItem isHighlighted]];
    [self assertTrue:[[[anInstantiatedMenuItem _menuItemView] view] isHighlighted] message:@"Underlying view was not highlighted in removeAll"];

    [menu removeAllItems];

    [self assertFalse:[anInstantiatedMenuItem isHighlighted]];
    [self assertFalse:[[[anInstantiatedMenuItem _menuItemView] view] isHighlighted] message:@"Underlying view was still highlighted after removeAll"];
}

- (void)testRemoveOneItemHighlighting
{
    [menu _highlightItemAtIndex:[menu indexOfItem:anInstantiatedMenuItem]];

    [self assertTrue:[anInstantiatedMenuItem isHighlighted]];
    [self assertTrue:[[[anInstantiatedMenuItem _menuItemView] view] isHighlighted] message:@"Underlying view was not highlighted in removeItem"];

    [menu removeItem:anInstantiatedMenuItem];

    [self assertFalse:[anInstantiatedMenuItem isHighlighted]];
    [self assertFalse:[[[anInstantiatedMenuItem _menuItemView] view] isHighlighted] message:@"Underlying view was still highlighted after removeItem"];
}

- (void)testRemoveOneItemByIndexHighlighting
{
    [menu _highlightItemAtIndex:[menu indexOfItem:anInstantiatedMenuItem]];

    [self assertTrue:[anInstantiatedMenuItem isHighlighted]];
    [self assertTrue:[[[anInstantiatedMenuItem _menuItemView] view] isHighlighted] message:@"Underlying view was not highlighted in removeItemAtIndex"];

    [menu removeItemAtIndex:[menu indexOfItem:anInstantiatedMenuItem]];

    [self assertFalse:[anInstantiatedMenuItem isHighlighted]];
    [self assertFalse:[[[anInstantiatedMenuItem _menuItemView] view] isHighlighted] message:@"Underlying view was still highlighted after removeItemAtIndex"];
}

- (void)testSetEnabledHighlighting
{
    [menu _highlightItemAtIndex:[menu indexOfItem:anInstantiatedMenuItem]];

    [self assertTrue:[anInstantiatedMenuItem isHighlighted]];

    [anInstantiatedMenuItem setEnabled:NO];

    [self assertFalse:[anInstantiatedMenuItem isHighlighted]];
    [self assertFalse:[[[anInstantiatedMenuItem _menuItemView] view] isHighlighted] message:@"Underlying view was still highlighted after setEnabled:NO"];
}

- (void)testKeyEquivalent
{
    [self _retarget:menu];

    // Don't match anything.
    [menu performKeyEquivalent:[CPEvent keyEventWithType:CPKeyDown location:CGPointMakeZero() modifierFlags:CPPlatformActionKeyMask
        timestamp:0 windowNumber:0 context:nil
        characters:"b" charactersIgnoringModifiers:"b" isARepeat:NO keyCode:0 isActionKey:NO]];
    [self assertFalse:escapeWasCalled || escapeNoModifierWasCalled || openDocumentWasCalled || undoWasCalled];

    [menu performKeyEquivalent:[CPEvent keyEventWithType:CPKeyDown location:CGPointMakeZero() modifierFlags:0
        timestamp:0 windowNumber:0 context:nil
        characters:"o" charactersIgnoringModifiers:"o" isARepeat:NO keyCode:0 isActionKey:NO]];
    [self assertFalse:escapeWasCalled || escapeNoModifierWasCalled || openDocumentWasCalled || undoWasCalled];

    [menu performKeyEquivalent:[CPEvent keyEventWithType:CPKeyDown location:CGPointMakeZero() modifierFlags:CPPlatformActionKeyMask
        timestamp:0 windowNumber:0 context:nil
        characters:"o" charactersIgnoringModifiers:"o" isARepeat:NO keyCode:0 isActionKey:NO]];
    [self assertFalse:escapeWasCalled || escapeNoModifierWasCalled || undoWasCalled];
    [self assertTrue:openDocumentWasCalled message:"expect openDocumentWasCalled"];

    openDocumentWasCalled = NO;
    [menu performKeyEquivalent:[CPEvent keyEventWithType:CPKeyDown location:CGPointMakeZero() modifierFlags:CPPlatformActionKeyMask
        timestamp:0 windowNumber:0 context:nil
        characters:CPUndoKeyEquivalent charactersIgnoringModifiers:CPUndoKeyEquivalent isARepeat:NO keyCode:0 isActionKey:NO]];
    [self assertFalse:escapeWasCalled || escapeNoModifierWasCalled || openDocumentWasCalled];
    [self assertTrue:undoWasCalled];
}

- (void)testKeyEquivalentModifierMask
{
    [self _retarget:menu];

    [menu performKeyEquivalent:[CPEvent keyEventWithType:CPKeyDown location:CGPointMakeZero() modifierFlags:0
        timestamp:0 windowNumber:0 context:nil
        characters:CPEscapeFunctionKey charactersIgnoringModifiers:CPEscapeFunctionKey isARepeat:NO keyCode:0 isActionKey:NO]];
    [self assertFalse:escapeWasCalled || openDocumentWasCalled || undoWasCalled];
    [self assertTrue:escapeNoModifierWasCalled];

    escapeNoModifierWasCalled = NO;

    [menu performKeyEquivalent:[CPEvent keyEventWithType:CPKeyDown location:CGPointMakeZero() modifierFlags:CPPlatformActionKeyMask
        timestamp:0 windowNumber:0 context:nil
        characters:CPEscapeFunctionKey charactersIgnoringModifiers:CPEscapeFunctionKey isARepeat:NO keyCode:0 isActionKey:NO]];
    [self assertFalse:escapeNoModifierWasCalled || openDocumentWasCalled || undoWasCalled];
    [self assertTrue:escapeWasCalled];
}

- (void)testKeyEquivalentWithShiftMask
{
    [self _retarget:menu];

    [menu performKeyEquivalent:[CPEvent keyEventWithType:CPKeyDown location:CGPointMakeZero() modifierFlags:CPPlatformActionKeyMask
        timestamp:0 windowNumber:0 context:nil
        characters:@"s" charactersIgnoringModifiers:@"s" isARepeat:NO keyCode:0 isActionKey:NO]];
    [self assertFalse:escapeWasCalled || escapeNoModifierWasCalled || openDocumentWasCalled || saveDocumentAsWasCalled || undoWasCalled];
    [self assertTrue:saveDocumentWasCalled message:"saveDocumentWasCalled"];

    saveDocumentWasCalled = NO;

    [menu performKeyEquivalent:[CPEvent keyEventWithType:CPKeyDown location:CGPointMakeZero() modifierFlags:CPPlatformActionKeyMask | CPShiftKeyMask
        timestamp:0 windowNumber:0 context:nil
        characters:@"s" charactersIgnoringModifiers:@"s" isARepeat:NO keyCode:0 isActionKey:NO]];
    [self assertFalse:escapeWasCalled || escapeNoModifierWasCalled || openDocumentWasCalled || saveDocumentWasCalled || undoWasCalled];
    [self assertTrue:saveDocumentAsWasCalled message:"saveDocumentAsWasCalled"];
}

- (void)escape:(id)sender
{
    escapeWasCalled = YES;
}

- (void)escapeNoModifier:(id)sender
{
    escapeNoModifierWasCalled = YES;
}

- (void)openDocument:(id)sender
{
    openDocumentWasCalled = YES;
}

- (void)saveDocument:(id)sender
{
    saveDocumentWasCalled = YES;
}

- (void)saveDocumentAs:(id)sender
{
    saveDocumentAsWasCalled = YES;
}

- (void)undo:(id)sender
{
    undoWasCalled = YES;
}

/*
    A menu window takes the background of the style it is given. Every style took the pop-up
    background. The test reads the built Aristo3 theme, so it needs the themes built first, as
    `npx jake build` does.
*/
- (void)testEachBackgroundStyleTakesItsOwnBackground
{
    var aristo3 = BuiltThemeNamed(@"Aristo3"),
        previousTheme = [CPTheme defaultTheme];

    [self assertNotNull:aristo3 message:@"The built blends hold no Aristo3 theme. Build the themes first."];

    [CPTheme setDefaultTheme:aristo3];

    try
    {
        var menuWindow = [[_CPMenuWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 100.0, 100.0) styleMask:CPBorderlessWindowMask];

        [menuWindow setBackgroundStyle:_CPMenuWindowMenuBarBackgroundStyle];
        [self assert:[aristo3 valueForAttributeWithName:@"menu-window-menu-bar-background-style-color" forClass:_CPMenuView] same:[menuWindow backgroundColor]];

        [menuWindow setBackgroundStyle:_CPMenuWindowPopUpBackgroundStyle];
        [self assert:[aristo3 valueForAttributeWithName:@"menu-window-pop-up-background-style-color" forClass:_CPMenuView] same:[menuWindow backgroundColor]];
    }
    finally
    {
        [CPTheme setDefaultTheme:previousTheme];
    }
}

// MARK: - Menu bar visibility

/*
    ojtest has no browser window for a window to fill and sets no primary platform window or
    main menu. This test sets both, and marks the window as one that fills its platform window
    without going through -setFullPlatformWindow:. The window starts below a visible menu bar;
    hiding the bar must move its top to the top of the platform window, and showing the bar
    must move it below the bar again.
*/
- (void)testAWindowThatFillsThePlatformWindowFollowsTheMenuBar
{
    var aristo3 = BuiltThemeNamed(@"Aristo3"),
        previousTheme = [CPTheme defaultTheme],
        previousPlatformWindow = [CPPlatformWindow primaryPlatformWindow],
        previousMainMenu = [CPApp mainMenu],
        platformWindow = [[CPPlatformWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 800.0, 600.0)];

    [self assertNotNull:aristo3 message:@"The built blends hold no Aristo3 theme. Build the themes first."];

    [CPTheme setDefaultTheme:aristo3];
    [CPPlatformWindow setPrimaryPlatformWindow:platformWindow];
    [CPApp setMainMenu:[[CPMenu alloc] initWithTitle:@"Main"]];

    try
    {
        var window = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 300.0) styleMask:CPBorderlessWindowMask],
            menuBarHeight = [CPMenu menuBarHeight];

        [window setPlatformWindow:platformWindow];
        window._isFullPlatformWindow = YES;
        [window orderFront:nil];

        [CPMenu setMenuBarVisible:YES];
        [window setFrame:[[window platformWindow] visibleFrame]];

        [self assertTrue:menuBarHeight > 0 message:@"the theme gives the menu bar a height"];
        [self assert:menuBarHeight equals:CGRectGetMinY([window frame]) message:@"the window starts below the menu bar"];

        [CPMenu setMenuBarVisible:NO];
        [self assert:0 equals:CGRectGetMinY([window frame]) message:@"hiding the menu bar moves the window to the top"];

        [CPMenu setMenuBarVisible:YES];
        [self assert:menuBarHeight equals:CGRectGetMinY([window frame]) message:@"showing the menu bar moves the window below it"];
    }
    finally
    {
        [CPMenu setMenuBarVisible:NO];

        /*
            -setMainMenu: cannot clear the main menu, so the test puts back an absent main menu
            directly.
        */
        if (previousMainMenu)
            [CPApp setMainMenu:previousMainMenu];
        else
            CPApp._menu = nil;

        [CPPlatformWindow setPrimaryPlatformWindow:previousPlatformWindow];
        [CPTheme setDefaultTheme:previousTheme];
    }
}

@end
