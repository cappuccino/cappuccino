/*
 * CPTableColumn.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

import <Foundation/Foundation.j>


CPTableColumnNoResizing         = 0;
CPTableColumnAutoresizingMask   = 1;
CPTableColumnUserResizingMask   = 2;

@implementation CPTableColumn : CPObject
{
    CPString    _identifier;
    
    CPTableView _tableView;
    
    float       _width;
    float       _minWidth;
    float       _maxWidth;
    
    unsigned    _resizingMask;
}

- (id)initWithIdentifier:(CPString)anIdentifier
{
    self = [super init];
    
    if (self)
    {
        _identifier = anIdentifier;
        
        _width = 40.0;
        _minWidth = 8.0;
        _maxWidth = 1000.0;
        
        // FIXME
        _dataCell = [[CPTextField alloc] initWithFrame:CPRectMakeZero()];
    }
    
    return self;
}

- (void)setIdentifier:(CPString)anIdentifier
{
    _identifier = anIdentifier;
}

- (CPString)identifier
{
    return _identifier;
}

// Setting the NSTableView

- (void)setTabelView:(CPTableView)aTableView
{
    _tableView = aTableView;
}

- (CPTableView)tableView
{
    return _tableView;
}

// Controlling size

- (void)setWidth:(float)aWidth
{
    _width = aWidth;
}

- (float)width
{
    return _width;
}

- (void)setMinWidth:(float)aWidth
{
    if (_width < (_minWidth = aWidth))
        [self setWidth:_minWidth];
}

- (float)minWidth
{
    return _minWidth;
}

- (float)setMaxWidth:(float)aWidth
{
    if (_width > (_maxmimumWidth = aWidth))
        [self setWidth:_maxWidth];
}

- (void)setResizingMask:(unsigned)aMask
{
    _resizingMask = aMask;
}

- (unsigned)resizingMask
{
    return _resizingMask;
}

- (void)sizeToFit
{
    var width = CPRectGetWidth([_headerView frame]);
    
    if (width < _minWidth)
        [self setMinWidth:width];
    else if (width > _maxWidth)
        [self setMaxWidth:width]

    if (_width != width)
        [self setWidth:width];
}

- (void)setEditable:(BOOL)aFlag
{
    _isEditable = aFlag;
}

- (BOOL)isEditable
{
    return _isEditable;
}

- (void)setHeaderView:(CPView)aHeaderView
{
    _headerView = aHeaderView;
}

- (CPView)headerView
{
    return _headerView;
}

- (void)setDataCell:(id)aDataCell
{
    _dataCell = aDataCell;
}

- (id)dataCell
{
    return _dataCell;
}

- (Class)dataCellForRow:(int)aRowIndex
{
    return [self dataCell];
}

@end
