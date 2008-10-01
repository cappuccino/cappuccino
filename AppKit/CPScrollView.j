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

/*
    Used to display views that are too large for the viewing area. the <objj>CPScrollView</objj>
    places scroll bars on the side of the view to allow the user to scroll and see the entire
    contents of the view.
*/
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

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _verticalLineScroll = 10.0;
        _verticalPageScroll = CGRectGetHeight(aFrame)/2.0;
        
        _horizontalLineScroll = 10.0;
        _horizontalPageScroll = CGRectGetWidth(aFrame)/2.0;

        _contentView = [[CPClipView alloc] initWithFrame:[self bounds]];
        
        [self addSubview:_contentView];
        
        [self setHasVerticalScroller:YES];
        [self setHasHorizontalScroller:YES];
    }
    
    return self;
}

// Determining component sizes
/*
    Returns the size of the scroll view's content view.
*/
- (CGRect)contentSize
{
    return [_contentView frame].size;
}

/*
    Returns the view that is scrolled for the user.
*/
- (id)documentView
{
    return [_contentView documentView];
}

/*
    Sets the content view that clips the document
    @param aContentView the content view
*/
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

/*
    Returns the content view that clips the document.
*/
- (CPClipView)contentView
{
    return _contentView;
}

/*
    Sets the view that is scrolled for the user.
    @param aView the view that will be scrolled
*/
- (void)setDocumentView:(CPView)aView
{
   [_contentView setDocumentView:aView];
   [self reflectScrolledClipView:_contentView];
}

/*
    Resizes the scroll view to contain the specified
    clip view.
    @param aClipView the clip view to resize to
*/
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
/*
    Sets the scroll view's horizontal scroller.
    @param aScroller the horizontal scroller for the scroll view
*/
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

/*
    Returns the scroll view's horizontal scroller
*/
- (CPScroller)horizontalScroller
{
    return _horizontalScroller;
}

/*
    Specifies whether the scroll view can have a horizontal scroller.
    @param hasHorizontalScroller <code>YES</code> lets the scroll view
    allocate a horizontal scroller if necessary.
*/
- (void)setHasHorizontalScroller:(BOOL)hasHorizontalScroller
{
    _hasHorizontalScroller = hasHorizontalScroller;
    
    if (_hasHorizontalScroller && !_horizontalScroller)
        [self setHorizontalScroller:[[CPScroller alloc] initWithFrame:CPRectMake(0.0, 0.0, CPRectGetWidth([self bounds]), [CPScroller scrollerWidth])]];
    else if (!hasHorizontalScroller && _horizontalScroller)
        [_horizontalScroller setHidden:YES];
}

/*
    Returns <code>YES</code> if the scroll view can have a horizontal
    scroller.
*/
- (BOOL)hasHorizontalScroller
{
    return _hasHorizontalScroller;
}

/*
    Sets the scroll view's vertical scroller.
    @param aScroller the vertical scroller
*/
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

/*
    Return's the scroll view's vertical scroller
*/
- (CPScroller)verticalScroller
{
    return _verticalScroller;
}

/*
    Specifies whether the scroll view has can have
    a vertical scroller. It allocates it if necessary.
    @param hasVerticalScroller <code>YES</code> allows
    the scroll view to display a vertical scroller
*/
- (void)setHasVerticalScroller:(BOOL)hasVerticalScroller
{
    _hasVerticalScroller = hasVerticalScroller;
    
    if (_hasVerticalScroller && !_verticalScroller)
        [self setVerticalScroller:[[CPScroller alloc] initWithFrame:CPRectMake(0.0, 0.0, [CPScroller scrollerWidth], CPRectGetHeight([self bounds]))]];
    else if (!hasVerticalScroller && _verticalScroller)
        [_verticalScroller setHidden:YES];
}

/*
    Returns <code>YES</code> if the scroll view can have
    a vertical scroller.
*/
- (BOOL)hasHorizontalScroller
{
    return _hasHorizontalScroller;
}

/*
    Sets whether the scroll view hides its scoll bars when not needed.
    @param autohidesScrollers <code>YES</code> causes the scroll bars
    to be hidden when not needed.
*/
- (void)setAutohidesScrollers:(BOOL)autohidesScrollers
{
    _autohidesScrollers = autohidesScrollers;
}

/*
    Returns <code>YES</code> if the scroll view hides its scroll
    bars when not necessary.
*/
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

/* @ignore */
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

/* @ignore */
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

/*
    Lays out the scroll view's components.
*/
- (void)tile
{
    // yuck.
    // RESIZE: tile->setHidden AND refl
    // Outside Change: refl->tile->setHidden AND refl
    // scroll: refl.
}

/*
    @ignore
*/
-(void)resizeSubviewsWithOldSize:(CGSize)aSize
{
    [self reflectScrolledClipView:_contentView];
}

// Setting Scrolling Behavior
/*
    Sets how much the document moves when scrolled. Sets
    the vertical and horizontal scroll.
    @param aLineScroll the amount to move the document
    when scrolled
*/
- (void)setLineScroll:(float)aLineScroll
{
    [self setHorizonalLineScroll:aLineScroll];
    [self setVerticalLineScroll:aLineScroll];
}

/*
    Returns how much the document moves
    when scrolled
*/
- (float)lineScroll
{
    return [self horizontalLineScroll];
}

/*
    Sets how much the document moves when scrolled
    horizontally.
    @param aLineScroll the amount to move horizontally
    when scrolled.
*/
- (void)setHorizontalLineScroll:(float)aLineScroll
{
    _horizontalLineScroll = aLineScroll;
}

/*
    Returns how much the document moves horizontally
    when scrolled.
*/
- (float)horizontalLineScroll
{
    return _horizontalLineScroll;
}

/*
    Sets how much the document moves when scrolled
    vertically.
    @param aLineScroll the new amount to move vertically
    when scrolled.
*/
- (void)setVerticalLineScroll:(float)aLineScroll
{
    _verticalLineScroll = aLineScroll;
}

/*
    Returns how much the document moves vertically
    when scrolled.
*/
- (float)verticalLineScroll
{
    return _verticalLineScroll;
}

/*
    Sets the horizontal and vertical page scroll amount.
    @param aPageScroll the new horizontal and vertical page
    scroll amount
*/
- (void)setPageScroll:(float)aPageScroll
{
    [self setHorizontalPageScroll:aPageScroll];
    [self setVerticalPageScroll:aPageScroll];
}

/*
    Returns the vertical and horizontal page scroll
    amount.
*/
- (float)pageScroll
{
    return [self horizontalPageScroll];
}

/*
    Sets the horizontal page scroll amount.
    @param aPageScroll the new horizontal page scroll amount
*/
- (void)setHorizontalPageScroll:(float)aPageScroll
{
    _horizontalPageScroll = aPageScroll;
}

/*
    Returns the horizontal page scroll amount.
*/
- (float)horizontalPageScroll
{
    return _horizontalPageScroll;
}

/*
    Sets the vertical page scroll amount.
    @param aPageScroll the new vertcal page scroll
    amount
*/
- (void)setVerticalPageScroll:(float)aPageScroll
{
    _verticalPageScroll = aPageScroll;
}

/*
    Returns the vertical page scroll amount.
*/
- (float)verticalPageScroll
{
    return _verticalPageScroll;
}

/*
    Handles a scroll wheel event from the user.
    @param anEvent the scroll wheel event
*/
- (void)scrollWheel:(CPEvent)anEvent
{
   var value = [_verticalScroller floatValue],
       documentFrame = [[self documentView] frame],
       contentBounds = [_contentView bounds];

    contentBounds.origin.x += [anEvent deltaX] * _horizontalLineScroll;
    contentBounds.origin.y += [anEvent deltaY] * _verticalLineScroll;

    [_contentView scrollToPoint:contentBounds.origin];
}

- (void)keyDown:(CPEvent)anEvent
{
    var keyCode = [anEvent keyCode],
        value = [_verticalScroller floatValue],
        documentFrame = [[self documentView] frame],
        contentBounds = [_contentView bounds];
    
    switch (keyCode)
    {
        case 33:    /*pageup*/
                    contentBounds.origin.y -= [self verticalPageScroll];
                    break;
                    
        case 34:    /*pagedown*/
                    contentBounds.origin.y += [self verticalPageScroll];
                    break;
                    
        case 38:    /*up arrow*/
                    contentBounds.origin.y -= _verticalLineScroll;
                    break;

        case 40:    /*down arrow*/
                    contentBounds.origin.y += _verticalLineScroll;
                    break;
                    
        case 37:    /*left arrow*/
                    contentBounds.origin.x -= _horizontalLineScroll;
                    break;

        case 49:    /*right arrow*/
                    contentBounds.origin.x += _horizontalLineScroll;
                    break;
                    
        default:    return [super keyDown:anEvent];
    }

    [_contentView scrollToPoint:contentBounds.origin];
}

@end
