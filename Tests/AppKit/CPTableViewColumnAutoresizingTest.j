/*
 *  CPTableViewColumnAutoresizingTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-24.
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
    A table view in a scroll view resizes its columns by its column autoresizing style when its
    own width changes, as NSTableView does. The table view is as wide as the clip view, or as
    wide as its columns when they are wider, and the change in that width goes to the columns:

    - no column autoresizing: no column changes;
    - uniform: each autoresizable column takes an equal share at the same time;
    - sequential: the last autoresizable column takes the change until it reaches its minimum
      or maximum width, then the column before it, and so on to the first;
    - reverse sequential: the same from the first autoresizable column to the last;
    - last column only: the last column takes the change until it reaches its minimum or
      maximum width, then autoresizing stops;
    - first column only: the same with the first column.

    A column is autoresizable when it is visible and its resizing mask includes
    CPTableColumnAutoresizingMask. The default style is last column only.

    When the user resizes a column, the columns after it take the opposite change by the same
    style, so the columns keep their total width where they can. What they cannot take changes
    the total width. The tests resize the column as the header view does, then give the change
    to the columns after it.

    -sizeLastColumnToFit makes the last column end at the edge of the clip view, and
    -sizeToFit gives the columns equal widths, within their maximum widths, so that all of
    them are visible.

    The row views span the table view after every change. The scroll view has no scrollers and
    no border, so the clip view is as wide as the scroll view.
*/
@implementation CPTableViewColumnAutoresizingTest : OJTestCase
{
    CPWindow        theWindow;
    CPScrollView    scrollView;
    CPTableView     tableView;
    CPArray         columns;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 600.0, 400.0) styleMask:CPWindowNotSizable];

    scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 200.0)];
    [scrollView setBorderType:CPNoBorder];
    [scrollView setHasVerticalScroller:NO];
    [scrollView setHasHorizontalScroller:NO];

    tableView = [[CPTableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 200.0)];
    columns = [];

    for (var i = 0; i < 3; i++)
    {
        var column = [[CPTableColumn alloc] initWithIdentifier:@"Column" + i];

        [column setWidth:50.0];
        [tableView addTableColumn:column];
        columns.push(column);
    }

    [tableView setDataSource:[[_ColumnAutoresizingTestDataSource alloc] init]];
    [tableView setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];

    [scrollView setDocumentView:tableView];
    [[theWindow contentView] addSubview:scrollView];

    [self layOut];
}

/*
    Reloads the table view and lays it out, as the display cycle does.
*/
- (void)layOut
{
    [tableView reloadData];
    [tableView load];
}

- (void)setScrollViewWidth:(float)aWidth
{
    [scrollView setFrameSize:CGSizeMake(aWidth, CGRectGetHeight([scrollView frame]))];
    [tableView load];
}

- (float)clipWidth
{
    return CGRectGetWidth([[scrollView contentView] bounds]);
}

- (float)spacing
{
    return [tableView intercellSpacing].width;
}

- (float)maxXOfColumn:(CPInteger)anIndex
{
    return CGRectGetMaxX([tableView rectOfColumn:anIndex]);
}

/*
    Sets the style and gives the columns equal widths that together fill the clip view, 97
    points each with the default spacing.
*/
- (float)fillWithEqualColumnsForStyle:(unsigned)aStyle
{
    [tableView setColumnAutoresizingStyle:aStyle];

    var width = [self clipWidth] / 3 - [self spacing];

    for (var i = 0; i < 3; i++)
        [columns[i] setWidth:width];

    [tableView tile];
    [tableView load];

    return width;
}

/*
    Resizes the column at anIndex to aWidth as the user does with the header view: the columns
    after it take the opposite change.
*/
- (void)userResizeColumn:(CPInteger)anIndex toWidth:(float)aWidth
{
    var oldWidth = [columns[anIndex] width];

    [columns[anIndex] setWidth:aWidth];
    [tableView _autoresizeColumnsAfterColumn:anIndex byWidth:oldWidth - [columns[anIndex] width]];
    [tableView load];
}

- (void)assertWidths:(CPArray)someWidths message:(CPString)aMessage
{
    for (var i = 0; i < 3; i++)
        [self assert:someWidths[i] equals:[columns[i] width] message:aMessage + @": width of column " + i];
}

- (void)assertRowViewsSpanTheTableView:(CPString)aMessage
{
    var tableWidth = CGRectGetWidth([tableView bounds]);

    for (var row = 0; row < 5; row++)
    {
        var rowView = [tableView rowViewAtRow:row makeIfNecessary:NO];

        [self assertTrue:rowView !== nil message:aMessage + @": row " + row + @" has a row view"];
        [self assert:tableWidth equals:CGRectGetWidth([rowView frame]) message:aMessage + @": width of the row view of row " + row];
    }
}

// MARK: - Default

- (void)testTheDefaultStyleIsLastColumnOnly
{
    [self assert:CPTableViewLastColumnOnlyAutoresizingStyle equals:[[[CPTableView alloc] initWithFrame:CGRectMakeZero()] columnAutoresizingStyle]];
}

// MARK: - The width of the table view

- (void)testTheTableViewFillsTheClipViewWhenItsColumnsAreNarrower
{
    [self assert:[self clipWidth] equals:CGRectGetWidth([tableView frame]) message:@"the table view is as wide as the clip view"];
    [self assertRowViewsSpanTheTableView:@"with columns narrower than the clip view"];
}

/*
    Autoresizing applies the change in width; it does not fill the clip view. The last column
    of columns narrower than the clip view grows by the change, and the space after it stays.
*/
- (void)testAutoresizingAppliesTheChangeInWidth
{
    [self setScrollViewWidth:400.0];

    [self assertWidths:[50.0, 50.0, 150.0] message:@"after the clip view grows by 100 points"];
}

// MARK: - No column autoresizing

- (void)testNoColumnAutoresizingKeepsTheColumnWidths
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewNoColumnAutoresizing];

    [self setScrollViewWidth:360.0];
    [self assertWidths:[width, width, width] message:@"after the clip view grows"];
    [self assert:360.0 equals:CGRectGetWidth([tableView frame]) message:@"the table view is as wide as the clip view"];

    [self setScrollViewWidth:240.0];
    [self assertWidths:[width, width, width] message:@"after the clip view shrinks"];
    [self assert:300.0 equals:CGRectGetWidth([tableView frame]) message:@"the table view is as wide as its columns"];
}

// MARK: - Uniform

- (void)testUniformResizingSharesAGrowthEqually
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewUniformColumnAutoresizingStyle];

    [self setScrollViewWidth:330.0];

    [self assertWidths:[width + 10.0, width + 10.0, width + 10.0] message:@"after the clip view grows by 30 points"];
    [self assert:330.0 equals:[self maxXOfColumn:2] message:@"the columns fill the clip view"];
}

- (void)testUniformResizingSharesAShrinkEqually
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewUniformColumnAutoresizingStyle];

    [self setScrollViewWidth:270.0];

    [self assertWidths:[width - 10.0, width - 10.0, width - 10.0] message:@"after the clip view shrinks by 30 points"];
    [self assert:270.0 equals:[self maxXOfColumn:2] message:@"the columns fill the clip view"];
}

- (void)testUniformResizingGivesTheShareOfAColumnAtItsMaximumToTheOthers
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewUniformColumnAutoresizingStyle];

    [columns[0] setMaxWidth:width + 6.0];
    [self setScrollViewWidth:336.0];

    [self assertWidths:[width + 6.0, width + 15.0, width + 15.0] message:@"after the clip view grows by 36 points"];
    [self assert:336.0 equals:[self maxXOfColumn:2] message:@"the columns fill the clip view"];
}

- (void)testUniformResizingLeavesAColumnWithoutTheAutoresizingMask
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewUniformColumnAutoresizingStyle];

    [columns[1] setResizingMask:CPTableColumnUserResizingMask];
    [self setScrollViewWidth:330.0];

    [self assertWidths:[width + 15.0, width, width + 15.0] message:@"after the clip view grows by 30 points"];
}

- (void)testUniformResizingThroughNoWidthRestoresTheColumns
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewUniformColumnAutoresizingStyle];

    [self setScrollViewWidth:0.0];
    [self setScrollViewWidth:300.0];

    [self assertWidths:[width, width, width] message:@"after a resize through no width"];
}

// MARK: - Sequential

- (void)testSequentialResizingGrowsFromTheLastColumn
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewSequentialColumnAutoresizingStyle];

    [columns[2] setMaxWidth:width + 20.0];
    [self setScrollViewWidth:360.0];

    [self assertWidths:[width, width + 40.0, width + 20.0] message:@"after the clip view grows by 60 points"];
    [self assert:360.0 equals:[self maxXOfColumn:2] message:@"the columns fill the clip view"];
}

- (void)testSequentialResizingShrinksFromTheLastColumn
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewSequentialColumnAutoresizingStyle];

    [columns[2] setMinWidth:width - 20.0];
    [self setScrollViewWidth:240.0];

    [self assertWidths:[width, width - 40.0, width - 20.0] message:@"after the clip view shrinks by 60 points"];
    [self assert:240.0 equals:[self maxXOfColumn:2] message:@"the columns fill the clip view"];
}

- (void)testSequentialResizingSkipsAHiddenColumn
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewSequentialColumnAutoresizingStyle];

    [columns[2] setHidden:YES];
    [tableView tile];
    [self setScrollViewWidth:360.0];

    [self assertWidths:[width, width + 60.0, width] message:@"after the clip view grows by 60 points, with the last column hidden"];
}

// MARK: - Reverse sequential

- (void)testReverseSequentialResizingGrowsFromTheFirstColumn
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewReverseSequentialColumnAutoresizingStyle];

    [columns[0] setMaxWidth:width + 20.0];
    [self setScrollViewWidth:360.0];

    [self assertWidths:[width + 20.0, width + 40.0, width] message:@"after the clip view grows by 60 points"];
    [self assert:360.0 equals:[self maxXOfColumn:2] message:@"the columns fill the clip view"];
}

- (void)testReverseSequentialResizingShrinksFromTheFirstColumn
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewReverseSequentialColumnAutoresizingStyle];

    [columns[0] setMinWidth:width - 20.0];
    [self setScrollViewWidth:240.0];

    [self assertWidths:[width - 20.0, width - 40.0, width] message:@"after the clip view shrinks by 60 points"];
    [self assert:240.0 equals:[self maxXOfColumn:2] message:@"the columns fill the clip view"];
}

// MARK: - Last column only

- (void)testSizeLastColumnToFitFillsTheClipView
{
    [tableView sizeLastColumnToFit];

    [self assert:[self clipWidth] equals:[self maxXOfColumn:2] message:@"the last column ends at the edge of the clip view"];
    [self assert:50.0 equals:[columns[0] width] message:@"the first column keeps its width"];
    [self assert:50.0 equals:[columns[1] width] message:@"the second column keeps its width"];
    [self assert:[self clipWidth] equals:CGRectGetWidth([tableView frame]) message:@"the table view is as wide as the clip view"];
}

- (void)testSizeLastColumnToFitUsesTheLastVisibleColumn
{
    [columns[2] setHidden:YES];
    [tableView sizeLastColumnToFit];

    [self assert:[self clipWidth] equals:[self maxXOfColumn:1] message:@"the second column ends at the edge of the clip view"];
    [self assert:50.0 equals:[columns[0] width] message:@"the first column keeps its width"];
}

- (void)testTheLastColumnGrowsWithTheClipView
{
    [tableView sizeLastColumnToFit];
    [self setScrollViewWidth:400.0];

    [self assert:400.0 equals:[self maxXOfColumn:2] message:@"the last column ends at the edge of the clip view"];
    [self assert:50.0 equals:[columns[0] width] message:@"the first column keeps its width"];
    [self assert:50.0 equals:[columns[1] width] message:@"the second column keeps its width"];
}

- (void)testTheLastColumnShrinksWithTheClipView
{
    [tableView sizeLastColumnToFit];
    [self setScrollViewWidth:250.0];

    [self assert:250.0 equals:[self maxXOfColumn:2] message:@"the last column ends at the edge of the clip view"];
    [self assert:50.0 equals:[columns[0] width] message:@"the first column keeps its width"];
    [self assert:50.0 equals:[columns[1] width] message:@"the second column keeps its width"];
}

- (void)testTheLastColumnStopsAtItsMinimumWidth
{
    [columns[2] setMinWidth:40.0];
    [tableView sizeLastColumnToFit];
    [self setScrollViewWidth:100.0];

    [self assert:40.0 equals:[columns[2] width] message:@"the last column keeps its minimum width"];
    [self assert:50.0 equals:[columns[0] width] message:@"the first column keeps its width"];
    [self assert:[self maxXOfColumn:2] equals:CGRectGetWidth([tableView frame]) message:@"the table view is as wide as its columns, wider than the clip view"];
}

- (void)testTheLastColumnStopsAtItsMaximumWidth
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewLastColumnOnlyAutoresizingStyle];

    [columns[2] setMaxWidth:width + 20.0];
    [self setScrollViewWidth:360.0];

    [self assertWidths:[width, width, width + 20.0] message:@"after the clip view grows by 60 points"];
    [self assert:360.0 equals:CGRectGetWidth([tableView frame]) message:@"the table view is as wide as the clip view"];
}

- (void)testTheLastColumnFillsTheClipViewAgainAfterItsMinimumWidth
{
    [columns[2] setMinWidth:40.0];
    [tableView sizeLastColumnToFit];
    [self setScrollViewWidth:100.0];
    [self setScrollViewWidth:350.0];

    [self assert:350.0 equals:[self maxXOfColumn:2] message:@"the last column ends at the edge of the clip view"];
    [self assert:350.0 equals:CGRectGetWidth([tableView frame]) message:@"the table view is as wide as the clip view"];
}

- (void)testAResizeThroughNoWidthRestoresTheColumns
{
    [tableView sizeLastColumnToFit];

    var widths = [[columns[0] width], [columns[1] width], [columns[2] width]];

    [self setScrollViewWidth:0.0];
    [self setScrollViewWidth:300.0];

    [self assertWidths:widths message:@"after a resize through no width"];
    [self assert:300.0 equals:[self maxXOfColumn:2] message:@"the last column ends at the edge of the clip view"];
}

// MARK: - First column only

- (void)testFirstColumnOnlyResizingGivesTheGrowthToTheFirstColumn
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewFirstColumnOnlyAutoresizingStyle];

    [self setScrollViewWidth:360.0];

    [self assertWidths:[width + 60.0, width, width] message:@"after the clip view grows by 60 points"];
    [self assert:360.0 equals:[self maxXOfColumn:2] message:@"the columns fill the clip view"];
}

- (void)testTheFirstColumnStopsAtItsMinimumWidth
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewFirstColumnOnlyAutoresizingStyle];

    [columns[0] setMinWidth:width - 20.0];
    [self setScrollViewWidth:240.0];

    [self assertWidths:[width - 20.0, width, width] message:@"after the clip view shrinks by 60 points"];
    [self assert:280.0 equals:CGRectGetWidth([tableView frame]) message:@"the table view is as wide as its columns"];
}

// MARK: - Resizing a column by the user

- (void)testAUserResizeWithNoColumnAutoresizingChangesTheTotalWidth
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewNoColumnAutoresizing];

    [self userResizeColumn:0 toWidth:width - 20.0];

    [self assertWidths:[width - 20.0, width, width] message:@"after the first column shrinks by 20 points"];
    [self assert:280.0 equals:[self maxXOfColumn:2] message:@"the columns end 20 points before the edge"];
}

- (void)testAUserResizeWithUniformResizingSharesTheChangeAfterTheColumn
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewUniformColumnAutoresizingStyle];

    [self userResizeColumn:0 toWidth:width - 20.0];

    [self assertWidths:[width - 20.0, width + 10.0, width + 10.0] message:@"after the first column shrinks by 20 points"];
    [self assert:300.0 equals:[self maxXOfColumn:2] message:@"the columns fill the clip view"];
}

- (void)testAUserResizeWithSequentialResizingStartsAtTheLastColumn
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewSequentialColumnAutoresizingStyle];

    [columns[2] setMaxWidth:width + 5.0];
    [self userResizeColumn:0 toWidth:width - 20.0];

    [self assertWidths:[width - 20.0, width + 15.0, width + 5.0] message:@"after the first column shrinks by 20 points"];
    [self assert:300.0 equals:[self maxXOfColumn:2] message:@"the columns fill the clip view"];
}

- (void)testAUserResizeWithReverseSequentialResizingStartsAtTheNextColumn
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewReverseSequentialColumnAutoresizingStyle];

    [columns[1] setMaxWidth:width + 5.0];
    [self userResizeColumn:0 toWidth:width - 20.0];

    [self assertWidths:[width - 20.0, width + 5.0, width + 15.0] message:@"after the first column shrinks by 20 points"];
    [self assert:300.0 equals:[self maxXOfColumn:2] message:@"the columns fill the clip view"];
}

- (void)testAUserResizeWithLastColumnOnlyResizingGivesTheChangeToTheLastColumn
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewLastColumnOnlyAutoresizingStyle];

    [self userResizeColumn:1 toWidth:width - 20.0];

    [self assertWidths:[width, width - 20.0, width + 20.0] message:@"after the middle column shrinks by 20 points"];
    [self assert:300.0 equals:[self maxXOfColumn:2] message:@"the columns fill the clip view"];
}

- (void)testAUserResizeOfTheLastColumnChangesTheTotalWidth
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewLastColumnOnlyAutoresizingStyle];

    [self userResizeColumn:2 toWidth:width - 20.0];

    [self assertWidths:[width, width, width - 20.0] message:@"after the last column shrinks by 20 points"];
    [self assert:280.0 equals:[self maxXOfColumn:2] message:@"the columns end 20 points before the edge"];
}

- (void)testAUserResizeLeavesWhatTheLastColumnCannotTake
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewLastColumnOnlyAutoresizingStyle];

    [columns[2] setMaxWidth:width + 5.0];
    [self userResizeColumn:0 toWidth:width - 20.0];

    [self assertWidths:[width - 20.0, width, width + 5.0] message:@"after the first column shrinks by 20 points"];
    [self assert:285.0 equals:[self maxXOfColumn:2] message:@"the columns end 15 points before the edge"];
}

- (void)testAUserResizeWithFirstColumnOnlyResizingGivesTheChangeToTheNextColumn
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewFirstColumnOnlyAutoresizingStyle];

    [self userResizeColumn:0 toWidth:width - 20.0];

    [self assertWidths:[width - 20.0, width + 20.0, width] message:@"after the first column shrinks by 20 points"];
    [self assert:300.0 equals:[self maxXOfColumn:2] message:@"the columns fill the clip view"];
}

- (void)testAUserResizeSkipsAColumnWithoutTheAutoresizingMask
{
    var width = [self fillWithEqualColumnsForStyle:CPTableViewFirstColumnOnlyAutoresizingStyle];

    [columns[1] setResizingMask:CPTableColumnUserResizingMask];
    [self userResizeColumn:0 toWidth:width - 20.0];

    [self assertWidths:[width - 20.0, width, width + 20.0] message:@"after the first column shrinks by 20 points"];
}

// MARK: - Size to fit

- (void)testSizeToFitGivesTheColumnsEqualWidthsThatFillTheClipView
{
    [columns[0] setWidth:30.0];
    [columns[1] setWidth:120.0];
    [tableView sizeToFit];

    var width = [self clipWidth] / 3 - [self spacing];

    [self assertWidths:[width, width, width] message:@"after sizeToFit"];
    [self assert:[self clipWidth] equals:[self maxXOfColumn:2] message:@"the columns fill the clip view"];
}

- (void)testSizeToFitKeepsAColumnWithinItsMaximumWidth
{
    [columns[0] setMaxWidth:41.0];
    [tableView sizeToFit];

    [self assert:41.0 equals:[columns[0] width] message:@"the first column keeps its maximum width"];
    [self assert:[columns[1] width] equals:[columns[2] width] message:@"the other columns have equal widths"];
    [self assert:[self clipWidth] equals:[self maxXOfColumn:2] message:@"the columns fill the clip view"];
}

// MARK: - Row views

- (void)testTheRowViewsSpanTheTableViewAfterTheClipViewGrows
{
    [tableView sizeLastColumnToFit];
    [self setScrollViewWidth:400.0];

    [self assertRowViewsSpanTheTableView:@"after the clip view grows"];
}

- (void)testTheRowViewsSpanTheTableViewAfterTheClipViewShrinks
{
    [tableView sizeLastColumnToFit];
    [self setScrollViewWidth:200.0];

    [self assertRowViewsSpanTheTableView:@"after the clip view shrinks"];
}

- (void)testTheRowViewsSpanTheTableViewAfterAResizeThroughNoWidth
{
    [tableView sizeLastColumnToFit];
    [self setScrollViewWidth:0.0];
    [self setScrollViewWidth:300.0];

    [self assertRowViewsSpanTheTableView:@"after a resize through no width"];
}

@end

/*
    Five rows of text.
*/
@implementation _ColumnAutoresizingTestDataSource : CPObject
{
}

- (CPInteger)numberOfRowsInTableView:(CPTableView)aTableView
{
    return 5;
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRow
{
    return @"Row " + aRow;
}

@end
