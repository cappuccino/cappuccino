/*
 * CPSlider.j
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

@import "CPControl.j"
@import "CPWindow_Constants.j"


/*! SLIDER STATES */

CPLinearSlider      = 0;
CPCircularSlider    = 1;

/*!
    @ingroup appkit
*/

@implementation CPSlider : CPControl
{
    double          _minValue;
    double          _maxValue;
    double          _altIncrementValue;

    BOOL            _isVertical;

    CGSize          _dragOffset;
}

+ (CPString)defaultThemeClass
{
    return "slider";
}

+ (id)themeAttributes
{
    return @{
            @"knob-color": [CPNull null],
            @"knob-size": CGSizeMakeZero(),
            @"track-width": 0.0,
            @"track-color": [CPNull null],
        };
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _minValue = 0.0;
        _maxValue = 100.0;

        [self setObjectValue:50.0];

        [self setContinuous:YES];

        [self _recalculateIsVertical];
    }

    return self;
}

- (void)setMinValue:(float)aMinimumValue
{
    if (_minValue === aMinimumValue)
        return;

    _minValue = aMinimumValue;

    var doubleValue = [self doubleValue];

    if (doubleValue < _minValue)
        [self setDoubleValue:_minValue];

    // The relative position may have (did) change.
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (float)minValue
{
    return _minValue;
}

- (void)setMaxValue:(float)aMaximumValue
{
    if (_maxValue === aMaximumValue)
        return;

    _maxValue = aMaximumValue;

    var doubleValue = [self doubleValue];

    if (doubleValue > _maxValue)
        [self setDoubleValue:_maxValue];

    // The relative position may have (did) change.
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (float)maxValue
{
    return _maxValue;
}

- (void)setObjectValue:(id)aValue
{
    [super setObjectValue:MIN(MAX(aValue, _minValue), _maxValue)];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (void)setSliderType:(CPSliderType)aSliderType
{
    if (aSliderType === CPCircularSlider)
        [self setThemeState:CPThemeStateCircular];
    else
        [self unsetThemeState:CPThemeStateCircular];
}

- (CPSliderType)sliderType
{
    return [self hasThemeState:CPThemeStateCircular] ? CPCircularSlider : CPLinearSlider;
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    if ([self hasThemeState:CPThemeStateCircular])
    {
        var originalBounds = CGRectCreateCopy(bounds);

        bounds.size.width = MIN(bounds.size.width, bounds.size.height);
        bounds.size.height = bounds.size.width;

        if (bounds.size.width < originalBounds.size.width)
            bounds.origin.x += (originalBounds.size.width - bounds.size.width) / 2.0;
        else
            bounds.origin.y += (originalBounds.size.height - bounds.size.height) / 2.0;
    }
    else
    {
        var trackWidth = [self currentValueForThemeAttribute:@"track-width"];

        if (trackWidth <= 0)
            return CGRectMakeZero();

        if ([self isVertical])
        {
            bounds.origin.x = (CGRectGetWidth(bounds) - trackWidth) / 2.0;
            bounds.size.width = trackWidth;
        }
        else
        {
            bounds.origin.y = (CGRectGetHeight(bounds) - trackWidth) / 2.0;
            bounds.size.height = trackWidth;
        }
    }

    return bounds;
}

- (CGRect)knobRectForBounds:(CGRect)bounds
{
    var knobSize = [self currentValueForThemeAttribute:@"knob-size"];

    if (knobSize.width <= 0 || knobSize.height <= 0)
        return CGRectMakeZero();

    var knobRect = CGRectMake(0.0, 0.0, knobSize.width, knobSize.height),
        trackRect = [self trackRectForBounds:bounds];

    // No track, do our best to approximate a place for this thing.
    if (!trackRect || CGRectIsEmpty(trackRect))
        trackRect = bounds;

    if ([self hasThemeState:CPThemeStateCircular])
    {
        var angle = 3 * PI_2 - (1.0 - [self doubleValue] - _minValue) / (_maxValue - _minValue) * PI2,
            radius = CGRectGetWidth(trackRect) / 2.0 - 8.0;

        knobRect.origin.x = radius * COS(angle) + CGRectGetMidX(trackRect) - 3.0;
        knobRect.origin.y = radius * SIN(angle) + CGRectGetMidY(trackRect) - 2.0;
    }
    else if ([self isVertical])
    {
        knobRect.origin.x = CGRectGetMidX(trackRect) - knobSize.width / 2.0;
        knobRect.origin.y = ((_maxValue - [self doubleValue]) / (_maxValue - _minValue)) * (CGRectGetHeight(trackRect) - knobSize.height);
    }
    else
    {
        knobRect.origin.x = (([self doubleValue] - _minValue) / (_maxValue - _minValue)) * (CGRectGetWidth(trackRect) - knobSize.width);
        knobRect.origin.y = CGRectGetMidY(trackRect) - knobSize.height / 2.0;
    }

    return knobRect;
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "track-view")
        return [self trackRectForBounds:[self bounds]];

    else if (aName === "knob-view")
        return [self knobRectForBounds:[self bounds]];

    return [super rectForEphemeralSubviewNamed:aName];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "track-view" || aName === "knob-view")
    {
        var view = [[CPView alloc] init];

        [view setHitTests:NO];

        return view;
    }

    return [super createEphemeralSubviewNamed:aName];
}

- (void)setAltIncrementValue:(float)anAltIncrementValue
{
    _altIncrementValue = anAltIncrementValue;
}

- (float)altIncrementValue
{
    return _altIncrementValue;
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    [self _recalculateIsVertical];
}

- (void)_recalculateIsVertical
{
    // Recalculate isVertical.
    var bounds = [self bounds],
        width = CGRectGetWidth(bounds),
        height = CGRectGetHeight(bounds);

    _isVertical = width < height ? 1 : (width > height ? 0 : -1);

    if (_isVertical === 1)
        [self setThemeState:CPThemeStateVertical];
    else if (_isVertical === 0)
        [self unsetThemeState:CPThemeStateVertical];
}

- (int)isVertical
{
    return _isVertical;
}

- (void)layoutSubviews
{
    var trackView = [self layoutEphemeralSubviewNamed:@"track-view"
                                           positioned:CPWindowBelow
                      relativeToEphemeralSubviewNamed:@"knob-view"];

    if (trackView)
        [trackView setBackgroundColor:[self currentValueForThemeAttribute:@"track-color"]];

    var knobView = [self layoutEphemeralSubviewNamed:@"knob-view"
                                          positioned:CPWindowAbove
                     relativeToEphemeralSubviewNamed:@"track-view"];

    if (knobView)
        [knobView setBackgroundColor:[self currentValueForThemeAttribute:"knob-color"]];
}

- (BOOL)tracksMouseOutsideOfFrame
{
    return YES;
}

- (float)_valueAtPoint:(CGPoint)aPoint
{
    var bounds = [self bounds],
        knobRect = [self knobRectForBounds:bounds],
        trackRect = [self trackRectForBounds:bounds];

    if ([self hasThemeState:CPThemeStateCircular])
    {
        var knobWidth = CGRectGetWidth(knobRect);

        trackRect.origin.x += knobWidth / 2;
        trackRect.size.width -= knobWidth;

        var minValue = [self minValue],
            dx = aPoint.x - CGRectGetMidX(trackRect),
            dy = aPoint.y - CGRectGetMidY(trackRect);

        return MAX(0.0, MIN(1.0, 1.0 - (3 * PI_2 - ATAN2(dy, dx)) % PI2 / PI2)) * ([self maxValue] - minValue) + minValue;
    }
    else if ([self isVertical])
    {
        var knobHeight = CGRectGetHeight(knobRect);

        trackRect.origin.y += knobHeight / 2;
        trackRect.size.height -= knobHeight;

        var minValue = [self minValue];

        return MAX(0.0, MIN(1.0, (CGRectGetMaxY(trackRect) - aPoint.y) / CGRectGetHeight(trackRect))) * ([self maxValue] - minValue) + minValue;
    }
    else
    {
        var knobWidth = CGRectGetWidth(knobRect);

        trackRect.origin.x += knobWidth / 2;
        trackRect.size.width -= knobWidth;

        var minValue = [self minValue];

        return MAX(0.0, MIN(1.0, (aPoint.x - CGRectGetMinX(trackRect)) / CGRectGetWidth(trackRect))) * ([self maxValue] - minValue) + minValue;
    }
}

- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    var bounds = [self bounds],
        knobRect = [self knobRectForBounds:CGRectMakeCopy(bounds)];

    if (CGRectContainsPoint(knobRect, aPoint))
        _dragOffset = CGSizeMake(CGRectGetMidX(knobRect) - aPoint.x, CGRectGetMidY(knobRect) - aPoint.y);
    else
    {
        var trackRect = [self trackRectForBounds:bounds];

        if (trackRect && CGRectContainsPoint(trackRect, aPoint))
        {
            _dragOffset = CGSizeMakeZero();

            [self setObjectValue:[self _valueAtPoint:aPoint]];
        }

        else
            return NO;
    }

    [self setHighlighted:YES];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];

    return YES;
}

- (BOOL)continueTracking:(CGPoint)lastPoint at:(CGPoint)aPoint
{
    [self setObjectValue:[self _valueAtPoint:CGPointMake(aPoint.x + _dragOffset.width, aPoint.y + _dragOffset.height)]];

    return YES;
}

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    [self setHighlighted:NO];

    if ([_target respondsToSelector:@selector(sliderDidFinish:)])
        [_target sliderDidFinish:self];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (BOOL)isContinuous
{
    return (_sendActionOn & CPLeftMouseDraggedMask) !== 0;
}

/*!
    @ignore
    should we have _continuous?
*/
- (void)setContinuous:(BOOL)flag
{
    if (flag)
        _sendActionOn |= CPLeftMouseDraggedMask;
    else
        _sendActionOn &= ~CPLeftMouseDraggedMask;
}

- (void)takeValueFromKeyPath:(CPString)aKeyPath ofObjects:(CPArray)objects
{
    var count = objects.length,
        value = [objects[0] valueForKeyPath:aKeyPath];

    [self setObjectValue:value];

    while (count-- > 1)
        if (value !== ([objects[count] valueForKeyPath:aKeyPath]))
            return [self setFloatValue:1.0];
}

@end

var CPSliderMinValueKey             = "CPSliderMinValueKey",
    CPSliderMaxValueKey             = "CPSliderMaxValueKey",
    CPSliderAltIncrValueKey         = "CPSliderAltIncrValueKey";

@implementation CPSlider (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    _minValue = [aCoder decodeDoubleForKey:CPSliderMinValueKey];
    _maxValue = [aCoder decodeDoubleForKey:CPSliderMaxValueKey];

    self = [super initWithCoder:aCoder];

    if (self)
    {
        _altIncrementValue = [aCoder decodeDoubleForKey:CPSliderAltIncrValueKey];

        [self _recalculateIsVertical];

        [self setNeedsLayout];
        [self setNeedsDisplay:YES];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeDouble:_minValue forKey:CPSliderMinValueKey];
    [aCoder encodeDouble:_maxValue forKey:CPSliderMaxValueKey];
    [aCoder encodeDouble:_altIncrementValue forKey:CPSliderAltIncrValueKey];
}

@end

@implementation CPSlider (Deprecated)

- (id)value
{
    CPLog.warn("[CPSlider value] is deprecated, use doubleValue or objectValue instead.");

    return [self doubleValue];
}

- (void)setValue:(id)aValue
{
    CPLog.warn("[CPSlider setValue:] is deprecated, use setDoubleValue: or setObjectValue: instead.");

    [self setObjectValue:aValue];
}

@end
