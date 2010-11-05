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
@import <Foundation/CPIndexSet.j>
@import <Foundation/CPSortDescriptor.j>
@import <Foundation/CPString.j>

@import "CPTableHeaderView.j"


CPTableColumnNoResizing         = 0;
CPTableColumnAutoresizingMask   = 1 << 0;
CPTableColumnUserResizingMask   = 1 << 1;

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

    BOOL _disableResizingPosting @accessors(property=disableResizingPosting);
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
        _resizingMask = CPTableColumnAutoresizingMask | CPTableColumnUserResizingMask;
        _disableResizingPosting = NO;

        [self setIdentifier:anIdentifier];

        var header = [[_CPTableColumnHeaderView alloc] initWithFrame:CGRectMakeZero()];
        [self setHeaderView:header];

        [self setDataView:[CPTextField new]];
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
        var index = [[tableView tableColumns] indexOfObjectIdenticalTo:self],
            dirtyTableColumnRangeIndex = tableView._dirtyTableColumnRangeIndex;

        if (dirtyTableColumnRangeIndex < 0)
            tableView._dirtyTableColumnRangeIndex = index;
        else
            tableView._dirtyTableColumnRangeIndex = MIN(index,  tableView._dirtyTableColumnRangeIndex);

        var rows = tableView._exposedRows,
            columns = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(index, [tableView._exposedColumns lastIndex] - index + 1)];

        // FIXME: Would be faster with some sort of -setNeedsDisplayInColumns: that updates a dirtyTableColumnForDisplay cache; then marked columns would relayout their data views at display time.
        [tableView _layoutDataViewsInRows:rows columns:columns];
        [tableView tile];

        if (!_disableResizingPosting)
            [self _postDidResizeNotificationWithOldWidth:oldWidth];
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
        newWidth = MIN(width, [self maxWidth]);

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

- (unsigned)resizingMask
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

/*!
    This method set's the "prototype" view which will be used to create all table cells in this column.

    It creates a snapshot of aView, using keyed archiving, which is then copied over and over for each
    individual cell that is shown. As a result, changes made after calling this method won't be reflected.

    Example:

        [tableColumn setDataView:someView]; // snapshot taken
        [[tableColumn dataView] setSomething:x]; //won't work

    This doesn't work because the snapshot is taken before the new property is applied. Instead, do:

        [someView setSomething:x];
        [tableColumn setDataView:someView];
*/
- (void)setDataView:(CPView)aView
{
    if (_dataView)
        _dataViewData[[_dataView UID]] = nil;

    [aView setThemeState:CPThemeStateTableDataView];

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

    // make sure only we have control over the size and placement
    [newDataView setAutoresizingMask:CPViewNotSizable];

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
    shouldBeHidden = !!shouldBeHidden
    if (_isHidden === shouldBeHidden)
        return;

    _isHidden = shouldBeHidden;

    [[self headerView] setHidden:shouldBeHidden];
    [[self tableView] _tableColumnVisibilityDidChange:self];
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

- (void)_postDidResizeNotificationWithOldWidth:(float)oldWidth
{
    [[self tableView] _didResizeTableColumn:self];

    [[CPNotificationCenter defaultCenter]
    postNotificationName:CPTableViewColumnDidResizeNotification
                  object:[self tableView]
                userInfo:[CPDictionary dictionaryWithObjects:[self, oldWidth] forKeys:[@"CPTableColumn", "CPOldWidth"]]];
}

@end

@implementation CPTableColumn (Bindings)

- (void)bind:(CPString)aBinding toObject:(id)anObject withKeyPath:(CPString)aKeyPath options:(CPDictionary)options
{
    [super bind:aBinding toObject:anObject withKeyPath:aKeyPath options:options];

    if (![aBinding isEqual:@"someListOfExceptedBindings(notAcceptedBindings)"])
        [[self tableView] _establishBindingsIfUnbound:anObject];
}

- (void)prepareDataView:(CPView)aDataView forRow:(unsigned)aRow
{
    var bindingsDictionary = [CPKeyValueBinding allBindingsForObject:self],
        keys = [bindingsDictionary allKeys];

    for (var i = 0, count = [keys count]; i < count; i++)
    {
        var bindingName = keys[i],
            bindingPath = [aDataView _replacementKeyPathForBinding:bindingName],
            binding = [bindingsDictionary objectForKey:bindingName],
            bindingInfo = binding._info,
            destination = [bindingInfo objectForKey:CPObservedObjectKey],
            keyPath = [bindingInfo objectForKey:CPObservedKeyPathKey],
            dotIndex = keyPath.lastIndexOf("."),
            value;

        if (dotIndex === CPNotFound)
            value = [[destination valueForKeyPath:keyPath] objectAtIndex:aRow];
        else
        {
            /*
                Optimize the prototypical use case where the key path describes a value
                in an array. Without this optimization, we call CPArray's valueForKey
                which generates as many values as objects in the array, of which we then
                pick one and throw away the rest.

                The optimization is to get the array and access the value directly. This
                turns the operation into a single access regardless of how long the model
                array is.
            */

            var firstPart = keyPath.substring(0, dotIndex),
                secondPart = keyPath.substring(dotIndex + 1),
                firstValue = [destination valueForKeyPath:firstPart];

            if ([firstValue isKindOfClass:CPArray])
                value = [[firstValue objectAtIndex:aRow] valueForKeyPath:secondPart];
            else
                value = [[firstValue valueForKeyPath:secondPart] objectAtIndex:aRow];
        }

        value = [binding transformValue:value withOptions:[bindingInfo objectForKey:CPOptionsKey]];

        // console.log(bindingName+" : "+keyPath+" : "+aRow+" : "+[[destination valueForKeyPath:keyPath] objectAtIndex:aRow]);
        [aDataView setValue:value forKey:bindingPath];
    }
}

//- (void)objectValue
//{
//    return nil;
//}

- (void)setValue:(CPArray)content
{
    [[self tableView] reloadData];
}

@end

var CPTableColumnIdentifierKey   = @"CPTableColumnIdentifierKey",
    CPTableColumnHeaderViewKey   = @"CPTableColumnHeaderViewKey",
    CPTableColumnDataViewKey     = @"CPTableColumnDataViewKey",
    CPTableColumnWidthKey        = @"CPTableColumnWidthKey",
    CPTableColumnMinWidthKey     = @"CPTableColumnMinWidthKey",
    CPTableColumnMaxWidthKey     = @"CPTableColumnMaxWidthKey",
    CPTableColumnResizingMaskKey = @"CPTableColumnResizingMaskKey",
    CPTableColumnIsHiddenKey     = @"CPTableColumnIsHiddenKey",
    CPSortDescriptorPrototypeKey = @"CPSortDescriptorPrototypeKey",
    CPTableColumnIsEditableKey   = @"CPTableColumnIsEditableKey";

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
        [self setHeaderView:[aCoder decodeObjectForKey:CPTableColumnHeaderViewKey]];
        [self setDataView:[aCoder decodeObjectForKey:CPTableColumnDataViewKey]];
        [self setHeaderView:[aCoder decodeObjectForKey:CPTableColumnHeaderViewKey]];

        _resizingMask  = [aCoder decodeIntForKey:CPTableColumnResizingMaskKey];
        _isHidden = [aCoder decodeBoolForKey:CPTableColumnIsHiddenKey];
        _isEditable = [aCoder decodeBoolForKey:CPTableColumnIsEditableKey];

        _sortDescriptorPrototype = [aCoder decodeObjectForKey:CPSortDescriptorPrototypeKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_identifier forKey:CPTableColumnIdentifierKey];

    [aCoder encodeObject:_width forKey:CPTableColumnWidthKey];
    [aCoder encodeObject:_minWidth forKey:CPTableColumnMinWidthKey];
    [aCoder encodeObject:_maxWidth forKey:CPTableColumnMaxWidthKey];

    [aCoder encodeObject:_headerView forKey:CPTableColumnHeaderViewKey];
    [aCoder encodeObject:_dataView forKey:CPTableColumnDataViewKey];

    [aCoder encodeObject:_resizingMask forKey:CPTableColumnResizingMaskKey];
    [aCoder encodeBool:_isHidden forKey:CPTableColumnIsHiddenKey];
    [aCoder encodeBool:_isEditable forKey:CPTableColumnIsEditableKey];

    [aCoder encodeObject:_sortDescriptorPrototype forKey:CPSortDescriptorPrototypeKey];
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
