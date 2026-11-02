/*
 *  DropInBaselineTest.j
 *  AppKit
 *
 *  Created by David Richardson on 31/10/2026.
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

@import "DropInSnapshot.j"

/*
    Compares the running frameworks with the recorded drop-in baseline. See
    DropInSnapshot.j for what the baseline holds and DropInBaselineGenerator.j for
    how to update it.

    Each test reports every difference it finds. A list is more useful here than
    a failure at the first difference, because one change often affects several
    classes.
*/
var fs = require("fs"),
    path = require("path"),
    DropInBaseline = nil,
    DropInCurrent = nil;

@implementation DropInBaselineTest : OJTestCase

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    if (DropInBaseline)
        return;

    var baselinePath = path.join(path.dirname(__filename), "Resources", "DropInBaseline.json");

    DropInBaseline = JSON.parse(fs.readFileSync(baselinePath, {encoding: 'utf-8'}));
    DropInCurrent = DropInCreateSnapshot();
}

- (void)assertNoDifferences:(CPArray)differences
{
    [self assertTrue:differences.length === 0 message:"\n" + differences.join("\n")];
}

/*
    A themed application reads these values whenever its theme supplies none, so a
    changed default changes the application.
*/
- (void)testThemeAttributeDefaultsAreUnchanged
{
    var differences = [];

    for (var className in DropInBaseline.themeAttributes)
    {
        var expected = DropInBaseline.themeAttributes[className],
            current = DropInCurrent.themeAttributes[className];

        if (!current)
        {
            differences.push(className + ": class no longer declares theme attributes");
            continue;
        }

        for (var attribute in expected)
            if (expected[attribute] !== current[attribute])
                differences.push(className + " " + attribute + ": " + expected[attribute] + " is now " + current[attribute]);
    }

    [self assertNoDifferences:differences];
}

- (void)testPublicClassesExist
{
    var differences = DropInBaseline.publicClasses.filter(function(aName)
    {
        return !objj_getClass(aName);
    });

    [self assertNoDifferences:differences];
}

/*
    A public method may move to a superclass, since the class still responds to it.
    It may not disappear. This test cannot detect a method that remains but no
    longer does its work. Behavior tests cover that.
*/
- (void)testPublicMethodsExist
{
    var differences = [];

    DropInBaseline.publicClasses.forEach(function(aName)
    {
        var aClass = objj_getClass(aName);

        if (!aClass)
            return;

        DropInBaseline.instanceMethods[aName].forEach(function(aSelector)
        {
            if (!class_getInstanceMethod(aClass, aSelector))
                differences.push("-[" + aName + " " + aSelector + "]");
        });

        DropInBaseline.classMethods[aName].forEach(function(aSelector)
        {
            if (!class_getClassMethod(aClass, aSelector))
                differences.push("+[" + aName + " " + aSelector + "]");
        });
    });

    [self assertNoDifferences:differences];
}

/*
    A view created in code has these values until the application changes them.
*/
- (void)testDefaultViewConstructionIsUnchanged
{
    var differences = [];

    for (var className in DropInBaseline.construction)
    {
        var expected = DropInBaseline.construction[className],
            current = DropInCurrent.construction[className];

        if (!current)
        {
            differences.push(className + ": cannot be created");
            continue;
        }

        for (var key in expected)
        {
            var expectedValue = String(expected[key]),
                currentValue = String(current[key]);

            if (expectedValue !== currentValue)
                differences.push(className + " " + key + ": " + expectedValue + " is now " + currentValue);
        }
    }

    [self assertNoDifferences:differences];
}

/*
    The public subviews of a window view are the controls a person sees in the
    title bar, so they are part of how an existing application looks.
*/
- (void)testWindowControlsAreUnchanged
{
    var differences = [];

    for (var style in DropInBaseline.windows)
    {
        var expected = String(DropInBaseline.windows[style]),
            current = String(DropInCurrent.windows[style]);

        if (expected !== current)
            differences.push(style + ": " + expected + " is now " + current);
    }

    [self assertNoDifferences:differences];
}

@end
