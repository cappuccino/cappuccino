/*
 * CPTableView+Drawing.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
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

@import "CPTableViewCore.j"

@class CPTableRowView


/*
    The names of the table view's two ephemeral subviews. CPView does not archive ephemeral
    subviews.

    The decoration view holds the views of the column selection and the vertical grid lines.
    It lies in front of the row views and behind every other subview.

    The drawing pass view is the canvas of the four old drawing methods. It exists only for a
    class that overrides one of them, and lies in front of the decoration view and behind the
    data views.
*/
var CPTableViewDecorationViewName   = @"table-decoration",
    CPTableViewDrawingPassViewName  = @"table-drawing-pass";

/*
    The layers of the drawing pass for each table view class, by class UID.
*/
var CPTableViewDrawingPassLayersForClasses = { };


/*
    The canvas of the drawing pass. Its frame is the exposed rect of the table view.
*/
@implementation _CPTableDrawView : CPView
{
    CPTableView _tableView;
}

- (id)initWithTableView:(CPTableView)aTableView
{
    self = [super initWithFrame:CGRectMakeZero()];

    if (self)
    {
        _tableView = aTableView;
        [self setHitTests:NO];
    }

    return self;
}

- (void)drawRect:(CGRect)aRect
{
    var frame = [self frame],
        context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextTranslateCTM(context, -CGRectGetMinX(frame), -CGRectGetMinY(frame));

    [_tableView _drawRect:aRect];
}

@end


/*
    Holds the views of the column selection, behind, and of the vertical grid lines, in
    front. The table view keeps the views in two pools and places them in its layout.
*/
@implementation _CPTableDecorationView : CPView
{
    CPArray     _columnSelectionViews;
    CPArray     _gridLineViews;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _columnSelectionViews = [];
        _gridLineViews = [];
        [self setHitTests:NO];
    }

    return self;
}

- (void)setColumnSelectionRects:(CPArray)someRects color:(CPColor)aColor
{
    [self _showRects:someRects color:aColor inViews:_columnSelectionViews atBack:YES];
}

- (void)setGridLineRects:(CPArray)someRects color:(CPColor)aColor
{
    [self _showRects:someRects color:aColor inViews:_gridLineViews atBack:NO];
}

/*
    Shows one view of someViews for each rect, made when the pool has too few, and hides the
    others.
*/
- (void)_showRects:(CPArray)someRects color:(CPColor)aColor inViews:(CPArray)someViews atBack:(BOOL)atBack
{
    var count = someRects.length;

    while (someViews.length < count)
    {
        var newView = [[CPView alloc] initWithFrame:CGRectMakeZero()];

        [newView setHitTests:NO];

        if (atBack)
            [self addSubview:newView positioned:CPWindowBelow relativeTo:nil];
        else
            [self addSubview:newView];

        someViews.push(newView);
    }

    for (var i = 0; i < someViews.length; i++)
    {
        var view = someViews[i];

        if (i < count)
        {
            [view setFrame:someRects[i]];
            [view setBackgroundColor:aColor];
            [view setHidden:NO];
        }
        else
            [view setHidden:YES];
    }
}

@end


@implementation CPTableView (Drawing)

// MARK: The drawing pass

/*
    Returns the layers that the drawing pass of the receiver draws. The pass draws a layer
    when the class overrides the method of that layer or of a layer behind it, so a class that
    overrides none of the four methods has no drawing pass. The result is found once for each
    class, by comparison of the methods with CPTableView's.
*/
+ (unsigned)_drawingPassLayers
{
    var UID = [self UID],
        layers = CPTableViewDrawingPassLayersForClasses[UID];

    if (layers === undefined)
    {
        var overrides = function(aSelector)
            {
                return [self instanceMethodForSelector:aSelector] !== [CPTableView instanceMethodForSelector:aSelector];
            },
            rows = _CPTableViewDrawingLayerRows,
            grid = rows | _CPTableViewDrawingLayerGrid,
            selection = grid | _CPTableViewDrawingLayerSelection,
            background = selection | _CPTableViewDrawingLayerBackground;

        if (overrides(@selector(drawBackgroundInClipRect:)))
            layers = background;
        else if (overrides(@selector(highlightSelectionInClipRect:)))
            layers = selection;
        else if (overrides(@selector(drawGridInClipRect:)))
            layers = grid;
        else if (overrides(@selector(drawRow:clipRect:)))
            layers = rows;
        else
            layers = 0;

        CPTableViewDrawingPassLayersForClasses[UID] = layers;
    }

    return layers;
}

- (unsigned)_drawingPassLayers
{
    return [[self class] _drawingPassLayers];
}

/*
    Draws the layers of the drawing pass: background, selection and grid, each once for the
    exposed rect, then each row on screen, in ascending order.
*/
- (void)_drawRect:(CGRect)aRect
{
    var exposedRect = [self exposedRect],
        layers = [self _drawingPassLayers];

    if (layers & _CPTableViewDrawingLayerBackground)
        [self drawBackgroundInClipRect:exposedRect];

    if (layers & _CPTableViewDrawingLayerSelection)
        [self highlightSelectionInClipRect:exposedRect];

    if (layers & _CPTableViewDrawingLayerGrid)
        [self drawGridInClipRect:exposedRect];

    if (layers & _CPTableViewDrawingLayerRows)
        [self _drawRowsInClipRect:exposedRect];
}

/*
    Calls drawRow:clipRect: for each row in aRect, in ascending order, with the part of the
    row inside aRect.
*/
- (void)_drawRowsInClipRect:(CGRect)aRect
{
    var rows = [self rowsInRect:aRect],
        lastRow = MIN(CPMaxRange(rows), [self numberOfRows]);

    for (var row = rows.location; row < lastRow; row++)
        [self drawRow:row clipRect:CGRectIntersection(aRect, [self rectOfRow:row])];
}

/*
    Returns the rect of aRow limited to the horizontal extent of aRect. The rows below the
    last row have the default height.
*/
- (CGRect)_rectOfRow:(CPInteger)aRow inClipRect:(CGRect)aRect
{
    var rowRect = [self _rectOfRow:aRow checkRange:NO];

    return CGRectMake(CGRectGetMinX(aRect), CGRectGetMinY(rowRect), CGRectGetWidth(aRect), CGRectGetHeight(rowRect));
}

/*
    Returns the state of aRow: the state of its row view, else the state that the table view
    would give a row view.
*/
- (Object)_rowStateForRow:(CPInteger)aRow
{
    var rowView = _visibleRowViews[aRow];

    if (rowView)
        return [rowView _rowState];

    return [self _tableRowStateForRow:aRow];
}

- (Object)_lookForRow:(CPInteger)aRow
{
    return [CPTableRowView _lookForTableView:self rowState:[self _rowStateForRow:aRow]];
}

/*!
    Draws the background of the rows in a given clip rect on the current graphics context:
    the alternating row colours, the group row colour and the background colours that the
    application set on row views. The rows below the last row are included.

    A subclass overrides this method to draw something other than the standard background.
    The table view then draws the background, the selection, the grid and the rows on a
    canvas, and its row views draw none of these.

    @note The table view calls this method. Do not call it directly to redraw; send
    \c setNeedsDisplay: instead.
*/
- (void)drawBackgroundInClipRect:(CGRect)aRect
{
    var rows = [self _exposedRowsInRect:aRect];

    for (var row = rows.location; row < CPMaxRange(rows); row++)
        [CPTableRowView _drawBackgroundOfLook:[self _lookForRow:row] inRect:[self _rectOfRow:row inClipRect:aRect]];
}

/*!
    Draws the selection in a given clip rect on the current graphics context: the selected
    rows in the selection highlight style, or the selected columns in the selection colour.

    This method is kept for applications written for earlier versions of Cappuccino. New code
    changes the look of the selection with a subclass of \c CPTableRowView. A subclass that
    overrides this method draws the selection, the grid and the rows on a canvas.

    @note The table view calls this method. Do not call it directly to redraw; send
    \c setNeedsDisplay: instead.
*/
- (void)highlightSelectionInClipRect:(CGRect)aRect
{
    if (_selectionHighlightStyle === CPTableViewSelectionHighlightStyleNone)
        return;

    var rows = [self _exposedRowsInRect:aRect],
        lastRow = MIN(CPMaxRange(rows), [self numberOfRows]);

    for (var row = rows.location; row < lastRow; row++)
    {
        if ([_selectedRowIndexes containsIndex:row])
            [CPTableRowView _drawSelectionOfLook:[self _lookForRow:row] inRect:[self _rectOfRow:row inClipRect:aRect]];
    }

    var rects = [self _selectedColumnRectsInRect:aRect],
        color = [self _columnSelectionColor];

    if (!rects.length || !color || [color isCSSBased])
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSetFillColor(context, color);

    for (var i = 0; i < rects.length; i++)
        CGContextFillRect(context, rects[i]);
}

/*!
    Draws the grid in a given clip rect on the current graphics context, as the grid style
    mask gives it: a horizontal line at the bottom edge of each row that is not a group row,
    the rows below the last row included, and a vertical line at the right edge of each
    column.

    A subclass overrides this method to draw grid lines other than the standard ones. The
    table view then draws the grid and the rows on a canvas.

    @note The table view calls this method. Do not call it directly to redraw; send
    \c setNeedsDisplay: instead.
*/
- (void)drawGridInClipRect:(CGRect)aRect
{
    if (_gridStyleMask & CPTableViewSolidHorizontalGridLineMask)
    {
        var rows = [self _exposedRowsInRect:aRect];

        for (var row = rows.location; row < CPMaxRange(rows); row++)
            [CPTableRowView _drawSeparatorOfLook:[self _lookForRow:row] inRect:[self _rectOfRow:row inClipRect:aRect]];
    }

    var rects = [self _verticalGridLineRectsInRect:aRect],
        color = [self gridColor];

    if (!rects.length || !color || [color isCSSBased])
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSetFillColor(context, color);

    for (var i = 0; i < rects.length; i++)
        CGContextFillRect(context, rects[i]);
}

/*!
    Draws over a row. The default implementation draws nothing. A subclass overrides this
    method to draw content over a row, for example a badge in a source list. The table view
    calls it for each row on screen, in ascending order, after the background, the selection
    and the grid, with the part of the row inside the visible area.

    This method is kept for applications written for earlier versions of Cappuccino. New code
    draws in a subclass of \c CPTableRowView, or adds views to the row.

    @note \c tableView:willDisplayView:forTableColumn:row: is sent to the delegate before
    drawing.
*/
- (void)drawRow:(CPInteger)row clipRect:(CGRect)rect
{
}

// MARK: Views of the table view

/*
    Returns the rects of the selected columns in aRect, over the full height of aRect.
*/
- (CPArray)_selectedColumnRectsInRect:(CGRect)aRect
{
    var rects = [];

    if (_selectionHighlightStyle === CPTableViewSelectionHighlightStyleNone || ![_selectedColumnIndexes count])
        return rects;

    [[self columnIndexesInRect:aRect] enumerateIndexesUsingBlock:function(column, stop)
    {
        if (![_selectedColumnIndexes containsIndex:column])
            return;

        var columnRect = [self rectOfColumn:column];

        rects.push(CGRectMake(CGRectGetMinX(columnRect), CGRectGetMinY(aRect), CGRectGetWidth(columnRect), CGRectGetHeight(aRect)));
    }];

    return rects;
}

/*
    Returns the rects of the vertical grid lines in aRect, one at the right edge of each
    column, over the full height of aRect.
*/
- (CPArray)_verticalGridLineRectsInRect:(CGRect)aRect
{
    var rects = [];

    if (!(_gridStyleMask & CPTableViewSolidVerticalGridLineMask))
        return rects;

    var thickness = [self currentValueForThemeAttribute:@"grid-line-thickness"] || 1.0;

    [[self columnIndexesInRect:aRect] enumerateIndexesUsingBlock:function(column, stop)
    {
        var columnRect = [self rectOfColumn:column];

        rects.push(CGRectMake(CGRectGetMaxX(columnRect) - thickness, CGRectGetMinY(aRect), thickness, CGRectGetHeight(aRect)));
    }];

    return rects;
}

/*
    The column selection has the flat selection colour, or its unfocused variant.
*/
- (CPColor)_columnSelectionColor
{
    return [self _isFocused] ? [self selectionHighlightColor] : [self unfocusedSelectionHighlightColor];
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aViewName
{
    /*
        The decoration view keeps the frame that -_layoutTableDecorationViews gives it: the
        bounds of the table view while it shows a view, else an empty rect.
    */
    if (aViewName === CPTableViewDecorationViewName)
    {
        var decorationView = [self ephemeralSubviewNamed:CPTableViewDecorationViewName];

        return decorationView ? [decorationView frame] : CGRectMakeZero();
    }

    if (aViewName === CPTableViewDrawingPassViewName)
        return [self _drawingPassLayers] ? [self exposedRect] : nil;

    return [super rectForEphemeralSubviewNamed:aViewName];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aViewName
{
    if (aViewName === CPTableViewDecorationViewName)
        return [[_CPTableDecorationView alloc] initWithFrame:CGRectMakeZero()];

    if (aViewName === CPTableViewDrawingPassViewName)
        return [[_CPTableDrawView alloc] initWithTableView:self];

    return [super createEphemeralSubviewNamed:aViewName];
}

/*
    Makes and places the decoration view and the drawing pass view. The table view calls this
    method at the start of each load, so that both views exist before the first row view: row
    views are added behind every other subview, so they lie behind both.
*/
- (void)_layoutTableDrawingViews
{
    [self layoutEphemeralSubviewNamed:CPTableViewDecorationViewName
                           positioned:CPWindowBelow
      relativeToEphemeralSubviewNamed:nil];

    [self layoutEphemeralSubviewNamed:CPTableViewDrawingPassViewName
                           positioned:CPWindowAbove
      relativeToEphemeralSubviewNamed:CPTableViewDecorationViewName];
}

- (_CPTableDrawView)_drawingPassView
{
    return [self ephemeralSubviewNamed:CPTableViewDrawingPassViewName];
}

/*
    Marks the canvas of the drawing pass for display, when there is one.
*/
- (void)_markDrawingPassForDisplay
{
    [[self _drawingPassView] setNeedsDisplay:YES];
}

/*
    Places the views of the column selection and the vertical grid lines, over the full
    height of the table view, for the columns in the exposed rect. A layer that the drawing
    pass draws has no views.

    The column selection views were made again from the first responder handlers, twice
    through a timer, because the focus was not yet current when a handler ran. The layout runs
    after the event, when the focus is current.
*/
- (void)_layoutTableDecorationViews
{
    var decorationView = [self ephemeralSubviewNamed:CPTableViewDecorationViewName];

    if (!decorationView)
        return;

    var passLayers = [self _drawingPassLayers],
        exposedRect = [self exposedRect],
        rect = CGRectMake(CGRectGetMinX(exposedRect), 0.0, CGRectGetWidth(exposedRect), CGRectGetHeight([self bounds])),
        selectionRects = (passLayers & _CPTableViewDrawingLayerSelection) ? [] : [self _selectedColumnRectsInRect:rect],
        gridLineRects = (passLayers & _CPTableViewDrawingLayerGrid) ? [] : [self _verticalGridLineRectsInRect:rect];

    /*
        The decoration view spanned the table view at all times, so a table view without column
        selection or vertical grid lines had an empty view over its full height. It now has the
        bounds of the table view only while it shows a view.
    */
    [decorationView setFrame:(selectionRects.length || gridLineRects.length) ? [self bounds] : CGRectMakeZero()];
    [decorationView setColumnSelectionRects:selectionRects color:[self _columnSelectionColor]];
    [decorationView setGridLineRects:gridLineRects color:[self gridColor]];
}

// MARK: Keeping the visible rows current

/*!
    Marks the table view for display. With \c YES this is the signal that the look of the
    table view changed: the visible row views take the state of the table view again and lay
    out, the views of the column selection and the grid lines are placed again, and the canvas
    of a subclass that overrides a drawing method draws again.

    A change of theme, theme state, appearance or theme attribute sends this signal. An
    application sends it after a change that the table view cannot see, such as new content
    that \c drawRow:clipRect: draws.
*/
- (void)setNeedsDisplay:(BOOL)aFlag
{
    [super setNeedsDisplay:aFlag];
    [[self headerView] setNeedsDisplay:YES];

    // CPView sends the signal during initialization, before the table view has row views.
    if (!aFlag || !_visibleRowViews)
        return;

    _unfocusedSelectionHighlightColor = nil;
    _unfocusedSourceListSelectionColor = nil;

    /*
        The row views take the state now, so that their properties are current at once, and
        again in the layout, when the focus is current after an event.
    */
    for (var key in _visibleRowViews)
    {
        if (!_visibleRowViews.hasOwnProperty(key))
            continue;

        var rowView = _visibleRowViews[key];

        [self _configureRowView:rowView forRow:+key];
        [rowView setNeedsLayout];
        [rowView setNeedsDisplay:YES];
    }

    _rowViewsNeedConfiguration = YES;

    [self _markDrawingPassForDisplay];
    [self setNeedsLayout];
}

/*
    Gives every visible row view the state of the table view again, after the signal of
    -setNeedsDisplay:.
*/
- (void)_configureRowViewsAfterLookChangeIfNeeded
{
    if (!_rowViewsNeedConfiguration)
        return;

    _rowViewsNeedConfiguration = NO;

    for (var key in _visibleRowViews)
    {
        if (_visibleRowViews.hasOwnProperty(key))
            [self _configureRowView:_visibleRowViews[key] forRow:+key];
    }
}

/*!
    @ignore
*/
- (void)setNeedsLayout
{
    [super setNeedsLayout];
    [[self headerView] setNeedsLayout];
}

/*!
    @ignore
*/
- (BOOL)_isFocused
{
    return [[self window] isKeyWindow] && ([[self window] firstResponder] === self || _editingRow !== CPNotFound);
}

@end
