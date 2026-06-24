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

@import <Foundation/CPKeyedArchiver.j>
@import <Foundation/CPKeyedUnarchiver.j>
@import "CPView.j"
@import "CPTextField.j"
@import "CPImageView.j"
@import "CPImage.j"

@class _CPCibCustomResource
@class CPDatePicker

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
    
    // Pure DOM Views
    CPImageView             _hourHandView;
    CPImageView             _minuteHandView;
    CPImageView             _secondHandView;
    CPImageView             _middleHandView;
    
    CPArray                 _hourLabels;
    CPTextField             _PMAMTextField;

    CPDatePicker            _datePicker;

    CPView                  _currentHandView;
    _CPDatePickerClockHand  _currentHand;
    CPInteger               _currentRepresentedValue;
    float                   _currentValueShift;
    CPInteger               _numberOfUnits;
    BOOL                    _trackingHand;

    CPInteger               _representedHours;
    CPInteger               _representedMinutes;
    CPInteger               _representedSeconds;
    BOOL                    _representedHourIsPM;

    // Angles for Hit-Testing
    float                   _hourAngle;
    float                   _minuteAngle;
    float                   _secondAngle;

    CPInteger               _datePickerElements @accessors(getter=datePickerElements);
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
        _isEnabled          = YES;

        // 1. Initialize AM/PM Label
        _PMAMTextField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
        [_PMAMTextField setAlignment:CPCenterTextAlignment];
        [_PMAMTextField setVerticalAlignment:CPCenterVerticalTextAlignment];
        [self addSubview:_PMAMTextField];

        // 2. Initialize Number Labels (1 to 12)
        _hourLabels = [CPArray array];

        for (var i = 1; i <= 12; i++)
        {
            var label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
            [label setStringValue:String(i)];
            [label setAlignment:CPCenterTextAlignment];
            [label setVerticalAlignment:CPCenterVerticalTextAlignment];
            [self addSubview:label];
            [_hourLabels addObject:label];
        }

        // 3. Initialize Hand Views
        _hourHandView   = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
        _minuteHandView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
        _secondHandView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
        _middleHandView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];

        // Ensure images stretch accurately across the bounds of the image view
        [_hourHandView setImageScaling:CPImageScaleAxesIndependently];
        [_minuteHandView setImageScaling:CPImageScaleAxesIndependently];
        [_secondHandView setImageScaling:CPImageScaleAxesIndependently];
        [_middleHandView setImageScaling:CPImageScaleAxesIndependently];

        // 4. Add subviews in correct Z-Order
        [self addSubview:_hourHandView];
        [self addSubview:_minuteHandView];

        if ([_datePicker valueForThemeAttribute:@"clock-second-hand-over"])
        {
            [self addSubview:_middleHandView];
            [self addSubview:_secondHandView];
        }
        else
        {
            [self addSubview:_secondHandView];
            [self addSubview:_middleHandView];
        }
    }

    return self;
}

- (void)_initHands
{
    // FIX: Using 'duplicate' prevents CPImageViews from stealing the DOM element from each other!
    [_middleHandView setImage:[[_datePicker currentValueForThemeAttribute:@"middle-hand-image"] duplicate]];
    [_hourHandView   setImage:[[_datePicker currentValueForThemeAttribute:@"hour-hand-image"] duplicate]];
    [_minuteHandView setImage:[[_datePicker currentValueForThemeAttribute:@"minute-hand-image"] duplicate]];
    [_secondHandView setImage:[[_datePicker currentValueForThemeAttribute:@"second-hand-image"] duplicate]];

    var font       = [_datePicker currentValueForThemeAttribute:@"clock-font"],
        textColor  = [_datePicker currentValueForThemeAttribute:@"clock-text-color"],
        shadowCol  = [_datePicker currentValueForThemeAttribute:@"clock-text-shadow-color"],
        shadowOff  = [_datePicker currentValueForThemeAttribute:@"clock-text-shadow-offset"];

    if (font)
        [_PMAMTextField setFont:font];

    if (textColor)
        [_PMAMTextField setTextColor:textColor];

    if (shadowCol)
        [_PMAMTextField setTextShadowColor:shadowCol];

    if (shadowOff)
        [_PMAMTextField setTextShadowOffset:shadowOff];

    var hoursFont  = [_datePicker currentValueForThemeAttribute:@"clock-hours-font"],
        hoursColor = [_datePicker currentValueForThemeAttribute:@"clock-hours-text-color"],
        drawsHours = [_datePicker currentValueForThemeAttribute:@"clock-draws-hours"];

    for (var i = 0; i < 12; i++)
    {
        var label = _hourLabels[i];
        [label setHidden:!drawsHours];
        if (drawsHours) {
            if (hoursFont)  [label setFont:hoursFont];
            if (hoursColor) [label setTextColor:hoursColor];
            [label sizeToFit];
        }
    }
}

- (void)setDatePickerElements:(CPInteger)aDatePickerElements
{
    _datePickerElements = aDatePickerElements;

    [_secondHandView setHidden:!((_datePickerElements & CPHourMinuteSecondDatePickerElementFlag) == CPHourMinuteSecondDatePickerElementFlag)];
}

#pragma mark Layout methods

- (void)layoutSubviews
{
    [self _initHands];

    if (_trackingHand)
        return;

    [self setBackgroundColor:[_datePicker currentValueForThemeAttribute:@"bezel-color-clock"]];

    var dateValue = [[_datePicker dateValue] copy];

    [dateValue _dateWithTimeZone:[_datePicker timeZone]];

    _representedHours    = dateValue.getHours();
    _representedMinutes  = dateValue.getMinutes();
    _representedSeconds  = dateValue.getSeconds();
    _representedHourIsPM = (_representedHours > 11);

    _representedHours -= (_representedHourIsPM ? 12 : 0);

    var bounds  = [self bounds],
        centerX = bounds.size.width / 2.0,
        centerY = bounds.size.height / 2.0;

    [_PMAMTextField setStringValue:_representedHourIsPM ? @"PM" : @"AM"];
    [_PMAMTextField sizeToFit];
    [_PMAMTextField setFrameOrigin:CGPointMake(centerX - [_PMAMTextField frameSize].width / 2.0, centerY + 15.0)];

    if ([_datePicker currentValueForThemeAttribute:@"clock-draws-hours"])
    {
        var radius = [_datePicker currentValueForThemeAttribute:@"clock-hours-radius"] || 50.0;
        for (var i = 0, angle = 60.0; i < 12; i++, angle -= 30.0)
        {
            var label = _hourLabels[i],
                size  = [label frameSize],
                x     = centerX + radius * COS(angle * RADIANS) - size.width / 2.0,
                y     = centerY - radius * SIN(angle * RADIANS) - size.height / 2.0;

            [label setFrameOrigin:CGPointMake(x, y)];
        }
    }

    var centerView = function(view, size) {[view setFrame:CGRectMake(centerX - size.width / 2.0, centerY - size.height / 2.0, size.width, size.height)];
    };

    var hSize   = [_datePicker currentValueForThemeAttribute:@"hour-hand-size"]   || CGSizeMake(4, 64),
        mSize   = [_datePicker currentValueForThemeAttribute:@"minute-hand-size"] || CGSizeMake(4, 96),
        sSize   = [_datePicker currentValueForThemeAttribute:@"second-hand-size"] || CGSizeMake(4, 96),
        midSize = [_datePicker currentValueForThemeAttribute:@"middle-hand-size"] || CGSizeMake(8, 8);

    centerView(_hourHandView, hSize);
    centerView(_minuteHandView, mSize);
    centerView(_secondHandView, sSize);
    centerView(_middleHandView, midSize);

    [self _updateHands];
}

// Applies Pure CSS Transforms to rotate the elements natively in the browser
- (void)_rotateView:(CPView)view byAngle:(float)radians
{
#if PLATFORM(DOM)
    var style = view._DOMElement.style;
    style[CPBrowserStyleProperty("transformOrigin")] = "50% 50%";
    style[CPBrowserStyleProperty("transform")] = "rotate(" + radians + "rad)";
#endif
}

- (void)_updateHands
{
    _hourAngle   = (360.0 * (_representedHours   + _representedMinutes / 60.0) / 12.0) * RADIANS;
    _minuteAngle = (360.0 * (_representedMinutes + _representedSeconds / 60.0) / 60.0) * RADIANS;
    _secondAngle = (360.0 * _representedSeconds / 60.0) * RADIANS;

    [self _rotateView:_hourHandView byAngle:_hourAngle];
    [self _rotateView:_minuteHandView byAngle:_minuteAngle];
    [self _rotateView:_secondHandView byAngle:_secondAngle];
}

#pragma mark Accessors

- (void)setEnabled:(BOOL)shouldEnable
{
    shouldEnable = !!shouldEnable;

    if (shouldEnable === _isEnabled)
        return;

    _isEnabled = shouldEnable;

    [self setNeedsLayout];
}

#pragma mark Mouse actions

// Since we rotate using Pure CSS, Cappuccino's `convertPoint:` doesn't know about it.
// So we use standard Trigonometry to perfectly hit-test the rotated hands!
- (BOOL)_hitTestHandWithSize:(CGSize)size angle:(float)radians atPoint:(CGPoint)aPoint
{
    var bounds  = [self bounds],
        centerX = bounds.size.width / 2.0,
        centerY = bounds.size.height / 2.0;

    // 1. Move point to center
    var tx = aPoint.x - centerX,
        ty = aPoint.y - centerY;

    // 2. Rotate point backwards by the angle of the hand
    var cosA = COS(-radians),
        sinA = SIN(-radians),
        rx   = tx * cosA - ty * sinA,
        ry   = tx * sinA + ty * cosA;

    // 3. Test if point is within the unrotated hand's rectangle
    // The visual needle is in the top half of the hand's box (y from -h/2 to 0)
    var w2 = size.width / 2.0,
        h2 = size.height / 2.0;

    if (rx >= -w2 && rx <= w2 && ry >= -h2 && ry <= 0)
        return YES;

    return NO;
}

- (void)mouseDown:(CPEvent)anEvent
{
    if (!_isEnabled)
        return;

    var currentLocation = [self convertPoint:[anEvent locationInWindow] fromView:nil];

    var sSize = [_datePicker currentValueForThemeAttribute:@"second-hand-size"] || CGSizeMake(4, 96),
        mSize = [_datePicker currentValueForThemeAttribute:@"minute-hand-size"] || CGSizeMake(4, 96),
        hSize = [_datePicker currentValueForThemeAttribute:@"hour-hand-size"]   || CGSizeMake(4, 64);

    if (![_secondHandView isHidden] && [self _hitTestHandWithSize:sSize angle:_secondAngle atPoint:currentLocation])
    {
        _currentHandView         = _secondHandView;
        _currentHand             = _CPDatePickerClockSeconds;
        _currentRepresentedValue = _representedSeconds;
        _currentValueShift       = 0;
        _numberOfUnits           = 60;
    }
    else if (![_minuteHandView isHidden] && [self _hitTestHandWithSize:mSize angle:_minuteAngle atPoint:currentLocation])
    {
        _currentHandView         = _minuteHandView;
        _currentHand             = _CPDatePickerClockMinutes;
        _currentRepresentedValue = _representedMinutes;
        _currentValueShift       = _representedSeconds / 60;
        _numberOfUnits           = 60;
    }
    else if (![_hourHandView isHidden] && [self _hitTestHandWithSize:hSize angle:_hourAngle atPoint:currentLocation])
    {
        _currentHandView         = _hourHandView;
        _currentHand             = _CPDatePickerClockHours;
        _currentRepresentedValue = _representedHours;
        _currentValueShift       = _representedMinutes / 60;
        _numberOfUnits           = 12;
    }
    else
    {
        _currentHandView         = nil;
        _currentHand             = CPNotFound;
        _currentRepresentedValue = CPNotFound;
        _currentValueShift       = CPNotFound;
        _numberOfUnits           = CPNotFound;
    }

    if (_currentHandView)
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
    var dx    = aPoint.x - _bounds.size.width / 2,
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
                        dateValue.setDate(dateValue.getDate() + 1);
                    else if (movedBackward && _representedHourIsPM)
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

        _representedHours    = dateValue.getHours();
        _representedMinutes  = dateValue.getMinutes();
        _representedSeconds  = dateValue.getSeconds();
        _representedHourIsPM = (_representedHours > 11);
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
