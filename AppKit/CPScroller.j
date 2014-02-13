/*
 * CPScroller.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
 *
 * Modified to match Lion style by Antoine Mercadal 2011
 * <antoine.mercadal@archipelproject.org>
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

#include "../Foundation/Foundation.h"

@import "CPAnimation.j"
@import "CPControl.j"
@import "CPWindow_Constants.j"
@import "CPViewAnimation.j"

@global CPApp

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

/*!
    @ingroup appkit
    @class CPScroller
*/

var PARTS_ARRANGEMENT   = [CPScrollerKnobSlot, CPScrollerDecrementLine, CPScrollerIncrementLine, CPScrollerKnob],
    NAMES_FOR_PARTS     = {},
    PARTS_FOR_NAMES     = {};

var _CACHED_THEME_SCROLLER = nil; // This is used by the class methods to pull the theme attributes.

NAMES_FOR_PARTS[CPScrollerDecrementLine]    = @"decrement-line";
NAMES_FOR_PARTS[CPScrollerIncrementLine]    = @"increment-line";
NAMES_FOR_PARTS[CPScrollerKnobSlot]         = @"knob-slot";
NAMES_FOR_PARTS[CPScrollerKnob]             = @"knob";


CPScrollerStyleLegacy           = 0;
CPScrollerStyleOverlay          = 1;

CPScrollerKnobStyleDefault      = 0;
CPScrollerKnobStyleDark         = 1;
CPScrollerKnobStyleLight        = 2;

CPThemeStateScrollViewLegacy    = CPThemeState("scroller-style-legacy");
CPThemeStateScrollerKnobLight   = CPThemeState("scroller-knob-light");
CPThemeStateScrollerKnobDark    = CPThemeState("scroller-knob-dark");

@implementation CPScroller : CPControl
{
    CPControlSize           _controlSize;
    CPUsableScrollerParts   _usableParts;
    CPArray                 _partRects;

    BOOL                    _isVertical @accessors(readonly, getter=isVertical);
    float                   _knobProportion;

    CPScrollerPart          _hitPart;

    CPScrollerPart          _trackingPart;
    float                   _trackingFloatValue;
    CGPoint                 _trackingStartPoint;

    CPViewAnimation         _animationScroller;

    BOOL                    _allowFadingOut @accessors(getter=allowFadingOut);
    int                     _style;
    CPTimer                 _timerFadeOut;
    BOOL                    _isMouseOver;
}


#pragma mark -
#pragma mark Class methods

+ (CPString)defaultThemeClass
{
    return "scroller";
}

+ (CPDictionary)themeAttributes
{
    return @{
            @"scroller-width": 7.0,
            @"knob-slot-color": [CPNull null],
            @"decrement-line-color": [CPNull null],
            @"increment-line-color": [CPNull null],
            @"knob-color": [CPNull null],
            @"decrement-line-size": CGSizeMakeZero(),
            @"increment-line-size": CGSizeMakeZero(),
            @"track-inset": CGInsetMakeZero(),
            @"knob-inset": CGInsetMakeZero(),
            @"minimum-knob-length": 21.0,
            @"track-border-overlay": 9.0
        };
}

+ (float)scrollerWidth
{
    return [self scrollerWidthInStyle:CPScrollerStyleLegacy];
}

/*!
    Returns the CPScroller's width for a CPRegularControlSize.
*/
+ (float)scrollerWidthInStyle:(int)aStyle
{
    if (!_CACHED_THEME_SCROLLER)
        _CACHED_THEME_SCROLLER = [[self alloc] init];

    if (aStyle == CPScrollerStyleLegacy)
        return [_CACHED_THEME_SCROLLER valueForThemeAttribute:@"scroller-width" inState:CPThemeStateScrollViewLegacy];

    return [_CACHED_THEME_SCROLLER currentValueForThemeAttribute:@"scroller-width"];
}

/*!
    Returns the CPScroller's overlay value.
*/
+ (float)scrollerOverlay
{
    if (!_CACHED_THEME_SCROLLER)
        _CACHED_THEME_SCROLLER = [[self alloc] init];

    return [_CACHED_THEME_SCROLLER currentValueForThemeAttribute:@"track-border-overlay"];
}

/*!
    Returns the width of a CPScroller for the specified CPControlSize.
    @param aControlSize the size of a controller to return the width for
*/
+ (float)scrollerWidthForControlSize:(CPControlSize)aControlSize
{
    return [self scrollerWidth];
}


#pragma mark -
#pragma mark Initialization

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _controlSize = CPRegularControlSize;
        _partRects = [];

        [self setFloatValue:0.0];
        [self setKnobProportion:1.0];

        _hitPart = CPScrollerNoPart;
        _allowFadingOut = YES;
        _isMouseOver = NO;
        _style = CPScrollerStyleOverlay;

        var paramAnimFadeOut = @{
                CPViewAnimationTargetKey: self,
                CPViewAnimationEffectKey: CPViewAnimationFadeOutEffect,
            };

        _animationScroller = [[CPViewAnimation alloc] initWithDuration:0.2 animationCurve:CPAnimationEaseInOut];
        [_animationScroller setViewAnimations:[paramAnimFadeOut]];
        [_animationScroller setDelegate:self];
        [self setAlphaValue:0.0];

        // We have to choose an orientation. If for some bizarre reason width === height,
        // punt and choose vertical.
        [self _setIsVertical:CGRectGetHeight(aFrame) >= CGRectGetWidth(aFrame)];
    }

    return self;
}


#pragma mark -
#pragma mark Getters / Setters

/*!
    Returns the scroller's style
*/
- (void)style
{
    return _style;
}

/*!
    Set the scroller's control size
    @param aStyle the scroller style: CPScrollerStyleLegacy or CPScrollerStyleOverlay
*/
- (void)setStyle:(id)aStyle
{
    if (_style != nil && _style === aStyle)
        return;

    _style = aStyle;

    if (_style === CPScrollerStyleLegacy)
    {
        [self fadeIn];
        [self setThemeState:CPThemeStateScrollViewLegacy];
    }
    else
    {
        _allowFadingOut = YES;
        [self unsetThemeState:CPThemeStateScrollViewLegacy];
    }

    //[self _adjustScrollerSize];
}

- (void)setObjectValue:(id)aValue
{
    [super setObjectValue:MIN(1.0, MAX(0.0, +aValue))];
}

/*!
    Returns the scroller's control size
*/
- (CPControlSize)controlSize
{
    return _controlSize;
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
    Return's the knob's proportion
*/
- (float)knobProportion
{
    return _knobProportion;
}

/*!
    Set the knob's proportion
    @param aProportion the desired proportion
*/
- (void)setKnobProportion:(float)aProportion
{
    if (!_IS_NUMERIC(aProportion))
        [CPException raise:CPInvalidArgumentException reason:"aProportion must be numeric"];

    _knobProportion = MIN(1.0, MAX(0.0001, aProportion));

    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
}


#pragma mark -
#pragma mark Privates

/*! @ignore */
- (void)_adjustScrollerSize
{
    var frame = [self frame],
        scrollerWidth = [self currentValueForThemeAttribute:@"scroller-width"];

    if ([self isVertical] && CGRectGetWidth(frame) !== scrollerWidth)
        frame.size.width = scrollerWidth;

    if (![self isVertical] && CGRectGetHeight(frame) !== scrollerWidth)
        frame.size.height = scrollerWidth;

    [self setFrame:frame];
}

/*! @ignore */
- (void)_performFadeOut:(CPTimer)aTimer
{
    [self fadeOut];
    _timerFadeOut = nil;
}


#pragma mark -
#pragma mark Utilities

- (CGRect)rectForPart:(CPScrollerPart)aPart
{
    if (aPart == CPScrollerNoPart)
        return CGRectMakeZero();

    return _partRects[aPart];
}

/*!
    Returns the part of the scroller that would be hit by \c aPoint.
    @param aPoint the simulated point hit
    @return the part of the scroller that intersects the point
*/
- (CPScrollerPart)testPart:(CGPoint)aPoint
{
    aPoint = [self convertPoint:aPoint fromView:nil];

    // The ordering of these tests is important.  We check the knob and
    // page rects first since they may overlap with the arrows.

    if (![self hasThemeState:CPThemeStateSelected])
        return CPScrollerNoPart;

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

        _partRects[CPScrollerDecrementPage] = CGRectMakeZero();
        _partRects[CPScrollerKnob]          = CGRectMakeZero();
        _partRects[CPScrollerIncrementPage] = CGRectMakeZero();
        _partRects[CPScrollerDecrementLine] = CGRectMakeZero();
        _partRects[CPScrollerIncrementLine] = CGRectMakeZero();

        // In this case, the slot is the entirety of the scroller.
        _partRects[CPScrollerKnobSlot] = CGRectMakeCopy(bounds);

        return;
    }

    // At this point we know we're going to need arrows.
    _usableParts = CPAllScrollerParts;

    var knobInset = [self currentValueForThemeAttribute:@"knob-inset"],
        trackInset = [self currentValueForThemeAttribute:@"track-inset"],
        width = CGRectGetWidth(bounds),
        height = CGRectGetHeight(bounds);

    if ([self isVertical])
    {
        var decrementLineSize = [self currentValueForThemeAttribute:"decrement-line-size"],
            incrementLineSize = [self currentValueForThemeAttribute:"increment-line-size"],
            effectiveDecrementLineHeight = decrementLineSize.height + trackInset.top,
            effectiveIncrementLineHeight = incrementLineSize.height + trackInset.bottom,
            slotSize = height - effectiveDecrementLineHeight - effectiveIncrementLineHeight,
            minimumKnobLength = [self currentValueForThemeAttribute:"minimum-knob-length"],
            knobWidth = width - knobInset.left - knobInset.right,
            knobHeight = MAX(minimumKnobLength, (slotSize * _knobProportion)),
            knobLocation = effectiveDecrementLineHeight + (slotSize - knobHeight) * [self floatValue];

        _partRects[CPScrollerDecrementPage] = CGRectMake(0.0, effectiveDecrementLineHeight, width, knobLocation - effectiveDecrementLineHeight);
        _partRects[CPScrollerKnob]          = CGRectMake(knobInset.left, knobLocation, knobWidth, knobHeight);
        _partRects[CPScrollerIncrementPage] = CGRectMake(0.0, knobLocation + knobHeight, width, height - (knobLocation + knobHeight) - effectiveIncrementLineHeight);
        _partRects[CPScrollerKnobSlot]      = CGRectMake(trackInset.left, effectiveDecrementLineHeight, width - trackInset.left - trackInset.right, slotSize);
        _partRects[CPScrollerDecrementLine] = CGRectMake(0.0, 0.0, decrementLineSize.width, decrementLineSize.height);
        _partRects[CPScrollerIncrementLine] = CGRectMake(0.0, height - incrementLineSize.height, incrementLineSize.width, incrementLineSize.height);

        if (height < knobHeight + decrementLineSize.height + incrementLineSize.height + trackInset.top + trackInset.bottom)
            _partRects[CPScrollerKnob] = CGRectMakeZero();

        if (height < decrementLineSize.height + incrementLineSize.height - 2)
        {
            _partRects[CPScrollerIncrementLine] = CGRectMakeZero();
            _partRects[CPScrollerDecrementLine] = CGRectMakeZero();
            _partRects[CPScrollerKnobSlot]      = CGRectMake(trackInset.left, 0,  width - trackInset.left - trackInset.right, height);
        }
    }
    else
    {
        var decrementLineSize = [self currentValueForThemeAttribute:"decrement-line-size"],
            incrementLineSize = [self currentValueForThemeAttribute:"increment-line-size"],
            effectiveDecrementLineWidth = decrementLineSize.width + trackInset.left,
            effectiveIncrementLineWidth = incrementLineSize.width + trackInset.right,
            slotSize = width - effectiveDecrementLineWidth - effectiveIncrementLineWidth,
            minimumKnobLength = [self currentValueForThemeAttribute:"minimum-knob-length"],
            knobWidth = MAX(minimumKnobLength, (slotSize * _knobProportion)),
            knobHeight = height - knobInset.top - knobInset.bottom,
            knobLocation = effectiveDecrementLineWidth + (slotSize - knobWidth) * [self floatValue];

        _partRects[CPScrollerDecrementPage] = CGRectMake(effectiveDecrementLineWidth, 0.0, knobLocation - effectiveDecrementLineWidth, height);
        _partRects[CPScrollerKnob]          = CGRectMake(knobLocation, knobInset.top, knobWidth, knobHeight);
        _partRects[CPScrollerIncrementPage] = CGRectMake(knobLocation + knobWidth, 0.0, width - (knobLocation + knobWidth) - effectiveIncrementLineWidth, height);
        _partRects[CPScrollerKnobSlot]      = CGRectMake(effectiveDecrementLineWidth, trackInset.top, slotSize, height - trackInset.top - trackInset.bottom);
        _partRects[CPScrollerDecrementLine] = CGRectMake(0.0, 0.0, decrementLineSize.width, decrementLineSize.height);
        _partRects[CPScrollerIncrementLine] = CGRectMake(width - incrementLineSize.width, 0.0, incrementLineSize.width, incrementLineSize.height);

        if (width < knobWidth + decrementLineSize.width + incrementLineSize.width + trackInset.left + trackInset.right)
            _partRects[CPScrollerKnob] = CGRectMakeZero();

        if (width < decrementLineSize.width + incrementLineSize.width - 2)
        {
            _partRects[CPScrollerIncrementLine] = CGRectMakeZero();
            _partRects[CPScrollerDecrementLine] = CGRectMakeZero();
            _partRects[CPScrollerKnobSlot]      = CGRectMake(0.0, 0.0,  width, slotSize);
        }
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

/*!
    Display the scroller
*/
- (void)fadeIn
{
    if (_isMouseOver && _knobProportion != 1.0)
        [self setThemeState:CPThemeStateSelected];

    if (_timerFadeOut)
        [_timerFadeOut invalidate];

    [self setAlphaValue:1.0];
}

/*!
    Start the fade out anination
*/
- (void)fadeOut
{
    if ([self hasThemeState:CPThemeStateScrollViewLegacy])
        return;

    [_animationScroller startAnimation];
}


#pragma mark -
#pragma mark  Drawing

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
    var view = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [view setHitTests:NO];

    return view;
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aName
{
    return _partRects[aName];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    var view = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [view setHitTests:NO];

    return view;
}

- (void)layoutSubviews
{
    [self _adjustScrollerSize];
    [self checkSpaceForParts];

    var index = 0,
        count = PARTS_ARRANGEMENT.length,
        view;

    for (; index < count; ++index)
    {
        var part = PARTS_ARRANGEMENT[index];

        if (index === 0)
            view = [self layoutEphemeralSubviewNamed:part positioned:CPWindowBelow relativeToEphemeralSubviewNamed:PARTS_ARRANGEMENT[index + 1]];
        else
            view = [self layoutEphemeralSubviewNamed:part positioned:CPWindowAbove relativeToEphemeralSubviewNamed:PARTS_ARRANGEMENT[index - 1]];

        if (view)
            [view setBackgroundColor:[self currentValueForThemeAttribute:NAMES_FOR_PARTS[part] + "-color"]];
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
            remainder = ![self isVertical] ? (CGRectGetWidth(knobSlotRect) - CGRectGetWidth(knobRect)) : (CGRectGetHeight(knobSlotRect) - CGRectGetHeight(knobRect));

        if (remainder <= 0)
            [self setFloatValue:0.0];
        else
        {
            var location = [self convertPoint:[anEvent locationInWindow] fromView:nil],
                delta = ![self isVertical] ? location.x - _trackingStartPoint.x : location.y - _trackingStartPoint.y;

            [self setFloatValue:_trackingFloatValue + delta / remainder];
        }
    }

    [CPApp setTarget:self selector:@selector(trackKnob:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];

    if (type === CPLeftMouseDragged)
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
            if (_trackingPart === CPScrollerDecrementLine)
                _hitPart = CPScrollerDecrementPage;

            else if (_trackingPart === CPScrollerIncrementLine)
                _hitPart = CPScrollerIncrementPage;

            else if (_trackingPart === CPScrollerDecrementPage || _trackingPart === CPScrollerIncrementPage)
            {
                var knobRect = [self rectForPart:CPScrollerKnob],
                    knobWidth = ![self isVertical] ? CGRectGetWidth(knobRect) : CGRectGetHeight(knobRect),
                    knobSlotRect = [self rectForPart:CPScrollerKnobSlot],
                    remainder = (![self isVertical] ? CGRectGetWidth(knobSlotRect) : CGRectGetHeight(knobSlotRect)) - knobWidth;

                [self setFloatValue:((![self isVertical] ? _trackingStartPoint.x - CGRectGetMinX(knobSlotRect) : _trackingStartPoint.y - CGRectGetMinY(knobSlotRect)) - knobWidth / 2.0) / remainder];

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

        if (_trackingPart === CPScrollerDecrementPage || _trackingPart === CPScrollerIncrementPage)
        {
            var hitPart = [self testPart:[anEvent locationInWindow]];

            if (hitPart === CPScrollerDecrementPage || hitPart === CPScrollerIncrementPage)
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

- (void)_setIsVertical:(BOOL)isVertical
{
    _isVertical = isVertical;

    if (_isVertical)
        [self setThemeState:CPThemeStateVertical];
    else
        [self unsetThemeState:CPThemeStateVertical];
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];

    [self checkSpaceForParts];
    [self setNeedsLayout];
}


#pragma mark -
#pragma mark Overrides

- (id)currentValueForThemeAttribute:(CPString)anAttributeName
{
    var themeState = _themeState;

    if (NAMES_FOR_PARTS[_hitPart] + "-color" !== anAttributeName)
        themeState = CPThemeState.subtractThemeStates(themeState, CPThemeStateHighlighted);

    return [self valueForThemeAttribute:anAttributeName inState:themeState];
}

- (void)mouseDown:(CPEvent)anEvent
{
    if (![self isEnabled])
        return;

    _hitPart = [self testPart:[anEvent locationInWindow]];

    switch (_hitPart)
    {
        case CPScrollerKnob:
            return [self trackKnob:anEvent];

        case CPScrollerDecrementLine:
        case CPScrollerIncrementLine:
        case CPScrollerDecrementPage:
        case CPScrollerIncrementPage:
            return [self trackScrollButtons:anEvent];
    }
}

- (void)mouseEntered:(CPEvent)anEvent
{
    [super mouseEntered:anEvent];

    if (_timerFadeOut)
        [_timerFadeOut invalidate];

    if (![self isEnabled])
        return;

    _allowFadingOut = NO;
    _isMouseOver = YES;

    if ([self alphaValue] > 0 && _knobProportion != 1.0)
        [self setThemeState:CPThemeStateSelected];
}

- (void)mouseExited:(CPEvent)anEvent
{
    [super mouseExited:anEvent];

    if ([self isHidden] || ![self isEnabled] || !_isMouseOver)
        return;

    _allowFadingOut = YES;
    _isMouseOver = NO;

    if (_timerFadeOut)
        [_timerFadeOut invalidate];

    _timerFadeOut = [CPTimer scheduledTimerWithTimeInterval:1.2 target:self selector:@selector(_performFadeOut:) userInfo:nil repeats:NO];
}


#pragma mark -
#pragma mark Delegates

- (void)animationDidEnd:(CPAnimation)animation
{
    [self unsetThemeState:CPThemeStateSelected];
}

@end

var CPScrollerControlSizeKey    = @"CPScrollerControlSize",
    CPScrollerIsVerticalKey     = @"CPScrollerIsVerticalKey",
    CPScrollerKnobProportionKey = @"CPScrollerKnobProportion",
    CPScrollerStyleKey          = @"CPScrollerStyleKey";

@implementation CPScroller (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _controlSize = CPRegularControlSize;
        if ([aCoder containsValueForKey:CPScrollerControlSizeKey])
            _controlSize = [aCoder decodeIntForKey:CPScrollerControlSizeKey];

        _knobProportion = 1.0;

        if ([aCoder containsValueForKey:CPScrollerKnobProportionKey])
            _knobProportion = [aCoder decodeFloatForKey:CPScrollerKnobProportionKey];

        _partRects = [];

        _hitPart = CPScrollerNoPart;

        _allowFadingOut = YES;
        _isMouseOver = NO;

        var paramAnimFadeOut = @{
                CPViewAnimationTargetKey: self,
                CPViewAnimationEffectKey: CPViewAnimationFadeOutEffect,
            };

        _animationScroller = [[CPViewAnimation alloc] initWithDuration:0.2 animationCurve:CPAnimationEaseInOut];
        [_animationScroller setViewAnimations:[paramAnimFadeOut]];
        [_animationScroller setDelegate:self];
        [self setAlphaValue:0.0];

        [self setStyle:[aCoder decodeIntForKey:CPScrollerStyleKey]];

        [self _setIsVertical:[aCoder decodeBoolForKey:CPScrollerIsVerticalKey]];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeInt:_controlSize forKey:CPScrollerControlSizeKey];
    [aCoder encodeInt:_isVertical forKey:CPScrollerIsVerticalKey];
    [aCoder encodeFloat:_knobProportion forKey:CPScrollerKnobProportionKey];
    [aCoder encodeInt:_style forKey:CPScrollerStyleKey];
}

@end

@implementation CPScroller (Deprecated)

/*!
    Sets the position and proportion of the knob.
    @param aValue the knob position (ranges from 0.0 to 1.0)
    @param aProportion the knob's proportion (ranges from 0.0 to 1.0)
*/
- (void)setFloatValue:(float)aValue knobProportion:(float)aProportion
{
    [self setFloatValue:aValue];
    [self setKnobProportion:aProportion];
}

@end
