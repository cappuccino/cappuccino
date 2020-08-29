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
    BOOL                    _isBordered         @accessors(getter=isBordered, setter=setBordered:);
    BOOL                    _isBezeled          @accessors(getter=isBezeled, setter=setBezeled:);
    BOOL                    _drawsBackground    @accessors(property=drawsBackground);
    CPDate                  _dateValue          @accessors(property=dateValue);
    CPDate                  _minDate            @accessors(property=minDate);
    CPDate                  _maxDate            @accessors(property=maxDate);
    CPFont                  _textFont           @accessors(property=textFont);
    CPLocale                _locale             @accessors(property=locale);
    //CPCalendar            _calendar           @accessors(property=calendar);
    CPTimeZone              _timeZone           @accessors(property=timeZone);
    id                      _delegate           @accessors(property=delegate);
    CPInteger               _datePickerElements @accessors(property=datePickerElements);
    CPInteger               _datePickerMode     @accessors(property=datePickerMode);
    CPInteger               _datePickerStyle    @accessors(property=datePickerStyle);
    CPInteger               _timeInterval       @accessors(property=timeInterval);

    BOOL                    _invokedByUserEvent;
    unsigned                _implementedCDatePickerDelegateMethods;
    BOOL                    _isTextual;
    id                      _datePickerComponent;
}


#pragma mark -
#pragma mark Theme methods

+ (CPString)defaultThemeClass
{
    return @"datePicker";
}

+ (CPDictionary)themeAttributes
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
            @"second-hand-image": [CPNull null],
            @"hour-hand-image": [CPNull null],
            @"middle-hand-image": [CPNull null],
            @"minute-hand-image": [CPNull null],
            @"size-clock": CGSizeMakeZero(),
            @"second-hand-size": CGSizeMakeZero(),
            @"hour-hand-size": CGSizeMakeZero(),
            @"middle-hand-size": CGSizeMakeZero(),
            @"minute-hand-size": CGSizeMakeZero(),
            @"previous-button-size": CGSizeMakeZero(),
            @"current-button-size": CGSizeMakeZero(),
            @"next-button-size": CGSizeMakeZero(),
            @"title-inset": [CPNull null],
            @"day-label-inset": [CPNull null],
            @"tile-content-inset": CGInsetMakeZero(),
            @"tile-margin": [CPNull null],
            @"tile-inset": CGInsetMakeZero(),
            @"separator-color": [CPNull null],
            @"separator-margin-width": 0,
            @"separator-height": 0,
            @"bezel-color-calendar-left": [CPNull null],
            @"bezel-color-calendar-middle": [CPNull null],
            @"bezel-color-calendar-right": [CPNull null],
            @"tile-vertical-alignment": CPCenterVerticalTextAlignment,
            @"tile-text-alignment": CPCenterTextAlignment,
            @"hour-ampm-margin": 2,
            @"time-separator-content-inset": CGInsetMakeZero(),
            @"clock-second-hand-over": NO,
            @"clock-draws-hours": NO,
            @"clock-hours-font": [CPNull null],
            @"clock-hours-text-color": [CPColor clearColor],
            @"clock-hours-radius": 0,
            @"calendar-clock-margin": 10,
            @"clock-only-nib2cib-adjustment-frame": CPRectMakeZero(),
            @"uses-focus-ring": NO
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

- (CPString)_replacementKeyPathForBinding:(CPString)aBinding
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

    _datePickerComponent = nil;

    [self _createComponents];

    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
}

- (void)_createComponents
{
    _isTextual = (_datePickerStyle == CPTextFieldAndStepperDatePickerStyle) || (_datePickerStyle == CPTextFieldDatePickerStyle);

    if (_datePickerComponent)
    {
        [_datePickerComponent removeFromSuperview];

        _datePickerComponent = nil;
    }

    _datePickerComponent = [[(_isTextual ? _CPDatePickerTextField : _CPDatePickerCalendar) alloc] initWithFrame:[self bounds] withDatePicker:self];

    [_datePickerComponent setDateValue:_dateValue];
    [_datePickerComponent setControlSize:[self controlSize]];

    // FIXME: Don't know why but next line will cause theme compilation to fail...
    // Workaround: added "if PLATFORM(DOM)"
#if PLATFORM(DOM)
    [_datePickerComponent setEnabled:[self isEnabled]];
#endif

    if (_isTextual)
        // We need to transmit text color to the text field version (Cocoa doesn't permit adapting the calendar view text color)
        [_datePickerComponent setTextColor:[self textColor]];

    [self addSubview:_datePickerComponent];
}


#pragma mark -
#pragma mark Control Size

- (void)setControlSize:(CPControlSize)aControlSize
{
    [super setControlSize:aControlSize];

    [_datePickerComponent setControlSize:aControlSize];

    if (_isTextual)
        [self _sizeToControlSize];
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
    [_datePickerComponent setNeedsLayout];
    [_datePickerComponent setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Setter

/*! Return the objectValue of the datePicker. The objectValue should take the timeZoneEffect
*/
- (id)objectValue
{
    // TODO : add timeZone effect. How to do it because js ???
    return _dateValue
}

/*! Set the objectValue of the datePicker. It has to be a CPDate
    @param aDateValue the dateValue
*/
- (void)setObjectValue:(CPDate)aValue
{
    if (![aValue isKindOfClass:[CPDate class]])
        return;

    [self setDateValue:aValue];
}

/* Set the dateValue of the datePicker
    @param aDateValue the dateValue
*/
- (void)setDateValue:(CPDate)aDateValue
{
    if (aDateValue == nil)
        return;

    _invokedByUserEvent = NO;
    [self _setDateValue:aDateValue timeInterval:_timeInterval];
}

/*! Set the dateValue and the timeInterval. This method checks the min and max date of the datePicker also. It will call the delegate if possible.
    @param aDateValue the dateValue
    @param aTimeInterval the timeInterval
*/
- (void)_setDateValue:(CPDate)aDateValue timeInterval:(CPTimeInterval)aTimeInterval
{
    // Make sure to have a valid date and avoid NaN values
    if (!isFinite(aDateValue))
    {
        [CPException raise:CPInvalidArgumentException
                    reason:@"aDateValue is not valid"];
        return;
    }

    if (_minDate)
        aDateValue = new Date (MAX(aDateValue, _minDate));

    if (_maxDate)
        aDateValue = new Date (MIN(aDateValue, _maxDate));

    aTimeInterval = MAX(MIN(aTimeInterval, [_maxDate timeIntervalSinceDate:aDateValue]), [_minDate timeIntervalSinceDate:aDateValue]);

    if ([aDateValue isEqualToDate:_dateValue] && aTimeInterval == _timeInterval)
    {
        [_datePickerComponent setDateValue:_dateValue];

        return;
    }

    if (_implementedCDatePickerDelegateMethods & CPDatePicker_validateProposedDateValue_timeInterval)
    {
        // constrain timeInterval also
        var aStartDateRef = function(x){if (typeof x == 'undefined') return aDateValue; aDateValue = x;};
        var aTimeIntervalRef = function(x){if (typeof x == 'undefined') return aTimeInterval; aTimeInterval = x;};

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

    if (_invokedByUserEvent)
        [self sendAction:[self action] to:[self target]];

    [_datePickerComponent setDateValue:_dateValue];
}

/*! Set the minDate of the datePicker
    @param aMinDate the minDate
*/
- (void)setMinDate:(CPDate)aMinDate
{
    if (_minDate === aMinDate)
        return;

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
    if (_maxDate === aMaxDate)
        return;

    [self willChangeValueForKey:@"maxDate"];
    _maxDate = aMaxDate;
    [self didChangeValueForKey:@"maxDate"];

    [self _setDateValue:_dateValue timeInterval:_timeInterval];
}

/*! Set the syle of the datePicker
    @param aDatePickerStyle the datePicker style
*/
- (void)setDatePickerStyle:(CPInteger)aDatePickerStyle
{
    if (_datePickerStyle === aDatePickerStyle)
        return;

    _datePickerStyle = aDatePickerStyle;

    // This is needed in order to specify different theme attributes values for textual / graphical date picker
    if (_datePickerStyle === CPClockAndCalendarDatePickerStyle)
        [self setThemeState:CPThemeStateAlternateState];
    else
        [self unsetThemeState:CPThemeStateAlternateState];

    // This is needed in order to specify different theme attributes values for with / without stepper textual date picker
    if (_datePickerStyle === CPTextFieldAndStepperDatePickerStyle)
        [self setThemeState:CPThemeStateComposedControl];
    else
        [self unsetThemeState:CPThemeStateComposedControl];

    [self setControlSize:[self controlSize]];

    if (_datePickerComponent)
    {
        // We already have a component so we need to update it
        [_datePickerComponent resignFirstResponder];
        [self _createComponents];
    }

    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
}

/*! Set the elements of the datePicker
    @param aDatePickerElements the datePicker elements
*/
- (void)setDatePickerElements:(CPInteger)aDatePickerElements
{
    if (_datePickerElements === aDatePickerElements)
        return;

    _datePickerElements = aDatePickerElements;

    // Notify the component of the new value
    [_datePickerComponent setDatePickerElements:_datePickerElements];

    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
}

/*! Set the mode of the datePicker
    @param aDatePickerMode the datePicker mode
*/
- (void)setDatePickerMode:(CPInteger)aDatePickerMode
{
    if (_datePickerMode === aDatePickerMode)
        return;

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
    if (_locale === aLocale)
        return;

    _locale = aLocale;

    if (_formatter)
    {
        [self willChangeValueForKey:@"locale"];
        [_formatter setLocale:_locale];
        [self didChangeValueForKey:@"locale"];
    }

    // This will update the textFields (usefull when changing with a date with pm and am)
    if (_isTextual)
        [_datePickerComponent setDateValue:_dateValue];

    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
}

/*!
    Sets whether the datepicker will have a bezeled border.
    @param shouldBeBezeled \c YES means the datepicker will draw a bezeled border
*/
- (void)setBezeled:(BOOL)shouldBeBezeled
{
    if (_isBezeled === shouldBeBezeled)
        return;

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
    if (_isBordered === shouldBeBordered)
        return;

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

    if (_isTextual)
        [_datePickerComponent setTextFont:aFont];
}

/*!
 Sets the color of the control.
 @param aColor
 */
- (void)setTextColor:(CPColor)aColor
{
    [super setTextColor:aColor];

    if (_isTextual)
        [_datePickerComponent setTextColor:aColor];
    // REM: in Cocoa, setTextColor has no effect on calendar view
}

/*! Sets the enabled status of the control. Controls that are not enabled can not be used by the user and obtain the CPThemeStateDisabled theme state.
    @param a boolean. YES if the control should be enabled, otherwise NO.
*/
- (void)setEnabled:(BOOL)aBoolean
{
    [super setEnabled:aBoolean];

    [_datePickerComponent setEnabled:aBoolean];

    if (!aBoolean)
        [self resignFirstResponder];
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
    if (_drawsBackground === aBoolean)
        return;

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
    if (_timeZone === aTimeZone)
        return;

    [self willChangeValueForKey:@"timeZone"];
    _timeZone = aTimeZone;
    [self didChangeValueForKey:@"timeZone"];

    [self setNeedsLayout];

    [_datePickerComponent setDateValue:_dateValue];
}


#pragma mark -
#pragma mark First responder methods

/*! Return YES if style is set to CPTextFieldAndStepperDatePickerStyle or CPTextFieldDatePickerStyle
*/
- (BOOL)becomeFirstResponder
{
    if (_isTextual)
    {
        if (![super becomeFirstResponder])
            return NO;

        [_datePickerComponent _selectTextFieldWithFlags:[[CPApp currentEvent] modifierFlags]];

        return YES;
    }

    return NO;
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
    if (_isTextual)
        [_datePickerComponent resignFirstResponder];

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

#pragma mark -
#pragma mark Key event

/*! Key down event
    @param anEvent
*/
- (void)keyDown:(CPEvent)anEvent
{
    if (_isTextual)
        [_datePickerComponent keyDown:anEvent];
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
        _backgroundColor = [aCoder decodeObjectForKey:CPBackgroundColorKey];
        [self setBordered:[aCoder decodeBoolForKey:CPBorderedKey]];
        [self setDrawsBackground:[aCoder decodeBoolForKey:CPDrawsBackgroundKey]];

        [self setDatePickerElements:[aCoder decodeIntForKey:CPDatePickerElementsKey]];
        [self setDatePickerMode:[aCoder decodeIntForKey:CPDatePickerModeKey]];
        [self setDatePickerStyle:[aCoder decodeIntForKey:CPDatePickerStyleKey]];
        [self setMinDate:[aCoder decodeObjectForKey:CPMinDateKey] || [CPDate distantPast]];
        [self setMaxDate:[aCoder decodeObjectForKey:CPMaxDateKey] || [CPDate distantFuture]];
        [self setLocale:[aCoder decodeObjectForKey:CPLocaleKey]];

        [self _init];

        [self setTextFont:[aCoder decodeObjectForKey:CPTextFontKey]];
        [self setTimeInterval:[aCoder decodeDoubleForKey:CPIntervalKey]];
        [self setDateValue:[aCoder decodeObjectForKey:CPDateValueKey]];
    }

    return self
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    // Before encoding, we remove all subviews as we'll recreate them at loading
    while ([[self subviews] count] > 0)
        [[[self subviews] lastObject] removeFromSuperview];

    [super encodeWithCoder:aCoder];

    [aCoder encodeDouble:_timeInterval forKey:CPIntervalKey];
    [aCoder encodeInt:_datePickerMode forKey:CPDatePickerModeKey];
    [aCoder encodeInt:_datePickerStyle forKey:CPDatePickerStyleKey];
    [aCoder encodeInt:_datePickerElements forKey:CPDatePickerElementsKey];
    [aCoder encodeObject:_minDate forKey:CPMinDateKey];
    [aCoder encodeObject:_maxDate forKey:CPMaxDateKey];
    [aCoder encodeObject:_dateValue forKey:CPDateValueKey];
    [aCoder encodeObject:_textFont forKey:CPTextFontKey];
    [aCoder encodeObject:_locale forKey:CPLocaleKey];
    [aCoder encodeObject:_backgroundColor forKey:CPBackgroundColorKey];
    [aCoder encodeObject:_drawsBackground forKey:CPDrawsBackgroundKey];
    [aCoder encodeObject:_isBordered forKey:CPBorderedKey];

}

@end

// FIXME: add support for CPEditorRegistrationProtocol as implemented for CPTextField
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
