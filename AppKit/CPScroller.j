/*
 * CPScroller.j
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

@import "CPControl.j"

#include "CoreGraphics/CGGeometry.h"
#include "CPThemedValue.h"


// CPScroller Constants
CPScrollerNoPart            = 0;
CPScrollerDecrementPage     = 1;
CPScrollerKnob              = 2;
CPScrollerIncrementPage     = 3;
CPScrollerDecrementLine     = 4;
CPScrollerIncrementLine     = 5;
CPScrollerKnobSlot          = 6;

CPScrollerIncrementArrow    = 0;
CPScrollerDecrementArrow    = 1;

CPNoScrollerParts           = 0;
CPOnlyScrollerArrows        = 1;
CPAllScrollerParts          = 2;

/*! @class CPScroller
    
*/

var PARTS_ARRANGEMENT = [CPScrollerKnobSlot, CPScrollerDecrementLine, CPScrollerIncrementLine, CPScrollerKnob];

@implementation CPScroller : CPControl
{
    CPControlSize           _controlSize;
    CPUsableScrollerParts   _usableParts;
    CPArray                 _partRects;

    BOOL                    _isVertical;
    float                   _knobProportion;
    
    CPScrollerPart          _hitPart;
    
    CPScrollerPart          _trackingPart;
    float                   _trackingFloatValue;
    CGPoint                 _trackingStartPoint;
    
    CPView                  _knobView;
    CPView                  _knobSlotView;

    CPView                  _decrementArrowView;
    CPView                  _incrementArrowView;
    
    JSObject                _layoutViews;
    
    CPThemedValue           _scrollerWidth;
    
    CPThemedValue           _trackOverlapInset;
    
    CPArray                 _horizontalPartColors;
    CPArray                 _verticalPartColors;
    
    CPThemedValue           _verticalMinimumKnobSize;
    CPThemedValue           _verticalDecrementLineSize;
    CPThemedValue           _verticalIncrementLineSize;
    
    CPThemedValue           _horizontalMinimumKnobSize;
    CPThemedValue           _horizontalDecrementLineSize;
    CPThemedValue           _horizontalIncrementLineSize;
}

// Calculating Layout

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {_layoutViews = {}
        _controlSize = CPRegularControlSize;
        _partRects = [];

        [self setFloatValue:0.0 knobProportion:1.0];
        
        _hitPart = CPScrollerNoPart;
        
        var theme = [self theme],
            theClass = [self class];
        
        _trackOverlapInset = CPThemedValueMake(_CGInsetMakeZero(), "track-overlap-inset", theme, theClass);
    
        _verticalMinimumKnobSize = CPThemedValueMake(_CGSizeMake(10.0,10.0), "vertical-minimum-knob-size", theme, theClass);
        _verticalDecrementLineSize = CPThemedValueMake(_CGSizeMakeZero(), "vertical-decrement-line-size", theme, theClass);
        _verticalIncrementLineSize = CPThemedValueMake(_CGSizeMakeZero(), "vertical-increment-line-size", theme, theClass);

        _horizontalMinimumKnobSize = CPThemedValueMake(_CGSizeMakeZero(), "horizontal-minimum-knob-size", theme, theClass);
        _horizontalDecrementLineSize = CPThemedValueMake(_CGSizeMakeZero(), "horizontal-decrement-line-size", theme, theClass);
        _horizontalIncrementLineSize = CPThemedValueMake(_CGSizeMakeZero(), "horizontal-increment-line-size", theme, theClass);

        _horizontalPartColors = [];
        _verticalPartColors = [];
        
        var index = 0,
            count = PARTS_ARRANGEMENT.length;
        
        for (; index < count; ++index)
        {
            var part = PARTS_ARRANGEMENT[index];
            
            _horizontalPartColors[part] = CPThemedValueMake(nil, "horizontal-" + part + "-color", theme, theClass);
            _verticalPartColors[part] = CPThemedValueMake(nil, "vertical-" + part + "-color", theme, theClass);
        }
        
        [self setNeedsLayout];
    }

    return self;
}

- (BOOL)isVertical
{
    if (_isVertical === nil)
    {
        var bounds = [self bounds],
            width = _CGRectGetWidth(bounds),
            height = _CGRectGetHeight(bounds);
        
        _isVertical = width < height ? 1 : (width > height ? 0 : -1);
    }

    return _isVertical;
}
// Determining CPScroller Size
/*!
    Returns the CPScroller's width for a CPRegularControlSize.
*/
+ (float)scrollerWidth
{
    return 17.0;//[self scrollerWidthForControlSize:CPRegularControlSize];
}

/*!
    Returns the width of a CPScroller for the specified CPControlSize.
    @param aControlSize the size of a controller to return the width for
*/
+ (float)scrollerWidthForControlSize:(CPControlSize)aControlSize
{
    return 17.0;//_CPScrollerWidths[aControlSize];
}

/*!
    Sets the scroller's size.
    @param aControlSize the scroller's size
*/
- (void)setControlSize:(CPControlSize)aControlSize
{
    if (_controlSize == aControlSize)
        return;

    _controlSize = aControlSize;

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns the scroller's control size
*/
- (CPControlSize)controlSize
{
    return _controlSize;
}

// Setting the Knob Position
/*!
    Sets the scroller's knob position (ranges from 0.0 to 1.0).
    @param aValue the knob position (ranges from 0.0 to 1.0)
*/
- (void)setFloatValue:(float)aValue
{
    [super setFloatValue:MIN(1.0, MAX(0.0, aValue))];
    
    [self setNeedsLayout];
}

/*!
    Sets the position and proportion of the knob.
    @param aValue the knob position (ranges from 0.0 to 1.0)
    @param aProportion the knob's proportion (ranges from 0.0 to 1.0)
*/
- (void)setFloatValue:(float)aValue knobProportion:(float)aProportion
{
    _knobProportion = MIN(1.0, MAX(0.0001, aProportion));

    [self setFloatValue:aValue];
}

/*!
    Return's the knob's proportion
*/
- (float)knobProportion
{
    return _knobProportion;
}

THEMED_STATED_VALUE(TrackOverlapInset, trackOverlapInset);

THEMED_STATED_VALUE(VerticalMinimumKnobSize, verticalMinimumKnobSize);
THEMED_STATED_VALUE(VerticalDecrementLineSize, verticalDecrementLineSize);
THEMED_STATED_VALUE(VerticalIncrementLineSize, verticalIncrementLineSize);

THEMED_STATED_VALUE(HorizontalMinimumKnobSize, horizontalMinimumKnobSize);
THEMED_STATED_VALUE(HorizontalDecrementLineSize, horizontalDecrementLineSize);
THEMED_STATED_VALUE(HorizontalIncrementLineSize, horizontalIncrementLineSize);

- (void)setColor:(CPColor)aColor forHorizontalPart:(CPScrollerPart)aScrollerPart controlState:(CPControlState)aControlState
{
    var currentValue = [_horizontalPartColors[aScrollerPart] valueForControlState:_controlState];
    
    [_horizontalPartColors[aScrollerPart] setValue:aColor forControlState:aControlState];
    
    if ([_horizontalPartColors[aScrollerPart] valueForControlState:_controlState] === currentValue)
        return;
    
    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
}

- (CPColor)colorForHorizontalPart:(CPScrollerPart)aScrollerPart controlState:(CPControlState)aControlState
{
    return [_horizontalPartColors[aScrollerPart] valueForControlState:aControlState];
}

- (void)setColor:(CPColor)aColor forHorizontalPart:(CPScrollerPart)aScrollerPart
{
    var currentValue = [_horizontalPartColors[aScrollerPart] valueForControlState:_controlState];
    
    [_horizontalPartColors[aScrollerPart] setValue:aColor];
    
    if ([_horizontalPartColors[aScrollerPart] valueForControlState:_controlState] === currentValue)
        return;

    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
}

- (id)colorForHorizontalPart:(CPScrollerPart)aScrollerPart
{
    return [_horizontalPartColors[aScrollerPart] value];
}

- (id)currentColorForHorizontalPart:(CPScrollerPart)aScrollerPart
{
    var controlState = _controlState;
    
    if (_hitPart !== aScrollerPart)
        controlState &= ~CPControlStateHighlighted;
    
    return [_horizontalPartColors[aScrollerPart] valueForControlState:controlState];
}

- (void)setColor:(CPColor)aColor forVerticalPart:(CPScrollerPart)aScrollerPart controlState:(CPControlState)aControlState
{
    var currentValue = [_verticalPartColors[aScrollerPart] valueForControlState:_controlState];
    
    [_verticalPartColors[aScrollerPart] setValue:aColor forControlState:aControlState];
    
    if ([_verticalPartColors[aScrollerPart] valueForControlState:_controlState] === currentValue)
        return;
    
    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
}

- (CPColor)colorForVerticalPart:(CPScrollerPart)aScrollerPart controlState:(CPControlState)aControlState
{
    return [_verticalPartColors[aScrollerPart] valueForControlState:aControlState];
}

- (void)setColor:(CPColor)aColor forVerticalPart:(CPScrollerPart)aScrollerPart
{
    var currentValue = [_verticalPartColors[aScrollerPart] valueForControlState:_controlState];
    
    [_verticalPartColors[aScrollerPart] setValue:aColor];
    
    if ([_verticalPartColors[aScrollerPart] valueForControlState:_controlState] === currentValue)
        return;

    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
}

- (id)colorForVerticalPart:(CPScrollerPart)aScrollerPart
{
    return [_verticalPartColors[aScrollerPart] value];
}

- (id)currentColorForVerticalPart:(CPScrollerPart)aScrollerPart
{
    var controlState = _controlState;
    
    if (_hitPart !== aScrollerPart)
        controlState &= ~CPControlStateHighlighted;
    
    return [_verticalPartColors[aScrollerPart] valueForControlState:controlState];
}

// Calculating Layout

- (CGRect)rectForPart:(CPScrollerPart)aPart
{
    if (aPart == CPScrollerNoPart)
        return _CGRectMakeZero();

    return _partRects[aPart];
}

/*!
    Returns the part of the scroller that would be hit by <code>aPoint</code>.
    @param aPoint the simulated point hit
    @return the part of the scroller that intersects the point
*/
- (CPScrollerPart)testPart:(CGPoint)aPoint
{
    aPoint = [self convertPoint:aPoint fromView:nil];
    
    // The ordering of these tests is important.  We check the knob and 
    // page rects first since they may overlap with the arrows.
    
    if (CGRectContainsPoint([self rectForPart:CPScrollerKnob], aPoint))
        return CPScrollerKnob;
    
    if (CGRectContainsPoint([self rectForPart:CPScrollerDecrementPage], aPoint))
        return CPScrollerDecrementPage;
    
    if (CGRectContainsPoint([self rectForPart:CPScrollerIncrementPage], aPoint))
        return CPScrollerIncrementPage;
    
    if (CGRectContainsPoint([self rectForPart:CPScrollerDecrementLine], aPoint))
        return CPScrollerDecrementLine;
    
    if (CGRectContainsPoint([self rectForPart:CPScrollerIncrementLine], aPoint))
        return CPScrollerIncrementLine;
    
    if (CGRectContainsPoint([self rectForPart:CPScrollerKnobSlot], aPoint))
        return CPScrollerKnobSlot;

    return CPScrollerNoPart;
}

/*!
    Check if there's enough space in the scroller to display the knob
*/
- (void)checkSpaceForParts
{
    var bounds = [self bounds];

    // Assume we won't be needing the arrows.
    if (_knobProportion === 1.0)
    {
        _usableParts = CPNoScrollerParts;
    
        _partRects[CPScrollerDecrementPage] = _CGRectMakeZero();
        _partRects[CPScrollerKnob]          = _CGRectMakeZero();
        _partRects[CPScrollerIncrementPage] = _CGRectMakeZero();
        _partRects[CPScrollerDecrementLine] = _CGRectMakeZero();
        _partRects[CPScrollerIncrementLine] = _CGRectMakeZero();

        // In this case, the slot is the entirety of the scroller.
        _partRects[CPScrollerKnobSlot] = _CGRectMakeCopy(bounds);
        
        return;
    }

    // At this point we know we're going to need arrows.
    _usableParts = CPAllScrollerParts;

    var isHorizontal = ![self isVertical],
        trackOverlapInset = [self currentTrackOverlapInset],
        width = _CGRectGetWidth(bounds),
        height = _CGRectGetHeight(bounds);
    
    if (isHorizontal)
    {
        var decrementLineSize = [self currentHorizontalDecrementLineSize],
            incrementLineSize = [self currentHorizontalIncrementLineSize],
            effectiveDecrementLineWidth = decrementLineSize.width - trackOverlapInset.left,
            effectiveIncrementLineWidth = incrementLineSize.width - trackOverlapInset.right;
            slotWidth = width - effectiveDecrementLineWidth - effectiveIncrementLineWidth,
            minimumKnobSize = [self currentHorizontalMinimumKnobSize],
            knobWidth = MAX(minimumKnobSize.width, (slotWidth * _knobProportion)),
            knobLocation = effectiveDecrementLineWidth + (slotWidth - knobWidth) * [self floatValue];
        
        _partRects[CPScrollerDecrementPage] = _CGRectMake(effectiveDecrementLineWidth, 0.0, knobLocation - effectiveDecrementLineWidth, height);
        _partRects[CPScrollerKnob]          = _CGRectMake(knobLocation, 0.0, knobWidth, minimumKnobSize.height);
        _partRects[CPScrollerIncrementPage] = _CGRectMake(knobLocation + knobWidth, 0.0, width - (knobLocation + knobWidth) - effectiveIncrementLineWidth, height);
        _partRects[CPScrollerKnobSlot]      = _CGRectMake(effectiveDecrementLineWidth, 0.0, slotWidth, height);
        _partRects[CPScrollerDecrementLine] = _CGRectMake(0.0, 0.0, decrementLineSize.width, decrementLineSize.height);
        _partRects[CPScrollerIncrementLine] = _CGRectMake(width - incrementLineSize.width, 0.0, incrementLineSize.width, incrementLineSize.height);
    }
    else
    {
        var decrementLineSize = [self currentVerticalDecrementLineSize],
            incrementLineSize = [self currentVerticalIncrementLineSize],
            effectiveDecrementLineHeight = decrementLineSize.height - trackOverlapInset.top,
            effectiveIncrementLineHeight = incrementLineSize.height - trackOverlapInset.bottom,
            slotHeight = height - effectiveDecrementLineHeight - effectiveIncrementLineHeight,
            minimumKnobSize = [self currentVerticalMinimumKnobSize],
            knobHeight = MAX(minimumKnobSize.height, (slotHeight * _knobProportion)),
            knobLocation = effectiveDecrementLineHeight + (slotHeight - knobHeight) * [self floatValue];
        
        _partRects[CPScrollerDecrementPage] = _CGRectMake(0.0, effectiveDecrementLineHeight, width, knobLocation - effectiveDecrementLineHeight);
        _partRects[CPScrollerKnob]          = _CGRectMake((width - minimumKnobSize.width) / 2.0, knobLocation, minimumKnobSize.width, knobHeight);
        _partRects[CPScrollerIncrementPage] = _CGRectMake(0.0, knobLocation + knobHeight, width, height - (knobLocation + knobHeight) - effectiveIncrementLineHeight);
        _partRects[CPScrollerKnobSlot]      = _CGRectMake(0.0, effectiveDecrementLineHeight, width, slotHeight);
        _partRects[CPScrollerDecrementLine] = _CGRectMake(0.0, 0.0, decrementLineSize.width, decrementLineSize.height);
        _partRects[CPScrollerIncrementLine] = _CGRectMake(0.0, height - incrementLineSize.height, incrementLineSize.width, incrementLineSize.height);  
    }
}

/*!
    Returns all the parts of the scroller that
    are usable for displaying.
*/
- (CPUsableScrollerParts)usableParts
{
    return _usableParts;
}

// Drawing the Parts
/*!
    Draws the specified arrow and sets the highlight.
    @param anArrow the arrow to draw
    @param shouldHighlight sets whether the arrow should be highlighted
*/
- (void)drawArrow:(CPScrollerArrow)anArrow highlight:(BOOL)shouldHighlight
{
}

/*!
    Draws the knob
*/
- (void)drawKnob
{
}

/*!
    Draws the knob's slot
*/
- (void)drawKnobSlot
{
}

- (CPView)createViewForPart:(CPScrollerPart)aPart
{
    var view = [[CPView alloc] initWithFrame:_CGRectMakeZero()];
    
    [view setHitTests:NO];
    
    return view;
}

- (CPView)layoutSubviewNamed:(CPString)aViewName positioned:(CPWindowOrderingMode)anOrderingMode relativeToSubviewNamed:(CPString)relativeToViewName
{
    var frame = [self rectForPart:aViewName];

    if (frame && !_CGRectIsEmpty(frame))
    {
        if (!_layoutViews[aViewName])
        {
            _layoutViews[aViewName] = [self createViewForPart:aViewName];
        
            if (_layoutViews[aViewName])
                [self addSubview:_layoutViews[aViewName] positioned:anOrderingMode relativeTo:_layoutViews[relativeToViewName]];
        }
        
        if (_layoutViews[aViewName])
            [_layoutViews[aViewName] setFrame:frame];
    }
    else if (_layoutViews[aViewName])
    {
        [_layoutViews[aViewName] removeFromSuperview];
        
        delete _layoutViews[aViewName];
    }
    
    return _layoutViews[aViewName];
}

- (void)layoutSubviews
{
    [self checkSpaceForParts];

    var index = 0,
        count = PARTS_ARRANGEMENT.length,
        selector = [self isVertical] ? @selector(currentColorForVerticalPart:) : @selector(currentColorForHorizontalPart:);
    
    for (; index < count; ++index)
    {
        var part = PARTS_ARRANGEMENT[index];
    
        if (index === 0)
            view = [self layoutSubviewNamed:part positioned:CPWindowBelow relativeToSubviewNamed:PARTS_ARRANGEMENT[index + 1]];
        else
            view = [self layoutSubviewNamed:part positioned:CPWindowAbove relativeToSubviewNamed:PARTS_ARRANGEMENT[index - 1]];
        
        if (view)
            [view setBackgroundColor:objj_msgSend(self, selector, part)];
    }
}

/*!
    Caches images for the scroll arrow and knob.
*/
- (void)drawParts
{   
    [self drawKnobSlot];
    [self drawKnob];
    [self drawArrow:CPScrollerDecrementArrow highlight:NO];
    [self drawArrow:CPScrollerIncrementArrow highlight:NO];
}

// Event Handling
/*!
    Returns the part of the scroller that was hit.
*/
- (CPScrollerPart)hitPart
{
    return _hitPart;
}

/*!
    Tracks the knob.
    @param anEvent the input event
*/
- (void)trackKnob:(CPEvent)anEvent
{
    var type = [anEvent type];
    
    if (type === CPLeftMouseUp)
    {
        _hitPart = CPScrollerNoPart;
        
        return;
    }
    
    if (type === CPLeftMouseDown)
    {
        _trackingFloatValue = [self floatValue];
        _trackingStartPoint = [self convertPoint:[anEvent locationInWindow] fromView:nil];
    }
    
    else if (type === CPLeftMouseDragged)
    {
        var knobRect = [self rectForPart:CPScrollerKnob],
            knobSlotRect = [self rectForPart:CPScrollerKnobSlot],
            remainder = ![self isVertical] ? (_CGRectGetWidth(knobSlotRect) - _CGRectGetWidth(knobRect)) : (_CGRectGetHeight(knobSlotRect) - _CGRectGetHeight(knobRect));
            
        if (remainder <= 0)
            [self setFloatValue:0.0];
        else
        {
            var location = [self convertPoint:[anEvent locationInWindow] fromView:nil];
                delta = ![self isVertical] ? location.x - _trackingStartPoint.x : location.y - _trackingStartPoint.y;

            [self setFloatValue:_trackingFloatValue + delta / remainder];
        }
    }
    
    [CPApp setTarget:self selector:@selector(trackKnob:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];

    [self sendAction:[self action] to:[self target]];
}

/*!
    Tracks the scroll button.
    @param anEvent the input event
*/
- (void)trackScrollButtons:(CPEvent)anEvent
{
    var type = [anEvent type];

    if (type === CPLeftMouseUp)
    {
        [self highlight:NO];
        [CPEvent stopPeriodicEvents];
        
        _hitPart = CPScrollerNoPart;
        
        return;
    }
    
    if (type === CPLeftMouseDown)
    {
        _trackingPart = [self hitPart];
        
        _trackingStartPoint = [self convertPoint:[anEvent locationInWindow] fromView:nil];

        if ([anEvent modifierFlags] & CPAlternateKeyMask)
        {
            if (_trackingPart == CPScrollerDecrementLine)
                _hitPart = CPScrollerDecrementPage;
            
            else if (_trackingPart == CPScrollerIncrementLine)
                _hitPart = CPScrollerIncrementPage;
            
            else if (_trackingPart == CPScrollerDecrementPage || _trackingPart == CPScrollerIncrementPage)
            {
                var knobRect = [self rectForPart:CPScrollerKnob],
                    knobWidth = ![self isVertical] ? _CGRectGetWidth(knobRect) : _CGRectGetHeight(knobRect),
                    knobSlotRect = [self rectForPart:CPScrollerKnobSlot],
                    remainder = (![self isVertical] ? _CGRectGetWidth(knobSlotRect) : _CGRectGetHeight(knobSlotRect)) - knobWidth;

                [self setFloatValue:((![self isVertical] ? _trackingStartPoint.x - _CGRectGetMinX(knobSlotRect) : _trackingStartPoint.y - _CGRectGetMinY(knobSlotRect)) - knobWidth / 2.0) / remainder];
                
                _hitPart = CPScrollerKnob;
                
                [self sendAction:[self action] to:[self target]];        
                
                // Now just track the knob.
                return [self trackKnob:anEvent];
            }
        }
        
        [self highlight:YES];
        [self sendAction:[self action] to:[self target]];
        
        [CPEvent startPeriodicEventsAfterDelay:0.5 withPeriod:0.04];
    }
    
    else if (type === CPLeftMouseDragged)
    {
        _trackingStartPoint = [self convertPoint:[anEvent locationInWindow] fromView:nil];
        
        if (_trackingPart == CPScrollerDecrementPage || _trackingPart == CPScrollerIncrementPage)
        {
            var hitPart = [self testPart:[anEvent locationInWindow]];
            
            if (hitPart == CPScrollerDecrementPage || hitPart == CPScrollerIncrementPage)
            {
                _trackingPart = hitPart;
                _hitPart = hitPart;
            }
        }
        
        [self highlight:CGRectContainsPoint([self rectForPart:_trackingPart], _trackingStartPoint)];
    }
    else if (type == CPPeriodic && CGRectContainsPoint([self rectForPart:_trackingPart], _trackingStartPoint))
        [self sendAction:[self action] to:[self target]];
    
    [CPApp setTarget:self selector:@selector(trackScrollButtons:) forNextEventMatchingMask:CPPeriodicMask | CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];

}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    
    _isVertical = nil;
    
    [self checkSpaceForParts];
    [self setNeedsLayout];
}

- (void)mouseDown:(CPEvent)anEvent
{
    if (![self isEnabled])
        return;
    
    _hitPart = [self testPart:[anEvent locationInWindow]];
    
    switch (_hitPart)
    {
        case CPScrollerKnob:            return [self trackKnob:anEvent];
        
        case CPScrollerDecrementLine:   
        case CPScrollerIncrementLine:   
        case CPScrollerDecrementPage:
        case CPScrollerIncrementPage:   return [self trackScrollButtons:anEvent];
    }
}

@end

@implementation CPScroller (Theming)

- (void)viewDidChangeTheme
{
    [super viewDidChangeTheme];
    
    var theme = [self theme];
    
    [_trackOverlapInset setTheme:theme];
    
    [_verticalMinimumKnobSize setTheme:theme];
    [_verticalDecrementLineSize setTheme:theme];
    [_verticalIncrementLineSize setTheme:theme];

    [_horizontalMinimumKnobSize setTheme:theme];
    [_horizontalDecrementLineSize setTheme:theme];
    [_horizontalIncrementLineSize setTheme:theme];
    
    var index = 0,
        count = PARTS_ARRANGEMENT.length;
    
    for (; index < count; ++index)
    {
        var part = PARTS_ARRANGEMENT[index];
        
        [_horizontalPartColors[part] setTheme:theme];
        [_verticalPartColors[part] setTheme:theme];
    }
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (CPDictionary)themedValues
{
    var values = [super themedValues],
        isVertical = [self isVertical];
    
    [values setObject:_trackOverlapInset forKey:"track-overlap-inset"];
    
    if (isVertical)
    {
        [values setObject:_verticalMinimumKnobSize forKey:"vertical-minimum-knob-size"];
        [values setObject:_verticalDecrementLineSize forKey:"vertical-decrement-line-size"];
        [values setObject:_verticalIncrementLineSize forKey:"vertical-increment-line-size"];
    }
    else
    {
        [values setObject:_horizontalMinimumKnobSize forKey:"horizontal-minimum-knob-size"];
        [values setObject:_horizontalDecrementLineSize forKey:"horizontal-decrement-line-size"];
        [values setObject:_horizontalIncrementLineSize forKey:"horizontal-increment-line-size"];
    }
        
    var index = 0,
        count = PARTS_ARRANGEMENT.length;
    
    for (; index < count; ++index)
    {
        var part = PARTS_ARRANGEMENT[index];
        
        [values setObject:(isVertical ? _verticalPartColors : _horizontalPartColors)[part] forKey:(isVertical ? "vertical-" : "horizontal-") + part + "-color"];
    }
    
    return values;
}

@end

var CPScrollerControlSizeKey = "CPScrollerControlSize",
    CPScrollerKnobProportionKey = "CPScrollerKnobProportion";

@implementation CPScroller (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {_layoutViews = {};
        _controlSize = CPRegularControlSize;
        if ([aCoder containsValueForKey:CPScrollerControlSizeKey])
            _controlSize = [aCoder decodeIntForKey:CPScrollerControlSizeKey];
            
        _knobProportion = 1.0;
        if ([aCoder containsValueForKey:CPScrollerKnobProportionKey])
            _knobProportion = [aCoder decodeFloatForKey:CPScrollerKnobProportionKey];
            
        _partRects = [];
        _verticalPartColors = [];
        _horizontalPartColors = [];
        
        _isHorizontal = CPRectGetWidth([self frame]) > CPRectGetHeight([self frame]);
        
        _hitPart = CPScrollerNoPart;
        
//        [self checkSpaceForParts];
//        [self setNeedsLayout];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeInt:_controlSize forKey:CPScrollerControlSizeKey];
    [aCoder encodeFloat:_knobProportion forKey:CPScrollerKnobProportionKey];
}

@end
