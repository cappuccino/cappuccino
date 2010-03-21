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

@import <Foundation/CPArray.j>
@import <Foundation/CPData.j>
@import <Foundation/CPIndexSet.j>
@import <Foundation/CPKeyedArchiver.j>
@import <Foundation/CPKeyedUnarchiver.j>

@import "CPView.j"
@import "CPCollectionViewItem.j"


/*! 
    @ingroup appkit
    @class CPCollectionView

    This class displays an array as a grid of objects, where each object is represented by a view. 
    The view is controlled by creating a CPCollectionViewItem and specifying its view, then 
    setting that item as the collection view prototype.
    
    @par Delegate Methods
    
    @delegate -(void)collectionViewDidChangeSelection:(CPCollectionView)collectionView;
    Called when the selection in the collection view has changed.
    @param collectionView the collection view who's selection changed

    @delegate -(void)collectionView:(CPCollectionView)collectionView didDoubleClickOnItemAtIndex:(int)index;
    Called when the user double-clicks on an item in the collection view.
    @param collectionView the collection view that received the double-click
    @param index the index of the item that received the double-click

    @delegate -(CPData)collectionView:(CPCollectionView)collectionView dataForItemsAtIndexes:(CPIndexSet)indices forType:(CPString)aType;
    Invoked to obtain data for a set of indices.
    @param collectionView the collection view to obtain data for
    @param indices the indices to return data for
    @param aType the data type
    @return a data object containing the index items

    @delegate -(CPArray)collectionView:(CPCollectionView)collectionView dragTypesForItemsAtIndexes:(CPIndexSet)indices;
    Invoked to obtain the data types supported by the specified indices for placement on the pasteboard.
    @param collectionView the collection view the items reside in
    @param indices the indices to obtain drag types
    @return an array of drag types (CPString)
*/

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

    CPArray                 _backgroundColors;

    float                   _tileWidth;
    
    BOOL                    _isSelectable;
    BOOL                    _allowsMultipleSelection;
    BOOL                    _allowsEmptySelection;
    CPIndexSet              _selectionIndexes;
    
    CGSize                  _itemSize;
    
    float                   _horizontalMargin;
    float                   _verticalMargin;
    
    unsigned                _numberOfRows;
    unsigned                _numberOfColumns;
    
    id                      _delegate;

    CPEvent                 _mouseDownEvent;
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

        [self setBackgroundColors:nil];

        _verticalMargin = 5.0;
        _tileWidth = -1.0;
        
        _selectionIndexes = [CPIndexSet indexSet];
        _allowsEmptySelection = YES;
        _isSelectable = YES;
    }
    
    return self;
}

/*!
    Sets the item prototype to \c anItem
    @param anItem the new item prototype
*/
- (void)setItemPrototype:(CPCollectionViewItem)anItem
{
    _cachedItems = [];
    _itemData = nil;
    _itemForDragging = nil;
    _itemPrototype = anItem;

    [self reloadContent];
}

/*!
    Returns the current item prototype
*/
- (CPCollectionViewItem)itemPrototype
{
    return _itemPrototype;
}

/*!
    Returns a collection view item for \c anObject.
    @param anObject the object to be represented.
*/
- (CPCollectionViewItem)newItemForRepresentedObject:(id)anObject
{
    var item = nil;

    if (_cachedItems.length)
        item = _cachedItems.pop();

    else
    {
        if (!_itemData)
            if (_itemPrototype)
                _itemData = [CPKeyedArchiver archivedDataWithRootObject:_itemPrototype];

        item = [CPKeyedUnarchiver unarchiveObjectWithData:_itemData];
    }

    [item setRepresentedObject:anObject];
    [[item view] setFrameSize:_itemSize];

    return item;
}

// Working with the Responder Chain
/*!
    Returns \c YES by default.
*/
- (BOOL)acceptsFirstResponder
{
    return YES;
}

/*!
    Returns whether the receiver is currently the first responder.
*/
- (BOOL)isFirstResponder
{
    return [[self window] firstResponder] === self;
}

// Setting the Content
/*!
    Sets the content of the collection view to the content in \c anArray. 
    This array can be of any type, and each element will be passed to the \c -setRepresentedObject: method.  
    It's the responsibility of your custom collection view item to interpret the object.
    @param anArray the content array
*/
- (void)setContent:(CPArray)anArray
{
    if (_content == anArray)
        return;
    
    _content = anArray;
    
    [self reloadContent];
}

/*!
    Returns the collection view content array
*/
- (CPArray)content
{
    return _content;
}

/*!
    Returns the collection view items.
*/
- (CPArray)items
{
    return _items;
}

// Setting the Selection Mode
/*!
    Sets whether the user is allowed to select items
    @param isSelectable \c YES allows the user to select items.
*/
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

/*!
    Returns \c YES if the collection view is
    selectable, and \c NO otherwise.
*/
- (BOOL)isSelectable
{
    return _isSelectable;
}

/*!
    Sets whether the user may have no items selected. If YES, mouse clicks not on any item will empty the current selection. The first item will also start off as selected.
    @param shouldAllowMultipleSelection \c YES allows the user to select multiple items
*/
- (void)setAllowsEmptySelection:(BOOL)shouldAllowEmptySelection
{
    _allowsEmptySelection = shouldAllowEmptySelection;
}

/*!
    Returns \c YES if the user can select no items, \c NO otherwise.
*/
- (BOOL)allowsEmptySelection
{
    return _allowsEmptySelection;
}

/*!
    Sets whether the user can select multiple items.
    @param shouldAllowMultipleSelection \c YES allows the user to select multiple items
*/
- (void)setAllowsMultipleSelection:(BOOL)shouldAllowMultipleSelection
{
    _allowsMultipleSelection = shouldAllowMultipleSelection;
}

/*!
    Returns \c YES if the user can select multiple items, \c NO otherwise.
*/
- (BOOL)allowsMultipleSelection
{
    return _allowsMultipleSelection;
}

/*!
    Sets the selected items based on the provided indices.
    @param anIndexSet the set of items to be selected
*/
- (void)setSelectionIndexes:(CPIndexSet)anIndexSet
{
    if (_selectionIndexes == anIndexSet || !_isSelectable)
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

/*!
    Returns a set of the selected indices.
*/
- (CPIndexSet)selectionIndexes
{
    return [_selectionIndexes copy];
}

/* @ignore */
- (void)reloadContent
{   
    // Remove current views
    var count = _items.length;
    
    while (count--)
    {
        [[_items[count] view] removeFromSuperview];
        [_items[count] setSelected:NO];

        _cachedItems.push(_items[count]);
    }
    
    _items = [];

    if (!_itemPrototype || !_content)
        return;

    var index = 0;

    count = _content.length;

    for (; index < count; ++index)
    {
        _items.push([self newItemForRepresentedObject:_content[index]]);
    
        [self addSubview:[_items[index] view]];
    }

    index = CPNotFound;
    while ((index = [_selectionIndexes indexGreaterThanIndex:index]) != CPNotFound)
        [_items[index] setSelected:YES];

    [self tile];
}

/* @ignore */
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
    
    // When we ONE column and a non-integral width, the FLOORing above can cause the item width to be smaller than the total width.
    if (_maxNumberOfColumns == 1 && itemSize.width < _maxItemSize.width && itemSize.width < width)
        itemSize.width = MIN(_maxItemSize.width, width);
    
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
/*!
    Sets the maximum number of rows.
    @param aMaxNumberOfRows the new maximum number of rows
*/
- (void)setMaxNumberOfRows:(unsigned)aMaxNumberOfRows
{
    if (_maxNumberOfRows == aMaxNumberOfRows)
        return;
    
    _maxNumberOfRows = aMaxNumberOfRows;
    
    [self tile];
}

/*!
    Returns the maximum number of rows.
*/
- (unsigned)maxNumberOfRows
{
    return _maxNumberOfRows;
}

/*!
    Sets the maximum number of columns.
    @param aMaxNumberOfColumns the new maximum number of columns
*/
- (void)setMaxNumberOfColumns:(unsigned)aMaxNumberOfColumns
{
    if (_maxNumberOfColumns == aMaxNumberOfColumns)
        return;
    
    _maxNumberOfColumns = aMaxNumberOfColumns;
    
    [self tile];
}

/*!
    Returns the maximum number of columns
*/
- (unsigned)maxNumberOfColumns
{
    return _maxNumberOfColumns;
}

/*!
    Returns the current number of rows
*/
- (unsigned)numberOfRows
{
    return _numberOfRows;
}

/*!
    Returns the current number of columns
*/

- (unsigned)numberOfColumns
{
    return _numberOfColumns;
}

/*!
    Sets the minimum size for an item
    @param aSize the new minimum item size
*/
- (void)setMinItemSize:(CGSize)aSize
{
    if (CGSizeEqualToSize(_minItemSize, aSize))
        return;
    
    _minItemSize = CGSizeMakeCopy(aSize);
    
    [self tile];
}

/*!
    Returns the current minimum item size
*/
- (CGSize)minItemSize
{
    return _minItemSize;
}

/*!
    Sets the maximum item size.
    @param aSize the new maximum item size
*/
- (void)setMaxItemSize:(CGSize)aSize
{
    if (CGSizeEqualToSize(_maxItemSize, aSize))
        return;
    
    _maxItemSize = CGSizeMakeCopy(aSize);
    
    [self tile];
}

/*!
    Returns the current maximum item size.
*/
- (CGSize)maxItemSize
{
    return _maxItemSize;
}

- (void)setBackgroundColors:(CPArray)backgroundColors
{
    if (_backgroundColors === backgroundColors)
        return;

    _backgroundColors = backgroundColors;

    if (!_backgroundColors)
        _backgroundColors = [CPColor whiteColor];

    if ([_backgroundColors count] === 1)
        [self setBackgroundColor:_backgroundColors[0]];

    else
        [self setBackgroundColor:nil];

    [self setNeedsDisplay:YES];
}

- (CPArray)backgroundColors
{
    return _backgroundColors;
}

- (void)mouseUp:(CPEvent)anEvent
{
    if ([_selectionIndexes count] && [anEvent clickCount] == 2 && [_delegate respondsToSelector:@selector(collectionView:didDoubleClickOnItemAtIndex:)])
        [_delegate collectionView:self didDoubleClickOnItemAtIndex:[_selectionIndexes firstIndex]];
}

- (void)mouseDown:(CPEvent)anEvent
{
    _mouseDownEvent = anEvent;

    var location = [self convertPoint:[anEvent locationInWindow] fromView:nil],
        row = FLOOR(location.y / (_itemSize.height + _verticalMargin)),
        column = FLOOR(location.x / (_itemSize.width + _horizontalMargin)),
        index = row * _numberOfColumns + column;

    if (index >= 0 && index < _items.length)
        [self setSelectionIndexes:[CPIndexSet indexSetWithIndex:index]];

    else if (_allowsEmptySelection)
        [self setSelectionIndexes:[CPIndexSet indexSet]];
}

- (void)mouseDragged:(CPEvent)anEvent
{
    if (![_delegate respondsToSelector:@selector(collectionView:dragTypesForItemsAtIndexes:)])
        return;

    // If we don't have any selected items, we've clicked away, and thus the drag is meaningless.
    if (![_selectionIndexes count])
        return;

    if ([_delegate respondsToSelector:@selector(collectionView:canDragItemsAtIndexes:withEvent:)] &&
        ![_delegate collectionView:self canDragItemsAtIndexes:_selectionIndexes withEvent:_mouseDownEvent])
        return;

    // Set up the pasteboard
    var dragTypes = [_delegate collectionView:self dragTypesForItemsAtIndexes:_selectionIndexes];

    [[CPPasteboard pasteboardWithName:CPDragPboard] declareTypes:dragTypes owner:self];

    var point = [self convertPoint:[anEvent locationInWindow] fromView:nil];

    if (!_itemForDragging)
        _itemForDragging = [self newItemForRepresentedObject:_content[[_selectionIndexes firstIndex]]];
    else
        [_itemForDragging setRepresentedObject:_content[[_selectionIndexes firstIndex]]];

    var view = [_itemForDragging view];

    [view setFrameSize:_itemSize];
    [view setAlphaValue:0.7];

    [self dragView:view
        at:[[_items[[_selectionIndexes firstIndex]] view] frame].origin
        offset:CGSizeMakeZero()
        event:_mouseDownEvent
        pasteboard:nil
        source:self
        slideBack:YES];
}

/*!
    Places the selected items on the specified pasteboard. The items are requested from the collection's delegate.
    @param aPasteboard the pasteboard to put the items on
    @param aType the format the pasteboard data
*/
- (void)pasteboard:(CPPasteboard)aPasteboard provideDataForType:(CPString)aType
{
    [aPasteboard setData:[_delegate collectionView:self dataForItemsAtIndexes:_selectionIndexes forType:aType] forType:aType];
}

// Cappuccino Additions

/*!
    Sets the collection view's vertical spacing between elements.
    @param aVerticalMargin the number of pixels to place between elements
*/

- (void)setVerticalMargin:(float)aVerticalMargin
{
    if (_verticalMargin == aVerticalMargin)
        return;
    
    _verticalMargin = aVerticalMargin;
    
    [self tile];
}

/*!
    Gets the collection view's current vertical spacing between elements.
*/

- (float)verticalMargin
{
    return _verticalMargin;
}

/*!
    Sets the collection view's delegate
    @param aDelegate the new delegate
*/
- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}

/*!
    Returns the collection view's delegate
*/
- (id)delegate
{
    return _delegate;
}

- (CPCollectionViewItem)itemAtIndex:(unsigned)anIndex
{
    return [_items objectAtIndex:anIndex];
}

- (CGRect)frameForItemAtIndex:(unsigned)anIndex
{
    return [[[self itemAtIndex:anIndex] view] frame];
}

- (CGRect)frameForItemsAtIndexes:(CPIndexSet)anIndexSet
{
    var indexArray = [],
        frame = CGRectNull;

    [anIndexSet getIndexes:indexArray maxCount:-1 inIndexRange:nil];

    var index = 0,
        count = [indexArray count];

    for (; index < count; ++index)
        frame = CGRectUnion(frame, [self rectForItemAtIndex:indexArray[index]]);

    return frame;
}

@end

@implementation CPCollectionView (KeyboardInteraction)

- (void)_scrollToSelection
{
    var frame = [self frameForItemsAtIndexes:[self selectionIndexes]];

    if (!CGRectIsNull(frame))
        [self scrollRectToVisible:frame];
}

- (void)moveLeft:(id)sender
{
    var index = [[self selectionIndexes] firstIndex];
    if (index === CPNotFound) 
        index = [[self items] count];

    index = MAX(index - 1, 0);

    [self setSelectionIndexes:[CPIndexSet indexSetWithIndex:index]];
    [self _scrollToSelection];
}

- (void)moveRight:(id)sender
{
    var index = MIN([[self selectionIndexes] firstIndex] + 1, [[self items] count]-1);

    [self setSelectionIndexes:[CPIndexSet indexSetWithIndex:index]];
    [self _scrollToSelection];
}

- (void)moveDown:(id)sender
{
    var index = MIN([[self selectionIndexes] firstIndex] + [self numberOfColumns], [[self items] count]-1);

    [self setSelectionIndexes:[CPIndexSet indexSetWithIndex:index]];
    [self _scrollToSelection];
}

- (void)moveUp:(id)sender
{
    var index = [[self selectionIndexes] firstIndex];
    if (index == CPNotFound) 
        index = [[self items] count];

    index = MAX(0, index - [self numberOfColumns]);

    [self setSelectionIndexes:[CPIndexSet indexSetWithIndex:index]];
    [self _scrollToSelection];
}

- (void)deleteBackwards:(id)sender
{
    if ([[self delegate] respondsToSelector:@selector(collectionView:shouldDeleteItemsAtIndexes:)])
    {
        [[self delegate] collectionView:self shouldDeleteItemsAtIndexes:[self selectionIndexes]];

        var index = [[self selectionIndexes] firstIndex];
        if (index > [[self content] count]-1)
            [self setSelectionIndexes:[CPIndexSet indexSetWithIndex:[[self content] count]-1]];

        [self _scrollToSelection];
        [self setNeedsDisplay:YES];
    }
}

- (void)keyDown:(CPEvent)anEvent
{
    [self interpretKeyEvents:[anEvent]];
}

@end

@implementation CPCollectionView (Deprecated)

- (CGRect)rectForItemAtIndex:(int)anIndex
{
    _CPReportLenientDeprecation([self class], _cmd, @selector(frameForItemAtIndex:));

    // Don't re-compute anything just grab the current frame
    // This allows subclasses to override tile without messing this up.
    return [self frameForItemAtIndex:anIndex];
}

- (CGRect)rectForItemsAtIndexes:(CPIndexSet)anIndexSet
{
    _CPReportLenientDeprecation([self class], _cmd, @selector(frameForItemsAtIndexes:));

    return [self frameForItemsAtIndexes:anIndexSet];
}

@end

var CPCollectionViewMinItemSizeKey      = @"CPCollectionViewMinItemSizeKey",
    CPCollectionViewMaxItemSizeKey      = @"CPCollectionViewMaxItemSizeKey",
    CPCollectionViewVerticalMarginKey   = @"CPCollectionViewVerticalMarginKey",
    CPCollectionViewSelectableKey       = @"CPCollectionViewSelectableKey",
    CPCollectionViewBackgroundColorsKey = @"CPCollectionViewBackgroundColorsKey";


@implementation CPCollectionView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _items = [];
        _content = [];

        _cachedItems = [];

        _itemSize = CGSizeMakeZero();
        
        _minItemSize = [aCoder decodeSizeForKey:CPCollectionViewMinItemSizeKey] || CGSizeMakeZero();
        _maxItemSize = [aCoder decodeSizeForKey:CPCollectionViewMaxItemSizeKey] || CGSizeMakeZero();
        
        _verticalMargin = [aCoder decodeFloatForKey:CPCollectionViewVerticalMarginKey];
        
        _isSelectable = [aCoder decodeBoolForKey:CPCollectionViewSelectableKey];

        [self setBackgroundColors:[aCoder decodeObjectForKey:CPCollectionViewBackgroundColorsKey]];
          
        _tileWidth = -1.0;

        _selectionIndexes = [CPIndexSet indexSet];
        
        _allowsEmptySelection = YES;
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    if (!CGSizeEqualToSize(_minItemSize, CGSizeMakeZero()))
      [aCoder encodeSize:_minItemSize forKey:CPCollectionViewMinItemSizeKey];
    
    if (!CGSizeEqualToSize(_maxItemSize, CGSizeMakeZero()))
      [aCoder encodeSize:_maxItemSize forKey:CPCollectionViewMaxItemSizeKey];
    
    [aCoder encodeBool:_isSelectable forKey:CPCollectionViewSelectableKey];
    
    [aCoder encodeFloat:_verticalMargin forKey:CPCollectionViewVerticalMarginKey];

    [aCoder encodeObject:_backgroundColors forKey:CPCollectionViewBackgroundColorsKey];
}

@end
