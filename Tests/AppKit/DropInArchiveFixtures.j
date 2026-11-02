/*
 *  DropInArchiveFixtures.j
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
    Creates the views that the archive tests write and read back. An empty view has
    little to lose, so each view holds real content. The reference for a view is its
    own description before it is archived, never what a build restores.
*/

/*
    The only view classes without a fixture. Each entry states the reason. Any other
    class that cannot be archived is a failure.
*/
var DropInArchiveExclusions = {
        @"CPText": @"it is abstract and its text methods raise an exception",
        @"CPWebView": @"creating one needs a DOM"
    };

function DropInArchiveExclusion(aClassName)
{
    return DropInArchiveExclusions[aClassName];
}

function DropInArchiveChild(aWidth, aHeight)
{
    return [[CPView alloc] initWithFrame:CGRectMake(3.0, 5.0, aWidth, aHeight)];
}

function DropInArchiveTableColumn(anIdentifier)
{
    var column = [[CPTableColumn alloc] initWithIdentifier:anIdentifier];

    [column setWidth:60.0];

    return column;
}

/*
    The content of each class. A class without an entry uses the entry of its
    nearest superclass.
*/
var DropInArchivePopulators = {
        @"CPView": function(aView)
        {
            [aView addSubview:DropInArchiveChild(20.0, 10.0)];
        },
        @"CPControl": function(aControl)
        {
            [aControl setEnabled:NO];
            [aControl setTag:7];
        },
        @"CPAccordionView": function(anAccordionView)
        {
            var item = [[CPAccordionViewItem alloc] initWithIdentifier:@"item"];

            [item setLabel:@"Item"];
            [item setView:DropInArchiveChild(40.0, 30.0)];
            [anAccordionView addItem:item];
        },
        @"CPBox": function(aBox)
        {
            var content = DropInArchiveChild(60.0, 40.0);

            [content addSubview:DropInArchiveChild(20.0, 10.0)];
            [aBox setTitle:@"Box"];
            [aBox setTitlePosition:CPAtTop];
            [aBox setContentView:content];
        },
        @"CPButton": function(aButton)
        {
            [aButton setTitle:@"Button"];
            [aButton setState:CPOnState];
            [aButton setTag:7];
        },
        @"CPButtonBar": function(aButtonBar)
        {
            [aButtonBar setButtons:[[CPButtonBar plusButton], [CPButtonBar minusButton]]];
        },
        @"CPColorWell": function(aColorWell)
        {
            [aColorWell setColor:[CPColor redColor]];
        },
        @"CPComboBox": function(aComboBox)
        {
            [aComboBox addItemsWithObjectValues:[@"One", @"Two"]];
            [aComboBox setStringValue:@"One"];
        },
        @"CPDatePicker": function(aDatePicker)
        {
            [aDatePicker setDateValue:[[CPDate alloc] initWithString:@"2026-10-31 12:00:00 +0000"]];
        },
        @"CPLevelIndicator": function(aLevelIndicator)
        {
            [aLevelIndicator setMinValue:1.0];
            [aLevelIndicator setMaxValue:9.0];
            [aLevelIndicator setDoubleValue:4.0];
        },
        @"CPOutlineView": function(anOutlineView)
        {
            var column = DropInArchiveTableColumn(@"one");

            [anOutlineView addTableColumn:column];
            [anOutlineView setOutlineTableColumn:column];
        },
        @"CPPopUpButton": function(aPopUpButton)
        {
            [aPopUpButton addItemsWithTitles:[@"One", @"Two"]];
            [aPopUpButton selectItemAtIndex:1];
        },
        @"CPProgressIndicator": function(aProgressIndicator)
        {
            [aProgressIndicator setMinValue:1.0];
            [aProgressIndicator setMaxValue:9.0];
            [aProgressIndicator setDoubleValue:4.0];
        },
        @"CPScrollView": function(aScrollView)
        {
            [aScrollView setDocumentView:DropInArchiveChild(300.0, 400.0)];
        },
        @"CPSegmentedControl": function(aSegmentedControl)
        {
            [aSegmentedControl setSegmentCount:2];
            [aSegmentedControl setLabel:@"One" forSegment:0];
            [aSegmentedControl setLabel:@"Two" forSegment:1];
            [aSegmentedControl setWidth:40.0 forSegment:0];
            [aSegmentedControl setWidth:40.0 forSegment:1];
        },
        @"CPSlider": function(aSlider)
        {
            [aSlider setMinValue:1.0];
            [aSlider setMaxValue:9.0];
            [aSlider setDoubleValue:4.0];
        },
        @"CPSplitView": function(aSplitView)
        {
            [aSplitView addSubview:DropInArchiveChild(40.0, 90.0)];
            [aSplitView addSubview:DropInArchiveChild(40.0, 90.0)];
        },
        @"CPStackView": function(aStackView)
        {
            [aStackView addArrangedSubview:DropInArchiveChild(40.0, 30.0)];
        },
        @"CPStepper": function(aStepper)
        {
            [aStepper setMinValue:1.0];
            [aStepper setMaxValue:9.0];
            [aStepper setDoubleValue:4.0];
        },
        @"CPTableView": function(aTableView)
        {
            [aTableView addTableColumn:DropInArchiveTableColumn(@"one")];
            [aTableView addTableColumn:DropInArchiveTableColumn(@"two")];
        },
        @"CPTabView": function(aTabView)
        {
            ["one", "two"].forEach(function(anIdentifier)
            {
                var item = [[CPTabViewItem alloc] initWithIdentifier:anIdentifier];

                [item setLabel:anIdentifier];
                [item setView:DropInArchiveChild(40.0, 30.0)];
                [aTabView addTabViewItem:item];
            });

            [aTabView selectTabViewItemAtIndex:1];
        },
        @"CPTextView": function(aTextView)
        {
            [aTextView setString:@"Text"];
        },
        @"CPTextField": function(aTextField)
        {
            [aTextField setStringValue:@"Text"];
            [aTextField setEditable:YES];
            [aTextField setBezeled:YES];
        },
        @"CPTokenField": function(aTokenField)
        {
            [aTokenField setObjectValue:[@"One", @"Two"]];
        }
    };

function DropInArchivePopulator(aClass)
{
    for (; aClass; aClass = class_getSuperclass(aClass))
        if (DropInArchivePopulators[aClass.name])
            return DropInArchivePopulators[aClass.name];

    return nil;
}

function DropInArchiveFixture(aClass)
{
    var view = [[aClass alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 100.0)];

    DropInArchivePopulator(aClass)(view);

    return view;
}

/*
    Lists each place where two view descriptions differ.
*/
function DropInTreeDifferences(expected, current, aPath, differences)
{
    if (expected && current && typeof expected === "object" && typeof current === "object")
    {
        Object.keys(expected).concat(Object.keys(current)).filter(function(aKey, anIndex, aList)
        {
            return aList.indexOf(aKey) === anIndex;
        }).forEach(function(aKey)
        {
            DropInTreeDifferences(expected[aKey], current[aKey], aPath + "." + aKey, differences);
        });
    }
    else if (expected !== current)
        differences.push(aPath + ": " + JSON.stringify(expected) + " is now " + JSON.stringify(current));

    return differences;
}

/*
    Layout changes frames and adds subviews, and a new view has not asked for it. Every
    view is laid out before it is described, so that two descriptions are comparable.
*/
function DropInArchiveLayOut(aView)
{
    [aView setNeedsLayout];
    [_CPDisplayServer run];
}

/*
    Archives a fixture and reads it back.
*/
function DropInArchiveRoundTrip(aClass)
{
    return DropInWithFixedScrollerStyle(function()
    {
        var view = DropInArchiveFixture(aClass);

        DropInArchiveLayOut(view);

        var original = DropInViewTree(view),
            data = [CPKeyedArchiver archivedDataWithRootObject:view],
            decoded = [CPKeyedUnarchiver unarchiveObjectWithData:data];

        DropInArchiveLayOut(decoded);

        return { @"archive": [data rawString], @"original": original, @"decoded": DropInViewTree(decoded) };
    });
}

/*
    Reads a saved archive back and describes the view.
*/
function DropInSavedArchiveTree(aRawString)
{
    return DropInWithFixedScrollerStyle(function()
    {
        var decoded = [CPKeyedUnarchiver unarchiveObjectWithData:[CPData dataWithRawString:aRawString]];

        DropInArchiveLayOut(decoded);

        return DropInViewTree(decoded);
    });
}
