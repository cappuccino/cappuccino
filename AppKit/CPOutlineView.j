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

@import "CPTableColumn.j"
@import "CPTableView.j"


CPOutlineViewColumnDidMoveNotification          = @"CPOutlineViewColumnDidMoveNotification";
CPOutlineViewColumnDidResizeNotification        = @"CPOutlineViewColumnDidResizeNotification";
CPOutlineViewItemDidCollapseNotification        = @"CPOutlineViewItemDidCollapseNotification";
CPOutlineViewItemDidExpandNotification          = @"CPOutlineViewItemDidExpandNotification";
CPOutlineViewItemWillCollapseNotification       = @"CPOutlineViewItemWillCollapseNotification";
CPOutlineViewItemWillExpandNotification         = @"CPOutlineViewItemWillExpandNotification";
CPOutlineViewSelectionDidChangeNotification     = @"CPOutlineViewSelectionDidChangeNotification";
CPOutlineViewSelectionIsChangingNotification    = @"CPOutlineViewSelectionIsChangingNotification";

var CPOutlineViewDataSource_outlineView_setObjectValue_forTableColumn_byItem_                       = 1 << 1,
    CPOutlineViewDataSource_outlineView_shouldDeferDisplayingChildrenOfItem_                        = 1 << 2,

    CPOutlineViewDataSource_outlineView_acceptDrop_item_childIndex_                                 = 1 << 3,
    CPOutlineViewDataSource_outlineView_validateDrop_proposedItem_proposedChildIndex_               = 1 << 4,
    CPOutlineViewDataSource_outlineView_validateDrop_proposedRow_proposedDropOperation_             = 1 << 5,
    CPOutlineViewDataSource_outlineView_namesOfPromisedFilesDroppedAtDestination_forDraggedItems_   = 1 << 6,

    CPOutlineViewDataSource_outlineView_itemForPersistentObject_                                    = 1 << 7,
    CPOutlineViewDataSource_outlineView_persistentObjectForItem_                                    = 1 << 8,

    CPOutlineViewDataSource_outlineView_writeItems_toPasteboard_                                    = 1 << 9,

    CPOutlineViewDataSource_outlineView_sortDescriptorsDidChange_                                   = 1 << 10;

var CPOutlineViewDelegate_outlineView_dataViewForTableColumn_item_                                  = 1 << 1,
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
    CPOutlineViewDelegate_outlineView_shouldShowOutlineViewForItem_                                 = 1 << 15,
    CPOutlineViewDelegate_outlineView_shouldShowViewExpansionForTableColumn_item_                   = 1 << 16,
    CPOutlineViewDelegate_outlineView_shouldTrackView_forTableColumn_item_                          = 1 << 17,
    CPOutlineViewDelegate_outlineView_shouldTypeSelectForEvent_withCurrentSearchString_             = 1 << 18,
    CPOutlineViewDelegate_outlineView_sizeToFitWidthOfColumn_                                       = 1 << 19,
    CPOutlineViewDelegate_outlineView_toolTipForView_rect_tableColumn_item_mouseLocation_           = 1 << 20,
    CPOutlineViewDelegate_outlineView_typeSelectStringForTableColumn_item_                          = 1 << 21,
    CPOutlineViewDelegate_outlineView_willDisplayOutlineView_forTableColumn_item_                   = 1 << 22,
    CPOutlineViewDelegate_outlineView_willDisplayView_forTableColumn_item_                          = 1 << 23,
    CPOutlineViewDelegate_selectionShouldChangeInOutlineView_                                       = 1 << 24;

CPOutlineViewDropOnItemIndex = -1;

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
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {

        _selectionHighlightStyle = CPTableViewSelectionHighlightStyleSourceList;

        // The root item has weight "0", thus represents the weight solely of its descendants.
        _rootItemInfo = { isExpanded:YES, isExpandable:NO, level:-1, row:-1, children:[], weight:0 };

        _itemsForRows = [];
        _itemInfosForItems = { };
        _disclosureControlsForRows = [];

        _retargetedItem = nil;
        _shouldRetargetItem = NO;

        _retargedChildIndex = nil;
        _shouldRetargetChildIndex = NO;
        _startHoverTime = nil;

        [self setIndentationPerLevel:16.0];
        [self setIndentationMarkerFollowsDataView:YES];

        [super setDataSource:[[_CPOutlineViewTableViewDataSource alloc] initWithOutlineView:self]];
        [super setDelegate:[[_CPOutlineViewTableViewDelegate alloc] initWithOutlineView:self]];

        [self setDisclosureControlPrototype:[[CPDisclosureButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 10.0)]];
    }

    return self;
}

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

    if (![aDataSource respondsToSelector:@selector(outlineView:objectValueForTableColumn:byItem:)])
        [CPException raise:CPInternalInconsistencyException reason:"Data source must implement 'outlineView:objectValueForTableColumn:byItem:'"];

    _outlineViewDataSource = aDataSource;
    _implementedOutlineViewDataSourceMethods = 0;

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

- (id)dataSource
{
    return _outlineViewDataSource;
}

- (BOOL)isExpandable:(id)anItem
{
    if (!anItem)
        return YES;

    var itemInfo = _itemInfosForItems[[anItem UID]];

    if (!itemInfo)
        return NO;

    return itemInfo.isExpandable;
}

- (void)isItemExpanded:(id)anItem
{
    if (!anItem)
        return YES;

    var itemInfo = _itemInfosForItems[[anItem UID]];

    if (!itemInfo)
        return NO;

    return itemInfo.isExpanded;
}

- (void)expandItem:(id)anItem
{
    [self expandItem:anItem expandChildren:NO];
}

- (void)expandItem:(id)anItem expandChildren:(BOOL)shouldExpandChildren
{
    var itemInfo = null;

    if (!anItem)
        itemInfo = _rootItemInfo;
    else
        itemInfo = _itemInfosForItems[[anItem UID]];

    if (!itemInfo)
        return;

    // to prevent items which are already expanded from firing notifications
    if (!itemInfo.isExpanded)
    {
        [self _noteItemWillExpand:anItem];
        itemInfo.isExpanded = YES;
        [self _noteItemDidExpand:anItem];
        [self reloadItem:anItem reloadChildren:YES];
    }

    if (shouldExpandChildren)
    {
        var children = itemInfo.children,
            childIndex = children.length;

        while (childIndex--)
            [self expandItem:children[childIndex] expandChildren:YES];
    }
}

- (void)collapseItem:(id)anItem
{
    if (!anItem)
        return;

    var itemInfo = _itemInfosForItems[[anItem UID]];

    if (!itemInfo)
        return;

    if (!itemInfo.isExpanded)
        return;

    [self _noteItemWillCollapse:anItem];
    itemInfo.isExpanded = NO;
    [self _noteItemDidCollapse:anItem];

    [self reloadItem:anItem reloadChildren:YES];
}

- (void)reloadItem:(id)anItem
{
    [self reloadItem:anItem reloadChildren:NO];
}

- (void)reloadItem:(id)anItem reloadChildren:(BOOL)shouldReloadChildren
{
    if (!!shouldReloadChildren || !anItem)
        _loadItemInfoForItem(self, anItem);
    else
        _reloadItem(self, anItem);

    [super reloadData];
}

- (id)itemAtRow:(CPInteger)aRow
{
    return _itemsForRows[aRow] || nil;
}

- (CPInteger)rowForItem:(id)anItem
{
    if (!anItem)
        return _rootItemInfo.row;

    var itemInfo = _itemInfosForItems[[anItem UID]];

    if (!itemInfo)
        return CPNotFound;

    return itemInfo.row;
}

- (void)setOutlineTableColumn:(CPTableColumn)aTableColumn
{
    if (_outlineTableColumn === aTableColumn)
        return;

    _outlineTableColumn = aTableColumn;

    // FIXME: efficiency.
    [self reloadData];
}

- (CPTableColumn)outlineTableColumn
{
    return _outlineTableColumn;
}

- (CPInteger)levelForItem:(id)anItem
{
    if (!anItem)
        return _rootItemInfo.level;

    var itemInfo = _itemInfosForItems[[anItem UID]];

    if (!itemInfo)
        return CPNotFound;

    return itemInfo.level;
}

- (CPInteger)levelForRow:(CPInteger)aRow
{
    return [self levelForItem:[self itemAtRow:aRow]];
}

- (void)setIndentationPerLevel:(float)anIndentationWidth
{
    if (_indentationPerLevel === anIndentationWidth)
        return;

    _indentationPerLevel = anIndentationWidth;

    // FIXME: efficiency!!!!
    [self reloadData];
}

- (float)indentationPerLevel
{
    return _indentationPerLevel;
}

- (void)setIndentationMarkerFollowsDataView:(BOOL)indentationMarkerShouldFollowDataView
{
    if (_indentationMarkerFollowsDataView === indentationMarkerShouldFollowDataView)
        return;

    _indentationMarkerFollowsDataView = indentationMarkerShouldFollowDataView;

    // !!!!
    [self reloadData];
}

- (BOOL)indentationMarkerFollowsDataView
{
    return _indentationMarkerFollowsDataView;
}

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

- (CGRect)frameOfOutlineDataViewAtColumn:(CPInteger)aColumn row:(CPInteger)aRow
{
    var frame = [super frameOfDataViewAtColumn:aColumn row:aRow],
        indentationWidth = ([self levelForRow:aRow] + 1) * [self indentationPerLevel];

    frame.origin.x += indentationWidth;
    frame.size.width -= indentationWidth;

    return frame;
}

- (void)_performSelection:(BOOL)select forRow:(CPInteger)rowIndex context:(id)context
{
    [super _performSelection:select forRow:rowIndex context:context];

    var control = _disclosureControlsForRows[rowIndex],
        selector = select ? @"setThemeState:" : @"unsetThemeState:";

    [control performSelector:CPSelectorFromString(selector) withObject:CPThemeStateSelected];
}

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
            CPOutlineViewDelegate_outlineView_shouldShowOutlineViewForItem_                      , @selector(outlineView:shouldShowOutlineViewForItem:),
            CPOutlineViewDelegate_outlineView_shouldShowViewExpansionForTableColumn_item_        , @selector(outlineView:shouldShowViewExpansionForTableColumn:item:),
            CPOutlineViewDelegate_outlineView_shouldTrackView_forTableColumn_item_               , @selector(outlineView:shouldTrackView:forTableColumn:item:),
            CPOutlineViewDelegate_outlineView_shouldTypeSelectForEvent_withCurrentSearchString_  , @selector(outlineView:shouldTypeSelectForEvent:withCurrentSearchString:),
            CPOutlineViewDelegate_outlineView_sizeToFitWidthOfColumn_                            , @selector(outlineView:sizeToFitWidthOfColumn:),
            CPOutlineViewDelegate_outlineView_toolTipForView_rect_tableColumn_item_mouseLocation_, @selector(outlineView:toolTipForView:rect:tableColumn:item:mouseLocation:),
            CPOutlineViewDelegate_outlineView_typeSelectStringForTableColumn_item_               , @selector(outlineView:typeSelectStringForTableColumn:item:),
            CPOutlineViewDelegate_outlineView_willDisplayOutlineView_forTableColumn_item_        , @selector(outlineView:willDisplayOutlineView:forTableColumn:item:),
            CPOutlineViewDelegate_outlineView_willDisplayView_forTableColumn_item_               , @selector(outlineView:willDisplayView:forTableColumn:item:),
            CPOutlineViewDelegate_selectionShouldChangeInOutlineView_                            , @selector(selectionShouldChangeInOutlineView:)
        ],
        delegateCount = [delegateMethods count];

    for (var i=0; i < delegateCount; i += 2)
    {
        var bitMask = delegateMethods[i],
            selector = delegateMethods[i+1];

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

}

- (id)delegate
{
    return _outlineViewDelegate;
}

- (void)setDisclosureControlPrototype:(CPControl)aControl
{
    _disclosureControlPrototype = aControl;
    _disclosureControlData = nil;
    _disclosureControlQueue = [];

    // fIXME: reall?
    [self reloadData];
}

- (void)reloadData
{
    [self reloadItem:nil reloadChildren:YES];
}

- (CGRect)frameOfDataViewAtColumn:(CPInteger)aColumn row:(CPInteger)aRow
{
    var tableColumn = [self tableColumns][aColumn];

    if (tableColumn === _outlineTableColumn)
        return [self frameOfOutlineDataViewAtColumn:aColumn row:aRow];

    return [super frameOfDataViewAtColumn:aColumn row:aRow];
}

- (void)setDropItem:(id)theItem dropChildIndex:(int)theIndex
{
    if (_dropItem !== theItem && theIndex < 0 && [self isExpandable:theItem] && ![self isItemExpanded:theItem])
    {
        if (_dragHoverTimer)
            [_dragHoverTimer invalidate];

        var autoExpandCallBack = function(){
            if (_dropItem)
            {
                [_dropOperationFeedbackView blink];
                [CPTimer scheduledTimerWithTimeInterval:.3 callback:objj_msgSend(self, "expandItem:", _dropItem) repeats:NO];
            }
        }

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

- (void)_draggingEnded
{
    [super _draggingEnded];
    _dropItem = nil;
    [_dragHoverTimer invalidate];
    _dragHoverTimer = nil;
}

- (id)_parentItemForUpperRow:(int)theUpperRowIndex andLowerRow:(int)theLowerRowIndex atMouseOffset:(CPPoint)theOffset
{
    if (_shouldRetargetItem)
        return _retargetedItem;

    var lowerLevel = [self levelForRow:theLowerRowIndex]
        upperItem = [self itemAtRow:theUpperRowIndex];
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

- (CPRect)_rectForDropHighlightViewBetweenUpperRow:(int)theUpperRowIndex andLowerRow:(int)theLowerRowIndex offset:(CPPoint)theOffset
{
    // Call super and the update x to reflect the current indentation level
    var rect = [super _rectForDropHighlightViewBetweenUpperRow:theUpperRowIndex andLowerRow:theLowerRowIndex offset:theOffset],
        parentItem = [self _parentItemForUpperRow:theUpperRowIndex andLowerRow:theLowerRowIndex atMouseOffset:theOffset],
        level = [self levelForItem:parentItem];

    rect.origin.x = (level + 1) * [self indentationPerLevel];
    rect.size.width -= rect.origin.x; // This assumes that the x returned by super is zero

    return rect;
}

- (void)_loadDataViewsInRows:(CPIndexSet)rows columns:(CPIndexSet)columns
{
    [super _loadDataViewsInRows:rows columns:columns];

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
            item = _itemsForRows[row],
            isExpandable = [self isExpandable:item];

       if (!isExpandable)
            continue;

        var control = [self _dequeueDisclosureControl],
            frame = [control frame],
            dataViewFrame = [self frameOfDataViewAtColumn:outlineColumn row:row];

        frame.origin.x = _indentationMarkerFollowsDataView ? _CGRectGetMinX(dataViewFrame) - _CGRectGetWidth(frame) : 0.0;
        frame.origin.y = _CGRectGetMinY(dataViewFrame);
        frame.size.height = _CGRectGetHeight(dataViewFrame);
        // FIXME: center instead?
        //frame.origin.y = _CGRectGetMidY(dataViewFrame) - _CGRectGetHeight(frame) / 2.0;

        _disclosureControlsForRows[row] = control;

        [control setState:[self isItemExpanded:item] ? CPOnState : CPOffState];
        var selector = [self isRowSelected:row] ? @"setThemeState:" : @"unsetThemeState:";
        [control performSelector:CPSelectorFromString(selector) withObject:CPThemeStateSelected];
        [control setFrame:frame];

        [self addSubview:control];
    }
}

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

- (void)_toggleFromDisclosureControl:(CPControl)aControl
{
    var controlFrame = [aControl frame],
        item = [self itemAtRow:[self rowAtPoint:_CGPointMake(_CGRectGetMinX(controlFrame), _CGRectGetMidY(controlFrame))]];

    if ([self isItemExpanded:item])
        [self collapseItem:item];

    else
        [self expandItem:item];
}

- (void)_enqueueDisclosureControl:(CPControl)aControl
{
    _disclosureControlQueue.push(aControl);
}

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

- (void)_noteSelectionIsChanging
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPOutlineViewSelectionIsChangingNotification
                      object:self
                    userInfo:nil];
}

- (void)_noteSelectionDidChange
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPOutlineViewSelectionDidChangeNotification
                      object:self
                    userInfo:nil];
}

- (void)_noteItemWillExpand:(id)item
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPOutlineViewItemWillExpandNotification
                      object:self
                    userInfo:[CPDictionary dictionaryWithObject:item forKey:"CPObject"]];
}

- (void)_noteItemDidExpand:(id)item
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPOutlineViewItemDidExpandNotification
                      object:self
                    userInfo:[CPDictionary dictionaryWithObject:item forKey:"CPObject"]];
}

- (void)_noteItemWillCollapse:(id)item
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPOutlineViewItemWillCollapseNotification
                      object:self
                    userInfo:[CPDictionary dictionaryWithObject:item forKey:"CPObject"]];
}

- (void)_noteItemDidCollapse:(id)item
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPOutlineViewItemDidCollapseNotification
                      object:self
                    userInfo:[CPDictionary dictionaryWithObject:item forKey:"CPObject"]];
}

@end

// FIX ME: We're using with() here because Safari fails if we use anOutlineView._itemInfosForItems or whatever...
var _reloadItem = function(/*CPOutlineView*/ anOutlineView, /*id*/ anItem)
{
    if (!anItem)
        return;

    with(anOutlineView)
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
    }
}

// FIX ME: We're using with() here because Safari fails if we use anOutlineView._itemInfosForItems or whatever...
var _loadItemInfoForItem = function(/*CPOutlineView*/ anOutlineView, /*id*/ anItem,  /*BOOL*/ isIntermediate)
{
    with(anOutlineView)
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
                    childItemInfo = { isExpanded:NO, isExpandable:NO, children:[], weight:1 };
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
}

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

    var rowIndexes = [];
    [theIndexes getIndexes:rowIndexes maxCount:[theIndexes count] inIndexRange:nil];

    var rowIndex = [rowIndexes count],
        items = [];

    while (rowIndex--)
        [items addObject:[_outlineView itemAtRow:[rowIndexes objectAtIndex:rowIndex]]];

    return [_outlineView._outlineViewDataSource outlineView:_outlineView writeItems:items toPasteboard:thePasteboard];
}

- (int)_childIndexForDropOperation:(CPTableViewDropOperation)theDropOperation row:(int)theRow offset:(CPPoint)theOffset
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

- (void)_parentItemForDropOperation:(CPTableViewDropOperation)theDropOperation row:(int)theRow offset:(CPPoint)theOffset
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
        parentItem = [self _parentItemForDropOperation:theOperation row:theRow offset:location];
        childIndex = [self _childIndexForDropOperation:theOperation row:theRow offset:location];

    _outlineView._retargetedItem = nil;
    _outlineView._shouldRetargetItem = NO;

    _outlineView._retargedChildIndex = nil;
    _outlineView._shouldRetargetChildIndex = NO;

    return [_outlineView._outlineViewDataSource outlineView:_outlineView acceptDrop:theInfo item:parentItem childIndex:childIndex];
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

- (CPView)tableView:(CPTableView)theTableView dataViewForTableColumn:(CPTableColumn)theTableColumn row:(int)theRow
{
    var dataView = nil;

    if ((_outlineView._implementedOutlineViewDelegateMethods & CPOutlineViewDelegate_outlineView_dataViewForTableColumn_item_))
            dataView = [_outlineView._outlineViewDelegate outlineView:_outlineView
                                           dataViewForTableColumn:theTableColumn
                                                             item:[_outlineView itemAtRow:theRow]];

    if (!dataView)
        dataView = [theTableColumn dataViewForRow:theRow];

    return dataView;
}

- (BOOL)tableView:(CPTableView)theTableView shouldSelectRow:(int)theRow
{
    if ((_outlineView._implementedOutlineViewDelegateMethods & CPOutlineViewDelegate_outlineView_shouldSelectItem_))
        return [_outlineView._outlineViewDelegate outlineView:_outlineView shouldSelectItem:[_outlineView itemAtRow:theRow]];

    return YES;
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
        context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextBeginPath(context);

    CGContextTranslateCTM(context, _CGRectGetWidth(bounds) / 2.0, _CGRectGetHeight(bounds) / 2.0);
    CGContextRotateCTM(context, _angle);
    CGContextTranslateCTM(context, -_CGRectGetWidth(bounds) / 2.0, -_CGRectGetHeight(bounds) / 2.0);

    // Center, but crisp.
    CGContextTranslateCTM(context, FLOOR((_CGRectGetWidth(bounds) - 9.0) / 2.0), FLOOR((_CGRectGetHeight(bounds) - 8.0) / 2.0));

    CGContextMoveToPoint(context, 0.0, 0.0);
    CGContextAddLineToPoint(context, 9.0, 0.0);
    CGContextAddLineToPoint(context, 4.5, 8.0);
    CGContextAddLineToPoint(context, 0.0, 0.0);

    CGContextClosePath(context);
    CGContextSetFillColor(context,
        colorForDisclosureTriangle([self hasThemeState:CPThemeStateSelected],
            [self hasThemeState:CPThemeStateHighlighted]));
    CGContextFillPath(context);


    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0.0, 0.0);
    if(_angle === 0.0) {
        CGContextAddLineToPoint(context, 4.5, 8.0);
        CGContextAddLineToPoint(context, 9.0, 0.0);
    } else {
        CGContextAddLineToPoint(context, 4.5, 8.0);
    }
    CGContextSetStrokeColor(context, [CPColor colorWithCalibratedWhite:1.0 alpha: 0.8]);
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
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_outlineTableColumn forKey:CPOutlineViewOutlineTableColumnKey];
    [aCoder encodeFloat:_indentationPerLevel forKey:CPOutlineViewIndentationPerLevelKey];

    [aCoder encodeObject:_outlineViewDataSource forKey:CPOutlineViewDataSourceKey];
    [aCoder encodeObject:_outlineViewDelegate forKey:CPOutlineViewDelegateKey];
}

@end


var colorForDisclosureTriangle = function(isSelected, isHighlighted) {
    return isSelected
        ? (isHighlighted
            ? [CPColor colorWithCalibratedWhite:0.9 alpha: 1.0]
            : [CPColor colorWithCalibratedWhite:1.0 alpha: 1.0])
        : (isHighlighted
            ? [CPColor colorWithCalibratedWhite:0.4 alpha: 1.0]
            : [CPColor colorWithCalibratedWhite:0.5 alpha: 1.0]);
}
