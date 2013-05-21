/* _CPDatePickerTextField.j
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
@import "CPStepper.j"

@import <Foundation/CPArray.j>
@import <Foundation/CPObject.j>
@import <Foundation/CPDate.j>
@import <Foundation/CPDateFormatter.j>
@import <Foundation/CPLocale.j>

@class CPDatePicker

@global CPSingleDateMode
@global CPRangeDateMode

@global CPTextFieldAndStepperDatePickerStyle
@global CPClockAndCalendarDatePickerStyle
@global CPTextFieldDatePickerStyle

@global CPHourMinuteDatePickerElementFlag
@global CPHourMinuteSecondDatePickerElementFlag
@global CPTimeZoneDatePickerElementFlag
@global CPYearMonthDatePickerElementFlag
@global CPYearMonthDayDatePickerElementFlag
@global CPEraDatePickerElementFlag

var CPDatePickerElementTextFieldBecomeFirstResponder = @"CPDatePickerElementTextFieldBecomeFirstResponder",
    CPDatePickerElementTextFieldAMPMChangedNotification = @"CPDatePickerElementTextFieldAMPMChangedNotification";

var CPZeroKeyCode = 48,
    CPNineKeyCode = 57,
    CPMajAKeyCode = 65,
    CPMajPKeyCode = 80,
    CPAKeyCode = 97,
    CPPKeyCode = 112;

// This class is used to represente the datePicker with the CPTextFieldAndStepperDatePickerStyle/CPTextFieldDatePickerStyle mode
@implementation _CPDatePickerTextField : CPControl
{
    _CPDatePickerElementTextField       _firstTextField @accessors(property=firstTextField);
    _CPDatePickerElementTextField       _lastTextField @accessors(property=lastTextField);

    _CPDatePickerElementTextField       _currentTextField;
    _CPDatePickerElementView            _datePickerElementView;
    CPDatePicker                        _datePicker;
    CPStepper                           _stepper;
    CPTimer                             _timerEdition;
}


#pragma mark -
#pragma mark Init

- (id)initWithFrame:(CGRect)aFrame withDatePicker:(CPDatePicker)aDatePicker
{
    if (self = [super initWithFrame:aFrame])
    {
        _datePicker = aDatePicker
        [self _init];
    }
    return self;
}

- (void)_init
{
    _datePickerElementView = [[_CPDatePickerElementView alloc] initWithFrame:CGRectMakeZero() withDatePicker:_datePicker];
    [self addSubview:_datePickerElementView];

    _stepper = [CPStepper stepper];
    [_stepper setTarget:self];
    [_stepper setAction:@selector(_clickStepper:)];
    [self addSubview:_stepper];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_datePickerElementTextFieldBecomeFirstResponder:) name:CPDatePickerElementTextFieldBecomeFirstResponder object:self];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}


#pragma mark -
#pragma mark Responder methods

- (BOOL)becomeFirstResponder
{
    return NO;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)resignFirstResponder
{
    // End the timer of editing
    [self _endTimer];

    // Don't forget to unbind, otherwise several steppers will increase or decrease
    [_currentTextField unbind:@"objectValue"];
    [_currentTextField makeDeselectable];
    _currentTextField = nil

    // This is usefull when clicking on the stepper when the datePicker is not selected
    [_stepper setObjectValue:0];

    return YES;
}


#pragma mark -
#pragma mark Setter Getter methods


/*! Set the value of the control
    @param aDateValue
*/
- (void)setDateValue:(CPDate)aDateValue
{
    var dateValue = [aDateValue copy];
    [dateValue _dateWithTimeZone:[_datePicker timeZone]];

    [_datePickerElementView setDateValue:dateValue];
}

/*! Set the widget enabled or not
    @param aBoolean
*/
- (void)setEnabled:(BOOL)aBoolean
{
    [super setEnabled:aBoolean];
    [_stepper setEnabled:aBoolean];
    [_datePickerElementView setEnabled:aBoolean];
}


#pragma mark -
#pragma mark Notification methods

/*! This is called to when the user just changed the selected textField
    @param aNotification
*/
- (void)_datePickerElementTextFieldBecomeFirstResponder:(CPNotification)aNotification
{
    if ([[aNotification userInfo] objectForKey:@"textField"] == _currentTextField)
        return;

    [self _selectTextField:[[aNotification userInfo] objectForKey:@"textField"]];

    // This is tricky, its to avoid to have the cursor
    if ([[self window] firstResponder] != _datePicker)
        [[self window] makeFirstResponder:_datePicker];
}


#pragma mark -
#pragma mark SelectTextField action

- (void)_selecteTextFieldWithFlags:(unsigned)flags
{
    [_datePickerElementView _updateResponderTextField];

    // We select the firstTextField when the datePicker becomes firstResponder if _currentTextField is null. It can be null just when using tab
    if (!_currentTextField)
    {
        if (flags & CPShiftKeyMask)
            [self _selectTextField:_lastTextField];
        else
            [self _selectTextField:_firstTextField];
    }

}

/*! Select a textField
    @param aDatePickerElementTextField the textField
*/
- (void)_selectTextField:(_CPDatePickerElementTextField)aDatePickerElementTextField
{
    if (_currentTextField == aDatePickerElementTextField)
        return;

    // End the timer of editing
    [self _endTimer];

    // Don't forget to unbind, otherwise several steppers will increase or decrease
    [_currentTextField unbind:@"objectValue"];
    [_currentTextField makeDeselectable];

    _currentTextField = aDatePickerElementTextField;
    [_currentTextField makeSelectable];

    // We cannot assign a value with the textField AM/PM
    if ([_currentTextField dateType] != CPAMPMDateType)
    {
        // We update the value of the stepper dependind on the textField
        [_stepper setObjectValue:parseInt([_currentTextField objectValue])];
        [_stepper setMaxValue:[_currentTextField maxNumber]];
        [_stepper setMinValue:[_currentTextField minNumber]];

        // We bind the stepper with textField
        [_currentTextField bind:@"objectValue" toObject:_stepper withKeyPath:@"objectValue" options:nil];
    }
}


#pragma mark -
#pragma mark Events

/*! Called when the user click on the stepper
*/
- (void)_clickStepper:(id)sender
{
    // Success when clicking on the stepper if the datePicker is not selected
    if ([[self window] firstResponder] != _datePicker || !_currentTextField)
    {
        var isUp = NO;

        if ([sender objectValue] == 1)
            isUp = YES;

        [self _selectTextField:_firstTextField];
        [[self window] makeFirstResponder:_datePicker];

        // This gonna update the dateValue with the binding
        if (isUp)
            [_stepper setDoubleValue:parseInt([_currentTextField objectValue]) + 1];
        else
            [_stepper setDoubleValue:parseInt([_currentTextField objectValue]) - 1];

        return;
    }

    if ([_currentTextField dateType] != CPAMPMDateType)
    {
        // Make sure to get the good value, especially when we reach the maxDate or minDate
        [sender setDoubleValue:parseInt([_currentTextField objectValue])];
    }
    else
    {
        // AM/PM behavior
        if ([[_currentTextField stringValue] isEqualToString:@"PM"])
            [_currentTextField setStringValue:@"AM"];
        else
            [_currentTextField setStringValue:@"PM"];

        [[CPNotificationCenter defaultCenter] postNotificationName:CPDatePickerElementTextFieldAMPMChangedNotification object:_currentTextField userInfo:nil];
    }
}

/*! performKeyEquivalent event
    Used for moving in the textField
*/
- (BOOL)performKeyEquivalent:(CPEvent)anEvent
{
    if (![self isEnabled] || !_currentTextField || [[self window] firstResponder] != _datePicker)
        return NO;

    var key = [anEvent charactersIgnoringModifiers];

    if (key == CPUpArrowFunctionKey)
    {
        [self _endTimer];
        [_stepper setDoubleValue:parseInt([_currentTextField objectValue])];
        [_stepper performClickUp:self];
        return YES;
    }

    if (key == CPDownArrowFunctionKey)
    {
        [self _endTimer];
        [_stepper setDoubleValue:parseInt([_currentTextField objectValue])];
        [_stepper performClickDown:self];
        return YES;
    }

    if (key == CPLeftArrowFunctionKey || [anEvent keyCode] == CPTabKeyCode && [anEvent modifierFlags] & CPShiftKeyMask)
    {
        if (_currentTextField == _firstTextField && [anEvent keyCode] == CPTabKeyCode)
        {
            if ([_datePicker previousKeyView])
                [[self window] makeFirstResponder:[_datePicker previousKeyView]];

            return YES;
        }

        [self _selectTextField:[_currentTextField previousTextField]];
        return YES;
    }

    if (key == CPRightArrowFunctionKey || [anEvent keyCode] == CPTabKeyCode)
    {

        if (_currentTextField == _lastTextField && [anEvent keyCode] == CPTabKeyCode)
        {
            if ([_datePicker nextKeyView])
                [[self window] makeFirstResponder:[_datePicker nextKeyView]];

            return YES;

        } [self _selectTextField:[_currentTextField nextTextField]]; return YES; }

    if ([anEvent keyCode] == CPReturnKeyCode && _timerEdition)
    {
        [_timerEdition fire];
        return YES;
    }

    return NO;
}

/*! KeyDown event
    We just care care about the event A/P and every numbers
*/
- (void)keyDown:(CPEvent)anEvent
{
    if (![self isEnabled])
        return;

    if ([_datePicker _isEnglishFormat] && [_currentTextField dateType] == CPAMPMDateType && ([anEvent keyCode] == CPAKeyCode || [anEvent keyCode] == CPPKeyCode || [anEvent keyCode] == CPMajAKeyCode || [anEvent keyCode] == CPMajPKeyCode))
    {
        if ([anEvent keyCode] == CPAKeyCode || [anEvent keyCode] == CPMajAKeyCode)
            [_currentTextField setStringValue:@"AM"];
        else
            [_currentTextField setStringValue:@"PM"];

        [[CPNotificationCenter defaultCenter] postNotificationName:CPDatePickerElementTextFieldAMPMChangedNotification object:_currentTextField userInfo:nil];

        return;
    }

    if ([anEvent keyCode] != CPDeleteKeyCode && [anEvent keyCode] != CPDeleteForwardKeyCode  && [anEvent keyCode] < CPZeroKeyCode || [anEvent keyCode] > CPNineKeyCode)
        return;

    // Here, at the first editing we launch a timer to auto-finish the editing. There is another behavior when the user has already edited something
    if (!_timerEdition)
    {
         _timerEdition = [CPTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(_timerKeyEvent:) userInfo:nil repeats:NO];

         // Take care about the delete key
         if ([anEvent keyCode] == CPDeleteKeyCode || [anEvent keyCode] == CPDeleteForwardKeyCode)
             [_currentTextField setStringKeyValue:@""];
         else
             [_currentTextField setStringKeyValue:[anEvent characters]];
    }
    else
    {
        var newFireDate = [CPDate date],
            key;

        newFireDate.setSeconds(newFireDate.getSeconds() + 2);

        [_timerEdition setFireDate:newFireDate];

        // Take care about the delete key
        if ([anEvent keyCode] == CPDeleteKeyCode || [anEvent keyCode] == CPDeleteForwardKeyCode)
            key = [[_currentTextField stringValue] substringToIndex:[[_currentTextField stringValue] length] - 1];
        else
            key = [CPString stringWithFormat:@"%i%i",parseInt([_currentTextField stringValue]), parseInt([anEvent characters])];

        [_currentTextField setStringKeyValue:key];
    }
}


#pragma mark -
#pragma mark Timer event

/*! End of the timer
*/
- (void)_timerKeyEvent:(id)sender
{
    _timerEdition = nil;

    if (![[_currentTextField stringValue] isEqualToString:@"  "] && ![[_currentTextField stringValue] isEqualToString:@"    "])
    {
        var value = [_currentTextField stringValue];

        if ([_datePicker _isEnglishFormat] && [_currentTextField dateType] == CPHourDateType)
        {
            if (![_datePickerElementView _isAMHour] && value != 12)
                value = parseInt(value) + 12;

            if (value == 12 && ![_datePickerElementView _isAMHour])
                value = 12;
            else if (value == 12)
                value = 0;
        }

        [_currentTextField setObjectValue:value];
    }
    else
    {
        [_currentTextField setObjectValue:@"0"];
    }


}

/*! We force to end the timer
*/
- (void)_endTimer
{
    if (_timerEdition)
    {
        [_timerEdition invalidate];
        [self _timerKeyEvent:_timerEdition];
        _timerEdition = nil;
    }
}


#pragma mark -
#pragma mark Layout methods

/*! Layout the subviews
*/
- (void)layoutSubviews
{
    if ([_datePicker datePickerStyle] == CPClockAndCalendarDatePickerStyle)
        return;

    [super layoutSubviews];

    var frameSize = CGSizeMakeZero(),
        bezelInset = [_datePicker valueForThemeAttribute:@"bezel-inset" inState:[_datePicker themeState]];

    // Check the mode to display or not the stepper
    if ([_datePicker datePickerStyle] == CPTextFieldAndStepperDatePickerStyle)
    {
        frameSize = CGSizeMake(CGRectGetWidth([_datePicker frame]) - CGRectGetWidth([_stepper frame]) - [_datePicker valueForThemeAttribute:@"stepper-margin"], CGRectGetHeight([_datePicker frame]));

        frameSize.width -= bezelInset.left;
        frameSize.height -= bezelInset.top + bezelInset.bottom;

        [_datePickerElementView setFrameSize:frameSize];
        [_datePickerElementView setFrameOrigin:CGPointMake(bezelInset.left, bezelInset.top)];
        [_stepper setHidden:NO];
    }
    else if ([_datePicker datePickerStyle] == CPTextFieldDatePickerStyle)
    {
        frameSize = CGSizeMake(CGRectGetWidth([_datePicker frame]), CGRectGetHeight([_datePicker frame]));

        frameSize.width -= bezelInset.left + bezelInset.right;
        frameSize.height -= bezelInset.top + bezelInset.bottom;

        [_datePickerElementView setFrameSize:frameSize];
        [_datePickerElementView setFrameOrigin:CGPointMake(bezelInset.left, bezelInset.top)];
        [_stepper setHidden:YES];
    }

    [_stepper setFrameOrigin:CGPointMake(CGRectGetMaxX([_datePickerElementView frame]) + [_datePicker valueForThemeAttribute:@"stepper-margin"], bezelInset.top + CGRectGetHeight([_datePickerElementView frame]) / 2 - CGRectGetHeight([_stepper frame]) / 2)];

    [_datePickerElementView setNeedsLayout];
}

@end


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


#pragma mark -
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
    [self addSubview:_textFieldDay];

    _textFieldMonth = [_CPDatePickerElementTextField new];
    [_textFieldMonth setBezeled:NO];
    [_textFieldMonth setBordered:NO];
    [_textFieldMonth setDateType:CPMonthDateType];
    [_textFieldMonth setDatePicker:_datePicker];
    [_textFieldMonth setAlignment:CPRightTextAlignment];
    [self addSubview:_textFieldMonth];

    _textFieldYear = [_CPDatePickerElementTextField new];
    [_textFieldYear setBezeled:NO];
    [_textFieldYear setBordered:NO];
    [_textFieldYear setDateType:CPYearDateType];
    [_textFieldYear setDatePicker:_datePicker];
    [_textFieldYear setAlignment:CPRightTextAlignment];
    [self addSubview:_textFieldYear];

    _textFieldHour = [_CPDatePickerElementTextField new];
    [_textFieldHour setBezeled:NO];
    [_textFieldHour setBordered:NO];
    [_textFieldHour setDateType:CPHourDateType];
    [_textFieldHour setDatePicker:_datePicker];
    [_textFieldHour setAlignment:CPRightTextAlignment];
    [self addSubview:_textFieldHour];

    _textFieldMinute = [_CPDatePickerElementTextField new];
    [_textFieldMinute setBezeled:NO];
    [_textFieldMinute setBordered:NO];
    [_textFieldMinute setDateType:CPMinuteDateType];
    [_textFieldMinute setDatePicker:_datePicker];
    [_textFieldMinute setAlignment:CPRightTextAlignment];
    [self addSubview:_textFieldMinute];

    _textFieldSecond = [_CPDatePickerElementTextField new];
    [_textFieldSecond setBezeled:NO];
    [_textFieldSecond setBordered:NO];
    [_textFieldSecond setDateType:CPSecondDateType];
    [_textFieldSecond setDatePicker:_datePicker];
    [_textFieldSecond setAlignment:CPRightTextAlignment];
    [self addSubview:_textFieldSecond];

    _textFieldPMAM = [_CPDatePickerElementTextField new];
    [_textFieldPMAM setBezeled:NO];
    [_textFieldPMAM setBordered:NO];
    [_textFieldPMAM setDateType:CPAMPMDateType];
    [_textFieldPMAM setDatePicker:_datePicker];
    [_textFieldPMAM setAlignment:CPRightTextAlignment];
    [self addSubview:_textFieldPMAM];

    _textFieldSeparatorOne = [CPTextField labelWithTitle:@"/"];
    _textFieldSeparatorTwo = [CPTextField labelWithTitle:@"/"];
    _textFieldSeparatorThree = [CPTextField labelWithTitle:@":"];
    _textFieldSeparatorFour = [CPTextField labelWithTitle:@":"];

    [self addSubview: _textFieldSeparatorOne];
    [self addSubview: _textFieldSeparatorTwo];
    [self addSubview: _textFieldSeparatorThree];
    [self addSubview: _textFieldSeparatorFour];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_datePickerElementTextFieldAMPMChangedNotification:) name:CPDatePickerElementTextFieldAMPMChangedNotification object:_textFieldPMAM];

    [self setNeedsLayout];
}


#pragma mark -
#pragma mark Responder methods

- (BOOL)acceptFirstResponder
{
    return NO;
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

/*! Return YES if the hour is set to the morning
*/
- (BOOL)_isAMHour
{
    return [[_textFieldPMAM stringValue] isEqualToString:@"AM"];
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

    [_datePicker setDateValue:dateValue];
}


#pragma mark -
#pragma mark Layout methods

- (void)layoutSubviews
{
    if ([_datePicker datePickerStyle] == CPClockAndCalendarDatePickerStyle)
        return;

    [super layoutSubviews];

    var themeState = [_datePicker themeState];

    if ([_datePicker isBezeled] && [_datePicker drawsBackground] || [_datePicker isBordered] && [_datePicker drawsBackground])
        [self setBackgroundColor:[_datePicker valueForThemeAttribute:@"bezel-color" inState:themeState]];
    else if ([_datePicker drawsBackground])
        [self setBackgroundColor:[_datePicker backgroundColor]];
    else
        [self setBackgroundColor:[CPColor clearColor]];

    [self _themeTextFields];

    [self _updateResponderTextField];
    [self _updateHiddenTextFields];
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
    [_textFieldDay setValue:[_datePicker valueForThemeAttribute:@"min-size-datepicker-textfield"] forThemeAttribute:@"min-size"];
    [_textFieldDay setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield" inState:CPThemeStateNormal] forThemeAttribute:@"content-inset" inState:CPThemeStateNormal];
    [_textFieldDay setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield" inState:CPThemeStateSelected] forThemeAttribute:@"content-inset" inState:CPThemeStateSelected];
    [_textFieldDay setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateSelected] forThemeAttribute:@"bezel-color" inState:CPThemeStateSelected];
    [_textFieldDay setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateSelected];
    [_textFieldDay setValue:[_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateSelected] forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
    [_textFieldDay setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected];
    [_textFieldDay setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateSelected] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateSelected];
    [_textFieldDay setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateNormal] forThemeAttribute:@"bezel-color" inState:CPThemeStateNormal];
    [_textFieldDay setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateNormal];
    [_textFieldDay setValue:[_datePicker textColor] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
    [_textFieldDay setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [_textFieldDay setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];
    [_textFieldDay setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateDisabled] forThemeAttribute:@"bezel-color" inState:CPThemeStateDisabled];
    [_textFieldDay setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateDisabled];
    [_textFieldDay setValue:[_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
    [_textFieldDay setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled];
    [_textFieldDay setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled];

    [_textFieldMonth setValue:[_datePicker valueForThemeAttribute:@"min-size-datepicker-textfield"] forThemeAttribute:@"min-size"];
    [_textFieldMonth setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield" inState:CPThemeStateNormal] forThemeAttribute:@"content-inset" inState:CPThemeStateNormal];
    [_textFieldMonth setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield" inState:CPThemeStateSelected] forThemeAttribute:@"content-inset" inState:CPThemeStateSelected];
    [_textFieldMonth setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateSelected] forThemeAttribute:@"bezel-color" inState:CPThemeStateSelected];
    [_textFieldMonth setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateSelected];
    [_textFieldMonth setValue:[_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateSelected] forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
    [_textFieldMonth setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected];
    [_textFieldMonth setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateSelected] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateSelected];
    [_textFieldMonth setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateNormal] forThemeAttribute:@"bezel-color" inState:CPThemeStateNormal];
    [_textFieldMonth setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateNormal];
    [_textFieldMonth setValue:[_datePicker textColor] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
    [_textFieldMonth setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [_textFieldMonth setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];
    [_textFieldMonth setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateDisabled] forThemeAttribute:@"bezel-color" inState:CPThemeStateDisabled];
    [_textFieldMonth setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateDisabled];
    [_textFieldMonth setValue:[_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
    [_textFieldMonth setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled];
    [_textFieldMonth setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled];

    [_textFieldYear setValue:[_datePicker valueForThemeAttribute:@"min-size-datepicker-textfield"] forThemeAttribute:@"min-size"];
    [_textFieldYear setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield" inState:CPThemeStateNormal] forThemeAttribute:@"content-inset" inState:CPThemeStateNormal];
    [_textFieldYear setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield" inState:CPThemeStateSelected] forThemeAttribute:@"content-inset" inState:CPThemeStateSelected];
    [_textFieldYear setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateSelected] forThemeAttribute:@"bezel-color" inState:CPThemeStateSelected];
    [_textFieldYear setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateSelected];
    [_textFieldYear setValue:[_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateSelected] forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
    [_textFieldYear setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected];
    [_textFieldYear setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateSelected] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateSelected];
    [_textFieldYear setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateNormal] forThemeAttribute:@"bezel-color" inState:CPThemeStateNormal];
    [_textFieldYear setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateNormal];
    [_textFieldYear setValue:[_datePicker textColor] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
    [_textFieldYear setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [_textFieldYear setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];
    [_textFieldYear setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateDisabled] forThemeAttribute:@"bezel-color" inState:CPThemeStateDisabled];
    [_textFieldYear setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateDisabled];
    [_textFieldYear setValue:[_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
    [_textFieldYear setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled];
    [_textFieldYear setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled];

    [_textFieldHour setValue:[_datePicker valueForThemeAttribute:@"min-size-datepicker-textfield"] forThemeAttribute:@"min-size"];
    [_textFieldHour setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield" inState:CPThemeStateNormal] forThemeAttribute:@"content-inset" inState:CPThemeStateNormal];
    [_textFieldHour setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield" inState:CPThemeStateSelected] forThemeAttribute:@"content-inset" inState:CPThemeStateSelected];
    [_textFieldHour setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateSelected] forThemeAttribute:@"bezel-color" inState:CPThemeStateSelected];
    [_textFieldHour setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateSelected];
    [_textFieldHour setValue:[_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateSelected] forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
    [_textFieldHour setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected];
    [_textFieldHour setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateSelected] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateSelected];
    [_textFieldHour setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateNormal] forThemeAttribute:@"bezel-color" inState:CPThemeStateNormal];
    [_textFieldHour setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateNormal];
    [_textFieldHour setValue:[_datePicker textColor] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
    [_textFieldHour setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [_textFieldHour setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];
    [_textFieldHour setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateDisabled] forThemeAttribute:@"bezel-color" inState:CPThemeStateDisabled];
    [_textFieldHour setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateDisabled];
    [_textFieldHour setValue:[_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
    [_textFieldHour setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled];
    [_textFieldHour setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled];

    [_textFieldMinute setValue:[_datePicker valueForThemeAttribute:@"min-size-datepicker-textfield"] forThemeAttribute:@"min-size"];
    [_textFieldMinute setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield" inState:CPThemeStateNormal] forThemeAttribute:@"content-inset" inState:CPThemeStateNormal];
    [_textFieldMinute setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield" inState:CPThemeStateSelected] forThemeAttribute:@"content-inset" inState:CPThemeStateSelected];
    [_textFieldMinute setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateSelected] forThemeAttribute:@"bezel-color" inState:CPThemeStateSelected];
    [_textFieldMinute setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateSelected];
    [_textFieldMinute setValue:[_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateSelected] forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
    [_textFieldMinute setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected];
    [_textFieldMinute setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateSelected] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateSelected];
    [_textFieldMinute setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateNormal] forThemeAttribute:@"bezel-color" inState:CPThemeStateNormal];
    [_textFieldMinute setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateNormal];
    [_textFieldMinute setValue:[_datePicker textColor] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
    [_textFieldMinute setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [_textFieldMinute setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];
    [_textFieldMinute setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateDisabled] forThemeAttribute:@"bezel-color" inState:CPThemeStateDisabled];
    [_textFieldMinute setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateDisabled];
    [_textFieldMinute setValue:[_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
    [_textFieldMinute setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled];
    [_textFieldMinute setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled];

    [_textFieldSecond setValue:[_datePicker valueForThemeAttribute:@"min-size-datepicker-textfield"] forThemeAttribute:@"min-size"];
    [_textFieldSecond setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield" inState:CPThemeStateNormal] forThemeAttribute:@"content-inset" inState:CPThemeStateNormal];
    [_textFieldSecond setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield" inState:CPThemeStateSelected] forThemeAttribute:@"content-inset" inState:CPThemeStateSelected];
    [_textFieldSecond setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateSelected] forThemeAttribute:@"bezel-color" inState:CPThemeStateSelected];
    [_textFieldSecond setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateSelected];
    [_textFieldSecond setValue:[_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateSelected] forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
    [_textFieldSecond setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected];
    [_textFieldSecond setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateSelected] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateSelected];
    [_textFieldSecond setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateNormal] forThemeAttribute:@"bezel-color" inState:CPThemeStateNormal];
    [_textFieldSecond setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateNormal];
    [_textFieldSecond setValue:[_datePicker textColor] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
    [_textFieldSecond setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [_textFieldSecond setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];
    [_textFieldSecond setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateDisabled] forThemeAttribute:@"bezel-color" inState:CPThemeStateDisabled];
    [_textFieldSecond setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateDisabled];
    [_textFieldSecond setValue:[_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
    [_textFieldSecond setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled];
    [_textFieldSecond setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled];

    [_textFieldPMAM setValue:[_datePicker valueForThemeAttribute:@"min-size-datepicker-textfield"] forThemeAttribute:@"min-size"];
    [_textFieldPMAM setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield" inState:CPThemeStateNormal] forThemeAttribute:@"content-inset" inState:CPThemeStateNormal];
    [_textFieldPMAM setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield" inState:CPThemeStateSelected] forThemeAttribute:@"content-inset" inState:CPThemeStateSelected];
    [_textFieldPMAM setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateSelected] forThemeAttribute:@"bezel-color" inState:CPThemeStateSelected];
    [_textFieldPMAM setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateSelected];
    [_textFieldPMAM setValue:[_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateSelected] forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
    [_textFieldPMAM setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected];
    [_textFieldPMAM setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateSelected] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateSelected];
    [_textFieldPMAM setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateNormal] forThemeAttribute:@"bezel-color" inState:CPThemeStateNormal];
    [_textFieldPMAM setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateNormal];
    [_textFieldPMAM setValue:[_datePicker textColor] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
    [_textFieldPMAM setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [_textFieldPMAM setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];
    [_textFieldPMAM setValue:[_datePicker valueForThemeAttribute:@"datepicker-textfield-bezel-color" inState:CPThemeStateDisabled] forThemeAttribute:@"bezel-color" inState:CPThemeStateDisabled];
    [_textFieldPMAM setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateDisabled];
    [_textFieldPMAM setValue:[_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
    [_textFieldPMAM setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled];
    [_textFieldPMAM setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled];

    [_textFieldSeparatorOne setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield-separator" inState:CPThemeStateNormal] forThemeAttribute:@"content-inset" inState:CPThemeStateNormal];
    [_textFieldSeparatorOne setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield-separator" inState:CPThemeStateSelected] forThemeAttribute:@"content-inset" inState:CPThemeStateSelected];
    [_textFieldSeparatorOne setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateNormal];
    [_textFieldSeparatorOne setValue:[_datePicker textColor] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
    [_textFieldSeparatorOne setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [_textFieldSeparatorOne setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];
    [_textFieldSeparatorOne setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateDisabled];
    [_textFieldSeparatorOne setValue:[_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
    [_textFieldSeparatorOne setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled];
    [_textFieldSeparatorOne setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled];

    [_textFieldSeparatorTwo setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield-separator" inState:CPThemeStateNormal] forThemeAttribute:@"content-inset" inState:CPThemeStateNormal];
    [_textFieldSeparatorTwo setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield-separator" inState:CPThemeStateSelected] forThemeAttribute:@"content-inset" inState:CPThemeStateSelected];
    [_textFieldSeparatorTwo setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateNormal];
    [_textFieldSeparatorTwo setValue:[_datePicker textColor] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
    [_textFieldSeparatorTwo setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [_textFieldSeparatorTwo setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];
    [_textFieldSeparatorTwo setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateDisabled];
    [_textFieldSeparatorTwo setValue:[_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
    [_textFieldSeparatorTwo setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled];
    [_textFieldSeparatorTwo setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled];

    [_textFieldSeparatorThree setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield-separator" inState:CPThemeStateNormal] forThemeAttribute:@"content-inset" inState:CPThemeStateNormal];
    [_textFieldSeparatorThree setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield-separator" inState:CPThemeStateSelected] forThemeAttribute:@"content-inset" inState:CPThemeStateSelected];
    [_textFieldSeparatorThree setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateNormal];
    [_textFieldSeparatorThree setValue:[_datePicker textColor] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
    [_textFieldSeparatorThree setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [_textFieldSeparatorThree setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];
    [_textFieldSeparatorThree setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateDisabled];
    [_textFieldSeparatorThree setValue:[_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
    [_textFieldSeparatorThree setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled];
    [_textFieldSeparatorThree setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled];

    [_textFieldSeparatorFour setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield-separator" inState:CPThemeStateNormal] forThemeAttribute:@"content-inset" inState:CPThemeStateNormal];
    [_textFieldSeparatorFour setValue:[_datePicker valueForThemeAttribute:@"content-inset-datepicker-textfield-separator" inState:CPThemeStateSelected] forThemeAttribute:@"content-inset" inState:CPThemeStateSelected];
    [_textFieldSeparatorFour setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateNormal];
    [_textFieldSeparatorFour setValue:[_datePicker textColor] forThemeAttribute:@"text-color" inState:CPThemeStateNormal];
    [_textFieldSeparatorFour setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [_textFieldSeparatorFour setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];
    [_textFieldSeparatorFour setValue:[_datePicker textFont] forThemeAttribute:@"font" inState:CPThemeStateDisabled];
    [_textFieldSeparatorFour setValue:[_datePicker valueForThemeAttribute:@"text-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-color" inState:CPThemeStateDisabled];
    [_textFieldSeparatorFour setValue:[_datePicker valueForThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateDisabled];
    [_textFieldSeparatorFour setValue:[_datePicker valueForThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled] forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateDisabled];

}

/*! Hide or not the textField depending on the datePickerElements flag
*/
- (void)_updateHiddenTextFields
{
    var datePickerElements = [_datePicker datePickerElements],
        isEnglishFormat = [_datePicker _isEnglishFormat];

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

        if (isEnglishFormat)
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
    var contentInset = [_datePicker valueForThemeAttribute:@"content-inset" inState:[_datePicker themeState]],
        separatorContentInset = [_datePicker valueForThemeAttribute:@"separator-content-inset"],
        horizontalInset = contentInset.left - contentInset.right,
        verticalInset = contentInset.top - contentInset.bottom,
        firstTexField = _textFieldMonth,
        secondTextField = _textFieldDay,
        isEnglishFormat = [_datePicker _isEnglishFormat];

    if (!isEnglishFormat)
    {
        firstTexField = _textFieldDay;
        secondTextField = _textFieldMonth;
    }

    [firstTexField setFrameOrigin:CGPointMake(horizontalInset,verticalInset)];
    [_textFieldSeparatorOne setFrameOrigin:CGPointMake(CGRectGetMaxX([firstTexField frame]) + separatorContentInset.left, verticalInset)];

    if ([firstTexField isHidden])
        [secondTextField setFrameOrigin:CGPointMake(horizontalInset,verticalInset)];
    else
        [secondTextField setFrameOrigin:CGPointMake(CGRectGetMaxX([_textFieldSeparatorOne frame]) + separatorContentInset.right, verticalInset)];

    if (isEnglishFormat && [secondTextField isHidden])
        [_textFieldSeparatorTwo setFrameOrigin:CGPointMake(CGRectGetMaxX([firstTexField frame]) + separatorContentInset.left, verticalInset)];
    else
        [_textFieldSeparatorTwo setFrameOrigin:CGPointMake(CGRectGetMaxX([secondTextField frame]) + separatorContentInset.left, verticalInset)];

    [_textFieldYear setFrameOrigin:CGPointMake(CGRectGetMaxX([_textFieldSeparatorTwo frame]) + separatorContentInset.right, verticalInset)];

    if ([_textFieldMonth isHidden])
        [_textFieldHour setFrameOrigin:CGPointMake(horizontalInset, verticalInset)];
    else
        [_textFieldHour setFrameOrigin:CGPointMake(CGRectGetMaxX([_textFieldYear frame]) + [_datePicker valueForThemeAttribute:@"date-hour-margin"],verticalInset)];

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

    if ([_datePicker _isEnglishFormat])
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
        isEnglishFormat = [_datePicker _isEnglishFormat];

    if (!isEnglishFormat)
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
    else if (isEnglishFormat || (datePickerElements & CPYearMonthDayDatePickerElementFlag) == CPYearMonthDayDatePickerElementFlag)
        [_textFieldYear setNextTextField:firstTexField];
    else
        [_textFieldYear setNextTextField:secondTextField];

    [_textFieldHour setNextTextField:_textFieldMinute];

    if ((datePickerElements & CPHourMinuteSecondDatePickerElementFlag) == CPHourMinuteSecondDatePickerElementFlag)
        [_textFieldMinute setNextTextField:_textFieldSecond];
    else if (isEnglishFormat)
        [_textFieldMinute setNextTextField:_textFieldPMAM];
    else if ((datePickerElements & CPYearMonthDayDatePickerElementFlag) == CPYearMonthDayDatePickerElementFlag)
        [_textFieldMinute setNextTextField:firstTexField];
    else if (datePickerElements & CPYearMonthDatePickerElementFlag)
        [_textFieldMinute setNextTextField:secondTextField];
    else
        [_textFieldMinute setNextTextField:_textFieldHour];

    if (isEnglishFormat)
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
        isEnglishFormat = [_datePicker _isEnglishFormat];

    if (!isEnglishFormat)
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
    else if (isEnglishFormat)
        [_textFieldHour setPreviousTextField:_textFieldPMAM];
    else if ((datePickerElements & CPHourMinuteSecondDatePickerElementFlag) == CPHourMinuteSecondDatePickerElementFlag)
        [_textFieldHour setPreviousTextField:_textFieldSecond];
    else
        [_textFieldHour setPreviousTextField:_textFieldMinute];

    if (!isEnglishFormat)
        [_textFieldYear setPreviousTextField:_textFieldMonth];
    else if ((datePickerElements & CPYearMonthDayDatePickerElementFlag) == CPYearMonthDayDatePickerElementFlag)
        [_textFieldYear setPreviousTextField:_textFieldDay];
    else
        [_textFieldYear setPreviousTextField:_textFieldMonth];

    [secondTextField setPreviousTextField:firstTexField];

    if (isEnglishFormat && datePickerElements & CPHourMinuteDatePickerElementFlag)
        [firstTexField setPreviousTextField:_textFieldPMAM];
    else if ((datePickerElements & CPHourMinuteSecondDatePickerElementFlag) == CPHourMinuteSecondDatePickerElementFlag)
        [firstTexField setPreviousTextField:_textFieldSecond];
    else if (datePickerElements & CPHourMinuteDatePickerElementFlag)
        [firstTexField setPreviousTextField:_textFieldMinute];
    else
        [firstTexField setPreviousTextField:_textFieldYear];
}

@end


var CPMonthDateType = 0,
    CPDayDateType = 1,
    CPYearDateType = 2,
    CPHourDateType = 3,
    CPSecondDateType = 4,
    CPMinuteDateType = 5,
    CPAMPMDateType = 6;

/*! An element textField
*/
@implementation _CPDatePickerElementTextField : CPTextField
{
    _CPDatePickerElementTextField _nextTextField        @accessors(property=nextTextField);
    _CPDatePickerElementTextField _previousTextField    @accessors(property=previousTextField);

    CPDatePicker    _datePicker @accessors(setter=setDatePicker:);

    int _dateType  @accessors(getter=dateType);
    int _maxNumber @accessors(getter=maxNumber);
    int _minNumber @accessors(getter=minNumber);
}


#pragma mark -
#pragma mark Getter Setter methods

- (BOOL)acceptFirstResponder
{
    return NO;
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
- (void)setStringKeyValue:(id)anObjectValue
{
    if (_dateType == CPYearDateType)
    {
        if ([anObjectValue length] > 4)
            return

        while ([anObjectValue length] < 4)
            anObjectValue = " " + anObjectValue;
    }
    else
    {
        if ([anObjectValue length] > 2)
            return

        while ([anObjectValue length] < 2)
            anObjectValue = " " + anObjectValue;
    }

    if (parseInt(anObjectValue) > [self _maxNumberWithMaxDate])
        return;

    if ([_datePicker _isEnglishFormat] && _dateType == CPHourDateType && parseInt(anObjectValue) > 12)
        return;

    [super setObjectValue:anObjectValue];
}

/*! Set the stringValue of the TextField. Add some zeros of there isn't 2/4 letters in the value. It's called at the end of the editing process
    @param aStringValue a CPString
*/
- (void)setStringValue:(id)aStringValue
{
    if (_dateType == CPYearDateType)
    {
        while ([aStringValue length] < 4)
            aStringValue = "0" + aStringValue;
    }
    else if (_dateType != CPAMPMDateType)
    {
        if (_dateType == CPHourDateType && [_datePicker _isEnglishFormat])
        {
            var value = parseInt(aStringValue);

            if (value == 0)
                value = 12;
            else if (value > 12)
                value = value - 12;

            aStringValue = value.toString();
        }

        while ([aStringValue length] < 2)
            aStringValue = "0" + aStringValue;
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
    var dateValue = [[_datePicker dateValue] copy];

    switch (_dateType)
    {
        case CPMonthDateType:

            var dateNextMonth = [dateValue copy];

            dateNextMonth.setDate(1);
            dateNextMonth.setMonth(parseInt(anObjectValue) - 1);

            var numberDayNextMonth = [dateNextMonth _daysInMonth];

            if (numberDayNextMonth < [dateValue _daysInMonth] && dateValue.getDate() > numberDayNextMonth)
                dateValue.setDate(numberDayNextMonth);

            dateValue.setMonth(parseInt(anObjectValue) - 1);
            break;

        case CPDayDateType:
            dateValue.setDate(parseInt(anObjectValue));
            break;

        case CPYearDateType:
            dateValue.setFullYear(parseInt(anObjectValue));
            break;

        case CPHourDateType:
            dateValue.setHours(parseInt(anObjectValue));
            break;

        case CPSecondDateType:
            dateValue.setSeconds(parseInt(anObjectValue));
            break;

        case CPMinuteDateType:
            dateValue.setMinutes(parseInt(anObjectValue));
            break;
    }

    [_datePicker setDateValue:dateValue];
}

/*! Return the objectValue of the textField. Needed for the binding.
    This returns the objectValue relative to the dateValue
*/
- (void)objectValue
{
    var dateValue = [[_datePicker dateValue] copy];

    switch (_dateType)
    {
        case CPMonthDateType:
            return dateValue.getMonth() + 1;
            break;

        case CPDayDateType:
            return dateValue.getDate();
            break;

        case CPYearDateType:
            return dateValue.getFullYear();
            break;

        case CPHourDateType:
            return dateValue.getHours();
            break;

        case CPSecondDateType:
            return dateValue.getSeconds();
            break;

        case CPMinuteDateType:
            return dateValue.getMinutes();
            break;

        default:
            return [super objectValue];
            break;
    }

    return [super objectValue];
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
}

/*! Unsert the theme CPThemeStateSelected
*/
- (void)makeDeselectable
{
    [self unsetThemeState:CPThemeStateSelected];
}

@end
