/*
 * CPTableColumn.j
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

@import <Foundation/CPDictionary.j>
@import <Foundation/CPObject.j>
@import <Foundation/CPSortDescriptor.j>
@import <Foundation/CPString.j>

@import "CPTableHeaderView.j"

#include "CoreGraphics/CGGeometry.h"

CPTableColumnNoResizing         = 0;
CPTableColumnAutoresizingMask   = 1;
CPTableColumnUserResizingMask   = 2;

@implementation CPTableColumn : CPObject
{
    CPTableView         _tableView;
    CPView              _headerView;
    CPView              _dataView;
    Object              _dataViewData;

    float               _width;
    float               _minWidth;
    float               _maxWidth;
    unsigned            _resizingMask;

    id                  _identifier;
    BOOL                _isEditable;
    CPSortDescriptor    _sortDescriptorPrototype;
    BOOL                _isHidden;
    CPString            _headerToolTip;
}

- (id)init
{
    return [self initWithIdentifier:@""];
}

- (id)initWithIdentifier:(id)anIdentifier
{
    self = [super init];

    if (self)
    {
        _dataViewData = { };

        _width = 100.0;
        _minWidth = 10.0;
        _maxWidth = 1000000.0;

        [self setIdentifier:anIdentifier];

        var header = [CPTextField new];
        [header setBackgroundColor:[CPColor colorWithPatternImage:CPAppKitImage("tableview-headerview.png", CGSizeMake(1.0, 23.0))]];
        [self setHeaderView:header];
        
        var textDataView = [CPTextField new];
        [textDataView setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateHighlighted];
        [textDataView setValue:[CPFont boldSystemFontOfSize:12] forThemeAttribute:@"font" inState:CPThemeStateHighlighted];
        [self setDataView:textDataView];
    }

    return self;
}


- (void)setTableView:(CPTableView)aTableView
{
    _tableView = aTableView;
}

- (CPTableView)tableView
{
    return _tableView;
}

- (void)setWidth:(float)aWidth
{
    aWidth = +aWidth;

    if (_width === aWidth)
        return;

    var newWidth = MIN(MAX(aWidth, [self minWidth]), [self maxWidth]);

    if (_width === newWidth)
        return;

    var oldWidth = _width;

    _width = newWidth;

    var tableView = [self tableView];

    if (tableView)
    {
        var index = [[tableView tableColumns] indexOfObjectIdenticalTo:self];

        // FIXME: THIS IS HORRIBLE. Don't just reload everything when a table column changes, just relayout the changed widths.
        tableView._reloadAllRows = YES;
        tableView._dirtyTableColumnRangeIndex = tableView._dirtyTableColumnRangeIndex < 0 ? index : MIN(index,  tableView._dirtyTableColumnRangeIndex);

        [tableView tile];

        [[CPNotificationCenter defaultCenter]
            postNotificationName:CPTableViewColumnDidResizeNotification
                          object:tableView
                        userInfo:[CPDictionary dictionaryWithObjects:[self, oldWidth] forKeys:[@"CPTableColumn", "CPOldWidth"]]];
    }
}

- (float)width
{
    return _width;
}

- (void)setMinWidth:(float)aMinWidth
{
    aMinWidth = +aMinWidth;

    if (_minWidth === aMinWidth)
        return;

    _minWidth = aMinWidth;

    var width = [self width],
        newWidth = MAX(width, [self minWidth]);

    if (width !== newWidth)
        [self setWidth:newWidth];
}

- (float)minWidth
{
    return _minWidth;
}

- (void)setMaxWidth:(float)aMaxWidth
{
    aMaxWidth = +aMaxWidth;

    if (_maxWidth === aMaxWidth)
        return;

    _maxWidth = aMaxWidth;

    var width = [self width],
        newWidth = MAX(width, [self maxWidth]);

    if (width !== newWidth)
        [self setWidth:newWidth];
}

- (float)maxWidth
{
    return _maxWidth;
}

- (void)setResizingMask:(unsigned)aResizingMask
{
    _resizingMask = aResizingMask;
}

- (float)resizingMask
{
    return _resizingMask;
}

- (void)sizeToFit
{
    var width = _CGRectGetWidth([_headerView frame]);

    if (width < [self minWidth])
        [self setMinWidth:width];
    else if (width > [self maxWidth])
        [self setMaxWidth:width]

    if (_width !== width)
        [self setWidth:width];
}

//Setting Component Cells
- (void)setHeaderView:(CPView)aView
{
    if (!aView)
        [CPException raise:CPInvalidArgumentException reason:@"Attempt to set nil header view on " + [self description]];

    _headerView = aView;

    var tableHeaderView = [_tableView headerView];

    [tableHeaderView setNeedsLayout];
    [tableHeaderView setNeedsDisplay:YES];
}

- (CPView)headerView
{
    return _headerView;
}

- (void)setDataView:(CPView)aView
{
    if (_dataView === aView)
        return;

    if (_dataView)
        _dataViewData[[_dataView UID]] = nil;

    _dataView = aView;
    _dataViewData[[aView UID]] = [CPKeyedArchiver archivedDataWithRootObject:aView];
}

- (CPView)dataView
{
    return _dataView;
}

/*
    Returns the CPView object used by the CPTableView to draw values for the receiver.

    By default, this method just calls dataView. Subclassers can override if they need to
    potentially use different cells for different rows. Subclasses should expect this method
    to be invoked with row equal to -1 in cases where no actual row is involved but the table
    view needs to get some generic cell info.
*/
- (id)dataViewForRow:(int)aRowIndex
{
    return [self dataView];
}

- (id)_newDataViewForRow:(int)aRowIndex
{
    var dataView = [self dataViewForRow:aRowIndex],
        dataViewUID = [dataView UID];

var x = [self tableView]._cachedDataViews[dataViewUID];
if (x && x.length)
return x.pop();

    // if we haven't cached an archive of the data view, do it now
    if (!_dataViewData[dataViewUID])
        _dataViewData[dataViewUID] = [CPKeyedArchiver archivedDataWithRootObject:dataView];

    // unarchive the data view cache
    var newDataView = [CPKeyedUnarchiver unarchiveObjectWithData:_dataViewData[dataViewUID]];
newDataView.identifier = dataViewUID;
    return newDataView;
}

//Setting the Identifier

/*
    Sets the receiver identifier to anIdentifier.
*/
- (void)setIdentifier:(id)anIdentifier
{
    _identifier = anIdentifier;
}

/*
    Returns the object used by the data source to identify the attribute corresponding to the receiver.
*/
- (id)identifier
{
    return _identifier;
}

//Controlling Editability

/*
    Controls whether the user can edit cells in the receiver by double-clicking them.
*/
- (void)setEditable:(BOOL)shouldBeEditable
{
    _isEditable = shouldBeEditable;
}

/*
    Returns YES if the user can edit cells associated with the receiver by double-clicking the 
    column in the NSTableView, NO otherwise.
*/
- (BOOL)isEditable
{
    return _isEditable;
}

//Sorting
- (void)setSortDescriptorPrototype:(CPSortDescriptor)aSortDescriptor
{
    _sortDescriptorPrototype = aSortDescriptor;
}

- (CPSortDescriptor)sortDescriptorPrototype
{
    return _sortDescriptorPrototype;
}

//Setting Column Visibility

- (void)setHidden:(BOOL)shouldBeHidden
{
    _isHidden = shouldBeHidden;
}

- (BOOL)isHidden
{
    return _isHidden;
}

//Setting Tool Tips

/*
    Sets the tooltip string that is displayed when the cursor pauses over the 
    header cell of the receiver.
*/
- (void)setHeaderToolTip:(CPString)aToolTip
{
    _headerToolTip = aToolTip;
}

- (CPString)headerToolTip
{
    return _headerToolTip;
}

@end

var CPTableColumnIdentifierKey   = @"CPTableColumnIdentifierKey",
    CPTableColumnHeaderViewKey   = @"CPTableColumnHeaderViewKey",
    CPTableColumnDataViewKey     = @"CPTableColumnDataViewKey",
    CPTableColumnWidthKey        = @"CPTableColumnWidthKey",
    CPTableColumnMinWidthKey     = @"CPTableColumnMinWidthKey",
    CPTableColumnMaxWidthKey     = @"CPTableColumnMaxWidthKey",
    CPTableColumnResizingMaskKey = @"CPTableColumnResizingMaskKey";

@implementation CPTableColumn (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _dataViewData = { };

        _width = [aCoder decodeFloatForKey:CPTableColumnWidthKey];
        _minWidth = [aCoder decodeFloatForKey:CPTableColumnMinWidthKey];
        _maxWidth = [aCoder decodeFloatForKey:CPTableColumnMaxWidthKey];

        [self setIdentifier:[aCoder decodeObjectForKey:CPTableColumnIdentifierKey]];
    //    [self setHeaderView:[aCoder decodeObjectForKey:CPTableColumnHeaderViewKey]];
    //    [self setDataView:[aCoder decodeObjectForKey:CPTableColumnDataViewKey]];

        [self setHeaderView:[CPTextField new]];
        [self setDataView:[CPTextField new]];


    //    _resizingMask  = [aCoder decodeBoolForKey:CPTableColumnResizingMaskKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_identifier forKey:CPTableColumnIdentifierKey];

    [aCoder encodeObject:_width forKey:CPTableColumnWidthKey];
    [aCoder encodeObject:_minWidth forKey:CPTableColumnMinWidthKey];
    [aCoder encodeObject:_maxWidth forKey:CPTableColumnMaxWidthKey];

//    [aCoder encodeObject:_headerView forKey:CPTableColumnHeaderViewKey];
//    [aCoder encodeObject:_dataView forKey:CPTableColumnDataViewKey];

//    [aCoder encodeObject:_resizingMask forKey:CPTableColumnResizingMaskKey];
}

@end

@implementation CPTableColumn (NSInCompatibility)

- (void)setHeaderCell:(CPView)aView
{
    [CPException raise:CPUnsupportedMethodException
                reason:@"setHeaderCell: is not supported. -setHeaderCell:aView instead."];
}

- (CPView)headerCell
{
    [CPException raise:CPUnsupportedMethodException
                reason:@"headCell is not supported. -headerView instead."];
}

- (void)setDataCell:(CPView)aView
{
    [CPException raise:CPUnsupportedMethodException
                reason:@"setDataCell: is not supported. Use -setHeaderCell:aView instead."];
}

- (CPView)dataCell
{
    [CPException raise:CPUnsupportedMethodException
                reason:@"dataCell is not supported. Use -dataCell instead."];
}

- (id)dataCellForRow:(int)row
{
    [CPException raise:CPUnsupportedMethodException
                reason:@"dataCellForRow: is not supported. Use -dataViewForRow:row instead."];
}

@end