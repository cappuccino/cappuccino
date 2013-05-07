/*
 * CPOutlineView.j
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

@import "CPButton.j"
@import "CPTableColumn.j"
@import "CPTableView.j"

@global CPApp

CPOutlineViewColumnDidMoveNotification          = @"CPOutlineViewColumnDidMoveNotification";
CPOutlineViewColumnDidResizeNotification        = @"CPOutlineViewColumnDidResizeNotification";
CPOutlineViewItemDidCollapseNotification        = @"CPOutlineViewItemDidCollapseNotification";
CPOutlineViewItemDidExpandNotification          = @"CPOutlineViewItemDidExpandNotification";
CPOutlineViewItemWillCollapseNotification       = @"CPOutlineViewItemWillCollapseNotification";
CPOutlineViewItemWillExpandNotification         = @"CPOutlineViewItemWillExpandNotification";
CPOutlineViewSelectionDidChangeNotification     = @"CPOutlineViewSelectionDidChangeNotification";
CPOutlineViewSelectionIsChangingNotification    = @"CPOutlineViewSelectionIsChangingNotification";

var CPOutlineViewDataSource_outlineView_objectValue_forTableColumn_byItem_                          = 1 << 1,
    CPOutlineViewDataSource_outlineView_setObjectValue_forTableColumn_byItem_                       = 1 << 2,
    CPOutlineViewDataSource_outlineView_shouldDeferDisplayingChildrenOfItem_                        = 1 << 3,

    CPOutlineViewDataSource_outlineView_acceptDrop_item_childIndex_                                 = 1 << 4,
    CPOutlineViewDataSource_outlineView_validateDrop_proposedItem_proposedChildIndex_               = 1 << 5,
    CPOutlineViewDataSource_outlineView_validateDrop_proposedRow_proposedDropOperation_             = 1 << 6,
    CPOutlineViewDataSource_outlineView_namesOfPromisedFilesDroppedAtDestination_forDraggedItems_   = 1 << 7,

    CPOutlineViewDataSource_outlineView_itemForPersistentObject_                                    = 1 << 8,
    CPOutlineViewDataSource_outlineView_persistentObjectForItem_                                    = 1 << 9,

    CPOutlineViewDataSource_outlineView_writeItems_toPasteboard_                                    = 1 << 10,

    CPOutlineViewDataSource_outlineView_sortDescriptorsDidChange_                                   = 1 << 11;

var CPOutlineViewDelegate_outlineView_dataViewForTableColumn_item_                                  = 1 << 1,
    CPOutlineViewDelegate_outlineView_viewForTableColumn_item_                                      = 1 << 26,
    CPOutlineViewDelegate_outlineView_didClickTableColumn_                                          = 1 << 2,
    CPOutlineViewDelegate_outlineView_didDragTableColumn_                                           = 1 << 3,
    CPOutlineViewDelegate_outlineView_heightOfRowByItem_                                            = 1 << 4,
    CPOutlineViewDelegate_outlineView_isGroupItem_                                                  = 1 << 5,
    CPOutlineViewDelegate_outlineView_mouseDownInHeaderOfTableColumn_                               = 1 << 6,
    CPOutlineViewDelegate_outlineView_nextTypeSelectMatchFromItem_toItem_forString_                 = 1 << 7,
    CPOutlineViewDelegate_outlineView_selectionIndexesForProposedSelection_                         = 1 << 8,
    CPOutlineViewDelegate_outlineView_shouldCollapseItem_                                           = 1 << 9,
    CPOutlineViewDelegate_outlineView_shouldEditTableColumn_item_                                   = 1 << 10,
    CPOutlineViewDelegate_outlineView_shouldExpandItem_                                             = 1 << 11,
    CPOutlineViewDelegate_outlineView_shouldReorderColumn_toColumn_                                 = 1 << 12,
    CPOutlineViewDelegate_outlineView_shouldSelectItem_                                             = 1 << 13,
    CPOutlineViewDelegate_outlineView_shouldSelectTableColumn_                                      = 1 << 14,
    CPOutlineViewDelegate_outlineView_shouldShowOutlineDisclosureControlForItem_                    = 1 << 15,
    CPOutlineViewDelegate_outlineView_shouldShowViewExpansionForTableColumn_item_                   = 1 << 16,
    CPOutlineViewDelegate_outlineView_shouldTrackView_forTableColumn_item_                          = 1 << 17,
    CPOutlineViewDelegate_outlineView_shouldTypeSelectForEvent_withCurrentSearchString_             = 1 << 18,
    CPOutlineViewDelegate_outlineView_sizeToFitWidthOfColumn_                                       = 1 << 19,
    CPOutlineViewDelegate_outlineView_toolTipForView_rect_tableColumn_item_mouseLocation_           = 1 << 20,
    CPOutlineViewDelegate_outlineView_typeSelectStringForTableColumn_item_                          = 1 << 21,
    CPOutlineViewDelegate_outlineView_willDisplayOutlineView_forTableColumn_item_                   = 1 << 22,
    CPOutlineViewDelegate_outlineView_willDisplayView_forTableColumn_item_                          = 1 << 23,
    CPOutlineViewDelegate_selectionShouldChangeInOutlineView_                                       = 1 << 24,
    CPOutlineViewDelegate_outlineView_menuForTableColumn_item_                                      = 1 << 25;

CPOutlineViewDropOnItemIndex = -1;

var CPOutlineViewCoalesceSelectionNotificationStateOff  = 0,
    CPOutlineViewCoalesceSelectionNotificationStateOn   = 1,
    CPOutlineViewCoalesceSelectionNotificationStateDid  = 2;

#define SELECTION_SHOULD_CHANGE(anOutlineView) (!((anOutlineView)._implementedOutlineViewDelegateMethods & CPOutlineViewDelegate_selectionShouldChangeInOutlineView_) || [(anOutlineView)._outlineViewDelegate selectionShouldChangeInOutlineView:(anOutlineView)])

#define SHOULD_SELECT_ITEM(anOutlineView, anItem) (!((anOutlineView)._implementedOutlineViewDelegateMethods & CPOutlineViewDelegate_outlineView_shouldSelectItem_) || [(anOutlineView)._outlineViewDelegate outlineView:(anOutlineView) shouldSelectItem:(anItem)])

/*!
    @ingroup appkit
    @class CPOutlineView

    CPOutlineView is a subclass of CPTableView that inherits the row and
    column format to display hierarchical data. The outlineview adds the
    ability to expand and collapse items. This is useful for browsing a tree
    like structure such as directories or a filesystem.

    Like the tableview, an outlineview uses a data source to supply its data.
    For this reason you must implement a couple data source methods
    (documented in setDataSource:).

    Theme states for custom data views are documented in CPTableView.
*/
@implementation CPOutlineView : CPTableView
{
    id              _outlineViewDataSource;
    id              _outlineViewDelegate;
    CPTableColumn   _outlineTableColumn;

    float           _indentationPerLevel;
    BOOL            _indentationMarkerFollowsDataView;

    CPInteger       _implementedOutlineViewDataSourceMethods;
    CPInteger       _implementedOutlineViewDelegateMethods;

    Object          _rootItemInfo;
    CPMutableArray  _itemsForRows;
    Object          _itemInfosForItems;

    CPControl       _disclosureControlPrototype;
    CPArray         _disclosureControlsForRows;
    CPData          _disclosureControlData;
    CPArray         _disclosureControlQueue;

    BOOL            _shouldRetargetItem;
    id              _retargetedItem;

    BOOL            _shouldRetargetChildIndex;
    CPInteger       _retargedChildIndex;
    CPTimer         _dragHoverTimer;
    id              _dropItem;

    BOOL            _coalesceSelectionNotificationState;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _selectionHighlightStyle = CPTableViewSelectionHighlightStyleSourceList;

        // The root item has weight "0", thus represents the weight solely of its descendants.
        _rootItemInfo = { isExpanded:YES, isExpandable:NO, shouldShowOutlineDisclosureControl:NO, level:-1, row:-1, children:[], weight:0 };

        _itemsForRows = [];
        _itemInfosForItems = { };
        _disclosureControlsForRows = [];

        _retargetedItem = nil;
        _shouldRetargetItem = NO;

        _retargedChildIndex = nil;
        _shouldRetargetChildIndex = NO;

        [self setIndentationPerLevel:16.0];
        [self setIndentationMarkerFollowsDataView:YES];

        [super setDataSource:[[_CPOutlineViewTableViewDataSource alloc] initWithOutlineView:self]];
        [super setDelegate:[[_CPOutlineViewTableViewDelegate alloc] initWithOutlineView:self]];

        [self setDisclosureControlPrototype:[[CPDisclosureButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 10.0)]];
    }

    return self;
}
/*!
    In addition to standard delegation, the outline view also supports data
    source delegation. This method sets the data source object. Just like the
    TableView you have CPTableColumns but instead of rows you deal with items.

    @section required You must implement these data source methods:

    Returns the child item at an index of a given item. if item is nil you should return the appropriate root item.
    @code - (id)outlineView:(CPOutlineView)outlineView child:(CPInteger)index ofItem:(id)item; @endcode

    Returns YES if the item is expandable, otherwise NO.
    @code - (BOOL)outlineView:(CPOutlineView)outlineView isItemExpandable:(id)item; @endcode

    Returns the number of child items of a given item. If item is nil you should return the number of top level (root) items.
    @code - (int)outlineView:(CPOutlineView)outlineView numberOfChildrenOfItem:(id)item; @endcode

    Returns the object value of the item in a given column.
    @code - (id)outlineView:(CPOutlineView)outlineView objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item; @endcode

    ---------

    @section optional The following methods are optional:

    @section editin Editing:
    Sets the data object value for an item in a given column. This needs to be implemented if you want inline editing support.
    @code - (void)outlineView:(CPOutlineView)outlineView setObjectValue:(id)object forTableColumn:(CPTableColumn)tableColumn byItem:(id)item; @endcode


    @section sorting Sorting:
    The outlineview will call this method if you click the table header. You should sort the datasource based off of the new sort descriptors and reload the data
    @code - (void)outlineView:(CPOutlineView)outlineView sortDescriptorsDidChange:(CPArray)oldDescriptors; @endcode

    @section draganddrop Drag and Drop:
    @note In order for the outlineview to receive drops don't forget to first
    register the tableview for drag types like you do with every other view @endnote

    Return YES if the operation was successful otherwise return NO.
    The data source should incorporate the data from the dragging pasteboard in this method implementation.
    To get this data use the draggingPasteboard method on the CPDraggingInfo object.
    @code - (BOOL)outlineView:(CPOutlineView)outlineView acceptDrop:(id < CPDraggingInfo >)info item:(id)item childIndex:(CPInteger)index; @endcode


    Return the drag operation (move, copy, etc) that should be performed if a registered drag type is over the tableview
    The data source can retarget a drop if you want by calling <pre>-(void)setDropItem:(id)anItem dropChildIndex:(int)anIndex;</pre>
    @code - (CPDragOperation)outlineView:(CPOutlineView)outlineView validateDrop:(id < CPDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(CPInteger)index; @endcode

    Returns YES if the drop operation is allowed otherwise NO.
    This method is invoked by the outlineview after a drag should begin, but before it is started. If you don't want the drag to being return NO.
    If you want the drag to begin you should return YES and place the drag data on the pboard.
    @code - (BOOL)outlineView:(CPOutlineView)outlineView writeItems:(CPArray)items toPasteboard:(CPPasteboard)pboard; @endcode
*/
- (void)setDataSource:(id)aDataSource
{
    if (_outlineViewDataSource === aDataSource)
        return;

    if (![aDataSource respondsToSelector:@selector(outlineView:child:ofItem:)])
        [CPException raise:CPInternalInconsistencyException reason:"Data source must implement 'outlineView:child:ofItem:'"];

    if (![aDataSource respondsToSelector:@selector(outlineView:isItemExpandable:)])
        [CPException raise:CPInternalInconsistencyException reason:"Data source must implement 'outlineView:isItemExpandable:'"];

    if (![aDataSource respondsToSelector:@selector(outlineView:numberOfChildrenOfItem:)])
        [CPException raise:CPInternalInconsistencyException reason:"Data source must implement 'outlineView:numberOfChildrenOfItem:'"];

    _outlineViewDataSource = aDataSource;
    _implementedOutlineViewDataSourceMethods = 0;

    if ([_outlineViewDataSource respondsToSelector:@selector(outlineView:objectValueForTableColumn:byItem:)])
        _implementedOutlineViewDataSourceMethods |= CPOutlineViewDataSource_outlineView_objectValue_forTableColumn_byItem_;

    if ([_outlineViewDataSource respondsToSelector:@selector(outlineView:setObjectValue:forTableColumn:byItem:)])
        _implementedOutlineViewDataSourceMethods |= CPOutlineViewDataSource_outlineView_setObjectValue_forTableColumn_byItem_;

    if ([_outlineViewDataSource respondsToSelector:@selector(outlineView:shouldDeferDisplayingChildrenOfItem:)])
        _implementedOutlineViewDataSourceMethods |= CPOutlineViewDataSource_outlineView_shouldDeferDisplayingChildrenOfItem_;

    if ([_outlineViewDataSource respondsToSelector:@selector(outlineView:acceptDrop:item:childIndex:)])
        _implementedOutlineViewDataSourceMethods |= CPOutlineViewDataSource_outlineView_acceptDrop_item_childIndex_;

    if ([_outlineViewDataSource respondsToSelector:@selector(outlineView:validateDrop:proposedItem:proposedChildIndex:)])
        _implementedOutlineViewDataSourceMethods |= CPOutlineViewDataSource_outlineView_validateDrop_proposedItem_proposedChildIndex_;

    if ([_outlineViewDataSource respondsToSelector:@selector(outlineView:validateDrop:proposedRow:proposedDropOperation:)])
        _implementedOutlineViewDataSourceMethods |= CPOutlineViewDataSource_outlineView_validateDrop_proposedRow_proposedDropOperation_;

    if ([_outlineViewDataSource respondsToSelector:@selector(outlineView:namesOfPromisedFilesDroppedAtDestination:forDraggedItems:)])
        _implementedOutlineViewDataSourceMethods |= CPOutlineViewDataSource_outlineView_namesOfPromisedFilesDroppedAtDestination_forDraggedItems_;

    if ([_outlineViewDataSource respondsToSelector:@selector(outlineView:itemForPersistentObject:)])
        _implementedOutlineViewDataSourceMethods |= CPOutlineViewDataSource_outlineView_itemForPersistentObject_;

    if ([_outlineViewDataSource respondsToSelector:@selector(outlineView:persistentObjectForItem:)])
        _implementedOutlineViewDataSourceMethods |= CPOutlineViewDataSource_outlineView_persistentObjectForItem_;

    if ([_outlineViewDataSource respondsToSelector:@selector(outlineView:writeItems:toPasteboard:)])
        _implementedOutlineViewDataSourceMethods |= CPOutlineViewDataSource_outlineView_writeItems_toPasteboard_;

    if ([_outlineViewDataSource respondsToSelector:@selector(outlineView:sortDescriptorsDidChange:)])
        _implementedOutlineViewDataSourceMethods |= CPOutlineViewDataSource_outlineView_sortDescriptorsDidChange_;

    [self reloadData];
}

/*!
    Returns the datasource object.

    @return id - The data source object
*/
- (id)dataSource
{
    return _outlineViewDataSource;
}

/*!
    Used to query whether an item is expandable or not.

    @param anItem - the item you are interested in.

    @return BOOL - YES if the item is expandable, otherwise NO.
*/
- (BOOL)isExpandable:(id)anItem
{
    if (!anItem)
        return YES;

    var itemInfo = _itemInfosForItems[[anItem UID]];

    if (!itemInfo)
        return NO;

    return itemInfo.isExpandable;
}

- (BOOL)_shouldShowOutlineDisclosureControlForItem:(id)anItem
{
    if (!anItem)
        return YES;

    var itemInfo = _itemInfosForItems[[anItem UID]];

    if (!itemInfo)
        return YES;

    return itemInfo.shouldShowOutlineDisclosureControl;
}

/*!
    Used to find if an item is already expanded.

    @param anItem - the item you are interest in.

    @return BOOL - Yes if the item is already expanded, otherwise NO.
*/
- (BOOL)isItemExpanded:(id)anItem
{
    if (!anItem)
        return YES;

    var itemInfo = _itemInfosForItems[[anItem UID]];

    if (!itemInfo)
        return NO;

    return itemInfo.isExpanded;
}

/*!
    Expands a given item.

    @param anItem - the item to expand.
*/
- (void)expandItem:(id)anItem
{
    [self expandItem:anItem expandChildren:NO];
}

/*!
    Expands a given item, and optionally all the children of that item.

    @param anItem - the item you want to expand.
    @param shouldExpandChildren - Pass YES if you want to expand all the children of anItem, otherwise NO.
*/
- (void)expandItem:(id)anItem expandChildren:(BOOL)shouldExpandChildren
{
    var itemInfo = null;

    if (!anItem)
        itemInfo = _rootItemInfo;
    else
        itemInfo = _itemInfosForItems[[anItem UID]];

    if (!itemInfo)
        return;

    // When shouldExpandChildren is YES, we need to make sure we're collecting
    // selection notifications so that exactly one IsChanging and one
    // DidChange is sent as needed, for the totality of the operation.
    var isTopLevel = NO;
    if (!_coalesceSelectionNotificationState)
    {
        isTopLevel = YES;
        _coalesceSelectionNotificationState = CPOutlineViewCoalesceSelectionNotificationStateOn;
    }

    // To prevent items which are already expanded from firing notifications.
    if (!itemInfo.isExpanded)
    {
        [self _noteItemWillExpand:anItem];

        var previousRowCount = [self numberOfRows];

        itemInfo.isExpanded = YES;
        [self reloadItem:anItem reloadChildren:YES];
        [self _noteItemDidExpand:anItem];

        // Shift selection indexes below so that the same items remain selected.
        var rowCountDelta = [self numberOfRows] - previousRowCount;
        if (rowCountDelta)
        {
            var selection = [self selectedRowIndexes],
                expandIndex = [self rowForItem:anItem] + 1;

            if ([selection intersectsIndexesInRange:CPMakeRange(expandIndex, _itemsForRows.length)])
            {
                [self _noteSelectionIsChanging];
                [selection shiftIndexesStartingAtIndex:expandIndex by:rowCountDelta];
                [self _setSelectedRowIndexes:selection]; // _noteSelectionDidChange will be suppressed.
            }
        }
    }

    if (shouldExpandChildren)
    {
        var children = itemInfo.children,
            childIndex = children.length;

        while (childIndex--)
            [self expandItem:children[childIndex] expandChildren:YES];
    }

    if (isTopLevel)
    {
        var r = _coalesceSelectionNotificationState;
        _coalesceSelectionNotificationState = CPOutlineViewCoalesceSelectionNotificationStateOff;
        if (r === CPOutlineViewCoalesceSelectionNotificationStateDid)
            [self _noteSelectionDidChange];
    }
}

/*!
    Collapse a given item.

    @param anItem - The item you want to collapse.
*/
- (void)collapseItem:(id)anItem
{
    if (!anItem)
        return;

    var itemInfo = _itemInfosForItems[[anItem UID]];

    if (!itemInfo)
        return;

    if (!itemInfo.isExpanded)
        return;

    // Don't spam notifications.
    _coalesceSelectionNotificationState = CPOutlineViewCoalesceSelectionNotificationStateOn;

    [self _noteItemWillCollapse:anItem];
    // Update selections:
    // * Deselect items inside the collapsed item.
    // * Shift row selections below the collapsed item so that the same logical items remain selected.
    var collapseTopIndex = [self rowForItem:anItem],
        topLevel = [self levelForRow:collapseTopIndex],
        collapseEndIndex = collapseTopIndex;

    while (collapseEndIndex + 1 < _itemsForRows.length && [self levelForRow:collapseEndIndex + 1] > topLevel)
        collapseEndIndex++;

    var collapseRange = CPMakeRange(collapseTopIndex + 1, collapseEndIndex - collapseTopIndex);

    if (collapseRange.length)
    {
        var selection = [self selectedRowIndexes];

        if ([selection intersectsIndexesInRange:collapseRange])
        {
            [self _noteSelectionIsChanging];
            [selection removeIndexesInRange:collapseRange];
            [self _setSelectedRowIndexes:selection]; // _noteSelectionDidChange will be suppressed.
        }

        // Shift any selected rows below upwards.
        if ([selection intersectsIndexesInRange:CPMakeRange(collapseEndIndex + 1, _itemsForRows.length)])
        {
            [self _noteSelectionIsChanging];
            [selection shiftIndexesStartingAtIndex:collapseEndIndex + 1 by:-collapseRange.length];
            [self _setSelectedRowIndexes:selection]; // _noteSelectionDidChange will be suppressed.
        }
    }
    itemInfo.isExpanded = NO;

    [self reloadItem:anItem reloadChildren:YES];
    [self _noteItemDidCollapse:anItem];

    // Send selection notifications only after the items have loaded so that
    // the new selection is consistent with the actual rows for any observers.
    var r = _coalesceSelectionNotificationState;
    _coalesceSelectionNotificationState = CPOutlineViewCoalesceSelectionNotificationStateOff;
    if (r === CPOutlineViewCoalesceSelectionNotificationStateDid)
        [self _noteSelectionDidChange];
}

/*!
    Reloads the data for an item.

    @param anItem - The item you want to reload.
*/
- (void)reloadItem:(id)anItem
{
    [self reloadItem:anItem reloadChildren:NO];
}

/*!
    Reloads the data for a given item and optionally the children.

    @param anItem - The item you want to reload.
    @param shouldReloadChildren - Pass YES if you want to reload all the children, otherwise NO.
*/
- (void)reloadItem:(id)anItem reloadChildren:(BOOL)shouldReloadChildren
{
    if (!!shouldReloadChildren || !anItem)
        _loadItemInfoForItem(self, anItem);
    else
        _reloadItem(self, anItem);

    [super reloadData];
}

/*!
    Returns the item at a given row index. If no item exists nil is returned.

    @param aRow - The row index you want to find the item at.
    @return id - The item at a given index.
*/
- (id)itemAtRow:(CPInteger)aRow
{
    return _itemsForRows[aRow] || nil;
}

/*!
    Returns the row of a given item

    @param anItem - The item you want to find the row of.
    @return int - The row index of a given item.
*/
- (CPInteger)rowForItem:(id)anItem
{
    if (!anItem)
        return _rootItemInfo.row;

    var itemInfo = _itemInfosForItems[[anItem UID]];

    if (!itemInfo)
        return CPNotFound;

    return itemInfo.row;
}

/*!
    Sets the table column you want to display the disclosure button in. If you
    do not want an outline column pass nil.

    @param aTableColumn - The CPTableColumn you want to use for hierarchical data.
*/
- (void)setOutlineTableColumn:(CPTableColumn)aTableColumn
{
    if (_outlineTableColumn === aTableColumn)
        return;

    _outlineTableColumn = aTableColumn;

    // FIXME: efficiency.
    [self reloadData];
}

/*!
    Returns the table column used to display hierarchical data.

    @return CPTableColumn - The table column that displays the disclosure button.
*/
- (CPTableColumn)outlineTableColumn
{
    return _outlineTableColumn;
}

/*!
    Returns the indentation level of a given item. If the item is nil (the top
    level root item) CPNotFound is returned. Indentation levels are zero
    based, thus items that are not indented return 0.

    @param anItem - The item you want the indentation level for.
    @return int - the indentation level of anItem.
*/
- (CPInteger)levelForItem:(id)anItem
{
    if (!anItem)
        return _rootItemInfo.level;

    var itemInfo = _itemInfosForItems[[anItem UID]];

    if (!itemInfo)
        return CPNotFound;

    return itemInfo.level;
}

/*!
    Returns the indentation level for a given row. If the row is invalid
    CPNotFound is returned. Rows that are not indented return 0.

    @param aRow - the row of the receiver
    @return int - the indentation level of aRow.
*/
- (CPInteger)levelForRow:(CPInteger)aRow
{
    return [self levelForItem:[self itemAtRow:aRow]];
}

/*!
    Sets the number of pixels to indent an item at each indentation level.

    @param anIndentationWidth - the width of each indentation level.
*/
- (void)setIndentationPerLevel:(float)anIndentationWidth
{
    if (_indentationPerLevel === anIndentationWidth)
        return;

    _indentationPerLevel = anIndentationWidth;

    // FIXME: efficiency!!!!
    [self reloadData];
}

/*!
    Returns the width of an indentation level.

    @return float - the width of the indentation per level.
*/
- (float)indentationPerLevel
{
    return _indentationPerLevel;
}

/*!
    Sets the layout behavior of disclosure button. If you pass NO the
    disclosure button will always align itself to the left of the outline
    column.

    @param indentationMarkerShouldFollowDataView - Pass YES if the disclosure control should be indented along with the dataview, otherwise NO.
*/
- (void)setIndentationMarkerFollowsDataView:(BOOL)indentationMarkerShouldFollowDataView
{
    if (_indentationMarkerFollowsDataView === indentationMarkerShouldFollowDataView)
        return;

    _indentationMarkerFollowsDataView = indentationMarkerShouldFollowDataView;

    // !!!!
    [self reloadData];
}

/*!
    Returns the layout behavior of the disclosure buttons.

    @return BOOL - YES if the disclosure control indents itself with the
        dataview, otherwise NO if the control is always aligned to the left of
        the outline column
*/
- (BOOL)indentationMarkerFollowsDataView
{
    return _indentationMarkerFollowsDataView;
}

/*!
    Returns the parent item for a given item. If the item is a top level root object nil is returned.

    @param anItem - The item of the receiver.
    @return id - The parent item of anItem. If no parent exists (the item is a
        root item) nil is returned.
*/
- (id)parentForItem:(id)anItem
{
    if (!anItem)
        return nil;

    var itemInfo = _itemInfosForItems[[anItem UID]];

    if (!itemInfo)
        return nil;

    var parent = itemInfo.parent;

    // Check if the parent is the root item because we never return the actual root item
    if (itemInfo[[parent UID]] === _rootItemInfo)
        parent = nil;

    return parent;
}

/*!
    @ignore

    Returns the frame of the dataview at the row given for the outline column.
*/
- (CGRect)_frameOfOutlineDataViewAtRow:(CPInteger)aRow
{
    var columnIndex = [[self tableColumns] indexOfObject:_outlineTableColumn],
        frame = [super frameOfDataViewAtColumn:columnIndex row:aRow],
        indentationWidth = ([self levelForRow:aRow] + 1) * [self indentationPerLevel];

    frame.origin.x += indentationWidth;
    frame.size.width -= indentationWidth;

    return frame;
}

/*!
    Returns the frame of the disclosure button for the outline column. If the
    item is not expandable a CGZeroRect is returned. Subclasses can return a
    CGZeroRect to prevent the disclosure control from being displayed.

    @param aRow - The row of the receiver
    @return CGRect - The rect of the disclosure button at aRow.
*/
- (CGRect)frameOfOutlineDisclosureControlAtRow:(CPInteger)aRow
{
    var theItem = [self itemAtRow:aRow];
    if (![self isExpandable:theItem] || ![self _shouldShowOutlineDisclosureControlForItem:theItem])
        return CGRectMakeZero();

    var dataViewFrame = [self _frameOfOutlineDataViewAtRow:aRow],
        disclosureWidth = CGRectGetWidth([_disclosureControlPrototype frame]),
        frame = CGRectMake(CGRectGetMinX(dataViewFrame) - disclosureWidth, CGRectGetMinY(dataViewFrame), disclosureWidth, CGRectGetHeight(dataViewFrame));

    return frame;
}

/*!
    @ignore
    Select or deselect rows, this is overridden because we need to change the color of the outline control.
*/
- (void)_setSelectedRowIndexes:(CPIndexSet)rows
{
    if (_disclosureControlsForRows.length)
    {
        var indexes = [_selectedRowIndexes copy];
        [indexes removeIndexesInRange:CPMakeRange(_disclosureControlsForRows.length, _itemsForRows.length - _disclosureControlsForRows.length)];
        [[_disclosureControlsForRows objectsAtIndexes:indexes] makeObjectsPerformSelector:@selector(unsetThemeState:) withObject:CPThemeStateSelected];
    }

    [super _setSelectedRowIndexes:rows];

    if (_disclosureControlsForRows.length)
    {
        var indexes = [_selectedRowIndexes copy];
        [indexes removeIndexesInRange:CPMakeRange(_disclosureControlsForRows.length, _itemsForRows.length - _disclosureControlsForRows.length)];
        [[_disclosureControlsForRows objectsAtIndexes:indexes] makeObjectsPerformSelector:@selector(setThemeState:) withObject:CPThemeStateSelected];
    }
}

/*!

    Sets the delegate for the outlineview.

    The following methods can be implemented:
    @param aDelegate - the delegate object you wish to set for the receiver.

    @section notifications User Interaction Notifications:

    Called when the user moves a column in the outlineview.
    @code - (void)outlineViewColumnDidMove:(CPNotification)notification; @endcode

    Called when the user resizes a column in the outlineview.
    @code - (void)outlineViewColumnDidResize:(CPNotification)notification; @endcode

    Called when the user collapses an item in the outlineview.
    @code - (void)outlineViewItemDidCollapse:(CPNotification)notification; @endcode

    Called when the user expands an item in the outlineview.
    @code - (void)outlineViewItemDidExpand:(CPNotification)notification; @endcode

    Called when the user collapses an item in the outlineview, but before the item is actually collapsed.
    @code - (void)outlineViewItemWillCollapse:(CPNotification)notification; @endcode

    Called when the used expands an item, but before the item is actually expanded.
    @code - (void)outlineViewItemWillExpand:(CPNotification)notification; @endcode

    Called when the user changes the selection of the outlineview.
    @code - (void)outlineViewSelectionDidChange:(CPNotification)notification; @endcode

    Called when the user changes the selection of the outlineview, but before the change is made.
    @code - (void)outlineViewSelectionIsChanging:(CPNotification)notification; @endcode

    @section expandingandcollapsing Expanding and collapsing items:

    Return YES if the item should be given permission to expand, otherwise NO.
    @code - (BOOL)outlineView:(CPOutlineView)outlineView shouldExpandItem:(id)item; @endcode

    Return YES if the item should be given permission to collapse, otherwise NO.
    @code - (BOOL)outlineView:(CPOutlineView)outlineView shouldCollapseItem:(id)item; @endcode

    @section selection Selection:
    Return YES to allow the selection of tableColumn, otherwise NO.
    @code- (BOOL)outlineView:(CPOutlineView)outlineView shouldSelectTableColumn:(CPTableColumn)tableColumn; @endcode

    Return YES to allow the selection of an item, otherwise NO.
    @code- (BOOL)outlineView:(CPOutlineView)outlineView shouldSelectItem:(id)item; @endcode

    Return YES to allow the selection of the outlineview to be changed, otherwise NO.
    @code - (BOOL)selectionShouldChangeInOutlineView:(CPOutlineView)outlineView; @endcode

    @section dataviews Displaying DataViews:

    Called when a dataView is about to be displayed. This gives you the ability to alter the dataView if needed.
    @code - (void)outlineView:(CPOutlineView)outlineView willDisplayView:(id)dataView forTableColumn:(CPTableColumn)tableColumn item:(id)item; @endcode

    @section editin Editing:

    Return YES to allow for editing of a dataview at given item and tableColumn, otherwise NO to prevent the edit.
    @code - (BOOL)outlineView:(CPOutlineView)outlineView shouldEditTableColumn:(CPTableColumn)tableColumn item:(id)item; @endcode

    @section groups Group Items:

    Implement this to indicate whether a given item should be rendered using the group item style.
    Return YES if the item is a group item, otherwise NO.
    @code - (BOOL)outlineView:(CPOutlineView)outlineView isGroupItem:(id)item; @endcode


    @section variableitems Variable Item Heights

    Implement this method to get custom heights of rows based on the item.
    This delegate method will be passed your 'item' object and expects you to return an integer height.
    @note This should only be implemented if rows will be different heights, if you want to set a height for ALL of your rows see -setRowHeight:@endnote
    @code - (int)outlineView:(CPOutlineView)outlineView heightOfRowByItem:(id)anItem; @endcode

*/
- (void)setDelegate:(id)aDelegate
{
    if (_outlineViewDelegate === aDelegate)
        return;

    var defaultCenter = [CPNotificationCenter defaultCenter];

    if (_outlineViewDelegate)
    {
        if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewColumnDidMove:)])
            [defaultCenter
                removeObserver:_outlineViewDelegate
                          name:CPOutlineViewColumnDidMoveNotification
                        object:self];

        if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewColumnDidResize:)])
            [defaultCenter
                removeObserver:_outlineViewDelegate
                          name:CPOutlineViewColumnDidResizeNotification
                        object:self];

        if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewSelectionDidChange:)])
            [defaultCenter
                removeObserver:_outlineViewDelegate
                          name:CPOutlineViewSelectionDidChangeNotification
                        object:self];

        if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewSelectionIsChanging:)])
            [defaultCenter
                removeObserver:_outlineViewDelegate
                          name:CPOutlineViewSelectionIsChangingNotification
                        object:self];

        if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewItemWillExpand:)])
            [defaultCenter
                removeObserver:_outlineViewDelegate
                          name:CPOutlineViewItemWillExpandNotification
                        object:self];

        if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewItemDidExpand:)])
            [defaultCenter
                removeObserver:_outlineViewDelegate
                          name:CPOutlineViewItemDidExpandNotification
                        object:self];

        if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewItemWillCollapse:)])
            [defaultCenter
                removeObserver:_outlineViewDelegate
                          name:CPOutlineViewItemWillCollapseNotification
                        object:self];

        if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewItemDidCollapse:)])
            [defaultCenter
                removeObserver:_outlineViewDelegate
                          name:CPOutlineViewItemDidCollapseNotification
                        object:self];
    }

    _outlineViewDelegate = aDelegate;
    _implementedOutlineViewDelegateMethods = 0;

    var delegateMethods = [
            CPOutlineViewDelegate_outlineView_dataViewForTableColumn_item_                       , @selector(outlineView:dataViewForTableColumn:item:),
            CPOutlineViewDelegate_outlineView_viewForTableColumn_item_                           , @selector(outlineView:viewForTableColumn:item:),
            CPOutlineViewDelegate_outlineView_didClickTableColumn_                               , @selector(outlineView:didClickTableColumn:),
            CPOutlineViewDelegate_outlineView_didDragTableColumn_                                , @selector(outlineView:didDragTableColumn:),
            CPOutlineViewDelegate_outlineView_heightOfRowByItem_                                 , @selector(outlineView:heightOfRowByItem:),
            CPOutlineViewDelegate_outlineView_isGroupItem_                                       , @selector(outlineView:isGroupItem:),
            CPOutlineViewDelegate_outlineView_mouseDownInHeaderOfTableColumn_                    , @selector(outlineView:mouseDownInHeaderOfTableColumn:),
            CPOutlineViewDelegate_outlineView_nextTypeSelectMatchFromItem_toItem_forString_      , @selector(outlineView:nextTypeSelectMatchFromItem:toItem:forString:),
            CPOutlineViewDelegate_outlineView_selectionIndexesForProposedSelection_              , @selector(outlineView:selectionIndexesForProposedSelection:),
            CPOutlineViewDelegate_outlineView_shouldCollapseItem_                                , @selector(outlineView:shouldCollapseItem:),
            CPOutlineViewDelegate_outlineView_shouldEditTableColumn_item_                        , @selector(outlineView:shouldEditTableColumn:item:),
            CPOutlineViewDelegate_outlineView_shouldExpandItem_                                  , @selector(outlineView:shouldExpandItem:),
            CPOutlineViewDelegate_outlineView_shouldReorderColumn_toColumn_                      , @selector(outlineView:shouldReorderColumn:toColumn:),
            CPOutlineViewDelegate_outlineView_shouldSelectItem_                                  , @selector(outlineView:shouldSelectItem:),
            CPOutlineViewDelegate_outlineView_shouldSelectTableColumn_                           , @selector(outlineView:shouldSelectTableColumn:),
            CPOutlineViewDelegate_outlineView_shouldShowOutlineDisclosureControlForItem_         , @selector(outlineView:shouldShowOutlineDisclosureControlForItem:),
            CPOutlineViewDelegate_outlineView_shouldShowViewExpansionForTableColumn_item_        , @selector(outlineView:shouldShowViewExpansionForTableColumn:item:),
            CPOutlineViewDelegate_outlineView_shouldTrackView_forTableColumn_item_               , @selector(outlineView:shouldTrackView:forTableColumn:item:),
            CPOutlineViewDelegate_outlineView_shouldTypeSelectForEvent_withCurrentSearchString_  , @selector(outlineView:shouldTypeSelectForEvent:withCurrentSearchString:),
            CPOutlineViewDelegate_outlineView_sizeToFitWidthOfColumn_                            , @selector(outlineView:sizeToFitWidthOfColumn:),
            CPOutlineViewDelegate_outlineView_toolTipForView_rect_tableColumn_item_mouseLocation_, @selector(outlineView:toolTipForView:rect:tableColumn:item:mouseLocation:),
            CPOutlineViewDelegate_outlineView_typeSelectStringForTableColumn_item_               , @selector(outlineView:typeSelectStringForTableColumn:item:),
            CPOutlineViewDelegate_outlineView_willDisplayOutlineView_forTableColumn_item_        , @selector(outlineView:willDisplayOutlineView:forTableColumn:item:),
            CPOutlineViewDelegate_outlineView_willDisplayView_forTableColumn_item_               , @selector(outlineView:willDisplayView:forTableColumn:item:),
            CPOutlineViewDelegate_selectionShouldChangeInOutlineView_                            , @selector(selectionShouldChangeInOutlineView:),
            CPOutlineViewDelegate_outlineView_menuForTableColumn_item_                           , @selector(outlineView:menuForTableColumn:item:)
        ],
        delegateCount = [delegateMethods count];

    for (var i = 0; i < delegateCount; i += 2)
    {
        var bitMask = delegateMethods[i],
            selector = delegateMethods[i + 1];

        if ([_outlineViewDelegate respondsToSelector:selector])
            _implementedOutlineViewDelegateMethods |= bitMask;
    }

    if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewColumnDidMove:)])
        [defaultCenter
            addObserver:_outlineViewDelegate
            selector:@selector(outlineViewColumnDidMove:)
            name:CPOutlineViewColumnDidMoveNotification
            object:self];

    if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewColumnDidResize:)])
        [defaultCenter
            addObserver:_outlineViewDelegate
            selector:@selector(outlineViewColumnDidMove:)
            name:CPOutlineViewColumnDidResizeNotification
            object:self];

    if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewSelectionDidChange:)])
        [defaultCenter
            addObserver:_outlineViewDelegate
            selector:@selector(outlineViewSelectionDidChange:)
            name:CPOutlineViewSelectionDidChangeNotification
            object:self];

    if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewSelectionIsChanging:)])
        [defaultCenter
            addObserver:_outlineViewDelegate
            selector:@selector(outlineViewSelectionIsChanging:)
            name:CPOutlineViewSelectionIsChangingNotification
            object:self];

    if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewItemWillExpand:)])
        [defaultCenter
            addObserver:_outlineViewDelegate
            selector:@selector(outlineViewItemWillExpand:)
            name:CPOutlineViewItemWillExpandNotification
            object:self];

    if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewItemDidExpand:)])
        [defaultCenter
            addObserver:_outlineViewDelegate
            selector:@selector(outlineViewItemDidExpand:)
            name:CPOutlineViewItemDidExpandNotification
            object:self];

    if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewItemWillCollapse:)])
        [defaultCenter
            addObserver:_outlineViewDelegate
            selector:@selector(outlineViewItemWillCollapse:)
            name:CPOutlineViewItemWillCollapseNotification
            object:self];

    if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewItemDidCollapse:)])
        [defaultCenter
            addObserver:_outlineViewDelegate
            selector:@selector(outlineViewItemDidCollapse:)
            name:CPOutlineViewItemDidCollapseNotification
            object:self];

    [self _updateIsViewBased];

    if ([self _delegateRespondsToDataViewForTableColumn])
        CPLog.warn("outlineView:dataViewForTableColumn:item: is deprecated. You should use -outlineView:viewForTableColumn:item: where you can request the view with -makeViewWithIdentifier:owner:");
}

- (BOOL)_sendDelegateDeleteKeyPressed
{
    if ([[self delegate] respondsToSelector: @selector(outlineViewDeleteKeyPressed:)])
    {
        [[self delegate] outlineViewDeleteKeyPressed:self];
        return YES;
    }

    return NO;
}

/*!
    Returns the delegate object for the outlineview.
*/
- (id)delegate
{
    return _outlineViewDelegate;
}

/*!
    Sets the prototype of the disclosure control. This is used if you want to
    set a special type of button, instead of the default triangle. The control
    must implement CPCoding.

    @param aControl - the control to be used to expand and collapse items.
*/
- (void)setDisclosureControlPrototype:(CPControl)aControl
{
    _disclosureControlPrototype = aControl;
    _disclosureControlData = nil;
    _disclosureControlQueue = [];

    // FIXME: really?
    [self reloadData];
}

/*!
    Reloads all the data of the outlineview.
*/
- (void)reloadData
{
    [self reloadItem:nil reloadChildren:YES];
}

/*!
    Adds a new table column to the receiver. If this is the first column added
    it will automatically be set to the outline column.

    Also see -setOutlineTableColumn:.

    @note This behavior deviates from cocoa slightly.

    @param CPTableColumn aTableColumn - The table column to add.
*/
- (void)addTableColumn:(CPTableColumn)aTableColumn
{
    [super addTableColumn:aTableColumn];

    if ([self numberOfColumns] === 1)
        _outlineTableColumn = aTableColumn;
}
/*!
    @ignore
*/
- (void)removeTableColumn:(CPTableColumn)aTableColumn
{
    if (aTableColumn === [self outlineTableColumn])
        CPLog("CPOutlineView cannot remove outlineTableColumn with removeTableColumn:. User setOutlineTableColumn: instead.");
    else
        [super removeTableColumn:aTableColumn];
}
/*!
    @ignore
    We override this because we need a special behavior for the outline
    column.
*/
- (CGRect)frameOfDataViewAtColumn:(CPInteger)aColumn row:(CPInteger)aRow
{
    var tableColumn = [self tableColumns][aColumn];

    if (tableColumn === _outlineTableColumn)
        return [self _frameOfOutlineDataViewAtRow:aRow];

    return [super frameOfDataViewAtColumn:aColumn row:aRow];
}

/*!
    @ignore
    We need to offset the dataview and add the disclosure triangle.
*/
- (CPView)_dragViewForColumn:(int)theColumnIndex event:(CPEvent)theDragEvent offset:(CGPoint)theDragViewOffset
{
    var dragView = [[_CPColumnDragView alloc] initWithLineColor:[self gridColor]],
        tableColumn = [[self tableColumns] objectAtIndex:theColumnIndex],
        defaultRowHeight = [self valueForThemeAttribute:@"default-row-height"],
        bounds = CGRectMake(0.0, 0.0, [tableColumn width], CGRectGetHeight([self exposedRect]) + defaultRowHeight),
        columnRect = [self rectOfColumn:theColumnIndex],
        headerView = [tableColumn headerView],
        row = [_exposedRows firstIndex];

    while (row !== CPNotFound)
    {
        var dataView = [self _newDataViewForRow:row tableColumn:tableColumn],
            dataViewFrame = [self frameOfDataViewAtColumn:theColumnIndex row:row];

        // Only one column is ever dragged so we just place the view at
        dataViewFrame.origin.x = 0.0;

        // Offset by table header height - scroll position
        dataViewFrame.origin.y = (CGRectGetMinY(dataViewFrame) - CGRectGetMinY([self exposedRect])) + defaultRowHeight;
        [dataView setFrame:dataViewFrame];

        [dataView setObjectValue:[self _objectValueForTableColumn:tableColumn row:row]];


        if (tableColumn === _outlineTableColumn)
        {
            // first inset the dragview
            var indentationWidth = ([self levelForRow:row] + 1) * [self indentationPerLevel];

            dataViewFrame.origin.x += indentationWidth;
            dataViewFrame.size.width -= indentationWidth;

            [dataView setFrame:dataViewFrame];
        }

        [dragView addSubview:dataView];

        row = [_exposedRows indexGreaterThanIndex:row];
    }

    // Add the column header view
    var headerFrame = [headerView frame];
    headerFrame.origin = CGPointMakeZero();

    var columnHeaderView = [[_CPTableColumnHeaderView alloc] initWithFrame:headerFrame];
    [columnHeaderView setStringValue:[headerView stringValue]];
    [columnHeaderView setThemeState:[headerView themeState]];
    [dragView addSubview:columnHeaderView];

    [dragView setBackgroundColor:[CPColor whiteColor]];
    [dragView setAlphaValue:0.7];
    [dragView setFrame:bounds];

    return dragView;
}

/*!
    Retargets the drop item for the outlineview.

    To specify a drop on theItem, you specify item as theItem and index as
    CPOutlineViewDropOnItemIndex.

    To specify a drop between child 1 and 2 of theItem, you specify item as
    theItem and index as 2.

    To specify a drop on an item that can't be expanded theItem, you specify
    item as someOutlineItem and index as CPOutlineViewDropOnItemIndex.

    @param theItem - The item you want to retarget the drop on.
    @param theIndex - The index of the child item you want to retarget the drop between. Pass CPOutlineViewDropOnItemIndex if you want to drop on theItem.
*/
- (void)setDropItem:(id)theItem dropChildIndex:(int)theIndex
{
    if (_dropItem !== theItem && theIndex < 0 && [self isExpandable:theItem] && ![self isItemExpanded:theItem])
    {
        if (_dragHoverTimer)
            [_dragHoverTimer invalidate];

        var autoExpandCallBack = function()
        {
            if (_dropItem)
            {
                [_dropOperationFeedbackView blink];
                [CPTimer scheduledTimerWithTimeInterval:.3 callback:objj_msgSend(self, "expandItem:", _dropItem) repeats:NO];
            }
        };

        _dragHoverTimer = [CPTimer scheduledTimerWithTimeInterval:.8 callback:autoExpandCallBack repeats:NO];
    }

    if (theIndex >= 0)
    {
        [_dragHoverTimer invalidate];
        _dragHoverTimer = nil;
    }

    _dropItem = theItem;
    _retargetedItem = theItem;
    _shouldRetargetItem = YES;

    _retargedChildIndex = theIndex;
    _shouldRetargetChildIndex = YES;

    // set CPTableView's _retargetedDropRow based on retargetedItem and retargetedChildIndex
    var retargetedItemInfo = (_retargetedItem !== nil) ? _itemInfosForItems[[_retargetedItem UID]] : _rootItemInfo;

    if (_retargedChildIndex === [retargetedItemInfo.children count])
    {
        var retargetedChildItem = [retargetedItemInfo.children lastObject];
        _retargetedDropRow = [self rowForItem:retargetedChildItem] + 1;
    }
    else
    {
        var retargetedChildItem = (_retargedChildIndex !== CPOutlineViewDropOnItemIndex) ? retargetedItemInfo.children[_retargedChildIndex] : _retargetedItem;
        _retargetedDropRow = [self rowForItem:retargetedChildItem];
    }
}

/*!
    @ignore
*/
- (void)_draggingEnded
{
    [super _draggingEnded];
    _dropItem = nil;
    [_dragHoverTimer invalidate];
    _dragHoverTimer = nil;
}

/*!
    @ignore
*/
- (id)_parentItemForUpperRow:(int)theUpperRowIndex andLowerRow:(int)theLowerRowIndex atMouseOffset:(CGPoint)theOffset
{
    if (_shouldRetargetItem)
        return _retargetedItem;

    var lowerLevel = [self levelForRow:theLowerRowIndex],
        upperItem = [self itemAtRow:theUpperRowIndex],
        upperLevel = [self levelForItem:upperItem];

    // If the row above us has a higher level the item can be added to multiple parent items
    // Determine which one by looping through all possible parents and return the first
    // of which the indentation level is larger than the current x offset
    while (upperLevel > lowerLevel)
    {
        upperLevel = [self levelForItem:upperItem];

        // See if this item's indentation level matches the mouse offset
        if (theOffset.x > (upperLevel + 1) * [self indentationPerLevel])
            return [self parentForItem:upperItem];

        // Check the next parent
        upperItem = [self parentForItem:upperItem];
    }

    return [self parentForItem:[self itemAtRow:theLowerRowIndex]];
}

/*!
    @ignore
*/
- (CGRect)_rectForDropHighlightViewBetweenUpperRow:(int)theUpperRowIndex andLowerRow:(int)theLowerRowIndex offset:(CGPoint)theOffset
{
    // Call super and the update x to reflect the current indentation level
    var rect = [super _rectForDropHighlightViewBetweenUpperRow:theUpperRowIndex andLowerRow:theLowerRowIndex offset:theOffset],
        parentItem = [self _parentItemForUpperRow:theUpperRowIndex andLowerRow:theLowerRowIndex atMouseOffset:theOffset],
        level = [self levelForItem:parentItem];

    rect.origin.x = (level + 1) * [self indentationPerLevel];
    rect.size.width -= rect.origin.x; // This assumes that the x returned by super is zero

    return rect;
}

/*!
    @ignore
    We need to move the disclosure control too.
*/
- (void)_layoutDataViewsInRows:(CPIndexSet)rows columns:(CPIndexSet)columns
{
    var rowArray = [],
        columnArray = [];

    [rows getIndexes:rowArray maxCount:-1 inIndexRange:nil];
    [columns getIndexes:columnArray maxCount:-1 inIndexRange:nil];

    var columnIndex = 0,
        columnsCount = columnArray.length;

    for (; columnIndex < columnsCount; ++columnIndex)
    {
        var column = columnArray[columnIndex],
            tableColumn = _tableColumns[column],
            tableColumnUID = [tableColumn UID],
            dataViewsForTableColumn = _dataViewsForTableColumns[tableColumnUID],
            rowIndex = 0,
            rowsCount = rowArray.length;

        for (; rowIndex < rowsCount; ++rowIndex)
        {
            var row = rowArray[rowIndex],
                dataView = dataViewsForTableColumn[row],
                dataViewFrame = [self frameOfDataViewAtColumn:column row:row];

            [dataView setFrame:dataViewFrame];

            if (tableColumn === _outlineTableColumn)
            {
                var control = _disclosureControlsForRows[row],
                    frame = [self frameOfOutlineDisclosureControlAtRow:row];

                [control setFrame:frame];
            }
        }
    }
}

/*!
    @ignore
*/
- (void)_loadDataViewsInRows:(CPIndexSet)rows columns:(CPIndexSet)columns
{
    [super _loadDataViewsInRows:rows columns:columns];

    var outlineColumn = [[self tableColumns] indexOfObjectIdenticalTo:[self outlineTableColumn]];

    if (![columns containsIndex:outlineColumn] ||  [self outlineTableColumn] === _draggedColumn)
        return;

    var rowArray = [];

    [rows getIndexes:rowArray maxCount:-1 inIndexRange:nil];

    var rowIndex = 0,
        rowsCount = rowArray.length;

    for (; rowIndex < rowsCount; ++rowIndex)
    {
        var row = rowArray[rowIndex],
            item = _itemsForRows[row],
            isExpandable = [self isExpandable:item];

        if (!isExpandable)
            continue;

        var disclosureControlFrame = [self frameOfOutlineDisclosureControlAtRow:row];

        if (CGRectIsEmpty(disclosureControlFrame))
            continue;

        var control = [self _dequeueDisclosureControl];

        _disclosureControlsForRows[row] = control;

        [control setState:[self isItemExpanded:item] ? CPOnState : CPOffState];
        var selector = [self isRowSelected:row] ? @"setThemeState:" : @"unsetThemeState:";
        [control performSelector:CPSelectorFromString(selector) withObject:CPThemeStateSelected];
        [control setFrame:disclosureControlFrame];

        [self addSubview:control];
    }
}

/*!
    @ignore
*/
- (void)_unloadDataViewsInRows:(CPIndexSet)rows columns:(CPIndexSet)columns
{
    [super _unloadDataViewsInRows:rows columns:columns];

    var outlineColumn = [[self tableColumns] indexOfObjectIdenticalTo:[self outlineTableColumn]];

    if (![columns containsIndex:outlineColumn])
        return;

    var rowArray = [];

    [rows getIndexes:rowArray maxCount:-1 inIndexRange:nil];

    var rowIndex = 0,
        rowsCount = rowArray.length;

    for (; rowIndex < rowsCount; ++rowIndex)
    {
        var row = rowArray[rowIndex],
            control = _disclosureControlsForRows[row];

        if (!control)
            continue;

        [control removeFromSuperview];

        [self _enqueueDisclosureControl:control];

        _disclosureControlsForRows[row] = nil;
    }
}

/*!
    @ignore
*/
- (void)_toggleFromDisclosureControl:(CPControl)aControl
{
    var controlFrame = [aControl frame],
        item = [self itemAtRow:[self rowAtPoint:CGPointMake(CGRectGetMinX(controlFrame), CGRectGetMidY(controlFrame))]];

    if ([self isItemExpanded:item])
        [self collapseItem:item];

    else
        [self expandItem:item expandChildren:([[CPApp currentEvent] modifierFlags] & CPAlternateKeyMask)];
}

/*!
    @ignore
*/
- (void)_enqueueDisclosureControl:(CPControl)aControl
{
    _disclosureControlQueue.push(aControl);
}

/*!
    @ignore
*/
- (CPControl)_dequeueDisclosureControl
{
    if (_disclosureControlQueue.length)
        return _disclosureControlQueue.pop();

    if (!_disclosureControlData)
        if (!_disclosureControlPrototype)
            return nil;
        else
            _disclosureControlData = [CPKeyedArchiver archivedDataWithRootObject:_disclosureControlPrototype];

    var disclosureControl = [CPKeyedUnarchiver unarchiveObjectWithData:_disclosureControlData];

    [disclosureControl setTarget:self];
    [disclosureControl setAction:@selector(_toggleFromDisclosureControl:)];

    return disclosureControl;
}

/*!
    @ignore
*/
- (void)_noteSelectionIsChanging
{
    if (!_coalesceSelectionNotificationState || _coalesceSelectionNotificationState === CPOutlineViewCoalesceSelectionNotificationStateOn)
    {
        [[CPNotificationCenter defaultCenter]
            postNotificationName:CPOutlineViewSelectionIsChangingNotification
                          object:self
                        userInfo:nil];
    }

    if (_coalesceSelectionNotificationState === CPOutlineViewCoalesceSelectionNotificationStateOn)
        _coalesceSelectionNotificationState = CPOutlineViewCoalesceSelectionNotificationStateDid;
}

/*!
    @ignore
*/
- (void)_noteSelectionDidChange
{
    if (!_coalesceSelectionNotificationState)
    {
        [[CPNotificationCenter defaultCenter]
            postNotificationName:CPOutlineViewSelectionDidChangeNotification
                          object:self
                        userInfo:nil];
    }

    if (_coalesceSelectionNotificationState === CPOutlineViewCoalesceSelectionNotificationStateOn)
        _coalesceSelectionNotificationState = CPOutlineViewCoalesceSelectionNotificationStateDid;
}

/*!
    @ignore
*/
- (void)_noteItemWillExpand:(id)item
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPOutlineViewItemWillExpandNotification
                      object:self
                    userInfo:@{ "CPObject": item }];
}

/*!
    @ignore
*/
- (void)_noteItemDidExpand:(id)item
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPOutlineViewItemDidExpandNotification
                      object:self
                    userInfo:@{ "CPObject": item }];
}

/*!
    @ignore
*/
- (void)_noteItemWillCollapse:(id)item
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPOutlineViewItemWillCollapseNotification
                      object:self
                    userInfo:@{ "CPObject": item }];
}

/*!
    @ignore
*/
- (void)_noteItemDidCollapse:(id)item
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPOutlineViewItemDidCollapseNotification
                      object:self
                    userInfo:@{ "CPObject": item }];
}

- (void)keyDown:(CPEvent)anEvent
{
    var character = [anEvent charactersIgnoringModifiers],
        modifierFlags = [anEvent modifierFlags];

    // Check for the key events manually, as opposed to waiting for CPWindow to sent the actual action message
    // in _processKeyboardUIKey:, because we might not want to handle the arrow events.

    if (character !== CPRightArrowFunctionKey && character !== CPLeftArrowFunctionKey)
        return [super keyDown:anEvent];

    var rows = [self selectedRowIndexes],
        indexes = [],
        items = [];

    [rows getIndexes:indexes maxCount:-1 inIndexRange:nil];

    var i = 0,
        c = [indexes count];

    for (; i < c; i++)
        items.push([self itemAtRow:indexes[i]]);

    if (character === CPRightArrowFunctionKey)
    {
        for (var i = 0; i < c; i++)
            [self expandItem:items[i]];
    }
    else if (character === CPLeftArrowFunctionKey)
    {
        // When a single, collapsed item is selected and the left arrow key is pressed, the parent
        // should be selected if possible.
        if (c == 1)
        {
            var theItem = items[0];
            if (![self isItemExpanded:theItem])
            {
                var parent = [self parentForItem:theItem],
                    shouldSelect = parent && SELECTION_SHOULD_CHANGE(self) && SHOULD_SELECT_ITEM(self, parent);
                if (shouldSelect)
                {
                    var rowIndex = [self rowForItem:parent];
                    [self selectRowIndexes:[CPIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
                    [self scrollRowToVisible:rowIndex];
                    return;
                }
            }
        }

        for (var i = 0; i < c; i++)
            [self collapseItem:items[i]];
    }

    [super keyDown:anEvent];
}

- (CPView)_viewForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRow
{
    return [_outlineViewDelegate outlineView:self viewForTableColumn:aTableColumn item:[self itemAtRow:aRow]];
}

- (CPView)_dataViewForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRow
{
    return [_outlineViewDelegate outlineView:self dataViewForTableColumn:aTableColumn item:[self itemAtRow:aRow]];
}

- (BOOL)_dataSourceRespondsToObjectValueForTableColumn
{
    return _implementedOutlineViewDataSourceMethods & CPOutlineViewDataSource_outlineView_objectValue_forTableColumn_byItem_;
}

- (BOOL)_delegateRespondsToViewForTableColumn
{
    return _implementedOutlineViewDelegateMethods & CPOutlineViewDelegate_outlineView_viewForTableColumn_item_;
}

- (BOOL)_delegateRespondsToDataViewForTableColumn
{
    return _implementedOutlineViewDelegateMethods & CPOutlineViewDelegate_outlineView_dataViewForTableColumn_item_;
}

@end

// FIX ME: We're using with() here because Safari fails if we use anOutlineView._itemInfosForItems or whatever...
var _reloadItem = function(/*CPOutlineView*/ anOutlineView, /*id*/ anItem)
{
    if (!anItem)
        return;

    with (anOutlineView)
    {
        // Get the existing info if it exists.
        var itemInfosForItems = _itemInfosForItems,
            dataSource = _outlineViewDataSource,
            itemUID = [anItem UID],
            itemInfo = itemInfosForItems[itemUID];

        // If we're not in the tree, then just bail.
        if (!itemInfo)
            return [];

        // See if the item itself can be swapped out.
        var parent = itemInfo.parent,
            parentItemInfo = parent ? itemInfosForItems[[parent UID]] : _rootItemInfo,
            parentChildren = parentItemInfo.children,
            index = [parentChildren indexOfObjectIdenticalTo:anItem],
            newItem = [dataSource outlineView:anOutlineView child:index ofItem:parent];

        if (anItem !== newItem)
        {
            itemInfosForItems[[anItem UID]] = nil;
            itemInfosForItems[[newItem UID]] = itemInfo;

            parentChildren[index] = newItem;
            _itemsForRows[itemInfo.row] = newItem;
        }

        itemInfo.isExpandable = [dataSource outlineView:anOutlineView isItemExpandable:newItem];
        itemInfo.isExpanded = itemInfo.isExpandable && itemInfo.isExpanded;
        itemInfo.shouldShowOutlineDisclosureControl = !(_implementedOutlineViewDelegateMethods & CPOutlineViewDelegate_outlineView_shouldShowOutlineDisclosureControlForItem_) || [_outlineViewDelegate outlineView:self shouldShowOutlineDisclosureControlForItem:newItem];
    }
};

// FIX ME: We're using with() here because Safari fails if we use anOutlineView._itemInfosForItems or whatever...
var _loadItemInfoForItem = function(/*CPOutlineView*/ anOutlineView, /*id*/ anItem,  /*BOOL*/ isIntermediate)
{
    with (anOutlineView)
    {
        var itemInfosForItems = _itemInfosForItems,
            dataSource = _outlineViewDataSource;

        if (!anItem)
            var itemInfo = _rootItemInfo;

        else
        {
            // Get the existing info if it exists.
            var itemUID = [anItem UID],
                itemInfo = itemInfosForItems[itemUID];

            // If we're not in the tree, then just bail.
            if (!itemInfo)
                return [];

            itemInfo.isExpandable = [dataSource outlineView:anOutlineView isItemExpandable:anItem];
            itemInfo.shouldShowOutlineDisclosureControl = !(_implementedOutlineViewDelegateMethods & CPOutlineViewDelegate_outlineView_shouldShowOutlineDisclosureControlForItem_) || [_outlineViewDelegate outlineView:self shouldShowOutlineDisclosureControlForItem:anItem];

            // If we were previously expanded, but now no longer expandable, "de-expand".
            // NOTE: we are *not* collapsing, thus no notification is posted.
            if (!itemInfo.isExpandable && itemInfo.isExpanded)
            {
                itemInfo.isExpanded = NO;
                itemInfo.children = [];
            }
        }

        // The root item does not count as a descendant.
        var weight = itemInfo.weight,
            descendants = anItem ? [anItem] : [];

        if (itemInfo.isExpanded && (!(_implementedOutlineViewDataSourceMethods & CPOutlineViewDataSource_outlineView_shouldDeferDisplayingChildrenOfItem_) ||
            ![dataSource outlineView:anOutlineView shouldDeferDisplayingChildrenOfItem:anItem]))
        {
            var index = 0,
                count = [dataSource outlineView:anOutlineView numberOfChildrenOfItem:anItem],
                level = itemInfo.level + 1;

            itemInfo.children = [];

            for (; index < count; ++index)
            {
                var childItem = [dataSource outlineView:anOutlineView child:index ofItem:anItem],
                    childItemInfo = itemInfosForItems[[childItem UID]];

                if (!childItemInfo)
                {
                    childItemInfo = { isExpanded:NO, isExpandable:NO, shouldShowOutlineDisclosureControl:YES, children:[], weight:1 };
                    itemInfosForItems[[childItem UID]] = childItemInfo;
                }

                itemInfo.children[index] = childItem;

                var childDescendants = _loadItemInfoForItem(anOutlineView, childItem, YES);

                childItemInfo.parent = anItem;
                childItemInfo.level = level;
                descendants = descendants.concat(childDescendants);
            }
        }

        itemInfo.weight = descendants.length;

        if (!isIntermediate)
        {
            // row = -1 is the root item, so just go to row 0 since it is ignored.
            var index = MAX(itemInfo.row, 0),
                itemsForRows = _itemsForRows;

            descendants.unshift(index, weight);

            itemsForRows.splice.apply(itemsForRows, descendants);

            var count = itemsForRows.length;

            for (; index < count; ++index)
                itemInfosForItems[[itemsForRows[index] UID]].row = index;

            var deltaWeight = itemInfo.weight - weight;

            if (deltaWeight !== 0)
            {
                var parent = itemInfo.parent;

                while (parent)
                {
                    var parentItemInfo = itemInfosForItems[[parent UID]];

                    parentItemInfo.weight += deltaWeight;
                    parent = parentItemInfo.parent;
                }

                if (anItem)
                    _rootItemInfo.weight += deltaWeight;
            }
        }
    }//end of with
    return descendants;
};

@implementation _CPOutlineViewTableViewDataSource : CPObject
{
    CPObject _outlineView;
}

- (id)initWithOutlineView:(CPOutlineView)anOutlineView
{
    self = [super init];

    if (self)
        _outlineView = anOutlineView;

    return self;
}

- (CPInteger)numberOfRowsInTableView:(CPTableView)anOutlineView
{
    return _outlineView._itemsForRows.length;
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRow
{
    return [_outlineView._outlineViewDataSource outlineView:_outlineView objectValueForTableColumn:aTableColumn byItem:_outlineView._itemsForRows[aRow]];
}

- (void)tableView:(CPTableView)aTableView setObjectValue:(id)aValue forTableColumn:(CPTableColumn)aColumn row:(CPInteger)aRow
{
    if (!(_outlineView._implementedOutlineViewDataSourceMethods & CPOutlineViewDataSource_outlineView_setObjectValue_forTableColumn_byItem_))
        return;
    [_outlineView._outlineViewDataSource outlineView:_outlineView setObjectValue:aValue forTableColumn:aColumn byItem:_outlineView._itemsForRows[aRow]];
}

- (BOOL)tableView:(CPTableView)aTableColumn writeRowsWithIndexes:(CPIndexSet)theIndexes toPasteboard:(CPPasteboard)thePasteboard
{
    if (!(_outlineView._implementedOutlineViewDataSourceMethods & CPOutlineViewDataSource_outlineView_writeItems_toPasteboard_))
        return NO;

    var items = [],
        index = [theIndexes firstIndex];

    while (index !== CPNotFound)
    {
        [items addObject:[_outlineView itemAtRow:index]]
        index = [theIndexes indexGreaterThanIndex:index];
    }

    return [_outlineView._outlineViewDataSource outlineView:_outlineView writeItems:items toPasteboard:thePasteboard];
}

- (int)_childIndexForDropOperation:(CPTableViewDropOperation)theDropOperation row:(int)theRow offset:(CGPoint)theOffset
{
    if (_outlineView._shouldRetargetChildIndex)
        return _outlineView._retargedChildIndex;

    var childIndex = CPNotFound;

    if (theDropOperation === CPTableViewDropAbove)
    {
        var parentItem = [_outlineView _parentItemForUpperRow:theRow - 1 andLowerRow:theRow atMouseOffset:theOffset],
            itemInfo = (parentItem !== nil) ? _outlineView._itemInfosForItems[[parentItem UID]] : _outlineView._rootItemInfo,
            children = itemInfo.children;

        childIndex = [children indexOfObject:[_outlineView itemAtRow:theRow]];

        if (childIndex === CPNotFound)
            childIndex = children.length;
    }
    else if (theDropOperation === CPTableViewDropOn)
        childIndex = -1;

    return childIndex;
}

- (void)_parentItemForDropOperation:(CPTableViewDropOperation)theDropOperation row:(int)theRow offset:(CGPoint)theOffset
{
    if (theDropOperation === CPTableViewDropAbove)
        return [_outlineView _parentItemForUpperRow:theRow - 1 andLowerRow:theRow atMouseOffset:theOffset]

    return [_outlineView itemAtRow:theRow];
}

- (CPDragOperation)tableView:(CPTableView)aTableView validateDrop:(id < CPDraggingInfo >)theInfo
    proposedRow:(int)theRow proposedDropOperation:(CPTableViewDropOperation)theOperation
{
    if (!(_outlineView._implementedOutlineViewDataSourceMethods & CPOutlineViewDataSource_outlineView_validateDrop_proposedItem_proposedChildIndex_))
        return CPDragOperationNone;

    // Make sure the retargeted item and index are reset
    _outlineView._retargetedItem = nil;
    _outlineView._shouldRetargetItem = NO;

    _outlineView._retargedChildIndex = nil;
    _outlineView._shouldRetargetChildIndex = NO;

    var location = [_outlineView convertPoint:[theInfo draggingLocation] fromView:nil],
        parentItem = [self _parentItemForDropOperation:theOperation row:theRow offset:location],
        childIndex = [self _childIndexForDropOperation:theOperation row:theRow offset:location];

    return [_outlineView._outlineViewDataSource outlineView:_outlineView validateDrop:theInfo proposedItem:parentItem proposedChildIndex:childIndex];
}

- (BOOL)tableView:(CPTableView)aTableView acceptDrop:(id <CPDraggingInfo>)theInfo row:(int)theRow dropOperation:(CPTableViewDropOperation)theOperation
{
    if (!(_outlineView._implementedOutlineViewDataSourceMethods & CPOutlineViewDataSource_outlineView_acceptDrop_item_childIndex_))
        return NO;

    var location = [_outlineView convertPoint:[theInfo draggingLocation] fromView:nil],
        parentItem = [self _parentItemForDropOperation:theOperation row:theRow offset:location],
        childIndex = [self _childIndexForDropOperation:theOperation row:theRow offset:location];

    _outlineView._retargetedItem = nil;
    _outlineView._shouldRetargetItem = NO;

    _outlineView._retargedChildIndex = nil;
    _outlineView._shouldRetargetChildIndex = NO;

    return [_outlineView._outlineViewDataSource outlineView:_outlineView acceptDrop:theInfo item:parentItem childIndex:childIndex];
}

- (void)tableView:(CPTableView)aTableView sortDescriptorsDidChange:(CPArray)oldSortDescriptors
{
    if ((_outlineView._implementedOutlineViewDataSourceMethods &
         CPOutlineViewDataSource_outlineView_sortDescriptorsDidChange_))
    {
        [[_outlineView dataSource] outlineView:_outlineView sortDescriptorsDidChange:oldSortDescriptors];
    }
}

@end

@implementation _CPOutlineViewTableViewDelegate : CPObject
{
    CPOutlineView   _outlineView;
}

- (id)initWithOutlineView:(CPOutlineView)anOutlineView
{
    self = [super init];

    if (self)
        _outlineView = anOutlineView;

    return self;
}

- (BOOL)tableView:(CPTableView)theTableView shouldSelectRow:(int)theRow
{
    return SHOULD_SELECT_ITEM(_outlineView, [_outlineView itemAtRow:theRow]);
}

- (BOOL)selectionShouldChangeInTableView:(CPTableView)theTableView
{
    return SELECTION_SHOULD_CHANGE(_outlineView);
}

- (BOOL)tableView:(CPTableView)aTableView shouldEditTableColumn:(CPTableColumn)aColumn row:(int)aRow
{
    if ((_outlineView._implementedOutlineViewDelegateMethods & CPOutlineViewDelegate_outlineView_shouldEditTableColumn_item_))
        return [_outlineView._outlineViewDelegate outlineView:_outlineView shouldEditTableColumn:aColumn item:[_outlineView itemAtRow:aRow]];

    return NO;
}

- (float)tableView:(CPTableView)theTableView heightOfRow:(int)theRow
{
    if ((_outlineView._implementedOutlineViewDelegateMethods & CPOutlineViewDelegate_outlineView_heightOfRowByItem_))
        return [_outlineView._outlineViewDelegate outlineView:_outlineView heightOfRowByItem:[_outlineView itemAtRow:theRow]];

    return [theTableView rowHeight];
}

- (void)tableView:(CPTableView)aTableView willDisplayView:(id)aView forTableColumn:(CPTableColumn)aTableColumn row:(int)aRowIndex
{
    if ((_outlineView._implementedOutlineViewDelegateMethods & CPOutlineViewDelegate_outlineView_willDisplayView_forTableColumn_item_))
    {
        var item = [_outlineView itemAtRow:aRowIndex];
        [_outlineView._outlineViewDelegate outlineView:_outlineView willDisplayView:aView forTableColumn:aTableColumn item:item];
    }
}

- (BOOL)tableView:(CPTableView)aTableView isGroupRow:(int)aRow
{
    if ((_outlineView._implementedOutlineViewDelegateMethods & CPOutlineViewDelegate_outlineView_isGroupItem_))
        return [_outlineView._outlineViewDelegate outlineView:_outlineView isGroupItem:[_outlineView itemAtRow:aRow]];

    return NO;
}

- (CPMenu)tableView:(CPTableView)aTableView menuForTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
{
    if ((_outlineView._implementedOutlineViewDelegateMethods & CPOutlineViewDelegate_outlineView_menuForTableColumn_item_))
    {
        var item = [_outlineView itemAtRow:aRow];
        return [_outlineView._outlineViewDelegate outlineView:_outlineView menuForTableColumn:aTableColumn item:item]
    }

    // We reimplement CPView menuForEvent: because we can't call it directly. CPTableView implements menuForEvent:
    // to call this delegate method.
    return [_outlineView menu] || [[_outlineView class] defaultMenu];
}

@end

@implementation CPDisclosureButton : CPButton
{
    float _angle;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
        [self setBordered:NO];

    return self;
}

- (void)setState:(CPState)aState
{
    [super setState:aState];

    if ([self state] === CPOnState)
        _angle = 0.0;

    else
        _angle = -PI_2;
}

- (void)drawRect:(CGRect)aRect
{
    var bounds = [self bounds],
        context = [[CPGraphicsContext currentContext] graphicsPort],
        width = CGRectGetWidth(bounds),
        height = CGRectGetHeight(bounds);

    CGContextBeginPath(context);

    if (_angle)
    {
        var centre = CGPointMake(FLOOR(width / 2.0), FLOOR(height / 2.0));
        CGContextTranslateCTM(context, centre.x, centre.y);
        CGContextRotateCTM(context, _angle);
        CGContextTranslateCTM(context, -centre.x, -centre.y);
    }

    // Center, but crisp.
    CGContextTranslateCTM(context, FLOOR((width - 9.0) / 2.0), FLOOR((height - 8.0) / 2.0));

    CGContextMoveToPoint(context, 0.0, 0.0);
    CGContextAddLineToPoint(context, 9.0, 0.0);
    CGContextAddLineToPoint(context, 4.5, 8.0);
    CGContextClosePath(context);

    CGContextSetFillColor(context,
        colorForDisclosureTriangle([self hasThemeState:CPThemeStateSelected],
            [self hasThemeState:CPThemeStateHighlighted]));
    CGContextFillPath(context);

    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0.0, 0.0);
    CGContextAddLineToPoint(context, 4.5, 8.0);

    if (_angle === 0.0)
        CGContextAddLineToPoint(context, 9.0, 0.0);

    CGContextSetStrokeColor(context, [CPColor colorWithCalibratedWhite:1.0 alpha: 0.7]);
    CGContextStrokePath(context);
}

@end


var CPOutlineViewIndentationPerLevelKey = @"CPOutlineViewIndentationPerLevelKey",
    CPOutlineViewOutlineTableColumnKey = @"CPOutlineViewOutlineTableColumnKey",
    CPOutlineViewDataSourceKey = @"CPOutlineViewDataSourceKey",
    CPOutlineViewDelegateKey = @"CPOutlineViewDelegateKey";

@implementation CPOutlineView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        // The root item has weight "0", thus represents the weight solely of its descendants.
        _rootItemInfo = { isExpanded:YES, isExpandable:NO, level:-1, row:-1, children:[], weight:0 };

        _itemsForRows = [];
        _itemInfosForItems = { };
        _disclosureControlsForRows = [];

        [self setIndentationMarkerFollowsDataView:YES];
        [self setDisclosureControlPrototype:[[CPDisclosureButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 10.0)]];

        _outlineTableColumn = [aCoder decodeObjectForKey:CPOutlineViewOutlineTableColumnKey];
        _indentationPerLevel = [aCoder decodeFloatForKey:CPOutlineViewIndentationPerLevelKey];

        _outlineViewDataSource = [aCoder decodeObjectForKey:CPOutlineViewDataSourceKey];
        _outlineViewDelegate = [aCoder decodeObjectForKey:CPOutlineViewDelegateKey];

        [super setDataSource:[[_CPOutlineViewTableViewDataSource alloc] initWithOutlineView:self]];
        [super setDelegate:[[_CPOutlineViewTableViewDelegate alloc] initWithOutlineView:self]];

        [self _updateIsViewBased];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    // Make sure we don't encode our internal delegate and data source.
    var internalDelegate = _delegate,
        internalDataSource = _dataSource;
    _delegate = nil;
    _dataSource = nil;
    [super encodeWithCoder:aCoder];
    _delegate = internalDelegate;
    _dataSource = internalDataSource;

    [aCoder encodeObject:_outlineTableColumn forKey:CPOutlineViewOutlineTableColumnKey];
    [aCoder encodeFloat:_indentationPerLevel forKey:CPOutlineViewIndentationPerLevelKey];

    [aCoder encodeObject:_outlineViewDataSource forKey:CPOutlineViewDataSourceKey];
    [aCoder encodeObject:_outlineViewDelegate forKey:CPOutlineViewDelegateKey];
}

@end


var colorForDisclosureTriangle = function(isSelected, isHighlighted)
{
    return isSelected
        ? (isHighlighted
            ? [CPColor colorWithCalibratedWhite:0.9 alpha: 1.0]
            : [CPColor colorWithCalibratedWhite:1.0 alpha: 1.0])
        : (isHighlighted
            ? [CPColor colorWithCalibratedWhite:0.4 alpha: 1.0]
            : [CPColor colorWithCalibratedWhite:0.5 alpha: 1.0]);
};
