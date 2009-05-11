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

@import <Foundation/Foundation.j>


/*
@ignore
*/

/*
    @global
    @class CPTableColumn
*/
CPTableColumnNoResizing         = 0;
/*
    @global
    @class CPTableColumn
*/
CPTableColumnAutoresizingMask   = 1;
/*
    @global
    @class CPTableColumn
*/
CPTableColumnUserResizingMask   = 2;

#define PurgableInfoMake(aView, aRow) { view:(aView), row:(aRow) }
#define PurgableInfoView(anInfo) ((anInfo).view)
#define PurgableInfoRow(anInfo) ((anInfo).row)

/*! @class CPTableColumn

    An CPTableColumn object mainly keeps information about the width of the column, its minimum and maximum width; whether the column can be edited or resized; and the cells used to draw the column header and the data in the column. You can change all these attributes of the column by calling the appropriate methods. Please note that the table column does not hold nor has access to the data to be displayed in the column; this data is maintained in the table view's data source.</p>
    
    <p>Each CPTableColumn object is identified by a CPString, called the column identifier. The reason is that, after a column has been added to a table view, the user might move the columns around, so there is a need to identify the columns regardless of its position in the table.
    
    @ignore
*/
@implementation CPTableColumn : CPObject
{
    CPString    _identifier;
    CPView      _headerView;
    
    CPTableView _tableView;
    
    float       _width;
    float       _minWidth;
    float       _maxWidth;
    
    unsigned    _resizingMask;

    CPView      _dataView;                  // default data view for this column

    Object      _dataViewData;              // cache of data view archives (key=data view hash, value=data view archive)
    Object      _dataViewForView;           // mapping from view instances back to their data view prototype (key=view instance hash, value=data view)
    Object      _purgableInfosForDataView;  // (key=data view hash, value=)
}

/*!
    Initializes the table column with the specified identifier.
    @param anIdentifier the identifier
    @return the initialized table column
*/
- (id)initWithIdentifier:(CPString)anIdentifier
{
    self = [super init];
    
    if (self)
    {
        [self _init];
        
        _identifier = anIdentifier;
        
        _width = 40.0;
        _minWidth = 8.0;
        _maxWidth = 1000.0;
        
        var dataView = [[CPTextField alloc] initWithFrame:CPRectMakeZero()];
        [dataView setValue:[CPColor whiteColor] forThemeAttribute:"text-color" inState:CPThemeStateHighlighted];
        
        [self setDataView:dataView];
        
        _headerView = [[CPTextField alloc] initWithFrame:CPRectMakeZero()];
        [_headerView setBackgroundColor:[CPColor greenColor]];
    }
    
    return self;
}

- (void)_init
{
    _dataViewData = {};
    _dataViewForView = {};
    _purgableInfosForDataView = {};
}

/*!
    Sets the table column's identifier
    @param anIdentifier the new identifier
*/
- (void)setIdentifier:(CPString)anIdentifier
{
    _identifier = anIdentifier;
}

/*!
    Returns the table column's identifier
*/
- (CPString)identifier
{
    return _identifier;
}

// Setting the CPTableView
/*!
    Sets the table's view. This is called automatically by Cappuccino.
    @param aTableView the new table view
*/
- (void)setTableView:(CPTableView)aTableView
{
    _tableView = aTableView;
}

/*!
    Returns the column's table view.
*/
- (CPTableView)tableView
{
    return _tableView;
}

// Controlling size
/*!
    Sets the column's width.
    @param aWidth the new column width
*/
- (void)setWidth:(float)aWidth
{
    _width = aWidth;
}

/*!
    Returns the column's width
*/
- (float)width
{
    return _width;
}

/*!
    Sets column's minimum width.
    @param aWidth the new minimum column width
*/
- (void)setMinWidth:(float)aWidth
{
    if (_width < (_minWidth = aWidth))
        [self setWidth:_minWidth];
}

/*!
    The column's minimum width
*/
- (float)minWidth
{
    return _minWidth;
}

/*!
    Sets the column's maximum width.
    @param aWidth the new maximum width
*/
- (void)setMaxWidth:(float)aWidth
{
    if (_width > (_maxmimumWidth = aWidth))
        [self setWidth:_maxWidth];
}

/*!
    Sets the resizing mask. The mask is one of:
<pre>
CPTableColumnNoResizing;
CPTableColumnAutoresizingMask;
CPTableColumnUserResizingMask;
</pre>
    @param aMask the new resizing mask 
*/
- (void)setResizingMask:(unsigned)aMask
{
    _resizingMask = aMask;
}

/*!
    Returns the column's resizing mask. One of:
<pre>
CPTableColumnNoResizing;
CPTableColumnAutoresizingMask;
CPTableColumnUserResizingMask;
</pre>
*/
- (unsigned)resizingMask
{
    return _resizingMask;
}

/*!
    Resizes the column according to the min, max and set width.
*/
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

/*!
    Sets whether the column in this data is editable.
    @param aFlag <code>YES</code> means the column data is editable
*/
- (void)setEditable:(BOOL)aFlag
{
    _isEditable = aFlag;
}

/*!
    Returns <code>YES</code> if the column data is editable.
*/
- (BOOL)isEditable
{
    return _isEditable;
}

//Setting the column header view

/*!
    Sets the view that draws the column's header.
    @param aHeaderView the view that will draws the column header
*/

- (void)setHeaderView:(CPView)aView
{
    _headerView = aView;
}

/*!
    Return the view that draws the column's header
*/
- (CPView)headerView
{
    return _headerView;
}

/*!
    Sets the data cell that draws rows in this column.
*/
- (void)setDataCell:(CPView <CPCoding>)aView
{
    [self setDataView:aView];
}

/*
    Sets the data view that draws rows in this column.
*/
- (void)setDataView:(CPView <CPCoding>)aView
{
    if (_dataView)
        _dataViewData[[_dataView hash]] = nil;
    
    _dataView = aView;
    _dataViewData[[aView hash]] = [CPKeyedArchiver archivedDataWithRootObject:aView];
}

/*!
    Returns the data cell that draws rows in this column
*/
- (CPCell)dataCell
{
    return _dataView;
}

/*
    Returns the data view that draws rows in this column
*/
- (CPView)dataView
{
    return [self dataCell];
}

/*!
    By default returns the value from <code>dataCell</code>. This can
    be overridden by a subclass to return different cells for different
    rows.
    @param aRowIndex the index of the row to obtain the cell for
*/
- (CPCell)dataCellForRow:(int)aRowIndex
{
    return [self dataView];
}

- (CPView)dataViewForRow:(int)aRowIndex
{
    return [self dataCellForRow:aRowIndex];
}
/*
- (void)_markViewAsPurgable:(CPView)aView
{
    var viewHash = [aView hash],
        dataViewHash = [_dataViewForView[viewHash] hash];
    
    if (!_purgableInfosForDataView[dataViewHash])
        _purgableInfosForDataView[dataViewHash] = [CPDictionary dictionary];
    
    [_purgableInfosForDataView[dataViewHash] setObject:aView forKey:viewHash];
}
*/
- (void)_markView:(CPView)aView inRow:(unsigned)aRow asPurgable:(BOOL)isPurgable
{
    var viewHash = [aView hash],
        dataViewHash = [_dataViewForView[viewHash] hash];
    
    if (!_purgableInfosForDataView[dataViewHash])
    {
        if (!isPurgable)
            return;
        
        _purgableInfosForDataView[dataViewHash] = {};
    }
    
    if (!isPurgable) {
        if (_purgableInfosForDataView[dataViewHash][viewHash])
            CPLog.warn("removing unpurgable " + _purgableInfosForDataView[dataViewHash][viewHash]);
        delete _purgableInfosForDataView[dataViewHash][viewHash];   
    }
    else
        _purgableInfosForDataView[dataViewHash][viewHash] = PurgableInfoMake(aView, aRow);
}

- (CPView)_newDataViewForRow:(int)aRowIndex avoidingRows:(CPRange)rows
{
    var view = [self dataViewForRow:aRowIndex],
        viewHash = [view hash],
        purgableInfos = _purgableInfosForDataView[viewHash];
    
    if (purgableInfos)
    {
        for (var key in purgableInfos)
        {
            var info = purgableInfos[key];
            //if (!CPLocationInRange(PurgableInfoRow(info), rows))
            //{
                //CPLog.debug("yes, a purged view is usable, its called: " + PurgableInfoView(info));
                delete purgableInfos[key];
                return PurgableInfoView(info);
            //}
            //else
            //    CPLog.warn("avoiding");
        }
    }
    
    // if we haven't cached an archive of the data view, do it now
    if (!_dataViewData[viewHash])
        _dataViewData[viewHash] = [CPKeyedArchiver archivedDataWithRootObject:view];

    // unarchive the data view cache
    var newView = [CPKeyedUnarchiver unarchiveObjectWithData:_dataViewData[viewHash]];
    
    // map the new view's hash to it's data view prototype
    _dataViewForView[[newView hash]] = view;
    
    CPLog.warn("creating cell: %s", newView);
    
    return newView;
}

- (void)_purge
{
    for (var viewHash in _purgableInfosForDataView)
    {
        var purgableInfos = _purgableInfosForDataView[viewHash];

        for (var key in purgableInfos)
        {
            var view = PurgableInfoView(purgableInfos[key]);
            
            if (!view)
                CPLog.info("key="+key+" view=" + view + " purgableInfos[key]="+purgableInfos[key])
            else if (view._superview) {
                //CPLog.error("PURGING: (removing)" + view);
                //[view removeFromSuperview];
                [view setHidden:YES];
            } 
            //else
            //    CPLog.warn("PURGING: (already removed)" + view);
            
            //delete purgableInfos[key];
        }
    }
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
    [self _init];
    
    _identifier = [aCoder decodeObjectForKey:CPTableColumnIdentifierKey];

    [self setHeaderView:[aCoder decodeObjectForKey:CPTableColumnHeaderViewKey]];
    [self setDataView:[aCoder decodeObjectForKey:CPTableColumnDataViewKey]];
    
    _width = [aCoder decodeFloatForKey:CPTableColumnWidthKey];
    _minWidth = [aCoder decodeFloatForKey:CPTableColumnMinWidthKey];
    _maxWidth = [aCoder decodeFloatForKey:CPTableColumnMaxWidthKey];
    
    _resizingMask  = [aCoder decodeBoolForKey:CPTableColumnResizingMaskKey];

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_identifier forKey:CPTableColumnIdentifierKey];
    
    [aCoder encodeObject:_headerView forKey:CPTableColumnHeaderViewKey];
    [aCoder encodeObject:_dataView forKey:CPTableColumnDataViewKey];
    
    [aCoder encodeObject:_width forKey:CPTableColumnWidthKey];
    [aCoder encodeObject:_minWidth forKey:CPTableColumnMinWidthKey];
    [aCoder encodeObject:_maxWidth forKey:CPTableColumnMaxWidthKey];
    
    [aCoder encodeObject:_resizingMask forKey:CPTableColumnResizingMaskKey];
}

@end
