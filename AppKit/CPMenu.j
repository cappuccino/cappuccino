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

@import "CPApplication.j"
@import "CPClipView.j"
@import "CPMenuItem.j"
@import "CPPanel.j"

#include "Platform/Platform.h"


CPMenuDidAddItemNotification        = @"CPMenuDidAddItemNotification";
CPMenuDidChangeItemNotification     = @"CPMenuDidChangeItemNotification";
CPMenuDidRemoveItemNotification     = @"CPMenuDidRemoveItemNotification";

CPMenuDidEndTrackingNotification    = @"CPMenuDidEndTrackingNotification";

var MENUBAR_HEIGHT = 19.0;

var _CPMenuBarVisible               = NO,
    _CPMenuBarTitle                 = @"",
    _CPMenuBarIconImage             = nil,
    _CPMenuBarIconImageAlphaValue   = 1.0,
    _CPMenuBarAttributes            = nil,
    _CPMenuBarSharedWindow          = nil;

/*! @class CPMenu

    Menus provide the user with a list of actions and/or submenus. Submenus themselves are full fledged menus and so a heirarchical structure appears.
*/
@implementation CPMenu : CPObject
{
    CPString        _title;
    
    CPMutableArray  _items;
    CPMenu          _attachedMenu;
    
    BOOL            _autoenablesItems;
    BOOL            _showsStateColumn;
    
    id              _delegate;
    
    CPMenuItem      _highlightedIndex;
    _CPMenuWindow   _menuWindow;
}

// Managing the Menu Bar

+ (BOOL)menuBarVisible
{
    return _CPMenuBarVisible;
}

+ (void)setMenuBarVisible:(BOOL)menuBarShouldBeVisible
{
    if (_CPMenuBarVisible == menuBarShouldBeVisible)
        return;
    
    _CPMenuBarVisible = menuBarShouldBeVisible;
    
    if (menuBarShouldBeVisible)
    {
        if (!_CPMenuBarSharedWindow)
            _CPMenuBarSharedWindow = [[_CPMenuBarWindow alloc] init];
        
        [_CPMenuBarSharedWindow setMenu:[CPApp mainMenu]];
        
        [_CPMenuBarSharedWindow setTitle:_CPMenuBarTitle];
        [_CPMenuBarSharedWindow setIconImage:_CPMenuBarIconImage];
        [_CPMenuBarSharedWindow setIconImageAlphaValue:_CPMenuBarIconImageAlphaValue];
        
        [_CPMenuBarSharedWindow setColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarBackgroundColor"]];
        [_CPMenuBarSharedWindow setTextColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarTextColor"]];
        [_CPMenuBarSharedWindow setTitleColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarTitleColor"]];
        
        [_CPMenuBarSharedWindow orderFront:self];
    }
    else
        [_CPMenuBarSharedWindow orderOut:self];
        
// FIXME: There must be a better way to do this.
#if PLATFORM(DOM)
    [[CPDOMWindowBridge sharedDOMWindowBridge] _bridgeResizeEvent:nil];
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

+ (void)setMenuBarAttributes:(CPDictionary)attributes
{
    if (_CPMenuBarAttributes == attributes)
        return;
        
    _CPMenuBarAttributes = [attributes copy];
    
    var textColor = [attributes objectForKey:@"CPMenuBarTextColor"],
        titleColor = [attributes objectForKey:@"CPMenuBarTitleColor"];
    
    if (!textColor && titleColor)
        [_CPMenuBarAttributes setObject:titleColor forKey:@"CPMenuBarTextColor"];
    
    else if (textColor && !titleColor)
        [_CPMenuBarAttributes setObject:textColor forKey:@"CPMenuBarTitleColor"];
    
    else if (!textColor && !titleColor)
    {
        [_CPMenuBarAttributes setObject:[CPColor blackColor] forKey:@"CPMenuBarTextColor"];
        [_CPMenuBarAttributes setObject:[CPColor blackColor] forKey:@"CPMenuBarTitleColor"];
    }
    
    if (_CPMenuBarSharedWindow)
    {
        [_CPMenuBarSharedWindow setColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarBackgroundColor"]];
        [_CPMenuBarSharedWindow setTextColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarTextColor"]];
        [_CPMenuBarSharedWindow setTitleColor:[_CPMenuBarAttributes objectForKey:@"CPMenuBarTitleColor"]];
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
    if (self == [CPApp mainMenu])
        return MENUBAR_HEIGHT;
    
    return 0.0;
}

+ (float)menuBarHeight
{
    return MENUBAR_HEIGHT;
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
    var menu = [aMenuItem menu];
    
    if (menu)
        if (menu != self)
            [CPException raise:CPInternalInconsistencyException reason:@"Attempted to insert item into menu that was already in another menu."];
        else
            return;
    
    [aMenuItem setMenu:self];
    [_items insertObject:aMenuItem atIndex:anIndex];
    
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPMenuDidAddItemNotification
                      object:self
                    userInfo:[CPDictionary dictionaryWithObject:anIndex forKey:@"CPMenuItemIndex"]];

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
    if (anIndex < 0 || anIndex >= _items.length)
        return;
    
    [_items[anIndex] setMenu:nil];
    [_items removeObjectAtIndex:anIndex];
    
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPMenuDidRemoveItemNotification
                      object:self
                    userInfo:[CPDictionary dictionaryWithObject:anIndex forKey:@"CPMenuItemIndex"]];
}

/*!
    Called when a menu item has visually changed.
    @param aMenuItem the item that changed
*/
- (void)itemChanged:(CPMenuItem)aMenuItem
{
    if ([aMenuItem menu] != self)
        return;
    
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPMenuDidChangeItemNotification
                      object:self
                    userInfo:[CPDictionary dictionaryWithObject:[_items indexOfObjectIdenticalTo:aMenuItem] forKey:@"CPMenuItemIndex"]];
}

// Finding Menu Items
/*!
    Returns the menu item with the specified tag
    @param the tag of the desired menu item
    @return the menu item or <code>nil</code> if a match was not found
*/
- (CPMenuItem)menuWithTag:(int)aTag
{
    var index = [self indexOfItemWithTag:aTag];
    
    if (index == CPNotFound)
        return nil;
    
    return _items[index];
}

/*!
    Returns the menu item with the specified title.
    @param aTitle the title of the menu item
    @return the menu item or <code>nil</code> if a match was not found
*/
- (CPMenuItem)menuWithTitle:(CPString)aTitle
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
    if ([aMenuItem menu] != self)
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
    Returns the attaced menu, or <code>nil</code> if there isn't one.
*/
- (CPMenu)attachedMenu
{
    return _attachedMenu;
}

/*!
    Returns <code>YES</code> if the menu is attached to another menu.
*/
- (BOOL)isAttached
{
    return _isAttached;
}

/*!
    Not yet implemented
*/
- (CGPoint)locationOfSubmenu:(CPMenu)aMenu
{
    // FIXME: IMPLEMENT.
}

/*!
    Returns the super menu or <code>nil</code> if there is none.
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
    If there are two instances of this menu visible, return <code>NO</code>.
    Otherwise, return <code>YES</code> if we are a detached menu and visible.
*/
- (BOOL)isTornOff
{
    return !_supermenu /* || offscreen(?) */ || self == [CPApp mainMenu];
}

// Enabling and Disabling Menu Items
/*!
    Sets whether the menu automatically enables menu items.
    @param aFlag <code>YES</code> sets the menu to automatically enable items.
*/
- (void)setAutoenablesItems:(BOOL)aFlag
{
    _autoenablesItems = aFlag;
}

/*!
    Returns <code>YES</code> if the menu auto enables items.
*/
- (BOOL)autoenablesItems
{
    return _autoenablesItems;
}

/*!
    Not implemented.
*/
- (void)update
{

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

//

+ (void)popUpContextMenu:(CPMenu)aMenu withEvent:(CPEvent)anEvent forView:(CPView)aView
{
    [self popUpContextMenu:aMenu withEvent:anEvent forView:aView withFont:nil];
}

+ (void)popUpContextMenu:(CPMenu)aMenu withEvent:(CPEvent)anEvent forView:(CPView)aView withFont:(CPFont)aFont
{
    [self _popUpContextMenu:aMenu withEvent:anEvent forView:aView withFont:aFont forMenuBar:NO];
}

+ (void)_popUpContextMenu:(CPMenu)aMenu withEvent:(CPEvent)anEvent forView:(CPView)aView withFont:(CPFont)aFont forMenuBar:(BOOL)isForMenuBar
{
    var delegate = [aMenu delegate];
    
    if ([delegate respondsToSelector:@selector(menuWillOpen:)])
        [delegate menuWillOpen:aMenu];
    
    if (!aFont)
        aFont = [CPFont systemFontOfSize:12.0];
    
    var theWindow = [aView window],
        menuWindow = [_CPMenuWindow menuWindowWithMenu:aMenu font:aFont];
    
    [menuWindow setDelegate:self];
    [menuWindow setBackgroundStyle:isForMenuBar ? _CPMenuWindowMenuBarBackgroundStyle : _CPMenuWindowPopUpBackgroundStyle];

    [menuWindow setFrameOrigin:[[anEvent window] convertBaseToBridge:[anEvent locationInWindow]]];

    [menuWindow orderFront:self];
    [menuWindow beginTrackingWithEvent:anEvent sessionDelegate:self didEndSelector:@selector(_menuWindowDidFinishTracking:highlightedItem:)];
}

+ (void)_menuWindowDidFinishTracking:(_CPMenuWindow)aMenuWindow highlightedItem:(CPMenuItem)aMenuItem
{
    [_CPMenuWindow poolMenuWindow:aMenuWindow];
    
//    var index = [self indexOfItem:aMenuItem];
    
//    if (index == CPNotFound)
//        return;
    
    var target = nil,
        action = [aMenuItem action];
    
    if (!action)
    {
//        target = [self target];
//        action = [self action];
    }
    
    // FIXME: If [selectedItem target] == nil do we use our own target?
    else
        target = [aMenuItem target];

    if([aMenuItem isEnabled])
        [CPApp sendAction:action to:target from:nil];
}

// Managing Display of State Column
/*!
    Sets whether to show the state column
    @param shouldShowStateColumn <code>YES</code> shows the state column
*/
- (void)setShowsStateColumn:(BOOL)shouldShowStateColumn
{
    _showsStateColumn = shouldShowStateColumn;
}

/*!
    Returns <code>YES</code> if the menu shows the state column
*/
- (BOOL)showsStateColumn
{
    return _showsStateColumn;
}

// Handling Highlighting
/*!
    Returns the currently highlighted menu item.
    @return the highlighted menu item or <code>nil</code> if no item is currently highlighted
*/
- (CPMenuItem)highlightedItem
{
    return _highlightedIndex >= 0 ? _items[_highlightedIndex] : nil;
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

// Handling Tracking
/*!
	Cancels tracking.
*/
- (void)cancelTracking
{
    [_menuWindow cancelTracking];
}

/* @ignore */
- (void)_setMenuWindow:(_CPMenuWindow)aMenuWindow
{
    _menuWindow = aMenuWindow;
}

/*!
    Initiates the action of the menu item that
    has a keyboard shortcut equivalent to <code>anEvent</code>
    @param anEvent the keyboard event
    @return <code>YES</code> if it was handled.
*/
- (BOOL)performKeyEquivalent:(CPEvent)anEvent
{
    if (_autoenablesItems)
        [self update];

    var index = 0,
        count = _items.length,
        characters = [anEvent charactersIgnoringModifiers],
        modifierFlags = [anEvent modifierFlags];

    for(; index < count; ++index)
    {
        var item = _items[index],
            modifierMask = [item keyEquivalentModifierMask];
        
        if ((modifierFlags & (CPShiftKeyMask | CPAlternateKeyMask | CPCommandKeyMask | CPControlKeyMask)) == modifierMask &&
            [characters caseInsensitiveCompare:[item keyEquivalent]] == CPOrderedSame)
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
- (BOOL)_itemIsHighlighted:(CPMenuItem)aMenuItem
{
    return _items[_highlightedIndex] == aMenuItem;
}

/*
    @ignore
*/
- (void)_highlightItemAtIndex:(int)anIndex
{
    var previousHighlightedIndex = _highlightedIndex;
    
    _highlightedIndex = anIndex;
    
    if (previousHighlightedIndex != CPNotFound)
        [[_items[previousHighlightedIndex] _menuItemView] highlight:NO];
    
    if (_highlightedIndex != CPNotFound)
        [[_items[_highlightedIndex] _menuItemView] highlight:YES];
}

@end


var CPMenuTitleKey  = @"CPMenuTitleKey",
    CPMenuItemsKey  = @"CPMenuItemsKey";

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
    [aCoder encodeObject:_items forKey:CPMenuItemsKey];
}

@end

var _CPMenuWindowPool                       = [],
    _CPMenuWindowPoolCapacity               = 5,
    
    _CPMenuWindowBackgroundColors           = [],
    
    _CPMenuWindowScrollingStateUp           = -1,
    _CPMenuWindowScrollingStateDown         = 1,
    _CPMenuWindowScrollingStateNone         = 0;
    
_CPMenuWindowMenuBarBackgroundStyle         = 0;
_CPMenuWindowPopUpBackgroundStyle           = 1;
_CPMenuWindowAttachedMenuBackgroundStyle    = 2;

var STICKY_TIME_INTERVAL        = 500,

    TOP_MARGIN                  = 5.0,
    LEFT_MARGIN                 = 1.0,
    RIGHT_MARGIN                = 1.0,
    BOTTOM_MARGIN               = 5.0,
    
    SCROLL_INDICATOR_HEIGHT     = 16.0;

/*
    @ignore
*/
@implementation _CPMenuWindow : CPWindow
{
    _CPMenuView         _menuView;    
    CPClipView          _menuClipView;
    CPView              _lastMouseOverMenuView;
    
    CPImageView         _moreAboveView;
    CPImageView         _moreBelowView;
    
    id                  _sessionDelegate;
    SEL                 _didEndSelector;
    
    CPTimeInterval      _startTime;
    int                 _scrollingState;
    CGPoint             _lastScreenLocation;
    
    BOOL                _isShowingTopScrollIndicator;
    BOOL                _isShowingBottomScrollIndicator;
    BOOL                _trackingCanceled;
    
    CGRect              _unconstrainedFrame;
}

+ (id)menuWindowWithMenu:(CPMenu)aMenu font:(CPFont)aFont
{
    var menuWindow = nil;
    
    if (_CPMenuWindowPool.length)
        menuWindow = _CPMenuWindowPool.pop();
    else
        menuWindow = [[_CPMenuWindow alloc] init];
    
    [menuWindow setFont:aFont];
    [menuWindow setMenu:aMenu];
    
    return menuWindow;
}

+ (void)poolMenuWindow:(_CPMenuWindow)aMenuWindow
{
    if (!aMenuWindow || _CPMenuWindowPool.length >= _CPMenuWindowPoolCapacity)
        return;
    
    _CPMenuWindowPool.push(aMenuWindow);
}

+ (void)initialize
{
    if (self != [_CPMenuWindow class])
        return;
    
    var bundle = [CPBundle bundleForClass:self];
    
    _CPMenuWindowMoreAboveImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindowMoreAbove.png"] size:CGSizeMake(38.0, 18.0)];
    _CPMenuWindowMoreBelowImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindowMoreBelow.png"] size:CGSizeMake(38.0, 18.0)];
}

- (id)init
{
    self = [super initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessWindowMask];
    
    if (self)
    {
        [self setLevel:CPPopUpMenuWindowLevel];
        [self setHasShadow:YES];
        [self setAcceptsMouseMovedEvents:YES];
        
        _unconstrainedFrame = CGRectMakeZero();
        
        var contentView = [self contentView];
        
        _menuView = [[_CPMenuView alloc] initWithFrame:CGRectMakeZero()];
        
        _menuClipView = [[CPClipView alloc] initWithFrame:CGRectMake(LEFT_MARGIN, TOP_MARGIN, 0.0, 0.0)];
        [_menuClipView setDocumentView:_menuView];
        
        [contentView addSubview:_menuClipView];
        
        _moreAboveView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
        
        [_moreAboveView setImage:_CPMenuWindowMoreAboveImage];
        [_moreAboveView setFrameSize:[_CPMenuWindowMoreAboveImage size]];
        
        [contentView addSubview:_moreAboveView];
        
        _moreBelowView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
    
        [_moreBelowView setImage:_CPMenuWindowMoreBelowImage];
        [_moreBelowView setFrameSize:[_CPMenuWindowMoreBelowImage size]];
        
        [contentView addSubview:_moreBelowView];
    }
    
    return self;
}

- (CGFloat)overlapOffsetWidth
{
    return LEFT_MARGIN;
}

- (void)setFont:(CPFont)aFont
{
    [_menuView setFont:aFont];
}

- (void)setBackgroundStyle:(_CPMenuWindowBackgroundStyle)aBackgroundStyle
{
    var color = _CPMenuWindowBackgroundColors[aBackgroundStyle];
    
    if (!color)
    {
        var bundle = [CPBundle bundleForClass:[self class]];

        if (aBackgroundStyle == _CPMenuWindowPopUpBackgroundStyle)
            color = [CPColor colorWithPatternImage:[[CPNinePartImage alloc] initWithImageSlices:
                [
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindowRounded0.png"] size:CGSizeMake(4.0, 4.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow1.png"] size:CGSizeMake(1.0, 4.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindowRounded2.png"] size:CGSizeMake(4.0, 4.0)],
                    
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow3.png"] size:CGSizeMake(4.0, 1.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow4.png"] size:CGSizeMake(1.0, 1.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow5.png"] size:CGSizeMake(4.0, 1.0)],
                    
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindowRounded6.png"] size:CGSizeMake(4.0, 4.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow7.png"] size:CGSizeMake(1.0, 4.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindowRounded8.png"] size:CGSizeMake(4.0, 4.0)]
                ]]];
        
        else if (aBackgroundStyle == _CPMenuWindowMenuBarBackgroundStyle)
            color = [CPColor colorWithPatternImage:[[CPNinePartImage alloc] initWithImageSlices:
                [
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow3.png"] size:CGSizeMake(4.0, 0.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow4.png"] size:CGSizeMake(1.0, 0.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow5.png"] size:CGSizeMake(4.0, 0.0)],
                    
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow3.png"] size:CGSizeMake(4.0, 1.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow4.png"] size:CGSizeMake(1.0, 1.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow5.png"] size:CGSizeMake(4.0, 1.0)],
                    
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindowRounded6.png"] size:CGSizeMake(4.0, 4.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow7.png"] size:CGSizeMake(1.0, 4.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindowRounded8.png"] size:CGSizeMake(4.0, 4.0)]
                ]]];
                
        _CPMenuWindowBackgroundColors[aBackgroundStyle] = color;
    }
    
    [self setBackgroundColor:color];
}

- (void)setMenu:(CPMenu)aMenu
{
    [aMenu _setMenuWindow:self];
    [_menuView setMenu:aMenu];
    
    var menuViewSize = [_menuView frame].size;
    
    [self setFrameSize:CGSizeMake(LEFT_MARGIN + menuViewSize.width + RIGHT_MARGIN, TOP_MARGIN + menuViewSize.height + BOTTOM_MARGIN)];
    
    [_menuView scrollPoint:CGPointMake(0.0, 0.0)];
    [_menuClipView setFrame:CGRectMake(LEFT_MARGIN, TOP_MARGIN, menuViewSize.width, menuViewSize.height)];
}

- (void)setMinWidth:(float)aWidth
{
    var size = [self frame].size;
    
    [self setFrameSize:CGSizeMake(MAX(size.width, aWidth), size.height)];
}

- (CGPoint)rectForItemAtIndex:(int)anIndex
{
    return [_menuView convertRect:[_menuView rectForItemAtIndex:anIndex] toView:nil];
}

- (void)orderFront:(id)aSender
{
    [self constrainToScreen];
    
    [super orderFront:aSender];
}

- (void)constrainToScreen
{
    _unconstrainedFrame = CGRectMakeCopy([self frame]);

    var screenBounds = CGRectInset([[CPDOMWindowBridge sharedDOMWindowBridge] contentBounds], 5.0, 5.0),
        constrainedFrame = CGRectIntersection(_unconstrainedFrame, screenBounds),
        menuViewOrigin = [self convertBaseToBridge:CGPointMake(LEFT_MARGIN, TOP_MARGIN)];
    
    constrainedFrame.origin.x = CGRectGetMinX(_unconstrainedFrame);
    constrainedFrame.size.width = CGRectGetWidth(_unconstrainedFrame);
    
    if (CGRectGetWidth(constrainedFrame) > CGRectGetWidth(screenBounds))
        constrainedFrame.size.width = CGRectGetWidth(screenBounds);
    
    if (CGRectGetMaxX(constrainedFrame) > CGRectGetMaxX(screenBounds))
        constrainedFrame.origin.x -= CGRectGetMaxX(constrainedFrame) - CGRectGetMaxX(screenBounds);
    
    if (CGRectGetMinX(constrainedFrame) < CGRectGetMinX(screenBounds))
        constrainedFrame.origin.x = CGRectGetMinX(screenBounds);
    
    [super setFrame:constrainedFrame];
    
    var topMargin = TOP_MARGIN,
        bottomMargin = BOTTOM_MARGIN,
        
        contentView = [self contentView],
        bounds = [contentView bounds];
    
    var moreAbove = menuViewOrigin.y < CGRectGetMinY(constrainedFrame) + TOP_MARGIN,
        moreBelow = menuViewOrigin.y + CGRectGetHeight([_menuView frame]) > CGRectGetMaxY(constrainedFrame) - BOTTOM_MARGIN;
    
    if (moreAbove)
    {
        topMargin += SCROLL_INDICATOR_HEIGHT;
    
        var frame = [_moreAboveView frame];
        
        [_moreAboveView setFrameOrigin:CGPointMake((CGRectGetWidth(bounds) - CGRectGetWidth(frame)) / 2.0, (TOP_MARGIN + SCROLL_INDICATOR_HEIGHT - CGRectGetHeight(frame)) / 2.0)];
    }
    
    [_moreAboveView setHidden:!moreAbove];
    
    if (moreBelow)
    {
        bottomMargin += SCROLL_INDICATOR_HEIGHT;
    
        [_moreBelowView setFrameOrigin:CGPointMake((CGRectGetWidth(bounds) - CGRectGetWidth([_moreBelowView frame])) / 2.0, CGRectGetHeight(bounds) - SCROLL_INDICATOR_HEIGHT - BOTTOM_MARGIN)];
    }
    
    [_moreBelowView setHidden:!moreBelow];
    
    var clipFrame = CGRectMake(LEFT_MARGIN, topMargin, CGRectGetWidth(constrainedFrame) - LEFT_MARGIN - RIGHT_MARGIN, CGRectGetHeight(constrainedFrame) - topMargin - bottomMargin)
    
    [_menuClipView setFrame:clipFrame];
    [_menuView setFrameSize:CGSizeMake(CGRectGetWidth(clipFrame), CGRectGetHeight([_menuView frame]))];
    
    [_menuView scrollPoint:CGPointMake(0.0, [self convertBaseToBridge:clipFrame.origin].y - menuViewOrigin.y)];
}

- (void)cancelTracking
{
    _trackingCanceled = YES;
}

- (void)beginTrackingWithEvent:(CPEvent)anEvent sessionDelegate:(id)aSessionDelegate didEndSelector:(SEL)aDidEndSelector
{
    _startTime = [anEvent timestamp];//new Date();
    _scrollingState = _CPMenuWindowScrollingStateNone;
    _trackingCanceled = NO;
    
    _sessionDelegate = aSessionDelegate;
    _didEndSelector = aDidEndSelector;
    
    [self trackEvent:anEvent];
}

- (void)trackEvent:(CPEvent)anEvent
{
    var type = [anEvent type],
        theWindow = [anEvent window],
        screenLocation = theWindow ? [theWindow convertBaseToBridge:[anEvent locationInWindow]] : [anEvent locationInWindow];
    
    if (type == CPPeriodic)
    {
        var constrainedBounds = CGRectInset([[CPDOMWindowBridge sharedDOMWindowBridge] contentBounds], 5.0, 5.0);
        
        if (_scrollingState == _CPMenuWindowScrollingStateUp)
        {
            if (CGRectGetMinY(_unconstrainedFrame) < CGRectGetMinY(constrainedBounds))
                _unconstrainedFrame.origin.y += 10;
        }
        else if (_scrollingState == _CPMenuWindowScrollingStateDown)
            if (CGRectGetMaxY(_unconstrainedFrame) > CGRectGetHeight(constrainedBounds))
                _unconstrainedFrame.origin.y -= 10;
                
        [self setFrame:_unconstrainedFrame];
        [self constrainToScreen];
        
        screenLocation = _lastScreenLocation;
    }

    _lastScreenLocation = screenLocation;
    
    var menu = [_menuView menu],
        menuLocation = [self convertBridgeToBase:screenLocation],
        activeItemIndex = [_menuView itemIndexAtPoint:[_menuView convertPoint:menuLocation fromView:nil]],
        mouseOverMenuView = [[menu itemAtIndex:activeItemIndex] view];
    
    // If we're over a custom menu view...
    if (mouseOverMenuView)
    {
        if (!_lastMouseOverMenuView)
            [menu _highlightItemAtIndex:CPNotFound];
        
        if (_lastMouseOverMenuView != mouseOverMenuView)
        {
            [mouseOverMenuView mouseExited:anEvent];
            // FIXME: Possibly multiple of these?
            [_lastMouseOverMenuView mouseEntered:anEvent];
            
            _lastMouseOverMenuView = mouseOverMenuView;
        }
        
        [self sendEvent:[CPEvent mouseEventWithType:type location:menuLocation modifierFlags:[anEvent modifierFlags] 
            timestamp:[anEvent timestamp] windowNumber:[self windowNumber] context:nil 
            eventNumber:0 clickCount:[anEvent clickCount] pressure:[anEvent pressure]]];
    }
    else
    {
        if (_lastMouseOverMenuView)
        {
            [_lastMouseOverMenuView mouseExited:anEvent];
            _lastMouseOverMenuView = nil;
        }
        
        [menu _highlightItemAtIndex:[_menuView itemIndexAtPoint:[_menuView convertPoint:[self convertBridgeToBase:screenLocation] fromView:nil]]];
        
        if (type == CPMouseMoved || type == CPLeftMouseDragged || type == CPLeftMouseDown)
        {
            var frame = [self frame],
                oldScrollingState = _scrollingState;
            
            _scrollingState = _CPMenuWindowScrollingStateNone;
            
            // If we're at or above of the top scroll indicator...
            if (screenLocation.y < CGRectGetMinY(frame) + TOP_MARGIN + SCROLL_INDICATOR_HEIGHT)
                _scrollingState = _CPMenuWindowScrollingStateUp;
        
            // If we're at or below the bottom scroll indicator...
            else if (screenLocation.y > CGRectGetMaxY(frame) - BOTTOM_MARGIN - SCROLL_INDICATOR_HEIGHT)
                _scrollingState = _CPMenuWindowScrollingStateDown;
            
            if (_scrollingState != oldScrollingState)
            
                if (_scrollingState == _CPMenuWindowScrollingStateNone)
                    [CPEvent stopPeriodicEvents];
            
                else if (oldScrollingState == _CPMenuWindowScrollingStateNone)
                    [CPEvent startPeriodicEventsAfterDelay:0.0 withPeriod:0.04];
        }
        
        else if (type == CPLeftMouseUp && ([anEvent timestamp] - _startTime > STICKY_TIME_INTERVAL))
        {
            // Stop these if they're still goin'.
            if (_scrollingState != _CPMenuWindowScrollingStateNone)
                [CPEvent stopPeriodicEvents];
    
            [self cancelTracking];
        }
    }
        
    if (_trackingCanceled)
    {
        // Stop all periodic events at this point.
        [CPEvent stopPeriodicEvents];
        
        var highlightedItem = [[_menuView menu] highlightedItem];
        
        [menu _highlightItemAtIndex:CPNotFound];
        
        // Clear these now so its faster next time around.
        [_menuView setMenu:nil];
        
        [self orderOut:self];
        
        if (_sessionDelegate && _didEndSelector)
            objj_msgSend(_sessionDelegate, _didEndSelector, self, highlightedItem);
        
        [[CPNotificationCenter defaultCenter]
            postNotificationName:CPMenuDidEndTrackingNotification
                          object:menu];
        
        var delegate = [menu delegate];
        
        if ([delegate respondsToSelector:@selector(menuDidClose:)])
            [delegate menuDidClose:menu];
        
        return;
    }
            
    [CPApp setTarget:self selector:@selector(trackEvent:) forNextEventMatchingMask:CPPeriodicMask | CPMouseMovedMask | CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
}

@end

/*
    @ignore
*/
@implementation _CPMenuView : CPView
{
    CPArray _menuItemViews;
    CPArray _visibleMenuItemInfos;
    
    CPFont  _font;
}

/*- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
        [self setAutoresizingMask:CPViewWidthSizable];
    
    return self;
}*/

- (void)setFont:(CPFont)aFont
{
    _font = aFont;
}

- (CGRect)rectForItemAtIndex:(int)anIndex
{
    return [_menuItemViews[anIndex == CPNotFound ? 0 : anIndex] frame];
}

- (int)itemIndexAtPoint:(CGPoint)aPoint
{
    var x = aPoint.x,
        bounds = [self bounds];
    
    if (x < CGRectGetMinX(bounds) || x > CGRectGetMaxX(bounds))
        return CPNotFound;
    
    var y = aPoint.y,
        low = 0,
        high = _visibleMenuItemInfos.length - 1;
       
    while (low <= high)
    {
        var middle = FLOOR(low + (high - low) / 2),
            info = _visibleMenuItemInfos[middle]
            frame = [info.view frame];
        
        if (y < CGRectGetMinY(frame))
            high = middle - 1;
        
        else if (y > CGRectGetMaxY(frame))
            low = middle + 1;
        
        else
            return info.index;
   }
   
   return CPNotFound;
}

- (void)setMenu:(CPMenu)aMenu
{
    [super setMenu:aMenu];
    
    [_menuItemViews makeObjectsPerformSelector:@selector(removeFromSuperview)];   
    
    _menuItemViews = [];
    _visibleMenuItemInfos = [];
    
    var menu = [self menu];
    
    if (!menu)
        return;
    
    var items = [menu itemArray],
        index = 0,
        count = [items count],
        maxWidth = 0,
        y = 0,
        showsStateColumn = [menu showsStateColumn];
    
    for (; index < count; ++index)
    {
        var item = items[index],
            view = [item _menuItemView];        
        
        _menuItemViews.push(view);
        
        if ([item isHidden])
            continue;

        _visibleMenuItemInfos.push({ view:view, index:index });
        
        [view setFont:_font];
        [view setShowsStateColumn:showsStateColumn];
        [view synchronizeWithMenuItem];
                
        [view setFrameOrigin:CGPointMake(0.0, y)];
        
        [self addSubview:view];

        var size = [view minSize],
            width = size.width;
        
        if (maxWidth < width)
            maxWidth = width;
        
        y += size.height;
    }
    
    for (index = 0; index < count; ++index)
    {
        var view = _menuItemViews[index];
        
        [view setFrameSize:CGSizeMake(maxWidth, CGRectGetHeight([view frame]))];
    }
    
    [self setAutoresizesSubviews:NO];
    [self setFrameSize:CGSizeMake(maxWidth, y)];
    [self setAutoresizesSubviews:YES];
}

@end

var MENUBAR_HEIGHT          = 29.0,
    MENUBAR_MARGIN          = 10.0,
    MENUBAR_LEFT_MARGIN     = 10.0,
    MENUBAR_RIGHT_MARGIN    = 10.0;

var _CPMenuBarWindowBackgroundColor = nil,
    _CPMenuBarWindowFont            = nil;

@implementation _CPMenuBarWindow : CPPanel
{
    CPMenu      _menu;
    CPView      _highlightView;
    CPArray     _menuItemViews;
    
    CPMenuItem  _trackingMenuItem;
    
    CPImageView _iconImageView;
    CPTextField _titleField;
    
    CPColor     _textColor;
    CPColor     _titleColor;
}

+ (void)initialize
{
    if (self != [_CPMenuBarWindow class])
        return;
        
    var bundle = [CPBundle bundleForClass:self];
    
    _CPMenuBarWindowFont = [CPFont systemFontOfSize:11.0];
}

- (id)init
{
    var bridgeWidth = CGRectGetWidth([[CPDOMWindowBridge sharedDOMWindowBridge] contentBounds]);
    
    self = [super initWithContentRect:CGRectMake(0.0, 0.0, bridgeWidth, MENUBAR_HEIGHT) styleMask:CPBorderlessWindowMask];
    
    if (self)
    {
        // FIXME: http://280north.lighthouseapp.com/projects/13294-cappuccino/tickets/39-dont-allow-windows-to-go-above-menubar
        [self setLevel:-1];//CPTornOffMenuWindowLevel];
        [self setAutoresizingMask:CPWindowWidthSizable];
     
        var contentView = [self contentView];
        
        [contentView setAutoresizesSubviews:NO];
        
        [self setBecomesKeyOnlyIfNeeded:YES];
        
        //
        _iconImageView = [[CPImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 16.0, 16.0)];
        
        [contentView addSubview:_iconImageView];
        
        _titleField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
        
        [_titleField setFont:[CPFont boldSystemFontOfSize:12.0]];
        [_titleField setAlignment:CPCenterTextAlignment];
        
        [contentView addSubview:_titleField];
    }
    
    return self;
}

- (void)setTitle:(CPString)aTitle
{
#if PLATFORM(DOM)
    var bundleName = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPBundleName"];

    if (![bundleName length])
        document.title = aTitle;
    else if ([aTitle length])
        document.title = aTitle + @" - " + bundleName;
    else
        document.title = bundleName;
#endif

    [_titleField setStringValue:aTitle];
    [_titleField sizeToFit];
    
    [self tile];
}

- (void)setIconImage:(CPImage)anImage
{
    [_iconImageView setImage:anImage];
    [_iconImageView setHidden:anImage == nil];

    [self tile];
}

- (void)setIconImageAlphaValue:(float)anAlphaValue
{
    [_iconImageView setAlphaValue:anAlphaValue];
}

- (void)setColor:(CPColor)aColor
{
    if (!aColor)
    {
        if (!_CPMenuBarWindowBackgroundColor)
            _CPMenuBarWindowBackgroundColor = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[_CPMenuBarWindow class]] pathForResource:@"_CPMenuBarWindow/_CPMenuBarWindowBackground.png"] size:CGSizeMake(1.0, 18.0)]];
            
        [[self contentView] setBackgroundColor:_CPMenuBarWindowBackgroundColor];
    }
    else
        [[self contentView] setBackgroundColor:aColor];
}

- (void)setTextColor:(CPColor)aColor
{
    if (_textColor == aColor)
        return;
    
    _textColor = aColor;
    
    [_menuItemViews makeObjectsPerformSelector:@selector(setTextColor:) withObject:_textColor];
}

- (void)setTitleColor:(CPColor)aColor
{
    if (_titleColor == aColor)
        return;
    
    _titleColor = aColor;
    
    [_titleField setTextColor:aColor ? aColor : [CPColor blackColor]];
}

- (void)setMenu:(CPMenu)aMenu
{
    if (_menu == aMenu)
        return;
    
    var defaultCenter = [CPNotificationCenter defaultCenter];
    
    if (_menu)
    {
        [defaultCenter
            removeObserver:self
                      name:CPMenuDidAddItemNotification
                    object:_menu];

        [defaultCenter
            removeObserver:self
                      name:CPMenuDidChangeItemNotification
                    object:_menu];

        [defaultCenter
            removeObserver:self
                      name:CPMenuDidRemoveItemNotification
                    object:_menu];
                    
        var items = [_menu itemArray],
            count = items.length;
        
        while (count--)
            [[items[count] _menuItemView] removeFromSuperview];
    }

    _menu = aMenu;
    
    if (_menu)
    {
        [defaultCenter
            addObserver:self
              selector:@selector(menuDidAddItem:)
                  name:CPMenuDidAddItemNotification
                object:_menu];
    
        [defaultCenter
            addObserver:self
              selector:@selector(menuDidChangeItem:)
                  name:CPMenuDidChangeItemNotification
                object:_menu];
                
        [defaultCenter
            addObserver:self
              selector:@selector(menuDidRemoveItem:)
                  name:CPMenuDidRemoveItemNotification
                object:_menu];
    }
    
    _menuItemViews = [];
    
    var contentView = [self contentView],
        items = [_menu itemArray],
        count = items.length;
    
    for (index = 0; index < count; ++index)
    {
        var item = items[index],
            menuItemView = [item _menuItemView];
            
        _menuItemViews.push(menuItemView);
        
        [menuItemView setShowsStateColumn:NO];
        [menuItemView setBelongsToMenuBar:YES];
        [menuItemView setFont:_CPMenuBarWindowFont];
        [menuItemView setTextColor:_textColor];
        [menuItemView setHidden:[item isHidden]];
        
        [menuItemView synchronizeWithMenuItem];
        
        [contentView addSubview:menuItemView];
    }
        
    [self tile];
}

- (void)menuDidChangeItem:(CPNotification)aNotification
{
    var menuItem = [_menu itemAtIndex:[[aNotification userInfo] objectForKey:@"CPMenuItemIndex"]],
        menuItemView = [menuItem _menuItemView];

    [menuItemView setHidden:[menuItem isHidden]];
    [menuItemView synchronizeWithMenuItem];
    
    [self tile];
}

- (void)menuDidAddItem:(CPNotification)aNotification
{
    var index = [[aNotification userInfo] objectForKey:@"CPMenuItemIndex"],
        menuItem = [_menu itemAtIndex:index],
        menuItemView = [menuItem _menuItemView];

    [_menuItemViews insertObject:menuItemView atIndex:index];

    [menuItemView setShowsStateColumn:NO];
    [menuItemView setBelongsToMenuBar:YES];
    [menuItemView setFont:_CPMenuBarWindowFont];
    [menuItemView setTextColor:_textColor];
    [menuItemView setHidden:[menuItem isHidden]];

    [menuItemView synchronizeWithMenuItem];
    
    [[self contentView] addSubview:menuItemView];
    
    [self tile];
}

- (void)menuDidRemoveItem:(CPNotification)aNotification
{
    var index = [[aNotification userInfo] objectForKey:@"CPMenuItemIndex"],
        menuItemView = [_menuItemViews objectAtIndex:index];

    [_menuItemViews removeObjectAtIndex:index];

    [menuItemView removeFromSuperview];
        
    [self tile];
}

- (CGRect)frameForMenuItem:(CPMenuItem)aMenuItem
{
    var frame = [[aMenuItem _menuItemView] frame];
    
    frame.origin.x -= 5.0;
    frame.origin.y = 0;
    frame.size.width += 10.0;
    frame.size.height = MENUBAR_HEIGHT;
    
    return frame;
}

- (CPView)menuItemAtPoint:(CGPoint)aPoint
{
    var items = [_menu itemArray],
        count = items.length;
    
    while (count--)
    {
        var item = items[count];
        
        if ([item isHidden] || [item isSeparatorItem])
            continue;
        
        if (CGRectContainsPoint([self frameForMenuItem:item], aPoint))
            return item;
    }
    
    return nil;
}

- (void)mouseDown:(CPEvent)anEvent
{
    _trackingMenuItem = [self menuItemAtPoint:[anEvent locationInWindow]];
    
    if (![_trackingMenuItem isEnabled])
        return;
    
    if ([[_trackingMenuItem _menuItemView] eventOnSubmenu:anEvent])
        return [self showMenu:anEvent];
    
    if ([_trackingMenuItem isEnabled])
        [self trackEvent:anEvent];
}

- (void)trackEvent:(CPEvent)anEvent
{
    var type = [anEvent type];
    
    if (type === CPPeriodic)
        return [self showMenu:anEvent];
    
    var frame = [self frameForMenuItem:_trackingMenuItem],
        menuItemView = [_trackingMenuItem _menuItemView],
        onMenuItemView = CGRectContainsPoint(frame, [anEvent locationInWindow]);
        
    if (type == CPLeftMouseDown)
    {
        if ([_trackingMenuItem submenu] != nil)
        {
            // If the item has a submenu, but not direct action, a.k.a. a "pure" menu, simply show the menu.
            if (![_trackingMenuItem action])
                return [self showMenu:anEvent];
            
            // If this is a hybrid button/menu, show it in a bit...
            [CPEvent startPeriodicEventsAfterDelay:0.0 withPeriod:0.5];
        }
        
        [menuItemView highlight:onMenuItemView];
    }
    
    else if (type == CPLeftMouseDragged)
    {
        if (!onMenuItemView && [_trackingMenuItem submenu])
            return [self showMenu:anEvent];
    
        [menuItemView highlight:onMenuItemView];
    }
    
    else /*if (type == CPLeftMouseUp)*/
    {
        [CPEvent stopPeriodicEvents];
    
        [menuItemView highlight:NO];
        
        if (onMenuItemView)
            [CPApp sendAction:[_trackingMenuItem action] to:[_trackingMenuItem target] from:nil];
        
        return;
    }
    
    [CPApp setTarget:self selector:@selector(trackEvent:) forNextEventMatchingMask:CPPeriodicMask | CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];    
}

- (void)showMenu:(CPEvent)anEvent
{
    [CPEvent stopPeriodicEvents];
    
    var frame = [self frameForMenuItem:_trackingMenuItem],
        menuItemView = [_trackingMenuItem _menuItemView];
    
    if (!_highlightView)
    {
        _highlightView = [[CPView alloc] initWithFrame:frame];
    
        [_highlightView setBackgroundColor:[CPColor colorWithCalibratedRed:81.0 / 255.0 green:83.0 / 255.0 blue:109.0 / 255.0 alpha:1.0]];
    }
    else
        [_highlightView setFrame:frame];
        
    [[self contentView] addSubview:_highlightView positioned:CPWindowBelow relativeTo:menuItemView];
    
    [menuItemView activate:YES];
    
    var submenu = [_trackingMenuItem submenu];

    [[CPNotificationCenter defaultCenter]
        addObserver:self
          selector:@selector(menuDidEndTracking:)
              name:CPMenuDidEndTrackingNotification
            object:submenu];
    
    [CPMenu _popUpContextMenu:submenu
                    withEvent:[CPEvent mouseEventWithType:CPLeftMouseDown location:CGPointMake(CGRectGetMinX(frame), CGRectGetMaxY(frame))
                                modifierFlags:[anEvent modifierFlags] timestamp:[anEvent timestamp] windowNumber:[self windowNumber] 
                                context:nil eventNumber:0 clickCount:[anEvent clickCount] pressure:[anEvent pressure]] 
                      forView:[self contentView]
                     withFont:nil
                   forMenuBar:YES];
}

- (void)menuDidEndTracking:(CPNotification)aNotification
{
    [_highlightView removeFromSuperview];
    
    [[_trackingMenuItem _menuItemView] activate:NO];
    
    [[CPNotificationCenter defaultCenter]
        removeObserver:self
                  name:CPMenuDidEndTrackingNotification
                object:[aNotification object]];
}

- (void)tile
{
    var items = [_menu itemArray],
        index = 0,
        count = items.length,
        
        x = MENUBAR_LEFT_MARGIN,
        y = 0.0,
        isLeftAligned = YES;
    
    for (; index < count; ++index)
    {
        var item = items[index];
        
        if ([item isSeparatorItem])
        {
            x = CGRectGetWidth([self frame]) - MENUBAR_RIGHT_MARGIN;
            isLeftAligned = NO;
            
            continue;
        }
        
         if ([item isHidden])
            continue;

        var menuItemView = [item _menuItemView],
            frame = [menuItemView frame];
        
        if (isLeftAligned)
        {
            [menuItemView setFrameOrigin:CGPointMake(x, (MENUBAR_HEIGHT - 1.0 - CGRectGetHeight(frame)) / 2.0)];
     
            x += CGRectGetWidth([menuItemView frame]) + MENUBAR_MARGIN;
        }
        else
        {
            [menuItemView setFrameOrigin:CGPointMake(x - CGRectGetWidth(frame), (MENUBAR_HEIGHT - 1.0 - CGRectGetHeight(frame)) / 2.0)];
     
            x = CGRectGetMinX([menuItemView frame]) - MENUBAR_MARGIN;
        }
    }
    
    var bounds = [[self contentView] bounds],
        titleFrame = [_titleField frame];
    
    if ([_iconImageView isHidden])
        [_titleField setFrameOrigin:CGPointMake((CGRectGetWidth(bounds) - CGRectGetWidth(titleFrame)) / 2.0, (CGRectGetHeight(bounds) - CGRectGetHeight(titleFrame)) / 2.0)];
    else
    {
        var iconFrame = [_iconImageView frame],
            iconWidth = CGRectGetWidth(iconFrame),
            totalWidth = iconWidth + CGRectGetWidth(titleFrame);
        
        [_iconImageView setFrameOrigin:CGPointMake((CGRectGetWidth(bounds) - totalWidth) / 2.0, (CGRectGetHeight(bounds) - CGRectGetHeight(iconFrame)) / 2.0)];
        [_titleField setFrameOrigin:CGPointMake((CGRectGetWidth(bounds) - totalWidth) / 2.0 + iconWidth, (CGRectGetHeight(bounds) - CGRectGetHeight(titleFrame)) / 2.0)];
    }
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    
    [self tile];
}

@end
