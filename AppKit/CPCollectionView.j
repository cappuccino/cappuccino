/*
 * CPCollectionView.j
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

import <Foundation/CPArray.j>
import <Foundation/CPData.j>
import <Foundation/CPIndexSet.j>
import <Foundation/CPKeyedArchiver.j>
import <Foundation/CPKeyedUnarchiver.j>

import <AppKit/CPView.j>


@implementation CPCollectionView : CPView
{
    CPArray                 _content;
    CPArray                 _items;
    
    CPData                  _itemData;
    CPCollectionViewItem    _itemPrototype;
    CPCollectionViewItem    _itemForDragging;
    CPMutableArray          _cachedItems;
    
    unsigned                _maxNumberOfRows;
    unsigned                _maxNumberOfColumns;
    
    CGSize                  _minItemSize;
    CGSize                  _maxItemSize;
    
    float                   _tileWidth;
    
    BOOL                    _isSelectable;
    BOOL                    _allowsMultipleSelection;
    CPIndexSet              _selectionIndexes;
    
    CGSize                  _itemSize;
    
    float                   _horizontalMargin;
    float                   _verticalMargin;
    
    unsigned                _numberOfRows;
    unsigned                _numberOfColumns;
    
    id                      _delegate;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _items = [];
        _content = [];
        
        _cachedItems = [];
        
        _itemSize = CGSizeMakeZero();
        _minItemSize = CGSizeMakeZero();
        _maxItemSize = CGSizeMakeZero();
        
        _verticalMargin = 5.0;
        _tileWidth = -1.0;
        
        _selectionIndexes = [CPIndexSet indexSet];
    }
    
    return self;
}

- (void)setItemPrototype:(CPCollectionViewItem)anItem
{
    _itemData = [CPKeyedArchiver archivedDataWithRootObject:anItem];
    _itemForDragging = anItem//[CPKeyedUnarchiver unarchiveObjectWithData:_itemData];
    
    [self reloadContent];
}

- (CPCollectionViewItem)itemPrototype
{
    return _itemPrototype;
}

- (CPCollectionViewItem)newItemForRepresentedObject:(id)anObject
{
    var item = nil;
    
    if (_cachedItems.length)
        item = _cachedItems.pop();
    else
        item = [CPKeyedUnarchiver unarchiveObjectWithData:_itemData];

    [item setRepresentedObject:anObject];
    [[item view] setFrameSize:_itemSize];

    return item;
}

// Working with the Responder Chain

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)isFirstResponder
{
    return [[self window] firstResponder] == self;
}

// Setting the Content

- (void)setContent:(CPArray)anArray
{
    if (_content == anArray)
        return;
    
    _content = anArray;
    
    [self reloadContent];
}

- (CPArray)content
{
    return _content;
}

- (CPArray)items
{
    return _items;
}

// Setting the Selection Mode

- (void)setSelectable:(BOOL)isSelectable
{
    if (_isSelectable == isSelectable)
        return;
    
    _isSelectable = isSelectable;
    
    if (!_isSelectable)
    {
        var index = CPNotFound;
        
        while ((index = [_selectionIndexes indexGreaterThanIndex:index]) != CPNotFound)
            [_items[index] setSelected:NO];
    }
}

- (BOOL)isSelected
{
    return _isSelected;
}

- (void)setAllowsMultipleSelection:(BOOL)shouldAllowMultipleSelection
{
    _allowsMultipleSelection = shouldAllowsMultipleSelection;
}

- (BOOL)allowsMultipleSelection
{
    return _allowsMultipleSelection;
}

- (void)setSelectionIndexes:(CPIndexSet)anIndexSet
{
    if (_selectionIndexes == anIndexSet)
        return;
    
    var index = CPNotFound;
    
    while ((index = [_selectionIndexes indexGreaterThanIndex:index]) != CPNotFound)
        [_items[index] setSelected:NO];

    _selectionIndexes = anIndexSet;

    var index = CPNotFound;

    while ((index = [_selectionIndexes indexGreaterThanIndex:index]) != CPNotFound)
        [_items[index] setSelected:YES];

    if ([_delegate respondsToSelector:@selector(collectionViewDidChangeSelection:)])
        [_delegate collectionViewDidChangeSelection:self]
}

- (CPIndexSet)selectionIndexes
{
    return _selectionIndexes;
}

- (void)reloadContent
{   
    // Remove current views
    var count = _items.length;
    
    while (count--)
    {
        [[_items[count] view] removeFromSuperview];
        _cachedItems.push(_items[count]);
    }
    
    _items = [];

    if (!_itemData || !_content)
        return;
    
    var index = 0;
    
    count = _content.length;
        
    for (; index < count; ++index)
    {
        _items.push([self newItemForRepresentedObject:_content[index]]);
    
        [self addSubview:[_items[index] view]];
    }
    
    [self tile];
}

- (void)tile
{
    var width = CGRectGetWidth([self bounds]);
        
    if (![_content count] || width == _tileWidth)
        return;
        
    // We try to fit as many views per row as possible.  Any remaining space is then 
    // either proportioned out to the views (if their minSize != maxSize) or used as
    // margin
    var itemSize = CGSizeMakeCopy(_minItemSize);
        
    _numberOfColumns = MAX(1.0, FLOOR(width / itemSize.width));
    
    if (_maxNumberOfColumns > 0)
        _numberOfColumns = MIN(_maxNumberOfColumns, _numberOfColumns);
            
    var remaining = width - _numberOfColumns * itemSize.width,
        itemsNeedSizeUpdate = NO;
        
    if (remaining > 0 && itemSize.width < _maxItemSize.width)
        itemSize.width = MIN(_maxItemSize.width, itemSize.width + FLOOR(remaining / _numberOfColumns));
    
    if (!CGSizeEqualToSize(_itemSize, itemSize))
    {
        _itemSize = itemSize;
        itemsNeedSizeUpdate = YES;
    }
    
    var index = 0,
        count = _items.length;
    
    if (_maxNumberOfColumns > 0 && _maxNumberOfRows > 0)
        count = MIN(count, _maxNumberOfColumns * _maxNumberOfRows);
    
    _numberOfRows = CEIL(count / _numberOfColumns);

    _horizontalMargin = FLOOR((width - _numberOfColumns * itemSize.width) / (_numberOfColumns + 1));
        
    var x = _horizontalMargin,
        y = -itemSize.height;
    
    for (; index < count; ++index)
    {
        if (index % _numberOfColumns == 0)
        {
            x = _horizontalMargin;
            y += _verticalMargin + itemSize.height;
        }
        
        var view = [_items[index] view];
        
        [view setFrameOrigin:CGPointMake(x, y)];
        
        if (itemsNeedSizeUpdate)
            [view setFrameSize:_itemSize];
            
        x += itemSize.width + _horizontalMargin;
    }
    
    _tileWidth = width;
    [self setFrameSize:CGSizeMake(width, y + itemSize.height + _verticalMargin)];
    _tileWidth = -1.0;
}

- (void)resizeSubviewsWithOldSize:(CGSize)aSize
{
    [self tile];
}

// Laying Out the Collection View

- (void)setMaxNumberOfRows:(unsigned)aMaxNumberOfRows
{
    if (_maxNumberOfRows == aMaxNumberOfRows)
        return;
    
    _maxNumberOfRows = aMaxNumberOfRows;
    
    [self tile];
}

- (unsigned)maxNumberOfRows
{
    return _maxNumberOfRows;
}

- (void)setMaxNumberOfColumns:(unsigned)aMaxNumberOfColumns
{
    if (_maxNumberOfColumns == aMaxNumberOfColumns)
        return;
    
    _maxNumberOfColumns = aMaxNumberOfColumns;
    
    [self tile];
}

- (unsigned)maxNumberOfColumns
{
    return _maxNumberOfColumns;
}

- (void)setMinItemSize:(CGSize)aSize
{
    if (CGSizeEqualToSize(_minItemSize, aSize))
        return;
    
    _minItemSize = CGSizeMakeCopy(aSize);
    
    [self tile];
}

- (CGSize)minItemSize
{
    return _minItemSize;
}

- (void)setMaxItemSize:(CGSize)aSize
{
    if (CGSizeEqualToSize(_maxItemSize, aSize))
        return;
    
    _maxItemSize = CGSizeMakeCopy(aSize);
    
    [self tile];
}

- (CGSize)maxItemSize
{
    return _maxItemSize;
}

- (void)mouseUp:(CPEvent)anEvent
{
    if ([_selectionIndexes count] && [anEvent clickCount] == 2 && [_delegate respondsToSelector:@selector(collectionView:didDoubleClickOnItemAtIndex:)])
        [_delegate collectionView:self didDoubleClickOnItemAtIndex:[_selectionIndexes firstIndex]];
}

- (void)mouseDown:(CPEvent)anEvent
{
    var location = [self convertPoint:[anEvent locationInWindow] fromView:nil],
        row = FLOOR(location.y / (_itemSize.height + _verticalMargin)),
        column = FLOOR(location.x / (_itemSize.width + _horizontalMargin)),
        index = row * _numberOfColumns + column;
        
    if (index >= 0 && index < _items.length)
        [self setSelectionIndexes:[CPIndexSet indexSetWithIndex:index]];
}

- (void)mouseDragged:(CPEvent)anEvent
{
    if (![_delegate respondsToSelector:@selector(collectionView:dragTypesForItemsAtIndexes:)])
        return;
        
    // If we don't have any selected items, we've clicked away, and thus the drag is meaningless.
    if (![_selectionIndexes count])
        return;
        
    // Set up the pasteboard
    var dragTypes = [_delegate collectionView:self dragTypesForItemsAtIndexes:_selectionIndexes];
    
    [[CPPasteboard pasteboardWithName:CPDragPboard] declareTypes:dragTypes owner:self];
    
    var point = [self convertPoint:[anEvent locationInWindow] fromView:nil];

    [_itemForDragging setRepresentedObject:_content[[_selectionIndexes firstIndex]]];

    var view = [_itemForDragging view],
        frame = [view frame];
    
    [view setFrameSize:_itemSize];
    
    [self dragView:view
        at:[[_items[[_selectionIndexes firstIndex]] view] frame].origin
        offset:CGPointMakeZero()
        event:anEvent
        pasteboard:nil
        source:self
        slideBack:YES];
}

- (void)pasteboard:(CPPasteboard)aPasteboard provideDataForType:(CPString)aType
{
    [aPasteboard setData:[_delegate collectionView:self dataForItemsAtIndexes:_selectionIndexes forType:aType] forType:aType];
}

// Cappuccino Additions

- (void)setVerticalMargin:(float)aVerticalMargin
{
    if (_verticalMargin == aVerticalMargin)
        return;
    
    _verticalMargin = aVerticalMargin;
    
    [self tile];
}

- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}

- (id)delegate
{
    return _delegate;
}

@end

@implementation CPCollectionViewItem : CPObject
{
    id      _representedObject;
    
    CPView  _view;
    
    BOOL    _isSelected;
}

// Setting the Represented Object

- (void)setRepresentedObject:(id)anObject
{
    if (_representedObject == anObject)
        return;
    
    _representedObject = anObject;
    
    // FIXME: This should be set up by bindings
    [_view setRepresentedObject:anObject];
}

- (id)representedObject
{
    return _representedObject;
}

// Modifying the View

- (void)setView:(CPView)aView
{
    _view = aView;
}

- (CPView)view
{
    return _view;
}

// Modifying the Selection

- (void)setSelected:(BOOL)shouldBeSelected
{
    if (_isSelected == shouldBeSelected)
        return;
    
    _isSelected = shouldBeSelected;
    
    // FIXME: This should be set up by bindings
    [_view setSelected:_isSelected];
}

- (BOOL)isSelected
{
    return _isSelected;
}

// Parent Collection View

- (CPCollectionView)collectionView
{
    return [_view superview];
}

@end

var CPCollectionViewItemViewKey = @"CPCollectionViewItemViewKey";

@implementation CPCollectionViewItem (CPCoding)

- (id)copy
{
    
}

@end

var CPCollectionViewItemViewKey = @"CPCollectionViewItemViewKey";

@implementation CPCollectionViewItem (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
        _view = [aCoder decodeObjectForKey:CPCollectionViewItemViewKey];
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_view forKey:CPCollectionViewItemViewKey];
}

@end
