/*
 *  CPWindowViewCornerTest.j
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

@import "BuiltThemes.j"

@implementation CPWindowViewCornerTest : OJTestCase

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];
}

- (CPWindow)window
{
    return [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 300.0, 200.0) styleMask:CPTitledWindowMask];
}

- (void)testAnInnerCornerHasTheOuterRadiusLessEachInset
{
    [self assert:@"max(0px, 7px - 1px) max(0px, 7px - 2px)" equals:_CPWindowViewInnerCornerRadius(@"7px", 1, 2)];
}

- (void)testAnEmptyOuterRadiusGivesNoInnerRadius
{
    [self assert:@"" equals:_CPWindowViewInnerCornerRadius(@"", 1, 1)];
    [self assert:@"" equals:_CPWindowViewInnerCornerRadius(nil, 1, 1)];
}

- (void)testAFrameBorderCornerHasTheOuterRadiusPlusTheWidth
{
    [self assert:@"calc(7px + 1px)" equals:_CPWindowViewFrameBorderRadius(@"7px", 1)];
    [self assert:@"calc(0px + 1px)" equals:_CPWindowViewFrameBorderRadius(@"", 1)];
}

- (void)testAnEllipticalCornerTakesEachComponentApart
{
    [self assert:@"max(0px, 2px - 1px) max(0px, 4px - 3px)" equals:_CPWindowViewInnerCornerRadius(@"2px 4px", 1, 3)];
    [self assert:@"calc(2px + 1px) calc(4px + 1px)" equals:_CPWindowViewFrameBorderRadius(@"2px 4px", 1)];
}

- (void)assertCorners:(CPArray)expected ofRadii:(JSObject)someRadii message:(CPString)aMessage
{
    [self assertNotNull:someRadii message:aMessage];
    [self assert:expected[0] equals:someRadii.topLeft message:aMessage + @", top left"];
    [self assert:expected[1] equals:someRadii.topRight message:aMessage + @", top right"];
    [self assert:expected[2] equals:someRadii.bottomLeft message:aMessage + @", bottom left"];
    [self assert:expected[3] equals:someRadii.bottomRight message:aMessage + @", bottom right"];
}

/*
    One to four values give the corners top left, top right, bottom right and bottom left, as
    CSS expands them. The values after a slash are the vertical radii.
*/
- (void)testTheBorderRadiusShorthandGivesEachCornerAsCSSExpandsIt
{
    [self assertCorners:[@"6px", @"6px", @"6px", @"6px"] ofRadii:_CPWindowViewCornerRadiiOfShorthand(@"6px") message:@"one value"];
    [self assertCorners:[@"1px", @"2px", @"2px", @"1px"] ofRadii:_CPWindowViewCornerRadiiOfShorthand(@"1px 2px") message:@"two values"];
    [self assertCorners:[@"1px", @"2px", @"2px", @"3px"] ofRadii:_CPWindowViewCornerRadiiOfShorthand(@"1px 2px 3px") message:@"three values"];
    [self assertCorners:[@"1px", @"2px", @"4px", @"3px"] ofRadii:_CPWindowViewCornerRadiiOfShorthand(@"1px 2px 3px 4px") message:@"four values"];
    [self assertCorners:[@"2px 4px", @"2px 4px", @"2px 4px", @"2px 4px"] ofRadii:_CPWindowViewCornerRadiiOfShorthand(@"2px / 4px") message:@"a slash"];
    [self assertCorners:[@"calc(1px + 2px)", @"calc(1px + 2px)", @"calc(1px + 2px)", @"calc(1px + 2px)"] ofRadii:_CPWindowViewCornerRadiiOfShorthand(@"calc(1px + 2px)") message:@"a value with spaces"];
    [self assertNull:_CPWindowViewCornerRadiiOfShorthand(@"1px 2px 3px 4px 5px") message:@"five values"];
}

- (void)testASheetTakesTheFrameShapeOfADocumentModalWindow
{
    var parent = [self window],
        sheet = [self window],
        windowView = [sheet _windowView];

    [self assert:[windowView class] same:[windowView _frameClass] message:@"A window takes the frame shape of its own window view class"];

    [windowView _enableSheet:YES inWindow:parent];

    [self assert:_CPDocModalWindowView same:[windowView _frameClass] message:@"A sheet takes the frame shape of a document-modal window"];

    [windowView _enableSheet:NO inWindow:parent];

    [self assert:[windowView class] same:[windowView _frameClass] message:@"A former sheet takes its own frame shape again"];
}

/*
    The subview frame has the insets left 1, top 30, right 2 and bottom 4. Each corner of the
    subview takes the insets of its own two sides.
*/
- (void)testEachSubviewCornerTakesTheInsetsOfItsOwnSides
{
    var windowView = [[self window] _windowView],
        bounds = [windowView bounds],
        frame = CGRectMake(1.0, 30.0, CGRectGetWidth(bounds) - 3.0, CGRectGetHeight(bounds) - 34.0),
        radii = [windowView _cornerRadii],
        subviewRadii = [windowView _cornerRadiiForSubviewFrame:frame];

    [self assert:_CPWindowViewInnerCornerRadius(radii.topLeft, 1, 30) equals:subviewRadii.topLeft];
    [self assert:_CPWindowViewInnerCornerRadius(radii.topRight, 2, 30) equals:subviewRadii.topRight];
    [self assert:_CPWindowViewInnerCornerRadius(radii.bottomLeft, 1, 4) equals:subviewRadii.bottomLeft];
    [self assert:_CPWindowViewInnerCornerRadius(radii.bottomRight, 2, 4) equals:subviewRadii.bottomRight];
}

- (void)testTheWindowViewRoundsTheCornersOfTheCurrentContentView
{
    var window = [self window],
        windowView = [window _windowView],
        contentView = [window contentView],
        otherView = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [windowView layoutIfNeeded];

    [self assert:contentView same:windowView._cornerClippedView message:@"The first layout rounds the content view"];

    [window setContentView:otherView];

    [self assertNull:windowView._cornerClippedView message:@"The old content view loses its corners when it leaves the window view"];
    [self assertTrue:[windowView needsLayout] message:@"A new content view marks the window view for layout"];

    [windowView layoutIfNeeded];

    [self assert:otherView same:windowView._cornerClippedView message:@"The next layout rounds the new content view"];
}

// MARK: Corners of each kind of window under Aristo3

/*
    These tests read the built Aristo3 theme, so they need the themes built first, as
    `npx jake build` does.
*/
- (CPTheme)aristo3
{
    var theme = BuiltThemeNamed(@"Aristo3");

    [self assertNotNull:theme message:@"The built blends hold no Aristo3 theme. Build the themes first."];

    return theme;
}

/*
    Returns a window view of aClass that takes its values from the built Aristo3 theme.
*/
- (_CPWindowView)aristo3WindowViewOfClass:(Class)aClass styleMask:(unsigned)aStyleMask
{
    var windowView = [[aClass alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 200.0) styleMask:aStyleMask];

    [windowView setTheme:[self aristo3]];

    return windowView;
}

- (void)assertCorners:(CPArray)expected of:(_CPWindowView)aWindowView
{
    var radii = [aWindowView _cornerRadii],
        name = [aWindowView className];

    [self assert:expected[0] equals:radii.topLeft message:name + @" top left"];
    [self assert:expected[1] equals:radii.topRight message:name + @" top right"];
    [self assert:expected[2] equals:radii.bottomLeft message:name + @" bottom left"];
    [self assert:expected[3] equals:radii.bottomRight message:name + @" bottom right"];
}

/*
    The menu bar is a borderless window. These windows took the rounded bottom corners of a
    sheet from the values for every kind of window.
*/
- (void)testWindowsWithoutAFrameShapeHaveSquareCorners
{
    [self assertCorners:[@"", @"", @"", @""] of:[self aristo3WindowViewOfClass:_CPBorderlessWindowView styleMask:CPBorderlessWindowMask]];
    [self assertCorners:[@"", @"", @"", @""] of:[self aristo3WindowViewOfClass:_CPBorderlessBridgeWindowView styleMask:CPBorderlessBridgeWindowMask]];
    [self assertCorners:[@"", @"", @"", @""] of:[self aristo3WindowViewOfClass:_CPPopoverWindowView styleMask:CPBorderlessWindowMask]];
}

- (void)testEachKindOfWindowWithRoundedCornersGivesItsOwn
{
    [self assertCorners:[@"6px", @"6px", @"7px", @"7px"] of:[self aristo3WindowViewOfClass:_CPStandardWindowView styleMask:CPTitledWindowMask]];
    [self assertCorners:[@"0px", @"0px", @"7px", @"7px"] of:[self aristo3WindowViewOfClass:_CPDocModalWindowView styleMask:CPDocModalWindowMask]];
    [self assertCorners:[@"6px", @"6px", @"6px", @"6px"] of:[self aristo3WindowViewOfClass:_CPModalWindowView styleMask:_CPModalWindowMask]];
    [self assertCorners:[@"5px", @"5px", @"5px", @"5px"] of:[self aristo3WindowViewOfClass:_CPHUDWindowView styleMask:CPHUDBackgroundWindowMask | CPClosableWindowMask]];
    [self assertCorners:[@"2px", @"2px", @"2px", @"2px"] of:[self aristo3WindowViewOfClass:_CPToolTipWindowView styleMask:_CPToolTipWindowMask]];
}

- (void)testASheetHasTheCornersOfADocumentModalWindow
{
    var parent = [self window],
        sheet = [self window],
        windowView = [sheet _windowView];

    [windowView setTheme:[self aristo3]];
    [windowView _enableSheet:YES inWindow:parent];

    [self assertCorners:[@"0px", @"0px", @"7px", @"7px"] of:windowView];
}

/*
    The theme gives the corners of a kind of window in its corner radii. A border-radius in
    the bezel of the same kind would lose to them at each layout, and only confuse the reader.
*/
- (void)testNoWindowBezelGivesCornersOfItsOwn
{
    var theme = [self aristo3],
        classes = [_CPWindowView, _CPStandardWindowView, _CPDocModalWindowView, _CPModalWindowView, _CPHUDWindowView,
                   _CPBorderlessWindowView, _CPBorderlessBridgeWindowView, _CPToolTipWindowView, _CPPopoverWindowView],
        violations = [];

    for (var i = 0; i < classes.length; i++)
    {
        var values = [[theme attributeWithName:@"bezel-color" forClass:classes[i]] values];

        /*
            Some kinds of window, such as the base window view and the borderless window, have
            no bezel in the theme, so they have no bezel corners to check.
        */
        if (!values)
            continue;

        var states = [values allKeys];

        for (var j = 0; j < states.length; j++)
        {
            var bezel = [values objectForKey:states[j]],
                location = class_getName(classes[i]) + @" (" + states[j] + @"): ";

            if (!bezel || !bezel.isa || ![bezel isKindOfClass:[CPColor class]])
                continue;

            [[bezel cssDictionary], [bezel cssBeforeDictionary], [bezel cssAfterDictionary]].forEach(function(aDictionary)
            {
                if (!aDictionary)
                    return;

                [aDictionary allKeys].forEach(function(aKey)
                {
                    if (/radius/.test(aKey))
                        violations.push(location + aKey);
                });
            });
        }
    }

    [self assertTrue:violations.length === 0 message:violations.join("\n")];
}

// MARK: Corners from the background

/*
    A window that the theme gives no corners takes the corners that its background declares,
    each corner's own key over the shorthand.
*/
- (void)testAWindowWithoutThemeCornersTakesTheCornersOfItsBackground
{
    var windowView = [self aristo3WindowViewOfClass:_CPBorderlessWindowView styleMask:CPBorderlessWindowMask];

    [windowView setBackgroundColor:[CPColor colorWithCSSDictionary:@{
                                                                     @"border-top-left-radius": @"0px",
                                                                     @"border-top-right-radius": @"0px",
                                                                     @"border-bottom-left-radius": @"7px",
                                                                     @"border-bottom-right-radius": @"7px"
                                                                     }]];
    [self assertCorners:[@"0px", @"0px", @"7px", @"7px"] of:windowView];

    [windowView setBackgroundColor:[CPColor colorWithCSSDictionary:@{
                                                                     @"border-radius": @"6px",
                                                                     @"border-bottom-left-radius": @"1px"
                                                                     }]];
    [self assertCorners:[@"6px", @"6px", @"1px", @"6px"] of:windowView];

    [windowView setBackgroundColor:[CPColor colorWithCSSDictionary:@{ @"background-color": @"rgb(1, 2, 3)" }]];
    [self assertCorners:[@"", @"", @"", @""] of:windowView];
}

- (void)testTheThemeCornersComeBeforeTheBackground
{
    var windowView = [self aristo3WindowViewOfClass:_CPModalWindowView styleMask:_CPModalWindowMask];

    [windowView setBackgroundColor:[CPColor colorWithCSSDictionary:@{ @"border-radius": @"1px" }]];

    [self assertCorners:[@"6px", @"6px", @"6px", @"6px"] of:windowView];
}

/*
    The corners can come from the background, so a new background lays out the frame again.
    The same background does not.
*/
- (void)testANewBackgroundLaysOutTheFrameAgain
{
    var windowView = [self aristo3WindowViewOfClass:_CPBorderlessWindowView styleMask:CPBorderlessWindowMask],
        background = [CPColor colorWithCSSDictionary:@{ @"border-radius": @"6px" }];

    [windowView layoutIfNeeded];
    [windowView setBackgroundColor:background];

    [self assertTrue:[windowView needsLayout] message:@"a new background"];

    [windowView layoutIfNeeded];
    [windowView setBackgroundColor:background];

    [self assertFalse:[windowView needsLayout] message:@"the same background"];
}

/*
    A menu window gives its shape in its background, for each background style. The window
    view wrote empty radii over it and removed the menu's corners.
*/
- (void)testAMenuWindowHasTheCornersOfItsBackgroundStyle
{
    var previousTheme = [CPTheme defaultTheme];

    [CPTheme setDefaultTheme:[self aristo3]];

    try
    {
        var menuWindow = [[_CPMenuWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 100.0, 100.0) styleMask:CPBorderlessWindowMask];

        [menuWindow setBackgroundStyle:_CPMenuWindowMenuBarBackgroundStyle];
        [self assertCorners:[@"0px", @"0px", @"7px", @"7px"] of:[menuWindow _windowView]];

        [menuWindow setBackgroundStyle:_CPMenuWindowPopUpBackgroundStyle];
        [self assertCorners:[@"6px", @"6px", @"7px", @"7px"] of:[menuWindow _windowView]];
    }
    finally
    {
        [CPTheme setDefaultTheme:previousTheme];
    }
}

@end
