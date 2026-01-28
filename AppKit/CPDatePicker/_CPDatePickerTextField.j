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
@class _CPDatePickerElementView

@import "_CPDatePickerElementView.j"

@global CPSingleDateMode
@global CPRangeDateMode

@global CPTextFieldAndStepperDatePickerStyle
@global CPTextFieldDatePickerStyle

@global CPHourMinuteDatePickerElementFlag
@global CPHourMinuteSecondDatePickerElementFlag
@global CPTimeZoneDatePickerElementFlag
@global CPYearMonthDatePickerElementFlag
@global CPYearMonthDayDatePickerElementFlag
@global CPEraDatePickerElementFlag

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
    CPInteger                           _datePickerElements         @accessors(getter=datePickerElements);
}


#pragma mark Init

- (id)initWithFrame:(CGRect)aFrame withDatePicker:(CPDatePicker)aDatePicker
{
    if (self = [super initWithFrame:aFrame])
    {
        _datePicker = aDatePicker;
        [self _init];
    }
    return self;
}

- (void)_init
{
    _datePickerElements = [_datePicker datePickerElements];

    _datePickerElementView = [[_CPDatePickerElementView alloc] initWithFrame:CGRectMakeZero() withDatePicker:_datePicker];
    [self addSubview:_datePickerElementView];

    _stepper = [CPStepper stepper];
    [_stepper setTarget:self];
    [_stepper setAction:@selector(_clickStepper:)];
    [self addSubview:_stepper];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];

#if PLATFORM(DOM)
    if ([_datePicker currentValueForThemeAttribute:@"uses-focus-ring"])
    {
        // As with overflow:hidden, views are clipping their content, in order
        // to show a focus ring (which is external to a view), we need to let
        // content extend outside the view.
        _datePicker._DOMElement.style.overflow            = "visible";
        _DOMElement.style.overflow                        = "visible";
        _datePickerElementView._DOMElement.style.overflow = "visible";
    }
#endif
}


#pragma mark -
#pragma mark Override responder methods

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
    [_currentTextField _endEditing];

    // Don't forget to unbind, otherwise several steppers will increase or decrease
    [_currentTextField unbind:@"objectValue"];
    [_currentTextField makeDeselectable];
    _currentTextField = nil

    // This is usefull when clicking on the stepper when the datePicker is not selected
    [_stepper setObjectValue:0];

    return YES;
}

- (BOOL)canBecomeKeyView
{
    return NO;
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

    // Be sure to update the stepper value. We don't use -setObjectValue to avoid a binding update.
    if (_currentTextField)
        _stepper._value = [_currentTextField intValue];
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

- (void)setTextColor:(CPColor)aColor
{
    [super setTextColor:aColor];
    [_datePickerElementView setTextColor:aColor];
}

- (void)setTextFont:(CPFont)aFont
{
    [self setFont:aFont];
    [_datePickerElementView setTextFont:aFont];
}

- (void)setDatePickerElements:(CPInteger)aDatePickerElements
{
    if (_datePickerElements === aDatePickerElements)
        return;

    _datePickerElements = aDatePickerElements;

    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
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

- (void)_selectTextFieldWithFlags:(unsigned)flags
{
    [_datePickerElementView _updateResponderTextField];

    if (!_currentTextField)
    {
        if (flags & CPShiftKeyMask)
        {
            // If _lastTextField is hidden, find the one before it that is visible
            if ([_lastTextField isHidden])
                [self _selectTextField:[self _previousVisibleTextFieldFrom:_lastTextField]];
            else
                [self _selectTextField:_lastTextField];
        }
        else
        {
            // If _firstTextField is hidden, find the one after it that is visible
            if ([_firstTextField isHidden])
                [self _selectTextField:[self _nextVisibleTextFieldFrom:_firstTextField]];
            else
                [self _selectTextField:_firstTextField];
        }
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
    [_currentTextField _endEditing];

    // Don't forget to unbind, otherwise several steppers will increase or decrease
    [_currentTextField unbind:@"objectValue"];
    [_currentTextField makeDeselectable];

    _currentTextField = aDatePickerElementTextField;
    [_currentTextField makeSelectable];

    // We cannot assign a value with the textField AM/PM
    if ([_currentTextField dateType] != CPAMPMDateType)
    {
        // We update the value of the stepper dependind on the textField
        [_stepper setObjectValue:[_currentTextField intValue]];
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

        // Update the dateValue with the binding.
        if (isUp)
            [_stepper setDoubleValue:[_currentTextField intValue] + 1];
        else
            [_stepper setDoubleValue:[_currentTextField intValue] - 1];

        return;
    }

    if ([_currentTextField dateType] != CPAMPMDateType)
    {
        // Make sure to get the good value, especially when we reach the maxDate or minDate
        [sender setDoubleValue:[_currentTextField intValue]];
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

/*!
    PerformKeyEquivalent event
    We need to override that to handle the tab key
*/
- (BOOL)performKeyEquivalent:(CPEvent)anEvent
{
    if (![self isEnabled] || !_currentTextField || [[self window] firstResponder] != _datePicker)
        return NO;

    if ([anEvent charactersIgnoringModifiers] === CPTabCharacter)
    {
        if ([anEvent modifierFlags] & CPShiftKeyMask)
            [self insertBacktab:self];
        else
            [self insertTab:self];

        return YES;
    }
    else if ([anEvent charactersIgnoringModifiers] === CPBackTabCharacter)
    {
        [self insertBacktab:self];
        return YES;
    }

    return [super performKeyEquivalent:anEvent];
}

- (_CPDatePickerElementTextField)_nextVisibleTextFieldFrom:(_CPDatePickerElementTextField)aTextField
{
    var next = [aTextField nextTextField];
    // Keep looking while next exists AND it is hidden
    while (next && [next isHidden])
        next = [next nextTextField];
    
    return next;
}

- (_CPDatePickerElementTextField)_previousVisibleTextFieldFrom:(_CPDatePickerElementTextField)aTextField
{
    var prev = [aTextField previousTextField];
    // Keep looking while prev exists AND it is hidden
    while (prev && [prev isHidden])
        prev = [prev previousTextField];
        
    return prev;
}

- (void)insertTab:(id)sender
{
    if (!_currentTextField)
        return;

    // Determine what the actual next field is
    var nextField = [self _nextVisibleTextFieldFrom:_currentTextField];

    // If there is a visible field to go to, go there.
    if (nextField)
        [self _selectTextField:nextField];
    else
        // Otherwise, leave the DatePicker control
        [[self window] selectNextKeyView:self];
}

- (void)moveRight:(id)sender
{
    if (!_currentTextField)
        return;

    // Use the helper to skip hidden fields
    var nextField = [self _nextVisibleTextFieldFrom:_currentTextField];
    
    if (nextField)
        [self _selectTextField:nextField];
}

- (void)insertBacktab:(id)sender
{
    if (!_currentTextField)
        return;

    if (_currentTextField == _firstTextField)
        [[self window] selectPreviousKeyView:self];
    else
        [self moveLeft:sender];
}

- (void)moveLeft:(id)sender
{
    if (!_currentTextField)
        return;

    [self _selectTextField:[_currentTextField previousTextField]];
}

- (void)moveDown:(id)sender
{
    if (!_currentTextField)
        return;

    [_currentTextField _invalidTimer];
    [_stepper setDoubleValue:[_currentTextField intValue]];
    [_stepper performClickDown:self];
}

- (void)moveUp:(id)sender
{
    if (!_currentTextField)
        return;

    [_currentTextField _invalidTimer];
    [_stepper setDoubleValue:[_currentTextField intValue]];
    [_stepper performClickUp:self];
}

- (void)insertNewline:(id)sender
{
    if (!_currentTextField)
        return;

    [_currentTextField _endEditing];
}

/*! KeyDown event
    We just care care about the event A/P and every numbers
*/
- (void)keyDown:(CPEvent)anEvent
{
    if (![self isEnabled])
        return;

    [self interpretKeyEvents:[anEvent]];

    if ([_datePicker _isAmericanFormat] && [_currentTextField dateType] == CPAMPMDateType && ([anEvent keyCode] == CPAKeyCode || [anEvent keyCode] == CPPKeyCode || [anEvent keyCode] == CPMajAKeyCode || [anEvent keyCode] == CPMajPKeyCode))
    {
        if ([anEvent keyCode] == CPAKeyCode || [anEvent keyCode] == CPMajAKeyCode)
            [_currentTextField setStringValue:@"AM"];
        else
            [_currentTextField setStringValue:@"PM"];

        [[CPNotificationCenter defaultCenter] postNotificationName:CPDatePickerElementTextFieldAMPMChangedNotification object:_currentTextField userInfo:nil];

        return;
    }

    [_currentTextField setValueForKeyEvent:anEvent];
}


#pragma mark -
#pragma mark Layout methods

/*! Layout the subviews
*/
- (void)layoutSubviews
{
    [_datePicker _sizeToControlSize];
    [self setFrameSize:[_datePicker frameSize]];

    [super layoutSubviews];

    var frameSize,
        bezelInset = [_datePicker valueForThemeAttribute:@"bezel-inset" inState:[_datePicker themeState]];

    // Check the mode to display or not the stepper
    if ([_datePicker datePickerStyle] == CPTextFieldAndStepperDatePickerStyle)
    {
        [_stepper setHidden:NO];
        [_stepper setControlSize:[_datePicker controlSize]];

        frameSize = CGSizeMake(CGRectGetWidth([_datePicker frame]) - CGRectGetWidth([_stepper frame]) - [_datePicker currentValueForThemeAttribute:@"stepper-margin"], CGRectGetHeight([_datePicker frame]));

        frameSize.width -= bezelInset.left;
        frameSize.height -= bezelInset.top + bezelInset.bottom;

        [_datePickerElementView setFrameSize:frameSize];
        [_datePickerElementView setFrameOrigin:CGPointMake(bezelInset.left, bezelInset.top)];

        [_stepper setFrameOrigin:CGPointMake(CGRectGetMaxX([_datePickerElementView frame]) + [_datePicker currentValueForThemeAttribute:@"stepper-margin"], bezelInset.top + CGRectGetHeight([_datePickerElementView frame]) / 2 - CGRectGetHeight([_stepper frame]) / 2)];
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

    // FIXME: should be done in a self setControlSize
    [_datePickerElementView setControlSize:[_datePicker controlSize]];

    [_datePickerElementView setNeedsLayout];
}


#pragma mark -
#pragma mark Override observers

- (void)_removeObservers
{
    if (!_isObserving)
        return;

    [super _removeObservers];

    [[CPNotificationCenter defaultCenter] removeObserver:self name:CPDatePickerElementTextFieldBecomeFirstResponder object:self];
}

- (void)_addObservers
{
    if (_isObserving)
        return;

    [super _addObservers];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_datePickerElementTextFieldBecomeFirstResponder:) name:CPDatePickerElementTextFieldBecomeFirstResponder object:self];
}

@end
