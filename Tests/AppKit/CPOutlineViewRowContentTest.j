/*
 *  CPOutlineViewRowContentTest.j
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
    Applications draw their own content on table and outline rows. A source list
    draws a count badge beside an item, for example, as SmartFoldersDemo does in its
    BadgedOutlineView. That content is correct only if the table keeps redrawing it
    as a person uses the table.

    These tests take such a view through ordinary use: selecting, scrolling, resizing
    a column, expanding an item, reloading. After each action, the table must ask for
    its content again, and only for the rows now on screen.

    The tests observe what a subclass observes. They do not depend on which view
    performs the table's drawing.
*/
@implementation RowContentItem : CPObject
{
    CPString    title       @accessors;
    CPArray     children    @accessors;
}

+ (id)itemWithTitle:(CPString)aTitle children:(CPArray)someChildren
{
    var item = [[self alloc] init];

    [item setTitle:aTitle];
    [item setChildren:someChildren];

    return item;
}

@end

/*
    Records what it is asked to draw, in place of drawing. The default implementations
    need a canvas, which a unit test does not have.
*/
@implementation RowContentOutlineView : CPOutlineView
{
    CPArray     drawnSteps      @accessors;
    CPArray     drawnRows       @accessors;
    CPArray     drawnClipRects  @accessors;
}

- (void)drawBackgroundInClipRect:(CGRect)aRect
{
    [drawnSteps addObject:@"background"];
}

- (void)highlightSelectionInClipRect:(CGRect)aRect
{
    [drawnSteps addObject:@"selection"];
}

- (void)drawGridInClipRect:(CGRect)aRect
{
    [drawnSteps addObject:@"grid"];
}

- (void)drawRow:(CPInteger)aRow clipRect:(CGRect)aRect
{
    [drawnRows addObject:aRow];
    [drawnClipRects addObject:aRect];
}

@end

@implementation CPOutlineViewRowContentTest : OJTestCase
{
    CPWindow                theWindow;
    CPScrollView            scrollView;
    RowContentOutlineView   outlineView;
    CPTableColumn           firstColumn;
    CPTableColumn           secondColumn;
    CPArray                 rootItems;
    CPView                  drawingView;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 400.0) styleMask:CPWindowNotSizable];

    rootItems = [];

    for (var index = 0; index < 40; index++)
    {
        var children = [[RowContentItem itemWithTitle:@"Child A" children:[]],
                        [RowContentItem itemWithTitle:@"Child B" children:[]]];

        rootItems.push([RowContentItem itemWithTitle:@"Item" children:children]);
    }

    firstColumn = [[CPTableColumn alloc] initWithIdentifier:@"First"];
    secondColumn = [[CPTableColumn alloc] initWithIdentifier:@"Second"];

    outlineView = [[RowContentOutlineView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 200.0)];
    [outlineView setDrawnSteps:[]];
    [outlineView setDrawnRows:[]];
    [outlineView setDrawnClipRects:[]];
    [outlineView addTableColumn:firstColumn];
    [outlineView addTableColumn:secondColumn];
    [outlineView setOutlineTableColumn:firstColumn];

    scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 200.0)];
    [scrollView setDocumentView:outlineView];
    [[theWindow contentView] addSubview:scrollView];

    [outlineView setDataSource:self];
    [outlineView reloadData];

    [self settle];
}

- (id)outlineView:(CPOutlineView)anOutlineView child:(CPInteger)anIndex ofItem:(id)anItem
{
    return anItem ? [anItem children][anIndex] : rootItems[anIndex];
}

- (BOOL)outlineView:(CPOutlineView)anOutlineView isItemExpandable:(id)anItem
{
    return [[anItem children] count] > 0;
}

- (int)outlineView:(CPOutlineView)anOutlineView numberOfChildrenOfItem:(id)anItem
{
    return anItem ? [[anItem children] count] : rootItems.length;
}

- (id)outlineView:(CPOutlineView)anOutlineView objectValueForTableColumn:(CPTableColumn)aColumn byItem:(id)anItem
{
    return [anItem title];
}

/*
    The views that make up the table: the outline view and its subviews. Controls
    are left out. Data views and disclosure buttons draw themselves, and they need
    a canvas to do so.
*/
- (CPArray)tableViews
{
    return [outlineView].concat([outlineView subviews].filter(function(aView)
    {
        return ![aView isKindOfClass:[CPControl class]];
    }));
}

/*
    Brings the table to rest, as the end of a display cycle does: the layout is
    current, nothing is waiting to draw, and nothing has been recorded.
*/
- (void)settle
{
    [outlineView layoutIfNeeded];
    [[self tableViews] makeObjectsPerformSelector:@selector(displayIfNeeded)];

    [[outlineView drawnSteps] removeAllObjects];
    [[outlineView drawnRows] removeAllObjects];
    [[outlineView drawnClipRects] removeAllObjects];
}

/*
    CPView does not draw without a DOM, so the display cycle cannot reach drawRect:
    in a unit test. This does its work: it lays the table out, then sends drawRect:
    to each view that has been marked for display, and only to those.
*/
- (void)redraw
{
    [outlineView layoutIfNeeded];

    var graphicsPort = { path: NULL, gState: CGGStateCreate(), gStateStack: [] };

    [CPGraphicsContext setCurrentContext:[CPGraphicsContext graphicsContextWithGraphicsPort:graphicsPort flipped:YES]];

    drawingView = nil;

    [self tableViews].forEach(function(aView)
    {
        if (![aView needsDisplay])
            return;

        var rowCount = [[outlineView drawnRows] count];

        [aView drawRect:[aView bounds]];

        if ([[outlineView drawnRows] count] > rowCount)
            drawingView = aView;
    });
}

/*
    A badge has to remain visible, including on a selected or alternating row. So the
    view that draws the row content must stay in front of anything that paints a row.
    Only controls may sit in front of it. Without a DOM a subview may not yet have
    its colors, so this does not look at colors. It looks at what is in front.
*/
- (void)assertNothingCoversRowContent:(CPString)anAction
{
    var subviews = [outlineView subviews],
        firstCovering = drawingView === outlineView ? 0 : [subviews indexOfObject:drawingView] + 1;

    for (var index = firstCovering; index < [subviews count]; index++)
    {
        var aView = subviews[index];

        if ([aView isKindOfClass:[CPControl class]] || [aView isHidden])
            continue;

        [self fail:anAction + ": " + [aView className] + " covers the row content"];
    }
}

- (CPArray)rowsOnScreen
{
    var range = [outlineView rowsInRect:[outlineView exposedRect]],
        rows = [];

    for (var row = range.location; row < CPMaxRange(range); row++)
        rows.push(row);

    return rows;
}

/*
    The table has been redrawn through each of its drawing steps, for exactly the
    rows on screen, and each row was asked to draw only within the visible part of
    the table.
*/
- (void)assertRowContentIsCurrentAfter:(CPString)anAction
{
    [self redraw];

    var rows = [self rowsOnScreen],
        exposedRect = [outlineView exposedRect];

    [self assert:[@"background", @"selection", @"grid"] equals:[outlineView drawnSteps] message:anAction];
    [self assert:rows equals:[outlineView drawnRows] message:anAction];

    [outlineView drawnClipRects].forEach(function(aRect)
    {
        [self assertTrue:CGRectContainsRect(exposedRect, aRect) message:anAction + ": clip rect is outside the visible area"];
    });

    [self assertNothingCoversRowContent:anAction];
}

/*
    Redrawing costs time, and a table can be large. A table with nothing to change
    has nothing to draw.
*/
- (void)testNothingIsRedrawnWithoutAChange
{
    [self redraw];

    [self assert:[] equals:[outlineView drawnSteps]];
    [self assert:[] equals:[outlineView drawnRows]];
}

- (void)testContentIsDrawnWhenTheOutlineFirstAppears
{
    [outlineView setNeedsDisplay:YES];

    [self assertRowContentIsCurrentAfter:@"first display"];
}

- (void)testContentIsRedrawnAfterSelectingARow
{
    [outlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:2] byExtendingSelection:NO];

    [self assertRowContentIsCurrentAfter:@"selecting a row"];
}

- (void)testContentIsRedrawnAfterChangingTheSelection
{
    [outlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:2] byExtendingSelection:NO];
    [self settle];

    [outlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:4] byExtendingSelection:NO];

    [self assertRowContentIsCurrentAfter:@"changing the selection"];
}

- (void)testContentIsRedrawnAfterClearingTheSelection
{
    [outlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:2] byExtendingSelection:NO];
    [self settle];

    [outlineView deselectAll:nil];

    [self assertRowContentIsCurrentAfter:@"clearing the selection"];
}

- (void)testContentIsRedrawnAfterSelectingAColumn
{
    [outlineView selectColumnIndexes:[CPIndexSet indexSetWithIndex:1] byExtendingSelection:NO];

    [self assertRowContentIsCurrentAfter:@"selecting a column"];
}

- (void)testContentIsRedrawnAfterChangingTheGridStyle
{
    [outlineView setGridStyleMask:CPTableViewSolidVerticalGridLineMask];

    [self assertRowContentIsCurrentAfter:@"changing the grid style"];
}

- (void)testContentIsRedrawnAfterChangingTheGridColor
{
    [outlineView setGridColor:[CPColor redColor]];

    [self assertRowContentIsCurrentAfter:@"changing the grid color"];
}

- (void)testContentIsRedrawnAfterChangingTheRowColors
{
    [outlineView setAlternatingRowBackgroundColors:[[CPColor redColor], [CPColor blueColor]]];

    [self assertRowContentIsCurrentAfter:@"changing the row colors"];
}

- (void)testContentIsRedrawnAfterChangingTheHighlightStyle
{
    [outlineView setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleNone];

    [self assertRowContentIsCurrentAfter:@"changing the highlight style"];
}

- (void)testContentIsRedrawnAfterReloadingTheData
{
    [outlineView reloadData];

    [self assertRowContentIsCurrentAfter:@"reloading the data"];
}

- (void)testContentIsRedrawnForTheNewRowsAfterScrolling
{
    var firstRows = [self rowsOnScreen];

    [[scrollView contentView] scrollToPoint:CGPointMake(0.0, 300.0)];

    [self assertFalse:[firstRows isEqual:[self rowsOnScreen]] message:@"scrolling must change the rows on screen"];
    [self assertRowContentIsCurrentAfter:@"scrolling"];
}

- (void)testContentIsRedrawnAfterResizingAColumn
{
    [secondColumn setWidth:40.0];

    [self assertRowContentIsCurrentAfter:@"resizing a column"];
}

- (void)testContentIsRedrawnAfterHidingAColumn
{
    [secondColumn setHidden:YES];

    [self assertRowContentIsCurrentAfter:@"hiding a column"];
}

- (void)testContentIsRedrawnAfterExpandingAnItem
{
    [outlineView expandItem:rootItems[1]];

    [self assertRowContentIsCurrentAfter:@"expanding an item"];
}

- (void)testContentIsRedrawnAfterCollapsingAnItem
{
    [outlineView expandItem:rootItems[1]];
    [self settle];

    [outlineView collapseItem:rootItems[1]];

    [self assertRowContentIsCurrentAfter:@"collapsing an item"];
}

@end
