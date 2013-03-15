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

@import "CGGeometry.j"
@import "CPButton.j"
@import "CPKeyValueBinding.j"
@import "CPMenu.j"
@import "CPMenuItem.j"

var VISIBLE_MARGIN = 7.0;

CPPopUpButtonStatePullsDown = CPThemeState("pulls-down");

/*!
    @ingroup appkit
    @class CPPopUpButton

    A CPPopUpButton contains a pop-up menu of items that a user can select from.
*/
@implementation CPPopUpButton : CPButton
{
    CPUInteger  _selectedIndex;
    CPRectEdge  _preferredEdge;
}

+ (CPString)defaultThemeClass
{
    return "popup-button";
}

+ (CPSet)keyPathsForValuesAffectingSelectedIndex
{
    return [CPSet setWithObject:@"objectValue"];
}

+ (CPSet)keyPathsForValuesAffectingSelectedTag
{
    return [CPSet setWithObject:@"objectValue"];
}

+ (CPSet)keyPathsForValuesAffectingSelectedItem
{
    return [CPSet setWithObject:@"objectValue"];
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
        [self selectItemAtIndex:CPNotFound];

        _preferredEdge = CPMaxYEdge;

        [self setValue:CPImageLeft forThemeAttribute:@"image-position"];
        [self setValue:CPLeftTextAlignment forThemeAttribute:@"alignment"];
        [self setValue:CPLineBreakByTruncatingTail forThemeAttribute:@"line-break-mode"];

        [self setMenu:[[CPMenu alloc] initWithTitle:@""]];

        [self setPullsDown:shouldPullDown];

        var options = CPKeyValueObservingOptionNew | CPKeyValueObservingOptionOld; // | CPKeyValueObservingOptionInitial;
        [self addObserver:self forKeyPath:@"menu.items" options:options context:nil];
        [self addObserver:self forKeyPath:@"_firstItem.changeCount" options:options context:nil];
        [self addObserver:self forKeyPath:@"selectedItem.changeCount" options:options context:nil];
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
    If the button pulls down the menu items represent actions, not states.
    So the text in the button will NOT change when the user selects something different.

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

    var items = [[self menu] itemArray];

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
    [[self menu] addItem:anItem];
}

/*!
    Adds a new menu item with the specified title.
    @param the new menu item's title
*/
- (void)addItemWithTitle:(CPString)aTitle
{
    [[self menu] addItemWithTitle:aTitle action:NULL keyEquivalent:nil];
}

/*!
    Adds multiple new menu items with the titles specified in the provided array.
    @param titles an array of names for the new items
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
    @param aTitle the new item's title
    @param anIndex the item's index in the menu
*/
- (void)insertItemWithTitle:(CPString)aTitle atIndex:(int)anIndex
{
    var items = [self itemArray],
        count = [items count];

    while (count--)
        if ([items[count] title] == aTitle)
            [self removeItemAtIndex:count];

    [[self menu] insertItemWithTitle:aTitle action:NULL keyEquivalent:nil atIndex:anIndex];
}

/*!
    Removes all menu items from the pop-up button's menu
*/
- (void)removeAllItems
{
    [[self menu] removeAllItems];
    [self synchronizeTitleAndSelectedItem];
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
    [[self menu] removeItemAtIndex:anIndex];
    [self synchronizeTitleAndSelectedItem];
}

// Getting the User's Selection
/*!
    Returns the selected item or \c nil if no item is selected.
*/
- (CPMenuItem)selectedItem
{
    var indexOfSelectedItem = [self indexOfSelectedItem];

    if (indexOfSelectedItem < 0 || indexOfSelectedItem > [self numberOfItems] - 1)
        return nil;

    return [[self menu] itemAtIndex:indexOfSelectedItem];
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
- (void)selectItemAtIndex:(CPUInteger)anIndex
{
    [self setObjectValue:anIndex];
}

- (void)setSelectedIndex:(CPUInteger)anIndex
{
    [self setObjectValue:anIndex];
}

- (CPUInteger)selectedIndex
{
    return [self objectValue];
}

/*!
    Selects the item at the specified index
    @param anIndex the index of the item to select
*/
- (void)setObjectValue:(int)anIndex
{
    var indexOfSelectedItem = [self objectValue];

    anIndex = parseInt(+anIndex, 10);

    if (indexOfSelectedItem === anIndex)
        return;

    if (indexOfSelectedItem >= 0 && ![self pullsDown])
        [[self selectedItem] setState:CPOffState];

    _selectedIndex = anIndex;

    if (indexOfSelectedItem >= 0 && ![self pullsDown])
        [[self selectedItem] setState:CPOnState];

    [self synchronizeTitleAndSelectedItem];
}

- (id)objectValue
{
    return _selectedIndex;
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

// Getting Menu Items

/*!
    Returns a count of the number of items in the button's menu.
*/
- (int)numberOfItems
{
    return [[self menu] numberOfItems];
}

/*!
    Returns an array of the items in the menu
*/
- (CPArray)itemArray
{
    return [[self menu] itemArray];
}

/*!
    Returns the item at the specified index or \c nil if the item does not exist.
    @param anIndex the index of the item to obtain
*/
- (CPMenuItem)itemAtIndex:(unsigned)anIndex
{
    return [[self menu] itemAtIndex:anIndex];
}

/*!
    Returns the title of the item at the specified index or \c nil if no item exists.
    @param anIndex the index of the item
*/
- (CPString)itemTitleAtIndex:(unsigned)anIndex
{
    return [[[self menu] itemAtIndex:anIndex] title];
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
    var menu = [self menu],
        itemIndex = [menu indexOfItemWithTitle:aTitle];

    if (itemIndex === CPNotFound)
        return nil;

    return [menu itemAtIndex:itemIndex];
}

/*!
    Returns the last menu item
*/
- (CPMenuItem)lastItem
{
    return [[[self menu] itemArray] lastObject];
}

// Getting the Indices of Menu Items
/*!
    Returns the index of the specified item or CPNotFound if the item is not in the list.
    @param aMenuItem the item to obtain the index for
*/
- (int)indexOfItem:(CPMenuItem)aMenuItem
{
    return [[self menu] indexOfItem:aMenuItem];
}

/*!
    Returns the index of the item with the specified tag or CPNotFound if the item is not in the list.
    @param aTag the item's tag
*/
- (int)indexOfItemWithTag:(int)aTag
{
    return [[self menu] indexOfItemWithTag:aTag];
}

/*!
    Returns the index of the item with the specified title or CPNotFound.
    @param aTitle the item's title
*/
- (int)indexOfItemWithTitle:(CPString)aTitle
{
    return [[self menu] indexOfItemWithTitle:aTitle];
}

/*!
    Returns the index of the item with the specified
    represented object or CPNotFound
    if a match does not exist.
    @param anObject the item's represented object
*/
- (int)indexOfItemWithRepresentedObject:(id)anObject
{
    return [[self menu] indexOfItemWithRepresentedObject:anObject];
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
    return [[self menu] indexOfItemWithTarget:aTarget action:anAction];
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
    Sets the preferred edge of the button to display the
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
        var items = [[self menu] itemArray];

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
        var items = [[self menu] itemArray];

        if ([items count] > 0)
            item = items[0];
    }
    else
        item = [self selectedItem];

    [super setImage:[item image]];
    [super setTitle:[item title]];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)changes context:(id)aContext
{
    var pullsDown = [self pullsDown];

    if (!pullsDown && aKeyPath === @"selectedItem.changeCount" ||
        pullsDown && (aKeyPath === @"_firstItem" || aKeyPath === @"_firstItem.changeCount"))
        [self synchronizeTitleAndSelectedItem];

    // FIXME: This is due to a bug in KVO, we should never get it for "menu".
    if (aKeyPath === @"menu")
    {
        aKeyPath = @"menu.items";

        [changes setObject:CPKeyValueChangeSetting forKey:CPKeyValueChangeKindKey];
        [changes setObject:[[self menu] itemArray] forKey:CPKeyValueChangeNewKey];
    }

    if (aKeyPath === @"menu.items")
    {
        var changeKind = [changes objectForKey:CPKeyValueChangeKindKey],
            indexOfSelectedItem = [self indexOfSelectedItem];

        if (changeKind === CPKeyValueChangeRemoval)
        {
            var index = CPNotFound,
                indexes = [changes objectForKey:CPKeyValueChangeIndexesKey];

            if ([indexes containsIndex:0] && [self pullsDown])
                [self _firstItemDidChange];

            if (![self pullsDown] && [indexes containsIndex:indexOfSelectedItem])
            {
                // If the selected item is removed the first item becomes selected.
                indexOfSelectedItem = 0;
            }
            else
            {
                // See whether the index has changed, despite the actual item not changing.
                while ((index = [indexes indexGreaterThanIndex:index]) !== CPNotFound &&
                        index <= indexOfSelectedItem)
                    --indexOfSelectedItem;
            }

            [self selectItemAtIndex:indexOfSelectedItem];
        }

        else if (changeKind === CPKeyValueChangeReplacement)
        {
            var indexes = [changes objectForKey:CPKeyValueChangeIndexesKey];

            if (pullsDown && [indexes containsIndex:0] ||
                !pullsDown && [indexes containsIndex:indexOfSelectedItem])
                [self synchronizeTitleAndSelectedItem];
        }

        else
        {
            // No matter what, we want to prepare the new items.
            var newItems = [changes objectForKey:CPKeyValueChangeNewKey];

            [newItems enumerateObjectsUsingBlock:function(aMenuItem)
            {
                var action = [aMenuItem action];

                if (!action)
                    [aMenuItem setAction:action = @selector(_popUpItemAction:)];

                if (action === @selector(_popUpItemAction:))
                    [aMenuItem setTarget:self];
            }];

            if (changeKind === CPKeyValueChangeSetting)
            {
                [self _firstItemDidChange];

                [self selectItemAtIndex:CPNotFound];
                [self selectItemAtIndex:MIN([newItems count] - 1, indexOfSelectedItem)];
            }

            else //if (changeKind === CPKeyValueChangeInsertion)
            {
                var indexes = [changes objectForKey:CPKeyValueChangeIndexesKey];

                if ([self pullsDown] && [indexes containsIndex:0])
                {
                    [self _firstItemDidChange];

                    if ([self numberOfItems] > 1)
                    {
                        var index = CPNotFound,
                            originalIndex = 0;

                        while ((index = [indexes indexGreaterThanIndex:index]) !== CPNotFound &&
                                index <= originalIndex)
                            ++originalIndex;

                        [[self itemAtIndex:originalIndex] setHidden:NO];
                    }
                }

                if (indexOfSelectedItem < 0)
                    [self selectItemAtIndex:0];

                else
                {
                    var index = CPNotFound;

                    // See whether the index has changed, despite the actual item not changing.
                    while ((index = [indexes indexGreaterThanIndex:index]) !== CPNotFound &&
                            index <= indexOfSelectedItem)
                        ++indexOfSelectedItem;

                    [self selectItemAtIndex:indexOfSelectedItem];
                }
            }
        }
    }

//    [super observeValueForKeyPath:aKeyPath ofObject:anObject change:changes context:aContext];
}

- (void)mouseDown:(CPEvent)anEvent
{
    if (![self isEnabled] || ![self numberOfItems])
        return;

    var menu = [self menu];

    // Don't reopen the menu based on the same click which caused it to close, e.g. a click on this button.
    if (menu._lastCloseEvent === anEvent)
        return;

    [self highlight:YES];

    var bounds = [self bounds],
        minimumWidth = CGRectGetWidth(bounds);

    // FIXME: setFont: should set the font on the menu.
    [menu setFont:[self font]];

    if ([self pullsDown])
    {
        var positionedItem = nil,
            location = CGPointMake(0.0, CGRectGetMaxY(bounds) - 1);
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
    // Disable standard CPView behavior which incorrectly displays the menu as a 'context menu'.
}

- (void)_popUpItemAction:(id)aSender
{
    [self sendAction:[self action] to:[self target]];
}

- (void)_firstItemDidChange
{
    [self willChangeValueForKey:@"_firstItem"];
    [self didChangeValueForKey:@"_firstItem"];

    [[self _firstItem] setHidden:YES];
}

- (CPMenuItem)_firstItem
{
    if ([self numberOfItems] <= 0)
        return nil;

    return [[self menu] itemAtIndex:0];
}

- (void)takeValueFromKeyPath:(CPString)aKeyPath ofObjects:(CPArray)objects
{
    var count = objects.length,
        value = [objects[0] valueForKeyPath:aKeyPath];

    [self selectItemWithTag:value];
    [self setEnabled:YES];

    while (count-- > 1)
        if (value !== [objects[count] valueForKeyPath:aKeyPath])
            [[self selectedItem] setState:CPOffState];
}

- (void)_reverseSetBinding
{
    [_CPPopUpButtonSelectionBinder reverseSetValueForObject:self];

    [super _reverseSetBinding];
}

@end

@implementation CPPopUpButton (BindingSupport)

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding == CPSelectedIndexBinding ||
        aBinding == CPSelectedObjectBinding ||
        aBinding == CPSelectedTagBinding ||
        aBinding == CPSelectedValueBinding ||
        aBinding == CPContentBinding ||
        aBinding == CPContentObjectsBinding ||
        aBinding == CPContentValuesBinding)
    {
        var capitalizedBinding = aBinding.charAt(0).toUpperCase() + aBinding.substr(1);

        return [CPClassFromString(@"_CPPopUpButton" + capitalizedBinding + "Binder") class];
    }

    return [super _binderClassForBinding:aBinding];
}

@end

@implementation _CPPopUpButtonContentBinder : CPBinder
{
}

- (CPInteger)_getInsertNullOffset
{
    var options = [_info objectForKey:CPOptionsKey];

    return [options objectForKey:CPInsertsNullPlaceholderBindingOption] ? 1 : 0;
}

- (CPString)_getNullPlaceholder
{
    var options = [_info objectForKey:CPOptionsKey],
        placeholder = [options objectForKey:CPNullPlaceholderBindingOption] || @"";

    if (placeholder === [CPNull null])
        placeholder = @"";

    return placeholder;
}

- (id)transformValue:(CPArray)contentArray withOptions:(CPDictionary)options
{
    // Desactivate the full array transformation forced by super because we don't want this. We want individual transformations (see below).
    return contentArray;
}

- (void)setValue:(CPArray)contentArray forBinding:(CPString)aBinding
{
    [self _setContent:contentArray];
    [self _setContentValuesIfNeeded:contentArray];
}

- (void)valueForBinding:(CPString)aBinding
{
    return [self _content];
}

- (void)_setContent:(CPArray)aValue
{
    var count = [aValue count],
        options = [_info objectForKey:CPOptionsKey],
        offset = [self _getInsertNullOffset];

    if (count + offset != [_source numberOfItems])
    {
        [_source removeAllItems];

        if (offset)
            [_source addItemWithTitle:[self _getNullPlaceholder]];

        for (var i = 0; i < count; i++)
        {
            var item = [[CPMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:nil];
            [self _setValue:[aValue objectAtIndex:i] forItem:item withOptions:options];
            [_source addItem:item];
        }
    }
    else
    {
        for (var i = 0; i < count; i++)
        {
            [self _setValue:[aValue objectAtIndex:i] forItem:[_source itemAtIndex:i + offset] withOptions:options];
        }
    }
}

- (void)_setContentValuesIfNeeded:(CPArray)values
{
    var offset = [self _getInsertNullOffset];

    if (![_source infoForBinding:CPContentValuesBinding])
    {
        if (offset)
            [[_source itemAtIndex:0] setTitle:[self _getNullPlaceholder]];

        var count = [values count];

        for (var i = 0; i < count; i++)
            [[_source itemAtIndex:i + offset] setTitle:[[values objectAtIndex:i] description]];
    }
}

- (void)_setValue:(id)aValue forItem:(CPMenuItem)aMenuItem withOptions:(CPDictionary)options
{
    var value = [self _transformValue:aValue withOptions:options];
    [aMenuItem setRepresentedObject:value];
}

- (id)_transformValue:(id)aValue withOptions:(CPDictionary)options
{
    return [super transformValue:aValue withOptions:options];
}

- (CPArray)_content
{
    return [_source valueForKeyPath:@"itemArray.representedObject"];
}

@end

@implementation _CPPopUpButtonContentValuesBinder : _CPPopUpButtonContentBinder
{
}

- (void)setValue:(id)aValue forBinding:(CPString)aBinding
{
    [super _setContent:aValue];
}

- (void)_setValue:(id)aValue forItem:(CPMenuItem)aMenuItem withOptions:(CPDictionary)options
{
    if (aValue === [CPNull null])
        aValue = nil;

    var value = [self _transformValue:aValue withOptions:options];
    [aMenuItem setTitle:value];
}

- (CPArray)_content
{
    return [_source valueForKeyPath:@"itemArray.title"];
}

@end

var binderForObject = {};

@implementation _CPPopUpButtonSelectionBinder : CPBinder
{
    CPString _selectionBinding @accessors;
}

- (id)initWithBinding:(CPString)aBinding name:(CPString)aName to:(id)aDestination keyPath:(CPString)aKeyPath options:(CPDictionary)options from:(id)aSource
{
    self = [super initWithBinding:aBinding name:aName to:aDestination keyPath:aKeyPath options:options from:aSource];

    if (self)
    {
        binderForObject[[aSource UID]] = self;
        _selectionBinding = aName;
    }

    return self;
}

+ (void)reverseSetValueForObject:(id)aSource
{
    var binder = binderForObject[[aSource UID]];
    [binder reverseSetValueFor:[binder _selectionBinding]];
}

- (void)setPlaceholderValue:(id)aValue withMarker:(CPString)aMarker forBinding:(CPString)aBinding
{
    [self setValue:aValue forBinding:aBinding];
}

- (CPInteger)_getInsertNullOffset
{
    var options = [[CPBinder infoForBinding:CPContentBinding forObject:_source] objectForKey:CPOptionsKey];

    return [options objectForKey:CPInsertsNullPlaceholderBindingOption] ? 1 : 0;
}

@end

@implementation _CPPopUpButtonSelectedIndexBinder : _CPPopUpButtonSelectionBinder
{
}

- (void)setValue:(id)aValue forBinding:(CPString)aBinding
{
    [_source selectItemAtIndex:aValue + [self _getInsertNullOffset]];
}

- (id)valueForBinding:(CPString)aBinding
{
    return [_source indexOfSelectedItem] - [self _getInsertNullOffset];
}

@end

@implementation _CPPopUpButtonSelectedObjectBinder : _CPPopUpButtonSelectionBinder
{
}

- (void)setValue:(id)aValue forBinding:(CPString)aBinding
{
    var index = [_source indexOfItemWithRepresentedObject:aValue],
        offset = [self _getInsertNullOffset];

    // If the content binding has the option CPNullPlaceholderBindingOption and the object to select is nil, select the first item (i.e., the placeholder).
    // Other cases to consider:
    // 1. no binding:
    // 1.1 there's no item with a represented object matching the object to select.
    // 1.2 the object to select is nil/CPNull
    // 2. there's a binding:
    // 2.1 there's a CPNullPlaceholderBindingOption:
    // 2.1.1 there's no item with a represented object matching the object to select?
    // 2.1.2 the object to select is nil/CPNull
    // 2.2 there's no CPNullPlaceholderBindingOption:
    // 2.2.1 there's no item with a represented object matching the object to select?
    // 2.2.2 the object to select is nil/CPNull
    // More cases? Behaviour that depends on array controller settings?

    if (offset === 1 && index === CPNotFound)
        index = 0;

    [_source selectItemAtIndex:index];
}

- (id)valueForBinding:(CPString)aBinding
{
    return [[_source selectedItem] representedObject];
}

@end

@implementation _CPPopUpButtonSelectedTagBinder : _CPPopUpButtonSelectionBinder
{
}

- (void)setValue:(id)aValue forBinding:(CPString)aBinding
{
    [_source selectItemWithTag:aValue];
}

- (id)valueForBinding:(CPString)aBinding
{
    return [[_source selectedItem] tag];
}

@end

@implementation _CPPopUpButtonSelectedValueBinder : _CPPopUpButtonSelectionBinder
{
}

- (void)setValue:(id)aValue forBinding:(CPString)aBinding
{
    [_source selectItemWithTitle:aValue];
}

- (id)valueForBinding:(CPString)aBinding
{
    return [_source titleOfSelectedItem];
}

@end

var DEPRECATED_CPPopUpButtonMenuKey             = @"CPPopUpButtonMenuKey",
    DEPRECATED_CPPopUpButtonSelectedIndexKey    = @"CPPopUpButtonSelectedIndexKey";

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
        // FIXME: (or not?) _title is nulled in - [CPButton initWithCoder:],
        // so we need to do this again.
        [self synchronizeTitleAndSelectedItem];

        // FIXME: Remove deprecation leniency for 1.0
        if ([aCoder containsValueForKey:DEPRECATED_CPPopUpButtonMenuKey])
        {
            CPLog.warn(self + " was encoded with an older version of Cappuccino. Please nib2cib the original nib again or open and re-save in Atlas.");

            [self setMenu:[aCoder decodeObjectForKey:DEPRECATED_CPPopUpButtonMenuKey]];
            [self setObjectValue:[aCoder decodeObjectForKey:DEPRECATED_CPPopUpButtonSelectedIndexKey]];
        }

        var options = CPKeyValueObservingOptionNew | CPKeyValueObservingOptionOld;/* | CPKeyValueObservingOptionInitial */

        [self addObserver:self forKeyPath:@"menu.items" options:options context:nil];
        [self addObserver:self forKeyPath:@"_firstItem.changeCount" options:options context:nil];
        [self addObserver:self forKeyPath:@"selectedItem.changeCount" options:options context:nil];
    }

    return self;
}

@end
