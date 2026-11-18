/*
 *  CPTableRowView.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-16.
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

@import "CPTableViewCore.j"

@class CPTableView

/*
    YES for each row view class that draws on a canvas, by class UID.
*/
var CPTableRowViewDrawsOnCanvasForClasses = { };


/*!
    @ingroup appkit
    @class CPTableRowView

    A table view shows each visible row with a row view. The row view shows the state of its
    row: the background, the selection, the group row style, the horizontal separator and the
    feedback for a drop on the row.

    The table view sets every property of a row view. A row view only shows its state: a
    change of \c selected on a row view does not change the selection of the table view.

    An application changes the look of rows with a subclass. The delegate gives the table view
    an instance of the subclass in \c tableView:rowViewForRow:. The table view announces each
    row view that it adds with \c tableView:didAddRowView:forRow:, and each row view that it
    removes with \c tableView:didRemoveRowView:forRow:. A background colour that the
    application sets, for example in \c tableView:didAddRowView:forRow:, stays until the row
    view leaves its row.

    In Cappuccino the views of a row are subviews of the table view, not of the row view. The
    row view lies behind the views of its row and spans the full width of the table view.
    A row view takes no mouse events.

    The row view draws the standard look with CSS. A subclass that overrides \c drawRect: or
    one of the four draw methods draws on a canvas instead: its \c drawRect: calls
    \c drawBackgroundInRect:, \c drawSelectionInRect: when the row is selected,
    \c drawSeparatorInRect: when the table view's grid style has horizontal lines, and
    \c drawDraggingDestinationFeedbackInRect: when a drag proposes a drop on the row, in that
    order. The four methods draw the standard look on the current graphics context, so an
    override can call super.
*/
@implementation CPTableRowView : CPView
{
    BOOL            _selected;
    BOOL            _emphasized;
    BOOL            _groupRowStyle;
    BOOL            _previousRowSelected;
    BOOL            _nextRowSelected;
    BOOL            _targetForDropOperation;
    CPInteger       _selectionHighlightStyle;
    CPInteger       _draggingDestinationFeedbackStyle;
    float           _indentationForDropOperation;

    CPColor         _rowBackgroundColor;
    CPColor         _defaultRowBackgroundColor;

    CPTableView     _tableView;
    BOOL            _isMadeByTableView;
    BOOL            _isFillerRow;
    BOOL            _isDropFeedbackHiddenForBlink;

    CPView          _selectionView;
    CPView          _selectionLineView;
    CPView          _separatorView;
    CPView          _dropFeedbackView;
}

/*
    Returns YES when the receiver overrides drawRect: or one of the four draw methods. Its
    instances then draw on a canvas, and the CSS parts of the standard look are off.
*/
+ (BOOL)_drawsOnCanvas
{
    var UID = [self UID],
        drawsOnCanvas = CPTableRowViewDrawsOnCanvasForClasses[UID];

    if (drawsOnCanvas === undefined)
    {
        var selectors = [@selector(drawRect:), @selector(drawBackgroundInRect:), @selector(drawSelectionInRect:),
                         @selector(drawSeparatorInRect:), @selector(drawDraggingDestinationFeedbackInRect:)];

        drawsOnCanvas = NO;

        for (var i = 0; i < selectors.length && !drawsOnCanvas; i++)
            drawsOnCanvas = [self instanceMethodForSelector:selectors[i]] !== [CPTableRowView instanceMethodForSelector:selectors[i]];

        CPTableRowViewDrawsOnCanvasForClasses[UID] = drawsOnCanvas;
    }

    return drawsOnCanvas;
}

/*
    A row view of a class that does not draw on a canvas takes no display marks, although
    CPTableRowView implements drawRect:. Otherwise every row view would receive drawRect: at
    each change of its state.
*/
+ (BOOL)_hasCustomDrawRect
{
    return [self _drawsOnCanvas] || [self instanceMethodForSelector:@selector(viewWillDraw)] !== [CPView instanceMethodForSelector:@selector(viewWillDraw)];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
        [self _initRowView];

    return self;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
        [self _initRowView];

    return self;
}

/*
    Sets the state that a row view has before a table view configures it.
*/
- (void)_initRowView
{
    _selectionHighlightStyle = CPTableViewSelectionHighlightStyleRegular;
    _draggingDestinationFeedbackStyle = CPTableViewDraggingDestinationFeedbackStyleRegular;
    _indentationForDropOperation = 0.0;

    [self setHitTests:NO];
}

/*!
    Sets whether the row is selected. The table view sets this property.
*/
- (void)setSelected:(BOOL)isSelected
{
    isSelected = !!isSelected;

    if (_selected === isSelected)
        return;

    _selected = isSelected;
    [self _rowStateDidChange];
}

/*!
    Returns YES if the row is selected.
*/
- (BOOL)isSelected
{
    return _selected;
}

/*!
    Sets whether the row shows the emphasized look, the look of a selection in a table view
    that has the keyboard focus. The table view sets this property.
*/
- (void)setEmphasized:(BOOL)isEmphasized
{
    isEmphasized = !!isEmphasized;

    if (_emphasized === isEmphasized)
        return;

    _emphasized = isEmphasized;
    [self _rowStateDidChange];
}

/*!
    Returns YES if the row shows the emphasized look.
*/
- (BOOL)isEmphasized
{
    return _emphasized;
}

/*!
    Sets whether the row is a group row. The table view sets this property from the delegate
    method \c tableView:isGroupRow:.
*/
- (void)setGroupRowStyle:(BOOL)isGroupRowStyle
{
    isGroupRowStyle = !!isGroupRowStyle;

    if (_groupRowStyle === isGroupRowStyle)
        return;

    _groupRowStyle = isGroupRowStyle;
    [self _rowStateDidChange];
}

/*!
    Returns YES if the row is a group row.
*/
- (BOOL)isGroupRowStyle
{
    return _groupRowStyle;
}

/*!
    Sets the selection highlight style: \c CPTableViewSelectionHighlightStyleNone,
    \c CPTableViewSelectionHighlightStyleRegular or
    \c CPTableViewSelectionHighlightStyleSourceList. The table view sets this property from
    its own style.
*/
- (void)setSelectionHighlightStyle:(CPInteger)aStyle
{
    if (_selectionHighlightStyle === aStyle)
        return;

    _selectionHighlightStyle = aStyle;
    [self _rowStateDidChange];
}

/*!
    Returns the selection highlight style.
*/
- (CPInteger)selectionHighlightStyle
{
    return _selectionHighlightStyle;
}

/*!
    Sets whether the row above this row is selected. The table view sets this property.
*/
- (void)setPreviousRowSelected:(BOOL)isPreviousRowSelected
{
    isPreviousRowSelected = !!isPreviousRowSelected;

    if (_previousRowSelected === isPreviousRowSelected)
        return;

    _previousRowSelected = isPreviousRowSelected;
    [self _rowStateDidChange];
}

/*!
    Returns YES if the row above this row is selected.
*/
- (BOOL)isPreviousRowSelected
{
    return _previousRowSelected;
}

/*!
    Sets whether the row below this row is selected. The table view sets this property.
*/
- (void)setNextRowSelected:(BOOL)isNextRowSelected
{
    isNextRowSelected = !!isNextRowSelected;

    if (_nextRowSelected === isNextRowSelected)
        return;

    _nextRowSelected = isNextRowSelected;
    [self _rowStateDidChange];
}

/*!
    Returns YES if the row below this row is selected.
*/
- (BOOL)isNextRowSelected
{
    return _nextRowSelected;
}

/*!
    Sets whether a drag proposes a drop on this row. The table view sets this property
    while a drag is over it.
*/
- (void)setTargetForDropOperation:(BOOL)isTargetForDropOperation
{
    isTargetForDropOperation = !!isTargetForDropOperation;

    if (_targetForDropOperation === isTargetForDropOperation)
        return;

    _targetForDropOperation = isTargetForDropOperation;
    [self _rowStateDidChange];
}

/*!
    Returns YES if a drag proposes a drop on this row.
*/
- (BOOL)isTargetForDropOperation
{
    return _targetForDropOperation;
}

/*!
    Sets the style of the feedback for a drop:
    \c CPTableViewDraggingDestinationFeedbackStyleNone,
    \c CPTableViewDraggingDestinationFeedbackStyleRegular or
    \c CPTableViewDraggingDestinationFeedbackStyleSourceList. The table view sets this
    property from its own style.
*/
- (void)setDraggingDestinationFeedbackStyle:(CPInteger)aStyle
{
    if (_draggingDestinationFeedbackStyle === aStyle)
        return;

    _draggingDestinationFeedbackStyle = aStyle;
    [self _rowStateDidChange];
}

/*!
    Returns the style of the feedback for a drop.
*/
- (CPInteger)draggingDestinationFeedbackStyle
{
    return _draggingDestinationFeedbackStyle;
}

/*!
    Sets the indentation of the feedback for a drop on this row. A table view sets 0. An
    outline view sets the indentation of the row's item.
*/
- (void)setIndentationForDropOperation:(float)anIndentation
{
    anIndentation = +anIndentation || 0.0;

    if (_indentationForDropOperation === anIndentation)
        return;

    _indentationForDropOperation = anIndentation;
    [self _rowStateDidChange];
}

/*!
    Returns the indentation of the feedback for a drop on this row.
*/
- (float)indentationForDropOperation
{
    return _indentationForDropOperation;
}

/*!
    Sets the background colour of the row. A nil colour gives the row its default
    background again. The colour stays until the row view leaves its row.
*/
- (void)setBackgroundColor:(CPColor)aColor
{
    if (aColor === [CPNull null])
        aColor = nil;

    if (_rowBackgroundColor === aColor)
        return;

    _rowBackgroundColor = aColor;
    [self _rowStateDidChange];
}

/*!
    Returns the background colour of the row: the colour that the application set, else the
    default that the table view gives, else the background colour of the table view. The
    default is the group row colour for a group row, else the alternating colour of the row
    when the table view uses alternating colours.
*/
- (CPColor)backgroundColor
{
    return _rowBackgroundColor || _defaultRowBackgroundColor || [_tableView backgroundColor];
}

/*
    A row view archives only a background colour that the application set. The colour in the
    DOM can be the selection colour or a default of the table view.
*/
- (CPColor)_archivedBackgroundColor
{
    return _rowBackgroundColor;
}

/*!
    Returns the view of the row in the given column, or nil when the row view is not in a
    table view or the column has no view.
*/
- (id)viewAtColumn:(CPInteger)aColumn
{
    var row = [_tableView rowForView:self];

    if (row === nil || row === CPNotFound)
        return nil;

    return [_tableView viewAtColumn:aColumn row:row makeIfNecessary:NO];
}

/*!
    Returns the number of columns of the row: the number of columns of the table view, or 0
    when the row view is not in a table view.
*/
- (CPInteger)numberOfColumns
{
    var row = [_tableView rowForView:self];

    if (row === nil || row === CPNotFound)
        return 0;

    return [_tableView numberOfColumns];
}

/*
    A change of state marks the row view. The look follows in the layout, under the row
    view's effective appearance.
*/
- (void)_rowStateDidChange
{
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*
    Returns the state of the row, in the form that the look rules read.
*/
- (Object)_rowState
{
    return {
        selected: _selected,
        emphasized: _emphasized,
        groupRowStyle: _groupRowStyle,
        selectionHighlightStyle: _selectionHighlightStyle,
        nextRowSelected: _nextRowSelected,
        targetForDropOperation: _targetForDropOperation && !_isDropFeedbackHiddenForBlink,
        draggingDestinationFeedbackStyle: _draggingDestinationFeedbackStyle,
        indentationForDropOperation: _indentationForDropOperation,
        backgroundColor: _rowBackgroundColor,
        defaultBackgroundColor: _defaultRowBackgroundColor
    };
}

/*
    Returns the layers that the table view's drawing pass draws in place of the row view.
*/
- (unsigned)_drawingPassLayers
{
    return [_tableView _drawingPassLayers] || 0;
}

// MARK: Drawing on a canvas

/*!
    Draws the row, for a subclass that overrides this method or one of the four draw methods.
    It calls \c drawBackgroundInRect:, then \c drawSelectionInRect: when the row is selected
    and the selection highlight style is not None, then \c drawSeparatorInRect: when the table
    view's grid style has horizontal lines, then \c drawDraggingDestinationFeedbackInRect:
    when a drag proposes a drop on the row. A part that the table view's drawing pass draws is
    left out.

    A row view of the base class draws with CSS and receives no \c drawRect:.
*/
- (void)drawRect:(CGRect)aRect
{
    if (![[self class] _drawsOnCanvas])
        return;

    var passLayers = [self _drawingPassLayers];

    if (!(passLayers & _CPTableViewDrawingLayerBackground))
        [self drawBackgroundInRect:aRect];

    if (_selected && _selectionHighlightStyle !== CPTableViewSelectionHighlightStyleNone && !(passLayers & _CPTableViewDrawingLayerSelection))
        [self drawSelectionInRect:aRect];

    if (([_tableView gridStyleMask] & CPTableViewSolidHorizontalGridLineMask) && !(passLayers & _CPTableViewDrawingLayerGrid))
        [self drawSeparatorInRect:aRect];

    if (_targetForDropOperation && !_isDropFeedbackHiddenForBlink)
        [self drawDraggingDestinationFeedbackInRect:aRect];
}

/*!
    Draws the background of the row on the current graphics context: the background colour,
    or the group row colour for a group row. A subclass overrides this method to draw another
    background.
*/
- (void)drawBackgroundInRect:(CGRect)aRect
{
    [CPTableRowView _drawBackgroundOfLook:[self _look] inRect:[self bounds]];
}

/*!
    Draws the selection of the row on the current graphics context, in the table view's
    selection highlight style. The row view calls this method only for a selected row.
*/
- (void)drawSelectionInRect:(CGRect)aRect
{
    [CPTableRowView _drawSelectionOfLook:[self _look] inRect:[self bounds]];
}

/*!
    Draws the horizontal separator at the bottom edge of the row on the current graphics
    context. The row view calls this method only when the table view's grid style has
    horizontal lines. A group row has no separator.
*/
- (void)drawSeparatorInRect:(CGRect)aRect
{
    [CPTableRowView _drawSeparatorOfLook:[self _look] inRect:[self bounds]];
}

/*!
    Draws the feedback for a drop on the row on the current graphics context. The row view
    calls this method only when a drag proposes a drop on the row.
*/
- (void)drawDraggingDestinationFeedbackInRect:(CGRect)aRect
{
    [CPTableRowView _drawDropFeedbackOfLook:[self _look] inRect:[self bounds]];
}

- (Object)_look
{
    return [CPTableRowView _lookForTableView:_tableView rowState:[self _rowState]];
}

// MARK: Drawing with CSS

/*
    Writes the look of the row in CSS, under the row view's effective appearance: the
    background colour of the row view itself, then a child view for each other part, made at
    first use: the selection, the horizontal separator and the feedback for a drop. A part
    that the table view's drawing pass draws is off. A row view that draws on a canvas has no
    CSS parts.
*/
- (void)layoutSubviews
{
    if ([[self class] _drawsOnCanvas])
    {
        [super setBackgroundColor:nil];
        [_selectionView setHidden:YES];
        [_separatorView setHidden:YES];
        [_dropFeedbackView setHidden:YES];

        return;
    }

    var look = [self _look],
        passLayers = [self _drawingPassLayers];

    [super setBackgroundColor:(passLayers & _CPTableViewDrawingLayerBackground) ? nil : look.backgroundColor];

    [self _layoutSelection:(passLayers & _CPTableViewDrawingLayerSelection) ? nil : look.selection
            bottomLineColor:look.selectionBottomLineColor];
    [self _layoutSeparator:(passLayers & _CPTableViewDrawingLayerGrid) ? nil : look.separator];
    [self _layoutDropFeedback:look.drop];
}

/*
    The selection: one child view over the whole row, behind the other parts. When the next
    row is selected too, a line at the bottom edge separates the two selections.
*/
- (void)_layoutSelection:(Object)aSelection bottomLineColor:(CPColor)aLineColor
{
    if (!aSelection)
    {
        [_selectionView setHidden:YES];
        return;
    }

    var bounds = [self bounds];

    if (!_selectionView)
    {
        _selectionView = [self _newPartView];
        [self addSubview:_selectionView positioned:CPWindowBelow relativeTo:nil];
    }

    [_selectionView setFrame:bounds];
    [_selectionView setBackgroundColor:[CPTableRowView _CSSColorForSelection:aSelection]];
    [_selectionView setHidden:NO];

    if (!aLineColor)
    {
        [_selectionLineView setHidden:YES];
        return;
    }

    if (!_selectionLineView)
    {
        _selectionLineView = [self _newPartView];
        [_selectionView addSubview:_selectionLineView];
    }

    [_selectionLineView setFrame:CGRectMake(0.0, CGRectGetHeight(bounds) - 1.0, CGRectGetWidth(bounds), 1.0)];
    [_selectionLineView setBackgroundColor:aLineColor];
    [_selectionLineView setHidden:NO];
}

/*
    The horizontal separator: one child view at the bottom edge, in front of the selection.
*/
- (void)_layoutSeparator:(Object)aSeparator
{
    if (!aSeparator)
    {
        [_separatorView setHidden:YES];
        return;
    }

    if (!_separatorView)
    {
        _separatorView = [self _newPartView];

        if (_dropFeedbackView)
            [self addSubview:_separatorView positioned:CPWindowBelow relativeTo:_dropFeedbackView];
        else
            [self addSubview:_separatorView];
    }

    [_separatorView setFrame:[CPTableRowView _separatorRectOfLook:aSeparator inRect:[self bounds]]];
    [_separatorView setBackgroundColor:aSeparator.color];
    [_separatorView setHidden:NO];
}

/*
    The feedback for a drop on the row: one child view in front of the other parts.
*/
- (void)_layoutDropFeedback:(Object)aDrop
{
    if (!aDrop)
    {
        [_dropFeedbackView setHidden:YES];
        return;
    }

    if (!_dropFeedbackView)
    {
        _dropFeedbackView = [self _newPartView];
        [self addSubview:_dropFeedbackView];
    }

    var css = @{ @"box-sizing": @"border-box" };

    if (aDrop.backgroundColor)
        [css setObject:aDrop.backgroundColor forKey:@"background-color"];

    if (aDrop.borderColor && aDrop.borderWidth)
        [css setObject:[aDrop.borderWidth + "px solid ", aDrop.borderColor] forKey:@"border"];

    if (aDrop.borderRadius)
        [css setObject:aDrop.borderRadius + "px" forKey:@"border-radius"];

    [_dropFeedbackView setFrame:[CPTableRowView _dropFeedbackRectOfLook:aDrop inRect:[self bounds]]];
    [_dropFeedbackView setBackgroundColor:[CPColor colorWithCSSDictionary:css]];
    [_dropFeedbackView setHidden:NO];
}

- (CPView)_newPartView
{
    var view = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [view setHitTests:NO];

    return view;
}

@end


/*
    The table view's side of a row view. A table view calls these methods; an application
    does not.
*/
@implementation CPTableRowView (CPTableViewPrivate)

- (CPTableView)_tableView
{
    return _tableView;
}

- (void)_setTableView:(CPTableView)aTableView
{
    _tableView = aTableView;
}

/*
    Sets the background that the row has when the application set no colour.
*/
- (void)_setDefaultBackgroundColor:(CPColor)aColor
{
    if (_defaultRowBackgroundColor === aColor)
        return;

    _defaultRowBackgroundColor = aColor;
    [self _rowStateDidChange];
}

/*
    YES for a row view that the table view made, which goes back to the table view's pool
    when it leaves its row.
*/
- (BOOL)_isMadeByTableView
{
    return _isMadeByTableView;
}

- (void)_setMadeByTableView:(BOOL)aFlag
{
    _isMadeByTableView = aFlag;
}

/*
    YES for a row view below the last row. Such a row view fills the empty area of the table
    view with the row look. It is private: the delegate never sees it.
*/
- (BOOL)_isFillerRow
{
    return _isFillerRow;
}

- (void)_setFillerRow:(BOOL)aFlag
{
    _isFillerRow = aFlag;
}

/*
    Ends the state that belongs to one row, when the row view leaves its row.
*/
- (void)_prepareForReuse
{
    _rowBackgroundColor = nil;
    _targetForDropOperation = NO;
    _isDropFeedbackHiddenForBlink = NO;
}

/*
    Blinks the feedback for a drop on the row, before an outline view expands the item that
    the drag hovers over.
*/
- (void)_blinkDraggingDestinationFeedback
{
    if (!_targetForDropOperation)
        return;

    var setHidden = function(isHidden)
    {
        _isDropFeedbackHiddenForBlink = isHidden;
        [self _rowStateDidChange];
    };

    setHidden(YES);

    [CPTimer scheduledTimerWithTimeInterval:0.1 callback:function() { setHidden(NO); } repeats:NO];
    [CPTimer scheduledTimerWithTimeInterval:0.19 callback:function() { setHidden(YES); } repeats:NO];
    [CPTimer scheduledTimerWithTimeInterval:0.27 callback:function() { setHidden(NO); } repeats:NO];
}

@end


/*
    The look of a row: one set of rules, read by the CSS renderer of a row view, by the canvas
    renderer of a row view that draws on a canvas, and by the table view's default drawing
    methods.
*/
@implementation CPTableRowView (CPTableRowLook)

/*
    Returns the resolved look of a row in aTableView with aState, the state of a row view
    (see -_rowState). Each part is nil when the row does not show it:

    - backgroundColor: the colour that the application set on the row view, else the default
      that the table view gives (the group row colour outside the source-list style, else the
      alternating colour of the row), else nil, so that the table view's background shows.
    - selection: for a selected row whose style is not None. In the source-list style, the
      gradient of the source-list selection colour with its top and bottom line colours; else
      the selection colour with the selection radius. Without the emphasized look, the
      unfocused variants.
    - selectionBottomLineColor: the highlighted grid colour, when the next row is selected too.
    - separator: the grid colour and line thickness, when the grid style has horizontal lines
      and the row is not a group row.
    - drop: the colours, border and radius of the feedback for a drop on the row, with the
      selected variants for a selected row, and the indentation of the drop.
*/
+ (Object)_lookForTableView:(CPTableView)aTableView rowState:(Object)aState
{
    var look = {
            backgroundColor: aState.backgroundColor || aState.defaultBackgroundColor || nil,
            selection: nil,
            selectionBottomLineColor: nil,
            separator: nil,
            drop: nil
        };

    if (aState.selected && aState.selectionHighlightStyle !== CPTableViewSelectionHighlightStyleNone)
    {
        if (aState.selectionHighlightStyle === CPTableViewSelectionHighlightStyleSourceList && [aTableView selectionGradientColors])
        {
            var colors = aState.emphasized ? [aTableView selectionGradientColors] : [aTableView unfocusedSelectionGradientColors],
                gradient = [colors objectForKey:CPSourceListGradient];

            if (gradient)
                look.selection = {
                    gradient: gradient,
                    topLineColor: [colors objectForKey:CPSourceListTopLineColor],
                    bottomLineColor: [colors objectForKey:CPSourceListBottomLineColor]
                };
        }

        if (!look.selection)
        {
            var color = aState.emphasized ? [aTableView selectionHighlightColor] : [aTableView unfocusedSelectionHighlightColor];

            if (color)
                look.selection = {
                    color: color,
                    radius: [aTableView currentValueForThemeAttribute:@"selection-radius"] || 0.0
                };
        }

        if (look.selection && aState.nextRowSelected)
            look.selectionBottomLineColor = [aTableView currentValueForThemeAttribute:@"highlighted-grid-color"];
    }

    if (!aState.groupRowStyle && ([aTableView gridStyleMask] & CPTableViewSolidHorizontalGridLineMask) && [aTableView gridColor])
        look.separator = {
            color: [aTableView gridColor],
            thickness: [aTableView currentValueForThemeAttribute:@"grid-line-thickness"] || 1.0
        };

    if (aState.targetForDropOperation && aState.draggingDestinationFeedbackStyle !== CPTableViewDraggingDestinationFeedbackStyleNone)
    {
        var prefix = aState.selected ? @"dropview-on-selected-" : @"dropview-on-";

        look.drop = {
            backgroundColor: [aTableView currentValueForThemeAttribute:prefix + @"background-color"],
            borderColor: [aTableView currentValueForThemeAttribute:prefix + @"border-color"],
            borderWidth: [aTableView currentValueForThemeAttribute:prefix + @"border-width"] || 0.0,
            borderRadius: [aTableView currentValueForThemeAttribute:prefix + @"border-radius"] || 0.0,
            indentation: aState.indentationForDropOperation || 0.0
        };
    }

    return look;
}

/*
    Returns the rect of a separator at the bottom edge of aRect, a row rect.
*/
+ (CGRect)_separatorRectOfLook:(Object)aSeparator inRect:(CGRect)aRect
{
    return CGRectMake(CGRectGetMinX(aRect), CGRectGetMaxY(aRect) - aSeparator.thickness, CGRectGetWidth(aRect), aSeparator.thickness);
}

/*
    Returns the rect of the feedback for a drop in aRect, a row rect: inset by 2 points, less
    3 points at the bottom, and shifted right by the indentation of the drop.
*/
+ (CGRect)_dropFeedbackRectOfLook:(Object)aDrop inRect:(CGRect)aRect
{
    return CGRectMake(CGRectGetMinX(aRect) + 2.0 + aDrop.indentation,
                      CGRectGetMinY(aRect) + 2.0,
                      MAX(0.0, CGRectGetWidth(aRect) - 4.0 - aDrop.indentation),
                      MAX(0.0, CGRectGetHeight(aRect) - 5.0));
}

/*
    Returns the colour of the CSS selection view: the flat selection colour, with the
    selection radius when there is one; or, in the source-list style, a linear gradient whose
    first and last point are the top and bottom line colours.
*/
+ (CPColor)_CSSColorForSelection:(Object)aSelection
{
    if (!aSelection.gradient)
    {
        if (!aSelection.radius)
            return aSelection.color;

        return [CPColor colorWithCSSDictionary:@{
                    @"background-color": aSelection.color,
                    @"border-radius": aSelection.radius + "px"
                }];
    }

    var gradient = aSelection.gradient,
        colors = gradient.colors,
        locations = gradient.locations,
        topLineColor = aSelection.topLineColor,
        bottomLineColor = aSelection.bottomLineColor,
        topInset = topLineColor ? 1.0 : 0.0,
        bottomInset = bottomLineColor ? 1.0 : 0.0,
        value = [@"linear-gradient(to bottom"];

    if (topLineColor)
        value.push(@", ", topLineColor, @" 0px, ", topLineColor, @" 1px");

    for (var i = 0, count = colors.length; i < count; i++)
    {
        var location = locations ? locations[i] : i / MAX(1, count - 1),
            offset = topInset - location * (topInset + bottomInset);

        value.push(@", ", [CPTableRowView _colorFromCGColor:colors[i]], @" calc(" + (location * 100.0) + "% + " + offset + "px)");
    }

    if (bottomLineColor)
        value.push(@", ", bottomLineColor, @" calc(100% - 1px), ", bottomLineColor, @" 100%");

    value.push(@")");

    return [CPColor colorWithCSSDictionary:@{ @"background-image": value }];
}

+ (CPColor)_colorFromCGColor:(CGColor)aColor
{
    var components = aColor.components;

    return [CPColor colorWithRed:components[0] green:components[1] blue:components[2] alpha:components[3]];
}

/*
    The canvas renderer. Each method draws one part of aLook in aRect, a row rect, on the
    current graphics context, and draws nothing for a part that is nil. A colour that CSS
    defines has no canvas form and is not drawn.
*/
+ (void)_drawBackgroundOfLook:(Object)aLook inRect:(CGRect)aRect
{
    var color = aLook.backgroundColor;

    if (!color || [color isCSSBased])
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSetFillColor(context, color);
    CGContextFillRect(context, aRect);
}

+ (void)_drawSelectionOfLook:(Object)aLook inRect:(CGRect)aRect
{
    var selection = aLook.selection;

    if (!selection)
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        minX = CGRectGetMinX(aRect),
        minY = CGRectGetMinY(aRect),
        maxX = CGRectGetMaxX(aRect),
        maxY = CGRectGetMaxY(aRect);

    if (selection.gradient)
    {
        CGContextBeginPath(context);
        CGContextAddRect(context, aRect);
        CGContextDrawLinearGradient(context, selection.gradient, CGPointMake(minX, minY), CGPointMake(minX, maxY), 0);

        if (selection.topLineColor && ![selection.topLineColor isCSSBased])
        {
            CGContextSetFillColor(context, selection.topLineColor);
            CGContextFillRect(context, CGRectMake(minX, minY, maxX - minX, 1.0));
        }

        if (selection.bottomLineColor && ![selection.bottomLineColor isCSSBased])
        {
            CGContextSetFillColor(context, selection.bottomLineColor);
            CGContextFillRect(context, CGRectMake(minX, maxY - 1.0, maxX - minX, 1.0));
        }
    }
    else if (![selection.color isCSSBased])
    {
        CGContextSetFillColor(context, selection.color);

        if (selection.radius > 0)
            CGContextFillRoundedRectangleInRect(context, aRect, selection.radius, YES, YES, YES, YES);
        else
            CGContextFillRect(context, aRect);
    }

    var lineColor = aLook.selectionBottomLineColor;

    if (lineColor && ![lineColor isCSSBased])
    {
        CGContextSetFillColor(context, lineColor);
        CGContextFillRect(context, CGRectMake(minX, maxY - 1.0, maxX - minX, 1.0));
    }
}

+ (void)_drawSeparatorOfLook:(Object)aLook inRect:(CGRect)aRect
{
    var separator = aLook.separator;

    if (!separator || [separator.color isCSSBased])
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSetFillColor(context, separator.color);
    CGContextFillRect(context, [self _separatorRectOfLook:separator inRect:aRect]);
}

+ (void)_drawDropFeedbackOfLook:(Object)aLook inRect:(CGRect)aRect
{
    var drop = aLook.drop;

    if (!drop)
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        rect = [self _dropFeedbackRectOfLook:drop inRect:aRect];

    if (drop.backgroundColor && ![drop.backgroundColor isCSSBased])
    {
        CGContextSetFillColor(context, drop.backgroundColor);
        CGContextFillRoundedRectangleInRect(context, rect, drop.borderRadius, YES, YES, YES, YES);
    }

    if (drop.borderColor && drop.borderWidth && ![drop.borderColor isCSSBased])
    {
        CGContextSetStrokeColor(context, drop.borderColor);
        CGContextSetLineWidth(context, drop.borderWidth);
        CGContextStrokeRoundedRectangleInRect(context, rect, drop.borderRadius, YES, YES, YES, YES);
    }
}

@end
