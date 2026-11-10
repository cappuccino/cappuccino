/*
 * AppController.j
 * CPAppearanceTest
 *
 * Created by David Richardson on 2026-11-10.
 * Copyright David Richardson 2026.
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

/*
    Shows the effective appearance in the DOM, which the unit tests do not see. Each probe row
    holds four views that use the asset catalog colour Probe and the catalog image Mark:
    a background colour, a text colour, a fill in drawRect: and an image view. No theme has
    dark values yet, so the catalog gives the visible difference:

    - light: orange;
    - dark: purple;
    - light, high contrast: red;
    - dark, high contrast: cyan.

    Build with "npx jake debug" and open Build/Debug/CPAppearanceTest/index.html by file://.
    The asset catalog is compiled only by the build.
*/

@import <Foundation/CPObject.j>
@import <AppKit/AppKit.j>

var AppearanceNames = [
        CPAppearanceNameAqua,
        CPAppearanceNameDarkAqua,
        CPAppearanceNameLightContent,
        CPAppearanceNameVibrantLight,
        CPAppearanceNameVibrantDark,
        CPAppearanceNameAccessibilityHighContrastAqua,
        CPAppearanceNameAccessibilityHighContrastDarkAqua,
        CPAppearanceNameAccessibilityHighContrastVibrantLight,
        CPAppearanceNameAccessibilityHighContrastVibrantDark
    ],
    AppearanceNamePrefix = @"CPAppearanceName";

function ShortAppearanceName(anAppearance)
{
    return anAppearance ? [[anAppearance name] substringFromIndex:AppearanceNamePrefix.length] : @"nil";
}

/*
    Fills its bounds with the catalog colour in drawRect:.
*/
@implementation ProbeDrawingView : CPView

- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSetFillColor(context, [CPColor colorNamed:@"Probe"]);
    CGContextFillRect(context, [self bounds]);
}

@end

@implementation AppController : CPObject
{
    CPWindow        mainWindow;
    CPView          subjectView;
    CPTextField     statusLabel;

    CPWindow        sheet;
    CPWindow        childWindow;
    CPPopover       minimalPopover;
    CPPopover       hudPopover;
    CPMenu          probeMenu;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    mainWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(40.0, 40.0, 860.0, 560.0) styleMask:CPTitledWindowMask];
    [mainWindow setTitle:@"Appearance"];

    var contentView = [mainWindow contentView],
        instructions = [CPTextField labelWithTitle:@"Probes: background, text colour, drawRect: fill, image. Light orange, dark purple, high contrast red (light) or cyan (dark)."];

    [instructions setFrameOrigin:CGPointMake(20.0, 16.0)];
    [contentView addSubview:instructions];

    [self addAppearancePopUpTitled:@"Application" atX:20.0 action:@selector(setApplicationAppearance:)];
    [self addAppearancePopUpTitled:@"Window" atX:300.0 action:@selector(setWindowAppearance:)];
    [self addAppearancePopUpTitled:@"View" atX:580.0 action:@selector(setViewAppearance:)];

    statusLabel = [CPTextField labelWithTitle:@""];
    [statusLabel setFrame:CGRectMake(20.0, 100.0, 820.0, 20.0)];
    [contentView addSubview:statusLabel];

    var subjectCaption = [CPTextField labelWithTitle:@"This row follows the View setting:"];

    [subjectCaption setFrameOrigin:CGPointMake(20.0, 136.0)];
    [contentView addSubview:subjectCaption];

    subjectView = [self probeRowWithFrame:CGRectMake(20.0, 160.0, 820.0, 100.0)];
    [contentView addSubview:subjectView];

    var windowCaption = [CPTextField labelWithTitle:@"This row follows the window:"];

    [windowCaption setFrameOrigin:CGPointMake(20.0, 276.0)];
    [contentView addSubview:windowCaption];
    [contentView addSubview:[self probeRowWithFrame:CGRectMake(20.0, 300.0, 820.0, 100.0)]];

    [self addButtonTitled:@"Sheet" atX:20.0 action:@selector(showSheet:)];
    [self addButtonTitled:@"Child Window" atX:180.0 action:@selector(toggleChildWindow:)];
    [self addButtonTitled:@"Popover (Minimal)" atX:340.0 action:@selector(showMinimalPopover:)];
    [self addButtonTitled:@"Popover (HUD)" atX:500.0 action:@selector(showHUDPopover:)];
    [self addButtonTitled:@"Menu" atX:660.0 action:@selector(showMenu:)];

    [CPApp addObserver:self forKeyPath:@"effectiveAppearance" options:0 context:nil];
    [mainWindow addObserver:self forKeyPath:@"effectiveAppearance" options:0 context:nil];
    [subjectView addObserver:self forKeyPath:@"effectiveAppearance" options:0 context:nil];
    [self updateStatus];

    [mainWindow orderFront:self];
}

// MARK: Building

/*
    Returns a row of the four probe views. The background view also has a tool tip, which
    takes the appearance of its window.
*/
- (CPView)probeRowWithFrame:(CGRect)aFrame
{
    var row = [[CPView alloc] initWithFrame:aFrame],
        probeColor = [CPColor colorNamed:@"Probe"],
        width = 180.0,
        spacing = (CGRectGetWidth(aFrame) - 4 * width) / 3,
        height = CGRectGetHeight(aFrame);

    var backgroundView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, height)];

    [backgroundView setBackgroundColor:probeColor];
    [backgroundView setToolTip:@"A tool tip follows its window"];
    [row addSubview:backgroundView];

    var textField = [CPTextField labelWithTitle:@"Text colour"];

    [textField setFont:[CPFont boldSystemFontOfSize:22.0]];
    [textField setTextColor:probeColor];
    [textField setFrame:CGRectMake(width + spacing, (height - 30.0) / 2, width, 30.0)];
    [row addSubview:textField];

    [row addSubview:[[ProbeDrawingView alloc] initWithFrame:CGRectMake(2 * (width + spacing), 0.0, width, height)]];

    var imageView = [[CPImageView alloc] initWithFrame:CGRectMake(3 * (width + spacing), 0.0, width, height)];

    [imageView setImageScaling:CPImageScaleNone];
    [imageView setImage:[CPImage imageNamed:@"Mark"]];
    [row addSubview:imageView];

    return row;
}

- (void)addAppearancePopUpTitled:(CPString)aTitle atX:(float)x action:(SEL)anAction
{
    var contentView = [mainWindow contentView],
        label = [CPTextField labelWithTitle:aTitle + @":"],
        popUp = [[CPPopUpButton alloc] initWithFrame:CGRectMake(x + 90.0, 56.0, 170.0, 26.0) pullsDown:NO];

    [label setFrameOrigin:CGPointMake(x, 60.0)];
    [contentView addSubview:label];

    [popUp addItemWithTitle:@"nil"];

    for (var i = 0; i < AppearanceNames.length; i++)
    {
        [popUp addItemWithTitle:[AppearanceNames[i] substringFromIndex:AppearanceNamePrefix.length]];
        [[popUp lastItem] setRepresentedObject:AppearanceNames[i]];
    }

    [popUp setTarget:self];
    [popUp setAction:anAction];
    [contentView addSubview:popUp];
}

- (void)addButtonTitled:(CPString)aTitle atX:(float)x action:(SEL)anAction
{
    var button = [CPButton buttonWithTitle:aTitle];

    [button setFrameOrigin:CGPointMake(x, 430.0)];
    [button setTarget:self];
    [button setAction:anAction];
    [[mainWindow contentView] addSubview:button];
}

- (CPWindow)probeWindowWithTitle:(CPString)aTitle
{
    var window = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 860.0, 170.0) styleMask:CPTitledWindowMask];

    [window setTitle:aTitle];
    [[window contentView] addSubview:[self probeRowWithFrame:CGRectMake(20.0, 20.0, 820.0, 100.0)]];

    return window;
}

- (CPPopover)popoverWithAppearance:(id)anAppearance
{
    var popover = [[CPPopover alloc] init],
        controller = [[CPViewController alloc] init];

    [controller setView:[self probeRowWithFrame:CGRectMake(0.0, 0.0, 820.0, 100.0)]];
    [popover setContentViewController:controller];
    [popover setBehavior:CPPopoverBehaviorTransient];
    [popover setAppearance:anAppearance];

    return popover;
}

// MARK: Actions

- (CPAppearance)appearanceOfPopUp:(CPPopUpButton)aPopUp
{
    var name = [[aPopUp selectedItem] representedObject];

    return name ? [CPAppearance appearanceNamed:name] : nil;
}

- (void)setApplicationAppearance:(id)sender
{
    [CPApp setAppearance:[self appearanceOfPopUp:sender]];
}

- (void)setWindowAppearance:(id)sender
{
    [mainWindow setAppearance:[self appearanceOfPopUp:sender]];
}

- (void)setViewAppearance:(id)sender
{
    [subjectView setAppearance:[self appearanceOfPopUp:sender]];
}

- (void)showSheet:(id)sender
{
    if (!sheet)
    {
        sheet = [self probeWindowWithTitle:@"Sheet"];

        var closeButton = [CPButton buttonWithTitle:@"Close"];

        [closeButton setFrameOrigin:CGPointMake(20.0, 132.0)];
        [closeButton setTarget:self];
        [closeButton setAction:@selector(closeSheet:)];
        [[sheet contentView] addSubview:closeButton];
    }

    [CPApp beginSheet:sheet modalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (void)closeSheet:(id)sender
{
    [CPApp endSheet:sheet returnCode:0];
    [sheet orderOut:self];
}

- (void)toggleChildWindow:(id)sender
{
    if (!childWindow)
    {
        childWindow = [self probeWindowWithTitle:@"Child Window"];
        [childWindow setFrameOrigin:CGPointMake(80.0, 640.0)];
    }

    if ([[mainWindow childWindows] containsObject:childWindow])
    {
        [mainWindow removeChildWindow:childWindow];
        [childWindow orderOut:self];
    }
    else
    {
        [mainWindow addChildWindow:childWindow ordered:CPWindowAbove];
        [childWindow orderFront:self];
    }
}

- (void)showMinimalPopover:(id)sender
{
    if (!minimalPopover)
        minimalPopover = [self popoverWithAppearance:CPPopoverAppearanceMinimal];

    [minimalPopover showRelativeToRect:nil ofView:sender preferredEdge:CPMaxYEdge];
}

- (void)showHUDPopover:(id)sender
{
    if (!hudPopover)
        hudPopover = [self popoverWithAppearance:CPPopoverAppearanceHUD];

    [hudPopover showRelativeToRect:nil ofView:sender preferredEdge:CPMaxYEdge];
}

/*
    The menu follows the application. Its first item shows the catalog image.
*/
- (void)showMenu:(id)sender
{
    if (!probeMenu)
    {
        probeMenu = [[CPMenu alloc] initWithTitle:@"Probe"];

        var imageItem = [[CPMenuItem alloc] initWithTitle:@"Catalog image" action:nil keyEquivalent:@""];

        [imageItem setImage:[CPImage imageNamed:@"Mark"]];
        [probeMenu addItem:imageItem];
        [probeMenu addItem:[[CPMenuItem alloc] initWithTitle:@"Plain item" action:nil keyEquivalent:@""]];
    }

    [CPMenu popUpContextMenu:probeMenu withEvent:[CPApp currentEvent] forView:sender];
}

// MARK: Status

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)aChange context:(id)aContext
{
    [self updateStatus];
}

- (void)updateStatus
{
    [statusLabel setStringValue:[CPString stringWithFormat:@"System: %@    Application: %@    Window: %@    View: %@",
                                 ShortAppearanceName([[_CPAppearanceManager sharedManager] systemAppearance]),
                                 ShortAppearanceName([CPApp effectiveAppearance]),
                                 ShortAppearanceName([mainWindow effectiveAppearance]),
                                 ShortAppearanceName([subjectView effectiveAppearance])]];
}

@end
