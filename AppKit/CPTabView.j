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

@typedef CPTabViewType
CPTopTabsBezelBorder     = 0;
//CPLeftTabsBezelBorder  = 1;
CPBottomTabsBezelBorder  = 2;
//CPRightTabsBezelBorder = 3;
CPNoTabsBezelBorder      = 4; //Displays no tabs and has a bezeled border.
CPNoTabsLineBorder       = 5; //Has no tabs and displays a line border.
CPNoTabsNoBorder         = 6; //Displays no tabs and no border.

@class _CPTabViewBox

var CPTabViewDidSelectTabViewItemSelector           = 1 << 1,
    CPTabViewShouldSelectTabViewItemSelector        = 1 << 2,
    CPTabViewWillSelectTabViewItemSelector          = 1 << 3,
    CPTabViewDidChangeNumberOfTabViewItemsSelector  = 1 << 4;


@protocol CPTabViewDelegate <CPObject>

@optional
- (BOOL)tabView:(CPTabView)tabView shouldSelectTabViewItem:(CPTabViewItem)tabViewItem;
- (void)tabView:(CPTabView)tabView didSelectTabViewItem:(CPTabViewItem)tabViewItem;
- (void)tabView:(CPTabView)tabView willSelectTabViewItem:(CPTabViewItem)tabViewItem;
- (void)tabViewDidChangeNumberOfTabViewItems:(CPTabView)tabView;

@end


/*!
    @ingroup appkit
    @class CPTabView

    A CPTabView object presents a tabbed interface where each page is one a
    complete view hiearchy of its own. The user can navigate between various
    pages by clicking on the tab headers.
*/
@implementation CPTabView : CPView
{
    CPArray                 _items;

    CPSegmentedControl      _tabs;
    _CPTabViewBox           _box;
    CPView                  _placeHolderView;

    CPTabViewItem           _selectedTabViewItem;

    CPTabViewType           _type;
    CPFont                  _font;

    id <CPTabViewDelegate>  _delegate;
    unsigned                _delegateSelectors;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self _init];
        _selectedTabViewItem = nil;
        [self setTabViewType:CPTopTabsBezelBorder];
    }

    return self;
}

- (void)_init
{
    _tabs = [[CPSegmentedControl alloc] initWithFrame:CGRectMakeZero()];
    [_tabs setHitTests:NO];
    [_tabs setSegments:[CPArray array]];

    var height = [_tabs valueForThemeAttribute:@"min-size"].height;
    [_tabs setFrameSize:CGSizeMake(0, height)];

    _box = [[_CPTabViewBox alloc] initWithFrame:[self  bounds]];
    [_box setTabView:self];
    [self setBackgroundColor:[CPColor colorWithCalibratedWhite:0.95 alpha:1.0]];

    [self addSubview:_box];
    [self addSubview:_tabs];

    _placeHolderView = nil;
}

- (CPArray)items
{
    return [_tabs segments];
}

// Adding and Removing Tabs
/*!
    Adds a CPTabViewItem to the tab view.
    @param aTabViewItem the item to add
*/
- (void)addTabViewItem:(CPTabViewItem)aTabViewItem
{
    [self insertTabViewItem:aTabViewItem atIndex:[self numberOfTabViewItems]];
}

/*!
    Inserts a CPTabViewItem into the tab view at the specified index.
    @param aTabViewItem the item to insert
    @param anIndex the index for the item
*/
- (void)insertTabViewItem:(CPTabViewItem)aTabViewItem atIndex:(CPUInteger)anIndex
{
    [self _insertTabViewItems:[aTabViewItem] atIndexes:[CPIndexSet indexSetWithIndex:anIndex]];
}

- (void)_insertTabViewItems:(CPArray)tabViewItems atIndexes:(CPIndexSet)indexes
{
    [_tabs insertSegments:tabViewItems atIndexes:indexes];
    [tabViewItems makeObjectsPerformSelector:@selector(_setTabView:) withObject:self];

    [self tileWithChangedItem:[tabViewItems firstObject]];
    [self _reverseSetContent];

    [self _sendDelegateTabViewDidChangeNumberOfTabViewItems];
}

/*!
    Removes the specified tab view item from the tab view.
    @param aTabViewItem the item to remove
*/
- (void)removeTabViewItem:(CPTabViewItem)aTabViewItem
{
    var idx = [[self items] indexOfObjectIdenticalTo:aTabViewItem];

    if (idx == CPNotFound)
        return;

    [_tabs removeSegmentsAtIndexes:[CPIndexSet indexSetWithIndex:idx]];
    [aTabViewItem _setTabView:nil];

    [self tileWithChangedItem:nil];
    [self _didRemoveTabViewItem:aTabViewItem atIndex:idx];
    [self _reverseSetContent];

    [self _sendDelegateTabViewDidChangeNumberOfTabViewItems];
}

- (void)_didRemoveTabViewItem:(CPTabViewItem)aTabViewItem atIndex:(CPInteger)idx
{
    // If the selection is managed by bindings, let the binder do that.
    if ([self binderForBinding:CPSelectionIndexesBinding] || [self binderForBinding:CPSelectedIndexBinding])
        return;

    if (_selectedTabViewItem == aTabViewItem)
    {
        var didSelect = NO;

        if (idx > 0)
            didSelect = [self selectTabViewItemAtIndex:idx - 1];
        else if ([self numberOfTabViewItems] > 0)
            didSelect = [self selectTabViewItemAtIndex:0];

        if (didSelect == NO)
            _selectedTabViewItem == nil;
    }
}

// Accessing Tabs
/*!
    Returns the index of the specified item
    @param aTabViewItem the item to find the index for
    @return the index of aTabViewItem or CPNotFound
*/
- (int)indexOfTabViewItem:(CPTabViewItem)aTabViewItem
{
    return [[self items] indexOfObjectIdenticalTo:aTabViewItem];
}

/*!
    Returns the index of the CPTabViewItem with the specified identifier.
    @param anIdentifier the identifier of the item
    @return the index of the tab view item identified by anIdentifier, or CPNotFound
*/
- (int)indexOfTabViewItemWithIdentifier:(CPString)anIdentifier
{
    return [[self items] indexOfObjectPassingTest:function(item, idx, stop)
    {
        return [[item identifier] isEqual:anIdentifier];
    }];
}

/*!
    Returns the number of items in the tab view.
    @return the number of tab view items in the receiver
*/
- (unsigned)numberOfTabViewItems
{
    return [[self items] count];
}

/*!
    Returns the CPTabViewItem at the specified index.
    @return a tab view item, or nil
*/
- (CPTabViewItem)tabViewItemAtIndex:(CPUInteger)anIndex
{
    return [[self items] objectAtIndex:anIndex];
}

/*!
    Returns the array of items that backs this tab view.
    @return a copy of the array of items in the receiver
*/
- (CPArray)tabViewItems
{
    return [[self items] copy]; // Copy?
}

// Selecting a Tab
/*!
    Sets the first tab view item in the array to be displayed to the user.
    @param aSender the object making this request
*/
- (void)selectFirstTabViewItem:(id)aSender
{
    if ([self numberOfTabViewItems] === 0)
        return; // throw?

    [self selectTabViewItemAtIndex:0];
}

/*!
    Sets the last tab view item in the array to be displayed to the user.
    @param aSender the object making this request
*/
- (void)selectLastTabViewItem:(id)aSender
{
    if ([self numberOfTabViewItems] === 0)
        return; // throw?

    [self selectTabViewItemAtIndex:[self numberOfTabViewItems] - 1];
}

/*!
    Sets the next tab item in the array to be displayed.
    @param aSender the object making this request
*/
- (void)selectNextTabViewItem:(id)aSender
{
    if (_selectedTabViewItem === nil)
        return;

    var nextIndex = [self indexOfTabViewItem:_selectedTabViewItem] + 1;

    if (nextIndex === [self numberOfTabViewItems])
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
    if (_selectedTabViewItem === nil)
        return;

    var previousIndex = [self indexOfTabViewItem:_selectedTabViewItem] - 1;

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
- (BOOL)selectTabViewItemAtIndex:(CPUInteger)anIndex
{
    if (![self _selectTabViewItemAtIndex:anIndex])
        return NO;

    [self _reverseSetSelectedIndex];

    return YES;
}

// Like selectTabViewItemAtIndex: but without bindings interaction
- (BOOL)_selectTabViewItemAtIndex:(CPUInteger)anIndex
{
    var aTabViewItem = [self tabViewItemAtIndex:anIndex];

    if (aTabViewItem == _selectedTabViewItem)
        return NO;

    if (![self _sendDelegateShouldSelectTabViewItem:aTabViewItem])
        return NO;

    [self _sendDelegateWillSelectTabViewItem:aTabViewItem];

    [_tabs setSelectedSegment:anIndex];
    _selectedTabViewItem = aTabViewItem;
    [self _displayItemView:[aTabViewItem view]];

    [self _sendDelegateDidSelectTabViewItem:aTabViewItem];

    return YES;
}

/*!
    Returns the current item being displayed.
    @return the tab view item currenly being displayed by the receiver
*/
- (CPTabViewItem)selectedTabViewItem
{
    return _selectedTabViewItem;
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

- (void)tileWithChangedItem:(CPTabViewItem)aTabViewItem
{
    var segment = aTabViewItem ? [self indexOfTabViewItem:aTabViewItem] : 0;
    [_tabs tileWithChangedSegment:segment];

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
- (void)setDelegate:(id <CPTabViewDelegate>)aDelegate
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

- (void)_displayItemView:(CPView)aView
{
    [_box setContentView:aView];
}

// DELEGATE METHODS

- (BOOL)_sendDelegateShouldSelectTabViewItem:(CPTabViewItem)aTabViewItem
{
    if (_delegateSelectors & CPTabViewShouldSelectTabViewItemSelector)
        return [_delegate tabView:self shouldSelectTabViewItem:aTabViewItem];

    return YES;
}

- (void)_sendDelegateWillSelectTabViewItem:(CPTabViewItem)aTabViewItem
{
    if (_delegateSelectors & CPTabViewWillSelectTabViewItemSelector)
        [_delegate tabView:self willSelectTabViewItem:aTabViewItem];
}

- (void)_sendDelegateDidSelectTabViewItem:(CPTabViewItem)aTabViewItem
{
    if (_delegateSelectors & CPTabViewDidSelectTabViewItemSelector)
        [_delegate tabView:self didSelectTabViewItem:aTabViewItem];
}

- (void)_sendDelegateTabViewDidChangeNumberOfTabViewItems
{
    if (_delegateSelectors & CPTabViewDidChangeNumberOfTabViewItemsSelector)
        [_delegate tabViewDidChangeNumberOfTabViewItems:self];
}

@end

@implementation CPTabView (BindingSupport)

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding == CPContentBinding)
        return [_CPTabViewContentBinder class];
    else if (aBinding == CPSelectionIndexesBinding || aBinding == CPSelectedIndexBinding)
        return [_CPTabViewSelectionBinder class];

    return [super _binderClassForBinding:aBinding];
}

+ (BOOL)isBindingExclusive:(CPString)aBinding
{
    return (aBinding == CPSelectionIndexesBinding || aBinding == CPSelectedIndexBinding);
}

- (void)_reverseSetContent
{
    var theBinder = [self binderForBinding:CPContentBinding];
    [theBinder reverseSetValueFor:@"items"];
}

- (void)_reverseSetSelectedIndex
{
    var theBinder = [self binderForBinding:CPSelectionIndexesBinding];

    if (theBinder !== nil)
        [theBinder reverseSetValueFor:@"selectionIndexes"];
    else
    {
        theBinder = [self binderForBinding:CPSelectedIndexBinding];
        [theBinder reverseSetValueFor:@"selectedIndex"];
    }
}

- (CPBinder)binderForBinding:(CPString)aBinding
{
    var cls = [[self class] _binderClassForBinding:aBinding]
    return [cls getBinding:aBinding forObject:self];
}

- (void)setItems:(CPArray)tabViewItems
{
    if ([tabViewItems isEqualToArray:[_tabs segments]])
        return;

    [[self items] makeObjectsPerformSelector:@selector(_setTabView:) withObject:nil];
    [_tabs setSegments:tabViewItems];
    [tabViewItems makeObjectsPerformSelector:@selector(_setTabView:) withObject:self];

    [self tileWithChangedItem:nil];

    // Update the selection because setSegments: did remove all previous segments AND the selection.
    [_tabs setSelectedSegment:[self indexOfTabViewItem:_selectedTabViewItem]];

    // should we send delegate methods in bindings mode ?
    //[self _delegateTabViewDidChangeNumberOfTabViewItems:self];
}

- (void)_deselectAll
{
    [_tabs setSelectedSegment:-1];
    _selectedTabViewItem = nil;
}

- (void)_displayPlaceholder:(CPString)aPlaceholder
{
    if (_placeHolderView == nil)
    {
        _placeHolderView = [[CPView alloc] initWithFrame:CGRectMakeZero()];
        var textField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
        [textField setTag:1000];
        [textField setTextColor:[CPColor whiteColor]];
        [textField setFont:[CPFont boldFontWithName:@"Geneva" size:18 italic:YES]];
        [_placeHolderView addSubview:textField];
    }

    var textField = [_placeHolderView viewWithTag:1000];
    [textField setStringValue:aPlaceholder];
    [textField sizeToFit];

    var boxBounds = [_box bounds],
        textFieldBounds = [textField bounds],
        origin = CGPointMake(CGRectGetWidth(boxBounds)/2 - CGRectGetWidth(textFieldBounds)/2, CGRectGetHeight(boxBounds)/2 - CGRectGetHeight(textFieldBounds));

    [textField setFrameOrigin:origin];

    [self _displayItemView:_placeHolderView];
}

#pragma mark -
#pragma mark Override

/*!
    Enabled controls accept first mouse by default.
*/
- (BOOL)acceptsFirstMouse:(CPEvent)anEvent
{
    return YES;
}

@end

var _CPTabViewContentBinderNull = @"NO CONTENT";

@implementation _CPTabViewContentBinder : CPBinder
{
}

- (void)_updatePlaceholdersWithOptions:(CPDictionary)options
{
    [super _updatePlaceholdersWithOptions:options];
    [self _setPlaceholder:_CPTabViewContentBinderNull forMarker:CPNullMarker isDefault:YES];
}

- (void)setPlaceholderValue:(id)aValue withMarker:(CPString)aMarker forBinding:(CPString)aBinding
{
    [_source setItems:@[]];
    [_source _setPlaceholderView:aValue];
}

- (void)setValue:(id)aValue forBinding:(CPString)aBinding
{
    [_source setItems:aValue];
}

- (id)valueForBinding:(CPString)aBinding
{
    return [_source items];
}

@end

var _CPTabViewSelectionBinderMultipleValues = @"Multiple Selection",
    _CPTabViewSelectionBinderNoSelection = @"No Selection";

@implementation _CPTabViewSelectionBinder : CPBinder
{
}

- (void)_updatePlaceholdersWithOptions:(CPDictionary)options
{
    [super _updatePlaceholdersWithOptions:options];

    [self _setPlaceholder:_CPTabViewSelectionBinderMultipleValues forMarker:CPMultipleValuesMarker isDefault:YES];
    [self _setPlaceholder:_CPTabViewSelectionBinderNoSelection forMarker:CPNoSelectionMarker isDefault:YES];
}

- (void)setPlaceholderValue:(id)aValue withMarker:(CPString)aMarker forBinding:(CPString)aBinding
{
    if (aMarker == CPNoSelectionMarker || aMarker == CPNullMarker)
        [_source _deselectAll];

    [_source _displayPlaceholder:aValue];
}

- (void)setValue:(id)aValue forBinding:(CPString)aBinding
{
    if (aBinding == CPSelectionIndexesBinding)
    {
        if (aValue == nil || [aValue count] == 0)
        {
            [_source _deselectAll];
            [_source _displayPlaceholder:_CPTabViewSelectionBinderNoSelection];
        }
        else if ([aValue count] > 1)
            [_source _displayPlaceholder:_CPTabViewSelectionBinderMultipleValues];
        else if ([aValue firstIndex] < [_source numberOfTabViewItems])
            [_source _selectTabViewItemAtIndex:[aValue firstIndex]];
    }
    else if (aBinding == CPSelectedIndexBinding)
    {
        if (aValue == CPNotFound)
        {
            [_source _deselectAll];
            [_source _displayPlaceholder:_CPTabViewSelectionBinderNoSelection];
        }
        else if (aValue < [_source numberOfTabViewItems])
            [_source _selectTabViewItemAtIndex:aValue];
    }
}

- (id)valueForBinding:(CPString)aBinding
{
    if (aBinding == CPSelectionIndexesBinding)
    {
        var result = [CPIndexSet indexSet],
            idx = [_source indexOfTabViewItem:[_source selectedTabViewItem]];

        if (idx !== CPNotFound)
            [result addIndex:idx];

        return result;
    }
    else if (aBinding == CPSelectedIndexBinding)
        return [_source indexOfTabViewItem:[_source selectedTabViewItem]];
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

        var items = [aCoder decodeObjectForKey:CPTabViewItemsKey] || [CPArray array];
        [self _insertTabViewItems:items atIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [items count])]];

        [self setDelegate:[aCoder decodeObjectForKey:CPTabViewDelegateKey]];

        _selectedTabViewItem = [aCoder decodeObjectForKey:CPTabViewSelectedItemKey];

        _type = [aCoder decodeIntForKey:CPTabViewTypeKey];
    }

    return self;
}

- (void)awakeFromCib
{
    [super awakeFromCib];

    // This cannot be run in initWithCoder because it might call selectTabViewItem:, which is
    // not safe to call before the views of the tab views items are fully decoded.

    if (_selectedTabViewItem)
    {
        var idx = [self indexOfTabViewItem:_selectedTabViewItem];

        if (idx !== CPNotFound)
            [self selectTabViewItemAtIndex:idx];
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

    [aCoder encodeConditionalObject:_selectedTabViewItem forKey:CPTabViewSelectedItemKey];

    [aCoder encodeInt:_type forKey:CPTabViewTypeKey];
    [aCoder encodeObject:_font forKey:CPTabViewFontKey];

    [aCoder encodeConditionalObject:_delegate forKey:CPTabViewDelegateKey];
}

@end

@implementation _CPTabViewBox : CPBox
{
    CPTabView _tabView @accessors(property=tabView);
}


#pragma mark -
#pragma mark Override

- (CPView)hitTest:(CGPoint)aPoint
{
    // Here we check if we have clicked on the segmentedControl of the tabView or not
    // If YES, the CPBox should not handle the click
    var segmentIndex = [_tabView._tabs testSegment:[_tabView._tabs convertPoint:aPoint fromView:[self superview]]];

    if (segmentIndex != CPNotFound)
        return nil;

    return [super hitTest:aPoint];
}

@end