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

#include "CoreGraphics/CGGeometry.h"


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

@implementation CPOutlineView : CPTableView
{
    id              _outlineViewDataSource;
    CPTableColumn   _outlineTableColumn;

    float           _indentationPerLevel;

    CPInteger       _implementedOutlineViewDataSourceMethods;

    Object          _rootItemInfo;
    CPMutableArray  _itemsForRows;
    Object          _itemInfosForItems;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _rootItemInfo = { isExpanded:YES, isExpandable:NO, level:-1, row:-1, children:[], weight:1 };

        _itemsForRows = [nil];
        _itemInfosForItems = { };

        [self setIndentationPerLevel:25.0];

        [super setDataSource:[[_CPOutlineViewTableViewDataSource alloc] initWithOutlineView:self]];
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
    if (!anItem)
        return;

    var itemInfo = _itemInfosForItems[[anItem UID]];

    if (!itemInfo)
        return;

    if (itemInfo.isExpanded)
        return;

    itemInfo.isExpanded = YES;

    [self reloadItem:anItem reloadChildren:YES];
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

    itemInfo.isExpanded = NO;

    [self reloadItem:anItem reloadChildren:YES];
}

- (void)mouseDown:(CPEvent)anEvent
{
    var row = [self rowAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil]];

    if ([self isItemExpanded:[self itemAtRow:row]])
        [self collapseItem:[self itemAtRow:row]];
    else
        [self expandItem:[self itemAtRow:row]];
}

- (void)reloadItem:(id)anItem
{
    [self reloadItem:anItem reloadChildren:NO];
}

- (void)reloadItem:(id)anItem reloadChildren:(BOOL)shouldReloadChildren
{
    _loadItemInfoForItem(self, anItem, shouldReloadChildren);

    [super reloadData];
}

- (id)itemAtRow:(CPInteger)aRow
{
    return _itemsForRows[aRow + 1] || nil;
}

- (CPInteger)rowForItem:(id)aItem
{
    if (!anItem)
        return _rootItemInfo.row;

    var itemInfo = _itemInfosForItems[[anItem UID]];

    if (typeof itemInfo === "undefined")
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

    if (typeof itemInfo === "undefined")
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

- (void)reloadData
{
    [self reloadItem:nil reloadChildren:YES];
}

- (void)_enqueueReusableDataView:(CPView)aDataView
{
    if ([aDataView isKindOfClass:[_CPOutlineViewHierarchicalView class]])
    {
        [aDataView removeFromSuperview];
        [super _enqueueReusableDataView:[aDataView dataView]];
    }
    else
        [super _enqueueReusableDataView:aDataView];
}

- (CPView)_newDataViewForRow:(CPInteger)aRow tableColumn:(CPTableColumn)aTableColumn
{
    var dataView = [super _newDataViewForRow:aRow tableColumn:aTableColumn];

    if (aTableColumn !== _outlineTableColumn)
        return dataView;

    var hierarchicalView = [[_CPOutlineViewHierarchicalView alloc] init];

    [hierarchicalView setIndentationWidth:[self levelForRow:aRow] * [self indentationPerLevel]];
    [hierarchicalView setDataView:dataView];

    return hierarchicalView;
}

@end

var _loadItemInfoForItem = function(/*CPOutlineView*/ anOutlineView, /*id*/ anItem, /*BOOL*/ shouldLoadChildren,  /*id*/ parentItemInfo)
{
    // FIXME: remote...
    var dataSource = anOutlineView._outlineViewDataSource,
        itemInfosForItems = anOutlineView._itemInfosForItems,
        shouldReloadData = !parentItemInfo;

    // If we are the root, just use the "static" root item info.
    if (!anItem)
        var itemInfo = anOutlineView._rootItemInfo;

    else
    {
        // Get the existing info if it exists.
        var itemUID = [anItem UID],
            itemInfo = itemInfosForItems[itemUID];

        // If we're not in the tree, then just bail.
        if (!itemInfo)
            return [];

        // If no state, then we are the initiator, no need to update row/level.
        if (!parentItemInfo)
            parentItemInfo = itemInfo.parentItemInfo;

        itemInfo.isExpandable = [dataSource outlineView:anOutlineView isItemExpandable:anItem];

        // If we were previously expanded, but now no longer expandable, "de-expand".
        // NOTE: we are *not* collapsing, thus no notification is posted.
        if (!itemInfo.isExpandable && itemInfo.isExpanded)
        {
            itemInfo.isExpanded = NO;
            itemInfo.children = [];
        }
    }

    var weight = itemInfo.weight,
        descendants = [anItem];

    if (itemInfo.isExpanded && (shouldReloadData || shouldLoadChildren) &&
        (!(anOutlineView._implementedOutlineViewDataSourceMethods & CPOutlineViewDataSource_outlineView_shouldDeferDisplayingChildrenOfItem_) ||
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

            var childDescendants = _loadItemInfoForItem(anOutlineView, childItem, shouldLoadChildren, itemInfo);

            childItemInfo.parent = anItem;
            childItemInfo.level = level;
            descendants = descendants.concat(childDescendants);
        }
    }

    itemInfo.weight = descendants.length;

    if (shouldReloadData)
    {
        var index = itemInfo.row + 1,
            itemsForRows = anOutlineView._itemsForRows;

        descendants.unshift(index, weight);

        itemsForRows.splice.apply(itemsForRows, descendants);

        var count = itemsForRows.length;

        for (; index < count; ++index)
            if (index > 0)
                itemInfosForItems[[itemsForRows[index] UID]].row = index - 1;

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
        }
    }

    return descendants;
}

@implementation _CPOutlineViewTableViewDataSource : CPObject
{
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
    return _outlineView._itemsForRows.length - 1;
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(CPInteger)aRow
{
    return [_outlineView._outlineViewDataSource outlineView:_outlineView objectValueForTableColumn:aTableColumn byItem:_outlineView._itemsForRows[aRow + 1]];
}

@end

@implementation _CPOutlineViewHierarchicalView : CPView
{
    float   _indentationWidth;
    CPView  _dataView;
}

- (void)updateDataViewFrame
{
    var size = [self bounds].size;

    [_dataView setFrame:_CGRectMake(_indentationWidth, 0.0, size.width - _indentationWidth, size.height)];
}

- (void)setIndentationWidth:(float)aWidth
{
    if (_indentationWidth === aWidth)
        return;

    _indentationWidth = aWidth;

    [self updateDataViewFrame];
}

- (void)setDataView:(CPView)aDataView
{
    if (_dataView === aDataView)
        return;

    [_dataView removeFromSuperview];

    _dataView = aDataView;

    [self updateDataViewFrame];

    [self addSubview:_dataView];
}

- (CPView)dataView
{
    return _dataView;
}

- (void)setObjectValue:(id)anObjectValue
{
    [_dataView setObjectValue:anObjectValue];
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    [self updateDataViewFrame];
}

@end
