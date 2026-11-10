/*
 *  CPWindowAppearanceTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-10.
 *  Copyright David Richardson 2026.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <AppKit/AppKit.j>
@import <AppKit/_CPCibWindowTemplate.j>
@import <AppKit/_CPMenuWindow.j>
@import <AppKit/_CPToolTip.j>

@import "BuiltThemes.j"

@implementation CPWindowAppearanceTestView : CPView
{
    int     hookCount;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
        hookCount = 0;

    return self;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
        hookCount = 0;

    return self;
}

- (void)viewDidChangeEffectiveAppearance
{
    hookCount++;
}

@end

@implementation CPWindowAppearanceTest : OJTestCase

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];
}

- (void)tearDown
{
    [CPApp setAppearance:nil];
}

- (CPAppearance)appearance:(CPString)aName
{
    return [CPAppearance appearanceNamed:aName];
}

- (CPWindow)window
{
    return [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 300.0, 200.0) styleMask:CPTitledWindowMask];
}

/*
    Returns YES when aView holds the state of anAppearance and no other appearance state.
*/
- (BOOL)view:(CPView)aView holdsOnlyTheStateOf:(CPAppearance)anAppearance
{
    var state = _CPThemeStateForAppearanceName([anAppearance name]);

    return [aView hasThemeState:state] && String([aView themeState].without(state)).indexOf("appearance-") === -1;
}

- (void)testAWindowWithoutAnAppearanceTakesTheApplicationAppearance
{
    var window = [self window];

    [self assertNull:[window appearance]];
    [self assert:[CPApp effectiveAppearance] same:[window effectiveAppearance]];

    [CPApp setAppearance:[self appearance:CPAppearanceNameDarkAqua]];

    [self assert:[self appearance:CPAppearanceNameDarkAqua] same:[window effectiveAppearance]];
    [self assertTrue:[self view:[window contentView] holdsOnlyTheStateOf:[self appearance:CPAppearanceNameDarkAqua]]];
}

/*
    A unit test has no DOM, so CPWindow init makes the window share chrome with its platform
    window, and such a window has no shadow view. The test gives the window its browser state.
    Only a theme without CSS gives a window a shadow view, and the tests run under Aristo3, a
    CSS theme. The window is made under Aristo2.
*/
- (void)testAWindowAppearanceReachesItsRootViews
{
    var defaultTheme = [CPTheme defaultTheme],
        aristo2 = BuiltThemeNamed(@"Aristo2");

    [self assertNotNull:aristo2 message:@"Aristo2 was not found in the built blends. Build the themes first."];
    [CPTheme setDefaultTheme:aristo2];

    try
    {
        var window = [self window],
            vibrantDark = [self appearance:CPAppearanceNameVibrantDark];

        [window _setSharesChromeWithPlatformWindow:NO];
        [self assertNotNull:window._shadowView message:@"A window under Aristo2 has a shadow view"];

        [window setAppearance:vibrantDark];

        [self assert:vibrantDark same:[window effectiveAppearance]];

        var views = [[window _windowView], [window contentView], window._shadowView];

        for (var i = 0; i < views.length; i++)
        {
            [self assert:vibrantDark same:[views[i] effectiveAppearance] message:[views[i] className] + @" takes the window's appearance"];
            [self assertTrue:[self view:views[i] holdsOnlyTheStateOf:vibrantDark] message:[views[i] className] + @" holds the window's state"];
        }
    }
    finally
    {
        [CPTheme setDefaultTheme:defaultTheme];
    }
}

- (void)testAViewWithItsOwnAppearanceKeepsItWhenTheWindowAppearanceChanges
{
    var window = [self window],
        view = [[CPWindowAppearanceTestView alloc] initWithFrame:CGRectMake(0.0, 0.0, 50.0, 50.0)],
        subview = [[CPWindowAppearanceTestView alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 10.0)],
        vibrantLight = [self appearance:CPAppearanceNameVibrantLight];

    [view setAppearance:vibrantLight];
    [view addSubview:subview];
    [[window contentView] addSubview:view];

    view.hookCount = 0;
    subview.hookCount = 0;

    [window setAppearance:[self appearance:CPAppearanceNameDarkAqua]];

    [self assert:vibrantLight same:[view effectiveAppearance]];
    [self assert:vibrantLight same:[subview effectiveAppearance]];
    [self assertTrue:[self view:subview holdsOnlyTheStateOf:vibrantLight]];
    [self assert:0 equals:view.hookCount];
    [self assert:0 equals:subview.hookCount];
}

/*
    The test runs the steps of -[CPApplication beginSheet:modalForWindow:modalDelegate:
    didEndSelector:contextInfo:] and of the end of the sheet without their timers.

    The first version of this test called -_attachSheet:modalDelegate:didEndSelector:
    contextInfo:, which schedules a timer, and left the frame animation running on a timer.
    Both fired after the test, found no sheet context and raised. -[CPRunLoop
    limitDateForMode:] has no finally, so the exception left the run loop locked, and later
    tests that use the run loop failed.
*/
- (void)testASheetTakesItsParentAppearanceWhileAttached
{
    var parent = [self window],
        sheet = [self window],
        darkAqua = [self appearance:CPAppearanceNameDarkAqua];

    [parent setAppearance:darkAqua];

    // The context that -_attachSheet:modalDelegate:didEndSelector:contextInfo: makes.
    [sheet._windowView _enableSheet:YES inWindow:parent];
    parent._sheetContext = {
        "sheet": sheet,
        "modalDelegate": nil,
        "endSelector": nil,
        "contextInfo": nil,
        "returnCode": -1,
        "opened": NO,
        "isAttached": YES,
        "savedConstrains": sheet._constrainsToUsableScreen
    };
    sheet._constrainsToUsableScreen = NO;

    [parent _sheetShouldAnimateIn:nil];
    [sheet._frameAnimation stopAnimation];

    [self assert:darkAqua same:[sheet effectiveAppearance]];
    [self assertTrue:[self view:[sheet contentView] holdsOnlyTheStateOf:darkAqua]];

    [parent setAppearance:[self appearance:CPAppearanceNameVibrantDark]];
    [self assert:[self appearance:CPAppearanceNameVibrantDark] same:[sheet effectiveAppearance]];
    [self assertTrue:[self view:[sheet contentView] holdsOnlyTheStateOf:[self appearance:CPAppearanceNameVibrantDark]]];

    [parent _cleanupSheetWindow];

    [self assert:[CPApp effectiveAppearance] same:[sheet effectiveAppearance]];
    [self assertTrue:[self view:[sheet contentView] holdsOnlyTheStateOf:[CPApp effectiveAppearance]]];
}

- (void)testAChildWindowTakesItsParentAppearance
{
    var parent = [self window],
        child = [self window],
        darkAqua = [self appearance:CPAppearanceNameDarkAqua];

    [parent setAppearance:darkAqua];
    [parent addChildWindow:child ordered:CPWindowAbove];

    [self assert:darkAqua same:[child effectiveAppearance]];
    [self assertTrue:[self view:[child contentView] holdsOnlyTheStateOf:darkAqua]];

    [parent removeChildWindow:child];

    [self assert:[CPApp effectiveAppearance] same:[child effectiveAppearance]];
    [self assertTrue:[self view:[child contentView] holdsOnlyTheStateOf:[CPApp effectiveAppearance]]];
}

/*
    -showToolTip reads the position of the current event, which a unit test lacks. The test
    runs its last step, which attaches the tool tip to its owner window as a child window.
*/
- (void)testAToolTipTakesTheAppearanceOfItsOwnerWindow
{
    var owner = [self window],
        darkAqua = [self appearance:CPAppearanceNameDarkAqua],
        toolTip = [[_CPToolTip alloc] initWithString:@"Tip" styleMask:_CPToolTipWindowMask toolTipWindow:owner];

    [owner setAppearance:darkAqua];
    [owner addChildWindow:toolTip ordered:CPWindowAbove];

    [self assert:darkAqua same:[toolTip effectiveAppearance]];
    [self assertTrue:[self view:toolTip._content holdsOnlyTheStateOf:darkAqua]];
}

- (void)testAMenuWindowFollowsTheApplication
{
    var menu = [[CPMenu alloc] initWithTitle:@"Menu"],
        visibleItem = [[CPMenuItem alloc] initWithTitle:@"Visible" action:nil keyEquivalent:@""],
        hiddenItem = [[CPMenuItem alloc] initWithTitle:@"Hidden" action:nil keyEquivalent:@""],
        darkAqua = [self appearance:CPAppearanceNameDarkAqua];

    [hiddenItem setHidden:YES];
    [menu addItem:visibleItem];
    [menu addItem:hiddenItem];

    /*
        The menu window is made directly, not taken from the pool: a pooled window can come
        from an earlier test, whose application no longer exists.
    */
    var menuWindow = [[_CPMenuWindow alloc] init];

    [menuWindow setFont:[CPFont systemFontOfSize:12.0]];
    [menuWindow setMenu:menu];

    [CPApp setAppearance:darkAqua];

    var hiddenItemView = [hiddenItem _menuItemView];

    [self assert:darkAqua same:[menuWindow effectiveAppearance]];
    [self assertTrue:[self view:[menuWindow _menuView] holdsOnlyTheStateOf:darkAqua]];
    [self assertTrue:[self view:[visibleItem _menuItemView] holdsOnlyTheStateOf:darkAqua]];

    [self assertNull:[hiddenItemView superview]];
    [self assert:darkAqua same:[hiddenItemView effectiveAppearance]];
    [self assertTrue:[self view:hiddenItemView holdsOnlyTheStateOf:darkAqua]];
}

- (void)testAWindowFromACibTemplateTakesTheTemplateAppearance
{
    var template = [[_CPCibWindowTemplate alloc] init],
        darkAqua = [self appearance:CPAppearanceNameDarkAqua];

    // -init leaves the screen rectangle unset, and the encoder needs it. nib2cib sets it.
    template._screenRect = CGRectMake(0.0, 0.0, 1024.0, 768.0);

    var archive = [[CPKeyedArchiver archivedDataWithRootObject:template] rawString];

    [self assertTrue:archive.indexOf(@"_CPCibWindowTemplateWindowAppearanceKey") === -1 message:@"A template without an appearance encodes no appearance key"];

    template._windowAppearance = darkAqua;

    var decodedTemplate = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:template]],
        window = [decodedTemplate _cibInstantiate];

    [self assert:darkAqua same:[window appearance]];
    [self assert:darkAqua same:[window effectiveAppearance]];
    [self assertTrue:[self view:[window contentView] holdsOnlyTheStateOf:darkAqua]];
}

- (void)testACibTemplateAppearanceCallsTheHookOncePerView
{
    var template = [[_CPCibWindowTemplate alloc] init],
        contentView = [[CPWindowAppearanceTestView alloc] initWithFrame:CGRectMake(0.0, 0.0, 400.0, 200.0)],
        subview = [[CPWindowAppearanceTestView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 20.0)];

    [contentView addSubview:subview];
    contentView.hookCount = 0;
    subview.hookCount = 0;

    template._windowView = contentView;
    template._windowAppearance = [self appearance:CPAppearanceNameDarkAqua];

    [self assert:CPAppearanceNameAqua equals:[[CPApp effectiveAppearance] name]];

    var window = [template _cibInstantiate];

    [self assert:contentView same:[window contentView]];
    [self assert:1 equals:contentView.hookCount];
    [self assert:1 equals:subview.hookCount];
}

@end
