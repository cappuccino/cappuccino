/* _CPDatePickerElementView.j
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
@import "_CPDatePickerElementTextField.j"

@class CPDatePicker

@global CPHourMinuteDatePickerElementFlag
@global CPHourMinuteSecondDatePickerElementFlag
@global CPTimeZoneDatePickerElementFlag
@global CPYearMonthDatePickerElementFlag
@global CPYearMonthDayDatePickerElementFlag
@global CPEraDatePickerElementFlag

/*! This class is used to display the elements (all of the textFields) in the datePicker
*/
@implementation _CPDatePickerElementView : CPControl
{
    _CPDatePickerElementTextField       _textFieldDay;
    _CPDatePickerElementTextField       _textFieldMonth;
    _CPDatePickerElementTextField       _textFieldYear;
    _CPDatePickerElementTextField       _textFieldHour;
    _CPDatePickerElementTextField       _textFieldMinute;
    _CPDatePickerElementTextField       _textFieldSecond;
    _CPDatePickerElementTextField       _textFieldPMAM;
    CPDatePicker                        _datePicker;
    CPTextField                         _textFieldSeparatorOne;
    CPTextField                         _textFieldSeparatorTwo;
    CPTextField                         _textFieldSeparatorThree;
    CPTextField                         _textFieldSeparatorFour;
}


#pragma mark Init

- (id)initWithFrame:(CGRect)aFrame withDatePicker:(CPDatePicker)aDatePicker
{
    if (self = [super init])
    {
        _datePicker = aDatePicker;
        [self _init];
    }
    return self;
}

- (void)_init
{
    _textFieldDay = [_CPDatePickerElementTextField new];
    [_textFieldDay setBezeled:NO];
    [_textFieldDay setBordered:NO];
    [_textFieldDay setDateType:CPDayDateType];
    [_textFieldDay setDatePicker:_datePicker];
    [_textFieldDay setAlignment:CPRightTextAlignment];
    [_textFieldDay setDatePickerElementView:self];
    [self addSubview:_textFieldDay];

    _textFieldMonth = [_CPDatePickerElementTextField new];
    [_textFieldMonth setBezeled:NO];
    [_textFieldMonth setBordered:NO];
    [_textFieldMonth setDateType:CPMonthDateType];
    [_textFieldMonth setDatePicker:_datePicker];
    [_textFieldMonth setAlignment:CPRightTextAlignment];
    [_textFieldMonth setDatePickerElementView:self];
    [self addSubview:_textFieldMonth];

    _textFieldYear = [_CPDatePickerElementTextField new];
    [_textFieldYear setBezeled:NO];
    [_textFieldYear setBordered:NO];
    [_textFieldYear setDateType:CPYearDateType];
    [_textFieldYear setDatePicker:_datePicker];
    [_textFieldYear setAlignment:CPRightTextAlignment];
    [_textFieldYear setDatePickerElementView:self];
    [self addSubview:_textFieldYear];

    _textFieldHour = [_CPDatePickerElementTextField new];
    [_textFieldHour setBezeled:NO];
    [_textFieldHour setBordered:NO];
    [_textFieldHour setDateType:CPHourDateType];
    [_textFieldHour setDatePicker:_datePicker];
    [_textFieldHour setAlignment:CPRightTextAlignment];
    [_textFieldHour setDatePickerElementView:self];
    [self addSubview:_textFieldHour];

    _textFieldMinute = [_CPDatePickerElementTextField new];
    [_textFieldMinute setBezeled:NO];
    [_textFieldMinute setBordered:NO];
    [_textFieldMinute setDateType:CPMinuteDateType];
    [_textFieldMinute setDatePicker:_datePicker];
    [_textFieldMinute setAlignment:CPRightTextAlignment];
    [_textFieldMinute setDatePickerElementView:self];
    [self addSubview:_textFieldMinute];

    _textFieldSecond = [_CPDatePickerElementTextField new];
    [_textFieldSecond setBezeled:NO];
    [_textFieldSecond setBordered:NO];
    [_textFieldSecond setDateType:CPSecondDateType];
    [_textFieldSecond setDatePicker:_datePicker];
    [_textFieldSecond setAlignment:CPRightTextAlignment];
    [_textFieldSecond setDatePickerElementView:self];
    [self addSubview:_textFieldSecond];

    _textFieldPMAM = [_CPDatePickerElementTextField new];
    [_textFieldPMAM setBezeled:NO];
    [_textFieldPMAM setBordered:NO];
    [_textFieldPMAM setDateType:CPAMPMDateType];
    [_textFieldPMAM setDatePicker:_datePicker];
    [_textFieldPMAM setAlignment:CPRightTextAlignment];
    [_textFieldPMAM setDatePickerElementView:self];
    [self addSubview:_textFieldPMAM];

    _textFieldSeparatorOne   = [_CPDatePickerElementSeparator labelWithTitle:@"/"];
    _textFieldSeparatorTwo   = [_CPDatePickerElementSeparator labelWithTitle:@"/"];
    _textFieldSeparatorThree = [_CPDatePickerElementSeparator labelWithTitle:@":"];
    _textFieldSeparatorFour  = [_CPDatePickerElementSeparator labelWithTitle:@":"];

    [self addSubview: _textFieldSeparatorOne];
    [self addSubview: _textFieldSeparatorTwo];
    [self addSubview: _textFieldSeparatorThree];
    [self addSubview: _textFieldSeparatorFour];

    [self setNeedsLayout];
}


#pragma mark -
#pragma mark Responder methods

/*! @ignore */
- (BOOL)acceptsFirstResponder
{
    // This is needed to accept to be firstResponder when nothing is selected.
    // This element needs to be first responder when the CPDatePicker is in the CPTableView
    // When clicking on a row of a CPTableView where there isn't a date element, the CPTableView will ask this element to know if it can becomes or not a firstResponder.
    return [_datePicker isEnabled] && ![self superview]._currentTextField;
}


#pragma mark -
#pragma mark Override observers

- (void)_removeObservers
{
    if (!_isObserving)
        return;

    [super _removeObservers];

    [[CPNotificationCenter defaultCenter] removeObserver:self name:CPDatePickerElementTextFieldAMPMChangedNotification object:_textFieldPMAM];
}

- (void)_addObservers
{
    if (_isObserving)
        return;

    [super _addObservers];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_datePickerElementTextFieldAMPMChangedNotification:) name:CPDatePickerElementTextFieldAMPMChangedNotification object:_textFieldPMAM];
}

#pragma mark -
#pragma mark Mouse event

- (BOOL)continueTracking:(CGPoint)lastPoint at:(CGPoint)aPoint
{
    [self _selectTextFieldForPoint:aPoint];
    return YES;
}

- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    [self _selectTextFieldForPoint:aPoint];
    return YES;
}

- (void)_selectTextFieldForPoint:(CGPoint)aPoint
{
    var textField = [self _textFieldForPoint:aPoint],
        superview = [self superview];

    if (!textField || [superview._currentTextField] == textField)
        return;

    [[CPNotificationCenter defaultCenter] postNotificationName:CPDatePickerElementTextFieldBecomeFirstResponder object:superview userInfo:[CPDictionary dictionaryWithObject:textField forKey:@"textField"]];
}

- (_CPDatePickerElementTextField)_textFieldForPoint:(CGPoint)aPoint
{
    if (![_textFieldDay isHidden] && CGRectContainsPoint([_textFieldDay frame], aPoint))
        return _textFieldDay;

    if (![_textFieldMonth isHidden] && CGRectContainsPoint([_textFieldMonth frame], aPoint))
        return _textFieldMonth;

    if (![_textFieldYear isHidden] && CGRectContainsPoint([_textFieldYear frame], aPoint))
        return _textFieldYear;

    if (![_textFieldHour isHidden] && CGRectContainsPoint([_textFieldHour frame], aPoint))
        return _textFieldHour;

    if (![_textFieldMinute isHidden] && CGRectContainsPoint([_textFieldMinute frame], aPoint))
        return _textFieldMinute;

    if (![_textFieldSecond isHidden] && CGRectContainsPoint([_textFieldSecond frame], aPoint))
        return _textFieldSecond;

    if (![_textFieldPMAM isHidden] && CGRectContainsPoint([_textFieldPMAM frame], aPoint))
        return _textFieldPMAM;

    return nil;
}

#pragma mark -
#pragma mark Setter Getter methods

/*! Set the value of the textFields
    @param aDateValue the value
*/
- (void)setDateValue:(CPDate)aDateValue
{
    [_textFieldDay setStringValue:[CPString stringWithFormat:@"%i", aDateValue.getDate()]];
    [_textFieldMonth setStringValue:[CPString stringWithFormat:@"%i", aDateValue.getMonth() + 1]];
    [_textFieldYear setStringValue:[CPString stringWithFormat:@"%i", aDateValue.getFullYear()]];
    [_textFieldHour setStringValue:[CPString stringWithFormat:@"%i", aDateValue.getHours()]];
    [_textFieldMinute setStringValue:[CPString stringWithFormat:@"%i", aDateValue.getMinutes()]];
    [_textFieldSecond setStringValue:[CPString stringWithFormat:@"%i", aDateValue.getSeconds()]];

    if (aDateValue.getHours() > 11)
        [_textFieldPMAM setStringValue:@"PM"];
    else
        [_textFieldPMAM setStringValue:@"AM"];
}

/*! Set the day date value to the appropriate textField
    @param aDayDateValue the day
*/
- (void)setDayDateValue:(CPString)aDayDateValue
{
    [_textFieldDay setStringValue:aDayDateValue];
}

/*! Set the widget enabled or not
    @param aBoolean
*/
- (void)setEnabled:(BOOL)aBoolean
{
    [super setEnabled:aBoolean];
    [_textFieldDay setEnabled:aBoolean];
    [_textFieldMonth setEnabled:aBoolean];
    [_textFieldYear setEnabled:aBoolean];
    [_textFieldHour setEnabled:aBoolean];
    [_textFieldMinute setEnabled:aBoolean];
    [_textFieldSecond setEnabled:aBoolean];
    [_textFieldSeparatorOne setEnabled:aBoolean];
    [_textFieldSeparatorTwo setEnabled:aBoolean];
    [_textFieldSeparatorThree setEnabled:aBoolean];
    [_textFieldSeparatorFour setEnabled:aBoolean];
    [_textFieldPMAM setEnabled:aBoolean];
}

- (void)setTextColor:(CPColor)aColor
{
    [super setTextColor:aColor];

    [_textFieldDay            setTextColor:aColor];
    [_textFieldMonth          setTextColor:aColor];
    [_textFieldYear           setTextColor:aColor];
    [_textFieldHour           setTextColor:aColor];
    [_textFieldMinute         setTextColor:aColor];
    [_textFieldSecond         setTextColor:aColor];
    [_textFieldSeparatorOne   setTextColor:aColor];
    [_textFieldSeparatorTwo   setTextColor:aColor];
    [_textFieldSeparatorThree setTextColor:aColor];
    [_textFieldSeparatorFour  setTextColor:aColor];
    [_textFieldPMAM           setTextColor:aColor];
}

- (void)setTextFont:(CPFont)aFont
{
    [self setFont:aFont];

    [_textFieldDay            setFont:aFont];
    [_textFieldMonth          setFont:aFont];
    [_textFieldYear           setFont:aFont];
    [_textFieldHour           setFont:aFont];
    [_textFieldMinute         setFont:aFont];
    [_textFieldSecond         setFont:aFont];
    [_textFieldSeparatorOne   setFont:aFont];
    [_textFieldSeparatorTwo   setFont:aFont];
    [_textFieldSeparatorThree setFont:aFont];
    [_textFieldSeparatorFour  setFont:aFont];
    [_textFieldPMAM           setFont:aFont];
}

/*! Return YES if the hour is set to the morning
*/
- (BOOL)_isAMHour
{
    return [[_textFieldPMAM stringValue] isEqualToString:@"AM"];
}

- (CPDate)dateValue
{
    var date = [[_datePicker dateValue] copy];

    [date _dateWithTimeZone:[_datePicker timeZone]];

    if (![_textFieldDay isHidden])
        date.setDate([_textFieldDay intValue]);

    if (![_textFieldMonth isHidden])
        date.setMonth([_textFieldMonth intValue] - 1);

    if (![_textFieldYear isHidden])
        date.setFullYear([_textFieldYear intValue]);

    if (![_textFieldSecond isHidden])
        date.setSeconds([_textFieldSecond intValue]);

    if (![_textFieldMinute isHidden])
        date.setMinutes([_textFieldMinute intValue]);

    if (![_textFieldHour isHidden])
    {
        var hour = [_textFieldHour intValue],
            currentHour = parseInt(date.getHours());

        if (hour != currentHour)
        {
            if ([_datePicker _isAmericanFormat])
            {
                if (![self _isAMHour])
                {
                    if (!(currentHour == 12 && hour == 11) && hour < 13)
                        hour = hour + 12;
                }
                else if (hour == 12 && currentHour != 11)
                {
                    hour = 0;
                }
                else if (currentHour == 0 && hour == 11)
                {
                    hour = 23;
                }
                else if (hour == 13)
                {
                    hour = 1;
                }
            }

            if (hour == 24)
                hour = 0;

            date.setHours(hour);
        }
    }

    return date;
}


#pragma mark -
#pragma mark Notification methods

/*! Called when changing AM or PM
    @param aNotification
*/
- (void)_datePickerElementTextFieldAMPMChangedNotification:(CPNotification)aNotification
{
    var value = [[aNotification object] stringValue],
        dateValue = [[_datePicker dateValue] copy],
        d = [dateValue copy];

    [d _dateWithTimeZone:[_datePicker timeZone]];

    if ([value isEqualToString:@"PM"])
    {
        if (d.getHours() <= 11)
            dateValue.setHours(dateValue.getHours() + 12);
    }
    else
    {
        if (d.getHours() > 11)
            dateValue.setHours(dateValue.getHours() - 12);
    }

#if PLATFORM(DOM)
    _datePicker._invokedByUserEvent = YES;
#endif
    [_datePicker _setDateValue:dateValue timeInterval:[_datePicker timeInterval]];
#if PLATFORM(DOM)
    _datePicker._invokedByUserEvent = NO;
#endif
}


#pragma mark -
#pragma mark Layout methods

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "bezel-view")
        return [self bounds];

    return [super rectForEphemeralSubviewNamed:aName];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "bezel-view")
    {
        var view = [[CPView alloc] initWithFrame:CGRectMakeZero()];

        [view setHitTests:NO];

        return view;
    }

    return [super createEphemeralSubviewNamed:aName];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    var themeState = [_datePicker themeState];

    if ([self isCSSBased])
    {
        if ([_datePicker isBezeled] || [_datePicker isBordered])
        {
            var bezelView = [self layoutEphemeralSubviewNamed:@"bezel-view"
                                                   positioned:CPWindowBelow
                              relativeToEphemeralSubviewNamed:nil];

            [bezelView setBackgroundColor:[_datePicker valueForThemeAttribute:@"bezel-color" inState:themeState]];
        }

        if ([_datePicker drawsBackground])
            [self setBackgroundColor:[_datePicker backgroundColor]];
        else
            [self setBackgroundColor:[CPColor clearColor]];
    }
    else
    {
        if ([_datePicker isBezeled] && [_datePicker drawsBackground] || [_datePicker isBordered] && [_datePicker drawsBackground])
            [self setBackgroundColor:[_datePicker valueForThemeAttribute:@"bezel-color" inState:themeState]];
        else if ([_datePicker drawsBackground])
            [self setBackgroundColor:[_datePicker backgroundColor]];
        else
            [self setBackgroundColor:[CPColor clearColor]];
    }

    [self _themeTextFields];

    [self _updateResponderTextField];
    [self _updateHiddenTextFields];
    [self _setControlSizes];
    [self _sizeToFit];
    [self _updatePositions];

    [self setNeedsDisplay:YES];
}

- (void)drawRect:(CGRect)aRect
{
    [super drawRect:aRect];

    if (([_datePicker isBordered] || [_datePicker isBezeled]) && ![_datePicker drawsBackground])
    {
        var context = [[CPGraphicsContext currentContext] graphicsPort],
            borderWidth = [_datePicker valueForThemeAttribute:@"border-width"] / 2,
            bezelInset = [_datePicker valueForThemeAttribute:@"bezel-inset" inState:[_datePicker themeState]];

        CGContextBeginPath(context);
        CGContextSetStrokeColor(context, [_datePicker valueForThemeAttribute:@"border-color" inState:[_datePicker themeState]]);
        CGContextSetLineWidth(context,  [_datePicker valueForThemeAttribute:@"border-width"]);

        CGContextMoveToPoint(context, borderWidth - bezelInset.left, borderWidth);
        CGContextAddLineToPoint(context, [self bounds].size.width + bezelInset.left - borderWidth, borderWidth);
        CGContextAddLineToPoint(context, [self bounds].size.width + bezelInset.left - borderWidth, [self bounds].size.height - borderWidth);
        CGContextAddLineToPoint(context, borderWidth - bezelInset.left, [self bounds].size.height - borderWidth);
        CGContextAddLineToPoint(context, borderWidth - bezelInset.left, borderWidth);

        CGContextStrokePath(context);
        CGContextClosePath(context);
    }

}

/*! Theme the textFields depending of the theme of the datePicker
*/
- (void)_themeTextFields
{
    // Beginning with Aristo3, elements and separators text fields are directly themed
    if ([self isCSSBased])
        return;

    var disabledTextColor = [_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateDisabled],
        disabledTextFieldBezelColor = [_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateDisabled],
        disabledTextShadowColor = [_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled],
        disabledTextShadowOffset = [_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled],
        normalSeparatorContentInset = [_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield-separator" inState:CPThemeStateNormal],
        normalTextFieldBezelColor = [_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateNormal],
        normalTextFieldContentInset = [_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield" inState:CPThemeStateNormal],
        normalTextShadowColor = [_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal],
        normalTextShadowOffset = [_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal],
        selectedSeparatorContentInset = [_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield-separator" inState:CPThemeStateSelected],
        selectedTextColor = [_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateSelected],
        selectedTextFieldBezelColor = [_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateSelected],
        selectedTextFieldContentInset = [_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield" inState:CPThemeStateSelected],
        selectedTextShadowColor = [_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected],
        selectedTextShadowOffset = [_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateSelected],
        textColor = [_datePicker textColor],
        textFieldMinSize = [_datePicker currentValueForThemeAttribute:@"min-size-datepicker-textfield"],
        textFont = [_datePicker textFont];

    [self _textFieldSetValue:textFieldMinSize forThemeAttribute:@"min-size" inState:nil];
    [self _textFieldSetValue:normalTextFieldContentInset forThemeAttribute:@"content-inset" inState:CPThemeStateNormal];
    [self _textFieldSetValue:selectedTextFieldContentInset forThemeAttribute:@"content-inset" inState:CPThemeStateSelected];
    [self _textFieldSetValue:selectedTextFieldBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateSelected];
    [self _textFieldSetValue:textFont forThemeAttribute:@"font" inState:CPThemeStateSelected];
    [self _textFieldSetValue:selectedTextColor forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
    [self _textFieldSetValue:selectedTextShadowColor forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected];
    [self _textFieldSetValue:selectedTextShadowOffset forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateSelected];
    [self _textFieldSetValue:normalTextFieldBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateNormal];
    [self _textFieldSetValue:textFont forThemeAttribute:@"font" inState:CPThemeStateNormal];
    [self _textFieldSetValue:textColor forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
    [self _textFieldSetValue:normalTextShadowColor forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [self _textFieldSetValue:normalTextShadowOffset forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];
    [self _textFieldSetValue:disabledTextFieldBezelColor forThemeAttribute:@"bezel-color" inState:CPThemeStateDisabled];
    [self _textFieldSetValue:textFont forThemeAttribute:@"font" inState:CPThemeStateDisabled];
    [self _textFieldSetValue:disabledTextColor forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
    [self _textFieldSetValue:disabledTextShadowColor forThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled];
    [self _textFieldSetValue:disabledTextShadowOffset forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled];

    [self _textFieldSeparatorSetValue:normalSeparatorContentInset forThemeAttribute:@"content-inset" inState:CPThemeStateNormal];
    [self _textFieldSeparatorSetValue:selectedSeparatorContentInset forThemeAttribute:@"content-inset" inState:CPThemeStateSelected];
    [self _textFieldSeparatorSetValue:textFont forThemeAttribute:@"font" inState:CPThemeStateNormal];
    [self _textFieldSeparatorSetValue:textColor forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
    [self _textFieldSeparatorSetValue:normalTextShadowColor forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [self _textFieldSeparatorSetValue:normalTextShadowOffset forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];
    [self _textFieldSeparatorSetValue:textFont forThemeAttribute:@"font" inState:CPThemeStateDisabled];
    [self _textFieldSeparatorSetValue:disabledTextColor forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
    [self _textFieldSeparatorSetValue:disabledTextShadowColor forThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled];
    [self _textFieldSeparatorSetValue:disabledTextShadowOffset forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled];
}

- (void)_textFieldSetValue:(id)aValue forThemeAttribute:(CPString)aThemeAttribute inState:(CPThemeState)aThemeState
{
    if (aThemeState)
    {
        [_textFieldDay    setValue:aValue forThemeAttribute:aThemeAttribute inState:aThemeState];
        [_textFieldMonth  setValue:aValue forThemeAttribute:aThemeAttribute inState:aThemeState];
        [_textFieldYear   setValue:aValue forThemeAttribute:aThemeAttribute inState:aThemeState];
        [_textFieldHour   setValue:aValue forThemeAttribute:aThemeAttribute inState:aThemeState];
        [_textFieldMinute setValue:aValue forThemeAttribute:aThemeAttribute inState:aThemeState];
        [_textFieldSecond setValue:aValue forThemeAttribute:aThemeAttribute inState:aThemeState];
        [_textFieldPMAM   setValue:aValue forThemeAttribute:aThemeAttribute inState:aThemeState];
    }
    else
    {
        [_textFieldDay    setValue:aValue forThemeAttribute:aThemeAttribute];
        [_textFieldMonth  setValue:aValue forThemeAttribute:aThemeAttribute];
        [_textFieldYear   setValue:aValue forThemeAttribute:aThemeAttribute];
        [_textFieldHour   setValue:aValue forThemeAttribute:aThemeAttribute];
        [_textFieldMinute setValue:aValue forThemeAttribute:aThemeAttribute];
        [_textFieldSecond setValue:aValue forThemeAttribute:aThemeAttribute];
        [_textFieldPMAM   setValue:aValue forThemeAttribute:aThemeAttribute];
    }
}

- (void)_textFieldSeparatorSetValue:(id)aValue forThemeAttribute:(CPString)aThemeAttribute inState:(CPThemeState)aThemeState
{
    [_textFieldSeparatorOne   setValue:aValue forThemeAttribute:aThemeAttribute inState:aThemeState];
    [_textFieldSeparatorTwo   setValue:aValue forThemeAttribute:aThemeAttribute inState:aThemeState];
    [_textFieldSeparatorThree setValue:aValue forThemeAttribute:aThemeAttribute inState:aThemeState];
    [_textFieldSeparatorFour  setValue:aValue forThemeAttribute:aThemeAttribute inState:aThemeState];

}

/*! Hide or not the textField depending on the datePickerElements flag
*/
- (void)_updateHiddenTextFields
{
    var datePickerElements = [_datePicker datePickerElements],
        isAmericanFormat = [_datePicker _isAmericanFormat];

    if (datePickerElements & CPYearMonthDatePickerElementFlag)
    {
        [_textFieldDay setHidden:YES];
        [_textFieldMonth setHidden:NO];
        [_textFieldYear setHidden:NO];
        [_textFieldSeparatorTwo setHidden:NO];
        [_textFieldSeparatorOne setHidden:YES];

        if (([datePickerElements & CPYearMonthDayDatePickerElementFlag]) == CPYearMonthDayDatePickerElementFlag)
        {
            [_textFieldDay setHidden:NO];
            [_textFieldSeparatorOne setHidden:NO];
        }
    }
    else
    {
        [_textFieldMonth setHidden:YES];
        [_textFieldYear setHidden:YES];
        [_textFieldDay setHidden:YES];
        [_textFieldSeparatorTwo setHidden:YES];
        [_textFieldSeparatorOne setHidden:YES];
    }

    if (datePickerElements & CPHourMinuteDatePickerElementFlag)
    {
        [_textFieldHour setHidden:NO];
        [_textFieldMinute setHidden:NO];
        [_textFieldSecond setHidden:YES];
        [_textFieldSeparatorThree setHidden:NO];
        [_textFieldSeparatorFour setHidden:YES];

        if (isAmericanFormat)
            [_textFieldPMAM setHidden:NO];
        else
            [_textFieldPMAM setHidden:YES];

        if ((datePickerElements & CPHourMinuteSecondDatePickerElementFlag) == CPHourMinuteSecondDatePickerElementFlag)
        {
            [_textFieldSecond setHidden:NO];
            [_textFieldSeparatorFour setHidden:NO];
        }
    }
    else
    {
        [_textFieldHour setHidden:YES];
        [_textFieldMinute setHidden:YES];
        [_textFieldSecond setHidden:YES];
        [_textFieldSeparatorThree setHidden:YES];
        [_textFieldSeparatorFour setHidden:YES];
        [_textFieldPMAM setHidden:YES];
    }
}

/*! Update the position of the textField depending on the datePickerElements flag
*/
- (void)_updatePositions
{
    var contentInset              = [_datePicker valueForThemeAttribute:@"content-inset" inState:[_datePicker themeState]] || CGInsetMakeZero(),
        separatorContentInset     = [_datePicker valueForThemeAttribute:@"separator-content-inset"],
        timeSeparatorContentInset = [_datePicker valueForThemeAttribute:@"time-separator-content-inset"] || separatorContentInset,
        horizontalInset           = contentInset.left - contentInset.right,
        verticalInset             = contentInset.top - contentInset.bottom,
        firstTextField            = _textFieldMonth,
        secondTextField           = _textFieldDay,
        isAmericanFormat          = [_datePicker _isAmericanFormat];

    if (!isAmericanFormat)
    {
        firstTextField  = _textFieldDay;
        secondTextField = _textFieldMonth;
    }

    // IMPORTANT REMARK
    // The "content-inset" theme parameter was incorrectly used before Aristo3
    // While an inset should shrink a rectangle as indicated by its .top, .right, .bottom and .left components,
    // it was only used to shift origin by (.top - .bottom) and (.left - .right) values.
    // This leads to difficulties for the theme descriptor to correctly specify positionning.
    //
    // In order to ensure compatibility with previous behavior, we use isCSSBased property to
    // branch between new and old behaviors as all themes before Aristo3 use the previous uncorrect computation.

    if (![self isCSSBased])
    {
        [self _deprecatedUpdatePositions];
        return;
    }

    // New behavior of the "content-inset" theme parameter
    var currentFrameWidth,
        newFrame,
        currentX = contentInset.left,
        height   = [self frame].size.height - contentInset.top - contentInset.bottom;

    if (![firstTextField isHidden])
    {
        currentFrameWidth = [firstTextField frame].size.width;
        newFrame          = CGRectMake(currentX, contentInset.top, currentFrameWidth, height);
        currentX         += currentFrameWidth;

        [firstTextField setFrame:newFrame];

        currentFrameWidth = [_textFieldSeparatorOne frame].size.width;
        currentX         += separatorContentInset.left;
        newFrame          = CGRectMake(currentX, contentInset.top, currentFrameWidth, height);
        currentX         += currentFrameWidth;

        [_textFieldSeparatorOne setFrame:newFrame];

        currentX         += separatorContentInset.right;
    }

    [_textFieldSeparatorOne setHidden:[firstTextField isHidden]];

    if (![secondTextField isHidden])
    {
        currentFrameWidth = [secondTextField frame].size.width;
        newFrame          = CGRectMake(currentX, contentInset.top, currentFrameWidth, height);
        currentX         += currentFrameWidth;

        [secondTextField setFrame:newFrame];

        currentFrameWidth = [_textFieldSeparatorTwo frame].size.width;
        currentX         += separatorContentInset.left;
        newFrame          = CGRectMake(currentX, contentInset.top, currentFrameWidth, height);
        currentX         += currentFrameWidth;

        [_textFieldSeparatorTwo setFrame:newFrame];

        currentX         += separatorContentInset.right;
    }

    [_textFieldSeparatorTwo setHidden:[secondTextField isHidden]];

    if (![_textFieldYear isHidden])
    {
        currentFrameWidth = [_textFieldYear frame].size.width;
        newFrame          = CGRectMake(currentX, contentInset.top, currentFrameWidth, height);
        currentX         += currentFrameWidth;

        [_textFieldYear setFrame:newFrame];

        currentX         += [_datePicker currentValueForThemeAttribute:@"date-hour-margin"];
    }

    if (![_textFieldHour isHidden])
    {
        currentFrameWidth = [_textFieldHour frame].size.width;
        newFrame          = CGRectMake(currentX, contentInset.top, currentFrameWidth, height);
        currentX         += currentFrameWidth;

        [_textFieldHour setFrame:newFrame];

        currentFrameWidth = [_textFieldSeparatorThree frame].size.width;
        currentX         += timeSeparatorContentInset.left;
        newFrame          = CGRectMake(currentX, contentInset.top, currentFrameWidth, height);
        currentX         += currentFrameWidth;

        [_textFieldSeparatorThree setFrame:newFrame];

        currentFrameWidth = [_textFieldMinute frame].size.width;
        currentX         += timeSeparatorContentInset.right;
        newFrame          = CGRectMake(currentX, contentInset.top, currentFrameWidth, height);
        currentX         += currentFrameWidth;

        [_textFieldMinute setFrame:newFrame];

        if (![_textFieldSecond isHidden])
        {
            currentFrameWidth = [_textFieldSeparatorFour frame].size.width;
            currentX         += timeSeparatorContentInset.left;
            newFrame          = CGRectMake(currentX, contentInset.top, currentFrameWidth, height);
            currentX         += currentFrameWidth;

            [_textFieldSeparatorFour setFrame:newFrame];

            currentFrameWidth = [_textFieldSecond frame].size.width;
            currentX         += timeSeparatorContentInset.right;
            newFrame          = CGRectMake(currentX, contentInset.top, currentFrameWidth, height);
            currentX         += currentFrameWidth;

            [_textFieldSecond setFrame:newFrame];
        }

        if (![_textFieldPMAM isHidden])
        {
            currentFrameWidth = [_textFieldPMAM frame].size.width;
            currentX         += [_datePicker currentValueForThemeAttribute:@"hour-ampm-margin"];
            newFrame          = CGRectMake(currentX, contentInset.top, currentFrameWidth, height);

            [_textFieldPMAM setFrame:newFrame];
        }
    }
}

// Old behavior of the "content-inset" theme parameter
- (void)_deprecatedUpdatePositions
{
    var contentInset              = [_datePicker valueForThemeAttribute:@"content-inset" inState:[_datePicker themeState]] || CGInsetMakeZero(),
        separatorContentInset     = [_datePicker valueForThemeAttribute:@"separator-content-inset"],
        timeSeparatorContentInset = [_datePicker valueForThemeAttribute:@"time-separator-content-inset"] || separatorContentInset,
        horizontalInset           = contentInset.left - contentInset.right,
        verticalInset             = contentInset.top - contentInset.bottom,
        firstTextField            = _textFieldMonth,
        secondTextField           = _textFieldDay,
        isAmericanFormat          = [_datePicker _isAmericanFormat];

    if (!isAmericanFormat)
    {
        firstTextField  = _textFieldDay;
        secondTextField = _textFieldMonth;
    }

    [firstTextField setFrameOrigin:CGPointMake(horizontalInset,verticalInset)];

    [_textFieldSeparatorOne setFrameOrigin:CGPointMake(CGRectGetMaxX([firstTextField frame]) + separatorContentInset.left, verticalInset)];

    if ([firstTextField isHidden])
        [secondTextField setFrameOrigin:CGPointMake(horizontalInset,verticalInset)];
    else
        [secondTextField setFrameOrigin:CGPointMake(CGRectGetMaxX([_textFieldSeparatorOne frame]) + separatorContentInset.right, verticalInset)];

    if (isAmericanFormat && [secondTextField isHidden])
        [_textFieldSeparatorTwo setFrameOrigin:CGPointMake(CGRectGetMaxX([firstTextField frame]) + separatorContentInset.left, verticalInset)];
    else
        [_textFieldSeparatorTwo setFrameOrigin:CGPointMake(CGRectGetMaxX([secondTextField frame]) + separatorContentInset.left, verticalInset)];

    [_textFieldYear setFrameOrigin:CGPointMake(CGRectGetMaxX([_textFieldSeparatorTwo frame]) + separatorContentInset.right, verticalInset)];

    if ([_textFieldMonth isHidden])
        [_textFieldHour setFrameOrigin:CGPointMake(horizontalInset, verticalInset)];
    else
        [_textFieldHour setFrameOrigin:CGPointMake(CGRectGetMaxX([_textFieldYear frame]) + [_datePicker currentValueForThemeAttribute:@"date-hour-margin"], verticalInset)];

    [_textFieldSeparatorThree setFrameOrigin:CGPointMake(CGRectGetMaxX([_textFieldHour frame]) + separatorContentInset.left, verticalInset)];
    [_textFieldMinute setFrameOrigin:CGPointMake(CGRectGetMaxX([_textFieldSeparatorThree frame]) + separatorContentInset.right, verticalInset)];
    [_textFieldSeparatorFour setFrameOrigin:CGPointMake(CGRectGetMaxX([_textFieldMinute frame]) + separatorContentInset.left, verticalInset)];
    [_textFieldSecond setFrameOrigin:CGPointMake(CGRectGetMaxX([_textFieldSeparatorFour frame]) + separatorContentInset.right, verticalInset)];

    if ([_textFieldSecond isHidden])
        [_textFieldPMAM setFrameOrigin:CGPointMake(CGRectGetMaxX([_textFieldMinute frame]) + 2, verticalInset)];
    else
        [_textFieldPMAM setFrameOrigin:CGPointMake(CGRectGetMaxX([_textFieldSecond frame]) + 2, verticalInset)];
}

/*! Size to fit all of the textFields
*/
- (void)_sizeToFit
{
    [_textFieldDay sizeToFit];
    [_textFieldMonth sizeToFit];
    [_textFieldYear sizeToFit];
    [_textFieldHour sizeToFit];
    [_textFieldMinute sizeToFit];
    [_textFieldSecond sizeToFit];
    [_textFieldSeparatorOne sizeToFit];
    [_textFieldSeparatorTwo sizeToFit];
    [_textFieldSeparatorThree sizeToFit];
    [_textFieldSeparatorFour sizeToFit];
    [_textFieldPMAM sizeToFit];
}

/*! Size to fit all of the textFields
*/
- (void)_setControlSizes
{
    var controlSize = [_datePicker controlSize];

    [_textFieldDay setControlSize:controlSize];
    [_textFieldMonth setControlSize:controlSize];
    [_textFieldYear setControlSize:controlSize];
    [_textFieldHour setControlSize:controlSize];
    [_textFieldMinute setControlSize:controlSize];
    [_textFieldSecond setControlSize:controlSize];
    [_textFieldSeparatorOne setControlSize:controlSize];
    [_textFieldSeparatorTwo setControlSize:controlSize];
    [_textFieldSeparatorThree setControlSize:controlSize];
    [_textFieldSeparatorFour setControlSize:controlSize];
    [_textFieldPMAM setControlSize:controlSize];
}


#pragma mark -
#pragma mark Responder methods

- (void)_updateResponderTextField
{
    [self _updateFirstLastTextField];
    [self _updateKeyView];
}

/*! Update the var _firstTextField and _lastTextField
*/
- (void)_updateFirstLastTextField
{
    var datePickerElements = [_datePicker datePickerElements];

    if ([_datePicker _isAmericanFormat])
    {
        if (datePickerElements & CPYearMonthDayDatePickerElementFlag || datePickerElements & CPYearMonthDatePickerElementFlag)
            [[self superview] setFirstTextField:_textFieldMonth];
        else
            [[self superview] setFirstTextField:_textFieldHour];

        if (datePickerElements & CPHourMinuteSecondDatePickerElementFlag || datePickerElements & CPHourMinuteDatePickerElementFlag)
            [[self superview] setLastTextField:_textFieldPMAM];
        else
            [[self superview] setLastTextField:_textFieldYear];
    }
    else
    {
        if ((datePickerElements & CPYearMonthDayDatePickerElementFlag) == CPYearMonthDayDatePickerElementFlag)
            [[self superview] setFirstTextField:_textFieldDay];
        else if (datePickerElements & CPYearMonthDayDatePickerElementFlag || datePickerElements & CPYearMonthDatePickerElementFlag)
            [[self superview] setFirstTextField:_textFieldMonth];
        else
            [[self superview] setFirstTextField:_textFieldHour];

        if ((datePickerElements & CPHourMinuteSecondDatePickerElementFlag) == CPHourMinuteSecondDatePickerElementFlag)
            [[self superview] setLastTextField:_textFieldSecond];
        else if (datePickerElements & CPHourMinuteSecondDatePickerElementFlag || datePickerElements & CPHourMinuteDatePickerElementFlag)
            [[self superview] setLastTextField:_textFieldMinute];
        else
            [[self superview] setLastTextField:_textFieldYear];
    }
}

/*! Update the nextTextField params of all of the textField. This is used to move the current textField with the arrows
*/
- (void)_updateKeyView
{
    [self _updateNextTextField];
    [self _updatePreviousTextField]
}

- (void)_updateNextTextField
{
    var datePickerElements = [_datePicker datePickerElements],
        firstTexField = _textFieldMonth,
        secondTextField = _textFieldDay,
        isAmericanFormat = [_datePicker _isAmericanFormat];

    if (!isAmericanFormat)
    {
        firstTexField = _textFieldDay;
        secondTextField = _textFieldMonth;
    }

    if ((datePickerElements & CPYearMonthDayDatePickerElementFlag) == CPYearMonthDayDatePickerElementFlag)
        [firstTexField setNextTextField:secondTextField];
    else
        [firstTexField setNextTextField:_textFieldYear];

    [secondTextField setNextTextField:_textFieldYear];

    if (datePickerElements & CPHourMinuteSecondDatePickerElementFlag || datePickerElements & CPHourMinuteDatePickerElementFlag)
        [_textFieldYear setNextTextField:_textFieldHour];
    else if (isAmericanFormat || (datePickerElements & CPYearMonthDayDatePickerElementFlag) == CPYearMonthDayDatePickerElementFlag)
        [_textFieldYear setNextTextField:firstTexField];
    else
        [_textFieldYear setNextTextField:secondTextField];

    [_textFieldHour setNextTextField:_textFieldMinute];

    if ((datePickerElements & CPHourMinuteSecondDatePickerElementFlag) == CPHourMinuteSecondDatePickerElementFlag)
        [_textFieldMinute setNextTextField:_textFieldSecond];
    else if (isAmericanFormat)
        [_textFieldMinute setNextTextField:_textFieldPMAM];
    else if ((datePickerElements & CPYearMonthDayDatePickerElementFlag) == CPYearMonthDayDatePickerElementFlag)
        [_textFieldMinute setNextTextField:firstTexField];
    else if (datePickerElements & CPYearMonthDatePickerElementFlag)
        [_textFieldMinute setNextTextField:secondTextField];
    else
        [_textFieldMinute setNextTextField:_textFieldHour];

    if (isAmericanFormat)
        [_textFieldSecond setNextTextField:_textFieldPMAM];
    else if ((datePickerElements & CPYearMonthDayDatePickerElementFlag) == CPYearMonthDayDatePickerElementFlag)
        [_textFieldSecond setNextTextField:firstTexField];
    else if (datePickerElements & CPYearMonthDatePickerElementFlag)
        [_textFieldSecond setNextTextField:secondTextField];
    else
        [_textFieldSecond setNextTextField:_textFieldHour];

    if (datePickerElements & CPYearMonthDayDatePickerElementFlag)
        [_textFieldPMAM setNextTextField:_textFieldMonth];
    else
        [_textFieldPMAM setNextTextField:_textFieldHour];
}

- (void)_updatePreviousTextField
{
    var datePickerElements = [_datePicker datePickerElements],
        firstTexField = _textFieldMonth,
        secondTextField = _textFieldDay,
        isAmericanFormat = [_datePicker _isAmericanFormat];

    if (!isAmericanFormat)
    {
        firstTexField = _textFieldDay;
        secondTextField = _textFieldMonth;
    }

    if ((datePickerElements & CPHourMinuteSecondDatePickerElementFlag) == CPHourMinuteSecondDatePickerElementFlag)
        [_textFieldPMAM setPreviousTextField:_textFieldSecond];
    else if (datePickerElements & CPHourMinuteDatePickerElementFlag)
        [_textFieldPMAM setPreviousTextField:_textFieldMinute];

    [_textFieldSecond setPreviousTextField:_textFieldMinute];
    [_textFieldMinute setPreviousTextField:_textFieldHour];

    if (datePickerElements & CPYearMonthDatePickerElementFlag)
        [_textFieldHour setPreviousTextField:_textFieldYear];
    else if (isAmericanFormat)
        [_textFieldHour setPreviousTextField:_textFieldPMAM];
    else if ((datePickerElements & CPHourMinuteSecondDatePickerElementFlag) == CPHourMinuteSecondDatePickerElementFlag)
        [_textFieldHour setPreviousTextField:_textFieldSecond];
    else
        [_textFieldHour setPreviousTextField:_textFieldMinute];

    if (!isAmericanFormat)
        [_textFieldYear setPreviousTextField:_textFieldMonth];
    else if ((datePickerElements & CPYearMonthDayDatePickerElementFlag) == CPYearMonthDayDatePickerElementFlag)
        [_textFieldYear setPreviousTextField:_textFieldDay];
    else
        [_textFieldYear setPreviousTextField:_textFieldMonth];

    [secondTextField setPreviousTextField:firstTexField];

    if (isAmericanFormat && datePickerElements & CPHourMinuteDatePickerElementFlag)
        [firstTexField setPreviousTextField:_textFieldPMAM];
    else if ((datePickerElements & CPHourMinuteSecondDatePickerElementFlag) == CPHourMinuteSecondDatePickerElementFlag)
        [firstTexField setPreviousTextField:_textFieldSecond];
    else if (datePickerElements & CPHourMinuteDatePickerElementFlag)
        [firstTexField setPreviousTextField:_textFieldMinute];
    else
        [firstTexField setPreviousTextField:_textFieldYear];
}

@end
