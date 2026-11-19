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
@import "_CPToolbarCustomizationPalette.j"

@global CPApp

var CPToolbarDelegate_toolbar_itemForItemIdentifier_willBeInsertedIntoToolbar_  = 1 << 0,
    CPToolbarDelegate_toolbarAllowedItemIdentifiers_                            = 1 << 1,
    CPToolbarDelegate_toolbarDefaultItemIdentifiers_                            = 1 << 2,
    CPToolbarDelegate_toolbarDidRemoveItem_                                     = 1 << 3,
    CPToolbarDelegate_toolbarSelectableItemIdentifiers_                         = 1 << 4,
    CPToolbarDelegate_toolbarWillAddItem_                                       = 1 << 5;


@typedef CPToolbarDisplayMode
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

@typedef CPToolbarSizeMode
CPToolbarSizeModeDefault                = 0;
CPToolbarSizeModeRegular                = 1;
CPToolbarSizeModeSmall                  = 2;

/*!
    Posted before an item is added to a toolbar. The notification's object is the toolbar, and
    its user info holds the item under the key \c "item".
*/
CPToolbarWillAddItemNotification        = @"CPToolbarWillAddItemNotification";

/*!
    Posted after an item is removed from a toolbar. The notification's object is the toolbar,
    and its user info holds the item under the key \c "item".
*/
CPToolbarDidRemoveItemNotification      = @"CPToolbarDidRemoveItemNotification";

var CPToolbarsByIdentifier              = nil,
    CPToolbarConfigurationsByIdentifier = nil;

/*
    The keys of a configuration dictionary (see -configurationDictionary), as AppKit names them,
    and the prefix of the user defaults key under which an autosaving toolbar keeps its
    configuration.
*/
var CPToolbarConfigurationDisplayModeKey        = @"TB Display Mode",
    CPToolbarConfigurationSizeModeKey           = @"TB Size Mode",
    CPToolbarConfigurationIsShownKey            = @"TB Is Shown",
    CPToolbarConfigurationItemIdentifiersKey    = @"TB Item Identifiers",
    CPToolbarConfigurationDefaultsKeyPrefix     = @"CPToolbar Configuration ";


@protocol CPToolbarDelegate <CPObject>

@optional
- (CPToolbarItem)toolbar:(CPToolbar)toolbar itemForItemIdentifier:(CPString)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)toolbar;
- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)toolbar;
- (void)toolbarDidRemoveItem:(CPNotification)notification;
- (CPArray)toolbarSelectableItemIdentifiers:(CPToolbar)toolbar;
- (void)toolbarWillAddItem:(CPNotification)notification;

@end


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
    @param flag \c YES means the toolbar inserts the returned item itself, with its view. \c NO means the item will be
    displayed for some other purpose (non-functional)
    @return the toolbar item or \c nil if no such item belongs in the toolbar. Each toolbar expects an item of
    its own.
*/
@implementation CPToolbar : CPObject
{
    CPString                _identifier;
    CPToolbarDisplayMode    _displayMode                @accessors(property=displayMode);
    BOOL                    _showsBaselineSeparator;
    BOOL                    _allowsUserCustomization;
    BOOL                    _autosavesConfiguration;
    BOOL                    _isVisible;
    CPToolbarSizeMode       _sizeMode                   @accessors(property=sizeMode);
    int                     _desiredHeight;

    id <CPToolbarDelegate>  _delegate;
    unsigned                _implementedDelegateMethods;

    CPArray                 _itemIdentifiers;
    CPArray                 _configurationItemIdentifiers;

    CPDictionary            _identifiedItems;
    CPArray                 _defaultItems;
    CPArray                 _allowedItems;
    CPArray                 _selectableItems;

    CPArray                 _items;
    CPArray                 _itemsSortedByVisibilityPriority;

    CPView                  _toolbarView;
    CPWindow                _window;

    _CPToolbarCustomizationPalette  _customizationPalette;
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
        toolbarsSharingIdentifier = [];
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
    [self _autosaveConfiguration];
}

- (void)setSizeMode:(CPToolbarSizeMode)aSize
{
    if (aSize === _sizeMode)
        return;
    _sizeMode = aSize;

    [[self _toolbarView] setFrame:[self _toolbarViewFrame]];

    /*
        The item views size their images when they are made, so they are made again for the
        new size mode.
    */
    [_toolbarView reloadToolbarItems];
    [_window _noteToolbarChanged];

    [[self _toolbarsSharingConfiguration] makeObjectsPerformSelector:@selector(setSizeMode:) withObject:aSize];
    [self _autosaveConfiguration];
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
    _implementedDelegateMethods = 0;

    if ([_delegate respondsToSelector:@selector(toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:)])
        _implementedDelegateMethods |= CPToolbarDelegate_toolbar_itemForItemIdentifier_willBeInsertedIntoToolbar_;

    if ([_delegate respondsToSelector:@selector(toolbarAllowedItemIdentifiers:)])
        _implementedDelegateMethods |= CPToolbarDelegate_toolbarAllowedItemIdentifiers_;

    if ([_delegate respondsToSelector:@selector(toolbarDefaultItemIdentifiers:)])
        _implementedDelegateMethods |= CPToolbarDelegate_toolbarDefaultItemIdentifiers_;

    if ([_delegate respondsToSelector:@selector(toolbarDidRemoveItem:)])
        _implementedDelegateMethods |= CPToolbarDelegate_toolbarDidRemoveItem_;

    if ([_delegate respondsToSelector:@selector(toolbarSelectableItemIdentifiers:)])
        _implementedDelegateMethods |= CPToolbarDelegate_toolbarSelectableItemIdentifiers_;

    if ([_delegate respondsToSelector:@selector(toolbarWillAddItem:)])
        _implementedDelegateMethods |= CPToolbarDelegate_toolbarWillAddItem_;

    [self _reloadToolbarItems];
}

- (void)setDisplayMode:(CPToolbarDisplayMode)aDisplayMode
{
    if (_displayMode === aDisplayMode)
        return;
    _displayMode = aDisplayMode;

    [self _reloadToolbarItems];

    [[self _toolbarsSharingConfiguration] makeObjectsPerformSelector:@selector(setDisplayMode:) withObject:aDisplayMode];
    [self _autosaveConfiguration];
}

// MARK: Customization and configuration

/*!
    Returns \c YES if the user may customize the toolbar.
*/
- (BOOL)allowsUserCustomization
{
    return _allowsUserCustomization;
}

/*!
    Sets whether the user may customize the toolbar: add, remove and rearrange its items.
    @param aFlag \c YES allows customization
*/
- (void)setAllowsUserCustomization:(BOOL)aFlag
{
    _allowsUserCustomization = !!aFlag;
}

/*!
    Returns \c YES if the toolbar saves its configuration in the user defaults.
*/
- (BOOL)autosavesConfiguration
{
    return _autosavesConfiguration;
}

/*!
    Sets whether the toolbar saves its configuration in the user defaults whenever the
    configuration changes, under a key made from its identifier. When the flag becomes \c YES,
    the toolbar takes a configuration saved earlier, if there is one. A toolbar without an
    identifier saves nothing.
    @param aFlag \c YES saves the configuration
*/
- (void)setAutosavesConfiguration:(BOOL)aFlag
{
    aFlag = !!aFlag;

    if (_autosavesConfiguration === aFlag)
        return;

    _autosavesConfiguration = aFlag;

    if (_autosavesConfiguration)
        [self _loadConfiguration];
}

/*!
    Returns the toolbar's configuration: its display mode, size mode, visibility and item
    identifiers, under the keys that AppKit uses. The identifiers are those of the configuration
    the toolbar took, also one for which no item could be made yet, such as an item that the
    delegate gives once it is set.
*/
- (CPDictionary)configurationDictionary
{
    return @{
        CPToolbarConfigurationDisplayModeKey:       _displayMode || CPToolbarDisplayModeDefault,
        CPToolbarConfigurationSizeModeKey:          _sizeMode || CPToolbarSizeModeDefault,
        CPToolbarConfigurationIsShownKey:           _isVisible ? 1 : 0,
        CPToolbarConfigurationItemIdentifiersKey:   [_configurationItemIdentifiers || _itemIdentifiers || [] copy]
    };
}

/*!
    Sets the toolbar's configuration from a dictionary that -configurationDictionary returned.
    A key that the dictionary does not hold leaves that part of the configuration as it is.
    @param aDictionary the configuration
*/
- (void)setConfigurationFromDictionary:(CPDictionary)aDictionary
{
    var displayMode = [aDictionary objectForKey:CPToolbarConfigurationDisplayModeKey],
        sizeMode = [aDictionary objectForKey:CPToolbarConfigurationSizeModeKey],
        isShown = [aDictionary objectForKey:CPToolbarConfigurationIsShownKey],
        itemIdentifiers = [aDictionary objectForKey:CPToolbarConfigurationItemIdentifiersKey];

    if (displayMode != nil)
        _displayMode = displayMode;

    if (sizeMode != nil)
    {
        _sizeMode = sizeMode;
        [_toolbarView setFrame:[self _toolbarViewFrame]];
    }

    if (isShown != nil)
        _isVisible = !!isShown;

    if (itemIdentifiers)
        _configurationItemIdentifiers = [itemIdentifiers copy];

    [self _reloadToolbarItems];
    [_window _noteToolbarChanged];
    [self _autosaveConfiguration];
}

/*!
    Inserts the item with the identifier at the index. The toolbar makes the item as it makes
    its default items, and posts \c CPToolbarWillAddItemNotification before it adds the item.
    Every other toolbar with the same identifier makes the same change.
    @param anIdentifier the identifier of the item
    @param anIndex the index at which to insert the item
*/
- (void)insertItemWithItemIdentifier:(CPString)anIdentifier atIndex:(CPInteger)anIndex
{
    [self _insertItemWithItemIdentifier:anIdentifier atIndex:anIndex];

    [[self _toolbarsSharingConfiguration] enumerateObjectsUsingBlock:function(aToolbar)
    {
        [aToolbar _insertItemWithItemIdentifier:anIdentifier atIndex:anIndex];
    }];

    [self _autosaveConfiguration];
}

/*!
    Removes the item at the index, and posts \c CPToolbarDidRemoveItemNotification after it
    removes the item. Every other toolbar with the same identifier makes the same change.
    @param anIndex the index of the item
*/
- (void)removeItemAtIndex:(CPInteger)anIndex
{
    [self _removeItemAtIndex:anIndex];

    [[self _toolbarsSharingConfiguration] makeObjectsPerformSelector:@selector(_removeItemAtIndex:) withObject:anIndex];

    [self _autosaveConfiguration];
}

/* @ignore */
- (void)_insertItemWithItemIdentifier:(CPString)anIdentifier atIndex:(CPInteger)anIndex
{
    var item = [self _itemForInsertionWithItemIdentifier:anIdentifier];

    if (!item)
        [CPException raise:CPInvalidArgumentException
                    reason:@"Toolbar delegate " + _delegate + " returned nil toolbar item for identifier \"" + anIdentifier + "\""];

    anIndex = MAX(0, MIN(anIndex, [_items count]));

    var notification = [CPNotification notificationWithName:CPToolbarWillAddItemNotification object:self userInfo:@{ @"item": item }];

    [self _sendDelegateToolbarWillAddItem:notification];
    [[CPNotificationCenter defaultCenter] postNotification:notification];

    [_items insertObject:item atIndex:anIndex];
    _itemIdentifiers = [_items valueForKey:@"itemIdentifier"];
    _configurationItemIdentifiers = [_itemIdentifiers copy];

    [self _noteItemsChanged];
}

/* @ignore */
- (void)_removeItemAtIndex:(CPInteger)anIndex
{
    if (anIndex < 0 || anIndex >= [_items count])
        [CPException raise:CPRangeException reason:@"Index " + anIndex + " is beyond the toolbar's " + [_items count] + " items"];

    var item = _items[anIndex];

    [_items removeObjectAtIndex:anIndex];
    _itemIdentifiers = [_items valueForKey:@"itemIdentifier"];
    _configurationItemIdentifiers = [_itemIdentifiers copy];

    [self _noteItemsChanged];

    var notification = [CPNotification notificationWithName:CPToolbarDidRemoveItemNotification object:self userInfo:@{ @"item": item }];

    [self _sendDelegateToolbarDidRemoveItem:notification];
    [[CPNotificationCenter defaultCenter] postNotification:notification];
}

/* @ignore */
- (void)_noteItemsChanged
{
    _itemsSortedByVisibilityPriority = [_items sortedArrayUsingFunction:_CPToolbarItemVisibilityPriorityCompare context:NULL];

    [_toolbarView reloadToolbarItems];
}

/*
    Returns the other toolbars that share the receiver's configuration: those with the same
    identifier. Toolbars without an identifier share nothing.
    @ignore
*/
- (CPArray)_toolbarsSharingConfiguration
{
    if (![_identifier length])
        return [];

    return ([CPToolbarsByIdentifier objectForKey:_identifier] || []).filter(function(aToolbar)
    {
        return aToolbar !== self;
    });
}

/* @ignore */
- (CPString)_configurationDefaultsKey
{
    return CPToolbarConfigurationDefaultsKeyPrefix + _identifier;
}

/*
    Takes the configuration saved in the user defaults, if there is one.
    @ignore
*/
- (void)_loadConfiguration
{
    if (![_identifier length])
        return;

    var configuration = [[CPUserDefaults standardUserDefaults] objectForKey:[self _configurationDefaultsKey]];

    if (configuration)
        [self setConfigurationFromDictionary:configuration];
}

/*
    Saves the configuration in the user defaults when the toolbar autosaves.
    @ignore
*/
- (void)_autosaveConfiguration
{
    if (!_autosavesConfiguration || ![_identifier length])
        return;

    [[CPUserDefaults standardUserDefaults] setObject:[self configurationDictionary] forKey:[self _configurationDefaultsKey]];
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

    /*
        A configuration that the toolbar took, or that the user made by adding and removing
        items, gives the items in place of the default ones. An identifier for which no item can
        be made, such as one that a saved configuration still holds after the application
        dropped it, is left out.
    */
    var isConfigured = !!_configurationItemIdentifiers;

    _itemIdentifiers = isConfigured ? [_configurationItemIdentifiers copy] : [self _defaultItemIdentifiers];

    var index = 0,
        count = [_itemIdentifiers count];

    _items = [];

    for (; index < count; ++index)
    {
        var identifier = _itemIdentifiers[index],
            item = [self _itemForInsertionWithItemIdentifier:identifier];

        if (item == nil)
        {
            if (isConfigured)
                continue;

            [CPException raise:CPInvalidArgumentException
                         reason:@"Toolbar delegate " + _delegate + " returned nil toolbar item for identifier \"" + identifier + "\""];
        }

        [_items addObject:item];
    }

    _itemIdentifiers = [_items valueForKey:@"itemIdentifier"];

//    _items = [[self _defaultToolbarItems] mutableCopy];

    // Store items sorted by priority.  We want items to be removed first at the end of the array,
    // items to be removed last at the front.

    _itemsSortedByVisibilityPriority = [_items sortedArrayUsingFunction:_CPToolbarItemVisibilityPriorityCompare context:NULL];

    [_toolbarView reloadToolbarItems];
}

/*
    Returns the identifiers of the default items: those that the delegate gives, then those of
    the default items decoded from a cib. Without either, the list is empty.
    @ignore
*/
- (CPArray)_defaultItemIdentifiers
{
    // _defaultItems may have been loaded from Cib
    var identifiers = [_defaultItems valueForKey:@"itemIdentifier"] || [];

    if ([self _delegateRespondsToToolbarDefaultItemIdentifiers])
    {
        var itemIdentifiersFromDelegate = [self _sendDelegateToolbarDefaultItemIdentifiers];

        // If we get items both from the Cib and from the delegate method, put the delegate items before the
        // Cib ones.
        if (itemIdentifiersFromDelegate)
            identifiers = [itemIdentifiersFromDelegate arrayByAddingObjectsFromArray:identifiers];
    }

    return identifiers;
}

/*
    Returns the identifiers of the items the user may add: those that the delegate allows, then
    those of the allowed items decoded from a cib, each once.
    @ignore
*/
- (CPArray)_allowedItemIdentifiers
{
    var identifiers = [[self _sendDelegateToolbarAllowedItemIdentifiers] || [] copy],
        decoded = [_allowedItems valueForKey:@"itemIdentifier"] || [];

    for (var i = 0; i < decoded.length; i++)
        if ([identifiers indexOfObject:decoded[i]] === CPNotFound)
            [identifiers addObject:decoded[i]];

    return identifiers;
}

/*
    Returns an item to show in the customization palette for the identifier, or nil. The
    toolbar does not insert it, so the delegate is asked for an item not to be inserted.
    @ignore
*/
- (CPToolbarItem)_paletteItemForItemIdentifier:(CPString)anIdentifier
{
    return [CPToolbarItem _standardItemWithItemIdentifier:anIdentifier] ||
           [_identifiedItems objectForKey:anIdentifier] ||
           [self _sendDelegateItemForItemIdentifier:anIdentifier willBeInsertedIntoToolbar:NO];
}

/*!
    Runs the customization palette: a sheet on the toolbar's window from which the user drags
    items into, within and out of the toolbar. It runs only when the toolbar allows
    customization, is in a window and has no palette running; it shows a hidden toolbar.
    @param aSender the object that sent the message
*/
- (void)runCustomizationPalette:(id)aSender
{
    if (!_allowsUserCustomization || !_window || _customizationPalette)
        return;

    [self setVisible:YES];

    _customizationPalette = [[_CPToolbarCustomizationPalette alloc] initWithToolbar:self];
    [_customizationPalette run];
}

/*!
    Returns \c YES while the toolbar's customization palette runs.
*/
- (BOOL)customizationPaletteIsRunning
{
    return !!_customizationPalette;
}

/* @ignore */
- (void)_customizationPaletteDidEnd
{
    _customizationPalette = nil;
    [self validateVisibleItems];
}

/*
    Returns the item to insert for the identifier: a standard item, an item decoded from a cib,
    or the item the delegate gives for insertion; nil when there is none.
    @ignore
*/
- (CPToolbarItem)_itemForInsertionWithItemIdentifier:(CPString)identifier
{
    var item = [CPToolbarItem _standardItemWithItemIdentifier:identifier];

    // May come from a Cib.
    if (!item)
        item = [_identifiedItems objectForKey:identifier];

    if (!item && _delegate)
        item = [self _sendDelegateItemForItemIdentifier:identifier willBeInsertedIntoToolbar:YES];

    if (!item)
        return nil;

        /*
            The toolbar copied every item before it inserted it, also the item that the delegate
            returned for insertion and the item decoded from a cib. A copy archives and unarchives
            the item's view, so the toolbar showed a decoded copy: the application's references
            reached an item and a view that were never shown, and the copy lost its target. AppKit
            inserts the item that it receives. An item already placed in this reload or shown by
            another toolbar is still copied, because a view has only one superview.
        */
    if ([self _isItemInUse:item])
        item = [item copy];

    item._toolbar = self;

    return item;
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

/*
    Returns YES when the receiver has already placed the item in the current reload, or when
    another toolbar shows the item.
    @ignore
*/
- (BOOL)_isItemInUse:(CPToolbarItem)anItem
{
    if ([_items indexOfObjectIdenticalTo:anItem] !== CPNotFound)
        return YES;

    var owner = [anItem toolbar];

    if (!owner || owner === self)
        return NO;

    return [[owner items] indexOfObjectIdenticalTo:anItem] !== CPNotFound;
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
            item = [[self _sendDelegateItemForItemIdentifier:identifier willBeInsertedIntoToolbar:toolbar] copy];
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
    return [identifiers arrayByApplyingBlock:function(identifier)
    {
        return [self _itemForItemIdentifier:identifier willBeInsertedIntoToolbar:NO];
    }];
}

/* @ignore */
- (id)_defaultToolbarItems
{
    if (!_defaultItems && [self _delegateRespondsToToolbarDefaultItemIdentifiers])
    {
        _defaultItems = [];

        var identifiers = [self _sendDelegateToolbarDefaultItemIdentifiers],
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
    CPToolbarAutosavesConfigurationKey  = @"CPToolbarAutosavesConfigurationKey",
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
        _autosavesConfiguration = [aCoder decodeBoolForKey:CPToolbarAutosavesConfigurationKey];

        _identifiedItems = [aCoder decodeObjectForKey:CPToolbarIdentifiedItemsKey];
        _defaultItems = [aCoder decodeObjectForKey:CPToolbarDefaultItemsKey];
        _allowedItems = [aCoder decodeObjectForKey:CPToolbarAllowedItemsKey];
        _selectableItems = [aCoder decodeObjectForKey:CPToolbarSelectableItemsKey];

        [[_identifiedItems allValues] makeObjectsPerformSelector:@selector(_setToolbar:) withObject:self];

        _items = [];

        [CPToolbar _addToolbar:self forIdentifier:_identifier];

        if (_autosavesConfiguration)
            [self _loadConfiguration];

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
    [aCoder encodeBool:_autosavesConfiguration forKey:CPToolbarAutosavesConfigurationKey];
    [aCoder encodeBool:_isVisible forKey:CPToolbarIsVisibleKey];
    [aCoder encodeInt:_sizeMode forKey:CPToolbarSizeModeKey];

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

    CPView              _customizationOverlay;

    CPArray             _visibleItems @accessors(readonly, property=visibleItems);
    CPArray             _invisibleItems;

    CPPopUpButton       _additionalItemsButton;

    float               _minWidth;
}

+ (CPString)defaultThemeClass
{
    return @"toolbar-view";
}

+ (CPDictionary)themeAttributes
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
            @"label-color": [CPColor labelColor],
            @"label-font": [CPFont systemFontOfSize:11.0],
            @"label-shadow-color": [CPNull null],
            @"label-shadow-offset": CGSizeMakeZero(),
        };
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _minWidth = 0;

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
    /*
        The old item views kept observing their items after a reload. Each item was a new copy,
        so nothing else used the items they observed. The toolbar now keeps an item across a
        reload, and an old view would still update with it. The old views now stop observing.
    */
    for (var UID in _viewsForToolbarItems)
        [_viewsForToolbarItems[UID] _stopObservingToolbarItem];

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

    if (_customizationOverlay)
        [self addSubview:_customizationOverlay];
}

/*
    Lays aView over the items while the customization palette runs, or removes the view laid
    earlier when aView is nil. A reload of the items keeps the view on top.
    @ignore
*/
- (void)_setCustomizationOverlay:(CPView)aView
{
    [_customizationOverlay removeFromSuperview];

    _customizationOverlay = aView;

    if (_customizationOverlay)
    {
        [_customizationOverlay setFrame:[self bounds]];
        [self addSubview:_customizationOverlay];
    }
}

- (void)layoutSubviews
{
    [_additionalItemsButton setAlternateImage:[self valueForThemeAttribute:@"extra-item-extra-alternate-image"]];
}

@end

/* @ignore */
var _CPToolbarItemViewObservedKeyPaths = [@"label", @"image", @"alternateImage", @"minSize", @"maxSize", @"target", @"action", @"enabled"];

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

var LABEL_MARGIN    = 2.0,
    _CPToolbarSmallSizeScale = 24.0 / 32.0;

@implementation _CPToolbarItemView : CPControl
{
    CGSize          _minSize @accessors(readonly, property=minSize);
    CGSize          _maxSize @accessors(readonly, property=maxSize);
    CGSize          _labelSize;

    CPToolbarItem   _toolbarItem;
    CPToolbar       _toolbar;

    CPImageView     _imageView;
    CPView          _view;
    CPView          _highlightView;

    CPTextField     _labelField;
}

- (BOOL)acceptsFirstResponder
{
    if (_view && [_view acceptsFirstResponder])
        return YES;

     return NO;
}

- (BOOL)becomeFirstResponder
{
    if (_view && [_view acceptsFirstResponder])
        return [[self window] makeFirstResponder:_view];

    return [super becomeFirstResponder];
}

- (id)initWithToolbarItem:(CPToolbarItem)aToolbarItem toolbar:(CPToolbar)aToolbar
{
    self = [super init];

    if (self)
    {
        _toolbarItem = aToolbarItem;

        _labelField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

        /*
            The font sets the label size, which -updateFromItem measures below, before the
            toolbar view is assigned. Colour and shadow follow in -layoutSubviews.
        */
        [_labelField setFont:[aToolbar valueForThemeAttribute:@"label-font" inState:[self themeState]]];
        [_labelField setAutoresizingMask:CPViewWidthSizable | CPViewMinXMargin];

        [self addSubview:_labelField];

        [self updateFromItem];

        _toolbar = aToolbar;

        var index = 0,
            count = [_CPToolbarItemViewObservedKeyPaths count];

        for (; index < count; ++index)
            [_toolbarItem
                addObserver:self
                 forKeyPath:_CPToolbarItemViewObservedKeyPaths[index]
                    options:0
                    context:NULL];
    }

    return self;
}

/*
    Ends the observation of the item when the toolbar view discards the receiver.
    @ignore
*/
- (void)_stopObservingToolbarItem
{
    var index = 0,
        count = [_CPToolbarItemViewObservedKeyPaths count];

    for (; index < count; ++index)
        [_toolbarItem removeObserver:self forKeyPath:_CPToolbarItemViewObservedKeyPaths[index]];
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

    var minSize = [self _sizeForSizeMode:[_toolbarItem minSize]],
        maxSize = [self _sizeForSizeMode:[_toolbarItem maxSize]];

    if (_toolbar)
        [_labelField setFont:[_toolbar valueForThemeAttribute:@"label-font" inState:[self themeState]]];

    [_labelField setStringValue:[_toolbarItem label]];
    [_labelField sizeToFit]; // FIXME

    [self setEnabled:[_toolbarItem isEnabled]];

    _labelSize = [_labelField frame].size;

    var iconOnly = [[_toolbarItem toolbar] displayMode] === CPToolbarDisplayModeIconOnly,
        labelOnly = [[_toolbarItem toolbar] displayMode] === CPToolbarDisplayModeLabelOnly;
    [_labelField setHidden:iconOnly];

    /*
        Text Only hid an item's own view but not its image, so an image item kept its image, and
        an item whose image had no room showed a dot above its label.
    */
    [_view || _imageView setHidden:labelOnly];

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
        itemMaxSize = [self _sizeForSizeMode:[_toolbarItem maxSize]],
        iconOnly = [[_toolbarItem toolbar] displayMode] === CPToolbarDisplayModeIconOnly,
        height = CGRectGetHeight(bounds) - (iconOnly ? 0 : _labelSize.height),
        viewWidth = MIN(itemMaxSize.width, width),
        viewHeight =  MIN(itemMaxSize.height, height);

    [view setFrame:CGRectMake(ROUND((width - viewWidth) / 2.0),
                               ROUND((height - viewHeight) / 2.0),
                               viewWidth,
                               viewHeight)];

    [self _layoutLabelAppearance];

    // Label is always drawn at the bottom of the view. So if the view is really tall but the icon is tiny, the icon is centred above the label while the label remains on the bottom.
    [_labelField setFrameOrigin:CGPointMake(ROUND((width - _labelSize.width) / 2.0), CGRectGetHeight(bounds) - _labelSize.height)];
}

/*
    Returns aSize for the toolbar's size mode. In the small size mode an image item takes AppKit's
    small toolbar image, 24 points against 32, so its size scales by three quarters. Small size
    lowered the toolbar but left every image at its full size, so the toolbar looked the same. An
    item with a view of its own keeps its size.
    @ignore
*/
- (CGSize)_sizeForSizeMode:(CGSize)aSize
{
    if ([_toolbarItem view] || [[_toolbarItem toolbar] sizeMode] !== CPToolbarSizeModeSmall)
        return aSize;

    return CGSizeMake(ROUND(aSize.width * _CPToolbarSmallSizeScale), ROUND(aSize.height * _CPToolbarSmallSizeScale));
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

    /*
        The label takes its disabled look from the toolbar view's theme in -layoutSubviews.
    */
    [_imageView setAlphaValue:shouldBeEnabled ? 1.0 : 0.5];

    [_toolbar tile];
}

/*
    Applies the label colour and shadow of the toolbar view's theme for the receiver's state:
    highlighted, disabled, and HUD in a HUD window.

    Labels had black text and a white shadow, hard-coded in this class, so they ignored the
    theme and the appearance; the shadow was wrong in dark mode. The values now come from the
    toolbar view's theme attributes, applied in layout, and no theme gives a shadow.
*/
- (void)_layoutLabelAppearance
{
    var state = [self themeState];

    [_labelField setTextColor:[_toolbar valueForThemeAttribute:@"label-color" inState:state]];
    [_labelField setTextShadowColor:[_toolbar valueForThemeAttribute:@"label-shadow-color" inState:state]];
    [_labelField setTextShadowOffset:[_toolbar valueForThemeAttribute:@"label-shadow-offset" inState:state]];
}

- (void)setHighlighted:(BOOL)shouldBeHighlighted
{
    [super setHighlighted:shouldBeHighlighted];

    if (shouldBeHighlighted)
    {
        var alternateImage = [_toolbarItem alternateImage];

        if (alternateImage)
            [_imageView setImage:alternateImage];
        else
        {
            if (!_highlightView)
            {
                _highlightView = [[CPView alloc] initWithFrame:[_imageView bounds]];
                [_highlightView setBackgroundColor:[CPColor blackColor]];
                [_highlightView setAlphaValue:0.3];
                [_highlightView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
            }

            [_imageView addSubview:_highlightView];
        }

    }
    else
    {
        var image = [_toolbarItem image];

        if (image)
            [_imageView setImage:image];

        [_highlightView removeFromSuperview];
    }
}

- (BOOL)sendAction:(SEL)anAction to:(id)aSender
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


@implementation CPToolbar (CPToolbarDelegate)

/*
    @ignore
    Return YES if the delegate implements toolbarDefaultItemIdentifiers:
*/
- (BOOL)_delegateRespondsToToolbarDefaultItemIdentifiers
{
    return _implementedDelegateMethods & CPToolbarDelegate_toolbarDefaultItemIdentifiers_;
}

/*!
    @ignore
    Call the delegate toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:
*/
- (CPToolbarItem)_sendDelegateItemForItemIdentifier:(CPString)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    if (!(_implementedDelegateMethods & CPToolbarDelegate_toolbar_itemForItemIdentifier_willBeInsertedIntoToolbar_))
        return nil;

    return [_delegate toolbar:self itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
}

/*!
    @ignore
    Call the delegate toolbarAllowedItemIdentifiers:
*/
- (CPArray)_sendDelegateToolbarAllowedItemIdentifiers
{
    if (!(_implementedDelegateMethods & CPToolbarDelegate_toolbarAllowedItemIdentifiers_))
        return [];

    return [_delegate toolbarAllowedItemIdentifiers:self];
}

/*!
    @ignore
    Call the delegate toolbarDefaultItemIdentifiers:
*/
- (CPArray)_sendDelegateToolbarDefaultItemIdentifiers
{
    if (!(_implementedDelegateMethods & CPToolbarDelegate_toolbarDefaultItemIdentifiers_))
        return [];

    return [_delegate toolbarDefaultItemIdentifiers:self];
}

/*!
    @ignore
    Call the delegate toolbarDidRemoveItem:
*/
- (void)_sendDelegateToolbarDidRemoveItem:(CPNotification)notification
{
    /*
        The test read the delegate object instead of the flags of the methods it implements, so
        the delegate never received the notification.
    */
    if (!(_implementedDelegateMethods & CPToolbarDelegate_toolbarDidRemoveItem_))
        return;

    [_delegate toolbarDidRemoveItem:notification];
}

/*!
    @ignore
    Call the delegate toolbarSelectableItemIdentifiers:
*/
- (CPArray)_sendDelegateToolbarSelectableItemIdentifiers
{
    if (!(_implementedDelegateMethods & CPToolbarDelegate_toolbarSelectableItemIdentifiers_))
        return [];

    return [_delegate toolbarSelectableItemIdentifiers:self];
}

/*!
    @ignore
    Call the delegate toolbarWillAddItem:
*/
- (void)_sendDelegateToolbarWillAddItem:(CPNotification)notification
{
    if (!(_implementedDelegateMethods & CPToolbarDelegate_toolbarWillAddItem_))
        return;

    [_delegate toolbarWillAddItem:notification];
}

@end
