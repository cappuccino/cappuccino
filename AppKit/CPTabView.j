/*
 * CPTabView.j
 * AppKit
 *
 * Created by Derek Hammer.
 * Copyright 2010, Derek Hammer.
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

@import "CPBox.j"
@import "CPSegmentedControl.j"
@import "CPTabViewItem.j"
@import "CPView.j"

CPTopTabsBezelBorder     = 0;
//CPLeftTabsBezelBorder  = 1;
CPBottomTabsBezelBorder  = 2;
//CPRightTabsBezelBorder = 3;
CPNoTabsBezelBorder      = 4; //Displays no tabs and has a bezeled border.
CPNoTabsLineBorder       = 5; //Has no tabs and displays a line border.
CPNoTabsNoBorder         = 6; //Displays no tabs and no border.

var CPTabViewDidSelectTabViewItemSelector           = 1,
    CPTabViewShouldSelectTabViewItemSelector        = 2,
    CPTabViewWillSelectTabViewItemSelector          = 4,
    CPTabViewDidChangeNumberOfTabViewItemsSelector  = 8;

/*!
    @ingroup appkit
    @class CPTabView

    A CPTabView object presents a tabbed interface where each page is one a
    complete view hiearchy of its own. The user can navigate between various
    pages by clicking on the tab headers.
*/
@implementation CPTabView : CPView
{
    CPArray             _items;

    CPSegmentedControl  _tabs;
    CPBox               _box;

    CPNumber            _selectedIndex;

    CPTabViewType       _type;
    CPFont              _font;

    id                  _delegate;
    unsigned            _delegateSelectors;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _items = [CPArray array];

        [self _init];
        [self setTabViewType:CPTopTabsBezelBorder];
    }

    return self;
}

- (void)_init
{
    _selectedIndex = CPNotFound;

    _tabs = [[CPSegmentedControl alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [_tabs setHitTests:NO];

    var height = [_tabs valueForThemeAttribute:@"default-height"];
    [_tabs setFrameSize:CGSizeMake(0, height)];

    _box = [[CPBox alloc] initWithFrame:[self  bounds]];
    [self setBackgroundColor:[CPColor colorWithCalibratedWhite:0.95 alpha:1.0]];

    [self addSubview:_box];
    [self addSubview:_tabs];
}

// Adding and Removing Tabs
/*!
    Adds a CPTabViewItem to the tab view.
    @param aTabViewItem the item to add
*/
- (void)addTabViewItem:(CPTabViewItem)aTabViewItem
{
    [self insertTabViewItem:aTabViewItem atIndex:[_items count]];
}

/*!
    Inserts a CPTabViewItem into the tab view at the specified index.
    @param aTabViewItem the item to insert
    @param anIndex the index for the item
*/
- (void)insertTabViewItem:(CPTabViewItem)aTabViewItem atIndex:(unsigned)anIndex
{
    [_items insertObject:aTabViewItem atIndex:anIndex];

    [self _updateItems];
    [self _repositionTabs];

    [aTabViewItem _setTabView:self];

    if (_delegateSelectors & CPTabViewDidChangeNumberOfTabViewItemsSelector)
        [_delegate tabViewDidChangeNumberOfTabViewItems:self];
}

/*!
    Removes the specified tab view item from the tab view.
    @param aTabViewItem the item to remove
*/
- (void)removeTabViewItem:(CPTabViewItem)aTabViewItem
{
    var count = [_items count];
    for (var i = 0; i < count; i++)
    {
        if ([_items objectAtIndex:i] === aTabViewItem)
        {
            [_items removeObjectAtIndex:i];
            break;
        }
    }

    [self _updateItems];
    [self _repositionTabs];

    [aTabViewItem _setTabView:nil];

    if (_delegateSelectors & CPTabViewDidChangeNumberOfTabViewItemsSelector)
        [_delegate tabViewDidChangeNumberOfTabViewItems:self];
}

// Accessing Tabs
/*!
    Returns the index of the specified item
    @param aTabViewItem the item to find the index for
    @return the index of aTabViewItem or CPNotFound
*/
- (int)indexOfTabViewItem:(CPTabViewItem)aTabViewItem
{
    return [_items indexOfObjectIdenticalTo:aTabViewItem];
}

/*!
    Returns the index of the CPTabViewItem with the specified identifier.
    @param anIdentifier the identifier of the item
    @return the index of the tab view item identified by anIdentifier, or CPNotFound
*/
- (int)indexOfTabViewItemWithIdentifier:(CPString)anIdentifier
{
    for (var index = [_items count]; index >= 0; index--)
        if ([[_items[index] identifier] isEqual:anIdentifier])
            return index;

    return CPNotFound;
}

/*!
    Returns the number of items in the tab view.
    @return the number of tab view items in the receiver
*/
- (unsigned)numberOfTabViewItems
{
    return [_items count];
}

/*!
    Returns the CPTabViewItem at the specified index.
    @return a tab view item, or nil
*/
- (CPTabViewItem)tabViewItemAtIndex:(unsigned)anIndex
{
    return [_items objectAtIndex:anIndex];
}

/*!
    Returns the array of items that backs this tab view.
    @return a copy of the array of items in the receiver
*/
- (CPArray)tabViewItems
{
    return [_items copy]; // Copy?
}

// Selecting a Tab
/*!
    Sets the first tab view item in the array to be displayed to the user.
    @param aSender the object making this request
*/
- (void)selectFirstTabViewItem:(id)aSender
{
    if ([_items count] === 0)
        return; // throw?

    [self selectTabViewItemAtIndex:0];
}

/*!
    Sets the last tab view item in the array to be displayed to the user.
    @param aSender the object making this request
*/
- (void)selectLastTabViewItem:(id)aSender
{
    if ([_items count] === 0)
        return; // throw?

    [self selectTabViewItemAtIndex:[_items count] - 1];
}

/*!
    Sets the next tab item in the array to be displayed.
    @param aSender the object making this request
*/
- (void)selectNextTabViewItem:(id)aSender
{
    if (_selectedIndex === CPNotFound)
        return;

    var nextIndex = _selectedIndex + 1;

    if (nextIndex === [_items count])
        // does nothing. According to spec at (http://developer.apple.com/mac/library/DOCUMENTATION/Cocoa/Reference/ApplicationKit/Classes/NSTabView_Class/Reference/Reference.html#//apple_ref/occ/instm/NSTabView/selectNextTabViewItem:)
        return;

    [self selectTabViewItemAtIndex:nextIndex];
}

/*!
    Selects the previous item in the array for display.
    @param aSender the object making this request
*/
- (void)selectPreviousTabViewItem:(id)aSender
{
    if (_selectedIndex === CPNotFound)
        return;

    var previousIndex = _selectedIndex - 1;

    if (previousIndex < 0)
        return; // does nothing. See above.

    [self selectTabViewItemAtIndex:previousIndex];
}

/*!
    Displays the specified item in the tab view.
    @param aTabViewItem the item to display
*/
- (void)selectTabViewItem:(CPTabViewItem)aTabViewItem
{
    [self selectTabViewItemAtIndex:[self indexOfTabViewItem:aTabViewItem]];
}

/*!
    Selects the item at the specified index.
    @param anIndex the index of the item to display.
*/
- (BOOL)selectTabViewItemAtIndex:(unsigned)anIndex
{
    if (anIndex === _selectedIndex)
        return;

    var aTabViewItem = [self tabViewItemAtIndex:anIndex];

    if ((_delegateSelectors & CPTabViewShouldSelectTabViewItemSelector) && ![_delegate tabView:self shouldSelectTabViewItem:aTabViewItem])
        return NO;

    if (_delegateSelectors & CPTabViewWillSelectTabViewItemSelector)
        [_delegate tabView:self willSelectTabViewItem:aTabViewItem];

    [_tabs selectSegmentWithTag:anIndex];
    [self _setSelectedIndex:anIndex];

    if (_delegateSelectors & CPTabViewDidSelectTabViewItemSelector)
        [_delegate tabView:self didSelectTabViewItem:aTabViewItem];

    return YES;
}

/*!
    Returns the current item being displayed.
    @return the tab view item currenly being displayed by the receiver
*/
- (CPTabViewItem)selectedTabViewItem
{
    if (_selectedIndex != CPNotFound)
        return [_items objectAtIndex:_selectedIndex];

    return nil;
}

// Modifying the font
/*!
    Returns the font for tab label text.
    @return the font for tab label text
*/
- (CPFont)font
{
    return _font;
}

/*!
    Sets the font for tab label text to font.
    @param font the font the receiver should use for tab label text
*/
- (void)setFont:(CPFont)font
{
    if ([_font isEqual:font])
        return;

    _font = font;
    [_tabs setFont:_font];
}

//
/*!
    Sets the tab view type.
    @param aTabViewType the view type
*/
- (void)setTabViewType:(CPTabViewType)aTabViewType
{
    if (_type === aTabViewType)
        return;

    _type = aTabViewType;

    if (_type !== CPTopTabsBezelBorder && _type !== CPBottomTabsBezelBorder)
        [_tabs removeFromSuperview];
    else
        [self addSubview:_tabs];

    switch (_type)
    {
        case CPTopTabsBezelBorder:
        case CPBottomTabsBezelBorder:
        case CPNoTabsBezelBorder:
            [_box setBorderType:CPBezelBorder];
            break;
        case CPNoTabsLineBorder:
            [_box setBorderType:CPLineBorder];
            break;
        case CPNoTabsNoBorder:
            [_box setBorderType:CPNoBorder];
            break;
    }

    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    // Even if CPTabView's autoresizesSubviews is NO, _tabs and _box has to be laid out.
    // This means we can't rely on autoresize masks.
    if (_type !== CPTopTabsBezelBorder && _type !== CPBottomTabsBezelBorder)
    {
        [_box setFrame:[self bounds]];
    }
    else
    {
        var aFrame = [self frame],
            segmentedHeight = CGRectGetHeight([_tabs frame]),
            origin = _type === CPTopTabsBezelBorder ? segmentedHeight / 2 : 0;

        [_box setFrame:CGRectMake(0, origin, CGRectGetWidth(aFrame),
                                   CGRectGetHeight(aFrame) - segmentedHeight / 2)];

        [self _repositionTabs];
    }
}

/*!
    Returns the tab view type.
    @return the tab view type of the receiver
*/
- (CPTabViewType)tabViewType
{
    return _type;
}

/*!
    Returns the receiver's delegate.
    @return the receiver's delegate
*/
- (id)delegate
{
    return _delegate;
}

/*!
    Sets the delegate for this tab view.
    @param aDelegate the tab view's delegate
*/
- (void)setDelegate:(id)aDelegate
{
    if (_delegate == aDelegate)
        return;

    _delegate = aDelegate;

    _delegateSelectors = 0;

    if ([_delegate respondsToSelector:@selector(tabView:shouldSelectTabViewItem:)])
        _delegateSelectors |= CPTabViewShouldSelectTabViewItemSelector;

    if ([_delegate respondsToSelector:@selector(tabView:willSelectTabViewItem:)])
        _delegateSelectors |= CPTabViewWillSelectTabViewItemSelector;

    if ([_delegate respondsToSelector:@selector(tabView:didSelectTabViewItem:)])
        _delegateSelectors |= CPTabViewDidSelectTabViewItemSelector;

    if ([_delegate respondsToSelector:@selector(tabViewDidChangeNumberOfTabViewItems:)])
        _delegateSelectors |= CPTabViewDidChangeNumberOfTabViewItemsSelector;
}

- (void)setBackgroundColor:(CPColor)aColor
{
    [_box setBackgroundColor:aColor];
}

- (CPColor)backgroundColor
{
    return [_box backgroundColor];
}

- (void)mouseDown:(CPEvent)anEvent
{
    var segmentIndex = [_tabs testSegment:[_tabs convertPoint:[anEvent locationInWindow] fromView:nil]];

    if (segmentIndex != CPNotFound && [self selectTabViewItemAtIndex:segmentIndex])
        [_tabs trackSegment:anEvent];
}

- (void)_repositionTabs
{
    var horizontalCenterOfSelf = CGRectGetWidth([self bounds]) / 2,
        verticalCenterOfTabs = CGRectGetHeight([_tabs bounds]) / 2;

    if (_type === CPBottomTabsBezelBorder)
        [_tabs setCenter:CGPointMake(horizontalCenterOfSelf, CGRectGetHeight([self bounds]) - verticalCenterOfTabs)];
    else
        [_tabs setCenter:CGPointMake(horizontalCenterOfSelf, verticalCenterOfTabs)];
}

- (void)_setSelectedIndex:(CPNumber)index
{
    _selectedIndex = index;
    [self _setContentViewFromItem:[_items objectAtIndex:_selectedIndex]];
}

- (void)_setContentViewFromItem:(CPTabViewItem)anItem
{
    [_box setContentView:[anItem view]];
}

- (void)_updateItems
{
    var count = [_items count];
    [_tabs setSegmentCount:count];

    for (var i = 0; i < count; i++)
    {
        [_tabs setLabel:[[_items objectAtIndex:i] label] forSegment:i];
        [_tabs setTag:i forSegment:i];
    }

    if (_selectedIndex === CPNotFound)
        [self selectFirstTabViewItem:self];
}

@end

var CPTabViewItemsKey               = "CPTabViewItemsKey",
    CPTabViewSelectedItemKey        = "CPTabViewSelectedItemKey",
    CPTabViewTypeKey                = "CPTabViewTypeKey",
    CPTabViewFontKey                = "CPTabViewFontKey",
    CPTabViewDelegateKey            = "CPTabViewDelegateKey";

@implementation CPTabView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        [self _init];

        _font = [aCoder decodeObjectForKey:CPTabViewFontKey];
        [_tabs setFont:_font];

        _items = [aCoder decodeObjectForKey:CPTabViewItemsKey];
        [_items makeObjectsPerformSelector:@selector(_setTabView:) withObject:self];

        [self setDelegate:[aCoder decodeObjectForKey:CPTabViewDelegateKey]];

        self.selectOnAwake = [aCoder decodeObjectForKey:CPTabViewSelectedItemKey];
        _type = [aCoder decodeIntForKey:CPTabViewTypeKey];
    }

    return self;
}

- (void)awakeFromCib
{
    // This cannot be run in initWithCoder because it might call selectTabViewItem:, which is
    // not safe to call before the views of the tab views items are fully decoded.
    [self _updateItems];

    if (self.selectOnAwake)
    {
        [self selectTabViewItem:self.selectOnAwake];
        delete self.selectOnAwake;
    }

    var type = _type;
    _type = nil;
    [self setTabViewType:type];

    [self setNeedsLayout];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    // Don't bother to encode the CPBox. We will recreate it on decode and its content view is already
    // stored by the tab view item. Not encoding _box makes the resulting archive smaller and reduces
    // the surface for decoding bugs (of which we've had many in tab view).
    var subviews = [self subviews];
    [_box removeFromSuperview];
    [super encodeWithCoder:aCoder];
    [self setSubviews:subviews];

    [aCoder encodeObject:_items forKey:CPTabViewItemsKey];

    var selected = [self selectedTabViewItem];
    if (selected)
        [aCoder encodeObject:selected forKey:CPTabViewSelectedItemKey];

    [aCoder encodeInt:_type forKey:CPTabViewTypeKey];
    [aCoder encodeObject:_font forKey:CPTabViewFontKey];

    [aCoder encodeConditionalObject:_delegate forKey:CPTabViewDelegateKey];
}

@end
