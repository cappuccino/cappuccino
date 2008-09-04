/*
 * CPScrollView.j
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

import "CPView.j"
import "CPClipView.j"
import "CPScroller.j"

#include "CoreGraphics/CGGeometry.h"


@implementation CPScrollView : CPView
{
    CPClipView  _contentView;
    
    BOOL        _hasVerticalScroller;
    BOOL        _hasHorizontalScroller;
    BOOL        _autohidesScrollers;
    
    CPScroller  _verticalScroller;
    CPScroller  _horizontalScroller;
    
    int         _recursionCount;
    
    float       _verticalLineScroll;
    float       _verticalPageScroll;
    float       _horizontalLineScroll;
    float       _horizontalPageScroll;
}

- (id)initWithFrame:(CPRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _verticalLineScroll = 10.0;
        _verticalPageScroll = 10.0;
        
        _horizontalLineScroll = 10.0;
        _horizontalPageScroll = 10.0;

        _contentView = [[CPClipView alloc] initWithFrame:[self bounds]];
        
        [self addSubview:_contentView];
        
        [self setHasVerticalScroller:YES];
        [self setHasHorizontalScroller:YES];
    }
    
    return self;
}

// Determining component sizes
- (CPRect)contentSize
{
    return [_contentView frame].size;
}

- (id)documentView
{
    return [_contentView documentView];
}

- (void)setContentView:(CPClipView)aContentView
{
    if (!aContentView)
        return;
    
    var documentView = [aContentView documentView];
    
    if (documentView)
        [documentView removeFromSuperview];
    
    [_contentView removeFromSuperview];
    
    var size = [self contentSize];
    
    _contentView = aContentView;
        
    [_contentView setFrame:CGRectMake(0.0, 0.0, size.width, size.height)];
    [_contentView setDocumentView:documentView];

    [self addSubview:_contentView];
}

- (CPClipView)contentView
{
    return _contentView;
}

- (void)setDocumentView:(CPView)aView
{
   [_contentView setDocumentView:aView];
   [self reflectScrolledClipView:_contentView];
}

- (void)reflectScrolledClipView:(CPClipView)aClipView
{
    if(_contentView != aClipView)
        return;

    if (_recursionCount > 5)
        return;
    
    ++_recursionCount;

    var documentView = [self documentView];
    
    if (!documentView)
    {
        if (_autohidesScrollers)
        {
            [_verticalScroller setHidden:YES];
            [_horizontalScroller setHidden:YES];
        }
        else
        {
            [_verticalScroller setEnabled:NO];
            [_horizontalScroller setEnabled:NO];
        }
        
        [_contentView setFrame:[self bounds]];
        
        --_recursionCount;
        
        return;
    }

    var documentFrame = [documentView frame],
        contentViewFrame = [self bounds],
        scrollPoint = [_contentView bounds].origin,
        difference = _CGSizeMake(CPRectGetWidth(documentFrame) - CPRectGetWidth(contentViewFrame), CPRectGetHeight(documentFrame) - CPRectGetHeight(contentViewFrame)),
        shouldShowVerticalScroller = (!_autohidesScrollers || difference.height > 0.0) && _hasVerticalScroller,
        shouldShowHorizontalScroller = (!_autohidesScrollers || difference.width > 0.0) && _hasHorizontalScroller,
        wasShowingVerticalScroller = ![_verticalScroller isHidden],
        wasShowingHorizontalScroller = ![_horizontalScroller isHidden],
        verticalScrollerWidth = [CPScroller scrollerWidthForControlSize:[_verticalScroller controlSize]],
        horizontalScrollerHeight = [CPScroller scrollerWidthForControlSize:[_horizontalScroller controlSize]];

    if (_autohidesScrollers)
    {
        if (shouldShowVerticalScroller)
            shouldShowHorizontalScroller = (!_autohidesScrollers || difference.width > -verticalScrollerWidth) && _hasHorizontalScroller;
        if (shouldShowHorizontalScroller)
            shouldShowVerticalScroller = (!_autohidesScrollers || difference.height > -horizontalScrollerHeight) && _hasVerticalScroller;
    }
    
    [_verticalScroller setHidden:!shouldShowVerticalScroller];
    [_verticalScroller setEnabled:!_autohidesScrollers && difference.height < 0];

    [_horizontalScroller setHidden:!shouldShowHorizontalScroller];
    [_horizontalScroller setEnabled:!_autohidesScrollers && difference.width < 0];

    if (shouldShowVerticalScroller)
    {
        var verticalScrollerHeight = CPRectGetHeight(contentViewFrame);
        
        if (shouldShowHorizontalScroller)
            verticalScrollerHeight -= horizontalScrollerHeight;
    
        difference.width += verticalScrollerWidth;
        contentViewFrame.size.width -= verticalScrollerWidth;
    
        [_verticalScroller setFloatValue:(difference.height <= 0.0) ? 0.0 : scrollPoint.y / difference.height
            knobProportion:CPRectGetHeight(contentViewFrame) / CPRectGetHeight(documentFrame)];
        [_verticalScroller setFrame:CPRectMake(CPRectGetMaxX(contentViewFrame), 0.0, verticalScrollerWidth, verticalScrollerHeight)];
    }
    else if (wasShowingVerticalScroller)
        [_verticalScroller setFloatValue:0.0 knobProportion:1.0];
    
    if (shouldShowHorizontalScroller)
    {
        difference.height += horizontalScrollerHeight;
        contentViewFrame.size.height -= horizontalScrollerHeight;
        
        [_horizontalScroller setFloatValue:(difference.width <= 0.0) ? 0.0 : scrollPoint.x / difference.width
            knobProportion:CPRectGetWidth(contentViewFrame) / CPRectGetWidth(documentFrame)];
        [_horizontalScroller setFrame:CPRectMake(0.0, CPRectGetMaxY(contentViewFrame), CPRectGetWidth(contentViewFrame), horizontalScrollerHeight)];
    }
    else if (wasShowingHorizontalScroller)
        [_horizontalScroller setFloatValue:0.0 knobProportion:1.0];
    
    [_contentView setFrame:contentViewFrame];
    
    // The reason we have to do this is because this is called on a frame size change, so when the frame changes, 
    // so does the the float value, so we have to update the clip view accordingly.
    if (_hasVerticalScroller && (shouldShowVerticalScroller || wasShowingVerticalScroller))
    {
        //[self _verticalScrollerDidScroll:_verticalScroller];
        var value = [_verticalScroller floatValue],
            contentBounds = [_contentView bounds];
        
        contentBounds.origin.y = value * (_CGRectGetHeight([[_contentView documentView] frame]) - _CGRectGetHeight(contentBounds));
        
        [_contentView scrollToPoint:contentBounds.origin];
    }
    if (_hasHorizontalScroller && (shouldShowHorizontalScroller || wasShowingHorizontalScroller))
    {
        //[self _horizontalScrollerDidScroll:_horizontalScroller];
    
        var value = [_horizontalScroller floatValue],
            contentBounds = [_contentView bounds];
        
        contentBounds.origin.x = value * (_CGRectGetWidth([[_contentView documentView] frame]) - _CGRectGetWidth(contentBounds));
        
        [_contentView scrollToPoint:contentBounds.origin];
    }
    
    --_recursionCount;
}

// Managing Scrollers

- (void)setHorizontalScroller:(CPScroller)aScroller
{
    if (_horizontalScroller == aScroller)
        return;
    
    [_horizontalScroller removeFromSuperview];
    [_horizontalScroller setTarget:nil];
    [_horizontalScroller setAction:nil];
    
    _horizontalScroller = aScroller;
    
    [_horizontalScroller setTarget:self];
    [_horizontalScroller setAction:@selector(_horizontalScrollerDidScroll:)];
    [self addSubview:_horizontalScroller];
}

- (CPScroller)horizontalScroller
{
    return _horizontalScroller;
}

- (void)setHasHorizontalScroller:(BOOL)hasHorizontalScroller
{
    _hasHorizontalScroller = hasHorizontalScroller;
    
    if (_hasHorizontalScroller && !_horizontalScroller)
        [self setHorizontalScroller:[[CPScroller alloc] initWithFrame:CPRectMake(0.0, 0.0, CPRectGetWidth([self bounds]), [CPScroller scrollerWidth])]];
    else if (!hasHorizontalScroller && _horizontalScroller)
        [_horizontalScroller setHidden:YES];
}

- (BOOL)hasHorizontalScroller
{
    return _hasHorizontalScroller;
}

- (void)setVerticalScroller:(CPScroller)aScroller
{
    if (_verticalScroller == aScroller)
        return;
    
    [_verticalScroller removeFromSuperview];
    [_verticalScroller setTarget:nil];
    [_verticalScroller setAction:nil];
    
    _verticalScroller = aScroller;
    
    [_verticalScroller setTarget:self];
    [_verticalScroller setAction:@selector(_verticalScrollerDidScroll:)];
    [self addSubview:_verticalScroller];
}

- (CPScroller)verticalScroller
{
    return _verticalScroller;
}

- (void)setHasVerticalScroller:(BOOL)hasVerticalScroller
{
    _hasVerticalScroller = hasVerticalScroller;
    
    if (_hasVerticalScroller && !_verticalScroller)
        [self setVerticalScroller:[[CPScroller alloc] initWithFrame:CPRectMake(0.0, 0.0, [CPScroller scrollerWidth], CPRectGetHeight([self bounds]))]];
    else if (!hasVerticalScroller && _verticalScroller)
        [_verticalScroller setHidden:YES];
}

- (BOOL)hasHorizontalScroller
{
    return _hasHorizontalScroller;
}

- (void)setAutohidesScrollers:(BOOL)autohidesScrollers
{
    _autohidesScrollers = autohidesScrollers;
}

- (BOOL)autohidesScrollers
{
    return _autohidesScrollers;
}
/*
- (void)setFrameSize:(CPRect)aSize
{
    [super setFrameSize:aSize];
    
    [self reflectScrolledClipView:_contentView];
}*/

- (void)_verticalScrollerDidScroll:(CPScroller)aScroller
{
   var  value = [aScroller floatValue],
        documentFrame = [[_contentView documentView] frame];
        contentBounds = [_contentView bounds];

    switch ([_verticalScroller hitPart])
    {
        case CPScrollerDecrementLine:   contentBounds.origin.y -= _verticalLineScroll;
                                        break;
        
        case CPScrollerIncrementLine:   contentBounds.origin.y += _verticalLineScroll;
                                        break;
           
        case CPScrollerDecrementPage:   contentBounds.origin.y -= _CGRectGetHeight(contentBounds) - _verticalPageScroll;
                                        break;
        
        case CPScrollerIncrementPage:   contentBounds.origin.y += _CGRectGetHeight(contentBounds) - _verticalPageScroll;
                                        break;
        
        case CPScrollerKnobSlot:
        case CPScrollerKnob:
        default:                        contentBounds.origin.y = value * (_CGRectGetHeight(documentFrame) - _CGRectGetHeight(contentBounds));
    }
    
    [_contentView scrollToPoint:contentBounds.origin];
}

- (void)_horizontalScrollerDidScroll:(CPScroller)aScroller
{
   var value = [aScroller floatValue],
       documentFrame = [[self documentView] frame],
       contentBounds = [_contentView bounds];
        
    switch ([_horizontalScroller hitPart])
    {
        case CPScrollerDecrementLine:   contentBounds.origin.x -= _horizontalLineScroll;
                                        break;
        
        case CPScrollerIncrementLine:   contentBounds.origin.x += _horizontalLineScroll;
                                        break;
           
        case CPScrollerDecrementPage:   contentBounds.origin.x -= _CGRectGetWidth(contentBounds) - _horizontalPageScroll;
                                        break;
        
        case CPScrollerIncrementPage:   contentBounds.origin.x += _CGRectGetWidth(contentBounds) - _horizontalPageScroll;
                                        break;
        
        case CPScrollerKnobSlot:
        case CPScrollerKnob:
        default:                        contentBounds.origin.x = value * (_CGRectGetWidth(documentFrame) - _CGRectGetWidth(contentBounds));
    }

    [_contentView scrollToPoint:contentBounds.origin];
}

- (void)tile
{
    // yuck.
    // RESIZE: tile->setHidden AND refl
    // Outside Change: refl->tile->setHidden AND refl
    // scroll: refl.
}

-(void)resizeSubviewsWithOldSize:(CPSize)aSize
{
    [self reflectScrolledClipView:_contentView];
}

// Setting Scrolling Behavior

- (void)setLineScroll:(float)aLineScroll
{
    [self setHorizonalLineScroll:aLineScroll];
    [self setVerticalLineScroll:aLineScroll];
}

- (float)lineScroll
{
    return [self horizontalLineScroll];
}

- (void)setHorizontalLineScroll:(float)aLineScroll
{
    _horizontalLineScroll = aLineScroll;
}

- (float)horizontalLineScroll
{
    return _horizontalLineScroll;
}

- (void)setVerticalLineScroll:(float)aLineScroll
{
    _verticalLineScroll = aLineScroll;
}

- (float)verticalLineScroll
{
    return _verticalLineScroll;
}

- (void)setPageScroll:(float)aPageScroll
{
    [self setHorizontalPageScroll:aPageScroll];
    [self setVerticalPageScroll:aPageScroll];
}

- (float)pageScroll
{
    return [self horizontalPageScroll];
}

- (void)setHorizontalPageScroll:(float)aPageScroll
{
    _horizontalPageScroll = aPageScroll;
}

- (float)horizontalPageScroll
{
    return _horizontalPageScroll;
}

- (void)setVerticalPageScroll:(float)aPageScroll
{
    _verticalPageScroll = aPageScroll;
}

- (float)verticalPageScroll
{
    return _verticalPageScroll;
}

- (void)scrollWheel:(CPEvent)anEvent
{
   var value = [_verticalScroller floatValue],
       documentFrame = [[self documentView] frame],
       contentBounds = [_contentView bounds];

    contentBounds.origin.x += [anEvent deltaX] * _horizontalLineScroll;
    contentBounds.origin.y += [anEvent deltaY] * _verticalLineScroll;

    [_contentView scrollToPoint:contentBounds.origin];
}

@end
