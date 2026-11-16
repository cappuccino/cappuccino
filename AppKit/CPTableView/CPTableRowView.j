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

    CPView          _separatorView;
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
    Writes the look of the row: the selection colour for a selected row, else the background
    colour; and the horizontal separator at the bottom edge when the table view's grid style
    has horizontal lines and the row is not a group row.
*/
- (void)layoutSubviews
{
    var color = nil;

    if (_selected && _selectionHighlightStyle !== CPTableViewSelectionHighlightStyleNone)
        color = _emphasized ? [_tableView selectionHighlightColor] : [_tableView unfocusedSelectionHighlightColor];
    else
        color = _rowBackgroundColor || _defaultRowBackgroundColor;

    [super setBackgroundColor:color];

    [self _layoutSeparator];
}

- (void)_layoutSeparator
{
    if (_groupRowStyle || !([_tableView gridStyleMask] & CPTableViewSolidHorizontalGridLineMask))
    {
        [_separatorView setHidden:YES];
        return;
    }

    if (!_separatorView)
    {
        _separatorView = [[CPView alloc] initWithFrame:CGRectMakeZero()];
        [_separatorView setHitTests:NO];
        [_separatorView setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];
        [self addSubview:_separatorView];
    }

    var thickness = [_tableView valueForThemeAttribute:@"grid-line-thickness"] || 1.0,
        bounds = [self bounds];

    [_separatorView setBackgroundColor:[_tableView gridColor]];
    [_separatorView setFrame:CGRectMake(0.0, CGRectGetHeight(bounds) - thickness, CGRectGetWidth(bounds), thickness)];
    [_separatorView setHidden:NO];
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
}

@end
