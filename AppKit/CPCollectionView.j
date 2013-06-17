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

@import "CPCollectionViewItem.j"
@import "CPCompatibility.j"
@import "CPDragServer_Constants.j"
@import "CPPasteboard.j"
@import "CPView.j"

/*!
    @ingroup appkit
    @class CPCollectionView

    This class displays an array as a grid of objects, where each object is represented by a view.
    The view is controlled by creating a CPCollectionViewItem and specifying its view, then
    setting that item as the collection view prototype.

    @par Delegate Methods

    @delegate - (void)collectionViewDidChangeSelection:(CPCollectionView)collectionView;
    DEPRECATED: Please do not use.
    @param collectionView the collection view who's selection changed

    @delegate - (void)collectionView:(CPCollectionView)collectionView didDoubleClickOnItemAtIndex:(int)index;
    Called when the user double-clicks on an item in the collection view.
    @param collectionView the collection view that received the double-click
    @param index the index of the item that received the double-click

    @delegate - (CPData)collectionView:(CPCollectionView)collectionView dataForItemsAtIndexes:(CPIndexSet)indices forType:(CPString)aType;
    Invoked to obtain data for a set of indices.
    @param collectionView the collection view to obtain data for
    @param indices the indices to return data for
    @param aType the data type
    @return a data object containing the index items

    @delegate - (CPArray)collectionView:(CPCollectionView)collectionView dragTypesForItemsAtIndexes:(CPIndexSet)indices;
    Invoked to obtain the data types supported by the specified indices for placement on the pasteboard.
    @param collectionView the collection view the items reside in
    @param indices the indices to obtain drag types
    @return an array of drag types (CPString)
*/

var HORIZONTAL_MARGIN = 2;

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

    BOOL                    _needsMinMaxItemSizeUpdate;
    CGSize                  _storedFrameSize;

    BOOL                    _uniformSubviewsResizing @accessors(property=uniformSubviewsResizing);
    BOOL                    _lockResizing;

    CPInteger               _currentDropIndex;
    CPDragOperation         _currentDragOperation;

    _CPCollectionViewDropIndicator _dropView;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _maxNumberOfRows = 0;
        _maxNumberOfColumns = 0;

        _minItemSize = CGSizeMakeZero();
        _maxItemSize = CGSizeMakeZero();

        [self setBackgroundColors:nil];

        _verticalMargin = 5.0;
        _isSelectable = YES;
        _allowsEmptySelection = YES;

        [self _init];
    }

    return self;
}

- (void)_init
{
    _content = [];

    _items = [];
    _cachedItems = [];

    _numberOfColumns = CPNotFound;
    _numberOfRows = CPNotFound;

    _itemSize = CGSizeMakeZero();

    _selectionIndexes = [CPIndexSet indexSet];

    _storedFrameSize = CGSizeMakeZero();

    _needsMinMaxItemSizeUpdate = YES;
    _uniformSubviewsResizing = NO;
    _lockResizing = NO;

    _currentDropIndex      = -1;
    _currentDragOperation  = CPDragOperationNone;
    _dropView = nil;

    [self setAutoresizesSubviews:NO];
    [self setAutoresizingMask:0];
}

/*!
    Sets the item prototype to \c anItem
    @param anItem the new item prototype.

    @note
    - If anItem is located in an external cib file, representedObject, outlets, and bindings will be automatically restored when an item is created.
    - If anItem and its view belong to the same cib as the collection view, the item prototype should implement the CPCoding protocol because the item is copied by archiving and unarchiving the prototypal view.
    @note
        Bindings won't be restored through archiving, instead you need to subclass the -representedObject: method and update the view there.

    @par Example:

@code
@implementation MyCustomPrototypeItem: CPCollectionViewItem
{
    @outlet CPTextField textField;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    textField = [aCoder decodeObjectForKey:@"TextField"];

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeConditionalObject:textField forKey:@"TextField"];
}

- (void)setRepresentedObject:(id)anObject
{
    [super setRepresentedObject:anObject];
    [textField setStringValue:[anObject objectForKey:@"value"]];
    [[self view] setColor:[anObject objectForKey:@"color"]];
}

@end
@endcode

*/
- (void)setItemPrototype:(CPCollectionViewItem)anItem
{
    _cachedItems = [];
    _itemData = nil;
    _itemForDragging = nil;
    _itemPrototype = anItem;

    [self _reloadContentCachingRemovedItems:NO];
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
        item = [_itemPrototype copy];

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

    If the new content array is smaller than the previous one, note that [receiver selectionIndexes] may
    refer to out of range indices. \c selectionIndexes is not changed as a result of calling the
    \c setContent: method.

    @param anArray a content array
*/
- (void)setContent:(CPArray)anArray
{
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
        var index = CPNotFound,
            itemCount = [_items count];

        // Be wary of invalid selection ranges since setContent: does not clear selection indexes.
        while ((index = [_selectionIndexes indexGreaterThanIndex:index]) != CPNotFound && index < itemCount)
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
    if (!anIndexSet)
        anIndexSet = [CPIndexSet indexSet];
    if (!_isSelectable || [_selectionIndexes isEqual:anIndexSet])
        return;

    var index = CPNotFound,
        itemCount = [_items count];

    // Be wary of invalid selection ranges since setContent: does not clear selection indexes.
    while ((index = [_selectionIndexes indexGreaterThanIndex:index]) !== CPNotFound && index < itemCount)
        [_items[index] setSelected:NO];

    _selectionIndexes = anIndexSet;

    var index = CPNotFound;

    while ((index = [_selectionIndexes indexGreaterThanIndex:index]) !== CPNotFound)
        [_items[index] setSelected:YES];

    var binderClass = [[self class] _binderClassForBinding:@"selectionIndexes"];
    [[binderClass getBinding:@"selectionIndexes" forObject:self] reverseSetValueFor:@"selectionIndexes"];

    if ([_delegate respondsToSelector:@selector(collectionViewDidChangeSelection:)])
    {
        CPLog.warn("The delegate method collectionViewDidChangeSelection: is deprecated and will be removed in a future version, please bind to selectionIndexes instead.");
        [_delegate collectionViewDidChangeSelection:self];
    }
}

/*!
    Returns a set of the selected indices.
*/
- (CPIndexSet)selectionIndexes
{
    return [_selectionIndexes copy];
}

- (void)reloadContent
{
    [self _reloadContentCachingRemovedItems:YES];
}

/* @ignore */
- (void)_reloadContentCachingRemovedItems:(BOOL)shouldCache
{
    // Remove current views
    var count = _items.length;

    while (count--)
    {
        [[_items[count] view] removeFromSuperview];
        [_items[count] setSelected:NO];

        if (shouldCache)
            _cachedItems.push(_items[count]);
    }

    _items = [];

    if (!_itemPrototype)
        return;

    var index = 0;

    count = _content.length;

    for (; index < count; ++index)
    {
        _items.push([self newItemForRepresentedObject:_content[index]]);

        [self addSubview:[_items[index] view]];
    }

    index = CPNotFound;
    // Be wary of invalid selection ranges since setContent: does not clear selection indexes.
    while ((index = [_selectionIndexes indexGreaterThanIndex:index]) != CPNotFound && index < count)
        [_items[index] setSelected:YES];

    [self tileIfNeeded:NO];
}

- (void)resizeSubviewsWithOldSize:(CGSize)oldBoundsSize
{
    // Desactivate subviews autoresizing
}

- (void)resizeWithOldSuperviewSize:(CGSize)oldBoundsSize
{
    if (_lockResizing)
        return;

    _lockResizing = YES;

    [self tile];

    _lockResizing = NO;
}

- (void)tile
{
    [self tileIfNeeded:!_uniformSubviewsResizing];
}

- (void)tileIfNeeded:(BOOL)lazyFlag
{
    var frameSize           = [[self superview] frameSize],
        count               = _items.length,
        oldNumberOfColumns  = _numberOfColumns,
        oldNumberOfRows     = _numberOfRows,
        oldItemSize         = _itemSize,
        storedFrameSize     = _storedFrameSize;

    // No need to tile if we are not yet placed in the view hierarchy.
    if (!frameSize)
        return;

    [self _updateMinMaxItemSizeIfNeeded];

    [self _computeGridWithSize:frameSize count:@ref(count)];

    //CPLog.debug("frameSize="+CPStringFromSize(frameSize) + "itemSize="+CPStringFromSize(itemSize) + " ncols=" +  colsRowsCount[0] +" nrows="+ colsRowsCount[1]+" displayCount="+ colsRowsCount[2]);

    [self setFrameSize:_storedFrameSize];

    //CPLog.debug("OLD " + oldNumberOfColumns + " NEW " + _numberOfColumns);
    if (!lazyFlag ||
        _numberOfColumns !== oldNumberOfColumns ||
        _numberOfRows    !== oldNumberOfRows ||
        !CGSizeEqualToSize(_itemSize, oldItemSize))

        [self displayItems:_items frameSize:_storedFrameSize itemSize:_itemSize columns:_numberOfColumns rows:_numberOfRows count:count];
}

- (void)_computeGridWithSize:(CGSize)aSuperviewSize count:(Function)countRef
{
    var width               = aSuperviewSize.width,
        height              = aSuperviewSize.height,
        itemSize            = CGSizeMakeCopy(_minItemSize),
        maxItemSizeWidth    = _maxItemSize.width,
        maxItemSizeHeight   = _maxItemSize.height,
        itemsCount          = [_items count],
        numberOfRows,
        numberOfColumns;

    numberOfColumns = FLOOR(width / itemSize.width);

    if (maxItemSizeWidth == 0)
        numberOfColumns = MIN(numberOfColumns, _maxNumberOfColumns);

    if (_maxNumberOfColumns > 0)
        numberOfColumns = MIN(MIN(_maxNumberOfColumns, itemsCount), numberOfColumns);

    numberOfColumns = MAX(1.0, numberOfColumns);

    itemSize.width = FLOOR(width / numberOfColumns);

    if (maxItemSizeWidth > 0)
    {
        itemSize.width = MIN(maxItemSizeWidth, itemSize.width);

        if (numberOfColumns == 1)
            itemSize.width = MIN(maxItemSizeWidth, width);
    }

    numberOfRows = CEIL(itemsCount / numberOfColumns);

    if (_maxNumberOfRows > 0)
        numberOfRows = MIN(numberOfRows, _maxNumberOfRows);

    height = MAX(height, numberOfRows * (_minItemSize.height + _verticalMargin));

    var itemSizeHeight = FLOOR(height / numberOfRows);

    if (maxItemSizeHeight > 0)
        itemSizeHeight = MIN(itemSizeHeight, maxItemSizeHeight);

    _itemSize        = CGSizeMake(MAX(_minItemSize.width, itemSize.width), MAX(_minItemSize.height, itemSizeHeight));
    _storedFrameSize = CGSizeMake(MAX(width, _minItemSize.width), height);
    _numberOfColumns = numberOfColumns;
    _numberOfRows    = numberOfRows;
    countRef(MIN(itemsCount, numberOfColumns * numberOfRows));
}

- (void)displayItems:(CPArray)displayItems frameSize:(CGSize)aFrameSize itemSize:(CGSize)anItemSize columns:(CPInteger)numberOfColumns rows:(CPInteger)numberOfRows count:(CPInteger)displayCount
{
//    CPLog.debug("DISPLAY ITEMS " + numberOfColumns + " " +  numberOfRows);

    _horizontalMargin = _uniformSubviewsResizing ? FLOOR((aFrameSize.width - numberOfColumns * anItemSize.width) / (numberOfColumns + 1)) : HORIZONTAL_MARGIN;

    var x = _horizontalMargin,
        y = -anItemSize.height;

    [displayItems enumerateObjectsUsingBlock:function(item, idx, stop)
    {
        var view = [item view];

        if (idx >= displayCount)
        {
            [view setFrameOrigin:CGPointMake(-anItemSize.width, -anItemSize.height)];
            return;
        }

        if (idx % numberOfColumns == 0)
        {
            x = _horizontalMargin;
            y += _verticalMargin + anItemSize.height;
        }

        [view setFrameOrigin:CGPointMake(x, y)];
        [view setFrameSize:anItemSize];

        x += anItemSize.width + _horizontalMargin;
    }];
}

- (void)_updateMinMaxItemSizeIfNeeded
{
    if (!_needsMinMaxItemSizeUpdate)
        return;

    var prototypeView;

    if (_itemPrototype && (prototypeView = [_itemPrototype view]))
    {
        if (_minItemSize.width == 0)
            _minItemSize.width = [prototypeView frameSize].width;

        if (_minItemSize.height == 0)
            _minItemSize.height = [prototypeView frameSize].height;

        if (_maxItemSize.height == 0 && !([prototypeView autoresizingMask] & CPViewHeightSizable))
            _maxItemSize.height = [prototypeView frameSize].height;

        if (_maxItemSize.width == 0 && !([prototypeView autoresizingMask] & CPViewWidthSizable))
            _maxItemSize.width = [prototypeView frameSize].width;

        _needsMinMaxItemSizeUpdate = NO;
    }
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
    if (aSize === nil || aSize === undefined)
        [CPException raise:CPInvalidArgumentException reason:"Invalid value provided for minimum size"];

    if (CGSizeEqualToSize(_minItemSize, aSize))
        return;

    _minItemSize = CGSizeMakeCopy(aSize);

    if (CGSizeEqualToSize(_minItemSize, CGSizeMakeZero()))
        _needsMinMaxItemSizeUpdate = YES;

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

//    if (_maxItemSize.width == 0 || _maxItemSize.height == 0)
//        _needsMinMaxItemSizeUpdate = YES;

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
        _backgroundColors = [[CPColor whiteColor]];

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
        index = [self _indexAtPoint:location];

    if (index >= 0 && index < _items.length)
    {
        if (_allowsMultipleSelection && ([anEvent modifierFlags] & CPPlatformActionKeyMask || [anEvent modifierFlags] & CPShiftKeyMask))
        {
            if ([anEvent modifierFlags] & CPPlatformActionKeyMask)
            {
                var indexes = [_selectionIndexes copy];

                if ([indexes containsIndex:index])
                    [indexes removeIndex:index];
                else
                    [indexes addIndex:index];
            }
            else if ([anEvent modifierFlags] & CPShiftKeyMask)
            {
                var firstSelectedIndex = [[self selectionIndexes] firstIndex],
                    newSelectedRange = nil;

                // This catches the case where the shift key is held down for the first selection.
                if (firstSelectedIndex === CPNotFound)
                    firstSelectedIndex = index;

                if (index < firstSelectedIndex)
                    newSelectedRange = CPMakeRange(index, (firstSelectedIndex - index) + 1);
                else
                    newSelectedRange = CPMakeRange(firstSelectedIndex, (index - firstSelectedIndex) + 1);

                indexes = [[self selectionIndexes] copy];
                [indexes addIndexesInRange:newSelectedRange];
            }
        }
        else
            indexes = [CPIndexSet indexSetWithIndex:index];

        [self setSelectionIndexes:indexes];

        // TODO Is it allowable for collection view items to become the first responder? In that case they
        // may have become that at this point by virtue of CPWindow's sendEvent: mouse down handling, and
        // the following line will rudely snatch it away from them. For most cases though, clicking on an
        // item should naturally make the collection view the first responder so that keyboard navigation
        // is enabled.
        [[self window] makeFirstResponder:self];
    }
    else if (_allowsEmptySelection)
        [self setSelectionIndexes:[CPIndexSet indexSet]];
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

- (void)setUniformSubviewsResizing:(float)flag
{
    _uniformSubviewsResizing = flag;
    [self tileIfNeeded:NO];
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

/*!
    @ignore
*/
- (CPMenu)menuForEvent:(CPEvent)theEvent
{
    if (![[self delegate] respondsToSelector:@selector(collectionView:menuForItemAtIndex:)])
        return [super menuForEvent:theEvent];

    var location = [self convertPoint:[theEvent locationInWindow] fromView:nil],
        index = [self _indexAtPoint:location];

    return [_delegate collectionView:self menuForItemAtIndex:index];
}

- (int)_indexAtPoint:(CGPoint)thePoint
{
    var column = FLOOR(thePoint.x / (_itemSize.width + _horizontalMargin));

    if (column < _numberOfColumns)
    {
        var row = FLOOR(thePoint.y / (_itemSize.height + _verticalMargin));

        if (row < _numberOfRows)
            return (row * _numberOfColumns + column);
    }

    return CPNotFound;
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
        frame = CGRectUnion(frame, [self frameForItemAtIndex:indexArray[index]]);

    return frame;
}

@end

@implementation CPCollectionView (DragAndDrop)
/*
    TODO: dropOperation is not supported yet. The visible drop operation is like CPCollectionViewDropBefore.
*/

/*!
    Places the selected items on the specified pasteboard. The items are requested from the collection's delegate.
    @param aPasteboard the pasteboard to put the items on
    @param aType the format the pasteboard data
*/
- (void)pasteboard:(CPPasteboard)aPasteboard provideDataForType:(CPString)aType
{
    [aPasteboard setData:[_delegate collectionView:self dataForItemsAtIndexes:_selectionIndexes forType:aType] forType:aType];
}

- (void)_createDropIndicatorIfNeeded
{
    // Create and position the drop indicator view.

    if (!_dropView)
        _dropView = [[_CPCollectionViewDropIndicator alloc] initWithFrame:CGRectMake(-8, -8, 0, 0)];

    [_dropView setFrameSize:CGSizeMake(10, _itemSize.height + _verticalMargin)];
    [self addSubview:_dropView];
}

- (void)mouseDragged:(CPEvent)anEvent
{
    // Don't crash if we never registered the intial click.
    if (!_mouseDownEvent)
        return;

    [self _createDropIndicatorIfNeeded];

    var locationInWindow = [anEvent locationInWindow],
        mouseDownLocationInWindow = [_mouseDownEvent locationInWindow];

    // FIXME: This is because Safari's drag hysteresis is 3px x 3px
    if ((ABS(locationInWindow.x - mouseDownLocationInWindow.x) < 3) &&
        (ABS(locationInWindow.y - mouseDownLocationInWindow.y) < 3))
        return;

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

    var dragImageOffset = CGSizeMakeZero(),
        view = [self _draggingViewForItemsAtIndexes:_selectionIndexes withEvent:_mouseDownEvent offset:dragImageOffset];

    [view setFrameSize:_itemSize];
    [view setAlphaValue:0.7];

    var dragLocation = [self convertPoint:locationInWindow fromView:nil],
        dragPoint = CGPointMake(dragLocation.x - _itemSize.width / 2 , dragLocation.y - _itemSize.height / 2);

    [self dragView:view
        at:dragPoint
        offset:dragImageOffset
        event:_mouseDownEvent
        pasteboard:nil
        source:self
        slideBack:YES];
}

- (CPView)_draggingViewForItemsAtIndexes:(CPIndexSet)indexes withEvent:(CPEvent)anEvent offset:(CGPoint)offset
{
    if ([_delegate respondsToSelector:@selector(collectionView:draggingViewForItemsAtIndexes:withEvent:offset:)])
        return [_delegate collectionView:self draggingViewForItemsAtIndexes:indexes withEvent:anEvent offset:offset];

    return [self draggingViewForItemsAtIndexes:indexes withEvent:anEvent offset:offset];
}

- (CPView)draggingViewForItemsAtIndexes:(CPIndexSet)indexes withEvent:(CPEvent)event offset:(CGPoint)dragImageOffset
{
    var idx = _content[[indexes firstIndex]];

    if (!_itemForDragging)
        _itemForDragging = [self newItemForRepresentedObject:idx];
    else
        [_itemForDragging setRepresentedObject:idx];

    return [_itemForDragging view];
}

- (BOOL)_canDragItemsAtIndexes:(CPIndexSet)indexes withEvent:(CPEvent)anEvent
{
    if ([self respondsToSelector:@selector(collectionView:canDragItemsAtIndexes:withEvent:)])
        return [_delegate collectionView:self canDragItemsAtIndexes:indexes withEvent:anEvent];

  return YES;
}

- (CPDragOperation)draggingEntered:(id)draggingInfo
{
    var dropIndex = -1,
        dropIndexRef = @ref(dropIndex),
        dragOp = [self _validateDragWithInfo:draggingInfo dropIndex:dropIndexRef dropOperation:1];

    dropIndex = dropIndexRef();

    [self _createDropIndicatorIfNeeded];

    [self _updateDragAndDropStateWithDraggingInfo:draggingInfo newDragOperation:dragOp newDropIndex:dropIndex newDropOperation:1];

    return _currentDragOperation;
}

- (CPDragOperation)draggingUpdated:(id)draggingInfo
{
    if (![self _dropIndexDidChange:draggingInfo])
        return _currentDragOperation;

    var dropIndex,
        dropIndexRef = @ref(dropIndex);

    var dragOperation = [self _validateDragWithInfo:draggingInfo dropIndex:dropIndexRef dropOperation:1];

    dropIndex = dropIndexRef();

    [self _updateDragAndDropStateWithDraggingInfo:draggingInfo newDragOperation:dragOperation newDropIndex:dropIndex newDropOperation:1];

    return dragOperation;
}

- (CPDragOperation)_validateDragWithInfo:(id)draggingInfo dropIndex:(Function)dropIndexRef dropOperation:(int)dropOperation
{
    var result = CPDragOperationMove,
        dropIndex = [self _dropIndexForDraggingInfo:draggingInfo proposedDropOperation:dropOperation];

    if ([_delegate respondsToSelector:@selector(collectionView:validateDrop:proposedIndex:dropOperation:)])
    {
        var dropIndexRef2 = @ref(dropIndex);

        result = [_delegate collectionView:self validateDrop:draggingInfo proposedIndex:dropIndexRef2  dropOperation:dropOperation];

        if (result !== CPDragOperationNone)
        {
            dropIndex = dropIndexRef2();
        }
    }

    dropIndexRef(dropIndex);

    return result;
}

- (void)draggingExited:(id)draggingInfo
{
    [self _updateDragAndDropStateWithDraggingInfo:draggingInfo newDragOperation:0 newDropIndex:-1 newDropOperation:1];
}

- (void)draggingEnded:(id)draggingInfo
{
    [self _updateDragAndDropStateWithDraggingInfo:draggingInfo newDragOperation:0 newDropIndex:-1 newDropOperation:1];
}

/*
Not supported. Use -collectionView:dataForItemsAtIndexes:fortype:
- (BOOL)_writeItemsAtIndexes:(CPIndexSet)indexes toPasteboard:(CPPasteboard)pboard
{
    if ([self respondsToSelector:@selector(collectionView:writeItemsAtIndexes:toPasteboard:)])
        return [_delegate collectionView:self writeItemsAtIndexes:indexes toPasteboard:pboard];

    return NO;
}
*/

- (BOOL)performDragOperation:(id)draggingInfo
{
    var result = NO;

    if (_currentDragOperation && _currentDropIndex !== -1)
        result = [_delegate collectionView:self acceptDrop:draggingInfo index:_currentDropIndex dropOperation:1];

    [self draggingEnded:draggingInfo]; // Is this correct ?

    return result;
}

- (void)_updateDragAndDropStateWithDraggingInfo:(id)draggingInfo newDragOperation:(CPDragOperation)dragOperation newDropIndex:(CPInteger)dropIndex newDropOperation:(CPInteger)dropOperation
{
    _currentDropIndex = dropIndex;
    _currentDragOperation = dragOperation;

    var frameOrigin,
        dropviewFrameWidth = CGRectGetWidth([_dropView frame]);

    if (_currentDropIndex == -1 || _currentDragOperation == CPDragOperationNone)
        frameOrigin = CGPointMake(-dropviewFrameWidth, 0);
    else if (_currentDropIndex == 0)
        frameOrigin = CGPointMake(0, 0);
    else
    {
        var offset;

        if ((_currentDropIndex % _numberOfColumns) !== 0 || _currentDropIndex == [_items count])
        {
            dropIndex = _currentDropIndex - 1;
            offset = (_horizontalMargin - dropviewFrameWidth) / 2;
        }
        else
        {
            offset = - _itemSize.width - dropviewFrameWidth - (_horizontalMargin - dropviewFrameWidth) / 2;
        }

        var rect = [self frameForItemAtIndex:dropIndex];

        frameOrigin = CGPointMake(CGRectGetMaxX(rect) + offset, rect.origin.y - _verticalMargin);
    }

    [_dropView setFrameOrigin:frameOrigin];
}

- (BOOL)_dropIndexDidChange:(id)draggingInfo
{
    var dropIndex = [self _dropIndexForDraggingInfo:draggingInfo proposedDropOperation:1];

    if (dropIndex == CPNotFound)
        dropIndex = [[self content] count];

    return (_currentDropIndex !== dropIndex)
}

- (CPInteger)_dropIndexForDraggingInfo:(id)draggingInfo proposedDropOperation:(int)dropOperation
{
    var location = [self convertPoint:[draggingInfo draggingLocation] fromView:nil],
        locationX = location.x + _itemSize.width / 2;

    var column = MIN(FLOOR(locationX / (_itemSize.width + _horizontalMargin)), _numberOfColumns),
        row = FLOOR(location.y / (_itemSize.height + _verticalMargin));

    if (row >= _numberOfRows - 1)
    {
        if (row >= _numberOfRows)
        {
            row = _numberOfRows - 1;
            column = _numberOfColumns;
        }

        return MIN((row * _numberOfColumns + column), [_items count]);
    }

    return (row * _numberOfColumns + column);
}

@end

@implementation _CPCollectionViewDropIndicator : CPView
{
}

- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        width = CGRectGetWidth(aRect),
        circleRect = CGRectMake(1, 1, width - 2, width - 2);

    CGContextSetStrokeColor(context, [CPColor colorWithHexString:@"4886ca"]);
    CGContextSetFillColor(context, [CPColor whiteColor]);
    CGContextSetLineWidth(context, 3);

    //draw white under the circle thing
    CGContextFillRect(context, circleRect);

    //draw the circle thing
    CGContextStrokeEllipseInRect(context, circleRect);

    //then draw the line
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, FLOOR(width / 2), CGRectGetMinY(aRect) + width);
    CGContextAddLineToPoint(context, FLOOR(width / 2), CGRectGetHeight(aRect));
    CGContextStrokePath(context);
}

@end

@implementation CPCollectionView (KeyboardInteraction)

- (void)_modifySelectionWithNewIndex:(int)anIndex direction:(int)aDirection expand:(BOOL)shouldExpand
{
    var count = [[self items] count];

    if (count === 0)
        return;

    anIndex = MIN(MAX(anIndex, 0), count - 1);

    if (_allowsMultipleSelection && shouldExpand)
    {
        var indexes = [_selectionIndexes copy],
            bottomAnchor = [indexes firstIndex],
            topAnchor = [indexes lastIndex];

        // if the direction is backward (-1) check with the bottom anchor
        if (aDirection === -1)
            [indexes addIndexesInRange:CPMakeRange(anIndex, bottomAnchor - anIndex + 1)];
        else
            [indexes addIndexesInRange:CPMakeRange(topAnchor, anIndex -  topAnchor + 1)];
    }
    else
        indexes = [CPIndexSet indexSetWithIndex:anIndex];

    [self setSelectionIndexes:indexes];
    [self _scrollToSelection];
}

- (void)_scrollToSelection
{
    var frame = [self frameForItemsAtIndexes:[self selectionIndexes]];

    if (!CGRectIsEmpty(frame))
        [self scrollRectToVisible:frame];
}

- (void)moveLeft:(id)sender
{
    var index = [[self selectionIndexes] firstIndex];
    if (index === CPNotFound)
        index = [[self items] count];

    [self _modifySelectionWithNewIndex:index - 1 direction:-1 expand:NO];
}

- (void)moveLeftAndModifySelection:(id)sender
{
    var index = [[self selectionIndexes] firstIndex];
    if (index === CPNotFound)
        index = [[self items] count];

    [self _modifySelectionWithNewIndex:index - 1 direction:-1 expand:YES];
}

- (void)moveRight:(id)sender
{
    [self _modifySelectionWithNewIndex:[[self selectionIndexes] lastIndex] + 1 direction:1 expand:NO];
}

- (void)moveRightAndModifySelection:(id)sender
{
    [self _modifySelectionWithNewIndex:[[self selectionIndexes] lastIndex] + 1 direction:1 expand:YES];
}

- (void)moveDown:(id)sender
{
    [self _modifySelectionWithNewIndex:[[self selectionIndexes] lastIndex] + [self numberOfColumns] direction:1 expand:NO];
}

- (void)moveDownAndModifySelection:(id)sender
{
    [self _modifySelectionWithNewIndex:[[self selectionIndexes] lastIndex] + [self numberOfColumns] direction:1 expand:YES];
}

- (void)moveUp:(id)sender
{
    var index = [[self selectionIndexes] firstIndex];
    if (index == CPNotFound)
        index = [[self items] count];

    [self _modifySelectionWithNewIndex:index - [self numberOfColumns] direction:-1 expand:NO];
}

- (void)moveUpAndModifySelection:(id)sender
{
    var index = [[self selectionIndexes] firstIndex];
    if (index == CPNotFound)
        index = [[self items] count];

    [self _modifySelectionWithNewIndex:index - [self numberOfColumns] direction:-1 expand:YES];
}

- (void)deleteBackward:(id)sender
{
    if ([[self delegate] respondsToSelector:@selector(collectionView:shouldDeleteItemsAtIndexes:)])
    {
        [[self delegate] collectionView:self shouldDeleteItemsAtIndexes:[self selectionIndexes]];

        var index = [[self selectionIndexes] firstIndex];
        if (index > [[self content] count] - 1)
            [self setSelectionIndexes:[CPIndexSet indexSetWithIndex:[[self content] count] - 1]];

        [self _scrollToSelection];
        [self setNeedsDisplay:YES];
    }
}

- (void)keyDown:(CPEvent)anEvent
{
    [self interpretKeyEvents:[anEvent]];
}

- (void)setAutoresizingMask:(int)aMask
{
    [super setAutoresizingMask:0];
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

var CPCollectionViewMinItemSizeKey              = @"CPCollectionViewMinItemSizeKey",
    CPCollectionViewMaxItemSizeKey              = @"CPCollectionViewMaxItemSizeKey",
    CPCollectionViewVerticalMarginKey           = @"CPCollectionViewVerticalMarginKey",
    CPCollectionViewMaxNumberOfRowsKey          = @"CPCollectionViewMaxNumberOfRowsKey",
    CPCollectionViewMaxNumberOfColumnsKey       = @"CPCollectionViewMaxNumberOfColumnsKey",
    CPCollectionViewSelectableKey               = @"CPCollectionViewSelectableKey",
    CPCollectionViewAllowsMultipleSelectionKey  = @"CPCollectionViewAllowsMultipleSelectionKey",
    CPCollectionViewBackgroundColorsKey         = @"CPCollectionViewBackgroundColorsKey";


@implementation CPCollectionView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _minItemSize = [aCoder decodeSizeForKey:CPCollectionViewMinItemSizeKey];
        _maxItemSize = [aCoder decodeSizeForKey:CPCollectionViewMaxItemSizeKey];

        _maxNumberOfRows = [aCoder decodeIntForKey:CPCollectionViewMaxNumberOfRowsKey];
        _maxNumberOfColumns = [aCoder decodeIntForKey:CPCollectionViewMaxNumberOfColumnsKey];

        _verticalMargin = [aCoder decodeFloatForKey:CPCollectionViewVerticalMarginKey];

        _isSelectable = [aCoder decodeBoolForKey:CPCollectionViewSelectableKey];
        _allowsMultipleSelection = [aCoder decodeBoolForKey:CPCollectionViewAllowsMultipleSelectionKey];

        [self setBackgroundColors:[aCoder decodeObjectForKey:CPCollectionViewBackgroundColorsKey]];

        [self _init];
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

    [aCoder encodeInt:_maxNumberOfRows forKey:CPCollectionViewMaxNumberOfRowsKey];
    [aCoder encodeInt:_maxNumberOfColumns forKey:CPCollectionViewMaxNumberOfColumnsKey];

    [aCoder encodeBool:_isSelectable forKey:CPCollectionViewSelectableKey];
    [aCoder encodeBool:_allowsMultipleSelection forKey:CPCollectionViewAllowsMultipleSelectionKey];

    [aCoder encodeFloat:_verticalMargin forKey:CPCollectionViewVerticalMarginKey];

    [aCoder encodeObject:_backgroundColors forKey:CPCollectionViewBackgroundColorsKey];
}

@end
