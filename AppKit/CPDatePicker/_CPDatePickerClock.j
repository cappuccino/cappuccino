/*
* _CPDatePickerClock.j
* AppKit
*
* Created by Alexandre Wilhelm
* Copyright 2012 <alexandre.wilhelmfr@gmail.com>
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

@import "CPView.j"
@import "CPTextField.j"
@import "CPImage.j"
@import "CALayer.j"
@import <Foundation/CPKeyedArchiver.j>
@import <Foundation/CPKeyedUnarchiver.j>

@class _CPCibCustomResource
@class CPDatePicker
@class HandImageLayer
@class HoursLayer
@class HandLayer

@global CPHourMinuteSecondDatePickerElementFlag
@global CPTextFieldAndStepperDatePickerStyle
@global CPTextFieldDatePickerStyle

var RADIANS = Math.PI / 180;

@typedef _CPDatePickerClockHand
_CPDatePickerClockHours   = 1;
_CPDatePickerClockMinutes = 2;
_CPDatePickerClockSeconds = 3;

@implementation _CPDatePickerClock : CPControl
{
    BOOL                    _isEnabled;
    HoursLayer              _rootLayer;
    HandLayer               _hourHandLayer;
    HandLayer               _minuteHandLayer;
    HandLayer               _secondHandLayer;
    CALayer                 _middleHandLayer;
    CPDatePicker            _datePicker;
    CPTextField             _PMAMTextField;

    CALayer                 _currentHandLayer;
    _CPDatePickerClockHand  _currentHand;
    CPInteger               _currentRepresentedValue;
    float                   _currentValueShift;
    CPInteger               _numberOfUnits;
    BOOL                    _trackingHand;

    CPInteger               _representedHours;
    CPInteger               _representedMinutes;
    CPInteger               _representedSeconds;
    BOOL                    _representedHourIsPM;

    CPInteger                _datePickerElements         @accessors(getter=datePickerElements);
}


#pragma mark -
#pragma mark Init methods

- (id)initWithFrame:(CGRect)aFrame datePicker:(CPDatePicker)aDatePicker
{
    if (self = [super initWithFrame:aFrame])
    {
        _datePicker         = aDatePicker;
        _datePickerElements = [_datePicker datePickerElements];
        _trackingHand       = NO;

        _PMAMTextField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

        [_PMAMTextField setValue:[_datePicker valueForThemeAttribute:@"clock-font" inState:CPThemeStateNormal] forThemeAttribute:@"font" inState:CPThemeStateNormal];
        [_PMAMTextField setValue:[_datePicker valueForThemeAttribute:@"clock-text-color" inState:CPThemeStateNormal] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
        [_PMAMTextField setValue:[_datePicker valueForThemeAttribute:@"clock-text-shadow-color" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
        [_PMAMTextField setValue:[_datePicker valueForThemeAttribute:@"clock-text-shadow-offset" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];

        [_PMAMTextField setValue:[_datePicker valueForThemeAttribute:@"clock-font" inState:CPThemeStateDisabled] forThemeAttribute:@"font" inState:CPThemeStateDisabled];
        [_PMAMTextField setValue:[_datePicker valueForThemeAttribute:@"clock-text-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
        [_PMAMTextField setValue:[_datePicker valueForThemeAttribute:@"clock-text-shadow-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled];
        [_PMAMTextField setValue:[_datePicker valueForThemeAttribute:@"clock-text-shadow-offset" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled];

        [self addSubview:_PMAMTextField];

        var middleHandSize = [_datePicker valueForThemeAttribute:@"middle-hand-size"],
            minuteHandSize = [_datePicker valueForThemeAttribute:@"minute-hand-size"],
            hourHandSize   = [_datePicker valueForThemeAttribute:@"hour-hand-size"],
            secondHandSize = [_datePicker valueForThemeAttribute:@"second-hand-size"];

        // We use layer to make the rotation possible
        _hourHandLayer = [[HandLayer alloc] initWithSize:hourHandSize];
        [_hourHandLayer setBounds:CGRectMake(0, 0, aFrame.size.width, aFrame.size.height)];
        [_hourHandLayer setAnchorPoint:CGPointMakeZero()];
        [_hourHandLayer setPosition:CGPointMake(0.0, 0.0)];

        _minuteHandLayer = [[HandLayer alloc] initWithSize:minuteHandSize];
        [_minuteHandLayer setBounds:CGRectMake(0, 0, aFrame.size.width, aFrame.size.height)];
        [_minuteHandLayer setAnchorPoint:CGPointMakeZero()];
        [_minuteHandLayer setPosition:CGPointMake(0.0, 0.0)];

        _secondHandLayer = [[HandLayer alloc] initWithSize:secondHandSize];
        [_secondHandLayer setBounds:CGRectMake(0, 0, aFrame.size.width, aFrame.size.height)];
        [_secondHandLayer setAnchorPoint:CGPointMakeZero()];
        [_secondHandLayer setPosition:CGPointMake(0.0, 0.0)];

        _middleHandLayer = [[HandLayer alloc] initWithSize:middleHandSize];
        [_middleHandLayer setBounds:CGRectMake(0, 0, aFrame.size.width, aFrame.size.height)];
        [_middleHandLayer setAnchorPoint:CGPointMakeZero()];
        [_middleHandLayer setPosition:CGPointMake(0.0, 0.0)];

        _rootLayer = [[HoursLayer alloc] init];
        [self setWantsLayer:YES];
        [self setLayer:_rootLayer];

        [self _initHands];

        [_rootLayer addSublayer:_hourHandLayer];
        [_rootLayer addSublayer:_minuteHandLayer];

        if ([_datePicker valueForThemeAttribute:@"clock-second-hand-over"])
        {
            [_rootLayer addSublayer:_middleHandLayer];
            [_rootLayer addSublayer:_secondHandLayer];
        }
        else
        {
            [_rootLayer addSublayer:_secondHandLayer];
            [_rootLayer addSublayer:_middleHandLayer];
        }

        [_rootLayer setDrawsHours:[_datePicker valueForThemeAttribute:@"clock-draws-hours"]];
        [_rootLayer setNeedsDisplay];
    }

    return self;
}

- (void)_initHands
{
    var middleHandImage = [_datePicker currentValueForThemeAttribute:@"middle-hand-image"],
        hourHandImage   = [_datePicker currentValueForThemeAttribute:@"hour-hand-image"],
        minuteHandImage = [_datePicker currentValueForThemeAttribute:@"minute-hand-image"],
        secondHandImage = [_datePicker currentValueForThemeAttribute:@"second-hand-image"];

    // If hand images are true CPImage, we have to duplicate them to avoid
    // the multiple delegates bug when multiple clocks are displayed

    if ([middleHandImage isKindOfClass:[CPImage class]])
        middleHandImage = [middleHandImage duplicate];

    if ([hourHandImage isKindOfClass:[CPImage class]])
        hourHandImage = [hourHandImage duplicate];

    if ([minuteHandImage isKindOfClass:[CPImage class]])
        minuteHandImage = [minuteHandImage duplicate];

    if ([secondHandImage isKindOfClass:[CPImage class]])
        secondHandImage = [secondHandImage duplicate];

    [_middleHandLayer setImage:middleHandImage];
    [_hourHandLayer   setImage:hourHandImage];
    [_minuteHandLayer setImage:minuteHandImage];
    [_secondHandLayer setImage:secondHandImage];

    [_hourHandLayer   setNeedsDisplay];
    [_middleHandLayer setNeedsDisplay];
    [_secondHandLayer setNeedsDisplay];
    [_minuteHandLayer setNeedsDisplay];

    [_rootLayer setFont:[_datePicker currentValueForThemeAttribute:@"clock-hours-font"]];
    [_rootLayer setTextColor:[_datePicker currentValueForThemeAttribute:@"clock-hours-text-color"]];
    [_rootLayer setRadius:[_datePicker currentValueForThemeAttribute:@"clock-hours-radius"]];

    [_rootLayer setNeedsDisplay];
}

- (void)setDatePickerElements:(CPInteger)aDatePickerElements
{
    if (_datePickerElements === aDatePickerElements)
        return;

    _datePickerElements = aDatePickerElements;

    // Check if we have to display the hand second
    [_secondHandLayer setHidden:!((_datePickerElements & CPHourMinuteSecondDatePickerElementFlag) == CPHourMinuteSecondDatePickerElementFlag)];
}

#pragma mark Layout methods

- (void)layoutSubviews
{
    // While tracking a hand, we don't want the whole thing to be relayouted at each mouse movement
    if (_trackingHand)
        return;

    [self setBackgroundColor:[_datePicker currentValueForThemeAttribute:@"bezel-color-clock"]];

    var dateValue = [[_datePicker dateValue] copy];

    [dateValue _dateWithTimeZone:[_datePicker timeZone]];

    _representedHours    = dateValue.getHours();
    _representedMinutes  = dateValue.getMinutes();
    _representedSeconds  = dateValue.getSeconds();
    _representedHourIsPM = (_representedHours > 11);

    // Hours are expressed in 24 hours format, we need 12 hours format
    _representedHours -= (_representedHourIsPM ? 12 : 0);

    [self _updateHands];

    // FIXME: Workaround. Seems that CALayer doesn't redraw without an event
    [CALayer runLoopUpdateLayers];
}

- (void)_updateHands
{
    var bounds = [self bounds];

    [_PMAMTextField setStringValue:_representedHourIsPM ? @"PM" : @"AM"];
    [_PMAMTextField sizeToFit];
    [_PMAMTextField setFrameOrigin:CGPointMake(bounds.size.width / 2 - [_PMAMTextField frameSize].width / 2, bounds.size.height / 2 + 15)];

    [_hourHandLayer   setRotationRadians:(360 * (_representedHours   + _representedMinutes / 60) / 12) * RADIANS];
    [_minuteHandLayer setRotationRadians:(360 * (_representedMinutes + _representedSeconds / 60) / 60) * RADIANS];
    [_secondHandLayer setRotationRadians:(360 * _representedSeconds / 60) * RADIANS];

    [_hourHandLayer   setNeedsDisplay];
    [_minuteHandLayer setNeedsDisplay];
    [_secondHandLayer setNeedsDisplay];
//    [_middleHandLayer setNeedsDisplay];
}

#pragma mark Accessors

- (void)setEnabled:(BOOL)shouldEnable
{
    shouldEnable = !!shouldEnable;

    if (shouldEnable === _isEnabled)
        return;

    _isEnabled = shouldEnable;

    [self _initHands];
    [self setNeedsLayout];
}

#pragma mark Mouse actions

- (void)mouseDown:(CPEvent)anEvent
{
    if (!_isEnabled || ![_datePicker isCSSBased])
        return;

    var currentLocation = [self convertPoint:[anEvent locationInWindow] fromView:nil];

    if ([_secondHandLayer handIsHitAtPoint:currentLocation])
    {
        _currentHandLayer        = _secondHandLayer;
        _currentHand             = _CPDatePickerClockSeconds;
        _currentRepresentedValue = _representedSeconds;
        _currentValueShift       = 0;
        _numberOfUnits           = 60;
    }
    else if ([_minuteHandLayer handIsHitAtPoint:currentLocation])
    {
        _currentHandLayer        = _minuteHandLayer;
        _currentHand             = _CPDatePickerClockMinutes;
        _currentRepresentedValue = _representedMinutes;
        _currentValueShift       = _representedSeconds / 60;
        _numberOfUnits           = 60;
    }
    else if ([_hourHandLayer handIsHitAtPoint:currentLocation])
    {
        _currentHandLayer        = _hourHandLayer;
        _currentHand             = _CPDatePickerClockHours;
        _currentRepresentedValue = _representedHours;
        _currentValueShift       = _representedMinutes / 60;
        _numberOfUnits           = 12;
    }
    else
    {
        _currentHandLayer        = nil;
        _currentHand             = CPNotFound;
        _currentRepresentedValue = CPNotFound;
        _currentValueShift       = CPNotFound;
        _numberOfUnits           = CPNotFound;
    }

    if (_currentHandLayer)
        [self trackMouse:anEvent];
}

- (BOOL)tracksMouseOutsideOfFrame
{
    return YES;
}

- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    _trackingHand = YES;

    return YES;
}

- (BOOL)continueTracking:(CGPoint)lastPoint at:(CGPoint)aPoint
{
    var dx    = aPoint.x -_bounds.size.width / 2,
        dy    = _bounds.size.height / 2 - aPoint.y,
        angle = (PI_2 - ATAN2(dy,dx) + PI2) % PI2,
        value = ROUND(angle * _numberOfUnits / PI2 - _currentValueShift) % _numberOfUnits;

    if (value !== _currentRepresentedValue)
    {
        var movedForward  = (_currentRepresentedValue > _numberOfUnits * 3/4) && (value < _numberOfUnits / 4),
            movedBackward = (_currentRepresentedValue < _numberOfUnits / 4)   && (value > _numberOfUnits * 3/4),
            dateValue     = [[_datePicker dateValue] copy];

        [dateValue _dateWithTimeZone:[_datePicker timeZone]];

        switch (_currentHand)
        {
            case _CPDatePickerClockHours:

                if (movedForward || movedBackward)
                {
                    _representedHourIsPM = !_representedHourIsPM;

                    if (movedForward && !_representedHourIsPM)
                        // Day++
                        dateValue.setDate(dateValue.getDate() + 1);

                    else if (movedBackward && _representedHourIsPM)
                        // Day--
                        dateValue.setDate(dateValue.getDate() - 1);
                }

                dateValue.setHours(value + (_representedHourIsPM ? 12 : 0));
                break;

            case _CPDatePickerClockMinutes:

                if (movedForward)
                    // Hours++
                    dateValue.setHours(dateValue.getHours() + 1);

                else if (movedBackward)
                    // Hours--
                    dateValue.setHours(dateValue.getHours() - 1);

                dateValue.setMinutes(value);
                break;

            case _CPDatePickerClockSeconds:

                if (movedForward)
                    // Minutes++
                    dateValue.setMinutes(dateValue.getMinutes() + 1);

                else if (movedBackward)
                    // Minutes--
                    dateValue.setMinutes(dateValue.getMinutes() - 1);

                dateValue.setSeconds(value);
                break;
        }

#if PLATFORM(DOM)
        _datePicker._invokedByUserEvent = YES;
#endif
        [_datePicker _setDateValue:dateValue timeInterval:[_datePicker timeInterval]];
#if PLATFORM(DOM)
        _datePicker._invokedByUserEvent = NO;
#endif

        // We have to adapt represented values
        _representedHours    = dateValue.getHours();
        _representedMinutes  = dateValue.getMinutes();
        _representedSeconds  = dateValue.getSeconds();
        _representedHourIsPM = (_representedHours > 11);

        // Hours are expressed in 24 hours format, we need 12 hours format
        _representedHours -= (_representedHourIsPM ? 12 : 0);

        switch (_currentHand) {
            case _CPDatePickerClockHours:
                _currentRepresentedValue = _representedHours;
                break;

            case _CPDatePickerClockMinutes:
                _currentRepresentedValue = _representedMinutes;
                break;

            case _CPDatePickerClockSeconds:
                _currentRepresentedValue = _representedSeconds;
                break;
        }

        [self _updateHands];
    }

    return YES;
}

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    _trackingHand = NO;
}

@end

#pragma mark -

@implementation HandLayer : CALayer
{
    CPImage         _image;
    HandImageLayer  _imageLayer;
    float           _rotationRadians;
}

#pragma mark Init methods

- (id)initWithSize:(CGSize)aSize
{
    if (self = [super init])
    {
        _imageLayer = [HandImageLayer layer];
        _rotationRadians = 0;

        [_imageLayer setDelegate:self];
        [_imageLayer setBounds:CGRectMake(0.0, 0.0, aSize.width, aSize.height)];

        [self addSublayer:_imageLayer];
    }

    return self;
}


#pragma mark Setter Getter methods

/*!
    Set the bounds of the layer. The imageLayer will be at the center of this bounds.
*/
- (void)setBounds:(CGRect)aRect
{
    [super setBounds:aRect];

    [_imageLayer setPosition:CGPointMake(CGRectGetMidX(aRect), CGRectGetMidY(aRect))];
}

- (void)setImage:(CPImage)anImage
{
    if (_image === anImage)
        return;

    if ([anImage isKindOfClass:[_CPCibCustomResource class]])
        _image = [anImage imageFromCoder:nil];
    else
        _image = anImage;

    [_imageLayer setNeedsDisplay];
}

- (void)setRotationRadians:(float)radians
{
    if (_rotationRadians === radians)
        return;

    _rotationRadians = radians;

    [_imageLayer setAffineTransform:CGAffineTransformScale(
        CGAffineTransformMakeRotation(_rotationRadians),
        1.0, 1.0)];
}

- (void)imageDidLoad:(CPImage)anImage
{
    [_imageLayer setNeedsDisplay];
}

- (void)drawLayer:(CALayer)aLayer inContext:(CGContext)aContext
{
    if ([_image loadStatus] != CPImageLoadStatusCompleted)
        [_image setDelegate:self];
    else
        CGContextDrawImage(aContext, [aLayer bounds], _image);
}

- (BOOL)handIsHitAtPoint:(CGPoint)aPoint
{
    return (!_isHidden && [_imageLayer hitTest:aPoint] === _imageLayer);
}

- (void)setNeedsDisplay
{
    [super       setNeedsDisplay];
    [_imageLayer setNeedsDisplay];
}

@end

#pragma mark -

@implementation HandImageLayer : CALayer
{
    CGRect  _handBounds;
}

// We have to adapt hitTest so it only takes the hand into account (that's the top half of the image layer)
// We are also sure there's no sublayers
- (CALayer)hitTest:(CGPoint)aPoint
{
    if (_isHidden)
        return nil;

    var point = CGPointApplyAffineTransform(aPoint, _transformToLayer);

    return CGRectContainsPoint(_handBounds, point) ? self : nil;
}

- (void)setBounds:(CGRect)aBounds
{
    if (CGRectEqualToRect(_bounds, aBounds))
        return;

    _handBounds = CGRectMakeCopy(aBounds);

    _handBounds.size.height = _handBounds.size.height / 2;

    [super setBounds:aBounds];
}


@end

#pragma mark -

@implementation HoursLayer : CALayer
{
    BOOL    _drawsHours;

    CPFont  _font           @accessors(property=font);
    CPColor _textColor      @accessors(property=textColor);
    float   _radius         @accessors(property=radius);
}


- (id)init
{
    if (self = [super init])
    {
        _drawsHours = NO;
    }

    return self;
}

- (void)setDrawsHours:(BOOL)shouldDrawHours
{
    shouldDrawHours = !!shouldDrawHours;

    if (_drawsHours === shouldDrawHours)
        return;

    _drawsHours = shouldDrawHours;
    [self setNeedsDisplay];
}

- (void)drawInContext:(CGContext)aContext
{
    [super drawInContext:aContext];

    if (_drawsHours)
    {
        var bounds = [self bounds],
            centerX = bounds.size.width / 2,
            centerY = bounds.size.height / 2;

        CGContextSelectFont(aContext, _font);
        CGContextSetFillColor(aContext, _textColor);
        aContext.textBaseline = @"middle";
        aContext.textAlign = @"center";

        for (var i = 1, angle = 60.0, x, y; i < 13; i++, angle -= 30.0)
        {
            x = centerX + _radius * COS(angle * RADIANS);
            y = centerY - _radius * SIN(angle * RADIANS);

            aContext.fillText(i, x, y);
        }
    }
}

@end
