/*
 * CPTabView.j
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

import "CPImageView.j"
import "CPTabViewItem.j"
import "CPView.j"

#include "CoreGraphics/CGGeometry.h"


CPTopTabsBezelBorder     = 0;
//CPLeftTabsBezelBorder    = 1;
//CPBottomTabsBezelBorder  = 2;
//CPRightTabsBezelBorder   = 3;
CPNoTabsBezelBorder      = 4;
CPNoTabsLineBorder       = 5;
CPNoTabsNoBorder         = 6;

var CPTabViewBezelBorderLeftImage       = nil,
    CPTabViewBackgroundCenterImage      = nil,
    CPTabViewBezelBorderRightImage      = nil,
    CPTabViewBezelBorderColor           = nil,
    CPTabViewBezelBorderBackgroundColor = nil;

var LEFT_INSET  = 7.0,
    RIGHT_INSET = 7.0;
    
var CPTabViewDidSelectTabViewItemSelector           = 1,
    CPTabViewShouldSelectTabViewItemSelector        = 2,
    CPTabViewWillSelectTabViewItemSelector          = 4,
    CPTabViewDidChangeNumberOfTabViewItemsSelector  = 8;

@implementation CPTabView : CPView
{   
    CPView          _labelsView;
    CPView          _backgroundView;
    CPView          _separatorView;
    
    CPView          _auxiliaryView;
    CPView          _contentView;
    
    CPArray         _tabViewItems;
    CPTabViewItem   _selectedTabViewItem;

    CPTabViewType   _tabViewType;
    
    id              _delegate;
    unsigned        _delegateSelectors;
}

+ (void)initialize
{
    if (self != CPTabView)
        return;
    
    var bundle = [CPBundle bundleForClass:self],
        
        emptyImage = [[CPImage alloc] initByReferencingFile:@"" size:CGSizeMake(7.0, 0.0)],
        backgroundImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTabView/CPTabViewBezelBackgroundCenter.png"] size:CGSizeMake(1.0, 1.0)],
        
        bezelBorderLeftImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTabView/CPTabViewBezelBorderLeft.png"] size:CGSizeMake(7.0, 1.0)],
        bezerBorderImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTabView/CPTabViewBezelBorder.png"] size:CGSizeMake(1.0, 1.0)],
        bezelBorderRightImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTabView/CPTabViewBezelBorderRight.png"] size:CGSizeMake(7.0, 1.0)];
    
    CPTabViewBezelBorderBackgroundColor = [CPColor colorWithPatternImage:[[CPNinePartImage alloc] initWithImageSlices:
        [
            emptyImage, 
            emptyImage, 
            emptyImage,

            bezelBorderLeftImage,
            backgroundImage,
            bezelBorderRightImage,

            bezelBorderLeftImage,
            bezerBorderImage,
            bezelBorderRightImage
        ]]];
    
    CPTabViewBezelBorderColor = [CPColor colorWithPatternImage:bezerBorderImage];
}

+ (CPColor)bezelBorderColor
{
    return CPTabViewBezelBorderColor;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _tabViewType = CPTopTabsBezelBorder;
        _tabViewItems = [];
    }
    
    return self;
}

- (void)viewDidMoveToWindow
{
    if (_tabViewType != CPTopTabsBezelBorder || _labelsView)
        return;
        
    [self _createBezelBorder];
    [self layoutSubviews];
}

- (void)_createBezelBorder
{
    var bounds = [self bounds];
    
    _labelsView = [[_CPTabLabelsView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds), 0.0)];

    [_labelsView setTabView:self];
    [_labelsView setAutoresizingMask:CPViewWidthSizable];

    [self addSubview:_labelsView];

    _backgroundView = [[CPView alloc] initWithFrame:CGRectMakeZero()];        
    
    [_backgroundView setBackgroundColor:CPTabViewBezelBorderBackgroundColor];

    [_backgroundView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    
    [self addSubview:_backgroundView];
    
    _separatorView = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [_separatorView setBackgroundColor:[[self class] bezelBorderColor]];
    [_separatorView setAutoresizingMask:CPViewWidthSizable | CPViewMaxYMargin];
    
    [self addSubview:_separatorView];
}

- (void)layoutSubviews
{
    if (_tabViewType == CPTopTabsBezelBorder)
    {
        var backgroundRect = [self bounds],
            labelsViewHeight = [_CPTabLabelsView height];
        
        backgroundRect.origin.y += labelsViewHeight;
        backgroundRect.size.height -= labelsViewHeight;
        
        [_backgroundView setFrame:backgroundRect];
        
        var auxiliaryViewHeight = 5.0;
        
        if (_auxiliaryView)
        {
            auxiliaryViewHeight = CGRectGetHeight([_auxiliaryView frame]);
            
            [_auxiliaryView setFrame:CGRectMake(LEFT_INSET, labelsViewHeight, CGRectGetWidth(backgroundRect) - LEFT_INSET - RIGHT_INSET, auxiliaryViewHeight)];
        }
        
        [_separatorView setFrame:CGRectMake(LEFT_INSET, labelsViewHeight + auxiliaryViewHeight, CGRectGetWidth(backgroundRect) - LEFT_INSET - RIGHT_INSET, 1.0)];
    }

    // CPNoTabsNoBorder
    [_contentView setFrame:[self contentRect]];
}

// Adding and Removing Tabs

- (void)addTabViewItem:(CPTabViewItem)aTabViewItem
{
    [self insertTabViewItem:aTabViewItem atIndex:[_tabViewItems count]];
}

- (void)insertTabViewItem:(CPTabViewItem)aTabViewItem atIndex:(unsigned)anIndex
{
    [_tabViewItems insertObject:aTabViewItem atIndex:anIndex];
    
    [_labelsView tabView:self didAddTabViewItem:aTabViewItem];
    
    if ([_tabViewItems count] == 1)
        [self selectFirstTabViewItem:self];

    if (_delegateSelectors & CPTabViewDidChangeNumberOfTabViewItemsSelector)
        [_delegate tabViewDidChangeNumberOfTabViewItems:self];
}

- (void)removeTabViewItem:(CPTabViewItem)aTabViewItem
{
    [_tabViewItems removeObjectIdenticalTo:aTabViewItem];

    [_labelsView tabView:self didRemoveTabViewItem:aTabViewItem];
    
    if (_delegateSelectors & CPTabViewDidChangeNumberOfTabViewItemsSelector)
        [_delegate tabViewDidChangeNumberOfTabViewItems:self];
}

// Accessing Tabs

- (int)indexOfTabViewItem:(CPTabViewItem)aTabViewItem
{
    return [_tabViewItems indexOfObjectIdenticalTo:aTabViewItem];
}

- (int)indexOfTabViewItemWithIdentifier:(CPString)anIdentifier
{
    var index = 0,
        count = [_tabViewItems count];
        
    for (; index < count; ++index)
        if ([[_tabViewItems[index] identifier] isEqualTo:anIdentifier])
            return index;

    return index;
}

- (unsigned)numberOfTabViewItems
{
    return [_tabViewItems count];
}

- (CPTabViewItem)tabViewItemAtIndex:(unsigned)anIndex
{
    return _tabViewItems[anIndex];
}

- (CPArray)tabViewItems
{
    return _tabViewItems;
}

// Selecting a Tab

- (void)selectFirstTabViewItem:(id)aSender
{
    var count = [_tabViewItems count];
    
    if (count)
        [self selectTabViewItemAtIndex:0];
}

- (void)selectLastTabViewItem:(id)aSender
{
    var count = [_tabViewItems count];
    
    if (count)
        [self selectTabViewItemAtIndex:count - 1];
}

- (void)selectNextTabViewItem:(id)aSender
{
    if (!_selectedTabViewItem)
        return;
    
    var index = [self indexOfTabViewItem:_selectedTabViewItem],
        count = [_tabViewItems count];
    
    [self selectTabViewItemAtIndex:index + 1 % count];
}

- (void)selectPreviousTabViewItem:(id)aSender
{
    if (!_selectedTabViewItem)
        return;
    
    var index = [self indexOfTabViewItem:_selectedTabViewItem],
        count = [_tabViewItems count];
    
    [self selectTabViewItemAtIndex:index == 0 ? count : index - 1];
}

- (void)selectTabViewItem:(CPTabViewItem)aTabViewItem
{
    if ((_delegateSelectors & CPTabViewShouldSelectTabViewItemSelector) && ![_delegate tabView:self shouldSelectTabViewItem:aTabViewItem])
        return;
        
    if (_delegateSelectors & CPTabViewWillSelectTabViewItemSelector)
        [_delegate tabView:self willSelectTabViewItem:aTabViewItem];

    if (_selectedTabViewItem)
    {
        _selectedTabViewItem._tabState = CPBackgroundTab;
        [_labelsView tabView:self didChangeStateOfTabViewItem:_selectedTabViewItem];
        
        [_contentView removeFromSuperview];
        [_auxiliaryView removeFromSuperview];
    }
    _selectedTabViewItem = aTabViewItem;
    
    _selectedTabViewItem._tabState = CPSelectedTab;
        
    _contentView = [_selectedTabViewItem view];
    [_contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    
    _auxiliaryView = [_selectedTabViewItem auxiliaryView];
    [_auxiliaryView setAutoresizingMask:CPViewWidthSizable];
    
    [self addSubview:_contentView];

    if (_auxiliaryView)
        [self addSubview:_auxiliaryView];
    
    [_labelsView tabView:self didChangeStateOfTabViewItem:_selectedTabViewItem];
    
    [self layoutSubviews];
    
    if (_delegateSelectors & CPTabViewDidSelectTabViewItemSelector)
        [_delegate tabView:self didSelectTabViewItem:aTabViewItem];
}

- (void)selectTabViewItemAtIndex:(unsigned)anIndex
{
    [self selectTabViewItem:_tabViewItems[anIndex]];
}

- (void)selectedTabViewItem
{
    return _selectedTabViewItem;
}

// 

- (void)setTabViewType:(CPTabViewType)aTabViewType
{
    if (_tabViewType == aTabViewType)
        return;
    
    _tabViewType = aTabViewType;
    
    if (_tabViewType == CPNoTabsBezelBorder || _tabViewType == CPNoTabsLineBorder || _tabViewType == CPNoTabsNoBorder)
        [_labelsView removeFromSuperview];
    else if (![_labelsView superview])
        [self addSubview:_lablesView];
        
    if (_tabViewType == CPNoTabsLineBorder || _tabViewType == CPNoTabsNoBorder)
        [_backgroundView removeFromSuperview];
    else if (![_backgroundView superview])
        [self addSubview:_backgroundView];
    
    [self layoutSubviews];
}

- (CPTabViewType)tabViewType
{
    return _tabViewType;
}

// Determining the Size

- (CGRect)contentRect
{
    var contentRect = CGRectMakeCopy([self bounds]);
    
    if (_tabViewType == CPTopTabsBezelBorder)
    {
        var labelsViewHeight = [_CPTabLabelsView height],
            auxiliaryViewHeight = _auxiliaryView ? CGRectGetHeight([_auxiliaryView frame]) : 5.0,
            separatorViewHeight = 1.0;

        contentRect.origin.y += labelsViewHeight + auxiliaryViewHeight + separatorViewHeight;
        contentRect.size.height -= labelsViewHeight + auxiliaryViewHeight + separatorViewHeight * 2.0; // 2 for the bottom border as well.
        
        contentRect.origin.x += LEFT_INSET;
        contentRect.size.width -= LEFT_INSET + RIGHT_INSET;
    }

    return contentRect;
}

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

//

- (void)mouseDown:(CPEvent)anEvent
{
    var location = [_labelsView convertPoint:[anEvent locationInWindow] fromView:nil],
        tabViewItem = [_labelsView representedTabViewItemAtPoint:location];
        
    if (tabViewItem)
        [self selectTabViewItem:tabViewItem];
}

@end

var _CPTabLabelsViewBackgroundColor = nil,
    _CPTabLabelsViewInsideMargin    = 10.0,
    _CPTabLabelsViewOutsideMargin   = 15.0;

@implementation _CPTabLabelsView : CPView
{
    CPTabView       _tabView;
    CPDictionary    _tabLabels;
}

+ (void)initialize
{
    if (self != [_CPTabLabelsView class])
        return;

    var bundle = [CPBundle bundleForClass:self];
    
    _CPTabLabelsViewBackgroundColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTabView/_CPTabLabelsViewLeft.png"] size:CGSizeMake(12.0, 26.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTabView/_CPTabLabelsViewCenter.png"] size:CGSizeMake(1.0, 26.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTabView/_CPTabLabelsViewRight.png"] size:CGSizeMake(12.0, 26.0)]
        ] isVertical:NO]];
}

+ (float)height
{
    return 26.0;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _tabLabels = [];
        
        [self setBackgroundColor:_CPTabLabelsViewBackgroundColor];

        [self setFrameSize:CGSizeMake(CGRectGetWidth(aFrame), 26.0)];
    }
    
    return self;
}

- (void)setTabView:(CPTabView)aTabView
{
    _tabView = aTabView;
}

- (CPTabView)tabView
{
    return _tabView;
}

- (void)tabView:(CPTabView)aTabView didAddTabViewItem:(CPTabViewItem)aTabViewItem
{
    var label = [[_CPTabLabel alloc] initWithFrame:CGRectMakeZero()];
    
    [label setTabViewItem:aTabViewItem];
    
    _tabLabels.push(label);
    
    [self addSubview:label];
        
    [self layoutSubviews];
}

- (void)tabView:(CPTabView)aTabView didRemoveTabViewItem:(CPTabViewItem)aTabViewItem
{
    var index = [aTabView indexOfTabViewItem:aTabViewItem],
        label = _tabLabels[index];
    
    [_tabLabels removeObjectAtIndex:index];

    [label removeFromSuperview];
    
    [self layoutSubviews];
}

 -(void)tabView:(CPTabView)aTabView didChangeStateOfTabViewItem:(CPTabViewItem)aTabViewItem
 {
    [_tabLabels[[aTabView indexOfTabViewItem:aTabViewItem]] setTabState:[aTabViewItem tabState]];
 }

- (CPTabViewItem)representedTabViewItemAtPoint:(CGPoint)aPoint
{
    var index = 0,
        count = _tabLabels.length;
        
    for (; index < count; ++index)
    {
        var label = _tabLabels[index];
    
        if (CGRectContainsPoint([label frame], aPoint))
            return [label tabViewItem];
    }

    return nil;
}

- (void)layoutSubviews
{
    var index = 0,
        count = _tabLabels.length,
        width = (_CGRectGetWidth([self bounds]) - (count - 1) * _CPTabLabelsViewInsideMargin - 2 * _CPTabLabelsViewOutsideMargin) / count,
        x = _CPTabLabelsViewOutsideMargin;
    
    for (; index < count; ++index)
    {
        var label = _tabLabels[index],
            frame = _CGRectMake(x, 8.0, width, 18.0);
        
        [label setFrame:frame];
        
        x = _CGRectGetMaxX(frame) + _CPTabLabelsViewInsideMargin;
    }
}

- (void)setFrameSize:(CGSize)aSize
{
    if (CGSizeEqualToSize([self frame].size, aSize))
        return;
    
    [super setFrameSize:aSize];
    
    [self layoutSubviews];
}

@end

var _CPTabLabelBackgroundColor          = nil,
    _CPTabLabelSelectedBackgroundColor  = nil;

@implementation _CPTabLabel : CPView
{
    CPTabViewItem   _tabViewItem;
    CPTextField     _labelField;
}

+ (void)initialize
{
    if (self != [_CPTabLabel class])
        return;

    var bundle = [CPBundle bundleForClass:self];
    
    _CPTabLabelBackgroundColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTabView/_CPTabLabelBackgroundLeft.png"] size:CGSizeMake(6.0, 18.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTabView/_CPTabLabelBackgroundCenter.png"] size:CGSizeMake(1.0, 18.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTabView/_CPTabLabelBackgroundRight.png"] size:CGSizeMake(6.0, 18.0)]
        ] isVertical:NO]];
    
    _CPTabLabelSelectedBackgroundColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
        [
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTabView/_CPTabLabelSelectedLeft.png"] size:CGSizeMake(3.0, 18.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTabView/_CPTabLabelSelectedCenter.png"] size:CGSizeMake(1.0, 18.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTabView/_CPTabLabelSelectedRight.png"] size:CGSizeMake(3.0, 18.0)]
        ] isVertical:NO]];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {   
        _labelField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
        
        [_labelField setAlignment:CPCenterTextAlignment];
        [_labelField setFrame:CGRectMake(5.0, 0.0, CGRectGetWidth(aFrame) - 10.0, 20.0)];
        [_labelField setAutoresizingMask:CPViewWidthSizable];
        [_labelField setFont:[CPFont boldSystemFontOfSize:11.0]];
        
        [self addSubview:_labelField];
        
        [self setTabState:CPBackgroundTab];
    }
    
    return self;
}

- (void)setTabState:(CPTabState)aTabState
{
    [self setBackgroundColor:aTabState == CPSelectedTab ? _CPTabLabelSelectedBackgroundColor : _CPTabLabelBackgroundColor];
}

- (void)setTabViewItem:(CPTabViewItem)aTabViewItem
{
    _tabViewItem = aTabViewItem;
    
    [self update];
}

- (CPTabViewItem)tabViewItem
{
    return _tabViewItem;
}

- (void)update
{
    [_labelField setStringValue:[_tabViewItem label]];
}

@end
