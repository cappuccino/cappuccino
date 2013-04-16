/* _CPDatePickerClock.j
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

@class CPDatePicker

@global CPHourMinuteSecondDatePickerElementFlag

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

/*! Init a new _CPDatePickerClock
    @param aFrame
    @param aDatePicker
    @return a new instance of _CPDatePickerClock
*/
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

/*! Layout the subviews
*/
- (void)layoutSubviews
{
    [super layoutSubviews];

    var bounds = [self bounds],
        dateValue = [[_datePicker dateValue] copy];

    [dateValue _dateWithTimeZone:[_datePicker timeZone]];

    [self setBackgroundColor:[_datePicker valueForThemeAttribute:@"bezel-color-clock" inState:[_datePicker themeState]]];
    [_middleHandLayer setBackgroundHandColor:[_datePicker valueForThemeAttribute:@"middle-hand-color" inState:[_datePicker themeState]]];
    [_hourHandLayer setBackgroundHandColor:[_datePicker valueForThemeAttribute:@"hour-hand-color" inState:[_datePicker themeState]]];
    [_minuteHandLayer setBackgroundHandColor:[_datePicker valueForThemeAttribute:@"minute-hand-color" inState:[_datePicker themeState]]];
    [_secondHandLayer setBackgroundHandColor:[_datePicker valueForThemeAttribute:@"second-hand-color" inState:[_datePicker themeState]]];

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

    // Check if we have to display the hand second
    if (([_datePicker datePickerElements] & CPHourMinuteSecondDatePickerElementFlag) == CPHourMinuteSecondDatePickerElementFlag)
        [_secondHandLayer setHidden:NO];
    else
        [_secondHandLayer setHidden:YES];

    [_rootLayer setNeedsDisplay];
}


#pragma mark -
#pragma mark Getter Setter methods

/*! Return the radian position of the hour
*/
- (float)_hourPositionRadianForDate:(CPDate)aDate
{
    var hours = aDate.getHours() + aDate.getMinutes() / 60;

    return (360 * hours / 12) * (Math.PI / 180)
}

/*! Return the radian position of the second
*/
- (float)_secondPositionRadianForDate:(CPDate)aDate
{
    return (360 * aDate.getSeconds() / 60) * (Math.PI / 180)
}

/*! Return the radian position of the minute
*/
- (float)_minutePositionRadianForDate:(CPDate)aDate
{
    var minutes = aDate.getMinutes() + aDate.getSeconds() / 60;

    return (360 * minutes / 60) * (Math.PI / 180)
}

/*! Set enabled
    @param aBoolean
*/
- (void)setEnabled:(BOOL)aBoolean
{
    _isEnabled = aBoolean;
    [_PMAMTextField setEnabled:aBoolean];
    [_hourHandLayer setEnabled:aBoolean];
    [_middleHandLayer setEnabled:aBoolean];
    [_secondHandLayer setEnabled:aBoolean];
    [_minuteHandLayer setEnabled:aBoolean];

    [self setNeedsLayout];
}

@end


@implementation HandLayer : CALayer
{
    BOOL    _isEnabled      @accessors(setter=setEnabled:, getter=isEnabled);

    CALayer _imageLayer;
    float   _rotationRadians;
}


#pragma mark -
#pragma mark Init methods

/*! Init a new hand layer with an image. The image will be draw in a ImageLayer
    @param anImage
    @return a new instance of handLayer
*/
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

/*! Set the bounds of the layer. The imageLayer will be at the center of this bounds
    @param aRect
*/
- (void)setBounds:(CGRect)aRect
{
    [super setBounds:aRect];

    [_imageLayer setPosition:CGPointMake(CGRectGetMidX(aRect), CGRectGetMidY(aRect))];
}

/*! Set the rotation of the imageLayer
    @param radians
*/
- (void)setRotationRadians:(float)radians
{
    if (_rotationRadians == radians)
        return;

    _rotationRadians = radians;

    [_imageLayer setAffineTransform:CGAffineTransformScale(
        CGAffineTransformMakeRotation(_rotationRadians),
        1.0, 1.0)];
}

- (void)setBackgroundHandColor:(CPColor)aColor
{
    [_imageLayer setBackgroundColor:aColor];
}

- (void)setEnabled:(BOOL)aBoolean
{
    _isEnabled = aBoolean;
    [self setNeedsDisplay];
}

@end
