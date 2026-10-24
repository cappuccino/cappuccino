@import <AppKit/CPApplication.j>
@import <AppKit/CPMenu.j>
@import <AppKit/CPPanel.j>
@import <AppKit/CPWindow.j>

@implementation CPApplicationWindowsMenuTest : OJTestCase
{
    CPApplication   app;
    CPMenu          windowsMenu;
}

- (void)setUp
{
    app = [[CPApplication alloc] init];

    // A main menu whose Window submenu carries the name nib2cib gives the Windows menu.
    var mainMenu = [[CPMenu alloc] initWithTitle:@"Main"],
        windowsMenuItem = [[CPMenuItem alloc] initWithTitle:@"Window" action:nil keyEquivalent:@""];

    windowsMenu = [[CPMenu alloc] initWithTitle:@"Window"];
    [windowsMenu _setMenuName:@"_CPWindowsMenu"];
    [windowsMenu addItemWithTitle:@"Minimize" action:@selector(performMiniaturize:) keyEquivalent:@"m"];

    [windowsMenuItem setSubmenu:windowsMenu];
    [mainMenu addItem:windowsMenuItem];
    [app setMainMenu:mainMenu];
}

- (void)tearDown
{
    CPApp = nil;
}

- (CPWindow)visibleWindowWithTitle:(CPString)aTitle
{
    var aWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 200.0, 100.0) styleMask:CPTitledWindowMask];

    // There is no DOM in the test runner, so ordering a window in does not make it visible.
    aWindow._isVisible = YES;
    [aWindow setTitle:aTitle];

    return aWindow;
}

- (void)testWindowsMenuIsFoundInMainMenu
{
    [self assert:windowsMenu equals:[app windowsMenu]];
}

- (void)testVisibleTitledWindowIsListedBelowSeparator
{
    var aWindow = [self visibleWindowWithTitle:@"Report"];

    [self assert:3 equals:[windowsMenu numberOfItems]];
    [self assertTrue:[[windowsMenu itemAtIndex:1] isSeparatorItem] message:@"a separator should precede the window list"];

    var item = [windowsMenu itemAtIndex:2];

    [self assert:@"Report" equals:[item title]];
    [self assert:aWindow equals:[item target]];
    [self assert:@selector(makeKeyAndOrderFront:) equals:[item action]];
}

- (void)testRetitlingWindowChangesItsItem
{
    var aWindow = [self visibleWindowWithTitle:@"Report"];

    [aWindow setTitle:@"Final Report"];

    [self assert:3 equals:[windowsMenu numberOfItems]];
    [self assert:@"Final Report" equals:[[windowsMenu itemAtIndex:2] title]];
}

- (void)testUntitledWindowIsNotListed
{
    [self visibleWindowWithTitle:@""];

    [self assert:1 equals:[windowsMenu numberOfItems]];
}

- (void)testExcludedWindowIsNotListed
{
    var aWindow = [self visibleWindowWithTitle:@"Report"];

    [aWindow setExcludedFromWindowsMenu:YES];

    [self assert:1 equals:[windowsMenu numberOfItems]];

    [aWindow setExcludedFromWindowsMenu:NO];

    [self assert:3 equals:[windowsMenu numberOfItems]];
}

- (void)testPanelIsNotListed
{
    var panel = [[CPPanel alloc] initWithContentRect:CGRectMake(0.0, 0.0, 200.0, 100.0) styleMask:CPTitledWindowMask];

    panel._isVisible = YES;
    [panel setTitle:@"Inspector"];

    [self assert:1 equals:[windowsMenu numberOfItems]];
}

- (void)testMainWindowIsChecked
{
    var firstWindow = [self visibleWindowWithTitle:@"First"],
        secondWindow = [self visibleWindowWithTitle:@"Second"];

    [firstWindow makeMainWindow];

    [self assert:CPOnState equals:[[windowsMenu itemAtIndex:2] state]];
    [self assert:CPOffState equals:[[windowsMenu itemAtIndex:3] state]];

    [secondWindow makeMainWindow];

    [self assert:CPOffState equals:[[windowsMenu itemAtIndex:2] state]];
    [self assert:CPOnState equals:[[windowsMenu itemAtIndex:3] state]];
}

- (void)testClosingLastWindowRemovesItemAndSeparator
{
    var aWindow = [self visibleWindowWithTitle:@"Report"];

    [aWindow close];

    [self assert:1 equals:[windowsMenu numberOfItems]];
    [self assert:@"Minimize" equals:[[windowsMenu itemAtIndex:0] title]];
}

- (void)testClosingOneWindowKeepsSeparatorForOthers
{
    var firstWindow = [self visibleWindowWithTitle:@"First"];

    [self visibleWindowWithTitle:@"Second"];
    [firstWindow close];

    [self assert:3 equals:[windowsMenu numberOfItems]];
    [self assert:@"Second" equals:[[windowsMenu itemAtIndex:2] title]];
}

- (void)testFilenameItemShowsNameThenDirectory
{
    var aWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 200.0, 100.0) styleMask:CPTitledWindowMask];

    [app addWindowsItem:aWindow title:@"/Users/me/Report.txt" filename:YES];

    [self assert:@"Report.txt — /Users/me" equals:[[windowsMenu itemAtIndex:2] title]];
}

- (void)testAddingListedWindowAgainDoesNothing
{
    var aWindow = [self visibleWindowWithTitle:@"Report"];

    [app addWindowsItem:aWindow title:@"Other" filename:NO];

    [self assert:3 equals:[windowsMenu numberOfItems]];
    [self assert:@"Report" equals:[[windowsMenu itemAtIndex:2] title]];
}

- (void)testSetWindowsMenuMovesWindowItems
{
    var aWindow = [self visibleWindowWithTitle:@"Report"],
        otherMenu = [[CPMenu alloc] initWithTitle:@"Windows"];

    [app setWindowsMenu:otherMenu];

    [self assert:1 equals:[windowsMenu numberOfItems]];
    [self assert:1 equals:[otherMenu numberOfItems]];
    [self assert:aWindow equals:[[otherMenu itemAtIndex:0] target]];
}

@end
