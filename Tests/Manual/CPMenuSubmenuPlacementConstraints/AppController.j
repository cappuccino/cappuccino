/*
 * AppController.j
 * CPMenuTest
 *
 * Created by Daniel Boehringer 2025 for submenu constraints on the rightmost end of the screen.
 * Updated for Issue #3149 (Immediate menu updates).
 * Updated for Issue #3153 (Hide main menu items without submenus).
 */


@import <AppKit/AppKit.j>

@implementation AppController : CPObject
{
    CPWindow    theWindow;
    BOOL        _isEnabled;

    // Ivars for Live Update Test (#3149)
    CPMenuItem  _changeTitleItem;
    CPMenuItem  _changeStateItem;
    CPMenuItem  _changeEnabledItem;

    // Ivars for Hidden Menu Test (#3153)
    CPMenuItem  _ghostMenuItem;
    CPMenu      _ghostMenu;
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
        fileMenu = [[CPMenu alloc] initWithTitle:@"File"];

    _isEnabled = YES;

    [CPApp setMainMenu:mainMenu];

    // Standard App Menu
    [mainMenu addItemWithTitle:@"App" action:nil keyEquivalent:@""];
    [mainMenu setSubmenu:appMenu forItem:[mainMenu itemWithTitle:@"App"]];

    [appMenu addItemWithTitle:@"About" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    [appMenu addItem:[CPMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];

    // Standard File Menu
    [mainMenu addItemWithTitle:@"File" action:nil keyEquivalent:@""];
    [mainMenu setSubmenu:fileMenu forItem:[mainMenu itemWithTitle:@"File"]];

    [fileMenu addItemWithTitle:@"New" action:@selector(newDocument:) keyEquivalent:@"n"];
    [fileMenu addItemWithTitle:@"Open" action:@selector(openDocument:) keyEquivalent:@"o"];
    [fileMenu addItemWithTitle:@"Close" action:@selector(newDocument:) keyEquivalent:@"w"];

    // -------------------------------------------------------------------------
    // TEST ADDITION FOR ISSUE #3149: Immediate Updates
    // -------------------------------------------------------------------------
    var liveUpdateMenu = [[CPMenu alloc] initWithTitle:@"Live Update"],
        liveUpdateMenuItem = [mainMenu addItemWithTitle:@"Live Update" action:nil keyEquivalent:@""];
    
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
    // TEST ADDITION FOR ISSUE #3153: Hide main menu items with no submenus
    // -------------------------------------------------------------------------
    
    // 1. Create a "Ghost" item in the main menu bar.
    // We intentionally DO NOT set a submenu for it yet.
    // EXPECTATION: "Ghost Item" should NOT be visible in the menu bar.
    _ghostMenuItem = [mainMenu addItemWithTitle:@"Ghost Item" action:nil keyEquivalent:@""];
    
    // Prepare the menu that we will attach later
    _ghostMenu = [[CPMenu alloc] initWithTitle:@"Ghost Menu"];
    [_ghostMenu addItemWithTitle:@"I was hidden!" action:nil keyEquivalent:@""];

    // 2. Create a control menu to toggle the submenu
    var visibilityMenu = [[CPMenu alloc] initWithTitle:@"Visibility Test"],
        visibilityMenuItem = [mainMenu addItemWithTitle:@"Visibility Test" action:nil keyEquivalent:@""];
    
    [mainMenu setSubmenu:visibilityMenu forItem:visibilityMenuItem];
    [visibilityMenu addItemWithTitle:@"Toggle 'Ghost Item' Submenu" action:@selector(toggleGhost:) keyEquivalent:@""];
    [visibilityMenu addItemWithTitle:@"(If 'Ghost Item' is visible in bar now, bug is present)" action:nil keyEquivalent:@""];


    // -------------------------------------------------------------------------
    // Layout Testing (Right-side constraints)
    // -------------------------------------------------------------------------
    
    // Add some dummy menus to push the test menu further to the right.
    var dummyMenu1 = [[CPMenu alloc] initWithTitle:@"Dummy 1"];
    [dummyMenu1 addItemWithTitle:@"Dummy Action A" action:nil keyEquivalent:@""];
    
    var dummyMenuItem1 = [mainMenu addItemWithTitle:@"Dummy 1" action:nil keyEquivalent:@""];
    [mainMenu setSubmenu:dummyMenu1 forItem:dummyMenuItem1];
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


    // Create the right-most menu with submenus for testing layout.
    var rightTestMenu = [[CPMenu alloc] initWithTitle:@"Right-Side Test"],
        rightTestMenuItem = [mainMenu addItemWithTitle:@"Right-Side Test" action:nil keyEquivalent:@""];
    
    [mainMenu setSubmenu:rightTestMenu forItem:rightTestMenuItem];

    [rightTestMenu addItemWithTitle:@"Simple Item" action:nil keyEquivalent:@""];
    [rightTestMenu addItem:[CPMenuItem separatorItem]];

    var submenu1 = [[CPMenu alloc] initWithTitle:@"Submenu 1"],
        submenu1Item = [rightTestMenu addItemWithTitle:@"Test First Submenu" action:nil keyEquivalent:@""];
    
    [submenu1 addItemWithTitle:@"Sub-item A" action:nil keyEquivalent:@""];
    [rightTestMenu setSubmenu:submenu1 forItem:submenu1Item];

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
// Live Update Test Actions (#3149)
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

// -------------------------------------------------------------------------
// Visibility Test Actions (#3153)
// -------------------------------------------------------------------------

- (void)toggleGhost:(id)sender
{
    if ([_ghostMenuItem submenu])
    {
        // Remove submenu -> Item should disappear from the bar
        [mainMenu setSubmenu:nil forItem:_ghostMenuItem];
    }
    else
    {
        // Add submenu -> Item should appear in the bar
        [mainMenu setSubmenu:_ghostMenu forItem:_ghostMenuItem];
    }
}

@end
