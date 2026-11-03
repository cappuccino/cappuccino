/*
 *  CPThemeSwitchTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-03.
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

@import "BuiltThemes.j"
@import "DropInArchiveFixtures.j"

/*
    An application can change its theme while it runs. Afterwards every view must
    look as if it had been made under the new theme.

    - A view reads its theme values when it lays out and draws. A value it copied
      elsewhere, such as into an instance variable, must be read again when the theme
      changes. So a view that changes theme must match a view made under the new
      theme.
    - The change must reach every themed view: the views of each window, including
      the window's own frame and controls, and the views each class makes for itself.
    - A view outside any window when the theme changes, and whose theme was never set
      explicitly, takes the current theme when it enters a window. A view whose theme
      was set explicitly keeps it.

    A change of theme may change a view's frame, because the themes can differ in
    metrics. That is the work of the metric pass, which adjusts frames by the
    difference between the old and new themes' metrics, and nothing else may do it.
    Until views made in code record the size their theme gave them, the pass cannot
    reach them, and a view that sizes itself from its theme when it is made, such as a
    stepper, keeps the old theme's size. Such a frame difference belongs to the metric
    pass, not to a value that was not read again.

    These tests use the real Aristo2 and Aristo3 themes from the build, so they need
    the themes built first, as `npx jake build` does. Each test reports every
    difference it finds.

    The application's theme switch is not built yet. -switchToTheme:inWindow: does
    what it must do, in the same order: set the default theme, then change the theme
    of the window's views.
*/
var fs = require("fs"),
    path = require("path");

@implementation CPThemeSwitchTest : OJTestCase
{
    CPTheme     defaultTheme;
    CPTheme     aristo2;
    CPTheme     aristo3;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    defaultTheme = [CPTheme defaultTheme];
    aristo2 = BuiltThemeNamed(@"Aristo2");
    aristo3 = BuiltThemeNamed(@"Aristo3");

    [self assertTrue:aristo2 !== nil && aristo3 !== nil message:@"Aristo2 and Aristo3 were not found in the built blends. Build the themes first."];
}

- (void)tearDown
{
    [CPTheme setDefaultTheme:defaultTheme];
}

/*
    The view classes of the drop-in baseline, so that a class cannot leave these tests
    unnoticed. A class the archive tests cannot create is left out for the same reason.
*/
- (CPArray)viewClassNames
{
    var baseline = JSON.parse(fs.readFileSync(path.join(path.dirname(__filename), "Resources", "DropInBaseline.json"), { encoding: "utf-8" }));

    return Object.keys(baseline.construction).filter(function(aClassName)
    {
        return !DropInArchiveExclusion(aClassName);
    }).sort();
}

/*
    A new date picker shows the current time, so two pickers made a moment apart
    differ. Each picker is given the same date, so that only the theme can make them
    differ.
*/
- (CPView)newViewOfClassNamed:(CPString)aClassName
{
    var view = [[CPClassFromString(aClassName) alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];

    if ([view respondsToSelector:@selector(setDateValue:)])
        [view setDateValue:[CPDate dateWithTimeIntervalSince1970:0]];

    return view;
}

- (void)switchToTheme:(CPTheme)aTheme inWindow:(CPWindow)aWindow
{
    [CPTheme setDefaultTheme:aTheme];
    [aWindow _setThemeIncludingDescendants:aTheme];
    [_CPDisplayServer run];
}

/*
    Describes a theme value. Unlike the drop-in snapshot, an image is described by its
    file, so that a different image counts as a difference.
*/
- (CPString)describeThemeValue:(id)aValue
{
    if (aValue && aValue.isa && [aValue isKindOfClass:[CPImage class]])
        return "CPImage:" + ([aValue filename] || "") + " " + DropInDescribeValue([aValue size]);

    if (aValue && aValue.isa && [aValue isKindOfClass:[CPDictionary class]])
    {
        var keys = [[aValue allKeys] sortedArrayUsingSelector:@selector(compare:)],
            self_ = self;

        return "{" + keys.map(function(aKey) { return aKey + ": " + [self_ describeThemeValue:[aValue objectForKey:aKey]]; }).join(", ") + "}";
    }

    return DropInDescribeValue(aValue);
}

/*
    Adds to aResult, under aLocation, everything that is described about aValue. An
    object or array is added one entry at a time, so that a difference names the
    entry that differs.
*/
- (void)flatten:(id)aValue at:(CPString)aLocation into:(Object)aResult
{
    if (aValue !== null && typeof aValue === "object")
    {
        for (var key in aValue)
            if (aValue.hasOwnProperty(key))
                [self flatten:aValue[key] at:aLocation + "." + key into:aResult];
    }
    else
        aResult[aLocation] = String(aValue);
}

/*
    Adds the value each view below aView resolves for each of its theme attributes.
    Private views are included: their values are as much a part of the view's look as
    those of public views.
*/
- (void)collectThemeValuesOf:(CPView)aView at:(CPString)aLocation into:(Object)aResult
{
    var names = [[[aView _themeAttributeDictionary] allKeys] sortedArrayUsingSelector:@selector(compare:)];

    for (var i = 0; i < names.length; i++)
        aResult[aLocation + " " + names[i]] = [self describeThemeValue:[aView currentValueForThemeAttribute:names[i]]];

    var subviews = [aView subviews];

    for (var i = 0; i < subviews.length; i++)
        [self collectThemeValuesOf:subviews[i] at:aLocation + "/" + i + ":" + [subviews[i] className] into:aResult];
}

/*
    Describes a view as a flat list of entries: its view tree, as the drop-in snapshot
    records it, and the theme values of every view below it.
*/
- (Object)describeView:(CPView)aView
{
    var result = {};

    [self flatten:DropInViewTree(aView) at:@"tree" into:result];
    [self collectThemeValuesOf:aView at:@"values" into:result];

    return result;
}

/*
    Makes one view of each class under aTheme and changes it to anotherTheme, and
    makes a second view under anotherTheme. Returns each difference between the two.
*/
- (CPArray)differencesSwitchingFromTheme:(CPTheme)aTheme toTheme:(CPTheme)anotherTheme
{
    var classNames = [self viewClassNames],
        differences = [],
        self_ = self;

    DropInWithFixedScrollerStyle(function()
    {
        for (var i = 0; i < classNames.length; i++)
        {
            var className = classNames[i];

            try
            {
                [CPTheme setDefaultTheme:aTheme];

                var switched = [self_ newViewOfClassNamed:className];

                [_CPDisplayServer run];
                [CPTheme setDefaultTheme:anotherTheme];
                [switched _setThemeIncludingDescendants:anotherTheme];
                [_CPDisplayServer run];

                var made = [self_ newViewOfClassNamed:className];

                [_CPDisplayServer run];

                var expected = [self_ describeView:made],
                    actual = [self_ describeView:switched],
                    keys = Object.keys(expected);

                Object.keys(actual).forEach(function(aKey)
                {
                    if (!expected.hasOwnProperty(aKey))
                        keys.push(aKey);
                });

                keys.sort().forEach(function(aKey)
                {
                    if (expected[aKey] !== actual[aKey])
                        differences.push(className + " " + aKey + ": " + (actual[aKey] || "missing") + " should be " + (expected[aKey] || "missing"));
                });
            }
            catch (anException)
            {
                differences.push(className + ": " + String(anException));
            }
        }
    });

    return differences;
}

- (void)testSwitchingFromAristo2ToAristo3MatchesAViewMadeUnderAristo3
{
    var differences = [self differencesSwitchingFromTheme:aristo2 toTheme:aristo3];

    [self assertTrue:differences.length === 0 message:@"After the theme changes, a view must match one made under the new theme:\n" + differences.join("\n")];
}

- (void)testSwitchingFromAristo3ToAristo2MatchesAViewMadeUnderAristo2
{
    var differences = [self differencesSwitchingFromTheme:aristo3 toTheme:aristo2];

    [self assertTrue:differences.length === 0 message:@"After the theme changes, a view must match one made under the new theme:\n" + differences.join("\n")];
}

/*
    Adds a description of each view below aView whose theme is not aTheme.
*/
- (void)collectViewsBelow:(CPView)aView at:(CPString)aLocation notUsingTheme:(CPTheme)aTheme into:(CPArray)someViolations
{
    if ([aView theme] !== aTheme)
        someViolations.push(aLocation + " uses " + ([[aView theme] name] || "no theme"));

    var subviews = [aView subviews];

    for (var i = 0; i < subviews.length; i++)
        [self collectViewsBelow:subviews[i] at:aLocation + "/" + i + ":" + [subviews[i] className] notUsingTheme:aTheme into:someViolations];
}

/*
    Each class is tested in its own window, so that an exception in one class does not
    hide what happens to the others. A view of the window itself would then be reported
    once for each class, so each report is listed once.
*/
- (void)testAThemeChangeReachesEveryViewInAWindow
{
    var classNames = [self viewClassNames],
        violations = [];

    for (var i = 0; i < classNames.length; i++)
    {
        try
        {
            [CPTheme setDefaultTheme:aristo2];

            var window = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 300.0)
                                                     styleMask:CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask],
                windowView = [window _windowView];

            [[window contentView] addSubview:[self newViewOfClassNamed:classNames[i]]];
            [_CPDisplayServer run];
            [self switchToTheme:aristo3 inWindow:window];
            [self collectViewsBelow:windowView at:[windowView className] notUsingTheme:aristo3 into:violations];
        }
        catch (anException)
        {
            violations.push(classNames[i] + ": " + String(anException));
        }
    }

    violations = violations.filter(function(aViolation, anIndex)
    {
        return violations.indexOf(aViolation) === anIndex;
    });

    [self assertTrue:violations.length === 0 message:@"A theme change must reach every view in a window:\n" + violations.join("\n")];
}

- (void)testAViewOutsideAWindowTakesTheCurrentThemeWhenItEntersOne
{
    [CPTheme setDefaultTheme:aristo2];

    var window = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 300.0) styleMask:CPTitledWindowMask],
        button = [self newViewOfClassNamed:@"CPButton"];

    [self switchToTheme:aristo3 inWindow:window];
    [[window contentView] addSubview:button];

    [self assertTrue:[button theme] === aristo3 message:@"A view whose theme was never set explicitly must take the current theme when it enters a window, but it uses " + [[button theme] name]];
}

- (void)testAViewOutsideAWindowKeepsAnExplicitThemeWhenItEntersOne
{
    [CPTheme setDefaultTheme:aristo2];

    var window = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 300.0) styleMask:CPTitledWindowMask],
        button = [self newViewOfClassNamed:@"CPButton"];

    [button setTheme:aristo2];
    [self switchToTheme:aristo3 inWindow:window];
    [[window contentView] addSubview:button];

    [self assertTrue:[button theme] === aristo2 message:@"A view whose theme was set explicitly must keep it when it enters a window, but it uses " + [[button theme] name]];
}

@end
