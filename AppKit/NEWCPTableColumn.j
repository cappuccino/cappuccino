
@import <Foundation/CPDictionary.j>
@import <Foundation/CPObject.j>
@import <Foundation/CPSortDescriptor.j>
@import <Foundation/CPString.j>

@import "CPTableHeaderView.j"

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


@implementation NEWCPTableColumn : CPObject
{
    CPTableView         _tableView;
    CPView              _headerView;
    
    float               _width;
    float               _minWidth;
    float               _maxWidth;

    id                  _identifier;
    BOOL                _isEditable;
    CPSortDescriptor    _sortDescriptorPrototype;
    BOOL                _isHidden;
    CPString            _headerToolTip;
}

- (id)initWithIdentifier:(id)anIdentifier
{
    self = [super init];

    if (self)
    {
        [self setIdentifier:anIdentifier];
        [self setHeaderView:[CPTableHeaderView new]];
    }

    return self
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
        [[CPNotificationCenter defaultCenter]
            postNotificationName:CPTableViewColumnDidResizeNotification
                          object:tableView
                        userInfo:[CPDictionary dictionaryWithObjects:[self, oldWidth] forKeys:[@"CPTableColumn", "CPOldWidth"]]];
}

- (float)width
{
    return _width;
}

– (void)setMinWidth:(float)aMinWidth
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

– (void)setMaxWidth:(float)aMaxWidth
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

– (void)setResizingMask:(unsigned)aResizingMask
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
    if (!_headerView)
        [CPException raise:CPInvalidArgumentException reason:@"Attempt to set nil header view on " + [self description]];
        
    _headerView = aView;
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
    to be invoked with row equal to –1 in cases where no actual row is involved but the table
    view needs to get some generic cell info.
*/
– (id)dataViewForRow:(int)aRowIndex
{
    return [self dataView];
}

- (id)_newDataViewForRow:(int)aRowIndex
{
    var dataView = [self dataViewForRow:aRowIndex],
        dataViewUID = [view UID];

    // if we haven't cached an archive of the data view, do it now
    if (!_dataViewData[dataViewUID])
        _dataViewData[dataViewUID] = [CPKeyedArchiver archivedDataWithRootObject:dataView];

    // unarchive the data view cache
    var newDataView = [CPKeyedUnarchiver unarchiveObjectWithData:_dataViewData[dataViewUID]];

    return newView;
}

//Setting the Identifier

/*
    Sets the receiver’s identifier to anIdentifier.
*/
– (void)setIdentifier:(id)anIdentifier
{
    _identifier = anIdentifier;
}

/*
    Returns the object used by the data source to identify the attribute corresponding to the receiver.
*/
– (id)identifier
{
    return _identifier;
}  


//Controlling Editability

/*
    Controls whether the user can edit cells in the receiver by double-clicking them.
*/
– (void)setEditable:(BOOL)shouldBeEditable
{
    _isEditable = shouldBeEditable;
}

/*
    Returns YES if the user can edit cells associated with the receiver by double-clicking the 
    column in the NSTableView, NO otherwise.
*/
– (BOOL)isEditable
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
– (BOOL)isHidden
{
    return _isHidden;
}


– (void)setHidden:(BOOL)shouldBeHidden:
{
    _isHidden = shouldBeHidden;
}


//Setting Tool Tips

/*
    Sets the tooltip string that is displayed when the cursor pauses over the 
    header cell of the receiver.
*/

– (void)setHeaderToolTip:(CPString)aToolTip  
{
    _headerToolTip = aToolTip;
}


– (CPString)headerToolTip
{
    return _headerToolTip;
}

@end


@implementation NEWCPTableColumn (NSInCompatibility)

- (void)setHeaderCell:(CPView)aView
{
    [CPException raise:CPUnsupportedMethodException
                reason:"Not supported. -setHeaderCell:aView instead."];
}

- (CPView)headerCell
{
    [CPException raise:CPUnsupportedMethodException
                reason:"Not supported. -headerView instead."];
}

- (void)setDataCell:(CPView)aView
{
    [CPException raise:CPUnsupportedMethodException
                reason:"Not supported. Use -setHeaderCell:aView instead."];
}

- (CPView)dataCell
{
    [CPException raise:CPUnsupportedMethodException
                reason:"Not supported. Use -dataCell instead."];
}

- (id)dataCellForRow:(int)row
{
    [CPException raise:CPUnsupportedMethodException
                reason:"Not supported. Use -dataViewForRow:row instead."];
}

@end
