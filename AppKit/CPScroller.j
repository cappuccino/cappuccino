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

var _CPScrollerWidths                               = [],
    _CPScrollerKnobMinimumHeights                   = [],
    _CPScrollerArrowHeights                         = [],
    _CPScrollerArrowUsableHeights                   = [];

_CPScrollerWidths[CPRegularControlSize]             = 14.0;
_CPScrollerWidths[CPSmallControlSize]               = 11.0;
_CPScrollerWidths[CPMiniControlSize]                = 11.0; // FIXME
    
_CPScrollerKnobMinimumHeights[CPRegularControlSize] = 18.0;
_CPScrollerKnobMinimumHeights[CPSmallControlSize]   = 12.0;
_CPScrollerKnobMinimumHeights[CPMiniControlSize]    = 12.0; // FIXME

_CPScrollerArrowHeights[CPRegularControlSize]       = 21.0;
_CPScrollerArrowHeights[CPSmallControlSize]         = 16.0;
_CPScrollerArrowHeights[CPMiniControlSize]          = 16.0; // FIXME

_CPScrollerArrowUsableHeights[CPRegularControlSize] = 16.0
_CPScrollerArrowUsableHeights[CPSmallControlSize]   = 10.0;
_CPScrollerArrowUsableHeights[CPMiniControlSize]    = 10.0; // FIXME    

var _CPScrollerKnobIdentifier                       = @"Knob",
    _CPScrollerKnobSlotIdentifier                   = @"KnobSlot",
    _CPScrollerDecrementArrowIdentifier             = @"DecrementArrow",
    _CPScrollerIncrementArrowIdentifier             = @"IncrementArrow",
    _CPScrollerHorizontalIdentifier                 = @"Horizontal",
    _CPScrollerVerticalIdentifier                   = @"Vertical",
    _CPScrollerHighlightedIdentifier                = @"Highlighted",
    _CPScrollerDisabledIdentifier                   = @"Disabled";
    
var _CPScrollerClassName                            = nil,
    _CPScrollerPartSizes                            = {};

/*! @class CPScroller
    
*/

@implementation CPScroller : CPControl
{
    CPControlSize           _controlSize;
    CPUsableScrollerParts   _usableParts;
    CPArray                 _partRects;

    BOOL                    _isHorizontal;
    float                   _knobProportion;
    
    CPScrollerPart          _hitPart;
    
    CPScrollerPart          _trackingPart;
    float                   _trackingFloatValue;
    CGPoint                 _trackingStartPoint;
    
    CPView                  _knobView;
    CPView                  _knobSlotView;

    CPView                  _decrementArrowView;
    CPView                  _incrementArrowView;
}

/*
    @ignore
*/
+ (void)initialize
{
    if (self != [CPScroller class])
        return;

    _CPScrollerClassName = [self className];

    var regularIdentifier = _CPControlIdentifierForControlSize(CPRegularControlSize),
        smallIdentifier = _CPControlIdentifierForControlSize(CPSmallControlSize),
        miniIdentifier = _CPControlIdentifierForControlSize(CPMiniControlSize);

    // Horizontal Knob Sizes
    var prefix = _CPScrollerClassName + _CPScrollerKnobIdentifier + _CPScrollerHorizontalIdentifier;
    
    _CPScrollerPartSizes[prefix + regularIdentifier]    = [_CGSizeMake(9.0, _CPScrollerWidths[CPRegularControlSize]), _CGSizeMake(1.0, _CPScrollerWidths[CPRegularControlSize]), _CGSizeMake(9.0, _CPScrollerWidths[CPRegularControlSize])];
    _CPScrollerPartSizes[prefix + smallIdentifier]      = [_CGSizeMake(6.0, _CPScrollerWidths[CPSmallControlSize]), _CGSizeMake(1.0, _CPScrollerWidths[CPSmallControlSize]), _CGSizeMake(6.0, _CPScrollerWidths[CPSmallControlSize])];
    _CPScrollerPartSizes[prefix + miniIdentifier]       = [_CGSizeMake(6.0, _CPScrollerWidths[CPMiniControlSize]), _CGSizeMake(1.0, _CPScrollerWidths[CPMiniControlSize]), _CGSizeMake(6.0, _CPScrollerWidths[CPMiniControlSize])];
    
    // Vertical Knob Sizes
    var prefix = _CPScrollerClassName + _CPScrollerKnobIdentifier + _CPScrollerVerticalIdentifier;
    
    _CPScrollerPartSizes[prefix + regularIdentifier]    = [_CGSizeMake(_CPScrollerWidths[CPRegularControlSize], 9.0), _CGSizeMake(_CPScrollerWidths[CPRegularControlSize], 1.0), _CGSizeMake(_CPScrollerWidths[CPRegularControlSize], 9.0)];
    _CPScrollerPartSizes[prefix + smallIdentifier]      = [_CGSizeMake(_CPScrollerWidths[CPSmallControlSize], 6.0), _CGSizeMake(_CPScrollerWidths[CPSmallControlSize], 1.0), _CGSizeMake(_CPScrollerWidths[CPSmallControlSize], 6.0)];
    _CPScrollerPartSizes[prefix + miniIdentifier]       = [_CGSizeMake(_CPScrollerWidths[CPMiniControlSize], 6.0), _CGSizeMake(_CPScrollerWidths[CPMiniControlSize], 1.0), _CGSizeMake(_CPScrollerWidths[CPMiniControlSize], 6.0)];
    
    // Horizontal Knob Slot Sizes
    var prefix = _CPScrollerClassName + _CPScrollerKnobSlotIdentifier + _CPScrollerHorizontalIdentifier;
    
    _CPScrollerPartSizes[prefix + regularIdentifier]    = _CGSizeMake(1.0, _CPScrollerWidths[CPRegularControlSize]);
    _CPScrollerPartSizes[prefix + smallIdentifier]      = _CGSizeMake(1.0, _CPScrollerWidths[CPSmallControlSize]);
    _CPScrollerPartSizes[prefix + miniIdentifier]       = _CGSizeMake(1.0, _CPScrollerWidths[CPMiniControlSize]);

    // Vertical Knob Slot Sizes
    var prefix = _CPScrollerClassName + _CPScrollerKnobSlotIdentifier + _CPScrollerVerticalIdentifier;
    
    _CPScrollerPartSizes[prefix + regularIdentifier]    = _CGSizeMake(_CPScrollerWidths[CPRegularControlSize], 1.0);
    _CPScrollerPartSizes[prefix + smallIdentifier]      = _CGSizeMake(_CPScrollerWidths[CPSmallControlSize], 1.0);
    _CPScrollerPartSizes[prefix + miniIdentifier]       = _CGSizeMake(_CPScrollerWidths[CPMiniControlSize], 1.0);
    
    // Horizontal Decrement Arrows Sizes
    var prefix = _CPScrollerClassName + _CPScrollerDecrementArrowIdentifier + _CPScrollerHorizontalIdentifier;
    
    _CPScrollerPartSizes[prefix + regularIdentifier]                                    = _CGSizeMake(_CPScrollerArrowHeights[CPRegularControlSize], _CPScrollerWidths[CPRegularControlSize]);
    _CPScrollerPartSizes[prefix + regularIdentifier + _CPScrollerHighlightedIdentifier] = _CGSizeMake(_CPScrollerArrowHeights[CPRegularControlSize], _CPScrollerWidths[CPRegularControlSize]);
    _CPScrollerPartSizes[prefix + smallIdentifier]                                      = _CGSizeMake(_CPScrollerArrowHeights[CPSmallControlSize] , _CPScrollerWidths[CPSmallControlSize]);
    _CPScrollerPartSizes[prefix + smallIdentifier + _CPScrollerHighlightedIdentifier]   = _CGSizeMake(_CPScrollerArrowHeights[CPSmallControlSize] , _CPScrollerWidths[CPSmallControlSize]);
    _CPScrollerPartSizes[prefix + miniIdentifier]                                       = _CGSizeMake(_CPScrollerArrowHeights[CPMiniControlSize], _CPScrollerWidths[CPMiniControlSize]);
    _CPScrollerPartSizes[prefix + miniIdentifier + _CPScrollerHighlightedIdentifier]    = _CGSizeMake(_CPScrollerArrowHeights[CPMiniControlSize], _CPScrollerWidths[CPMiniControlSize]);

    // Vertical Decrement Arrows Sizes
    var prefix = _CPScrollerClassName + _CPScrollerDecrementArrowIdentifier + _CPScrollerVerticalIdentifier;
    
    _CPScrollerPartSizes[prefix + regularIdentifier]                                    = _CGSizeMake(_CPScrollerWidths[CPRegularControlSize], _CPScrollerArrowHeights[CPRegularControlSize]);
    _CPScrollerPartSizes[prefix + regularIdentifier + _CPScrollerHighlightedIdentifier] = _CGSizeMake(_CPScrollerWidths[CPRegularControlSize], _CPScrollerArrowHeights[CPRegularControlSize]);
    _CPScrollerPartSizes[prefix + smallIdentifier]                                      = _CGSizeMake(_CPScrollerWidths[CPSmallControlSize], _CPScrollerArrowHeights[CPSmallControlSize]);
    _CPScrollerPartSizes[prefix + smallIdentifier + _CPScrollerHighlightedIdentifier]   = _CGSizeMake(_CPScrollerWidths[CPSmallControlSize], _CPScrollerArrowHeights[CPSmallControlSize]);
    _CPScrollerPartSizes[prefix + miniIdentifier]                                       = _CGSizeMake(_CPScrollerWidths[CPMiniControlSize], _CPScrollerArrowHeights[CPMiniControlSize]);
    _CPScrollerPartSizes[prefix + miniIdentifier + _CPScrollerHighlightedIdentifier]    = _CGSizeMake(_CPScrollerWidths[CPMiniControlSize], _CPScrollerArrowHeights[CPMiniControlSize]);

    // Horizontal Increment Arrows Sizes
    var prefix = _CPScrollerClassName + _CPScrollerIncrementArrowIdentifier + _CPScrollerHorizontalIdentifier;
    
    _CPScrollerPartSizes[prefix + regularIdentifier]                                    = _CGSizeMake(_CPScrollerArrowHeights[CPRegularControlSize], _CPScrollerWidths[CPRegularControlSize]);
    _CPScrollerPartSizes[prefix + regularIdentifier + _CPScrollerHighlightedIdentifier] = _CGSizeMake(_CPScrollerArrowHeights[CPRegularControlSize], _CPScrollerWidths[CPRegularControlSize]);
    _CPScrollerPartSizes[prefix + smallIdentifier]                                      = _CGSizeMake(_CPScrollerArrowHeights[CPSmallControlSize], _CPScrollerWidths[CPSmallControlSize]);
    _CPScrollerPartSizes[prefix + smallIdentifier + _CPScrollerHighlightedIdentifier]   = _CGSizeMake(_CPScrollerArrowHeights[CPSmallControlSize], _CPScrollerWidths[CPSmallControlSize]);
    _CPScrollerPartSizes[prefix + miniIdentifier]                                       = _CGSizeMake(_CPScrollerArrowHeights[CPMiniControlSize], _CPScrollerWidths[CPMiniControlSize]);
    _CPScrollerPartSizes[prefix + miniIdentifier + _CPScrollerHighlightedIdentifier]    = _CGSizeMake(_CPScrollerArrowHeights[CPMiniControlSize], _CPScrollerWidths[CPMiniControlSize]);

    // Vertical Increment Arrows Sizes
    var prefix = _CPScrollerClassName + _CPScrollerIncrementArrowIdentifier + _CPScrollerVerticalIdentifier;
    
    _CPScrollerPartSizes[prefix + regularIdentifier]                                    = _CGSizeMake(_CPScrollerWidths[CPRegularControlSize], _CPScrollerArrowHeights[CPRegularControlSize]);
    _CPScrollerPartSizes[prefix + regularIdentifier + _CPScrollerHighlightedIdentifier] = _CGSizeMake(_CPScrollerWidths[CPRegularControlSize], _CPScrollerArrowHeights[CPRegularControlSize]);
    _CPScrollerPartSizes[prefix + smallIdentifier]                                      = _CGSizeMake(_CPScrollerWidths[CPSmallControlSize], _CPScrollerArrowHeights[CPSmallControlSize]);
    _CPScrollerPartSizes[prefix + smallIdentifier + _CPScrollerHighlightedIdentifier]   = _CGSizeMake(_CPScrollerWidths[CPSmallControlSize], _CPScrollerArrowHeights[CPSmallControlSize]);
    _CPScrollerPartSizes[prefix + miniIdentifier]                                       = _CGSizeMake(_CPScrollerWidths[CPMiniControlSize], _CPScrollerArrowHeights[CPMiniControlSize]);
    _CPScrollerPartSizes[prefix + miniIdentifier + _CPScrollerHighlightedIdentifier]    = _CGSizeMake(_CPScrollerWidths[CPMiniControlSize], _CPScrollerArrowHeights[CPMiniControlSize]);
}

// Calculating Layout

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _controlSize = CPRegularControlSize;
        _partRects = [];

        [self setFloatValue:0.0 knobProportion:1.0];
        
        _isHorizontal = CPRectGetWidth(aFrame) > CPRectGetHeight(aFrame);
        
        _hitPart = CPScrollerNoPart;
        
        [self checkSpaceForParts];
        [self drawParts];
        
        [self layoutSubviews];
    }

    return self;
}

// Determining CPScroller Size
/*!
    Returns the CPScroller's width for a CPRegularControlSize.
*/
+ (float)scrollerWidth
{
    return [self scrollerWidthForControlSize:CPRegularControlSize];
}

/*!
    Returns the width of a CPScroller for the specified CPControlSize.
    @param aControlSize the size of a controller to return the width for
*/
+ (float)scrollerWidthForControlSize:(CPControlSize)aControlSize
{
    return _CPScrollerWidths[aControlSize];
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

    [self drawKnobSlot];
    [self drawKnob];
    [self drawArrow:CPScrollerDecrementArrow highlight:NO];
    [self drawArrow:CPScrollerIncrementArrow highlight:NO];
    
    [self layoutSubviews];
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
    
    [self checkSpaceForParts];
    [self layoutSubviews];
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
    if (_knobProportion == 1.0)
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

    var width = _CGRectGetWidth(bounds),
        height = _CGRectGetHeight(bounds),
        usableArrowHeight = _CPScrollerArrowUsableHeights[_controlSize],
        slotWidth = (_isHorizontal ? width : height) - 2.0 * usableArrowHeight,
        knobWidth = MAX(_CPScrollerKnobMinimumHeights[_controlSize], (slotWidth * _knobProportion));
    
    _usableParts = CPAllScrollerParts;
    
    var arrowHeight = _CPScrollerArrowHeights[_controlSize],
        knobLocation = usableArrowHeight + (slotWidth - knobWidth) * [self floatValue];
    
    // At this point we know we're going to need arrows.
    if (_isHorizontal)
    {
        // ASSERT(_CPScrollerWidths[_controlSize] == height)
        
        _partRects[CPScrollerDecrementPage] = _CGRectMake(usableArrowHeight, 0.0, knobLocation - usableArrowHeight, height);
        _partRects[CPScrollerKnob]          = _CGRectMake(knobLocation, 0.0, knobWidth, _CPScrollerWidths[_controlSize]);
        _partRects[CPScrollerIncrementPage] = _CGRectMake(knobLocation + knobWidth, 0.0, width - (knobLocation + knobWidth) - usableArrowHeight, height);
        _partRects[CPScrollerKnobSlot]      = _CGRectMake(usableArrowHeight, 0.0, slotWidth, height);
        _partRects[CPScrollerDecrementLine] = _CGRectMake(0.0, 0.0, arrowHeight, height);
        _partRects[CPScrollerIncrementLine] = _CGRectMake(width - _CPScrollerArrowHeights[_controlSize], 0.0, arrowHeight, height);
    }
    else
    {
        // ASSERT(_CPScrollerWidths[_controlSize] == width)
        
        _partRects[CPScrollerDecrementPage] = _CGRectMake(0.0, usableArrowHeight, width, knobLocation - usableArrowHeight);
        _partRects[CPScrollerKnob]          = _CGRectMake(0.0, knobLocation, _CPScrollerWidths[_controlSize], knobWidth);
        _partRects[CPScrollerIncrementPage] = _CGRectMake(0.0, knobLocation + knobWidth, width, height - (knobLocation + knobWidth) - usableArrowHeight);
        _partRects[CPScrollerKnobSlot]      = _CGRectMake(0.0, usableArrowHeight, width, slotWidth);
        _partRects[CPScrollerDecrementLine] = _CGRectMake(0.0, 0.0, width, arrowHeight);
        _partRects[CPScrollerIncrementLine] = _CGRectMake(0.0, height - _CPScrollerArrowHeights[_controlSize], width, arrowHeight);    
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
    var identifier = (anArrow == CPScrollerDecrementArrow ? _CPScrollerDecrementArrowIdentifier : _CPScrollerIncrementArrowIdentifier),
        arrowView = (anArrow == CPScrollerDecrementArrow ? _decrementArrowView : _incrementArrowView);

    [arrowView setBackgroundColor:_CPControlColorWithPatternImage(
        _CPScrollerPartSizes,
        _CPScrollerClassName,
        identifier,
        _isHorizontal ? _CPScrollerHorizontalIdentifier : _CPScrollerVerticalIdentifier,
        _CPControlIdentifierForControlSize(_controlSize),
        shouldHighlight ? _CPScrollerHighlightedIdentifier : @"")];
}

/*!
    Draws the knob
*/
- (void)drawKnob
{
    [_knobView setBackgroundColor:_CPControlThreePartImagePattern(
        !_isHorizontal,
        _CPScrollerPartSizes,
        _CPScrollerClassName,
        _CPScrollerKnobIdentifier,
        _isHorizontal ? _CPScrollerHorizontalIdentifier : _CPScrollerVerticalIdentifier,
        _CPControlIdentifierForControlSize(_controlSize))];
}

/*!
    Draws the knob's slot
*/
- (void)drawKnobSlot
{
    [_knobSlotView setBackgroundColor:_CPControlColorWithPatternImage(
        _CPScrollerPartSizes,
        _CPScrollerClassName,
        _CPScrollerKnobSlotIdentifier,
        _isHorizontal ? _CPScrollerHorizontalIdentifier : _CPScrollerVerticalIdentifier,
        _CPControlIdentifierForControlSize(_controlSize))];
}

/*!
    Caches images for the scroll arrow and knob.
*/
- (void)drawParts
{
    _knobSlotView = [[CPView alloc] initWithFrame:_CGRectMakeZero()];
    
    [_knobSlotView setHitTests:NO];
    
    [self addSubview:_knobSlotView];
    
    [self drawKnobSlot];
    
    _knobView = [[CPView alloc] initWithFrame:_CGRectMakeZero()];
    
    [_knobView setHitTests:NO];
    
    [self addSubview:_knobView];

    [self drawKnob];
    
    _decrementArrowView = [[CPView alloc] initWithFrame:_CGRectMakeZero()];
    
    [_decrementArrowView setHitTests:NO];
    
    [self addSubview:_decrementArrowView];
    
    [self drawArrow:CPScrollerDecrementArrow highlight:NO];

    _incrementArrowView = [[CPView alloc] initWithFrame:_CGRectMakeZero()];
    
    [_incrementArrowView setHitTests:NO];
    
    [self addSubview:_incrementArrowView];
    
    [self drawArrow:CPScrollerIncrementArrow highlight:NO];
}

/*!
    Draws the scroller's arrow with a possible highlight,
    if the user's mouse is over it.
    @param shouldHighlight <code>YES</code> will draw the
    arrow highlighted if the mouse is hovering over it.
*/
- (void)highlight:(BOOL)shouldHighlight
{
    if (_trackingPart == CPScrollerDecrementLine)
        [self drawArrow:CPScrollerDecrementArrow highlight:shouldHighlight];
    
    else if (_trackingPart == CPScrollerIncrementLine)
        [self drawArrow:CPScrollerIncrementArrow highlight:shouldHighlight];
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
    
    if (type == CPLeftMouseUp)
    {
        _hitPart = CPScrollerNoPart;
        
        return;
    }
    
    if (type == CPLeftMouseDown)
    {
        _trackingFloatValue = [self floatValue];
        _trackingStartPoint = [self convertPoint:[anEvent locationInWindow] fromView:nil];
    }
    
    else if (type == CPLeftMouseDragged)
    {
        var knobRect = [self rectForPart:CPScrollerKnob],
            knobSlotRect = [self rectForPart:CPScrollerKnobSlot],
            remainder = _isHorizontal ? (_CGRectGetWidth(knobSlotRect) - _CGRectGetWidth(knobRect)) : (_CGRectGetHeight(knobSlotRect) - _CGRectGetHeight(knobRect));
            
        if (remainder <= 0)
            [self setFloatValue:0.0];
        else
        {
            var location = [self convertPoint:[anEvent locationInWindow] fromView:nil];
                delta = _isHorizontal ? location.x - _trackingStartPoint.x : location.y - _trackingStartPoint.y;

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

    if (type == CPLeftMouseUp)
    {
        [self highlight:NO];
        [CPEvent stopPeriodicEvents];
        
        _hitPart = CPScrollerNoPart;
        
        return;
    }
    
    if (type == CPLeftMouseDown)
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
                    knobWidth = _isHorizontal ? _CGRectGetWidth(knobRect) : _CGRectGetHeight(knobRect),
                    knobSlotRect = [self rectForPart:CPScrollerKnobSlot],
                    remainder = (_isHorizontal ? _CGRectGetWidth(knobSlotRect) : _CGRectGetHeight(knobSlotRect)) - knobWidth;

                [self setFloatValue:((_isHorizontal ? _trackingStartPoint.x - _CGRectGetMinX(knobSlotRect) : _trackingStartPoint.y - _CGRectGetMinY(knobSlotRect)) - knobWidth / 2.0) / remainder];
                
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
    
    else if (type == CPLeftMouseDragged)
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
    
    [self checkSpaceForParts];
    
    var frame = [self frame],
        isHorizontal = CPRectGetWidth(frame) > CPRectGetHeight(frame);
    
    if (_isHorizontal != isHorizontal)
    {
        _isHorizontal = isHorizontal;
        
        [self drawParts];
    }
    
    [self layoutSubviews];
}

/*!
    Lays out the scrollers subviews
*/
- (void)layoutSubviews
{
    [_knobSlotView setFrame:[self rectForPart:CPScrollerKnobSlot]];

    var usableParts = [self usableParts],
        hidden = !(usableParts == CPAllScrollerParts);
    
    if (hidden != [_knobView isHidden])
    {
        [_knobView setHidden:hidden];    
        [_decrementArrowView setHidden:hidden];
        [_incrementArrowView setHidden:hidden];
    }
    
    if (!hidden)
    {
        [_knobView setFrame:[self rectForPart:CPScrollerKnob]];    
        [_decrementArrowView setFrame:[self rectForPart:CPScrollerDecrementLine]];
        [_incrementArrowView setFrame:[self rectForPart:CPScrollerIncrementLine]];
    }
}

- (void)mouseDown:(CPEvent)anEvent
{
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

// FIXME: This is a result of the "dumb" code that just makes things transparent when disabled.
- (void)setEnabled:(BOOL)shouldBeEnabled
{
}

@end
