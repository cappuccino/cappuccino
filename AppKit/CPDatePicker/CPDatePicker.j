/* CPDatePicker.j
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

@import "CPControl.j"
@import "CPFont.j"
@import "CPTextField.j"
@import "_CPDatePickerTextField.j"
@import "_CPDatePickerCalendar.j"

@import <Foundation/CPArray.j>
@import <Foundation/CPObject.j>
@import <Foundation/CPDate.j>
@import <Foundation/CPDateFormatter.j>
@import <Foundation/CPLocale.j>
@import <Foundation/CPTimeZone.j>

@class CPStepper
@class CPApp

@global CPLocaleLanguageCode
@global CPDateFormatterShortStyle

var CPDatePicker_validateProposedDateValue_timeInterval = 1 << 1;

CPSingleDateMode = 0;
CPRangeDateMode = 1;

CPTextFieldAndStepperDatePickerStyle    = 0;
CPClockAndCalendarDatePickerStyle       = 1;
CPTextFieldDatePickerStyle              = 2;

CPHourMinuteDatePickerElementFlag       = 0x000c;
CPHourMinuteSecondDatePickerElementFlag = 0x000e;
CPTimeZoneDatePickerElementFlag         = 0x0010;
CPYearMonthDatePickerElementFlag        = 0x00c0;
CPYearMonthDayDatePickerElementFlag     = 0x00e0;
CPEraDatePickerElementFlag              = 0x0100;

/*!
    @ingroup appkit
    This control displays a datepicker in a Cappuccino application
*/
@implementation CPDatePicker : CPControl
{
    BOOL            _isBordered         @accessors(getter=isBordered, setter=setBordered:);
    BOOL            _isBezeled          @accessors(getter=isBezeled, setter=setBezeled:);
    BOOL            _drawsBackground    @accessors(property=drawsBackground);
    CPDate          _dateValue          @accessors(property=dateValue);
    CPDate          _minDate            @accessors(property=minDate);
    CPDate          _maxDate            @accessors(property=maxDate);
    CPFont          _textFont           @accessors(property=textFont);
    CPLocale        _locale             @accessors(property=locale);
    //CPCalendar  _calendar           @accessors(property=calendar);
    CPTimeZone      _timeZone           @accessors(property=timeZone);
    id              _delegate           @accessors(property=delegate);
    unsigned        _datePickerElements @accessors(property=datePickerElements);
    CPInteger       _datePickerMode     @accessors(property=datePickerMode);
    CPInteger       _datePickerStyle    @accessors(property=datePickerStyle);
    CPInteger       _timeInterval       @accessors(property=timeInterval);

    _CPDatePickerTextField  _datePickerTextfield;
    _CPDatePickerCalendar   _datePickerCalendar;
    unsigned                _implementedCDatePickerDelegateMethods;
}


#pragma mark -
#pragma mark Theme methods

+ (CPString)defaultThemeClass
{
    return @"datePicker";
}

+ (id)themeAttributes
{
    return @{
            @"bezel-color": [CPColor clearColor],
            @"border-width" : 1.0,
            @"border-color": [CPColor clearColor],
            @"content-inset": CGInsetMakeZero(),
            @"bezel-inset": CGInsetMakeZero(),
            @"datepicker-textfield-bezel-color": [CPColor clearColor],
            @"min-size-datepicker-textfield": CGSizeMakeZero(),
            @"content-inset-datepicker-textfield": CGInsetMakeZero(),
            @"content-inset-datepicker-textfield-separator": CGInsetMakeZero(),
            @"separator-content-inset": CGInsetMakeZero(),
            @"date-hour-margin": 5.0,
            @"stepper-margin": 5.0,
            @"bezel-color-calendar": [CPColor clearColor],
            @"title-text-color": [CPColor blackColor],
            @"title-text-shadow-color": [CPColor clearColor],
            @"title-text-shadow-offset": CGSizeMakeZero(),
            @"title-font": [CPNull null],
            @"weekday-text-color": [CPColor blackColor],
            @"weekday-text-shadow-color": [CPColor clearColor],
            @"weekday-text-shadow-offset": CGSizeMakeZero(),
            @"weekday-font": [CPNull null],
            @"arrow-image-left": [CPNull null],
            @"arrow-image-right": [CPNull null],
            @"arrow-image-left-highlighted": [CPNull null],
            @"arrow-image-right-highlighted": [CPNull null],
            @"arrow-inset": CGInsetMakeZero(),
            @"circle-image": [CPNull null],
            @"circle-image-highlighted": [CPNull null],
            @"tile-text-color": [CPColor blackColor],
            @"tile-text-shadow-color": [CPColor clearColor],
            @"tile-text-shadow-offset": CGSizeMakeZero(),
            @"tile-font": [CPNull null],
            @"size-tile": CGSizeMakeZero(),
            @"size-calendar": CGSizeMakeZero(),
            @"size-header": CGSizeMakeZero(),
            @"min-size-calendar": CGSizeMakeZero(),
            @"max-size-calendar": CGSizeMakeZero(),
            @"bezel-color-clock": [CPColor clearColor],
            @"clock-text-color": [CPColor blackColor],
            @"clock-text-shadow-color": [CPColor clearColor],
            @"clock-text-shadow-offset": CGSizeMakeZero(),
            @"clock-font": [CPNull null],
            @"second-hand-color": [CPColor clearColor],
            @"hour-hand-color": [CPColor clearColor],
            @"middle-hand-color": [CPColor clearColor],
            @"minute-hand-color": [CPColor clearColor],
            @"size-clock": CGSizeMakeZero(),
            @"second-hand-size": CGSizeMakeZero(),
            @"hour-hand-size": CGSizeMakeZero(),
            @"middle-hand-size": CGSizeMakeZero(),
            @"minute-hand-size": CGSizeMakeZero(),
    };
}


#pragma mark -
#pragma mark Binding methods

+ (Class)_binderClassForBinding:(CPString)theBinding
{
    if (theBinding == CPValueBinding || theBinding == CPMinValueBinding || theBinding == CPMaxValueBinding)
        return [_CPDatePickerValueBinder class];

    return [super _binderClassForBinding:theBinding];
}

- (id)_replacementKeyPathForBinding:(CPString)aBinding
{
    if (aBinding == CPValueBinding)
        return @"dateValue";

    if (aBinding == CPMinValueBinding)
        return @"minDate";

    if (aBinding == CPMaxValueBinding)
        return @"maxDate";

    return [super _replacementKeyPathForBinding:aBinding];
}


#pragma mark -
#pragma mark Init methods

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _drawsBackground = YES;
        _datePickerStyle = CPTextFieldAndStepperDatePickerStyle;
        _datePickerMode = CPSingleDateMode;
        _datePickerElements = CPYearMonthDayDatePickerElementFlag | CPHourMinuteSecondDatePickerElementFlag;
        _timeInterval = 0;
        _implementedCDatePickerDelegateMethods = 0;

        [self setObjectValue:[CPDate date]];
        _minDate = [CPDate distantPast];
        _maxDate = [CPDate distantFuture];

        [self setBezeled:YES];
        [self setBordered:YES];

        [self _init];
    }

    return self
}

- (void)_init
{
    if (!_locale)
        _locale = [CPLocale currentLocale];

    if (!_timeZone)
        _timeZone = [CPTimeZone systemTimeZone];

    _datePickerTextfield = [[_CPDatePickerTextField alloc] initWithFrame:[self bounds] withDatePicker:self];

    [_datePickerTextfield setDateValue:_dateValue];
    [self addSubview:_datePickerTextfield];

    _datePickerCalendar = [[_CPDatePickerCalendar alloc] initWithFrame:[self bounds] withDatePicker:self];
    [_datePickerCalendar setDateValue:_dateValue];
    [_datePickerCalendar setHidden:YES];
    [self addSubview:_datePickerCalendar];

    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
}


#pragma mark -
#pragma mark Delegate methods

/*! Set the delegate of the datePicker
    @param aDelegate delegate of the datePicker
*/
- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
    _implementedCDatePickerDelegateMethods = 0;

    // Look if the delegate implements or not the delegate methods
    if ([_delegate respondsToSelector:@selector(datePicker:validateProposedDateValue:timeInterval:)])
        _implementedCDatePickerDelegateMethods |= CPDatePicker_validateProposedDateValue_timeInterval;
}


#pragma mark -
#pragma mark Layout method

/*! Layout the subviews
*/
- (void)layoutSubviews
{
    [super layoutSubviews];

    if (_datePickerStyle == CPTextFieldAndStepperDatePickerStyle || _datePickerStyle == CPTextFieldDatePickerStyle)
    {
        [_datePickerTextfield setHidden:NO];
        [_datePickerCalendar setHidden:YES];
        [_datePickerTextfield setNeedsLayout];
    }
    else
    {
        [_datePickerCalendar setHidden:NO];
        [_datePickerTextfield setHidden:YES];
        [_datePickerCalendar setNeedsLayout];
    }
}

#pragma mark -
#pragma mark Setter

/*! Return the objectValue of the datePicker. The objectValue should take the timeZoneEffect
*/
- (void)objectValue
{
    // TODO : add timeZone effect. How to do it because js ???
    return _dateValue
}

/*! Set the objectValue ofhe datePier. It has to be a CPDate
    @param aDateValue the dateValue
*/
- (void)setObjectValue:(CPDate)aValue
{
    [self setDateValue:aValue];
}

/* Set the dateValue of the datePicker
    @param aDateValue the dateValue
*/
- (void)setDateValue:(CPDate)aDateValue
{
    if (aDateValue == nil)
        return;

    [self _setDateValue:aDateValue timeInterval:_timeInterval];
}

/*! Set the dateValue and the timeInterval. This method checks the min and max date of the datePicker also. It will call the delegate if possible.
    @param aDateValue the dateValue
    @param aTimeInterval the timeInterval
*/
- (void)_setDateValue:(CPDate)aDateValue timeInterval:(CPTimeInterval)aTimeInterval
{
    if (_minDate)
        aDateValue = new Date (MAX(aDateValue, _minDate));

    if (_maxDate)
        aDateValue = new Date (MIN(aDateValue, _maxDate));

    aTimeInterval = MAX(MIN(aTimeInterval, [_maxDate timeIntervalSinceDate:aDateValue]), [_minDate timeIntervalSinceDate:aDateValue]);

    if ([aDateValue isEqualToDate:_dateValue] && aTimeInterval == _timeInterval)
        return;

    if (_implementedCDatePickerDelegateMethods & CPDatePicker_validateProposedDateValue_timeInterval)
    {
        // constrain timeInterval also
        var aStartDateRef = function(x){if (typeof x == 'undefined') return aDateValue; aDateValue = x;}
        var aTimeIntervalRef = function(x){if (typeof x == 'undefined') return aTimeInterval; aTimeInterval = x;}

        [_delegate datePicker:self validateProposedDateValue:aStartDateRef timeInterval:aTimeIntervalRef];
    }

    [self willChangeValueForKey:@"objectValue"];
    [self willChangeValueForKey:@"dateValue"];
    _dateValue = aDateValue;
    [super setObjectValue:_dateValue];
    [self didChangeValueForKey:@"objectValue"];
    [self didChangeValueForKey:@"dateValue"];

    [self willChangeValueForKey:@"timeInterval"];
    _timeInterval = (_datePickerMode == CPSingleDateMode)? 0 : aTimeInterval;
    [self didChangeValueForKey:@"timeInterval"];

    [self sendAction:[self action] to:[self target]];

    if (_datePickerStyle == CPTextFieldAndStepperDatePickerStyle || _datePickerStyle == CPTextFieldDatePickerStyle)
        [_datePickerTextfield setDateValue:_dateValue];
    else
        [_datePickerCalendar setDateValue:_dateValue];
}

/*! Set the minDate of the datePicker
    @param aMinDate the minDate
*/
- (void)setMinDate:(CPDate)aMinDate
{
    [self willChangeValueForKey:@"minDate"];
    _minDate = aMinDate;
    [self didChangeValueForKey:@"minDate"];

    [self _setDateValue:_dateValue timeInterval:_timeInterval];
}

/*! Set the maxDate of the datePicker
    @param aMaxDate the maxDate
*/
- (void)setMaxDate:(CPDate)aMaxDate
{
    [self willChangeValueForKey:@"maxDate"];
    _maxDate = aMaxDate;
    [self didChangeValueForKey:@"maxDate"];

    [self _setDateValue:_dateValue timeInterval:_timeInterval];
}

/*! Set the syle of the datePicker
    @param aDatePickerStyle the datePicker style
*/
- (void)setDatePickerStyle:(CPDate)aDatePickerStyle
{
    _datePickerStyle = aDatePickerStyle;

    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
}

/*! Set the elements of the datePicker
    @param aDatePickerElements the datePicker elements
*/
- (void)setDatePickerElements:(CPDate)aDatePickerElements
{
    _datePickerElements = aDatePickerElements;

    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
}

/*! Set the mode of the datePicker
    @param aDatePickerMode the datePicker mode
*/
- (void)setDatePickerMode:(CPDate)aDatePickerMode
{
    _datePickerMode = aDatePickerMode;

    if (_datePickerMode == CPSingleDateMode)
        [self _setDateValue:[self dateValue] timeInterval:0];

    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
}

/*! Set the timeInterval of the datePicker
    @param aTimeInterval the timeInterval of the datePicker
*/
- (void)setTimeInterval:(CPInteger)aTimeInterval
{
    if (_datePickerMode == CPSingleDateMode)
        return;

    [self _setDateValue:[self dateValue] timeInterval:aTimeInterval];
}

/*! Set the locale of the datePicker. This update laso the locale of the formatter.
    @param aLocale the locale
*/
- (void)setLocale:(CPLocale)aLocale
{
    _locale = aLocale;

    if (_formatter)
    {
        [self willChangeValueForKey:@"locale"];
        [_formatter setLocale:_locale];
        [self didChangeValueForKey:@"locale"];
    }

    // This will update the textFields (usefull when changing with a date with pm and am)
    [_datePickerTextfield setDateValue:_dateValue];
    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
}

/*!
    Sets whether the datepicker will have a bezeled border.
    @param shouldBeBezeled \c YES means the datepicker will draw a bezeled border
*/
- (void)setBezeled:(BOOL)shouldBeBezeled
{
    _isBezeled = shouldBeBezeled;

    if (shouldBeBezeled)
        [self setThemeState:CPThemeStateBezeled];
    else
        [self unsetThemeState:CPThemeStateBezeled];
}

/*!
    Sets whether the datepicker will have a border drawn. (actually it does nothing)
    @param shouldBeBordered \c YES makes the datepicker draw a border
*/
- (void)setBordered:(BOOL)shouldBeBordered
{
    _isBordered = shouldBeBordered;

    if (shouldBeBordered)
        [self setThemeState:CPThemeStateBordered];
    else
        [self unsetThemeState:CPThemeStateBordered];
}

/*!
    Sets the font of the control.
    @param aFont
*/
- (void)setTextFont:(CPFont)aFont
{
    [self setFont:aFont];
}

/*! Sets the enabled status of the control. Controls that are not enabled can not be used by the user and obtain the CPThemeStateDisabled theme state.
    @param a boolean. YES if the control should be enabled, otherwise NO.
*/
- (void)setEnabled:(BOOL)aBoolean
{
    [super setEnabled:aBoolean];

    [_datePickerTextfield setEnabled:aBoolean];
    [_datePickerCalendar setEnabled:aBoolean];
}

/*! Set the background color of the datePicker
    @param aColor
*/
- (void)setBackgroundColor:(CPColor)aColor
{
    _backgroundColor = aColor;
    [self setNeedsLayout];
}

/*! Set the boolean drawsBackgroundColor
    @param aBoolean
*/
- (void)setDrawsBackground:(BOOL)aBoolean
{
    [self willChangeValueForKey:@"drawsBackground"];
    _drawsBackground = aBoolean;
    [self didChangeValueForKey:@"drawsBackground"];

    [self setNeedsLayout];
}

/*! Set the timeZone
    @param aTimeZone
*/
- (void)setTimeZone:(CPTimeZone)aTimeZone
{
    [self willChangeValueForKey:@"timeZone"];
    _timeZone = aTimeZone;
    [self didChangeValueForKey:@"timeZone"];

    [self setNeedsLayout];
}


#pragma mark -
#pragma mark First responder methods

/*! Return YES if style is set to CPTextFieldAndStepperDatePickerStyle or CPTextFieldDatePickerStyle
*/
- (BOOL)becomeFirstResponder
{
    if (_datePickerStyle == CPTextFieldAndStepperDatePickerStyle || _datePickerStyle == CPTextFieldDatePickerStyle)
        [_datePickerTextfield _selecteTextFieldWithFlags:[[CPApp currentEvent] modifierFlags]];
    else
        return NO;

    return YES;
}

/*! Return YES
*/
- (BOOL)acceptsFirstResponder
{
    return YES;
}

/*! Return YES
*/
- (BOOL)resignFirstResponder
{
    if (_datePickerStyle == CPTextFieldAndStepperDatePickerStyle || _datePickerStyle == CPTextFieldDatePickerStyle)
        [_datePickerTextfield resignFirstResponder];

    return YES;
}


#pragma mark -
#pragma mark getter

/*!
    Returns \c YES if the textfield is bezeled.
*/
- (BOOL)isBezeled
{
    return [self hasThemeState:CPThemeStateBezeled];
}

/*!
    Returns \c YES if the textfield has a border.
*/
- (BOOL)isBordered
{
    return [self hasThemeState:CPThemeStateBordered];
}

/*!
    Returns the font of the control.
*/
- (CPFont)textFont
{
    return [self font];
}

/*! Check if we are in the american format or not. Depending on the locale
*/
- (BOOL)_isAmericanFormat
{
    return [[_locale objectForKey:CPLocaleCountryCode] isEqualToString:@"US"];
}

/*! Check if we are in the english format or not. Depending on the locale
*/
- (BOOL)_isEnglishFormat
{
    return [[_locale objectForKey:CPLocaleLanguageCode] isEqualToString:@"en"];
}


#pragma mark -
#pragma mark Key event

/*! Key down event
    @param anEvent
*/
- (void)keyDown:(CPEvent)anEvent
{
    if (_datePickerStyle == CPTextFieldAndStepperDatePickerStyle || _datePickerStyle == CPTextFieldDatePickerStyle)
        [_datePickerTextfield keyDown:anEvent];
}

@end

var CPDatePickerModeKey         = @"CPDatePickerModeKey",
    CPIntervalKey               = @"CPIntervalKey",
    CPMinDateKey                = @"CPMinDateKey",
    CPMaxDateKey                = @"CPMaxDateKey",
    CPBackgroundColorKey        = @"CPBackgroundColorKey",
    CPDrawsBackgroundKey        = @"CPDrawsBackgroundKey",
    CPTextFontKey               = @"CPTextFontKey",
    CPDatePickerElementsKey     = @"CPDatePickerElementsKey",
    CPDatePickerStyleKey        = @"CPDatePickerStyleKey",
    CPLocaleKey                 = @"CPLocaleKey",
    CPBorderedKey               = @"CPBorderedKey",
    CPDateValueKey              = @"CPDateValueKey";

@implementation CPDatePicker (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _textFont = [aCoder decodeObjectForKey:CPTextFontKey];
        _minDate = [aCoder decodeObjectForKey:CPMinDateKey] || [CPDate distantPast];
        _maxDate = [aCoder decodeObjectForKey:CPMaxDateKey] || [CPDate distantFuture];
        _timeInterval = [aCoder decodeDoubleForKey:CPIntervalKey];
        _datePickerMode = [aCoder decodeIntForKey:CPDatePickerModeKey];
        _datePickerElements = [aCoder decodeIntForKey:CPDatePickerElementsKey];
        _datePickerStyle = [aCoder decodeIntForKey:CPDatePickerStyleKey];
        _locale = [aCoder decodeObjectForKey:CPLocaleKey];
        _dateValue = [aCoder decodeObjectForKey:CPDateValueKey];
        _backgroundColor = [aCoder decodeObjectForKey:CPBackgroundColorKey];
        _drawsBackground = [aCoder decodeBoolForKey:CPDrawsBackgroundKey];
        _isBordered = [aCoder decodeBoolForKey:CPBorderedKey];
        [self _init];
    }

    return self
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeDouble:_timeInterval forKey:CPIntervalKey];
    [aCoder encodeInt:_datePickerMode forKey:CPDatePickerModeKey];
    [aCoder encodeInt:_datePickerStyle forKey:CPDatePickerStyleKey];
    [aCoder encodeInt:_datePickerElements forKey:CPDatePickerElementsKey];
    [aCoder encodeObject:_minDate forKey:CPMinDateKey];
    [aCoder encodeObject:_maxDate forKey:CPMaxDateKey]
    [aCoder encodeObject:_dateValue forKey:CPDateValueKey];;
    [aCoder encodeObject:_textFont forKey:CPTextFontKey];
    [aCoder encodeObject:_locale forKey:CPLocaleKey];
    [aCoder encodeObject:_backgroundColor forKey:CPBackgroundColorKey];
    [aCoder encodeObject:_drawsBackground forKey:CPDrawsBackgroundKey];
    [aCoder encodeObject:_isBordered forKey:CPBorderedKey];
}

@end

@implementation _CPDatePickerValueBinder : CPBinder
{
}

@end

@implementation CPDate (CPDatePickerAdditions)

- (int)_daysInMonth
{
    return 32 - new Date(self.getFullYear(), self.getMonth(), 32).getDate();
}

- (void)_resetToMidnight
{
    self.setHours(0);
    self.setMinutes(0);
    self.setSeconds(0);
    self.setMilliseconds(0);
}

- (void)_resetToLastSeconds
{
    self.setHours(23);
    self.setMinutes(59);
    self.setSeconds(59);
    self.setMilliseconds(99);
}

@end