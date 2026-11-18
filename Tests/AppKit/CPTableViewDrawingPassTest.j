/*
 *  CPTableViewDrawingPassTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-17.
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
    A table view draws its standard look with views: each row view draws its row, and the
    table view draws the column selection and the vertical grid lines. A subclass that
    overrides one of the four old drawing methods gets a canvas: the table view calls the
    overridden method and the methods of the layers in front of it, background, selection,
    grid, rows, once for each display, and the views stop drawing those layers.

    A row view subclass that overrides a draw method draws on a canvas too, with AppKit's
    order and conditions.

    Unit tests run without a DOM, so these tests observe which methods run and which views
    show, not what they draw.
*/

var DrawingPassRecord = nil;

@implementation DrawingPassBackgroundTableView : CPTableView
- (void)drawBackgroundInClipRect:(CGRect)aRect
{
    DrawingPassRecord.push(@"background");
}
@end

@implementation DrawingPassSelectionTableView : CPTableView
- (void)highlightSelectionInClipRect:(CGRect)aRect
{
    DrawingPassRecord.push(@"selection");
}
@end

@implementation DrawingPassGridTableView : CPTableView
- (void)drawGridInClipRect:(CGRect)aRect
{
    DrawingPassRecord.push(@"grid");
}
@end

@implementation DrawingPassRowTableView : CPTableView
- (void)drawRow:(CPInteger)aRow clipRect:(CGRect)aRect
{
    DrawingPassRecord.push(@"row " + aRow);
}
@end

/*
    Records the calls of the four draw methods, in place of drawing.
*/
@implementation DrawingPassRecordingRowView : CPTableRowView

- (void)drawBackgroundInRect:(CGRect)aRect
{
    DrawingPassRecord.push(@"background");
}

- (void)drawSelectionInRect:(CGRect)aRect
{
    DrawingPassRecord.push(@"selection");
}

- (void)drawSeparatorInRect:(CGRect)aRect
{
    DrawingPassRecord.push(@"separator");
}

- (void)drawDraggingDestinationFeedbackInRect:(CGRect)aRect
{
    DrawingPassRecord.push(@"drop");
}

@end

/*
    Overrides one draw method. The other three draw the standard look.
*/
@implementation DrawingPassSeparatorRowView : CPTableRowView
- (void)drawSeparatorInRect:(CGRect)aRect
{
    DrawingPassRecord.push(@"separator");
}
@end


@implementation CPTableViewDrawingPassTest : OJTestCase
{
    CPWindow        theWindow;
    CPTableView     tableView;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 400.0) styleMask:CPWindowNotSizable];
    DrawingPassRecord = [];

    [self useTableViewOfClass:[CPTableView class]];
}

/*
    Replaces the table view with one of aClass: 200 points square, with two columns and three
    rows, laid out.
*/
- (void)useTableViewOfClass:(Class)aClass
{
    [tableView removeFromSuperview];

    tableView = [[aClass alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 200.0)];

    var first = [[CPTableColumn alloc] initWithIdentifier:@"First"],
        second = [[CPTableColumn alloc] initWithIdentifier:@"Second"];

    [first setWidth:80.0];
    [second setWidth:80.0];
    [tableView addTableColumn:first];
    [tableView addTableColumn:second];
    [tableView setDataSource:self];

    [[theWindow contentView] addSubview:tableView];
    [tableView reloadData];
    [self settle];
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
    Brings the table view to rest, as the end of a display cycle does: the table view and its
    row views are laid out, nothing is marked for display, and nothing is recorded.
*/
- (void)settle
{
    [tableView layoutIfNeeded];
    [[tableView subviews] makeObjectsPerformSelector:@selector(layoutIfNeeded)];
    [self drawMarkedViews];

    DrawingPassRecord = [];
}

/*
    The subviews of the table view that are not controls. Data views draw themselves and need
    a canvas to do so.
*/
- (CPArray)tableSubviews
{
    return [tableView subviews].filter(function(aView)
    {
        return ![aView isKindOfClass:[CPControl class]];
    });
}

/*
    CPView does not draw without a DOM, so the display cycle cannot reach drawRect: here. This
    sends drawRect: to each subview that is marked for display, then displays it, which clears
    the mark. The graphics port has no backing store.
*/
- (void)drawMarkedViews
{
    var graphicsPort = { path: NULL, gState: CGGStateCreate(), gStateStack: [] };

    [CPGraphicsContext setCurrentContext:[CPGraphicsContext graphicsContextWithGraphicsPort:graphicsPort flipped:YES]];

    [self tableSubviews].forEach(function(aView)
    {
        if (![aView needsDisplay])
            return;

        [aView drawRect:[aView bounds]];
        [aView displayIfNeeded];
    });
}

- (CPView)canvasView
{
    var subviews = [tableView subviews];

    for (var i = 0; i < [subviews count]; i++)
        if ([subviews[i] isKindOfClass:[_CPTableDrawView class]])
            return subviews[i];

    return nil;
}

- (CPArray)visibleGridLineViews
{
    var decorationView = nil,
        subviews = [tableView subviews];

    for (var i = 0; i < [subviews count]; i++)
        if ([subviews[i] isKindOfClass:[_CPTableDecorationView class]])
            decorationView = subviews[i];

    return [decorationView subviews].filter(function(aView)
    {
        return ![aView isHidden] && CGRectGetWidth([aView frame]) < CGRectGetHeight([aView frame]);
    });
}

// MARK: The drawing pass

- (void)testATableViewWithoutAnOverrideHasNoCanvas
{
    [self assertNull:[self canvasView]];
}

- (void)testATableViewWithoutAnOverrideMarksNothingForDisplay
{
    [tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
    [tableView setGridStyleMask:CPTableViewSolidHorizontalGridLineMask];
    [tableView layoutIfNeeded];

    [self tableSubviews].forEach(function(aView)
    {
        [self assertFalse:[aView needsDisplay] message:[aView className] + " is marked for display"];
    });
}

- (void)testAnOverrideOfTheBackgroundCallsEveryLayer
{
    [self useTableViewOfClass:[DrawingPassBackgroundTableView class]];

    [tableView setNeedsDisplay:YES];
    [self drawMarkedViews];

    [self assert:[@"background"] equals:DrawingPassRecord];
    [self assert:15 equals:[DrawingPassBackgroundTableView _drawingPassLayers] message:@"background, selection, grid and rows"];
}

- (void)testAnOverrideOfTheSelectionCallsTheSelectionGridAndRows
{
    [self useTableViewOfClass:[DrawingPassSelectionTableView class]];

    [tableView setNeedsDisplay:YES];
    [self drawMarkedViews];

    [self assert:[@"selection"] equals:DrawingPassRecord];
    [self assert:14 equals:[DrawingPassSelectionTableView _drawingPassLayers] message:@"selection, grid and rows"];
}

- (void)testAnOverrideOfTheGridCallsTheGridAndRows
{
    [self useTableViewOfClass:[DrawingPassGridTableView class]];

    [tableView setNeedsDisplay:YES];
    [self drawMarkedViews];

    [self assert:[@"grid"] equals:DrawingPassRecord];
    [self assert:12 equals:[DrawingPassGridTableView _drawingPassLayers] message:@"grid and rows"];
}

- (void)testAnOverrideOfDrawRowCallsTheRowsOnly
{
    [self useTableViewOfClass:[DrawingPassRowTableView class]];

    [tableView setNeedsDisplay:YES];
    [self drawMarkedViews];

    [self assert:[@"row 0", @"row 1", @"row 2"] equals:DrawingPassRecord];
    [self assert:8 equals:[DrawingPassRowTableView _drawingPassLayers] message:@"rows"];
}

/*
    The canvas lies in front of the row views, so a layer that the canvas does not draw stays
    with the views. An override of drawRow:clipRect: keeps the vertical grid lines as views;
    an override of the grid draws them on the canvas.
*/
- (void)testAnOverrideOfDrawRowKeepsTheGridLinesAsViews
{
    [self useTableViewOfClass:[DrawingPassRowTableView class]];

    [tableView setGridStyleMask:CPTableViewSolidVerticalGridLineMask];
    [tableView setGridColor:[CPColor redColor]];
    [tableView layoutIfNeeded];

    [self assert:2 equals:[[self visibleGridLineViews] count]];
}

- (void)testAnOverrideOfTheGridDrawsTheGridLinesOnTheCanvas
{
    [self useTableViewOfClass:[DrawingPassGridTableView class]];

    [tableView setGridStyleMask:CPTableViewSolidVerticalGridLineMask];
    [tableView setGridColor:[CPColor redColor]];
    [tableView layoutIfNeeded];

    [self assert:0 equals:[[self visibleGridLineViews] count]];
}

- (void)testATableViewWithoutAnOverrideDrawsTheGridLinesAsViews
{
    [tableView setGridStyleMask:CPTableViewSolidVerticalGridLineMask];
    [tableView setGridColor:[CPColor redColor]];
    [tableView layoutIfNeeded];

    [self assert:2 equals:[[self visibleGridLineViews] count]];
}

// MARK: Row view state

/*
    The table view sets the state of its row views. The look signal, setNeedsDisplay:, gives
    every visible row view the state again and marks it for layout.
*/
- (void)testTheRowViewsShowTheStateOfTheTableViewAfterLayout
{
    [tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
    [tableView setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleSourceList];
    [tableView layoutIfNeeded];

    var rowView = [tableView rowViewAtRow:1 makeIfNecessary:NO];

    [self assertTrue:[rowView isSelected]];
    [self assertFalse:[rowView isEmphasized] message:@"the table view does not have the focus"];
    [self assert:CPTableViewSelectionHighlightStyleSourceList equals:[rowView selectionHighlightStyle]];
    [self assertTrue:[[tableView rowViewAtRow:0 makeIfNecessary:NO] isNextRowSelected]];
}

- (void)testAGridChangeMarksTheRowViewsForLayout
{
    [[tableView subviews] makeObjectsPerformSelector:@selector(layoutIfNeeded)];

    var rowView = [tableView rowViewAtRow:1 makeIfNecessary:NO];

    [self assertFalse:[rowView needsLayout]];

    [tableView setGridStyleMask:CPTableViewSolidHorizontalGridLineMask];

    [self assertTrue:[rowView needsLayout]];
    [self assertTrue:[tableView needsLayout]];
}

/*
    A setter writes no look. The row view writes its look in its layout, under its effective
    appearance.
*/
- (void)testARowViewWritesItsBackgroundInItsLayoutOnly
{
    var colors = [[CPColor redColor], [CPColor greenColor]];

    [[tableView subviews] makeObjectsPerformSelector:@selector(layoutIfNeeded)];

    var rowView = [tableView rowViewAtRow:1 makeIfNecessary:NO],
        writtenColor = rowView._backgroundColor;

    [tableView setAlternatingRowBackgroundColors:colors];
    [tableView setUsesAlternatingRowBackgroundColors:YES];

    [self assert:colors[1] equals:[rowView backgroundColor] message:@"the state is current at once"];
    [self assert:writtenColor same:rowView._backgroundColor message:@"nothing is written before the layout"];

    [rowView layoutIfNeeded];

    [self assert:colors[1] equals:rowView._backgroundColor];
}

/*
    The group row colour applies outside the source-list style only.
*/
- (void)testAGroupRowHasTheGroupColorOutsideTheSourceListStyle
{
    var color = [CPColor blueColor],
        state = nil;

    [tableView setValue:color forThemeAttribute:@"group-row-background-color"];
    [tableView setDelegate:self];

    state = [tableView _tableRowStateForRow:1];
    [self assert:color equals:state.defaultBackgroundColor];

    [tableView setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleSourceList];

    state = [tableView _tableRowStateForRow:1];
    [self assertNull:state.defaultBackgroundColor];
}

- (BOOL)tableView:(CPTableView)aTableView isGroupRow:(CPInteger)aRow
{
    return aRow === 1;
}

// MARK: Row views that draw on a canvas

- (void)testARowViewOfTheBaseClassTakesNoDisplayMarks
{
    var rowView = [[CPTableRowView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 20.0)];

    [rowView setNeedsDisplay:YES];

    [self assertFalse:[rowView needsDisplay]];
}

- (void)testARowViewThatOverridesOneDrawMethodDrawsOnACanvas
{
    var rowView = [[DrawingPassSeparatorRowView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 20.0)];

    [rowView setNeedsDisplay:YES];

    [self assertTrue:[rowView needsDisplay]];
}

/*
    drawRect: calls the background, then the selection for a selected row, then the separator
    when the grid has horizontal lines, then the feedback for a drop on the row.
*/
- (void)testARowViewDrawsItsPartsInAppKitOrder
{
    var rowView = [[DrawingPassRecordingRowView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 20.0)];

    [rowView _setTableView:tableView];
    [tableView setGridStyleMask:CPTableViewSolidHorizontalGridLineMask];
    [rowView setSelected:YES];
    [rowView setTargetForDropOperation:YES];

    [rowView drawRect:[rowView bounds]];

    [self assert:[@"background", @"selection", @"separator", @"drop"] equals:DrawingPassRecord];
}

- (void)testARowViewDrawsOnlyThePartsThatApply
{
    var rowView = [[DrawingPassRecordingRowView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 20.0)];

    [rowView _setTableView:tableView];
    [tableView setGridStyleMask:CPTableViewGridNone];
    [rowView setSelected:YES];
    [rowView setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleNone];

    [rowView drawRect:[rowView bounds]];

    [self assert:[@"background"] equals:DrawingPassRecord];
}

@end
