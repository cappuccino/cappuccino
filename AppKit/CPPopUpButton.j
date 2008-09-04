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

import "CPButton.j"
import "CPGeometry.j"
import "CPMenu.j"
import "CPMenuItem.j"


var VISIBLE_MARGIN  = 7.0;

var CPPopUpButtonArrowsImage = nil;

@implementation CPPopUpButton : CPButton
{
    BOOL        _pullsDown;
    int         _selectedIndex;
    CPRectEdge  _preferredEdge;
    
    CPImageView _arrowsView;
    
    CPMenu      _menu;
}

- (id)initWithFrame:(CGRect)aFrame pullsDown:(BOOL)shouldPullDown
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _pullsDown = shouldPullDown;
        _selectedIndex = CPNotFound;
        _preferredEdge = CPMaxYEdge;
        
        [self setBezelStyle:CPTexturedRoundedBezelStyle];
        
        [self setImagePosition:CPImageLeft];
        [self setAlignment:CPLeftTextAlignment];
        
        [self setMenu:[[CPMenu alloc] initWithTitle:@""]];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)aFrame
{
    return [self initWithFrame:aFrame pullsDown:NO];
}

- (void)setBordered:(BOOL)shouldBeBordered
{
    if (shouldBeBordered)
    {
        var bounds = [self bounds];
        
        _arrowsView = [[CPImageView alloc] initWithFrame:CGRectMake(CGRectGetWidth(bounds) - 10.0, (CGRectGetHeight(bounds) - 8.0) / 2.0, 5.0, 8.0)];
        
        if (!CPPopUpButtonArrowsImage)
            CPPopUpButtonArrowsImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[CPPopUpButton class]] pathForResource:@"CPPopUpButton/CPPopUpButtonArrows.png"] size:CGSizeMake(5.0, 8.0)];
        
        [_arrowsView setImage:CPPopUpButtonArrowsImage];
        [_arrowsView setAutoresizingMask:CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
        
        
        [self addSubview:_arrowsView];
    }
    else
    {
        [_arrowsView removeFromSuperview];
        
        _arrowsView = nil;
    }
    
    [super setBordered:shouldBeBordered];
}

// Setting the Type of Menu

- (void)setPullsDown:(BOOL)shouldPullDown
{
    if (_pullsDown == shouldPullDown)
        return;
    
    _pullsDown = shouldPullDown;

    var items = [_menu itemArray];
    
    if (items.length <= 0)
        return;
    
    [items[0] setHidden:_pullsDown];
    
    [self synchronizeTitleAndSelectedItem];
}

- (BOOL)pullsDown
{
    return _pullsDown;
}

// Inserting and Deleting Items

- (void)addItemWithTitle:(CPString)aTitle
{
    [_menu addItemWithTitle:aTitle action:NULL keyEquivalent:NULL];
}

- (void)addItemsWithTitles:(CPArray)titles
{
    var index = 0,
        count = [titles count];
    
    for (; index < count; ++index)
        [self addItemWithTitle:titles[index]];
}

- (void)insertItemWithTitle:(CPString)aTitle atIndex:(int)anIndex
{
    var items = [self itemArray],
        count = [items count];
    
    while (count--)
        if ([items[count] title] == aTitle)
            [self removeItemAtIndex:count];
        
    [_menu insertItemWithTitle:aTitle action:NULL keyEquivalent:NULL atIndex:anIndex];
}

- (void)removeAllItems
{
    var count = [_menu numberOfItems];
    
    while (count--)
        [_menu removeItemAtIndex:0];
}

- (void)removeItemWithTitle:(CPString)aTitle
{
    [self removeItemAtIndex:[self indexOfItemWithTitle:aTitle]];
    [self synchronizeTitleAndSelectedItem];
}

- (void)removeItemAtIndex:(int)anIndex
{
    [_menu removeItemAtIndex:anIndex];
    [self synchronizeTitleAndSelectedItem];
}

// Getting the User's Selection

- (CPMenuItem)selectedItem
{
    if (_selectedIndex < 0)
        return nil;
    
    return [_menu itemAtIndex:_selectedIndex];
}

- (CPString)titleOfSelectedItem
{
    return [[self selectedItem] title];
}

- (int)indexOfSelectedItem
{
    return _selectedIndex;
}

// For us, CPNumber is toll-free bridged to Number, so just return the selected index.
- (id)objectValue
{
    return _selectedIndex;
}

// Setting the Current Selection

- (void)selectItem:(CPMenuItem)aMenuItem
{
    [self selectItemAtIndex:[self indexOfItem:aMenuItem]];
}

- (void)selectItemAtIndex:(int)anIndex
{
    if (_selectedIndex == anIndex)
        return;
    
    if (_selectedIndex >= 0 && !_pullsDown)
        [[self selectedItem] setState:CPOffState];
    
    _selectedIndex = anIndex;

    if (_selectedIndex >= 0 && !_pullsDown)
        [[self selectedItem] setState:CPOnState];
    
    [self synchronizeTitleAndSelectedItem];
}

- (void)selectItemWithTag:(int)aTag
{
    [self selectItemAtIndex:[self indexOfItemWithTag:aTag]];
}

- (void)selectItemWithTitle:(CPString)aTitle
{
    [self selectItemAtIndex:[self indexOfItemWithTitle:aTitle]];
}

- (void)setObjectValue:(id)aValue
{
    [self selectItemAtIndex:[aValue intValue]];
}

// Getting Menu Items

- (CPMenu)menu
{
    return _menu;
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
                  selector:@selector(menuDidAddItem:)
                      name:CPMenuDidAddItemNotification
                    object:_menu];

        [defaultCenter
            removeObserver:self
                  selector:@selector(menuDidChangeItem:)
                      name:CPMenuDidChangeItemNotification
                    object:_menu];

        [defaultCenter
            removeObserver:self
                  selector:@selector(menuDidRemoveItem:)
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

- (int)numberOfItems
{
    return [_menu numberOfItems];
}

- (CPArray)itemArray
{
    return [_menu itemArray];
}

- (CPMenuItem)itemAtIndex:(unsigned)anIndex
{
    return [_menu itemAtIndex:anIndex];
}

- (CPString)itemTitleAtIndex:(unsigned)anIndex
{
    return [[_menu itemAtIndex:anIndex] title];
}

- (CPArray)itemTitles
{
    var titles = [],
        items = [self itemArray],
        
        index = 0,
        count = [items count];
    
    for (; index < count; ++index)
        items.push([items[index] title]);
}

- (CPMenuItem)itemWithTitle:(CPString)aTitle
{
    return [_menu itemAtIndex:[_menu indexOfItemWithTitle:aTitle]];
}

- (CPMenuItem)lastItem
{
    return [[_menu itemArray] lastObject];
}

// Getting the Indices of Menu Items

- (int)indexOfItem:(CPMenuItem)aMenuItem
{
    return [_menu indexOfItem:aMenuItem];
}

- (int)indexOfItemWithTag:(int)aTag
{
    return [_menu indexOfItemWithTag:aMenuItem];
}

- (int)indexOfItemWithTitle:(CPString)aTitle
{
    return [_menu indexOfItemWithTitle:aTitle];
}

- (int)indexOfItemWithRepresentedObject:(id)anObject
{
    return [_menu indexOfItemWithRepresentedObejct:anObject];
}

- (int)indexOfItemWithTarget:(id)aTarget action:(SEL)anAction
{
    return [_menu indexOfItemWithTarget:aTarget action:anAction];
}

// Setting the Cell Edge to Pop out in Restricted Situations

- (CPRectEdge)preferredEdge
{
    return _preferredEdge;
}

- (void)setPreferredEdge:(CPRectEdge)aRectEdge
{
    _preferredEdge = aRectEdge;
}

// Setting the Title

- (void)setTitle:(CPString)aTitle
{
    if ([self title] == aTitle)
        return;
    
    if (_pullsDown)
    {
        [_items[0] setTitle:aTitle];
        [self synchronizeTitleAndSelectedItem];
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

- (void)setImage:(CPImage)anImage
{
    // The Image is set by the currently selected item.
}

// Setting the State

- (void)synchronizeTitleAndSelectedItem
{
    var item = nil;

    if (_pullsDown)
    {
        var items = [_menu itemArray];
        
        if (items.length > 0)
            item = items[0];
    }
    else
        item = [self selectedItem];

    [super setImage:[item image]];
    [super setTitle:[item title]];
}

//

- (void)menuDidAddItem:(CPNotification)aNotification
{
    var index = [[aNotification userInfo] objectForKey:@"CPMenuItemIndex"];
    
    if (_selectedIndex < 0)
        [self selectItemAtIndex:0];
    
    else if (index == _selectedIndex)
        [self synchronizeTitleAndSelectedItem];
        
    else if (index < _selectedIndex)
        ++_selectedIndex;
        
    if (index == 0 && _pullsDown)
    {
        var items = [_menu itemArray];
        
        [items[0] setHidden:YES];
        
        if (items.length > 0)
            [items[1] setHidden:NO];
    }
}

- (void)menuDidChangeItem:(CPNotification)aNotification
{
    var index = [[aNotification userInfo] objectForKey:@"CPMenuItemIndex"];

    if (_pullsDown && index != 0)
        return;
    
    if (!_pullsDown && index != _selectedIndex)
        return;
    
    [self synchronizeTitleAndSelectedItem];
}

- (void)menuDidRemoveItem:(CPNotification)aNotification
{
    var numberOfItems = [self numberOfItems];
    
    if (numberOfItems <= _selectedIndex)
        [self selectItemAtIndex:numberOfItems - 1];
}

- (void)mouseDown:(CPEvent)anEvent
{
    if (![self isEnabled])
        return;
        
    [self highlight:YES];

    var theWindow = [self window],
        menuWindow = [_CPMenuWindow menuWindowWithMenu:[self menu] font:[self font]];
    
    [menuWindow setDelegate:self];
    [menuWindow setBackgroundStyle:_CPMenuWindowPopUpBackgroundStyle];
    
    var menuOrigin = [theWindow convertBaseToBridge:[self convertPoint:CGPointMakeZero() toView:nil]];
    
    // Pull Down Menus show up directly below their buttons.
    if (_pullsDown)
        menuOrigin.y += CGRectGetHeight([self frame]);
    
    // Pop Up Menus attempt to show up "on top" of the selected item.
    else
    {
        var contentRect = [menuWindow rectForItemAtIndex:_selectedIndex];
        
        menuOrigin.x -= CGRectGetMinX(contentRect) + [_CPMenuItemView leftMargin];
        menuOrigin.y -= CGRectGetMinY(contentRect);
    }
    
    [menuWindow setFrameOrigin:menuOrigin];
    
    var menuMaxX = CGRectGetMaxX([menuWindow frame]),
        buttonMaxX = CGRectGetMaxX([self convertRect:[self bounds] toView:nil]);
        
    if (menuMaxX < buttonMaxX)
        [menuWindow setMinWidth:CGRectGetWidth([menuWindow frame]) + buttonMaxX - menuMaxX - VISIBLE_MARGIN];
    
    [menuWindow orderFront:self];
    [menuWindow beginTrackingWithEvent:anEvent sessionDelegate:self didEndSelector:@selector(menuWindowDidFinishTracking:highlightedItem:)];
}

- (void)menuWindowDidFinishTracking:(_CPMenuWindow)aMenuWindow highlightedItem:(CPMenuItem)aMenuItem
{
    [_CPMenuWindow poolMenuWindow:aMenuWindow];

    [self highlight:NO];
    
    var index = [_menu indexOfItem:aMenuItem];
    
    if (index == CPNotFound)
        return;
    
    [self selectItemAtIndex:index];
    
    var selectedItem = [self selectedItem],
        target = nil,
        action = [selectedItem action];
    
    if (!action)
    {
        target = [self target];
        action = [self action];
    }
    
    // FIXME: If [selectedItem target] == nil do we use our own target?
    else
        target = [selectedItem target];

    [self sendAction:action to:target];
}

@end

var CPPopUpButtonMenuKey            = @"CPPopUpButtonMenuKey",
    CPPopUpButtonSelectedIndexKey   = @"CPPopUpButtonSelectedIndexKey",
    CPPopUpButtonPullsDownKey       = @"CPPopUpButtonPullsDownKey";

@implementation CPPopUpButton (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    
    if (self)
    {
        [self setMenu:[aCoder decodeObjectForKey:CPPopUpButtonMenuKey]];
        [self selectItemAtIndex:[aCoder decodeObjectForKey:CPPopUpButtonSelectedIndexKey]];
        [self setPullsDown:[aCoder decodeBoolForKey:CPPopUpButtonPullsDownKey]];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:_menu forKey:CPPopUpButtonMenuKey];
    [aCoder encodeInt:_selectedIndex forKey:CPPopUpButtonSelectedIndexKey];
    [aCoder encodeBool:_pullsDown forKey:CPPopUpButtonPullsDownKey];
}

@end
