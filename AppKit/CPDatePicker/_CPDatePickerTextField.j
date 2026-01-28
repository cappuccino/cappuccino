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
        var targetField = nil;

        if (flags & CPShiftKeyMask)
        {
            // Try last field; if hidden, find previous visible
            if ([_lastTextField isHidden])
                targetField = [self _previousVisibleTextFieldFrom:_lastTextField];
            else
                targetField = _lastTextField;
        }
        else
        {
            // Try first field; if hidden, find next visible
            if ([_firstTextField isHidden])
                targetField = [self _nextVisibleTextFieldFrom:_firstTextField];
            else
                targetField = _firstTextField;
        }

        // Only select if we actually found a valid visible field
        if (targetField)
            [self _selectTextField:targetField];
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
    var runner = [aTextField nextTextField];

    // If we wrapped back to the start immediately, or runner is nil, we are done.
    if (!runner || runner == _firstTextField)
        return nil;

    // Traverse hidden fields
    while (runner && [runner isHidden])
    {
        // If we hit the absolute last field and it is hidden, we've reached the end.
        if (runner == _lastTextField)
            return nil;

        runner = [runner nextTextField];

        // Safety: if we wrapped back to the start inside the loop
        if (runner == _firstTextField)
            return nil;
    }

    return runner;
}

- (_CPDatePickerElementTextField)_previousVisibleTextFieldFrom:(_CPDatePickerElementTextField)aTextField
{
    var runner = [aTextField previousTextField];

    // If we wrapped back to the end immediately, or runner is nil, we are done.
    if (!runner || runner == _lastTextField)
        return nil;

    // Traverse hidden fields
    while (runner && [runner isHidden])
    {
        // If we hit the absolute first field and it is hidden, we've reached the start.
        if (runner == _firstTextField)
            return nil;

        runner = [runner previousTextField];

        // Safety: if we wrapped back to the end inside the loop
        if (runner == _lastTextField)
            return nil;
    }

    return runner;
}

- (void)insertTab:(id)sender
{
    if (!_currentTextField)
        return;

    // Ensure boundaries are up to date
    [_datePickerElementView _updateResponderTextField];

    var nextField = [self _nextVisibleTextFieldFrom:_currentTextField];

    if (nextField)
    {
        [self _selectTextField:nextField];
    }
    else
    {
        // We reached the visual end. Manually find the next external view.
        // We cannot rely on [[self window] selectNextKeyView:self] because it might 
        // loop back into our own internal fields or select 'self' which refuses focus.
        var nextView = [_currentTextField nextValidKeyView];

        // Skip any view that is part of this control (descendant)
        while (nextView && [nextView isDescendantOf:self])
        {
            // If we looped back to the current field, we are trapped in a closed loop with no exit.
            if (nextView == _currentTextField)
            {
                nextView = nil;
                break;
            }
            nextView = [nextView nextValidKeyView];
        }

        if (nextView)
            [[self window] makeFirstResponder:nextView];
    }
}

- (void)insertBacktab:(id)sender
{
    if (!_currentTextField)
        return;

    [_datePickerElementView _updateResponderTextField];

    var prevField = [self _previousVisibleTextFieldFrom:_currentTextField];

    if (prevField)
    {
        [self _selectTextField:prevField];
    }
    else
    {
        // We reached the visual start. Manually find the previous external view.
        var prevView = [_currentTextField previousValidKeyView];

        // Skip any view that is part of this control
        while (prevView && [prevView isDescendantOf:self])
        {
            if (prevView == _currentTextField)
            {
                prevView = nil;
                break;
            }
            prevView = [prevView previousValidKeyView];
        }

        if (prevView)
            [[self window] makeFirstResponder:prevView];
    }
}

- (void)moveRight:(id)sender
{
    if (!_currentTextField)
        return;

    [_datePickerElementView _updateResponderTextField];

    // Use the helper to skip hidden fields
    var nextField = [self _nextVisibleTextFieldFrom:_currentTextField];
    
    if (nextField)
        [self _selectTextField:nextField];
}

- (void)moveLeft:(id)sender
{
    if (!_currentTextField)
        return;

    [_datePickerElementView _updateResponderTextField];

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
