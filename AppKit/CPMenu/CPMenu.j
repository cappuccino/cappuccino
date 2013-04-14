/*
 * CPMenu.j
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
@import <Foundation/CPDictionary.j>
@import <Foundation/CPNotificationCenter.j>
@import <Foundation/CPString.j>

@import "CPKeyValueBinding.j"
@import "CPMenuItem.j"

@global CPApp

CPMenuDidAddItemNotification        = @"CPMenuDidAddItemNotification";
CPMenuDidChangeItemNotification     = @"CPMenuDidChangeItemNotification";
CPMenuDidRemoveItemNotification     = @"CPMenuDidRemoveItemNotification";

CPMenuDidEndTrackingNotification    = @"CPMenuDidEndTrackingNotification";

var _CPMenuBarVisible               = NO,
    _CPMenuBarTitle                 = @"",
    _CPMenuBarAttributes            = nil,
    _CPMenuBarSharedWindow          = nil;

/*!
    @ingroup appkit
    @class CPMenu

    Menus provide the user with a list of actions and/or submenus. Submenus themselves are full fledged menus
    and so a hierarchical structure appears.
*/
@implementation CPMenu : CPObject
{
    CPMenu          _supermenu;

    CPString        _title;
    CPString        _name;

    CPFont          _font;

    float           _minimumWidth;

    CPMutableArray  _items;

    BOOL            _autoenablesItems;
    BOOL            _showsStateColumn;

    id              _delegate;

    int             _highlightedIndex;
    _CPMenuWindow   _menuWindow;

    CPEvent         _lastCloseEvent;
}

// Managing the Menu Bar

+ (void)initialize
{
    if (self !== [CPMenu class])
        return;

    [[self class] setMenuBarAttributes:@{}];
}

+ (BOOL)menuBarVisible
{
    return _CPMenuBarVisible;
}

+ (void)setMenuBarVisible:(BOOL)menuBarShouldBeVisible
{
    if (_CPMenuBarVisible === menuBarShouldBeVisible)
        return;

    _CPMenuBarVisible = menuBarShouldBeVisible;

    if ([CPPlatform supportsNativeMainMenu])
        return;

    if (menuBarShouldBeVisible)
    {
        if (!_CPMenuBarSharedWindow)
            _CPMenuBarSharedWindow = [[_CPMenuBarWindow alloc] init];

        [_CPMenuBarSharedWindow setMenu:[CPApp mainMenu]];

        [_CPMenuBarSharedWindow setTitle:_CPMenuBarTitle];
        [_CPMenuBarSharedWindow setIconImage:[[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-icon-image" forClass:_CPMenuView]];
        [_CPMenuBarSharedWindow setIconImageAlphaValue:[[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-icon-image-alpha-value" forClass:_CPMenuView]];

        [_CPMenuBarSharedWindow setColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarBackgroundColor"]];
        [_CPMenuBarSharedWindow setTextColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarTextColor"]];
        [_CPMenuBarSharedWindow setTitleColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarTitleColor"]];
        [_CPMenuBarSharedWindow setTextShadowColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarTextShadowColor"]];
        [_CPMenuBarSharedWindow setTitleShadowColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarTitleShadowColor"]];
        [_CPMenuBarSharedWindow setHighlightColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarHighlightColor"]];
        [_CPMenuBarSharedWindow setHighlightTextColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarHighlightTextColor"]];
        [_CPMenuBarSharedWindow setHighlightTextShadowColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarHighlightTextShadowColor"]];

        [_CPMenuBarSharedWindow orderFront:self];
    }
    else
        [_CPMenuBarSharedWindow orderOut:self];

// FIXME: There must be a better way to do this.
#if PLATFORM(DOM)
    [[CPPlatformWindow primaryPlatformWindow] resizeEvent:nil];
#endif
}

+ (void)setMenuBarTitle:(CPString)aTitle
{
    _CPMenuBarTitle = aTitle;
    [_CPMenuBarSharedWindow setTitle:_CPMenuBarTitle];
}

+ (CPString)menuBarTitle
{
    return _CPMenuBarTitle;
}

+ (void)setMenuBarIconImage:(CPImage)anImage
{
    _CPMenuBarImage = anImage;
    [_CPMenuBarSharedWindow setIconImage:anImage];
}

+ (CPImage)menuBarIconImage
{
    return _CPMenuBarImage;
}

+ (void)_setOrRemoveMenuBarAttribute:(id)aValue forKey:(id)aKey
{
    if (aValue === nil)
        [_CPMenuBarAttributes removeObjectForKey:aKey];
    else
        [_CPMenuBarAttributes setObject:aValue forKey:aKey];
}

+ (void)setMenuBarAttributes:(CPDictionary)attributes
{
    if (_CPMenuBarAttributes == attributes)
        return;

    _CPMenuBarAttributes = [attributes copy];

    var textColor = [attributes objectForKey:@"CPMenuBarTextColor"],
        titleColor = [attributes objectForKey:@"CPMenuBarTitleColor"],
        textShadowColor = [attributes objectForKey:@"CPMenuBarTextShadowColor"],
        titleShadowColor = [attributes objectForKey:@"CPMenuBarTitleShadowColor"],
        highlightColor = [attributes objectForKey:@"CPMenuBarHighlightColor"],
        highlightTextColor = [attributes objectForKey:@"CPMenuBarHighlightTextColor"],
        highlightTextShadowColor = [attributes objectForKey:@"CPMenuBarHighlightTextShadowColor"];

    if (!textColor && titleColor)
        [_CPMenuBarAttributes setObject:titleColor forKey:@"CPMenuBarTextColor"];

    else if (textColor && !titleColor)
        [_CPMenuBarAttributes setObject:textColor forKey:@"CPMenuBarTitleColor"];

    else if (!textColor && !titleColor)
    {
        [self _setOrRemoveMenuBarAttribute:[[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-text-color" forClass:_CPMenuView] forKey:@"CPMenuBarTextColor"];
        [self _setOrRemoveMenuBarAttribute:[[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-title-color" forClass:_CPMenuView] forKey:@"CPMenuBarTitleColor"];
    }

    if (!textShadowColor && titleShadowColor)
        [_CPMenuBarAttributes setObject:titleShadowColor forKey:@"CPMenuBarTextShadowColor"];

    else if (textShadowColor && !titleShadowColor)
        [_CPMenuBarAttributes setObject:textShadowColor forKey:@"CPMenuBarTitleShadowColor"];

    else if (!textShadowColor && !titleShadowColor)
    {
        [self _setOrRemoveMenuBarAttribute:[[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-text-shadow-color" forClass:_CPMenuView] forKey:@"CPMenuBarTextShadowColor"];
        [self _setOrRemoveMenuBarAttribute:[[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-title-shadow-color" forClass:_CPMenuView] forKey:@"CPMenuBarTitleShadowColor"];
    }

    if (!highlightColor)
        [self _setOrRemoveMenuBarAttribute:[[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-highlight-color" forClass:_CPMenuView] forKey:@"CPMenuBarHighlightColor"];

    if (!highlightTextColor)
        [self _setOrRemoveMenuBarAttribute:[[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-highlight-text-color" forClass:_CPMenuView] forKey:@"CPMenuBarHighlightTextColor"];

    if (!highlightTextShadowColor)
        [self _setOrRemoveMenuBarAttribute:[[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-highlight-text-shadow-color" forClass:_CPMenuView] forKey:@"CPMenuBarHighlightTextShadowColor"];

    if (_CPMenuBarSharedWindow)
    {
        [_CPMenuBarSharedWindow setColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarBackgroundColor"]];
        [_CPMenuBarSharedWindow setTextColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarTextColor"]];
        [_CPMenuBarSharedWindow setTitleColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarTitleColor"]];
        [_CPMenuBarSharedWindow setTextShadowColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarTextShadowColor"]];
        [_CPMenuBarSharedWindow setTitleShadowColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarTitleShadowColor"]];
        [_CPMenuBarSharedWindow setHighlightColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarHighlightColor"]];
        [_CPMenuBarSharedWindow setHighlightTextColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarHighlightTextColor"]];
        [_CPMenuBarSharedWindow setHighlightTextShadowColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarHighlightTextShadowColor"]];
    }
}

+ (CPDictionary)menuBarAttributes
{
    return _CPMenuBarAttributes;
}

+ (void)_setMenuBarIconImageAlphaValue:(float)anAlphaValue
{
    _CPMenuBarIconImageAlphaValue = anAlphaValue;
    [_CPMenuBarSharedWindow setIconImageAlphaValue:anAlphaValue];
}

- (float)menuBarHeight
{
    if (self === [CPApp mainMenu])
        return [CPMenu menuBarHeight];

    return 0.0;
}

+ (float)menuBarHeight
{
    return [[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-height" forClass:_CPMenuView];
}

// Creating a CPMenu Object
/*!
    Initializes the menu with a specified title.
    @param aTile the menu title
    @return the initialized menu
*/
- (id)initWithTitle:(CPString)aTitle
{
    self = [super init];

    if (self)
    {
        _title = aTitle;
        _items = [];

        _autoenablesItems = YES;
        _showsStateColumn = YES;

        [self setMinimumWidth:0];
    }

    return self;
}

- (id)init
{
    return [self initWithTitle:@""];
}

// Setting Up Menu Commands
/*!
    Inserts a menu item at the specified index.
    @param aMenuItem the item to insert
    @param anIndex the index in the menu to insert the item.
*/
- (void)insertItem:(CPMenuItem)aMenuItem atIndex:(unsigned)anIndex
{
    [self insertObject:aMenuItem inItemsAtIndex:anIndex];
}

/*!
    Creates and inserts a new menu item with the specified attributes.
    @param aTitle the title of the menu item
    @param anAction the action initiated when the user selects the item
    @param aKeyEquivalent the keyboard shortcut for the item
    @param anIndex the index location in the menu for the new item
    @return the new menu item
*/
- (CPMenuItem)insertItemWithTitle:(CPString)aTitle action:(SEL)anAction keyEquivalent:(CPString)aKeyEquivalent atIndex:(unsigned)anIndex
{
    var item = [[CPMenuItem alloc] initWithTitle:aTitle action:anAction keyEquivalent:aKeyEquivalent];

    [self insertItem:item atIndex:anIndex];

    return item;
}

/*!
    Adds a menu item at the end of the menu.
    @param aMenuItem the menu item to add
*/
- (void)addItem:(CPMenuItem)aMenuItem
{
    [self insertItem:aMenuItem atIndex:[_items count]];
}

/*!
    Creates and adds a menu item with the specified attributes
    at the end of the menu.
    @param aTitle the title of the new menu item
    @param anAction the action initiated when the user selects the item
    @param aKeyEquivalent the keyboard shortcut for the menu item
    @return the new menu item
*/
- (CPMenuItem)addItemWithTitle:(CPString)aTitle action:(SEL)anAction keyEquivalent:(CPString)aKeyEquivalent
{
    return [self insertItemWithTitle:aTitle action:anAction keyEquivalent:aKeyEquivalent atIndex:[_items count]];
}

/*!
    Removes the specified item from the menu
    @param aMenuItem the item to remove
*/
- (void)removeItem:(CPMenuItem)aMenuItem
{
    [self removeItemAtIndex:[_items indexOfObjectIdenticalTo:aMenuItem]];
}

/*!
    Removes the item at the specified index from the menu
    @param anIndex the index of the item to remove
*/
- (void)removeItemAtIndex:(unsigned)anIndex
{
    [self removeObjectFromItemsAtIndex:anIndex];
}

/*!
    Removes all the menu items in the receiver.
    This method is more efficient than removing menu items individually.

    Unlike the other remove methods, this method does not post CPMenuDidChangeItemNotification notifications.
*/
- (void)removeAllItems
{
    var count = [_items count];

    // Remove the connection to this menu in case
    // someone else has a reference to the menu item.
    while (count--)
        [_items[count] setMenu:nil];

    [self _highlightItemAtIndex:CPNotFound];

    // Because we are changing _items directly, be sure to notify KVO
    [self willChangeValueForKey:@"items"];
    _items = [CPMutableArray array];
    [self didChangeValueForKey:@"items"];
}

/*!
    Called when a menu item has visually changed.
    @param aMenuItem the item that changed
*/
- (void)itemChanged:(CPMenuItem)aMenuItem
{
    /*
        During cib unarchiving, menu items will have a reference to their menu,
        but of course the items are still being unarchived and the menu's _items
        have not yet been instantiated. In that case we will not do anything here.
    */
    if ([aMenuItem menu] !== self || !_items)
        return;

    [aMenuItem setValue:[aMenuItem valueForKey:@"changeCount"] + 1 forKey:@"changeCount"];

    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPMenuDidChangeItemNotification
                      object:self
                    userInfo:@{ @"CPMenuItemIndex": [_items indexOfObjectIdenticalTo:aMenuItem] }];
}

// Finding Menu Items
/*!
    Returns the menu item with the specified tag
    @param the tag of the desired menu item
    @return the menu item or \c nil if a match was not found
*/
- (CPMenuItem)itemWithTag:(int)aTag
{
    var index = [self indexOfItemWithTag:aTag];

    if (index == CPNotFound)
        return nil;

    return _items[index];
}

/*!
    Returns the menu item with the specified title.
    @param aTitle the title of the menu item
    @return the menu item or \c nil if a match was not found
*/
- (CPMenuItem)itemWithTitle:(CPString)aTitle
{
    var index = [self indexOfItemWithTitle:aTitle];

    if (index == CPNotFound)
        return nil;

    return _items[index];
}

/*!
    Returns the menu item at the specified index
    @param anIndex the index of the requested item
*/
- (CPMenuItem)itemAtIndex:(int)anIndex
{
    return [_items objectAtIndex:anIndex];
}

/*!
    Returns the number of menu items in the menu
*/
- (unsigned)numberOfItems
{
    return [_items count];
}

/*!
    Returns the array of menu items backing this menu
*/
- (CPArray)itemArray
{
    return _items;
}

// Finding Indices of Menu Items
/*!
    Returns the index of the specified menu item
    @param aMenuItem the item to find the index for
    @return the item index or CPNotFound
*/
- (int)indexOfItem:(CPMenuItem)aMenuItem
{
    if ([aMenuItem menu] !== self)
        return CPNotFound;

    return [_items indexOfObjectIdenticalTo:aMenuItem];
}

/*!
    Returns the index of the item with the specified title.
    @param aTitle the desired title to match
    @return the index of the item or CPNotFound
*/
- (int)indexOfItemWithTitle:(CPString)aTitle
{
    var index = 0,
        count = _items.length;

    for (; index < count; ++index)
        if ([_items[index] title] === aTitle)
            return index;

    return CPNotFound;
}

/*!
    Returns the index of the item with the specified tag
    @param aTag the desired tag to match
    @return the index of the item or CPNotFound
*/
- (int)indexOfItemWithTag:(int)aTag
{
    var index = 0,
        count = _items.length;

    for (; index < count; ++index)
        if ([_items[index] tag] == aTag)
            return index;

    return CPNotFound;
}

/*!
    Returns the index of the item with the specified target and action.
    @param aTarget the target of the desired menu item
    @param anAction the action of the desired menu item
    @return the index of the item or CPNotFound
*/
- (int)indexOfItemWithTarget:(id)aTarget andAction:(SEL)anAction
{
    var index = 0,
        count = _items.length;

    for (; index < count; ++index)
    {
        var item = _items[index];

        if ([item target] == aTarget && (!anAction || [item action] == anAction))
            return index;
    }

    return CPNotFound;
}

/*!
    Returns the index of the menu item with the specified represented object.
    @param anObject the represented object of the desired item
    @return the index of the item or CPNotFound
*/
- (int)indexOfItemWithRepresentedObject:(id)anObject
{
    var index = 0,
        count = _items.length;

    for (; index < count; ++index)
        if ([[_items[index] representedObject] isEqual:anObject])
            return index;

    return CPNotFound;
}

/*!
    Returns the index of the item with the specified submenu.
    @param the submenu of the desired menu item
    @return the index of the item or CPNotFound
*/
- (int)indexOfItemWithSubmenu:(CPMenu)aMenu
{
    var index = 0,
        count = _items.length;

    for (; index < count; ++index)
        if ([_items[index] submenu] == aMenu)
            return index;

    return CPNotFound;
}

// Managing Submenus
/*!
    Sets a submenu for a menu item
    @param aMenu the submenu
    @param aMenuItem the menu item to set the submenu on
*/
- (void)setSubmenu:(CPMenu)aMenu forItem:(CPMenuItem)aMenuItem
{
    [aMenuItem setTarget:aMenuItem];
    [aMenuItem setAction:@selector(submenuAction:)];

    [aMenuItem setSubmenu:aMenu];
}

/*!
    The action method of menu items that open submenus.
    The default implementation does nothing, but it may
    be subclassed to provide different behavior.
    @param aSender the object that sent the message
*/
- (void)submenuAction:(id)aSender
{
}

/*!
    Returns the super menu or \c nil if there is none.
*/
- (CPMenu)supermenu
{
    return _supermenu;
}

/*!
    Sets the super menu.
    @param aMenu the new super menu
*/
- (void)setSupermenu:(CPMenu)aMenu
{
    _supermenu = aMenu;
}

/*!
    If there are two instances of this menu visible, return \c NO.
    Otherwise, return \c YES if we are a detached menu and visible.
*/
- (BOOL)isTornOff
{
    return !_supermenu /* || offscreen(?) */ || self == [CPApp mainMenu];
}

// Enabling and Disabling Menu Items
/*!
    Sets whether the menu automatically enables menu items.
    @param aFlag \c YES sets the menu to automatically enable items.
*/
- (void)setAutoenablesItems:(BOOL)aFlag
{
    _autoenablesItems = aFlag;
}

/*!
    Returns \c YES if the menu auto enables items.
*/
- (BOOL)autoenablesItems
{
    return _autoenablesItems;
}

/*!
    Enables or disables the receiver’s menu items.
    If the item has no target, an action binding is checked. If the target does not implement
    the menu item's action method or the binding's selector, the item is disabled.
    If the target responds to selector validateMenuItem: or validateUserInterfaceItem: (in that order) the return value is used.
*/
- (void)update
{
    if (![self autoenablesItems])
        return;

    var items = [self itemArray];

    for (var i = 0; i < [items count]; i++)
    {
        var item = [items objectAtIndex:i];

        if ([item hasSubmenu])
            continue;

        var validator = [CPApp targetForAction:[item action] to:[item target] from:item];

        if (!validator)
        {
            // If targetForAction: returns nil, it could be that there is no action.
            // If there is an action and nil is returned, no valid target could be found.
            if ([item action] || [item target])
                [item setEnabled:NO];
            else
            {
                // Check to see if there is a target binding with an invalid selector
                var info = [CPBinder infoForBinding:CPTargetBinding forObject:item];

                if (info)
                {
                    var object = [info objectForKey:CPObservedObjectKey],
                        keyPath = [info objectForKey:CPObservedKeyPathKey],
                        options = [info objectForKey:CPOptionsKey],
                        target = [object valueForKeyPath:keyPath],
                        selector = [options valueForKey:CPSelectorNameBindingOption];

                    if (target && selector && ![target respondsToSelector:CPSelectorFromString(selector)])
                        [item setEnabled:NO];
                }
            }
        }
        else if (![validator respondsToSelector:[item action]])
            [item setEnabled:NO];
        else if ([validator respondsToSelector:@selector(validateMenuItem:)])
            [item setEnabled:[validator validateMenuItem:item]];
        else if ([validator respondsToSelector:@selector(validateUserInterfaceItem:)])
            [item setEnabled:[validator validateUserInterfaceItem:item]];
    }

    [[_menuWindow _menuView] tile];
}

// Managing the Title
/*!
    Sets the menu title.
    @param the new title
*/
- (void)setTitle:(CPString)aTitle
{
    _title = aTitle;
}

/*!
    Returns the menu title
*/
- (CPString)title
{
    return _title;
}

- (void)setMinimumWidth:(float)aMinimumWidth
{
    _minimumWidth = aMinimumWidth;
}

- (float)minimumWidth
{
    return _minimumWidth;
}

- (void)_performActionOfHighlightedItemChain
{
    var highlightedItem = [self highlightedItem];

    while ([highlightedItem submenu] && [highlightedItem action] === @selector(submenuAction:))
        highlightedItem = [[highlightedItem submenu] highlightedItem];

    // FIXME: It is theoretically not necessarily to check isEnabled here since
    // highlightedItem is always enabled. Do there exist edge cases: disabling on closing a menu,
    // etc.? Requires further investigation and tests.
    if (highlightedItem && [highlightedItem isEnabled])
    {
        // Perform any action binding
        var binding = [CPBinder getBinding:CPTargetBinding forObject:highlightedItem];
        [binding invokeAction];

        [CPApp sendAction:[highlightedItem action] to:[highlightedItem target] from:highlightedItem];
    }
}

//
+ (CGRect)_constraintRectForView:(CPView)aView
{
    if ([CPPlatform isBrowser])
        return CGRectInset([[[aView window] platformWindow] contentBounds], 5.0, 5.0);

    return CGRectInset([[[aView window] screen] visibleFrame], 5.0, 5.0);
}

- (void)popUpMenuPositioningItem:(CPMenuItem)anItem atLocation:(CGPoint)aLocation inView:(CPView)aView callback:(Function)aCallback
{
    [self _popUpMenuPositioningItem:anItem
                         atLocation:aLocation
                               topY:aLocation.y
                            bottomY:aLocation.y
                             inView:aView
                           callback:aCallback];
}

- (void)_popUpMenuPositioningItem:(CPMenuItem)anItem atLocation:(CGPoint)aLocation topY:(float)aTopY bottomY:(float)aBottomY inView:(CPView)aView callback:(Function)aCallback
{
    var itemIndex = 0;

    if (anItem)
    {
        itemIndex = [self indexOfItem:anItem];

        if (itemIndex === CPNotFound)
            throw   "In call to popUpMenuPositioningItem:atLocation:inView:callback:, menu item " +
                    anItem  + " is not present in menu " + self;
    }

    var theWindow = [aView window];

    if (aView && !theWindow)
        throw "In call to popUpMenuPositioningItem:atLocation:inView:callback:, view is not in any window.";

    [self _menuWillOpen];

    // Convert location to global coordinates if not already in them.
    if (aView)
        aLocation = [theWindow convertBaseToGlobal:[aView convertPoint:aLocation toView:nil]];

    // Create the window for our menu.
    var menuWindow = [_CPMenuWindow menuWindowWithMenu:self font:[self font]];

    [menuWindow setBackgroundStyle:_CPMenuWindowPopUpBackgroundStyle];

    if (anItem)
        // Don't convert this value to global, we care about the distance (delta) from the
        // the edge of the window, which is equivalent to its origin.
        aLocation.y -= [menuWindow deltaYForItemAtIndex:itemIndex];

    // Grab the constraint rect for this view.
    var constraintRect = [CPMenu _constraintRectForView:aView];

    [menuWindow setFrameOrigin:aLocation];
    [menuWindow setConstraintRect:constraintRect];

    // If we aren't showing enough items, reposition the view in a better place.
    if (![menuWindow hasMinimumNumberOfVisibleItems])
    {
        var unconstrainedFrame = [menuWindow unconstrainedFrame],
            unconstrainedY = CGRectGetMinY(unconstrainedFrame);

        // If we scroll to early downwards, or are offscreen (!), move it up.
        if (unconstrainedY >= CGRectGetMaxY(constraintRect) || [menuWindow canScrollDown])
        {
            // Convert this to global if it isn't already.
            if (aView)
                aTopY = [theWindow convertBaseToGlobal:[aView convertPoint:CGPointMake(0.0, aTopY) toView:nil]].y;

            unconstrainedFrame.origin.y = MIN(CGRectGetMaxY(constraintRect), aTopY) - CGRectGetHeight(unconstrainedFrame);
        }

        // If we scroll to early upwards, or are offscreen (!), move it down.
        else if (unconstrainedY < CGRectGetMinY(constraintRect) || [menuWindow canScrollUp])
        {
            // Convert this to global if it isn't already.
            if (aView)
                aBottomY = [theWindow convertBaseToGlobal:[aView convertPoint:CGPointMake(0.0, aBottomY) toView:nil]].y;

            unconstrainedFrame.origin.y = MAX(CGRectGetMinY(constraintRect), aBottomY);
        }

        [menuWindow setFrameOrigin:CGRectIntersection(unconstrainedFrame, constraintRect).origin];
    }

    // Show it.
    if ([CPPlatform isBrowser])
        [menuWindow setPlatformWindow:[[aView window] platformWindow]];

    [menuWindow orderFront:self];

    // Track it.
    [[_CPMenuManager sharedMenuManager]
        beginTracking:[CPApp currentEvent]
        menuContainer:menuWindow
       constraintRect:constraintRect
             callback:[CPMenu trackingCallbackWithCallback:aCallback]];
}

+ (Function)trackingCallbackWithCallback:(Function)aCallback
{
    return function(aMenuWindow, aMenu)
    {
        [aMenuWindow setMenu:nil];
        [aMenuWindow orderOut:self];

        [_CPMenuWindow poolMenuWindow:aMenuWindow];

        if (aCallback)
            aCallback(aMenu);

        [aMenu _performActionOfHighlightedItemChain];
    }
}

+ (void)popUpContextMenu:(CPMenu)aMenu withEvent:(CPEvent)anEvent forView:(CPView)aView
{
    [self popUpContextMenu:aMenu withEvent:anEvent forView:aView withFont:nil];
}

+ (void)popUpContextMenu:(CPMenu)aMenu withEvent:(CPEvent)anEvent forView:(CPView)aView withFont:(CPFont)aFont
{
    [aMenu _menuWillOpen];

    if (!aFont)
        aFont = [CPFont systemFontOfSize:[CPFont systemFontSize]];

    var theWindow = [aView window],
        menuWindow = [_CPMenuWindow menuWindowWithMenu:aMenu font:aFont];

    [_CPMenuWindow poolMenuWindow:menuWindow];

    [menuWindow setBackgroundStyle:_CPMenuWindowPopUpBackgroundStyle];

    var constraintRect = [CPMenu _constraintRectForView:aView],
        aLocation = [[anEvent window] convertBaseToGlobal:[anEvent locationInWindow]];

    [menuWindow setConstraintRect:constraintRect];
    [menuWindow setFrameOrigin:aLocation];

    // If we aren't showing enough items, reposition the view in a better place.
    if (![menuWindow hasMinimumNumberOfVisibleItems])
    {
        var unconstrainedFrame = [menuWindow unconstrainedFrame],
            unconstrainedY = CGRectGetMinY(unconstrainedFrame);

        // If we scroll to early downwards, or are offscreen (!), move it up.
        if (unconstrainedY >= CGRectGetMaxY(constraintRect) || [menuWindow canScrollDown])
            unconstrainedFrame.origin.y = MIN(CGRectGetMaxY(constraintRect), aLocation.y) - CGRectGetHeight(unconstrainedFrame);

        // If we scroll to early upwards, or are offscreen (!), move it down.
        else if (unconstrainedY < CGRectGetMinY(constraintRect) || [menuWindow canScrollUp])
            unconstrainedFrame.origin.y = MAX(CGRectGetMinY(constraintRect), aLocation.y);

        [menuWindow setFrameOrigin:CGRectIntersection(unconstrainedFrame, constraintRect).origin];
    }

    if ([CPPlatform isBrowser])
        [menuWindow setPlatformWindow:[[aView window] platformWindow]];

    [menuWindow orderFront:self];

    [[_CPMenuManager sharedMenuManager]
        beginTracking:anEvent
        menuContainer:menuWindow
       constraintRect:[CPMenu _constraintRectForView:aView]
             callback:[CPMenu trackingCallbackWithCallback:nil]];
}

// Managing Display of State Column
/*!
    Sets whether to show the state column
    @param shouldShowStateColumn \c YES shows the state column
*/
- (void)setShowsStateColumn:(BOOL)shouldShowStateColumn
{
    _showsStateColumn = shouldShowStateColumn;
}

/*!
    Returns \c YES if the menu shows the state column
*/
- (BOOL)showsStateColumn
{
    return _showsStateColumn;
}

// Handling Highlighting
/*!
    Returns the currently highlighted menu item.
    @return the highlighted menu item or \c nil if no item is currently highlighted
*/
- (CPMenuItem)highlightedItem
{
    if (_highlightedIndex < 0)
        return nil;

    var highlightedItem = _items[_highlightedIndex];

    if ([highlightedItem isSeparatorItem])
        return nil;

    return highlightedItem;
}

// Managing the Delegate

- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}

- (id)delegate
{
    return _delegate;
}

- (void)_menuWillOpen
{
    var delegate = [self delegate];

    if ([delegate respondsToSelector:@selector(menuWillOpen:)])
        [delegate menuWillOpen:self];
}

- (void)_menuDidClose
{
    // Remember which event caused this menu to close, if any. CPPopUpButton uses this to detect
    // when a click on the button itself caused the menu to close.
    _lastCloseEvent = [CPApp currentEvent];

    var delegate = [self delegate];

    if ([delegate respondsToSelector:@selector(menuDidClose:)])
        [delegate menuDidClose:self];
}

// Handling Tracking
/*!
    Cancels tracking.
*/
- (void)cancelTracking
{
    [[CPRunLoop currentRunLoop] performSelector:@selector(_fireCancelTrackingEvent) target:self argument:nil order:0 modes:[CPDefaultRunLoopMode]];
}

- (void)_fireCancelTrackingEvent
{
    [CPApp sendEvent:[CPEvent
        otherEventWithType:CPAppKitDefined
                  location:CGPointMakeZero()
             modifierFlags:0
                 timestamp:0
              windowNumber:0
                   context:0
                   subtype:0
                     data1:0
                     data2:0]];

    // FIXME: We need to do this because this happens in a limitDateForMode:, thus
    // the second limitDateForMode: won't take effect and the perform selector that
    // actually draws also won't go into effect. In Safari this works because it sends
    // an additional mouse move after all this, but not in other browsers.
    // This will be fixed correctly with the coming run loop changes.
    [_CPDisplayServer run];
}

/* @ignore */
- (void)_setMenuWindow:(_CPMenuWindow)aMenuWindow
{
    _menuWindow = aMenuWindow;
}

- (void)setFont:(CPFont)aFont
{
    _font = aFont;
}

- (CPFont)font
{
    return _font;
}

/*!
    Initiates the action of the menu item that
    has a keyboard shortcut equivalent to \c anEvent
    @param anEvent the keyboard event
    @return \c YES if it was handled.
*/
- (BOOL)performKeyEquivalent:(CPEvent)anEvent
{
    if (_autoenablesItems)
        [self update];

    var index = 0,
        count = _items.length,
        characters = [anEvent charactersIgnoringModifiers],
        modifierFlags = [anEvent modifierFlags];

    for (; index < count; ++index)
    {
        var item = _items[index];

        if ([anEvent _triggersKeyEquivalent:[item keyEquivalent] withModifierMask:[item keyEquivalentModifierMask]])
        {
            if ([item isEnabled])
                [self performActionForItemAtIndex:index];
            else
            {
                //beep?
            }

            return YES;
        }

        if ([[item submenu] performKeyEquivalent:anEvent])
            return YES;
   }

   return NO;
}

// Simulating Mouse Clicks
/*!
    Sends the action of the menu item at the specified index.
    @param anIndex the index of the item
*/
- (void)performActionForItemAtIndex:(unsigned)anIndex
{
    var item = _items[anIndex];

    [CPApp sendAction:[item action] to:[item target] from:item];
}

//
/*
    @ignore
*/
- (void)_highlightItemAtIndex:(int)anIndex
{
    if (_highlightedIndex === anIndex)
        return;

    if (_highlightedIndex !== CPNotFound)
        [[_items[_highlightedIndex] _menuItemView] highlight:NO];

    _highlightedIndex = anIndex;

    if (_highlightedIndex !== CPNotFound)
        [[_items[_highlightedIndex] _menuItemView] highlight:YES];

    if (_highlightedIndex !== CPNotFound && _menuWindow)
        [_menuWindow._menuView scrollRectToVisible:[[_items[_highlightedIndex] _menuItemView] frame]];
}

- (void)_setMenuName:(CPString)aName
{
    if (_name === aName)
        return;

    _name = aName;

    if (_name === @"CPMainMenu")
        [CPApp setMainMenu:self];
}

- (CPString)_menuName
{
    return _name;
}

- (void)awakeFromCib
{
    if (_name === @"_CPMainMenu")
    {
        [self _setMenuName:@"CPMainMenu"];
        [CPMenu setMenuBarVisible:YES];
    }
}

- (void)_menuWithName:(CPString)aName
{
    if (aName === _name)
        return self;

    for (var i = 0, count = [_items count]; i < count; i++)
    {
        var menu = [[_items[i] submenu] _menuWithName:aName];

        if (menu)
            return menu;
    }

    return nil;
}

@end

@implementation CPMenu (CPKeyValueCoding)

- (CPUInteger)countOfItems
{
    return [_items count];
}

- (CPMenuItem)objectInItemsAtIndex:(CPUInteger)anIndex
{
    return [_items objectAtIndex:anIndex];
}

- (CPArray)itemsAtIndexes:(CPIndexSet)indexes
{
    return [_items objectsAtIndexes:indexes];
}

@end

@implementation CPMenu (CPKeyValueObserving)

- (void)insertObject:(CPMenuItem)aMenuItem inItemsAtIndex:(CPUInteger)anIndex
{
    var menu = [aMenuItem menu];

    if (menu)
        if (menu !== self)
            [CPException raise:CPInternalInconsistencyException reason:@"Attempted to insert item into menu that was already in another menu."];
        else
            return;

    [aMenuItem setMenu:self];
    [self _highlightItemAtIndex:CPNotFound];
    [_items insertObject:aMenuItem atIndex:anIndex];

    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPMenuDidAddItemNotification
                      object:self
                    userInfo:@{ @"CPMenuItemIndex": anIndex }];
}

- (void)removeObjectFromItemsAtIndex:(CPUInteger)anIndex
{
    if (anIndex < 0 || anIndex >= [_items count])
        return;

    [[_items objectAtIndex:anIndex] setMenu:nil];
    [self _highlightItemAtIndex:CPNotFound];
    [_items removeObjectAtIndex:anIndex];

    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPMenuDidRemoveItemNotification
                      object:self
                    userInfo:@{ @"CPMenuItemIndex": anIndex }];
}

@end

var CPMenuTitleKey              = @"CPMenuTitleKey",
    CPMenuNameKey               = @"CPMenuNameKey",
    CPMenuItemsKey              = @"CPMenuItemsKey",
    CPMenuShowsStateColumnKey   = @"CPMenuShowsStateColumnKey";

@implementation CPMenu (CPCoding)

/*!
    Initializes the menu with data from the specified coder.
    @param aCoder the coder from which to read the data
    @return the initialized menu
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _title = [aCoder decodeObjectForKey:CPMenuTitleKey];
        _items = [aCoder decodeObjectForKey:CPMenuItemsKey];

        [self _setMenuName:[aCoder decodeObjectForKey:CPMenuNameKey]];

        _showsStateColumn = ![aCoder containsValueForKey:CPMenuShowsStateColumnKey] || [aCoder decodeBoolForKey:CPMenuShowsStateColumnKey];

        _autoenablesItems = YES;

        [self setMinimumWidth:0];
    }

    return self;
}

/*!
    Encodes the data of the menu into a coder
    @param aCoder the coder to which the data will be written
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_title forKey:CPMenuTitleKey];

    if (_name)
        [aCoder encodeObject:_name forKey:CPMenuNameKey];

    [aCoder encodeObject:_items forKey:CPMenuItemsKey];

    if (!_showsStateColumn)
        [aCoder encodeBool:_showsStateColumn forKey:CPMenuShowsStateColumnKey];
}

@end

@import "_CPMenuBarWindow.j"
@import "_CPMenuWindow.j"

