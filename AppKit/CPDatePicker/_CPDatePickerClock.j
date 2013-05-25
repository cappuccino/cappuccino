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
@import "CPImageView.j"
@import "CALayer.j"


@class _CPCibCustomResource
@class CPDatePicker

@global CPHourMinuteSecondDatePickerElementFlag
@global CPTextFieldAndStepperDatePickerStyle
@global CPTextFieldDatePickerStyle

var RADIANS = Math.PI / 180;


@implementation _CPDatePickerClock : CPView
{
    BOOL            _isEnabled;
    CALayer         _rootLayer;
    CALayer         _hourHandLayer;
    CALayer         _minuteHandLayer;
    CALayer         _secondHandLayer;
    CALayer         _middleHandLayer;
    CPDatePicker    _datePicker;
    CPTextField     _PMAMTextField;
}


#pragma mark -
#pragma mark Init methods

- (id)initWithFrame:(CGRect)aFrame datePicker:(CPDatePicker)aDatePicker
{
    if (self = [super initWithFrame:aFrame])
    {
        _datePicker = aDatePicker;

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
            hourHandSize = [_datePicker valueForThemeAttribute:@"hour-hand-size"],
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

        _rootLayer = [CALayer layer];
        [self setWantsLayer:YES];
        [self setLayer:_rootLayer];

        [_hourHandLayer setNeedsDisplay];
        [_middleHandLayer setNeedsDisplay];
        [_secondHandLayer setNeedsDisplay];
        [_minuteHandLayer setNeedsDisplay];

        [_rootLayer addSublayer:_hourHandLayer];
        [_rootLayer addSublayer:_minuteHandLayer];
        [_rootLayer addSublayer:_secondHandLayer];
        [_rootLayer addSublayer:_middleHandLayer];

        [_rootLayer setNeedsDisplay];
    }

    return self;
}


#pragma mark -
#pragma mark Layout methods

- (void)layoutSubviews
{
    if ([_datePicker datePickerStyle] == CPTextFieldAndStepperDatePickerStyle || [_datePicker datePickerStyle] == CPTextFieldDatePickerStyle)
        return;

    [super layoutSubviews];

    var bounds = [self bounds],
        dateValue = [[_datePicker dateValue] copy];

    [dateValue _dateWithTimeZone:[_datePicker timeZone]];

    [self setBackgroundColor:[_datePicker currentValueForThemeAttribute:@"bezel-color-clock"]];
    [_middleHandLayer setImage:[_datePicker currentValueForThemeAttribute:@"middle-hand-image"]];
    [_hourHandLayer setImage:[_datePicker currentValueForThemeAttribute:@"hour-hand-image"]];
    [_minuteHandLayer setImage:[_datePicker currentValueForThemeAttribute:@"minute-hand-image"]];
    [_secondHandLayer setImage:[_datePicker currentValueForThemeAttribute:@"second-hand-image"]];

    if ([_datePicker _isEnglishFormat])
    {
        if (dateValue.getHours() > 11)
            [_PMAMTextField setStringValue:@"PM"]
        else
            [_PMAMTextField setStringValue:@"AM"];

        [_PMAMTextField sizeToFit];
        [_PMAMTextField setFrameOrigin:CGPointMake(bounds.size.width / 2 - [_PMAMTextField frameSize].width / 2, bounds.size.height / 2 + 15)];
        [_PMAMTextField setHidden:NO];
    }
    else
    {
        [_PMAMTextField setHidden:YES];
    }

    [_hourHandLayer setRotationRadians:[self _hourPositionRadianForDate:dateValue]];
    [_minuteHandLayer setRotationRadians:[self _minutePositionRadianForDate:dateValue]];
    [_secondHandLayer setRotationRadians:[self _secondPositionRadianForDate:dateValue]];

    [_PMAMTextField setEnabled:_isEnabled];
    [_hourHandLayer setEnabled:_isEnabled];
    [_middleHandLayer setEnabled:_isEnabled];
    [_secondHandLayer setEnabled:_isEnabled];
    [_minuteHandLayer setEnabled:_isEnabled];

    // Check if we have to display the hand second
    if (([_datePicker datePickerElements] & CPHourMinuteSecondDatePickerElementFlag) == CPHourMinuteSecondDatePickerElementFlag)
        [_secondHandLayer setHidden:NO];
    else
        [_secondHandLayer setHidden:YES];

    [_rootLayer setNeedsDisplay];
}


#pragma mark -
#pragma mark Accessors

- (float)_hourPositionRadianForDate:(CPDate)aDate
{
    var hours = aDate.getHours() + aDate.getMinutes() / 60;

    return (360 * hours / 12) * RADIANS;
}

- (float)_secondPositionRadianForDate:(CPDate)aDate
{
    return (360 * aDate.getSeconds() / 60) * RADIANS;
}

- (float)_minutePositionRadianForDate:(CPDate)aDate
{
    var minutes = aDate.getMinutes() + aDate.getSeconds() / 60;

    return (360 * minutes / 60) * RADIANS;
}

- (void)setEnabled:(BOOL)shouldEnable
{
    shouldEnable = !!shouldEnable;

    if (shouldEnable === _isEnabled)
        return;

    _isEnabled = shouldEnable;
    [self setNeedsLayout];

    // FIXME: This is a workaround for an apparent bug in CALayer.
    // Without pumping the event loop, the sublayers of _rootLayer
    // (the hands) are not redrawn until an event occurs.
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

@end


@implementation HandLayer : CALayer
{
    BOOL    _isEnabled      @accessors(setter=setEnabled:, getter=isEnabled);

    CPImage _image;
    CALayer _imageLayer;
    float   _rotationRadians;
}


#pragma mark -
#pragma mark Init methods

- (id)initWithSize:(CGSize)aSize
{
    if (self = [super init])
    {
        _isEnabled = YES;
        _imageLayer = [CALayer layer];
        _rotationRadians = 0;

        [_imageLayer setDelegate:self];
        [_imageLayer setBounds:CGRectMake(0.0, 0.0, aSize.width, aSize.height)];

        [self addSublayer:_imageLayer];
    }

    return self;
}


#pragma mark -
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

- (void)setEnabled:(BOOL)shouldEnable
{
    shouldEnable = !!shouldEnable;

    if (_isEnabled === shouldEnable)
        return;

    _isEnabled = shouldEnable;
    [self setNeedsDisplay];
    [_imageLayer setNeedsDisplay];
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

@end
