/*
 * CPAccordionView.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
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
@import <Foundation/CPObject.j>
@import <Foundation/CPKeyValueObserving.j>
@import <Foundation/CPIndexSet.j>
@import <Foundation/CPString.j>

@import "CPView.j"
@import "CPButton.j"


/*!
  @ingroup appkit
  @class CPAccordionViewItem

  <p>A CPAccordionViewItem represents a single section of a CPAccordionView.</p>
*/
@implementation CPAccordionViewItem : CPObject
{
    CPString    _identifier @accessors(property=identifier);
    CPView      _view @accessors(property=view);
    CPString    _label @accessors(property=label);
}

- (id)init
{
    return [self initWithIdentifier:@""];
}

/*!
  Initializes a new CPAccordionViewItem with the specified identifier. This identifier may
  then be used in subsequent methods to provide abstract introspection of the CPAccordionView.
*/
- (id)initWithIdentifier:(CPString)anIdentifier
{
    self = [super init];

    if (self)
        [self setIdentifier:anIdentifier];

    return self;
}

@end

/*!
  @ingroup appkit
  @class CPAccordionView

  <p>CPAccordionView provides a container for CPAccordionViewItem objects and manages layout state
  for all sub-layout items.</p>

  <strong>Example</strong><br />
  <pre>
var myAccordionView = [[CPAccordionView alloc] initWithFrame:CGRectMakeZero()];
var firstItem = [[CPAccordionViewItem alloc] initWithIdentifier:@"firstSection"]];
[firstItem setView:[[CPView alloc] initWithFrame:CGRectMakeZero()]];
var secondItem = [[CPAccordionViewItem alloc] initWithIdentifier:@"secondSection"]];
[secondItem setView:[[CPView alloc] initWithFrame:CGRectMakeZero()]];
[myAccordionView addItem:firstItem];
[myAccordionView addItem:secondItem];
[myAccordionView setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
  </pre>
*/
@implementation CPAccordionView : CPView
{
    CPInteger       _dirtyItemIndex;
    CPView          _itemHeaderPrototype;

    CPMutableArray  _items;
    CPMutableArray  _itemViews;
    CPIndexSet      _expandedItemIndexes;
}
/*!
    Initializes the receiver for usage with the specified bounding rectangle
    @return the initialized view
*/
- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _items = [];
        _itemViews = [];
        _expandedItemIndexes = [CPIndexSet indexSet];

        [self setItemHeaderPrototype:[[CPButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 24.0)]];
    }

    return self;
}

- (void)setItemHeaderPrototype:(CPView)aView
{
    _itemHeaderPrototype = aView;
}

- (CPView)itemHeaderPrototype
{
    return _itemHeaderPrototype;
}

- (CPArray)items
{
    return _items;
}
/*!
  Append a CPAccordionViewItem to the receiver. Note that the CPAccordionViewItem must contain
  a valid CPView derived component or a TypeError will be generated when the contents of the
  ViewItem are disclosed.
*/
- (void)addItem:(CPAccordionViewItem)anItem
{
    [self insertItem:anItem atIndex:_items.length];
}

- (void)insertItem:(CPAccordionViewItem)anItem atIndex:(CPInteger)anIndex
{
    // FIXME: SHIFT ITEMS RIGHT
    [_expandedItemIndexes addIndex:anIndex];

    var itemView = [[_CPAccordionItemView alloc] initWithAccordionView:self];

    [itemView setIndex:anIndex];
    [itemView setLabel:[anItem label]];
    [itemView setContentView:[anItem view]];

    [self addSubview:itemView];

    [_items insertObject:anItem atIndex:anIndex];
    [_itemViews insertObject:itemView atIndex:anIndex];

    [self _invalidateItemsStartingAtIndex:anIndex];

    [self setNeedsLayout];
}

- (void)removeItem:(CPAccordionViewItem)anItem
{
    [self removeItemAtIndex:[_items indexOfObjectIdenticalTo:anItem]];
}

- (void)removeItemAtIndex:(CPInteger)anIndex
{
    // SHIFT ITEMS LEFT
    [_expandedItemIndexes removeIndex:anIndex];

    [_itemViews[anIndex] removeFromSuperview];

    [_items removeObjectAtIndex:anIndex];
    [_itemViews removeObjectAtIndex:anIndex];

    [self _invalidateItemsStartingAtIndex:anIndex];

    [self setNeedsLayout];
}

- (void)removeAllItems
{
    var count = _items.length;

    while (count--)
        [self removeItemAtIndex:count];
}

- (void)expandItemAtIndex:(CPInteger)anIndex
{
    if (![_itemViews[anIndex] isCollapsed])
        return;

    [_expandedItemIndexes addIndex:anIndex];
    [_itemViews[anIndex] setCollapsed:NO];

    [self _invalidateItemsStartingAtIndex:anIndex];
}

- (void)collapseItemAtIndex:(CPInteger)anIndex
{
    if ([_itemViews[anIndex] isCollapsed])
        return;

    [_expandedItemIndexes removeIndex:anIndex];
    [_itemViews[anIndex] setCollapsed:YES];

    [self _invalidateItemsStartingAtIndex:anIndex];
}

- (void)toggleItemAtIndex:(CPInteger)anIndex
{
    var itemView = _itemViews[anIndex];

    if ([itemView isCollapsed])
        [self expandItemAtIndex:anIndex];

    else
        [self collapseItemAtIndex:anIndex];
}

- (CPIndexSet)expandedItemIndexes
{
    return _expandedItemIndexes;
}

- (CPIndexSet)collapsedItemIndexes
{
    var indexSet = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, _items.length)];

    [indexSet removeIndexes:_expandedItemIndexes];

    return indexSet;
}

- (void)setEnabled:(BOOL)isEnabled forItemAtIndex:(CPInteger)anIndex
{
    var itemView = _itemViews[anIndex];
    if (!itemView)
        return;

    if (!isEnabled)
        [self collapseItemAtIndex:anIndex];
    else
        [self expandItemAtIndex:anIndex];

    [itemView setEnabled:isEnabled];
}

- (void)_invalidateItemsStartingAtIndex:(CPInteger)anIndex
{
    if (_dirtyItemIndex === CPNotFound)
        _dirtyItemIndex = anIndex;

    _dirtyItemIndex = MIN(_dirtyItemIndex, anIndex);

    [self setNeedsLayout];
}

- (void)setFrameSize:(CGSize)aSize
{
    var width = CGRectGetWidth([self frame]);

    [super setFrameSize:aSize];

    if (width !== CGRectGetWidth([self frame]))
        [self _invalidateItemsStartingAtIndex:0];
}

- (void)layoutSubviews
{
    if (_items.length <= 0)
        return [self setFrameSize:CGSizeMake(CGRectGetWidth([self frame]), 0.0)];

    if (_dirtyItemIndex === CPNotFound)
        return;

    _dirtyItemIndex = MIN(_dirtyItemIndex, _items.length - 1);

    var index = _dirtyItemIndex,
        count = _itemViews.length,
        width = CGRectGetWidth([self bounds]),
        y = index > 0 ? CGRectGetMaxY([_itemViews[index - 1] frame]) : 0.0;

    // Do this now (instead of after looping), so that if we are made dirty again in the middle we don't blow this value away.
    _dirtyItemIndex = CPNotFound;

    for (; index < count; ++index)
    {
        var itemView = _itemViews[index];

        [itemView setFrameY:y width:width];

        y = CGRectGetMaxY([itemView frame]);
    }

    [self setFrameSize:CGSizeMake(CGRectGetWidth([self frame]), y)];
}

@end

@implementation _CPAccordionItemView : CPView
{
    CPAccordionView _accordionView;

    BOOL            _isCollapsed @accessors(getter=isCollapsed, setter=setCollapsed:);
    CPInteger       _index @accessors(property=index);
    CPView          _headerView;
    CPView          _contentView;
}

- (id)initWithAccordionView:(CPAccordionView)anAccordionView
{
    self = [super initWithFrame:CGRectMakeZero()];

    if (self)
    {
        _accordionView = anAccordionView;
        _isCollapsed = NO;

        var bounds = [self bounds];

        _headerView = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:[_accordionView itemHeaderPrototype]]];

        if ([_headerView respondsToSelector:@selector(setTarget:)] && [_headerView respondsToSelector:@selector(setAction:)])
        {
            [_headerView setTarget:self];
            [_headerView setAction:@selector(toggle:)];
        }

        [self addSubview:_headerView];
    }

    return self;
}

- (void)toggle:(id)aSender
{
    [_accordionView toggleItemAtIndex:[self index]];
}

- (void)setLabel:(CPString)aLabel
{
    if ([_headerView respondsToSelector:@selector(setTitle:)])
        [_headerView setTitle:aLabel];

    else if ([_headerView respondsToSelector:@selector(setLabel:)])
        [_headerView setLabel:aLabel];

    else if ([_headerView respondsToSelector:@selector(setStringValue:)])
        [_headerView setStringValue:aLabel];
}

- (void)setEnabled:(BOOL)isEnabled
{
    if ([_headerView respondsToSelector:@selector(setEnabled:)])
        [_headerView setEnabled:isEnabled];
}

- (void)setContentView:(CPView)aView
{
    if (_contentView === aView)
        return;

    [_contentView removeObserver:self forKeyPath:@"frame"];

    [_contentView removeFromSuperview];

    _contentView = aView;

    [_contentView addObserver:self forKeyPath:@"frame" options:CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew context:NULL];

    [self addSubview:_contentView];

    [_accordionView _invalidateItemsStartingAtIndex:[self index]];
}

- (void)setFrameY:(float)aY width:(float)aWidth
{
    var headerHeight = CGRectGetHeight([_headerView frame]);

    // Size to fit or something?
    [_headerView setFrameSize:CGSizeMake(aWidth, headerHeight)];
    [_contentView setFrameOrigin:CGPointMake(0.0, headerHeight)];

    if ([self isCollapsed])
        [self setFrame:CGRectMake(0.0, aY, aWidth, headerHeight)];

    else
    {
        var contentHeight = CGRectGetHeight([_contentView frame]);

        [_contentView setFrameSize:CGSizeMake(aWidth, contentHeight)];
        [self setFrame:CGRectMake(0.0, aY, aWidth, contentHeight + headerHeight)];
    }
}

- (void)resizeSubviewsWithOldSize:(CGSize)aSize
{
}

- (void)observeValueForKeyPath:(CPString)aKeyPath
                      ofObject:(id)anObject
                        change:(CPDictionary)aChange
                       context:(id)aContext
{
    if (aKeyPath === "frame" && !CGRectEqualToRect([aChange objectForKey:CPKeyValueChangeOldKey], [aChange objectForKey:CPKeyValueChangeNewKey]))
        [_accordionView _invalidateItemsStartingAtIndex:[self index]];
/*
    else if (aKeyPath === "itemHeaderPrototype")
    {

    }
*/
}

@end
