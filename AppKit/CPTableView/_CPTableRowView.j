/*
 * _CPTableRowView.j
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


@class CPButton
@class CPClipView
@class CPUserDefaults
@class CPTableHeaderView
@class CPTableView
@class _CPTableColumnHeaderView
@class CPClipView
@class CPButton
@class _CPDropOperationDrawingView


// Internal class to handle row background, selection and grid lines via DOM/CSS
@implementation _CPTableRowView : CPView
{
    CPInteger   _rowIndex;
    CPTableView _tableView;
    CPView      _gridLineView;
    BOOL        _selected;
    BOOL        _focused;
    BOOL        _isGroupRow;
}

- (id)initWithTableView:(CPTableView)aTableView
{
    self = [super initWithFrame:CGRectMakeZero()];
    if (self)
    {
        _tableView = aTableView;
        _selected = NO;
        _focused = NO;
        _isGroupRow = NO;

        [self setHitTests:NO];
    }
    return self;
}

- (void)setRowIndex:(CPInteger)anIndex
{
    _rowIndex = anIndex;
    [self updateState];
}

// New method to toggle group row state
- (void)setIsGroupRow:(BOOL)isGroupRow
{
    if (_isGroupRow === isGroupRow)
        return;
        
    _isGroupRow = isGroupRow;
    [self updateState];
}

- (void)setSelected:(BOOL)isSelected focused:(BOOL)isFocused
{
    if (_selected === isSelected && _focused === isFocused)
        return;

    _selected = isSelected;
    _focused = isFocused;
    [self updateState];
}

- (void)updateState
{
    if (!CPDOMAvailable)
        return;

    var backgroundColor = nil;

    if (_selected && [_tableView selectionHighlightStyle] != CPTableViewSelectionHighlightStyleNone)
    {
        if (_focused)
            backgroundColor = [_tableView selectionHighlightColor];
        else
            backgroundColor = [_tableView unfocusedSelectionHighlightColor];
    }
    else if (_isGroupRow)
    {
        // Apply group row background
        backgroundColor = [_tableView valueForThemeAttribute:@"group-row-background-color"];
    }
    else if ([_tableView usesAlternatingRowBackgroundColors])
    {
        var colors = [_tableView alternatingRowBackgroundColors];
        if ([colors count] > 0)
            backgroundColor = colors[_rowIndex % [colors count]];
    }

    if (!backgroundColor)
        backgroundColor = [CPColor clearColor];

    [self setBackgroundColor:backgroundColor];
    [self _updateGridLine];
}

- (void)_updateGridLine
{
    // Don't draw grid lines on group rows
    if (_isGroupRow)
    {
        [_gridLineView setHidden:YES];
        return;
    }

    var mask = [_tableView gridStyleMask];

    if (mask & CPTableViewSolidHorizontalGridLineMask)
    {
        if (!_gridLineView)
        {
            _gridLineView = [[CPView alloc] initWithFrame:CGRectMakeZero()];
            [_gridLineView setBackgroundColor:[_tableView gridColor]];
            [_gridLineView setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];
            [self addSubview:_gridLineView];
        }

        var thickness = [_tableView valueForThemeAttribute:@"grid-line-thickness"] || 1.0;
        [_gridLineView setFrame:CGRectMake(0, CGRectGetHeight([self bounds]) - thickness, CGRectGetWidth([self bounds]), thickness)];
        [_gridLineView setHidden:NO];
    }
    else
    {
        [_gridLineView setHidden:YES];
    }
}

- (void)resizeWithOldSuperviewSize:(CGSize)oldSize
{
    [super resizeWithOldSuperviewSize:oldSize];
    if (_gridLineView && ![_gridLineView isHidden])
        [self _updateGridLine];
}

@end
