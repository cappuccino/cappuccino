/*
 * CPToolbar.j
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

import <Foundation/CPObject.j>

import "CPPopUpButton.j"
import "CPToolbarItem.j"

CPToolbarDisplayModeDefault             = 0;
CPToolbarDisplayModeIconAndLabel        = 1;
CPToolbarDisplayModeIconOnly            = 2;
CPToolbarDisplayModeLabelOnly           = 3;

var CPToolbarsByIdentifier              = nil;
var CPToolbarConfigurationsByIdentifier = nil;

var _CPToolbarItemVisibilityPriorityCompare = function(lhs, rhs)
{
    var lhsVisibilityPriority = [lhs visibilityPriority],
        rhsVisibilityPriority = [rhs visibilityPriority];
        
    if (lhsVisibilityPriority == rhsVisibilityPriority)
        return CPOrderedSame;
    
    if (lhsVisibilityPriority > rhsVisibilityPriority)
        return CPOrderedAscending;
    
    return CPOrderedDescending;
}

@implementation CPToolbar : CPObject
{
    CPString                _identifier;
    CPToolbarDisplayMode    _displayMode;
    BOOL                    _showsBaselineSeparator;
    BOOL                    _allowsUserCustomization;
    BOOL                    _isVisible;
    BOOL                    _needsReloadOfItems;
    
    id                      _delegate;
    CPView                  _toolbarView;
    
    CPArray                 _itemIdentifiers;
    CPArray                 _allowedItemIdentifiers;    
    
    CPArray                 _items;
    CPArray                 _labels;
    
    CPMutableDictionary     _itemIndexes;
}

+ (void)initialize
{
    if (self != [CPToolbar class])
        return;
        
    CPToolbarsByIdentifier = [CPDictionary dictionary];
    CPToolbarConfigurationsByIdentifier = [CPDictionary dictionary];
}

- (id)initWithIdentifier:(CPString)anIdentifier
{
    self = [super init];
    
    if (self)
    {
        _items = [];
        _labels = [];
        
        _identifier = anIdentifier;
        _isVisible = YES;
    
        var toolbarsSharingIdentifier = [CPToolbarsByIdentifier objectForKey:_identifier];
        
        if (!toolbarsSharingIdentifier)
        {
            toolbarsSharingIdentifier = []
            [CPToolbarsByIdentifier setObject:toolbarsSharingIdentifier forKey:_identifier];
        }
            
        [toolbarsSharingIdentifier addObject:self];
    }
    
    return self;
}

- (void)setDisplayMode:(CPToolbarDisplayMode)aDisplayMode
{
    
}

- (CPString)identifier
{
    return _identifier;
}

- (id)delegate
{
    return _delegate;
}

- (BOOL)isVisible
{
    return _isVisible;
}

- (void)setVisible:(BOOL)aFlag
{
    if (_isVisible == aFlag)
        return;
        
    _isVisible = aFlag;

    [_window _setToolbarVisible:_isVisible];
    [self _reloadToolbarItems];
}

- (void)setDelegate:(id)aDelegate
{
    if (_delegate == aDelegate)
        return;
        
    _delegate = aDelegate;
    
    // When _delegate is nil, this will be cleared out.
    _itemIdentifiers = nil;
    _allowedItemIdentifiers = [_delegate toolbarAllowedItemIdentifiers:self];
    
    [self _reloadToolbarItems];
}

- (void)_loadConfiguration
{

}

- (CPView)_toolbarView
{
    if (!_toolbarView)
    {
        _toolbarView = [[_CPToolbarView alloc] initWithFrame:CPRectMake(0.0, 0.0, 1200.0, 59.0)];
        [_toolbarView setAutoresizingMask:CPViewWidthSizable];
    
        [_toolbarView setToolbar:self];
    }
    
    return _toolbarView;
}

- (void)_reloadToolbarItems
{
    if (![_toolbarView superview] || !_delegate)
        return;
    
    var count = [_itemIdentifiers count];
    
    if (!count)
    {
        _itemIdentifiers = [[_delegate toolbarDefaultItemIdentifiers:self] mutableCopy];
        
        count = [_itemIdentifiers count];
    }
    
    [[_toolbarView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    _items = [];
    _labels = []; 

    var index = 0;
    
    for (; index < count; ++index)
    {
        var identifier = _itemIdentifiers[index],
            item = [CPToolbarItem _standardItemWithItemIdentifier:identifier];
        
        if (!item)
            item = [[_delegate toolbar:self itemForItemIdentifier:identifier willBeInsertedIntoToolbar:YES] copy];
        
        if (item == nil)
            [CPException raise:CPInvalidArgumentException
                        format:@"_delegate %@ returned nil toolbar item returned for identifier %@", _delegate, identifier];
        
        [_items addObject:item];
    }
    
    // Store items sorted by priority.  We want items to be removed first at the end of the array,
    // items to be removed last at the front.
    
    _itemsSortedByVisibilityPriority = [_items sortedArrayUsingFunction:_CPToolbarItemVisibilityPriorityCompare context:NULL];
    
    [_toolbarView reloadToolbarItems];
}

- (void)items
{
    return _items;
}

- (CPArray)visibleItems
{
    return [_toolbarView visibleItems];
}

- (int)indexOfItem:(CPToolbarItem)anItem
{
    var info = [_itemIndexes objectForKey:[anItem hash]];
    
    if (!info)
        return CPNotFound;
    
    return info.index;
}

- (CPArray)itemsSortedByVisibilityPriority
{
    return _itemsSortedByVisibilityPriority;
}

@end


var _CPToolbarViewBackgroundColor = nil,
    _CPToolbarViewExtraItemsImage = nil,
    _CPToolbarViewExtraItemsAlternateImage = nil;

var TOOLBAR_TOP_MARGIN  = 5.0,
    TOOLBAR_ITEM_MARGIN = 10.0,
    TOOLBAR_EXTRA_ITEMS_WIDTH = 20.0;

var _CPToolbarItemInfoMake = function(anIndex, aView, aLabel, aMinWidth)
{
    return { index:anIndex, view:aView, label:aLabel, minWidth:aMinWidth };
}

@implementation _CPToolbarView : CPView
{
    CPToolbar           _toolbar;
    
    CPIndexSet          _flexibleWidthIndexes;
    CPIndexSet          _visibleFlexibleWidthIndexes;
    
    CPMutableDictionary _itemInfos;
    
    CPArray             _visibleItems;
    CPArray             _invisibleItems;
    
    CPPopUpButton       _additionalItemsButton;
}

+ (void)initialize
{
    if (self != [_CPToolbarView class])
        return;
    
    var bundle = [CPBundle bundleForClass:self];
    
    _CPToolbarViewBackgroundColor = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPToolbarView/_CPToolbarViewBackground.png"] size:CGSizeMake(1.0, 59.0)]];
    
    _CPToolbarViewExtraItemsImage = [[CPImage alloc] initWithContentsOfFile: [bundle pathForResource:"_CPToolbarView/_CPToolbarViewExtraItemsImage.png"] size: CPSizeMake(10.0, 15.0)];

    _CPToolbarViewExtraItemsAlternateImage = [[CPImage alloc] initWithContentsOfFile: [bundle pathForResource:"_CPToolbarView/_CPToolbarViewExtraItemsAlternateImage.png"] size:CGSizeMake(10.0, 15.0)];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _minWidth = 0;
        
        [self setBackgroundColor:_CPToolbarViewBackgroundColor];
        
        _additionalItemsButton = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 15.0) pullsDown:YES];

        [_additionalItemsButton setImagePosition:CPImageOnly];
        [[_additionalItemsButton menu] setShowsStateColumn:NO];
        
        [_additionalItemsButton setAlternateImage:_CPToolbarViewExtraItemsAlternateImage];
    }
    
    return self;
}

- (void)setToolbar:(CPToolbar)aToolbar
{
    _toolbar = aToolbar;
}

- (CPToolbar)toolbar
{
    return _toolbar;
}

// This *should* be roughly O(3N) = O(N)
- (void)resizeSubviewsWithOldSize:(CGSize)aSize
{
    [self layoutSubviews];
}

- (void)layoutSubviews
{
    // We begin by recalculating the visible items.
    var items = [_toolbar items],
        width = CGRectGetWidth([self bounds]),
        minWidth = _minWidth,
        flexibleItemIndexes = [CPIndexSet indexSet],
        // FIXME: This should be a CPSet.
        invisibleItemsSortedByPriority = [];
    
    _visibleItems = items;
    
    // We only have hidden items if our actual width is smaller than our 
    // minimum width for hiding items.
    if (width < minWidth)
    {
        width -= TOOLBAR_EXTRA_ITEMS_WIDTH;
                
        _visibleItems = [_visibleItems copy];
        
        var itemsSortedByVisibilityPriority = [_toolbar itemsSortedByVisibilityPriority],
            count = itemsSortedByVisibilityPriority.length;
        
        // While our items take up too much space...
        while (minWidth > width)
        {
            var item = itemsSortedByVisibilityPriority[count--];
            
            minWidth -= [self minWidthForItem:item] + TOOLBAR_ITEM_MARGIN;
            
            [_visibleItems removeObjectIdenticalTo:item];
            [invisibleItemsSortedByPriority addObject:item];
            
            [[self viewForItem:item] setHidden:YES];
            [[self labelForItem:item] setHidden:YES];
        }
    }
    
    // Determine all the items that have flexible width.
    var index = _visibleItems.length;
    
    while (index--)
    {
        var item = _visibleItems[index];
        
        if ([item minSize].width != [item maxSize].width)
            [flexibleItemIndexes addIndex:index];            

        [[self viewForItem:item] setHidden:NO];
        [[self labelForItem:item] setHidden:NO];
    }
    
    var remainingSpace = width - minWidth,
        proportionate = 0.0;
    
    // Continue to dstribute space proportionately while we have it, 
    // and there are flexible items left that want it. (Those with max 
    // widths may eventually not want it anymore).
    while (remainingSpace && [flexibleItemIndexes count])
    {
        // Divy out the space.
        proportionate += remainingSpace / [flexibleItemIndexes count];
        
        // Reset the remaining space to 0
        remainingSpace = 0.0;
        
        var index = CPNotFound;

        while ((index = [flexibleItemIndexes indexGreaterThanIndex:index]) != CPNotFound)
        {
            var item = _visibleItems[index];
                view = [self viewForItem:item],
                frame = [view frame],
                proposedWidth = [item minSize].width + proportionate,
                constrainedWidth = MIN(proposedWidth, [item maxSize].width);
            
            if (constrainedWidth < proposedWidth)
            {
                [flexibleItemIndexes removeIndex:index];
                
                remainingSpace += proposedWidth - constrainedWidth;
            }
            
            [view setFrameSize:CGSizeMake(constrainedWidth, CGRectGetHeight(frame))];
        }
    }
    
    // Now that all the visible items are the correct width, position them accordingly.
    var count = _visibleItems.length,
        x = TOOLBAR_ITEM_MARGIN;
    
    for (index = 0; index < count; ++index)
    {
        var item = _visibleItems[index],
            view = [self viewForItem:item],
            
            viewFrame = [view frame],
            viewWidth = CGRectGetWidth(viewFrame),
            
            label = [self labelForItem:item],
            labelFrame = [label frame],
            labelWidth = CGRectGetWidth(labelFrame),
            
            itemWidth = MAX([self minWidthForItem:item], viewWidth);
        
        [view setFrameOrigin:CGPointMake(x + (itemWidth - viewWidth) / 2.0, TOOLBAR_TOP_MARGIN)];
        [label setFrameOrigin:CGPointMake(x + (itemWidth - labelWidth) / 2.0, TOOLBAR_TOP_MARGIN + CGRectGetHeight(viewFrame))];

        x += itemWidth + TOOLBAR_ITEM_MARGIN;
    }
    
    if ([invisibleItemsSortedByPriority count])
    {
        var index = 0,
            count = [items count];
            
        _invisibleItems = [];
        
        for (; index < count; ++index)
        {
            var item = items[index];
            
            if ([invisibleItemsSortedByPriority indexOfObjectIdenticalTo:item] != CPNotFound)
                [_invisibleItems addObject:item];
        }
        
        [_additionalItemsButton setFrameOrigin:CGPointMake(width + 5.0, (CGRectGetHeight([self bounds]) - CGRectGetHeight([_additionalItemsButton frame])) / 2.0)];
        
        [self addSubview:_additionalItemsButton];
        
        [_additionalItemsButton removeAllItems];
        
        var index = 0,
            count = [_invisibleItems count];

        [_additionalItemsButton addItemWithTitle:@"Additional Items"];
        [[_additionalItemsButton itemArray][0] setImage:_CPToolbarViewExtraItemsImage];
        
        for (; index < count; ++index)
        {
            var item = _invisibleItems[index];
            
            [_additionalItemsButton addItemWithTitle:[item label]];
            
            var menuItem = [_additionalItemsButton itemArray][index + 1];
            
            [menuItem setImage:[item image]];
            
            [menuItem setTarget:[item target]];
            [menuItem setAction:[item action]];
        }
    }
    else
        [_additionalItemsButton removeFromSuperview];
    
}

- (int)indexOfItem:(CPToolbarItem)anItem
{
    var info = [_itemInfos objectForKey:[anItem hash]];
    
    if (!info)
        return CPNotFound;
    
    return info.index;
}

- (CPView)viewForItem:(CPToolbarItem)anItem
{
    var info = [_itemInfos objectForKey:[anItem hash]];
    
    if (!info)
        return nil;
    
    return info.view;
}

- (CPTextField)labelForItem:(CPToolbarItem)anItem
{
    var info = [_itemInfos objectForKey:[anItem hash]];
    
    if (!info)
        return nil;
    
    return info.label;
}

- (float)minWidthForItem:(CPToolbarItem)anItem
{
    var info = [_itemInfos objectForKey:[anItem hash]];
    
    if (!info)
        return 0;
    
    return info.minWidth;
}

- (void)reloadToolbarItems
{
    // Get rid of all our current subviews.
    var subviews = [self subviews],
        count = subviews.length;
    
    while (count--)
        [subviews removeObjectAtIndex:count];

    // Populate with new subviews.
    var items = [_toolbar items],
        index = 0;
    
    count = items.length;
        
    _itemInfos = [CPDictionary dictionary];
    _minWidth = TOOLBAR_ITEM_MARGIN;

    for (; index < count; ++index)
    {
        var item = items[index],
            view = [item view];
        
        // If this item doesn't have a custom view, create a standard one.
        if (!view)
        {
            view = [[CPButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 32.0, 32.0)];
        
            [view setBordered:NO];
            
            [view setImage:[item image]];
            [view setAlternateImage:[item alternateImage]];
            
            [view setTarget:[item target]];
            [view setAction:[item action]];
        
            [view setImagePosition:CPImageOnly];
        }
        
        [self addSubview:view];
        
        // Create a lable for this item.
        var label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
        
        [label setStringValue:[item label]];
        [label setFont:[CPFont systemFontOfSize:11.0]];
        [label sizeToFit];

        [label setTarget:[item target]];
        [label setAction:[item action]];

        [self addSubview:label];
        
        var minSize = [item minSize],
            minWidth = MAX(minSize.width, CGRectGetWidth([label frame]));
            
        [_itemInfos setObject:_CPToolbarItemInfoMake(index, view, label, minWidth) forKey:[item hash]];
        
        _minWidth += minWidth + TOOLBAR_ITEM_MARGIN;
        
        // If the minSize is different than the maxSize, then this item has flexible width.
        //if (minSize.width != [item maxSize].width)
        //    [_flexibleWidthIndexes addIndex:index];
    }
    
    [self layoutSubviews];
}

@end
