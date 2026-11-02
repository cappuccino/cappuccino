/*
 *  DropInArchiveTest.j
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

@import "DropInArchiveFixtures.j"

/*
    Every application with an interface built in Xcode depends on cibs, and those
    cibs were written before the application's frameworks were last updated. An
    application that updates its frameworks does not rebuild them first, so the
    frameworks must keep reading what was already written. A new key may be added to
    an archive. Its absence from an older archive must then mean the old behavior,
    and not a new default.

    The reference for a view is the view before it was archived, so a build cannot
    pass by restoring something else. A warning during decoding is a failure. The
    classes under test are those in the drop-in baseline, so a class cannot leave
    these tests unnoticed.

    DropInArchiveGenerator.j saves the data these tests read. Each test reports every
    difference it finds.
*/
var fs = require("fs"),
    path = require("path");

@implementation DropInArchiveTest : OJTestCase
{
    CPString    resources;
    CPArray     warnings;
    Function    logWarning;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    resources = path.join(path.dirname(__filename), "Resources");
    warnings = [];
    logWarning = CPLog.warn;

    CPLog.warn = function(aMessage)
    {
        warnings.push(String(aMessage));
    };
}

- (void)tearDown
{
    CPLog.warn = logWarning;
}

- (id)jsonNamed:(CPString)aName
{
    return JSON.parse(fs.readFileSync(path.join(resources, aName), {encoding: 'utf-8'}));
}

- (CPArray)viewClassNames
{
    return Object.keys([self jsonNamed:@"DropInBaseline.json"].construction).filter(function(aClassName)
    {
        return !DropInArchiveExclusion(aClassName);
    });
}

- (void)assertNoDifferences:(CPArray)differences
{
    [self assertTrue:differences.length === 0 message:"\n" + differences.join("\n")];
}

- (void)moveWarningsNamed:(CPString)aName into:(CPArray)differences
{
    warnings.forEach(function(aWarning)
    {
        differences.push(aName + " warned: " + aWarning);
    });

    warnings = [];
}

/*
    A view that is archived and read back must be the same view, with the same
    content.
*/
- (void)testNewArchivesRestoreTheOriginalView
{
    var differences = [];

    [self viewClassNames].forEach(function(aClassName)
    {
        try
        {
            var result = DropInArchiveRoundTrip(objj_getClass(aClassName));

            DropInTreeDifferences(result.original, result.decoded, aClassName, differences);
        }
        catch (anException)
        {
            differences.push(aClassName + ": " + String(anException));
        }

        [self moveWarningsNamed:aClassName into:differences];
    });

    [self assertNoDifferences:differences];
}

/*
    An archive written by main must restore the view it was written from.
*/
- (void)testExistingArchivesRestoreTheOriginalView
{
    var archivePath = path.join(resources, @"DropInArchives.json");

    [self assertTrue:fs.existsSync(archivePath) message:@"DropInArchives.json has not been generated"];

    var archives = [self jsonNamed:@"DropInArchives.json"],
        differences = [];

    [self viewClassNames].forEach(function(aClassName)
    {
        var saved = archives[aClassName];

        if (!saved)
            return differences.push(aClassName + ": no saved archive");

        try
        {
            DropInTreeDifferences(saved.state, DropInSavedArchiveTree(saved.archive), aClassName, differences);
        }
        catch (anException)
        {
            differences.push(aClassName + ": " + String(anException));
        }

        [self moveWarningsNamed:aClassName into:differences];
    });

    [self assertNoDifferences:differences];
}

/*
    These are fixed copies of real cibs, and they do not follow their sources. They are
    Tests/Manual/SmartFoldersTest/Resources/PredicateEditor.cib and
    Tests/Manual/TextEditor/Resources/DocumentWindow.cib, as of commit 5db5adac0.
    Loading one must produce the same windows, views and frames as main. The MainMenu
    cibs of those applications are not here. TextEditor's shows a menu bar, which needs
    a platform window, and SmartFoldersTest's connects a data source that is defined by
    the application.
*/
- (void)testExistingCibsProduceTheSameObjects
{
    var expected = [self jsonNamed:@"DropInCibs.json"],
        differences = [];

    for (var cibName in expected)
    {
        var rawString = fs.readFileSync(path.join(resources, "DropInCibs", cibName), {encoding: 'utf-8'}),
            current = DropInCibTree(cibName, rawString),
            expectedTrees = expected[cibName];

        if (current.length !== expectedTrees.length)
        {
            differences.push(cibName + ": " + expectedTrees.length + " top level objects are now " + current.length);
            continue;
        }

        for (var index = 0; index < current.length; index++)
            DropInTreeDifferences(JSON.parse(expectedTrees[index]), JSON.parse(current[index]), cibName, differences);

        [self moveWarningsNamed:cibName into:differences];
    }

    [self assertNoDifferences:differences];
}

@end
