/* _CPDatePickerElementTextField.j
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

@import "CPTextField.j"

@class CPDatePicker
@class _CPDatePickerElementView

CPDatePickerElementTextFieldBecomeFirstResponder = @"CPDatePickerElementTextFieldBecomeFirstResponder";
CPDatePickerElementTextFieldAMPMChangedNotification = @"CPDatePickerElementTextFieldAMPMChangedNotification";

var CPZeroKeyCode = 48,
    CPNineKeyCode = 57,
    CPMajAKeyCode = 65,
    CPMajPKeyCode = 80,
    CPAKeyCode = 97,
    CPPKeyCode = 112;

CPMonthDateType = 0;
CPDayDateType = 1;
CPYearDateType = 2;
CPHourDateType = 3;
CPSecondDateType = 4;
CPMinuteDateType = 5;
CPAMPMDateType = 6;

/*! An element textField
*/
@implementation _CPDatePickerElementTextField : CPTextField
{
    _CPDatePickerElementTextField _nextTextField            @accessors(property=nextTextField);
    _CPDatePickerElementTextField _previousTextField        @accessors(property=previousTextField);
    _CPDatePickerElementView      _datePickerElementView    @accessors(property=datePickerElementView);

    CPDatePicker    _datePicker @accessors(setter=setDatePicker:);

    int _dateType  @accessors(getter=dateType);
    int _maxNumber @accessors(getter=maxNumber);
    int _minNumber @accessors(getter=minNumber);

    BOOL    _firstEvent;
    CPTimer _timerEdition;
}

+ (CPString)defaultThemeClass
{
    return @"datePickerElementTextField";
}

+ (CPDictionary)themeAttributes
{
    return @{
             @"content-inset":  CGInsetMake(1.0, 0.0, 0.0, 0.0),
             @"bezel-color":    [CPNull null],
             @"min-size":       CGSizeMakeZero()
             };
}

- (id)init
{
    if (self = [super init])
    {
        _firstEvent = YES;
    }

    return self;
}

/*! @ignore */
- (BOOL)acceptsFirstResponder
{
    return [_datePicker isEnabled];
}

/*! Set the dateType of the textField
*/
- (void)setDateType:(int)aDateType
{
    _dateType = aDateType;

    switch (aDateType)
    {
        case CPMonthDateType:
            _minNumber = 1;
            _maxNumber = 12;
            break;

        case CPDayDateType:
            _minNumber = 1;
            _maxNumber = 31;
            break;

        case CPYearDateType:
            _minNumber = 0;
            _maxNumber = 9999;
            break;

        case CPHourDateType:
            _minNumber = 0;
            _maxNumber = 23;
            break;

        case CPSecondDateType:
            _minNumber = 0;
            _maxNumber = 59;
            break;

        case CPMinuteDateType:
            _minNumber = 0;
            _maxNumber = 59;
            break;
    }
}

/*! Return the maxNumber of the textField
*/
- (int)maxNumber
{
    if (_dateType == CPDayDateType)
        return [[_datePicker dateValue] _daysInMonth];

    return _maxNumber;
}

/*! Return the maxNumber of the textField depending of the maxDate
*/
- (int)_maxNumberWithMaxDate
{
    var maxDate = [_datePicker maxDate],
        date = [_datePicker dateValue];

    if (maxDate)
    {
        switch (_dateType)
        {
            case CPMonthDateType:
                if (maxDate.getFullYear() == date.getFullYear())
                    return maxDate.getMonth();
                break;

            case CPDayDateType:
                if (maxDate.getFullYear() == date.getFullYear() && maxDate.getMonth() == date.getMonth())
                    return maxDate.getDate();
                break;

            case CPYearDateType:
                return maxDate.getFullYear();

            case CPHourDateType:
                if (maxDate.getFullYear() == date.getFullYear() && maxDate.getMonth() == date.getMonth() && maxDate.getDate() == date.getDate())
                    return maxDate.getHours();
                break;

            case CPSecondDateType:
                if (maxDate.getFullYear() == date.getFullYear() && maxDate.getMonth() == date.getMonth() && maxDate.getDate() == date.getDate() && maxDate.getHours() == date.getHours() && maxDate.getMinutes() == date.getMinutes())
                    return maxDate.getSeconds();
                break;

            case CPMinuteDateType:
                if (maxDate.getFullYear() == date.getFullYear() && maxDate.getMonth() == date.getMonth() && maxDate.getDate() == date.getDate() && maxDate.getHours() == date.getHours())
                    return maxDate.getMinutes();
                break;
        }
    }

    return _maxNumber;
}

/*! Set the stringValue of the textField. This is going to check if there is 2 or 4 letters. If not it adds a space. Check also the maxDate
    It's called when the user is editing with the keyboard
    @param aStringValue a CPString
*/
- (void)setValueForKeyEvent:(CPEvent)anEvent
{
    var keyCode = [anEvent keyCode];

    if (keyCode != CPDeleteKeyCode && keyCode != CPDeleteForwardKeyCode  && keyCode < CPZeroKeyCode || keyCode > CPNineKeyCode)
        return;

    var newValue = [self stringValue].replace(/\s/g, ''),
        length = [newValue length],
        eventKeyValue = parseInt([anEvent characters]).toString();

    if (keyCode == CPDeleteKeyCode || keyCode == CPDeleteForwardKeyCode)
    {
        [_timerEdition invalidate];
        _timerEdition = nil;
        newValue = [newValue substringToIndex:(length - 1)];
    }
    else
    {
        if (!_timerEdition)
        {
            _timerEdition = [CPTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(_timerKeyEvent:) userInfo:nil repeats:NO];

            if (_firstEvent || !length)
                newValue = eventKeyValue;
            else
                newValue = parseInt(newValue).toString() + eventKeyValue;
        }
        else
        {
            var newFireDate = [CPDate date];

            newFireDate.setSeconds(newFireDate.getSeconds() + 2);
            [_timerEdition setFireDate:newFireDate];

            newValue = parseInt(newValue).toString() + eventKeyValue;
        }
    }

    if (parseInt(newValue) > [self _maxNumberWithMaxDate] || ([_datePicker _isAmericanFormat] && _dateType == CPHourDateType && parseInt(newValue) > 12))
        return;

    _firstEvent = NO;

    [super setObjectValue:newValue];
}

/*!
    End of the timer
*/
- (void)_timerKeyEvent:(id)sender
{
    var stringValue = [self stringValue];

    _timerEdition = nil;

    if ([stringValue length])
    {
        if ([_datePicker _isAmericanFormat] && [self dateType] == CPHourDateType)
        {
            var isAMHour = [[self superview] _isAMHour];

            if (!isAMHour && stringValue != 12)
                stringValue = parseInt(stringValue) + 12;

            if (stringValue == 12 && !isAMHour)
                stringValue = 12;
            else if (stringValue == 12)
                stringValue = 0;
        }

        [self setObjectValue:stringValue];
    }
}

/*!
    We force to end the timer
*/
- (void)_invalidTimer
{
    if (_timerEdition)
    {
        [_timerEdition invalidate];
        _timerEdition = nil;
    }
}

/*!
    We force to end the timer and to update the objectValue of the datePicker
*/
- (void)_endEditing
{
    if (_timerEdition)
        [_timerEdition invalidate];

    _timerEdition = nil;

    var objectValue = [self stringValue];

    if (![objectValue length])
        objectValue = [self objectValue];

    if ([_datePicker _isAmericanFormat] && [self dateType] == CPHourDateType)
    {
        var isAMHour = [[self superview] _isAMHour];

        if (!isAMHour && objectValue != 12)
            objectValue = parseInt(objectValue) + 12;

        if (objectValue == 12 && !isAMHour)
            objectValue = 12;
        else if (objectValue == 12)
            objectValue = 0;
    }

    [self setObjectValue:objectValue];
}

/*! Set the stringValue of the TextField. Add some zeros of there isn't 2/4 letters in the value. It's called at the end of the editing process
    @param aStringValue a CPString
*/
- (void)setStringValue:(CPString)aStringValue
{
    if (_dateType == CPYearDateType)
    {
        while ([aStringValue length] < 4)
            aStringValue = "0" + aStringValue;
    }
    else if (_dateType != CPAMPMDateType)
    {
        if (_dateType == CPHourDateType && [_datePicker _isAmericanFormat])
        {
            var value = parseInt(aStringValue);

            if (value == 0)
                value = 12;
            else if (value > 12)
                value = value - 12;

            aStringValue = value.toString();
        }

        while ([aStringValue length] < 2)
        {
            if (_dateType == CPSecondDateType || _dateType == CPMinuteDateType)
                aStringValue = @"0" + aStringValue;
            else
                aStringValue = @" " + aStringValue;
        }

    }

    [super setObjectValue:aStringValue];
}

/*! Set the objectValue. This will update the dateValue of the datePicker also. It's called with the binding of the stepper or arrows
    This is not going to update the objectValue of the control !!! It updates the dateValue of the datePicker who's going to update the datePickerTextField if necessary
    It's a bit tricky
    @param aObjectValue
*/
- (void)setObjectValue:(id)anObjectValue
{
    var dateValue = [[_datePicker dateValue] copy],
        lengthString = [[self stringValue] length],
        objectValue = parseInt(anObjectValue);

    switch (_dateType)
    {
        case CPMonthDateType:

            if (objectValue == 0 || !lengthString)
            {
                [self setStringValue:(dateValue.getMonth() + 1).toString()];
                return;
            }

            var dateNextMonth = [dateValue copy];

            dateNextMonth.setDate(1);
            dateNextMonth.setMonth(parseInt(anObjectValue) - 1);

            var numberDayNextMonth = [dateNextMonth _daysInMonth];

            if (numberDayNextMonth < [dateValue _daysInMonth] && dateValue.getDate() > numberDayNextMonth)
                [_datePickerElementView setDayDateValue:numberDayNextMonth.toString()];

            [super setObjectValue:objectValue];
            break;

        case CPDayDateType:

            if (objectValue == 0 || !lengthString)
            {
                [self setStringValue:dateValue.getDate().toString()];
                return;
            }

            [super setObjectValue:objectValue];
            break;

        case CPYearDateType:

            if (objectValue == 0 || !lengthString)
            {
                [self setStringValue:dateValue.getFullYear().toString()];
                return;
            }

            [super setObjectValue:objectValue];
            break;

        case CPHourDateType:

            if (!lengthString)
            {
                [self setStringValue:dateValue.getHours().toString()];
                return;
            }

            [super setObjectValue:objectValue];
            break;

        case CPSecondDateType:

            if (!lengthString)
            {
                [self setStringValue:dateValue.getSeconds().toString()];
                return;
            }

            [super setObjectValue:objectValue];
            break;

        case CPMinuteDateType:

            if (!lengthString)
            {
                [self setStringValue:dateValue.getMinutes().toString()];
                return;
            }

            [super setObjectValue:objectValue];
            break;
    }

    var newDateValue = [_datePickerElementView dateValue],
        timeZone = [_datePicker timeZone];

    if (timeZone)
    {
        var secondsFromGMT = [timeZone secondsFromGMTForDate:newDateValue],
            secondsFromGMTTimeZone = [timeZone secondsFromGMT];

        newDateValue.setSeconds(newDateValue.getSeconds() + secondsFromGMT - secondsFromGMTTimeZone);
    }

#if PLATFORM(DOM)
    _datePicker._invokedByUserEvent = YES;
#endif
    [_datePicker _setDateValue:newDateValue timeInterval:[_datePicker timeInterval]];
#if PLATFORM(DOM)
    _datePicker._invokedByUserEvent = NO;
#endif
}


#pragma mark -
#pragma mark Mouse event

/*! Mouse down event. Launch a notification to notif the new first responder textField
*/
- (void)mouseDown:(CPEvent)anEvent
{
    if (![self isEnabled])
        return;

    [super mouseDown:anEvent];
    [[CPNotificationCenter defaultCenter] postNotificationName:CPDatePickerElementTextFieldBecomeFirstResponder object:[[self superview] superview] userInfo:[CPDictionary dictionaryWithObject:self forKey:@"textField"]];
}


#pragma mark -
#pragma mark Theme functions

/*! Set the theme CPThemeStateSelected
*/
- (void)makeSelectable
{
    [self setThemeState:CPThemeStateSelected];
    [_datePicker setThemeState:CPThemeStateEditing];
}

/*! Unsert the theme CPThemeStateSelected
*/
- (void)makeDeselectable
{
    _firstEvent = YES;
    [self unsetThemeState:CPThemeStateSelected];
    [_datePicker unsetThemeState:CPThemeStateEditing];
}


#pragma mark -
#pragma mark Override

/*!
    We override this method to get all the time the good width
*/
- (CGSize)_minimumFrameSize
{
    var frameSize = [self frameSize],
        contentInset = [self currentValueForThemeAttribute:@"content-inset"],
        minSize = [self currentValueForThemeAttribute:@"min-size"],
        maxSize = [self currentValueForThemeAttribute:@"max-size"],
        lineBreakMode = [self lineBreakMode],
        text = (_dateType == CPYearDateType) ? @"0000" : (_dateType == CPMonthDateType) ? @"10" : @"00",
        textSize = CGSizeMakeCopy(frameSize),
        font = [self currentValueForThemeAttribute:@"font"];

    textSize.width -= contentInset.left + contentInset.right;
    textSize.height -= contentInset.top + contentInset.bottom;

    if (_dateType == CPAMPMDateType)
        text = [self stringValue];

    if (frameSize.width !== 0 &&
        ![self isBezeled]     &&
        (lineBreakMode === CPLineBreakByWordWrapping || lineBreakMode === CPLineBreakByCharWrapping))
    {
        textSize = [text sizeWithFont:font inWidth:textSize.width];
    }
    else
    {
        textSize = [text sizeWithFont:font];

        // Account for possible fractional pixels at right edge
        textSize.width += 1;
    }

    // Account for possible fractional pixels at bottom edge
    textSize.height += 1;

    frameSize.height = textSize.height + contentInset.top + contentInset.bottom;

    if ([self isBezeled])
    {
        frameSize.height = MAX(frameSize.height, minSize.height);

        if (maxSize.width > 0.0)
            frameSize.width = MIN(frameSize.width, maxSize.width);

        if (maxSize.height > 0.0)
            frameSize.height = MIN(frameSize.height, maxSize.height);
    }
    else
        frameSize.width = textSize.width + contentInset.left + contentInset.right;

    frameSize.width = MAX(frameSize.width, minSize.width);

    return frameSize;
}

- (CGRect)bezelRectForBounds:(CGRect)bounds
{
    return CGRectMakeCopy(bounds);
}

@end

#pragma mark -

@implementation _CPDatePickerElementSeparator : CPTextField

+ (CPString)defaultThemeClass
{
    return @"datePickerElementSeparator";
}

+ (CPDictionary)themeAttributes
{
    return @{
             @"content-inset":  CGInsetMake(1.0, 0.0, 0.0, 0.0),
             @"min-size":       CGSizeMakeZero()
             };
}

@end
