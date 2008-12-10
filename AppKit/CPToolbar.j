/*
 * CPToolbar.j
 * AppKit
 *
 * Portions based on NSToolbar.m (11/10/2008) in Cocotron (http://www.cocotron.org/)
 * Copyright (c) 2006-2007 Christopher J. W. Lloyd
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

@import <Foundation/CPObject.j>

@import "CPPopUpButton.j"
@import "CPToolbarItem.j"


/*
    @global
    @group CPToolbarDisplayMode
*/
CPToolbarDisplayModeDefault             = 0;
/*
    @global
    @group CPToolbarDisplayMode
*/
CPToolbarDisplayModeIconAndLabel        = 1;
/*
    @global
    @group CPToolbarDisplayMode
*/
CPToolbarDisplayModeIconOnly            = 2;
/*
    @global
    @group CPToolbarDisplayMode
*/
CPToolbarDisplayModeLabelOnly           = 3;

var CPToolbarsByIdentifier              = nil;
var CPToolbarConfigurationsByIdentifier = nil;

/*!
    @class CPToolbar
    
    A CPToolbar is displayed at the top of a window with multiple
    buttons (tools) that offer the user quick access to features.

    @par Delegate Methods

    @delegate -(CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)toolbar;
    Called to obtain the toolbar's default item identifiers. Required.
    @param toolbar the toolbar to obtain identifiers for
    @return an array of default item identifiers in the order on the toolbar

    @delegate -(CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)toolbar;
    Called to obtain the toolbar's default item identifiers. Required.
    @param toolbar the toolbar to obtain identifiers for
    @return an array of default item identifiers in the order on the toolbar
    
    @delegate - (CPToolbarItem)toolbar:(CPToolbar)toolbar itemForItemIdentifier:(CPString)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
    Called to obtain a toolbar item. Required.
    @param toolbar the toolbar the item belongs to
    @param itemIdentifier the identifier of the toolbar item
    @param flag <code>YES</code> means the item will be placed in the toolbar. <code>NO</code> means the item will be displayed for
    some other purpose (non-functional)
    @return the toolbar item or <code>nil</code> if no such item belongs in the toolbar
*/
@implementation CPToolbar : CPObject
{
    CPString                _identifier;
    CPToolbarDisplayMode    _displayMode;
    BOOL                    _showsBaselineSeparator;
    BOOL                    _allowsUserCustomization;
    BOOL                    _isVisible;
    
    id                      _delegate;
    
    CPArray                 _itemIdentifiers;
    
    CPDictionary            _identifiedItems;
    CPArray                 _defaultItems;
    CPArray                 _allowedItems;
    CPArray                 _selectableItems;
    
    CPArray                 _items;
    CPArray                 _itemsSortedByVisibilityPriority;
    
    CPView                  _toolbarView;
}

/* @ignore */
+ (void)initialize
{
    if (self != [CPToolbar class])
        return;
        
    CPToolbarsByIdentifier = [CPDictionary dictionary];
    CPToolbarConfigurationsByIdentifier = [CPDictionary dictionary];
}

/* @ignore */
+ (void)_addToolbar:(CPToolbar)toolbar forIdentifier:(CPString)identifier
{
    var toolbarsSharingIdentifier = [CPToolbarsByIdentifier objectForKey:identifier];
    
    if (!toolbarsSharingIdentifier)
    {
        toolbarsSharingIdentifier = []
        [CPToolbarsByIdentifier setObject:toolbarsSharingIdentifier forKey:identifier];
    }
        
    [toolbarsSharingIdentifier addObject:toolbar];
}

/*!
    Initializes the toolbar with the specified identifier.
    @param anIdentifier the identifier for the toolbar
    @return the initialized toolbar
*/
- (id)initWithIdentifier:(CPString)anIdentifier
{
    self = [super init];
    
    if (self)
    {
        _items = [];
        
        _identifier = anIdentifier;
        _isVisible = YES;
    
        [CPToolbar _addToolbar:self forIdentifier:_identifier];
    }
    
    return self;
}


/*!
    Sets the toolbar's display mode. NOT YET IMPLEMENTED.
*/
- (void)setDisplayMode:(CPToolbarDisplayMode)aDisplayMode
{
    
}

/*!
    Returns the toolbar's identifier
*/
- (CPString)identifier
{
    return _identifier;
}

/*!
    Returns the toolbar's delegate
*/
- (id)delegate
{
    return _delegate;
}

/*!
    Returns <code>YES</code> if the toolbar is currently visible
*/
- (BOOL)isVisible
{
    return _isVisible;
}

/*!
    Sets whether the toolbar should be visible.
    @param aFlag <code>YES</code> makes the toolbar visible
*/
- (void)setVisible:(BOOL)aFlag
{
    if (_isVisible == aFlag)
        return;
        
    _isVisible = aFlag;

    [_window _setToolbarVisible:_isVisible];
    [self _reloadToolbarItems];
}

/*!
    Sets the delegate for the toolbar.
    @param aDelegate the new toolbar delegate
*/
- (void)setDelegate:(id)aDelegate
{
    if (_delegate == aDelegate)
        return;
        
    _delegate = aDelegate;
    
    [self _reloadToolbarItems];
}

/* @ignore */
- (void)_loadConfiguration
{

}

/* @ignore */
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

/* @ignore */
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

    var index = 0;
    
    for (; index < count; ++index)
    {
        var identifier = _itemIdentifiers[index],
            item = [CPToolbarItem _standardItemWithItemIdentifier:identifier];
        
        if (!item)
            item = [[_delegate toolbar:self itemForItemIdentifier:identifier willBeInsertedIntoToolbar:YES] copy];
            
        if (item == nil)
            [CPException raise:CPInvalidArgumentException
                         reason:sprintf(@"_delegate %s returned nil toolbar item returned for identifier %s", _delegate, identifier)];
            
        [_items addObject:item];
    }
  
//    _items = [[self _defaultToolbarItems] mutableCopy];
    
    // Store items sorted by priority.  We want items to be removed first at the end of the array,
    // items to be removed last at the front.
    
    _itemsSortedByVisibilityPriority = [_items sortedArrayUsingFunction:_CPToolbarItemVisibilityPriorityCompare context:NULL];
    
    [_toolbarView reloadToolbarItems];
}

/*!
    Returns all the items in this toolbar.
*/
- (CPArray)items
{
    return _items;
}

/*!
    Returns all the visible items in this toolbar
*/
- (CPArray)visibleItems
{
    return [_toolbarView visibleItems];
}

/*!
    Returns the toolbar items sorted by their <code>visibilityPriority</code>(ies).
*/
- (CPArray)itemsSortedByVisibilityPriority
{
    return _itemsSortedByVisibilityPriority;
}

/* @ignore */
- (id)_itemForItemIdentifier:(CPString)identifier willBeInsertedIntoToolbar:(BOOL)toolbar
{
    var item = [_identifiedItems objectForKey:identifier];
    if (!item)
    {
        item = [CPToolbarItem _standardItemWithItemIdentifier:identifier];
        if (_delegate && !item)
        {
            item = [[_delegate toolbar:self itemForItemIdentifier:identifier willBeInsertedIntoToolbar:toolbar] copy];
            if (!item)
                [CPException raise:CPInvalidArgumentException
                            reason:sprintf(@"_delegate %s returned nil toolbar item returned for identifier %s", _delegate, identifier)];
        }
        
        [_identifiedItems setObject:item forKey:identifier];
    }

    return item;
}

/* @ignore */
- (id)_itemsWithIdentifiers:(CPArray)identifiers
{   
    var items = [];
    for (var i = 0; i < identifiers.length; i++)
        [items addObject:[self _itemForItemIdentifier:identifiers[i] willBeInsertedIntoToolbar:NO]];

    return items;
}

/* @ignore */
-(id)_defaultToolbarItems
{
    if (!_defaultItems)
        if ([_delegate respondsToSelector:@selector(toolbarDefaultItemIdentifiers:)])
            _defaultItems = [self _itemsWithIdentifiers:[_delegate toolbarDefaultItemIdentifiers:self]];
    
    return _defaultItems;
}

@end


var CPToolbarIdentifierKey              = "CPToolbarIdentifierKey",
    CPToolbarDisplayModeKey             = "CPToolbarDisplayModeKey",
    CPToolbarShowsBaselineSeparatorKey  = "CPToolbarShowsBaselineSeparatorKey",
    CPToolbarAllowsUserCustomizationKey = "CPToolbarAllowsUserCustomizationKey",
    CPToolbarIsVisibleKey               = "CPToolbarIsVisibleKey",
    CPToolbarDelegateKey                = "CPToolbarDelegateKey",
    CPToolbarIdentifiedItemsKey         = "CPToolbarIdentifiedItemsKey",
    CPToolbarDefaultItemsKey            = "CPToolbarDefaultItemsKey",
    CPToolbarAllowedItemsKey            = "CPToolbarAllowedItemsKey",
    CPToolbarSelectableItemsKey         = "CPToolbarSelectableItemsKey";

@implementation CPToolbar (CPCoding)

/*
    Initializes the toolbar by unarchiving data from <code>aCoder</code>.
    @param aCoder the coder containing the archived CPToolbar.
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _identifier                 = [aCoder decodeObjectForKey:CPToolbarIdentifierKey];
        _displayMode                = [aCoder decodeIntForKey:CPToolbarDisplayModeKey];
        _showsBaselineSeparator     = [aCoder decodeBoolForKey:CPToolbarShowsBaselineSeparatorKey];
        _allowsUserCustomization    = [aCoder decodeBoolForKey:CPToolbarAllowsUserCustomizationKey];
        _isVisible                  = [aCoder decodeBoolForKey:CPToolbarIsVisibleKey];
        
        _identifiedItems            = [aCoder decodeObjectForKey:CPToolbarIdentifiedItemsKey];
        _defaultItems               = [aCoder decodeObjectForKey:CPToolbarDefaultItemsKey];
        _allowedItems               = [aCoder decodeObjectForKey:CPToolbarAllowedItemsKey];
        _selectableItems            = [aCoder decodeObjectForKey:CPToolbarSelectableItemsKey];
        
        _items = [];
        [CPToolbar _addToolbar:self forIdentifier:_identifier];
        
        [self setDelegate:[aCoder decodeObjectForKey:CPToolbarDelegateKey]];
    }
    
    return self;
}

/*
    Archives this toolbar into the provided coder.
    @param aCoder the coder to which the toolbar's instance data will be written.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_identifier            forKey:CPToolbarIdentifierKey];
    [aCoder encodeInt:_displayMode              forKey:CPToolbarDisplayModeKey];
    [aCoder encodeBool:_showsBaselineSeparator  forKey:CPToolbarShowsBaselineSeparatorKey];
    [aCoder encodeBool:_allowsUserCustomization forKey:CPToolbarAllowsUserCustomizationKey];
    [aCoder encodeBool:_isVisible               forKey:CPToolbarIsVisibleKey];
    
    [aCoder encodeObject:_identifiedItems       forKey:CPToolbarIdentifiedItemsKey];
    [aCoder encodeObject:_defaultItems          forKey:CPToolbarDefaultItemsKey];
    [aCoder encodeObject:_allowedItems          forKey:CPToolbarAllowedItemsKey];
    [aCoder encodeObject:_selectableItems       forKey:CPToolbarSelectableItemsKey];
    
    [aCoder encodeConditionalObject:_delegate   forKey:CPToolbarDelegateKey];
}

@end


var _CPToolbarViewBackgroundColor = nil,
    _CPToolbarViewExtraItemsImage = nil,
    _CPToolbarViewExtraItemsAlternateImage = nil;

var TOOLBAR_TOP_MARGIN          = 5.0,
    TOOLBAR_ITEM_MARGIN         = 10.0,
    TOOLBAR_EXTRA_ITEMS_WIDTH   = 20.0;

var _CPToolbarItemInfoMake = function(anIndex, aView, aLabel, aMinWidth)
{
    return { index:anIndex, view:aView, label:aLabel, minWidth:aMinWidth };
}

/* @ignore */
@implementation _CPToolbarView : CPView
{
    CPToolbar           _toolbar;
    
    CPIndexSet          _flexibleWidthIndexes;
    CPIndexSet          _visibleFlexibleWidthIndexes;
    
    CPDictionary        _itemInfos;
    
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
        [_additionalItemsButton setBordered:NO];

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
    // Also determine the height of the toolbar.
    // NOTE: height is height without top margin, and bottom margin/label.
    var index = _visibleItems.length,
        height = 0.0;

    while (index--)
    {
        var item = _visibleItems[index],
            minSize = [item minSize],
            view = [self viewForItem:item];
        
        if (minSize.width != [item maxSize].width)
            [flexibleItemIndexes addIndex:index];
        
        // If the item doesn't have flexible width, then make sure it's set to the static width (min==max)
        // This handles the case where the user did setView: with a view of a different size than minSize/maxSize
        else
            [view setFrameSize:CGSizeMake([item minSize].width, CGRectGetHeight([view frame]))];

        // FIXME: minHeight?

        [view setHidden:NO];
        [[self labelForItem:item] setHidden:NO];
        
        if (height < minSize.height)
            height = minSize.height;
    }
    
    var remainingSpace = width - minWidth,
        proportionate = 0.0;

    // Continue to distribute space proportionately while we have it, 
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
                viewFrame = [view frame],
                // FIXME: Should this be minWidthForItem: ?
                proposedWidth = [item minSize].width + proportionate,
                constrainedWidth = MIN(proposedWidth, [item maxSize].width);
            
            if (constrainedWidth < proposedWidth)
            {
                [flexibleItemIndexes removeIndex:index];
                
                remainingSpace += proposedWidth - constrainedWidth;
            }
            
            [view setFrameSize:CGSizeMake(constrainedWidth, CGRectGetHeight(viewFrame))];
        }
    }
    
    // Now that all the visible items are the correct width, position them accordingly.
    var count = _visibleItems.length,
        x = TOOLBAR_ITEM_MARGIN,
        fullHeightItems = [];

    for (index = 0; index < count; ++index)
    {
        var item = _visibleItems[index],
            view = [self viewForItem:item],
            
            viewFrame = [view frame],
            viewWidth = CGRectGetWidth(viewFrame),
            
            label = [self labelForItem:item],
            labelFrame = [label frame],
            labelWidth = CGRectGetWidth(labelFrame),
            
            itemWidth = MAX([self minWidthForItem:item], viewWidth),
            
            viewHeight = CGRectGetHeight(viewFrame);

        // itemWidth != viewWidth.  itemWidth is MAX(size of view, size of label).  If the label is larger,
        // *center* the view, don't resize it.
        [view setFrame:CGRectMake(x + (itemWidth - viewWidth) / 2.0, TOOLBAR_TOP_MARGIN + (height - viewHeight) / 2.0, viewWidth, viewHeight)];
        [label setFrameOrigin:CGPointMake(x + (itemWidth - labelWidth) / 2.0, TOOLBAR_TOP_MARGIN + height + 2.0)];

        x += itemWidth + TOOLBAR_ITEM_MARGIN;
        
        if ([item itemIdentifier] == CPToolbarSeparatorItemIdentifier)
            fullHeightItems.push(item);
    }
    
    for (index = 0, count = fullHeightItems.length; index < count; ++index)
    {
        var view = [self viewForItem:fullHeightItems[index]],
            viewHeight = 53.0;
        
        // FIXME: Variable Height
        [view setFrame:CGRectMake(CGRectGetMinX([view frame]), (59.0 - viewHeight) / 2.0, CGRectGetWidth([view frame]), viewHeight)];
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

/* @ignore */
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
