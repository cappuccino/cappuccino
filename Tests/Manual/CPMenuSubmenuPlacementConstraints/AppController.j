/*
 * AppController.j
 * CPMenuTest
 *
 * Created by Daniel Boehringer 2025 for submenu constraints on the rightmost end of the screen.
 * Updated for Issue #3149 (Immediate menu updates).
 */


@import <AppKit/AppKit.j>

@implementation AppController : CPObject
{
    CPWindow    theWindow;
    BOOL        _isEnabled;

    // Ivars for Live Update Test
    CPMenuItem  _changeTitleItem;
    CPMenuItem  _changeStateItem;
    CPMenuItem  _changeEnabledItem;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

        mainMenu = [[CPMenu alloc] initWithTitle:@"MainMenu"],
        appMenu = [[CPMenu alloc] initWithTitle:@"App"],
        fileMenu = [[CPMenu alloc] initWithTitle:@"File"],
        bindingsMenu = [[CPMenu alloc] initWithTitle:@"Bindings Test"];

    _isEnabled = YES;

    [CPApp setMainMenu:mainMenu];

    [mainMenu addItemWithTitle:@"App" action:nil keyEquivalent:@""];
    [mainMenu setSubmenu:appMenu forItem:[mainMenu itemWithTitle:@"App"]];

    [appMenu addItemWithTitle:@"About" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    [appMenu addItem:[CPMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];

    [mainMenu addItemWithTitle:@"File" action:nil keyEquivalent:@""];
    [mainMenu setSubmenu:fileMenu forItem:[mainMenu itemWithTitle:@"File"]];

    [fileMenu addItemWithTitle:@"New" action:@selector(newDocument:) keyEquivalent:@"n"];
    [fileMenu addItemWithTitle:@"Open" action:@selector(openDocument:) keyEquivalent:@"o"];
    [fileMenu addItemWithTitle:@"Close" action:@selector(newDocument:) keyEquivalent:@"w"];

    // 1. Add some dummy menus to push the test menu further to the right.
    var dummyMenu1 = [[CPMenu alloc] initWithTitle:@"Dummy 1"],
        dummyMenu2 = [[CPMenu alloc] initWithTitle:@"Dummy 2"];

    [dummyMenu1 addItemWithTitle:@"Dummy Action A" action:nil keyEquivalent:@""];
    [dummyMenu1 addItemWithTitle:@"Dummy Action B" action:nil keyEquivalent:@""];

    [dummyMenu2 addItemWithTitle:@"Another Dummy Action" action:nil keyEquivalent:@""];

    var dummyMenuItem1 = [mainMenu addItemWithTitle:@"Dummy Menu 1" action:nil keyEquivalent:@""];
    [mainMenu setSubmenu:dummyMenu1 forItem:dummyMenuItem1];

    var dummyMenuItem2 = [mainMenu addItemWithTitle:@"Dummy Menu 2" action:nil keyEquivalent:@""];
    [mainMenu setSubmenu:dummyMenu2 forItem:dummyMenuItem2];

    // -------------------------------------------------------------------------
    // TEST ADDITION FOR ISSUE #3149: Immediate Updates
    // -------------------------------------------------------------------------
    var liveUpdateMenu = [[CPMenu alloc] initWithTitle:@"Live Update"],
        liveUpdateMenuItem = [mainMenu addItemWithTitle:@"Live Update" action:nil keyEquivalent:@""];
    
    // Disable auto-enable so we can manually test setEnabled: on items without actions
    [liveUpdateMenu setAutoenablesItems:NO];
    [mainMenu setSubmenu:liveUpdateMenu forItem:liveUpdateMenuItem];

    [liveUpdateMenu addItemWithTitle:@"1. Click 'Start Timer' below" action:nil keyEquivalent:@""];
    [liveUpdateMenu addItemWithTitle:@"2. Keep this menu OPEN" action:nil keyEquivalent:@""];
    [liveUpdateMenu addItem:[CPMenuItem separatorItem]];

    _changeTitleItem = [liveUpdateMenu addItemWithTitle:@"Title will change in 3s" action:nil keyEquivalent:@""];
    _changeStateItem = [liveUpdateMenu addItemWithTitle:@"State will change in 3s" action:nil keyEquivalent:@""];
    _changeEnabledItem = [liveUpdateMenu addItemWithTitle:@"Enabled will change in 3s" action:nil keyEquivalent:@""];
    
    [liveUpdateMenu addItem:[CPMenuItem separatorItem]];
    [liveUpdateMenu addItemWithTitle:@"Start 3s Timer" action:@selector(startUpdateTimer:) keyEquivalent:@""];
    // -------------------------------------------------------------------------


    // 2. Create the right-most menu with submenus for testing.
    var rightTestMenu = [[CPMenu alloc] initWithTitle:@"Right-Side Test"],
        rightTestMenuItem = [mainMenu addItemWithTitle:@"Right-Side Test" action:nil keyEquivalent:@""];
    
    [mainMenu setSubmenu:rightTestMenu forItem:rightTestMenuItem];

    // Add some simple items
    [rightTestMenu addItemWithTitle:@"Simple Item (No Submenu)" action:nil keyEquivalent:@""];
    [rightTestMenu addItem:[CPMenuItem separatorItem]];

    // Create the first level submenu
    var submenu1 = [[CPMenu alloc] initWithTitle:@"Submenu 1"],
        submenu1Item = [rightTestMenu addItemWithTitle:@"Test First Submenu" action:nil keyEquivalent:@""];
    
    [submenu1 addItemWithTitle:@"Sub-item A" action:nil keyEquivalent:@""];
    [submenu1 addItemWithTitle:@"Sub-item B" action:nil keyEquivalent:@""];
    [rightTestMenu setSubmenu:submenu1 forItem:submenu1Item];

    // Create a nested submenu for deeper testing
    var submenu2 = [[CPMenu alloc] initWithTitle:@"Submenu 2"],
        submenu2Item = [rightTestMenu addItemWithTitle:@"Test Nested Submenu" action:nil keyEquivalent:@""],
        deeperSubmenu = [[CPMenu alloc] initWithTitle:@"Deeper"],
        deeperSubmenuItem = [submenu2 addItemWithTitle:@"Deeper Submenu..." action:nil keyEquivalent:@""];
    
    [submenu2 addItemWithTitle:@"Another Sub-item" action:nil keyEquivalent:@""];
    [deeperSubmenu addItemWithTitle:@"Deep Item X" action:nil keyEquivalent:@""];
    [deeperSubmenu addItemWithTitle:@"Deep Item Y" action:nil keyEquivalent:@""];

    [submenu2 setSubmenu:deeperSubmenu forItem:deeperSubmenuItem];
    [rightTestMenu setSubmenu:submenu2 forItem:submenu2Item];

    [CPMenu setMenuBarVisible:YES];
}

- (void)toggleEnabled:(id)sender
{
    _isEnabled = !_isEnabled;
    [self didChangeValueForKey:@"isEnabled"];
}

- (BOOL)validateMenuItem:(CPMenuItem)anItem
{
    if ([anItem action] == @selector(toggleEnabled:))
        return _isEnabled;

    return YES;
}

// -------------------------------------------------------------------------
// Live Update Test Actions
// -------------------------------------------------------------------------

- (void)startUpdateTimer:(id)sender
{
    // Reset state
    [_changeTitleItem setTitle:@"Title will change in 3s"];
    [_changeStateItem setState:CPOffState];
    [_changeStateItem setTitle:@"State will change in 3s"];
    [_changeEnabledItem setEnabled:YES];
    [_changeEnabledItem setTitle:@"Enabled will change in 3s"];

    // Trigger update
    [self performSelector:@selector(performLiveUpdate) withObject:nil afterDelay:3.0];
}

- (void)performLiveUpdate
{
    [_changeTitleItem setTitle:@"Title Changed!"];
    
    [_changeStateItem setState:CPOnState];
    [_changeStateItem setTitle:@"State Changed! (Checked)"];
    
    [_changeEnabledItem setEnabled:NO];
    [_changeEnabledItem setTitle:@"Enabled Changed! (Disabled)"];
}

@end
