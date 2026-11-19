/*
 *  CPPlatformWindowCanvasTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-19.
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

/*
    The platform window paints the canvas, the page area outside every window, with
    +[CPColor underPageBackgroundColor] in the application's effective appearance, unless the
    page sets a background of its own. The tests run without a DOM, so they test the colour and
    the background check that the platform window uses.
*/
@implementation CPPlatformWindowCanvasTest : OJTestCase
{
    CPTheme     _previousTheme;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    /*
        The built-in DarkAqua values apply only under a theme that lists DarkAqua among its
        supported appearances.
    */
    var theme = [[CPTheme alloc] initWithName:@"CPPlatformWindowCanvasTest"],
        template = [CPColor colorWithWhite:0.0 alpha:1.0];

    [template setValue:[CPAppearanceNameAqua, CPAppearanceNameDarkAqua] forThemeAttribute:@"supported-appearances"];
    [theme takeThemeFromObject:template];

    _previousTheme = [CPTheme defaultTheme];
    [CPTheme setDefaultTheme:theme];
}

- (void)tearDown
{
    [CPTheme setDefaultTheme:_previousTheme];
    [CPAppearance setCurrentAppearance:nil];
}

- (void)assertWhite:(float)aWhite of:(CPColor)aColor message:(CPString)aMessage
{
    var components = [aColor components];

    for (var i = 0; i < 3; i++)
        [self assert:ROUND(aWhite * 10000) equals:ROUND(components[i] * 10000) message:aMessage + @", component " + i];

    [self assert:1.0 equals:components[3] message:aMessage + @", alpha"];
}

// MARK: Canvas colour

- (void)testTheCanvasTakesTheUnderPageBackgroundOfEachAppearance
{
    [self assertWhite:0.9647 of:_CPPlatformWindowCanvasColor([CPAppearance appearanceNamed:CPAppearanceNameAqua]) message:@"Aqua"];
    [self assertWhite:0.1569 of:_CPPlatformWindowCanvasColor([CPAppearance appearanceNamed:CPAppearanceNameDarkAqua]) message:@"DarkAqua"];
}

/*
    The canvas colour resolves in the appearance it is given, whatever the current drawing
    appearance is, and leaves the current drawing appearance as it was.
*/
- (void)testTheCanvasColorKeepsTheCurrentDrawingAppearance
{
    var aqua = [CPAppearance appearanceNamed:CPAppearanceNameAqua];

    [CPAppearance setCurrentAppearance:aqua];

    [self assertWhite:0.1569 of:_CPPlatformWindowCanvasColor([CPAppearance appearanceNamed:CPAppearanceNameDarkAqua]) message:@"DarkAqua under Aqua"];
    [self assert:aqua same:[CPAppearance currentAppearance]];
}

// MARK: Background of the page

- (void)testAPageElementWithoutABackgroundLeavesTheCanvasToTheFramework
{
    [self assertTrue:_CPPlatformWindowStyleHasNoBackground(nil) message:@"no style"];
    [self assertTrue:_CPPlatformWindowStyleHasNoBackground({ backgroundColor: "rgba(0, 0, 0, 0)", backgroundImage: "none" }) message:@"computed default"];
    [self assertTrue:_CPPlatformWindowStyleHasNoBackground({ backgroundColor: "transparent", backgroundImage: "none" }) message:@"transparent"];
}

- (void)testAPageElementWithABackgroundKeepsIt
{
    [self assertFalse:_CPPlatformWindowStyleHasNoBackground({ backgroundColor: "rgb(255, 255, 255)", backgroundImage: "none" }) message:@"a colour"];
    [self assertFalse:_CPPlatformWindowStyleHasNoBackground({ backgroundColor: "rgba(0, 0, 0, 0)", backgroundImage: "url(\"canvas.png\")" }) message:@"an image"];
}

@end
