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

@import "CPTextField.j"

@global CPTableViewColumnDidResizeNotification

@class _CPTableColumnHeaderView

CPTableColumnNoResizing         = 0;
CPTableColumnAutoresizingMask   = 1 << 0;
CPTableColumnUserResizingMask   = 1 << 1;

/*!
    @class CPTableColumn

    A CPTableColumn contains a dataview to display for its column of the CPTableView.
    A CPTableColumn determines its own size constrains and resizing behavior.

    The default dataview is a CPTextField but you can set it to any view you'd like. See -setDataView: for documentation including theme states.

    To customize the text of the column header you can simply call setStringValue: on the headerview of a table column.
    For example: [[myTableColumn headerView] setStringValue:"My Title"];
*/
@implementation CPTableColumn : CPObject
{
    CPTableView         _tableView;
    CPView              _headerView;
    CPView              _dataView;
    CPData              _dataViewData;

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

/*!
    @ignore
*/
- (id)init
{
    return [self initWithIdentifier:@""];
}

/*!
    Initializes a newly created CPTableColumn with a given identifier.

*/
- (id)initWithIdentifier:(id)anIdentifier
{
    self = [super init];

    if (self)
    {
        _dataViewData = nil;

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

/*!
    Set the columns's parent tableview
*/
- (void)setTableView:(CPTableView)aTableView
{
    _tableView = aTableView;
}

/*!
    Return the column's parent tableview
*/
- (CPTableView)tableView
{
    return _tableView;
}

/*!
    @ignore
    this method tries to resize a column called via the tableview via autoresizing
    it returns the delta from the actual resize and the proposed resize

    for example if the column should have been resized 50px but the maxWidth was hit only
    after 25px then the return value would be 25px;

    if no edge has been hit zero will be returned
*/
- (int)_tryToResizeToWidth:(int)width
{
    var min = [self minWidth],
        max = [self maxWidth],
        newWidth = ROUND(MIN(MAX(width, min), max));

    [self setWidth:newWidth];

    return newWidth - width;
}

/*!
    Set the width of the column
    Default value is: 100

    If the value is greater than the maxWidth the maxWidth will be reset with the supplied width here
    If the value is less than the minWidth the minWidth will be reset with the supplied width.
*/
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

/*!
    Returns the column's width
*/
- (float)width
{
    return _width;
}

/*!
    Sets the minimum width of the column.
    Default value is 10.
*/
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

/*!
    Returns the minimum width of the column.
*/
- (float)minWidth
{
    return _minWidth;
}

/*!
    Sets the maximum width of the table column.
    Default value is: 1000000
*/
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

/*!
    Returns the maximum width of the column
*/
- (float)maxWidth
{
    return _maxWidth;
}

/*!
<pre>
    Set the resizing mask of the column.
    By default the column can be resized automatically with the tableview and manually by the user

    Possible masking values are:
    CPTableColumnNoResizing
    CPTableColumnAutoresizingMask
    CPTableColumnUserResizingMask
</pre>
*/
- (void)setResizingMask:(unsigned)aResizingMask
{
    _resizingMask = aResizingMask;
}


/*!
    Returns the resizing mask of the column
*/
- (unsigned)resizingMask
{
    return _resizingMask;
}

/*!
    Sizes the column to fix the column header text.
*/
- (void)sizeToFit
{
    var width = CGRectGetWidth([_headerView frame]);

    if (width < [self minWidth])
        [self setMinWidth:width];
    else if (width > [self maxWidth])
        [self setMaxWidth:width]

    if (_width !== width)
        [self setWidth:width];
}


/*!
    Sets the header view for the column.
    The headerview handles the display of sort indicators, text, etc.

    If you do not want a headerview for you table you should call setHeaderView: on your CPTableView instance.
    Passing nil here will throw an exception.

    In order to customize the text of the column header see - (CPView)headerView;
*/
- (void)setHeaderView:(CPView)aView
{
    if (!aView)
        [CPException raise:CPInvalidArgumentException reason:@"Attempt to set nil header view on " + [self description]];

    _headerView = aView;

    var tableHeaderView = [_tableView headerView];

    [tableHeaderView setNeedsLayout];
    [tableHeaderView setNeedsDisplay:YES];
}

/*!
    Returns the headerview for the column.

    In order to change the text of the headerview for a column you should call setStringValue: on the headerview.
    For example: [[myTableColumn headerView] setStringValue:"My Column"];
*/
- (CPView)headerView
{
    return _headerView;
}

/*!
    This method sets the "prototype" view which will be used to create all table cells in this column.

    It creates a snapshot of aView, using keyed archiving, which is then copied over and over for each
    individual cell that is shown. As a result, changes made after calling this method won't be reflected.

    Example:
        @code
        [tableColumn setDataView:someView]; // snapshot taken
        [[tableColumn dataView] setSomething:x]; //won't work
        @endcode

    This doesn't work because the snapshot is taken before the new property is applied. Instead, do:
        @code
        [someView setSomething:x];
        [tableColumn setDataView:someView];
        @endcode

    @note you should implement CPKeyedArchiving otherwise you might see unexpected results.
    This is done by adding the following methods to your class:
    @endnote

    @code
    - (id)initWithCoder(CPCoder)aCoder;
    - (void)encodeWithCoder:(CPCoder)aCoder;
    @endcode

    Example:
    Say you have two instance variables in your object that need to be set up each time an object is create.
    We will call these instance variables "image" and "text".
    Your CPCoding methods will look like the following:

    @code
    - (id)initWithCoder:(CPCoder)aCoder
    {
        self = [super initWithCoder:aCoder];

        if (self)
        {
            image = [aCoder decodeObjectForKey:"MyDataViewImage"];
            text = [aCoder decodeObjectForKey:"MyDataViewText"];
        }

        return self;
    }

    - (void)encodeWithCoder:(CPCoder)aCoder
    {
        [super encodeWithCoder:aCoder];

        [aCoder encodeObject:image forKey:"MyDataViewImage"];
        [aCoder encodeObject:text forKey:"MyDataViewText"];
    }
    @endcode

    @section Themeing

    When you set a dataview and it is added to the tableview the theme state will be set to \c CPThemeStateTableDataView
    When the dataview becomes selected the theme state will be set to \c CPThemeStateSelectedDataView.

    If the dataview shows up in a group row of the tableview the theme state will be set to \c CPThemeStateGroupRow.

    You should overide \c setThemeState: and \c unsetThemeState: to handle these theme state changes in your dataview.
*/
- (void)setDataView:(CPView)aView
{
    if (_dataView)
        _dataViewData = nil;

    [aView setThemeState:CPThemeStateTableDataView];

    _dataView = aView;
    _dataViewData = [CPKeyedArchiver archivedDataWithRootObject:aView];
}

- (CPView)dataView
{
    return _dataView;
}

/*
    Returns the CPView object used by the CPTableView to draw values for the receiver.

    By default, this method just calls dataView. Subclassers can override if they need to
    potentially use different "cells" or dataViews for different rows. Subclasses should expect this method
    to be invoked with row equal to -1 in cases where no actual row is involved but the table
    view needs to get some generic cell info.
*/
- (id)dataViewForRow:(int)aRowIndex
{
    return [self dataView];
}

/*!
    @ignore
*/
- (id)_newDataView
{
    if (!_dataViewData)
        return nil;

    var newDataView = [CPKeyedUnarchiver unarchiveObjectWithData:_dataViewData];
    [newDataView setAutoresizingMask:CPViewNotSizable];

    return newDataView;
}

//Setting the Identifier

/*!
    Sets the receiver identifier to anIdentifier.
*/
- (void)setIdentifier:(id)anIdentifier
{
    _identifier = anIdentifier;
}

/*!
    Returns the object used by the data source to identify the attribute corresponding to the receiver.
*/
- (id)identifier
{
    return _identifier;
}

//Controlling Editability

/*!
    Controls whether the user can edit cells in the receiver by double-clicking them.
*/
- (void)setEditable:(BOOL)shouldBeEditable
{
    _isEditable = shouldBeEditable;
}

/*!
    Returns YES if the user can edit cells associated with the receiver by double-clicking the
    column in the CPTableView, NO otherwise.
*/
- (BOOL)isEditable
{
    return _isEditable;
}

/*!
    Sets the sort descriptor prototype for the column.
*/
- (void)setSortDescriptorPrototype:(CPSortDescriptor)aSortDescriptor
{
    _sortDescriptorPrototype = aSortDescriptor;
}

/*!
    Returns the sort descriptor prototype for the column.
*/
- (CPSortDescriptor)sortDescriptorPrototype
{
    if (_sortDescriptorPrototype)
        return _sortDescriptorPrototype;

    var binderClass = [[self class] _binderClassForBinding:CPValueBinding],
        binding = [binderClass getBinding:CPValueBinding forObject:self];

    return [binding _defaultSortDescriptorPrototype];
}

/*!
    If YES the tablecolumn will no longer be visible in the tableview.
    If NO the tablecolumn will be visible in the tableview.
*/
- (void)setHidden:(BOOL)shouldBeHidden
{
    shouldBeHidden = !!shouldBeHidden

    if (_isHidden === shouldBeHidden)
        return;

    _isHidden = shouldBeHidden;

    [[self headerView] setHidden:shouldBeHidden];
    [[self tableView] _tableColumnVisibilityDidChange:self];
}

/*!
    Returns the visibility status of the column.
*/
- (BOOL)isHidden
{
    return _isHidden;
}

//Setting Tool Tips

/*!
    Sets the tooltip string that is displayed when the cursor pauses over the
    header cell of the receiver.
*/
- (void)setHeaderToolTip:(CPString)aToolTip
{
    _headerToolTip = aToolTip;
}

/*!
    Returns the tooltip for the column header
*/
- (CPString)headerToolTip
{
    return _headerToolTip;
}

/*!
    @ignore
*/
- (void)_postDidResizeNotificationWithOldWidth:(float)oldWidth
{
    [[self tableView] _didResizeTableColumn:self];

    [[CPNotificationCenter defaultCenter]
    postNotificationName:CPTableViewColumnDidResizeNotification
                  object:[self tableView]
                userInfo:@{ @"CPTableColumn": self, @"CPOldWidth": oldWidth }];
}

@end

@implementation CPTableColumnValueBinder : CPBinder
{
}

- (void)setValueFor:(CPString)aBinding
{
    var tableView = [_source tableView],
        column = [[tableView tableColumns] indexOfObjectIdenticalTo:_source],
        rowIndexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [tableView numberOfRows])],
        columnIndexes = [CPIndexSet indexSetWithIndex:column];

    [tableView reloadDataForRowIndexes:rowIndexes columnIndexes:columnIndexes];
}

- (CPSortDescriptor)_defaultSortDescriptorPrototype
{
    if (![self createsSortDescriptor])
        return nil;

    var keyPath = [_info objectForKey:CPObservedKeyPathKey],
        dotIndex = keyPath.indexOf(".");

    if (dotIndex === CPNotFound)
        return nil;

    var firstPart = keyPath.substring(0, dotIndex),
        key = keyPath.substring(dotIndex + 1);

    return [CPSortDescriptor sortDescriptorWithKey:key ascending:YES];
}

- (BOOL)createsSortDescriptor
{
    var options = [_info objectForKey:CPOptionsKey],
        optionValue = [options objectForKey:CPCreatesSortDescriptorBindingOption];
    return optionValue === nil ? YES : [optionValue boolValue];
}

@end

@implementation CPTableColumn (Bindings)

+ (id)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding == CPValueBinding)
        return [CPTableColumnValueBinder class];

    return [super _binderClassForBinding:aBinding];
}

/*!
    Binds the receiver to an object.

    @param CPString aBinding - The binding you wish to make. Typically CPValueBinding.
    @param id anObject - The object to bind the receiver to.
    @param CPString aKeyPath - The key path you wish to bind the receiver to.
    @param CPDictionary options - A dictionary of options for the binding. This parameter is optional, pass nil if you do not wish to use it.
*/
- (void)bind:(CPString)aBinding toObject:(id)anObject withKeyPath:(CPString)aKeyPath options:(CPDictionary)options
{
    [super bind:aBinding toObject:anObject withKeyPath:aKeyPath options:options];

    if (![aBinding isEqual:@"someListOfExceptedBindings(notAcceptedBindings)"])
    {
        // Bind the table to the array controller this column is bound to.
        // Note that anObject might not be the array controller. E.g. the keypath could be something like
        // somePathTo.anArrayController.arrangedObjects.aKey. Cocoa doesn't support this but it is consistent
        // and it makes sense.
        var acIndex = aKeyPath.lastIndexOf("arrangedObjects."),
            arrayController = anObject;

        if (acIndex > 1)
        {
            var firstPart = aKeyPath.substring(0, acIndex - 1);
            arrayController = [anObject valueForKeyPath:firstPart];
        }

        [[self tableView] _establishBindingsIfUnbound:arrayController];
    }
}

/*!
    @ignore
*/
- (void)_prepareDataView:(CPView)aDataView forRow:(unsigned)aRow
{
    var bindingsDictionary = [CPBinder allBindingsForObject:self],
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
        [aDataView setValue:value forKey:@"objectValue"];
    }
}

/*!
    @ignore
*/
- (void)_reverseSetDataView:(CPView)aDataView forRow:(unsigned)aRow
{
    var bindingsDictionary = [CPBinder allBindingsForObject:self],
        keys = [bindingsDictionary allKeys],
        newValue = [aDataView valueForKey:@"objectValue"];

    for (var i = 0, count = [keys count]; i < count; i++)
    {
        var bindingName = keys[i],
            bindingPath = [aDataView _replacementKeyPathForBinding:bindingName],
            binding = [bindingsDictionary objectForKey:bindingName],
            bindingInfo = binding._info,
            destination = [bindingInfo objectForKey:CPObservedObjectKey],
            keyPath = [bindingInfo objectForKey:CPObservedKeyPathKey],
            options = [bindingInfo objectForKey:CPOptionsKey],
            dotIndex = keyPath.lastIndexOf(".");

        newValue = [binding reverseTransformValue:newValue withOptions:options];

        if (dotIndex === CPNotFound)
            [[destination valueForKeyPath:keyPath] replaceObjectAtIndex:aRow withObject:newValue];
        else
        {
            var firstPart = keyPath.substring(0, dotIndex),
                secondPart = keyPath.substring(dotIndex + 1),
                firstValue = [destination valueForKeyPath:firstPart];

            if ([firstValue isKindOfClass:CPArray])
                 [[firstValue objectAtIndex:aRow] setValue:newValue forKeyPath:secondPart];
            else
                 [[firstValue valueForKeyPath:secondPart] replaceObjectAtIndex:aRow withObject:newValue];
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
    CPTableColumnResizingMaskKey = @"CPTableColumnResizingMaskKey",
    CPTableColumnIsHiddenKey     = @"CPTableColumnIsHiddenKey",
    CPSortDescriptorPrototypeKey = @"CPSortDescriptorPrototypeKey",
    CPTableColumnIsEditableKey   = @"CPTableColumnIsEditableKey";

@implementation CPTableColumn (CPCoding)

/*!
    @ignore
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _dataViewData = nil;

        _width = [aCoder decodeFloatForKey:CPTableColumnWidthKey];
        _minWidth = [aCoder decodeFloatForKey:CPTableColumnMinWidthKey];
        _maxWidth = [aCoder decodeFloatForKey:CPTableColumnMaxWidthKey];

        [self setIdentifier:[aCoder decodeObjectForKey:CPTableColumnIdentifierKey]];
        [self setHeaderView:[aCoder decodeObjectForKey:CPTableColumnHeaderViewKey]];
        [self setDataView:[aCoder decodeObjectForKey:CPTableColumnDataViewKey]];

        _resizingMask  = [aCoder decodeIntForKey:CPTableColumnResizingMaskKey];
        _isHidden = [aCoder decodeBoolForKey:CPTableColumnIsHiddenKey];
        _isEditable = [aCoder decodeBoolForKey:CPTableColumnIsEditableKey];

        _sortDescriptorPrototype = [aCoder decodeObjectForKey:CPSortDescriptorPrototypeKey];
    }

    return self;
}

/*!
    @ignore
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_identifier forKey:CPTableColumnIdentifierKey];

    [aCoder encodeFloat:_width forKey:CPTableColumnWidthKey];
    [aCoder encodeFloat:_minWidth forKey:CPTableColumnMinWidthKey];
    [aCoder encodeFloat:_maxWidth forKey:CPTableColumnMaxWidthKey];

    [aCoder encodeObject:_headerView forKey:CPTableColumnHeaderViewKey];
    [aCoder encodeObject:_dataView forKey:CPTableColumnDataViewKey];

    [aCoder encodeObject:_resizingMask forKey:CPTableColumnResizingMaskKey];
    [aCoder encodeBool:_isHidden forKey:CPTableColumnIsHiddenKey];
    [aCoder encodeBool:_isEditable forKey:CPTableColumnIsEditableKey];

    [aCoder encodeObject:_sortDescriptorPrototype forKey:CPSortDescriptorPrototypeKey];
}

@end

@implementation CPTableColumn (NSInCompatibility)
/*!
    @ignore
*/
- (void)setHeaderCell:(CPView)aView
{
    [CPException raise:CPUnsupportedMethodException
                reason:@"setHeaderCell: is not supported. Use -setHeaderView:aView instead."];
}

/*!
    @ignore
*/
- (CPView)headerCell
{
    [CPException raise:CPUnsupportedMethodException
                reason:@"headCell is not supported. Use -headerView instead."];
}

/*!
    @ignore
*/
- (void)setDataCell:(CPView)aView
{
    [CPException raise:CPUnsupportedMethodException
                reason:@"setDataCell: is not supported. Use -setDataView:aView instead."];
}

/*!
    @ignore
*/
- (CPView)dataCell
{
    [CPException raise:CPUnsupportedMethodException
                reason:@"dataCell is not supported. Use -dataView instead."];
}

/*!
    @ignore
*/
- (id)dataCellForRow:(int)row
{
    [CPException raise:CPUnsupportedMethodException
                reason:@"dataCellForRow: is not supported. Use -dataViewForRow:row instead."];
}

@end
