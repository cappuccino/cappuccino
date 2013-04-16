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

@global CPApp

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


CPToolbarSizeModeDefault                = 0;
CPToolbarSizeModeRegular                = 1;
CPToolbarSizeModeSmall                  = 2;

var CPToolbarsByIdentifier              = nil,
    CPToolbarConfigurationsByIdentifier = nil;

/*!
    @ingroup appkit
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
    @param flag \c YES means the item will be placed in the toolbar. \c NO means the item will be displayed for
    some other purpose (non-functional)
    @return the toolbar item or \c nil if no such item belongs in the toolbar
*/
@implementation CPToolbar : CPObject
{
    CPString                _identifier;
    CPToolbarDisplayMode    _displayMode @accessors(property=displayMode);
    BOOL                    _showsBaselineSeparator;
    BOOL                    _allowsUserCustomization;
    BOOL                    _isVisible;
    int                     _sizeMode @accessors(property=sizeMode);
    int                     _desiredHeight;

    id                      _delegate;

    CPArray                 _itemIdentifiers;

    CPDictionary            _identifiedItems;
    CPArray                 _defaultItems;
    CPArray                 _allowedItems;
    CPArray                 _selectableItems;

    CPArray                 _items;
    CPArray                 _itemsSortedByVisibilityPriority;

    CPView                  _toolbarView;
    CPWindow                _window;
}

/* @ignore */
+ (void)initialize
{
    if (self !== [CPToolbar class])
        return;

    CPToolbarsByIdentifier = @{};
    CPToolbarConfigurationsByIdentifier = @{};
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

- (id)init
{
    return [self initWithIdentifier:@""];
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
        _sizeMode = CPToolbarSizeModeDefault;
        _desiredHeight = 0;

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
    Returns \c YES if the toolbar is currently visible
*/
- (BOOL)isVisible
{
    return _isVisible;
}

/*!
    Sets whether the toolbar should be visible.
    @param aFlag \c YES makes the toolbar visible
*/
- (void)setVisible:(BOOL)aFlag
{
    if (_isVisible === aFlag)
        return;

    _isVisible = aFlag;

    [_window _noteToolbarChanged];
}

- (void)setSizeMode:(CPToolbarSizeMode)aSize
{
    if (aSize === _sizeMode)
        return;
    _sizeMode = aSize;

    [[self _toolbarView] setFrame:[self _toolbarViewFrame]];
    [_window _noteToolbarChanged];
}

- (CPWindow)_window
{
    return _window;
}

- (void)_setWindow:(CPWindow)aWindow
{
    if (_window)
        [[CPNotificationCenter defaultCenter] removeObserver:self name:_CPWindowDidChangeFirstResponderNotification object:_window];

    _window = aWindow;

    if (_window)
        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_autoValidateVisibleItems) name:_CPWindowDidChangeFirstResponderNotification object:aWindow];
}

/*!
    Sets the delegate for the toolbar.
    @param aDelegate the new toolbar delegate
*/
- (void)setDelegate:(id)aDelegate
{
    if (_delegate === aDelegate)
        return;

    _delegate = aDelegate;

    [self _reloadToolbarItems];
}

- (void)setDisplayMode:(CPToolbarDisplayMode)aDisplayMode
{
    if (_displayMode === aDisplayMode)
        return;
    _displayMode = aDisplayMode;

    [self _reloadToolbarItems];
}

/* @ignore */
- (void)_loadConfiguration
{

}

- (CGRect)_toolbarViewFrame
{
    var height = _desiredHeight || (_sizeMode != CPToolbarSizeModeSmall ? [_toolbarView valueForThemeAttribute:@"regular-size-height"] : [_toolbarView valueForThemeAttribute:@"small-size-height"]);
    return CGRectMake(0.0, 0.0, 1200.0, height);
}

/* @ignore */
- (CPView)_toolbarView
{
    if (!_toolbarView)
    {
        _toolbarView = [[_CPToolbarView alloc] initWithFrame:[self _toolbarViewFrame]];

        [_toolbarView setToolbar:self];
        [_toolbarView setAutoresizingMask:CPViewWidthSizable];
        [_toolbarView reloadToolbarItems];
    }

    return _toolbarView;
}

/* @ignore */
- (void)_reloadToolbarItems
{
    // As of OS X 10.5 (Leopard), toolbar items can be set in IB and a
    // toolbar delegate is optional. Toolbar items can be combined from
    // both IB and a delegate (see Apple's NSToolbar guide for IB, for more details).

    // _defaultItems may have been loaded from Cib
    _itemIdentifiers = [_defaultItems valueForKey:@"itemIdentifier"] || [];

    if ([_delegate respondsToSelector:@selector(toolbarDefaultItemIdentifiers:)])
    {
        var itemIdentifiersFromDelegate = [_delegate toolbarDefaultItemIdentifiers:self];

        // If we get items both from the Cib and from the delegate method, put the delegate items before the
        // Cib ones.
        if (itemIdentifiersFromDelegate)
            _itemIdentifiers = [itemIdentifiersFromDelegate arrayByAddingObjectsFromArray:_itemIdentifiers];
    }
    // If we didn't load from a cib and the delegate hasn't been set yet, we'll just work with an empty list
    // at this point.

    var index = 0,
        count = [_itemIdentifiers count];

    _items = [];

    for (; index < count; ++index)
    {
        var identifier = _itemIdentifiers[index],
            item = [CPToolbarItem _standardItemWithItemIdentifier:identifier];

        // May come from a Cib.
        if (!item)
            item = [_identifiedItems objectForKey:identifier];

        if (!item && _delegate)
            item = [_delegate toolbar:self itemForItemIdentifier:identifier willBeInsertedIntoToolbar:YES];

        item = [item copy];

        if (item === nil)
            [CPException raise:CPInvalidArgumentException
                         reason:@"Toolbar delegate " + _delegate + " returned nil toolbar item for identifier \"" + identifier + "\""];

        item._toolbar = self;

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
    Returns the toolbar items sorted by their \c visibilityPriority(ies).
*/
- (CPArray)itemsSortedByVisibilityPriority
{
    return _itemsSortedByVisibilityPriority;
}

/*!
    Validates the visible toolbar items by sending a validate message to
    each visible toolbar item.
*/
- (void)validateVisibleItems
{
    [self _validateVisibleItems:NO]
}

- (void)_autoValidateVisibleItems
{
    [self _validateVisibleItems:YES]
}

- (void)_validateVisibleItems:(BOOL)isAutovalidation
{
    var toolbarItems = [self visibleItems],
        count = [toolbarItems count];

    while (count--)
    {
        var item = [toolbarItems objectAtIndex:count];
        if (!isAutovalidation || [item autovalidates])
            [item validate];
    }
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
                            reason:@"Toolbar delegate " + _delegate + " returned nil toolbar item for identifier " + identifier];
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
- (id)_defaultToolbarItems
{
    if (!_defaultItems && [_delegate respondsToSelector:@selector(toolbarDefaultItemIdentifiers:)])
    {
        _defaultItems = [];

        var identifiers = [_delegate toolbarDefaultItemIdentifiers:self],
            index = 0,
            count = [identifiers count];

        for (; index < count; ++index)
            [_defaultItems addObject:[self _itemForItemIdentifier:identifiers[index] willBeInsertedIntoToolbar:NO]];
    }

    return _defaultItems;
}

/*!
    Notifies the toolbar that an item has been changed. This will cause the toolbar to reload its items.
    @param anItem the item that has been changed
*/
- (void)toolbarItemDidChange:(CPToolbarItem)anItem
{
    if ([_identifiedItems objectForKey:[anItem itemIdentifier]])
        [_identifiedItems setObject:anItem forKey:[anItem itemIdentifier]];

    var index = 0,
        count = [_items count];

    for (; index <= count; ++index)
    {
        var item = _items[index];

        if ([item itemIdentifier] === [anItem itemIdentifier])
        {
            _items[index] = anItem;
            _itemsSortedByVisibilityPriority = [_items sortedArrayUsingFunction:_CPToolbarItemVisibilityPriorityCompare context:NULL];

            [_toolbarView reloadToolbarItems];
        }
    }
}

@end


var CPToolbarIdentifierKey              = @"CPToolbarIdentifierKey",
    CPToolbarDisplayModeKey             = @"CPToolbarDisplayModeKey",
    CPToolbarShowsBaselineSeparatorKey  = @"CPToolbarShowsBaselineSeparatorKey",
    CPToolbarAllowsUserCustomizationKey = @"CPToolbarAllowsUserCustomizationKey",
    CPToolbarIsVisibleKey               = @"CPToolbarIsVisibleKey",
    CPToolbarDelegateKey                = @"CPToolbarDelegateKey",
    CPToolbarIdentifiedItemsKey         = @"CPToolbarIdentifiedItemsKey",
    CPToolbarDefaultItemsKey            = @"CPToolbarDefaultItemsKey",
    CPToolbarAllowedItemsKey            = @"CPToolbarAllowedItemsKey",
    CPToolbarSelectableItemsKey         = @"CPToolbarSelectableItemsKey",
    CPToolbarSizeModeKey                = @"CPToolbarSizeModeKey";

@implementation CPToolbar (CPCoding)

/*
    Initializes the toolbar by unarchiving data from \c aCoder.
    @param aCoder the coder containing the archived CPToolbar.
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _identifier = [aCoder decodeObjectForKey:CPToolbarIdentifierKey];
        _displayMode = [aCoder decodeIntForKey:CPToolbarDisplayModeKey];
        _showsBaselineSeparator = [aCoder decodeBoolForKey:CPToolbarShowsBaselineSeparatorKey];
        _allowsUserCustomization = [aCoder decodeBoolForKey:CPToolbarAllowsUserCustomizationKey];
        _isVisible = [aCoder decodeBoolForKey:CPToolbarIsVisibleKey];
        _sizeMode = [aCoder decodeIntForKey:CPToolbarSizeModeKey];

        _identifiedItems = [aCoder decodeObjectForKey:CPToolbarIdentifiedItemsKey];
        _defaultItems = [aCoder decodeObjectForKey:CPToolbarDefaultItemsKey];
        _allowedItems = [aCoder decodeObjectForKey:CPToolbarAllowedItemsKey];
        _selectableItems = [aCoder decodeObjectForKey:CPToolbarSelectableItemsKey];

        [[_identifiedItems allValues] makeObjectsPerformSelector:@selector(_setToolbar:) withObject:self];

        _items = [];

        [CPToolbar _addToolbar:self forIdentifier:_identifier];

        // This won't come from a Cib, but can come from manual encoding.
        [self setDelegate:[aCoder decodeObjectForKey:CPToolbarDelegateKey]];

        // Because we don't know if a delegate will be set later (it is optional
        // as of OS X 10.5), we need to call -_reloadToolbarItems here.
        // In order to load any toolbar items that may have been configured in the
        // Cib. Unfortunately this means that if there is a delegate
        // specified, it will be read later and the resulting call to -setDelegate:
        // will cause -_reloadToolbarItems] to run again :-(
        // FIXME: Can we make this better?

        // Do this at the end of the run loop to allow all the cib-stuff to
        // finish (establishing connections, etc.).
        [[CPRunLoop currentRunLoop]
            performSelector:@selector(_reloadToolbarItems)
                     target:self
                   argument:nil
                      order:0 modes:[CPDefaultRunLoopMode]];
    }

    return self;
}

/*
    Archives this toolbar into the provided coder.
    @param aCoder the coder to which the toolbar's instance data will be written.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_identifier forKey:CPToolbarIdentifierKey];
    [aCoder encodeInt:_displayMode forKey:CPToolbarDisplayModeKey];
    [aCoder encodeBool:_showsBaselineSeparator forKey:CPToolbarShowsBaselineSeparatorKey];
    [aCoder encodeBool:_allowsUserCustomization forKey:CPToolbarAllowsUserCustomizationKey];
    [aCoder encodeBool:_isVisible forKey:CPToolbarIsVisibleKey];
    [aCoder encodeInt:_sizeMode forKey:CPToolbarSizeModeKey]

    [aCoder encodeObject:_identifiedItems forKey:CPToolbarIdentifiedItemsKey];
    [aCoder encodeObject:_defaultItems forKey:CPToolbarDefaultItemsKey];
    [aCoder encodeObject:_allowedItems forKey:CPToolbarAllowedItemsKey];
    [aCoder encodeObject:_selectableItems forKey:CPToolbarSelectableItemsKey];

    [aCoder encodeConditionalObject:_delegate forKey:CPToolbarDelegateKey];
}

@end


var _CPToolbarViewBackgroundColor = nil,
    _CPToolbarViewExtraItemsImage = nil,
    _CPToolbarViewExtraItemsAlternateImage = nil;

var _CPToolbarItemInfoMake = function(anIndex, aView, aLabel, aMinWidth)
{
    return { index:anIndex, view:aView, label:aLabel, minWidth:aMinWidth };
};

/* @ignore */
@implementation _CPToolbarView : CPView
{
    CPToolbar           _toolbar;

    CPIndexSet          _flexibleWidthIndexes;
    CPIndexSet          _visibleFlexibleWidthIndexes;

    CPDictionary        _itemInfos;
    JSObject            _viewsForToolbarItems;

    CPArray             _visibleItems @accessors(readonly, property=visibleItems);
    CPArray             _invisibleItems;

    CPPopUpButton       _additionalItemsButton;
    CPColor             _labelColor;
    CPColor             _labelShadowColor;

    float               _minWidth;

    BOOL                _FIXME_isHUD;
}

+ (CPString)defaultThemeClass
{
    return @"toolbar-view";
}

+ (id)themeAttributes
{
    return @{
            @"item-margin": 10.0,
            @"extra-item-width": 20.0,
            @"extra-item-extra-image": [CPNull null],
            @"extra-item-extra-alternate-image": [CPNull null],
            @"content-inset": CGInsetMake(4.0, 4.0, 4.0, 10),
            @"regular-size-height": 59.0,
            @"small-size-height": 46.0,
            @"image-item-separator-color": [CPNull null],
            @"image-item-separator-size": CGRectMake(0.0, 0.0, 2.0, 32.0),
        };
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _minWidth = 0;

        _labelColor = [CPColor blackColor];
        _labelShadowColor = [CPColor colorWithWhite:1.0 alpha:0.75];

        _additionalItemsButton = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 15.0) pullsDown:YES];
        [_additionalItemsButton setBordered:NO];

        [_additionalItemsButton setImagePosition:CPImageOnly];
        [[_additionalItemsButton menu] setShowsStateColumn:NO];
        [[_additionalItemsButton menu] setAutoenablesItems:NO];
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

- (void)FIXME_setIsHUD:(BOOL)shouldBeHUD
{
    if (_FIXME_isHUD === shouldBeHUD)
        return;

    _FIXME_isHUD = shouldBeHUD;

    var items = [_toolbar items],
        count = [items count];

    while (count--)
        [[self viewForItem:items[count]] FIXME_setIsHUD:shouldBeHUD];
}

// This *should* be roughly O(3N) = O(N)
- (void)resizeSubviewsWithOldSize:(CGSize)aSize
{
    [self tile];
}

- (_CPToolbarItemView)viewForItem:(CPToolbarItem)anItem
{
    return _viewsForToolbarItems[[anItem UID]] || nil;
}

- (void)tile
{
    // We begin by recalculating the visible items.
    var items = [_toolbar items],
        itemsWidth = CGRectGetWidth([self bounds]),
        minWidth = _minWidth,
        // FIXME: This should be a CPSet.
        invisibleItemsSortedByPriority = [];

    _visibleItems = items;

    // We only have hidden items if our actual width is smaller than our
    // minimum width for hiding items.
    if (itemsWidth < minWidth)
    {
        itemsWidth -= [self valueForThemeAttribute:@"extra-item-width"];

        _visibleItems = [_visibleItems copy];

        var itemsSortedByVisibilityPriority = [_toolbar itemsSortedByVisibilityPriority],
            count = itemsSortedByVisibilityPriority.length;

        // Remove items until we fit:
        // The assumption here is that there are more visible items than there are
        // invisible items, if not it would be faster to add items until we *no
        // longer fit*.
        while (minWidth > itemsWidth && count)
        {
            var item = itemsSortedByVisibilityPriority[--count],
                view = [self viewForItem:item];

            minWidth -= [view minSize].width + [self valueForThemeAttribute:@"item-margin"];

            [_visibleItems removeObjectIdenticalTo:item];
            [invisibleItemsSortedByPriority addObject:item];

            [view setHidden:YES];
            [view FIXME_setIsHUD:_FIXME_isHUD];
        }
    }

    // FIXME: minHeight?
    var count = [items count],
        height = 0.0;

    while (count--)
    {
        var view = [self viewForItem:items[count]],
            minSize = [view minSize];

        if (height < minSize.height)
            height = minSize.height;
    }

    // We'll figure out the proper height for the toolbar depending on its items.
    // If nothing has a minimum size we'll use the standard toolbar size for the
    // sizeMode, indicated by a 0 _desiredHeight.
    var contentInset = [self valueForThemeAttribute:@"content-inset"],
        newDesiredHeight = height ? height + contentInset.top + contentInset.bottom : 0;

    if (newDesiredHeight != _toolbar._desiredHeight)
    {
        // FIXME Probably the toolbar view shouldn't be telling the toolbar which height it should be. Maybe refactor
        // to just have the toolbar scan the toolbar items whenever the items change.
        _toolbar._desiredHeight = newDesiredHeight;

        [self setFrame:[_toolbar _toolbarViewFrame]];
        [_toolbar._window _noteToolbarChanged];
        // The above will cause tile to be called again.
        return;
    }

    // Determine all the items that have flexible width.
    // Also determine the height of the toolbar.
    var count = _visibleItems.length,
        flexibleItemIndexes = [CPIndexSet indexSet];

    while (count--)
    {
        var item = _visibleItems[count],
            view = [self viewForItem:item],
            minSize = [view minSize];

        if (minSize.width !== [view maxSize].width)
            [flexibleItemIndexes addIndex:count];

        // FIXME: Is this still necessary? (probably not since we iterate them all below).
        // If the item doesn't have flexible width, then make sure it's set to the
        // static width (min==max). This handles the case where the user did setView:
        // with a view of a different size than minSize/maxSize
        else
            [view setFrameSize:CGSizeMake(minSize.width, height)];

        [view setHidden:NO];
    }

    var remainingSpace = itemsWidth - minWidth,
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

        while ((index = [flexibleItemIndexes indexGreaterThanIndex:index]) !== CPNotFound)
        {
            var item = _visibleItems[index],
                view = [self viewForItem:item],
                proposedWidth = [view minSize].width + proportionate,
                constrainedWidth = MIN(proposedWidth, [view maxSize].width);

            if (constrainedWidth < proposedWidth)
            {
                [flexibleItemIndexes removeIndex:index];

                remainingSpace += proposedWidth - constrainedWidth;
            }

            [view setFrameSize:CGSizeMake(constrainedWidth, height)];
        }
    }

    // Now that all the visible items are the correct width, give them their final frames.
    var index = 0,
        count = _visibleItems.length,
        x = contentInset.left,
        contentInset = [self valueForThemeAttribute:@"content-inset"],
        y = contentInset.top;

    for (; index < count; ++index)
    {
        var view = [self viewForItem:_visibleItems[index]],
            viewWidth = CGRectGetWidth([view frame]);

        [view setFrame:CGRectMake(x, y, viewWidth, height)];

        x += viewWidth + [self valueForThemeAttribute:@"item-margin"];
    }

    var needsAdditionalItemsButton = NO;

    if ([invisibleItemsSortedByPriority count])
    {
        var index = 0,
            count = [items count];

        _invisibleItems = [];

        for (; index < count; ++index)
        {
            var item = items[index];

            if ([invisibleItemsSortedByPriority indexOfObjectIdenticalTo:item] !== CPNotFound)
            {
                [_invisibleItems addObject:item];

                var identifier = [item itemIdentifier];

                if (identifier !== CPToolbarSpaceItemIdentifier &&
                    identifier !== CPToolbarFlexibleSpaceItemIdentifier &&
                    identifier !== CPToolbarSeparatorItemIdentifier)
                    needsAdditionalItemsButton = YES;
            }
        }
    }

    if (needsAdditionalItemsButton)
    {
        [_additionalItemsButton setFrameOrigin:CGPointMake(itemsWidth + 5.0, (CGRectGetHeight([self bounds]) - CGRectGetHeight([_additionalItemsButton frame])) / 2.0)];

        [self addSubview:_additionalItemsButton];

        [_additionalItemsButton removeAllItems];

        [_additionalItemsButton addItemWithTitle:@"Additional Items"];
        [[_additionalItemsButton itemArray][0] setImage:[self valueForThemeAttribute:@"extra-item-extra-image"]];

        var index = 0,
            count = [_invisibleItems count],
            hasNonSeparatorItem = NO;

        for (; index < count; ++index)
        {
            var item = _invisibleItems[index],
                identifier = [item itemIdentifier];

            if (identifier === CPToolbarSpaceItemIdentifier ||
                identifier === CPToolbarFlexibleSpaceItemIdentifier)
                continue;

            if (identifier === CPToolbarSeparatorItemIdentifier)
            {
                if (hasNonSeparatorItem)
                    [_additionalItemsButton addItem:[CPMenuItem separatorItem]];

                continue;
            }

            hasNonSeparatorItem = YES;

            var menuItem = [[CPMenuItem alloc] initWithTitle:[item label] action:@selector(didSelectMenuItem:) keyEquivalent:nil];

            [menuItem setRepresentedObject:item];
            [menuItem setImage:[item image]];
            [menuItem setTarget:self];
            [menuItem setEnabled:[item isEnabled]];

            [_additionalItemsButton addItem:menuItem];
        }
    }
    else
        [_additionalItemsButton removeFromSuperview];
}

/*
    Used privately.
    @ignore
*/

- (void)didSelectMenuItem:(id)aSender
{
    var toolbarItem = [aSender representedObject];

    [CPApp sendAction:[toolbarItem action] to:[toolbarItem target] from:toolbarItem];
}

- (void)reloadToolbarItems
{
    // Get rid of all our current subviews.
    var subviews = [self subviews],
        count = subviews.length;

    while (count--)
        [subviews[count] removeFromSuperview];

    // Populate with new subviews.
    var items = [_toolbar items],
        index = 0;

    count = items.length;

    _minWidth = [self valueForThemeAttribute:@"item-margin"];
    _viewsForToolbarItems = { };

    for (; index < count; ++index)
    {
        var item = items[index],
            view = [[_CPToolbarItemView alloc] initWithToolbarItem:item toolbar:self];

        _viewsForToolbarItems[[item UID]] = view;

        if ([item toolTip] && [view respondsToSelector:@selector(setToolTip:)])
            [view setToolTip:[item toolTip]];

        [self addSubview:view];

        _minWidth += [view minSize].width + [self valueForThemeAttribute:@"item-margin"];
    }

    [self tile];
}

- (void)layoutSubviews
{
    [_additionalItemsButton setAlternateImage:[self valueForThemeAttribute:@"extra-item-extra-alternate-image"]];
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
};

var LABEL_MARGIN    = 2.0;

@implementation _CPToolbarItemView : CPControl
{
    CGSize          _minSize @accessors(readonly, property=minSize);
    CGSize          _maxSize @accessors(readonly, property=maxSize);
    CGSize          _labelSize;

    CPToolbarItem   _toolbarItem;
    CPToolbar       _toolbar;

    CPImageView     _imageView;
    CPView          _view;

    CPTextField     _labelField;

    BOOL            _FIXME_isHUD;
}

- (id)initWithToolbarItem:(CPToolbarItem)aToolbarItem toolbar:(CPToolbar)aToolbar
{
    self = [super init];

    if (self)
    {
        _toolbarItem = aToolbarItem;

        _labelField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

        [_labelField setFont:[CPFont systemFontOfSize:11.0]];
        [_labelField setTextColor:[self FIXME_labelColor]];
        [_labelField setTextShadowColor:[self FIXME_labelShadowColor]];
        [_labelField setTextShadowOffset:CGSizeMake(0.0, 1.0)];
        [_labelField setAutoresizingMask:CPViewWidthSizable | CPViewMinXMargin];

        [self addSubview:_labelField];

        [self updateFromItem];

        _toolbar = aToolbar;

        var keyPaths = [@"label", @"image", @"alternateImage", @"minSize", @"maxSize", @"target", @"action", @"enabled"],
            index = 0,
            count = [keyPaths count];

        for (; index < count; ++index)
            [_toolbarItem
                addObserver:self
                 forKeyPath:keyPaths[index]
                    options:0
                    context:NULL];
    }

    return self;
}

- (void)FIXME_setIsHUD:(BOOL)shouldBeHUD
{
    _FIXME_isHUD = shouldBeHUD;
    [_labelField setTextColor:[self FIXME_labelColor]];
    [_labelField setTextShadowColor:[self FIXME_labelShadowColor]];
}

- (void)updateFromItem
{
    var identifier = [_toolbarItem itemIdentifier];

    if (identifier === CPToolbarSpaceItemIdentifier ||
        identifier === CPToolbarFlexibleSpaceItemIdentifier ||
        identifier === CPToolbarSeparatorItemIdentifier)
    {
        [_view removeFromSuperview];
        [_imageView removeFromSuperview];

        _minSize = [_toolbarItem minSize];
        _maxSize = [_toolbarItem maxSize];

        if (identifier === CPToolbarSeparatorItemIdentifier)
        {
            _view = [[CPView alloc] initWithFrame:CGRectMakeZero()];
            [self addSubview:_view];
        }

        return;
    }

    [self setTarget:[_toolbarItem target]];
    [self setAction:[_toolbarItem action]];

    var view = [_toolbarItem view] || nil;

    if (view !== _view)
    {
        if (!view)
            [_view removeFromSuperview];

        else
        {
            [self addSubview:view];
            [_imageView removeFromSuperview];
        }

        _view = view;
    }

    if (!_view)
    {
        if (!_imageView)
        {
            _imageView = [[CPImageView alloc] initWithFrame:[self bounds]];

            [_imageView setImageScaling:CPImageScaleProportionallyDown];

            [self addSubview:_imageView];
        }

        [_imageView setImage:[_toolbarItem image]];
    }

    var minSize = [_toolbarItem minSize],
        maxSize = [_toolbarItem maxSize];

    [_labelField setStringValue:[_toolbarItem label]];
    [_labelField sizeToFit]; // FIXME

    [self setEnabled:[_toolbarItem isEnabled]];

    _labelSize = [_labelField frame].size;

    var iconOnly = [[_toolbarItem toolbar] displayMode] === CPToolbarDisplayModeIconOnly,
        labelOnly = [[_toolbarItem toolbar] displayMode] === CPToolbarDisplayModeLabelOnly;
    [_labelField setHidden:iconOnly];
    [_view setHidden:labelOnly];

    _minSize = CGSizeMake(MAX(_labelSize.width, minSize.width), (labelOnly ? 0 : minSize.height) + (iconOnly ? 0 : _labelSize.height + LABEL_MARGIN));
    _maxSize = CGSizeMake(MAX(_labelSize.width, maxSize.width), 100000000.0);

    [_toolbar tile];
}

- (void)layoutSubviews
{
    var identifier = [_toolbarItem itemIdentifier];

    if (identifier === CPToolbarSpaceItemIdentifier ||
        identifier === CPToolbarFlexibleSpaceItemIdentifier)
        return;

    var bounds = [self bounds],
        width = CGRectGetWidth(bounds);

    if (identifier === CPToolbarSeparatorItemIdentifier)
    {
        var itemSeparatorColor = [_toolbar valueForThemeAttribute:@"image-item-separator-color"],
            itemSeparatorSize = [_toolbar valueForThemeAttribute:@"image-item-separator-size"];

        [_view setFrame:CGRectMake(ROUND((width - itemSeparatorSize.size.width) / 2.0), 0.0, itemSeparatorSize.size.width, CGRectGetHeight(bounds))];
        [_view setBackgroundColor:itemSeparatorColor];

        return;
    }

    // The view is centred in the available space above the label.
    var view = _view || _imageView,
        itemMaxSize = [_toolbarItem maxSize],
        iconOnly = [[_toolbarItem toolbar] displayMode] === CPToolbarDisplayModeIconOnly,
        height = CGRectGetHeight(bounds) - (iconOnly ? 0 : _labelSize.height),
        viewWidth = MIN(itemMaxSize.width, width),
        viewHeight =  MIN(itemMaxSize.height, height);

    [view setFrame:CGRectMake(ROUND((width - viewWidth) / 2.0),
                               ROUND((height - viewHeight) / 2.0),
                               viewWidth,
                               viewHeight)];

    // Label is always drawn at the bottom of the view. So if the view is really tall but the icon is tiny, the icon is centred above the label while the label remains on the bottom.
    [_labelField setFrameOrigin:CGPointMake(ROUND((width - _labelSize.width) / 2.0), CGRectGetHeight(bounds) - _labelSize.height)];
}

- (void)mouseDown:(CPEvent)anEvent
{
    if ([_toolbarItem view])
        return [[self nextResponder] mouseDown:anEvent];

    var identifier = [_toolbarItem itemIdentifier];

    if (identifier === CPToolbarSpaceItemIdentifier ||
        identifier === CPToolbarFlexibleSpaceItemIdentifier ||
        identifier === CPToolbarSeparatorItemIdentifier)
        return [[self nextResponder] mouseDown:anEvent];

    [super mouseDown:anEvent];
}

- (void)setEnabled:(BOOL)shouldBeEnabled
{
    // Tiling is very expensive so try to avoid it. The CPToolbarItem should already be careful to not notifying about its enabled state needlessly.
    if ([self isEnabled] === shouldBeEnabled)
        return;

    [super setEnabled:shouldBeEnabled];

    if (shouldBeEnabled)
    {
        [_imageView setAlphaValue:1.0];
        [_labelField setAlphaValue:1.0];
    }
    else
    {
        [_imageView setAlphaValue:0.5];
        [_labelField setAlphaValue:0.5];
    }

    [_toolbar tile];
}

- (CPColor)FIXME_labelColor
{
    if (_FIXME_isHUD)
        return [CPColor whiteColor];

    return [CPColor blackColor];
}

- (CPColor)FIXME_labelShadowColor
{
    if (_FIXME_isHUD)
        return [self isHighlighted] ? [CPColor colorWithWhite:1.0 alpha:0.5] : [CPColor clearColor];

    return [self isHighlighted] ? [CPColor colorWithWhite:0.0 alpha:0.3] : [CPColor colorWithWhite:1.0 alpha:0.75];
}

- (void)setHighlighted:(BOOL)shouldBeHighlighted
{
    [super setHighlighted:shouldBeHighlighted];

    if (shouldBeHighlighted)
    {
        var alternateImage = [_toolbarItem alternateImage];

        if (alternateImage)
            [_imageView setImage:alternateImage];

        [_labelField setTextShadowOffset:CGSizeMakeZero()];
    }
    else
    {
        var image = [_toolbarItem image];

        if (image)
            [_imageView setImage:image];

        [_labelField setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    }

    [_labelField setTextShadowColor:[self FIXME_labelShadowColor]];
}

- (void)sendAction:(SEL)anAction to:(id)aSender
{
    [CPApp sendAction:anAction to:aSender from:_toolbarItem];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath
                      ofObject:(id)anObject
                        change:(CPDictionary)aChange
                       context:(id)aContext
{
    if (aKeyPath === "enabled")
        [self setEnabled:[anObject isEnabled]];

    else if (aKeyPath === @"target")
        [self setTarget:[anObject target]];

    else if (aKeyPath === @"action")
        [self setAction:[anObject action]];

    else
        [self updateFromItem];
}

@end
