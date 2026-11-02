/*
 *  CPTableViewDrawingTest.j
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

@import <AppKit/AppKit.j>

/*
    NSTableView draws itself as a sequence of named steps: the background, then
    the selection highlight, then the grid, then the rows. Each step is a method.
    A subclass overrides one step to change it and inherits the others, so it can
    extend the table without owning the table's internals.

    CPTableView follows the same design. These tests confirm that each step reaches
    a subclass. How the table organizes its drawing is its own concern, so the tests
    observe only what a subclass can observe.
*/
@implementation DrawingRecordingTableView : CPTableView
{
    CPArray     drawnSteps  @accessors;
    CPArray     drawnRows   @accessors;
}

/*
    Applications override this method to draw something other than a solid color
    or alternating rows behind the table's content.
*/
- (void)drawBackgroundInClipRect:(CGRect)aRect
{
    [drawnSteps addObject:@"background"];
}

/*
    Applications override this method to change how selected rows appear.
    In Cocoa this applies to cell-based tables. A view-based NSTableView uses
    NSTableRowView for this purpose. CPTableView supports the method on its
    view-based tables, and existing applications depend on it.
*/
- (void)highlightSelectionInClipRect:(CGRect)aRect
{
    [drawnSteps addObject:@"selection"];
}

/*
    Cocoa documents this method for all tables: subclasses override it to draw
    grid lines other than the standard ones.
*/
- (void)drawGridInClipRect:(CGRect)aRect
{
    [drawnSteps addObject:@"grid"];
}

/*
    Applications override this method to draw over a row. A source list, for
    example, can draw a badge beside an item this way. Cocoa also restricts this
    method to cell-based tables, and CPTableView supports it as it does the
    selection highlight.
*/
- (void)drawRow:(CPInteger)aRow clipRect:(CGRect)aRect
{
    [drawnRows addObject:aRow];
}

@end

@implementation CPTableViewDrawingTest : OJTestCase
{
    CPWindow                    theWindow;
    DrawingRecordingTableView   tableView;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 400.0) styleMask:CPWindowNotSizable];

    tableView = [[DrawingRecordingTableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 200.0)];
    [tableView setDrawnSteps:[]];
    [tableView setDrawnRows:[]];

    [tableView addTableColumn:[[CPTableColumn alloc] initWithIdentifier:@"Column"]];
    [tableView setDataSource:self];

    [[theWindow contentView] addSubview:tableView];
    [tableView reloadData];
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return 3;
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRow
{
    return @"Value";
}

/*
    Unit tests run without a DOM, and CPView does not draw without one, so the
    display cycle never reaches drawRect: here. This method does what the display
    cycle does: it sends drawRect: to the table view and to each of its subviews.
    The graphics port has no backing store, because creating a bitmap context
    requires a DOM. The tests therefore show that the steps run, not what they draw.
*/
- (void)display
{
    [tableView load];

    var graphicsPort = { path: NULL, gState: CGGStateCreate(), gStateStack: [] };

    [CPGraphicsContext setCurrentContext:[CPGraphicsContext graphicsContextWithGraphicsPort:graphicsPort flipped:YES]];

    [tableView drawRect:[tableView bounds]];

    var subviews = [tableView subviews],
        count = [subviews count];

    while (count--)
        [subviews[count] drawRect:[subviews[count] bounds]];
}

- (void)testDrawGridInClipRectOverrideIsCalled
{
    [self display];

    [self assertTrue:[[tableView drawnSteps] containsObject:@"grid"]];
}

- (void)testDrawBackgroundInClipRectOverrideIsCalled
{
    [self display];

    [self assertTrue:[[tableView drawnSteps] containsObject:@"background"]];
}

- (void)testHighlightSelectionInClipRectOverrideIsCalled
{
    [self display];

    [self assertTrue:[[tableView drawnSteps] containsObject:@"selection"]];
}

- (void)testDrawRowClipRectOverrideIsCalledForEachExposedRow
{
    [self display];

    [self assert:[0, 1, 2] equals:[tableView drawnRows]];
}

/*
    Each step draws over the one before it. The order is part of the contract,
    because a subclass that draws a background relies on the selection and the
    grid appearing above it.
*/
- (void)testDrawingStepsRunInOrder
{
    [self display];

    [self assert:[@"background", @"selection", @"grid"] equals:[tableView drawnSteps]];
}

/*
    A color that an application sets belongs to the application. Theme states
    change often during normal use, for example when the table gains or loses
    first responder status, and they must leave that color in place.
*/
- (void)testBackgroundColorSurvivesThemeStateChange
{
    var color = [CPColor redColor];

    [tableView setBackgroundColor:color];
    [tableView setThemeState:CPThemeStateFirstResponder];
    [self assert:color equals:[tableView backgroundColor]];

    [tableView unsetThemeState:CPThemeStateFirstResponder];
    [self assert:color equals:[tableView backgroundColor]];
}

@end
