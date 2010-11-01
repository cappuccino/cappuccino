/*
 * CPPopUpButton.j
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

@import "CPButton.j"
@import "CPGeometry.j"
@import "CPMenu.j"
@import "CPMenuItem.j"


var VISIBLE_MARGIN  = 7.0;

CPPopUpButtonStatePullsDown = CPThemeState("pulls-down");

/*!
    @ingroup appkit
    @class CPPopUpButton

    A CPPopUpButton contains a pop-up menu of items that a user can select from.
*/
@implementation CPPopUpButton : CPButton
{
    int         _selectedIndex;
    CPRectEdge  _preferredEdge;

    CPMenu      _menu;
}

+ (CPString)defaultThemeClass
{
    return "popup-button";
}

/*!
    Initializes the pop-up button to the specified size.
    @param aFrame the size for the button
    @param shouldPullDown \c YES makes this a pull-down menu, \c NO makes it a pop-up menu.
    @return the initialized pop-up button
*/
- (id)initWithFrame:(CGRect)aFrame pullsDown:(BOOL)shouldPullDown
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _selectedIndex = CPNotFound;
        _preferredEdge = CPMaxYEdge;

        [self setValue:CPImageLeft forThemeAttribute:@"image-position"];
        [self setValue:CPLeftTextAlignment forThemeAttribute:@"alignment"];
        [self setValue:CPLineBreakByTruncatingTail forThemeAttribute:@"line-break-mode"];

        [self setMenu:[[CPMenu alloc] initWithTitle:@""]];

        [self setPullsDown:shouldPullDown];
    }

    return self;
}

- (id)initWithFrame:(CGRect)aFrame
{
    return [self initWithFrame:aFrame pullsDown:NO];
}

// Setting the Type of Menu

/*!
    Specifies whether the object is a pull-down or a pop-up menu.
    @param shouldPullDown \c YES makes the pop-up button
    a pull-down menu. \c NO makes it a pop-up menu.
*/
- (void)setPullsDown:(BOOL)shouldPullDown
{
    if (shouldPullDown)
        var changed = [self setThemeState:CPPopUpButtonStatePullsDown];
    else
        var changed = [self unsetThemeState:CPPopUpButtonStatePullsDown];

    if (!changed)
        return;

    var items = [_menu itemArray];

    if ([items count] <= 0)
        return;

    [items[0] setHidden:[self pullsDown]];

    [self synchronizeTitleAndSelectedItem];
}

/*!
    Returns \c YES if the button is a pull-down menu. \c NO if the button is a pop-up menu.
*/
- (BOOL)pullsDown
{
    return [self hasThemeState:CPPopUpButtonStatePullsDown];
}

// Inserting and Deleting Items

/*!
    Adds a new menu item using a CPMenuItem object.
*/
- (void)addItem:(CPMenuItem)anItem
{
    [_menu addItem:anItem];
}

/*!
    Adds a new menu item with the specified title.
    @param the new menu item's tite
*/
- (void)addItemWithTitle:(CPString)aTitle
{
    [_menu addItemWithTitle:aTitle action:NULL keyEquivalent:nil];
}

/*!
    Adds multiple new menu items with the titles specified in the provided array.
    @param titles an arry of names for the new items
*/
- (void)addItemsWithTitles:(CPArray)titles
{
    var index = 0,
        count = [titles count];

    for (; index < count; ++index)
        [self addItemWithTitle:titles[index]];
}

/*!
    Inserts a new item with the specified title and index location.
    @param aTitle the new itme's title
    @param anIndex the item's index in the menu
*/
- (void)insertItemWithTitle:(CPString)aTitle atIndex:(int)anIndex
{
    var items = [self itemArray],
        count = [items count];

    while (count--)
        if ([items[count] title] == aTitle)
            [self removeItemAtIndex:count];

    [_menu insertItemWithTitle:aTitle action:NULL keyEquivalent:nil atIndex:anIndex];
}

/*!
    Removes all menu items from the pop-up button's menu
*/
- (void)removeAllItems
{
    var count = [_menu numberOfItems];

    while (count--)
        [_menu removeItemAtIndex:0];
}

/*!
    Removes a menu item with the specified title from the button.
    @param aTitle the title of the item to remove
*/
- (void)removeItemWithTitle:(CPString)aTitle
{
    [self removeItemAtIndex:[self indexOfItemWithTitle:aTitle]];
    [self synchronizeTitleAndSelectedItem];
}

/*!
    Removes the menu item at the specified index
    @param anIndex the index of the item to remove
*/
- (void)removeItemAtIndex:(int)anIndex
{
    [_menu removeItemAtIndex:anIndex];
    [self synchronizeTitleAndSelectedItem];
}

// Getting the User's Selection
/*!
    Returns the selected item or \c nil if no item is selected.
*/
- (CPMenuItem)selectedItem
{
    if (_selectedIndex < 0 || _selectedIndex > [self numberOfItems] - 1)
        return nil;

    return [_menu itemAtIndex:_selectedIndex];
}

/*!
    Returns the title of the selected item or \c nil if no item is selected.
*/
- (CPString)titleOfSelectedItem
{
    return [[self selectedItem] title];
}

/*!
    Returns the index of the selected item. If no item is selected, it returns CPNotFound.
*/
- (int)indexOfSelectedItem
{
    return _selectedIndex;
}

// For us, CPNumber is toll-free bridged to Number, so just return the selected index.
/*!
    Returns the selected item's index. If no item is selected, it returns CPNotFound.
*/
- (id)objectValue
{
    return _selectedIndex;
}

// Setting the Current Selection
/*!
    Selects the specified menu item.
    @param aMenuItem the item to select
*/
- (void)selectItem:(CPMenuItem)aMenuItem
{
    [self selectItemAtIndex:[self indexOfItem:aMenuItem]];
}

/*!
    Selects the item at the specified index
    @param anIndex the index of the item to select
*/
- (void)selectItemAtIndex:(int)anIndex
{
    if (_selectedIndex == anIndex)
        return;

    if (_selectedIndex >= 0 && ![self pullsDown])
        [[self selectedItem] setState:CPOffState];

    _selectedIndex = anIndex;

    if (_selectedIndex >= 0 && ![self pullsDown])
        [[self selectedItem] setState:CPOnState];

    [self synchronizeTitleAndSelectedItem];
}

/*!
    Selects the menu item with the specified tag
    @param the tag of the item to select
*/
- (void)selectItemWithTag:(int)aTag
{
    [self selectItemAtIndex:[self indexOfItemWithTag:aTag]];
}

/*!
    Selects the item with the specified title
    @param the title of the item to select
*/
- (void)selectItemWithTitle:(CPString)aTitle
{
    [self selectItemAtIndex:[self indexOfItemWithTitle:aTitle]];
}

/*!
    Sets the object for the selected item. If no item is selected, then this method has no effect.
    @param the object set for the selected item
*/
- (void)setObjectValue:(id)aValue
{
    [self selectItemAtIndex:[aValue intValue]];
}

// Getting Menu Items
/*!
    Returns the button's menu of items.
*/
- (CPMenu)menu
{
    return _menu;
}

/*!
    Sets the menu for the button
*/
- (void)setMenu:(CPMenu)aMenu
{
    if (_menu === aMenu)
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

    [self synchronizeTitleAndSelectedItem];
}

/*!
    Returns a count of the number of items in the button's menu.
*/
- (int)numberOfItems
{
    return [_menu numberOfItems];
}

/*!
    Returns an array of the items in the menu
*/
- (CPArray)itemArray
{
    return [_menu itemArray];
}

/*!
    Returns the item at the specified index or \c nil if the item does not exist.
    @param anIndex the index of the item to obtain
*/
- (CPMenuItem)itemAtIndex:(unsigned)anIndex
{
    return [_menu itemAtIndex:anIndex];
}

/*!
    Returns the title of the item at the specified index or \c nil if no item exists.
    @param anIndex the index of the item
*/
- (CPString)itemTitleAtIndex:(unsigned)anIndex
{
    return [[_menu itemAtIndex:anIndex] title];
}

/*!
    Returns an array of all the menu item titles.
*/
- (CPArray)itemTitles
{
    var titles = [],
        items = [self itemArray],
        index = 0,
        count = [items count];

    for (; index < count; ++index)
        titles.push([items[index] title]);

    return titles;
}

/*!
    Returns the menu item with the specified title.
    @param aTitle the title of the desired menu item
*/
- (CPMenuItem)itemWithTitle:(CPString)aTitle
{
    return [_menu itemAtIndex:[_menu indexOfItemWithTitle:aTitle]];
}

/*!
    Returns the last menu item
*/
- (CPMenuItem)lastItem
{
    return [[_menu itemArray] lastObject];
}

// Getting the Indices of Menu Items
/*!
    Returns the index of the specified item or CPNotFound if the item is not in the list.
    @param aMenuItem the item to obtain the index for
*/
- (int)indexOfItem:(CPMenuItem)aMenuItem
{
    return [_menu indexOfItem:aMenuItem];
}

/*!
    Returns the index of the item with the specified tag or CPNotFound if the item is not in the list.
    @param aTag the item's tag
*/
- (int)indexOfItemWithTag:(int)aTag
{
    return [_menu indexOfItemWithTag:aTag];
}

/*!
    Returns the index of the item with the specified title or CPNotFound.
    @param aTitle the item's titel
*/
- (int)indexOfItemWithTitle:(CPString)aTitle
{
    return [_menu indexOfItemWithTitle:aTitle];
}

/*!
    Returns the index of the item with the specified
    represented object or CPNotFound
    if a match does not exist.
    @param anObject the item's represented object
*/
- (int)indexOfItemWithRepresentedObject:(id)anObject
{
    return [_menu indexOfItemWithRepresentedObject:anObject];
}

/*!
    Returns the index of the item with the specified target
    and action. Returns CPNotFound if the no
    such item is in the list.
    @param aTarget the item's target
    @param anAction the item's action
*/
- (int)indexOfItemWithTarget:(id)aTarget action:(SEL)anAction
{
    return [_menu indexOfItemWithTarget:aTarget action:anAction];
}

// Setting the Cell Edge to Pop out in Restricted Situations
/*!
    Returns the button's edge where the pop-up menu will be
    displayed when there is not enough room to display directly
    above the button.
*/
- (CPRectEdge)preferredEdge
{
    return _preferredEdge;
}

/*!
    Sets the preffered edge of the button to display the
    pop-up when there is a limited amount of screen space.
    By default, the pop-up should draw on top of the button.
*/
- (void)setPreferredEdge:(CPRectEdge)aRectEdge
{
    _preferredEdge = aRectEdge;
}

// Setting the Title
/*!
    Sets the pop-up button's title.
    @param aTitle the new title
*/
- (void)setTitle:(CPString)aTitle
{
    if ([self title] === aTitle)
        return;

    if ([self pullsDown])
    {
        var items = [_menu itemArray];

        if ([items count] <= 0)
            [self addItemWithTitle:aTitle];

        else
        {
            [items[0] setTitle:aTitle];
            [self synchronizeTitleAndSelectedItem];
        }
    }
    else
    {
        var index = [self indexOfItemWithTitle:aTitle];

        if (index < 0)
        {
            [self addItemWithTitle:aTitle];

            index = [self numberOfItems] - 1;
        }

        [self selectItemAtIndex:index];
    }
}

// Setting the Image
/*!
    This method has no effect. Because the image is taken
    from the currently selected item, this method serves
    no purpose.
*/
- (void)setImage:(CPImage)anImage
{
    // The Image is set by the currently selected item.
}

// Setting the State
/*!
    Makes sure the selected item and the item
    being displayed are one and the same.
*/
- (void)synchronizeTitleAndSelectedItem
{
    var item = nil;

    if ([self pullsDown])
    {
        var items = [_menu itemArray];

        if ([items count] > 0)
            item = items[0];
    }
    else
        item = [self selectedItem];

    [super setImage:[item image]];
    [super setTitle:[item title]];
}

//
/*!
    Called when the menu has a new item added to it.
    @param aNotification information about the event
*/
- (void)menuDidAddItem:(CPNotification)aNotification
{
    var index = [[aNotification userInfo] objectForKey:@"CPMenuItemIndex"];

    if (_selectedIndex < 0)
        [self selectItemAtIndex:0];

    else if (index == _selectedIndex)
        [self synchronizeTitleAndSelectedItem];

    else if (index < _selectedIndex)
        ++_selectedIndex;

    if (index == 0 && [self pullsDown])
    {
        var items = [_menu itemArray];

        [items[0] setHidden:YES];

        if (items.length > 0)
            [items[1] setHidden:NO];
    }

    var item = [_menu itemArray][index],
        action = [item action];

    if (!action || (action === @selector(_popUpItemAction:)))
    {
        [item setTarget:self];
        [item setAction:@selector(_popUpItemAction:)];
    }
}

/*!
    Called when a menu item has changed.
    @param aNotification information about the event
*/
- (void)menuDidChangeItem:(CPNotification)aNotification
{
    var index = [[aNotification userInfo] objectForKey:@"CPMenuItemIndex"];

    if ([self pullsDown] && index != 0)
        return;

    if (![self pullsDown] && index != _selectedIndex)
        return;

    [self synchronizeTitleAndSelectedItem];
}

/*!
    Called when an item was removed from the menu.
    @param aNotification information about the event
*/
- (void)menuDidRemoveItem:(CPNotification)aNotification
{
    var numberOfItems = [self numberOfItems];

    if (numberOfItems <= _selectedIndex && numberOfItems > 0)
        [self selectItemAtIndex:numberOfItems - 1];
    else
        [self synchronizeTitleAndSelectedItem];
}

- (void)mouseDown:(CPEvent)anEvent
{
    if (![self isEnabled] || ![self numberOfItems])
        return;

    [self highlight:YES];

    var menu = [self menu],
        bounds = [self bounds],
        minimumWidth = CGRectGetWidth(bounds);

    // FIXME: setFont: should set the font on the menu.
    [menu setFont:[self font]];

    if ([self pullsDown])
    {
        var positionedItem = nil,
            location = CGPointMake(0.0, CGRectGetMaxY(bounds));
    }
    else
    {
        var contentRect = [self contentRectForBounds:bounds],
            positionedItem = [self selectedItem],
            standardLeftMargin = [_CPMenuWindow _standardLeftMargin] + [_CPMenuItemStandardView _standardLeftMargin],
            location = CGPointMake(CGRectGetMinX(contentRect) - standardLeftMargin, 0.0);

        minimumWidth += standardLeftMargin;

        // To ensure the selected item is highlighted correctly, unset the highlighted item
        [menu _highlightItemAtIndex:CPNotFound];
    }

    [menu setMinimumWidth:minimumWidth];

    [menu
        _popUpMenuPositioningItem:positionedItem
                       atLocation:location
                             topY:CGRectGetMinY(bounds)
                          bottomY:CGRectGetMaxY(bounds)
                           inView:self
                         callback:function(aMenu)
        {
            [self highlight:NO];

            var highlightedItem = [aMenu highlightedItem];

            if ([highlightedItem _isSelectable])
                [self selectItem:highlightedItem];
        }];
/*
    else
    {
        // This is confusing, I KNOW, so let me explain it to you.
        // We want the *content* of the selected menu item to overlap the *content* of our pop up.
        // 1. So calculate where our content is, then calculate where the menu item is.
        // 2. Move LEFT by whatever indentation we have (offsetWidths, aka, window margin, item margin, etc).
        // 3. MOVE UP by the difference in sizes of the content and menu item, this will only work if the content is vertically centered.
        var contentRect = [self convertRect:[self contentRectForBounds:bounds] toView:nil],
            menuOrigin = [theWindow convertBaseToGlobal:contentRect.origin],
            menuItemRect = [menuWindow rectForItemAtIndex:_selectedIndex];

        menuOrigin.x -= CGRectGetMinX(menuItemRect) + [menuWindow overlapOffsetWidth] + [[[menu itemAtIndex:_selectedIndex] _menuItemView] overlapOffsetWidth];
        menuOrigin.y -= CGRectGetMinY(menuItemRect) + (CGRectGetHeight(menuItemRect) - CGRectGetHeight(contentRect)) / 2.0;
    }
*/
}

- (void)rightMouseDown:(CPEvent)anEvent
{
    // Disable standard CPView behaviour which incorrectly displays the menu as a 'context menu'.
}

- (void)_popUpItemAction:(id)aSender
{
    [self sendAction:[self action] to:[self target]];
}

- (void)takeValueFromKeyPath:(CPString)aKeyPath ofObjects:(CPArray)objects
{
    var count = objects.length,
        value = [objects[0] valueForKeyPath:aKeyPath];

    [self selectItemWithTag:value];
    [self setEnabled:YES];

    while (count-- > 1)
    {
        if (value !== [objects[count] valueForKeyPath:aKeyPath])
        {
            [[self selectedItem] setState:CPOffState];
        }
    }
}

@end

var CPPopUpButtonMenuKey            = @"CPPopUpButtonMenuKey",
    CPPopUpButtonSelectedIndexKey   = @"CPPopUpButtonSelectedIndexKey",
    CPPopUpButtonPullsDownKey       = @"CPPopUpButtonPullsDownKey";

@implementation CPPopUpButton (CPCoding)
/*!
    Initializes the pop-up button with data from the
    specified coder.
    @param aCoder the coder from which to read
    the data
    @return the initialized pop-up button
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        // Nothing is currently selected
        _selectedIndex = -1;

        [self setMenu:[aCoder decodeObjectForKey:CPPopUpButtonMenuKey]];
        [self selectItemAtIndex:[aCoder decodeObjectForKey:CPPopUpButtonSelectedIndexKey]];
    }

    return self;
}

/*!
    Encodes the data of the pop-up button into a coder
    @param aCoder the coder to which the data
    will be written
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_menu forKey:CPPopUpButtonMenuKey];
    [aCoder encodeInt:_selectedIndex forKey:CPPopUpButtonSelectedIndexKey];
}

@end
