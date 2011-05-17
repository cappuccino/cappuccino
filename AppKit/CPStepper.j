/*
 * CPStepper.j
 * AppKit
 *
 * Created by Antoine Mercadal
 * Copyright 2009, Antoine Mercadal
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

@import <AppKit/CPControl.j>
@import <AppKit/CPButton.j>
@import <AppKit/CPTextField.j>


var CPStepperButtonsSize = CPSizeMake(19, 13);

/*! CPStepper is an  implementation of Cocoa NSStepper.

    This control display a two part button that can be used to increase or decrease a value with a given interval.
*/
@implementation CPStepper: CPControl
{
    BOOL        _valueWraps     @accessors(property=valueWraps);
    int         _increment      @accessors(property=increment);
    int         _maxValue       @accessors(property=maxValue);
    int         _minValue       @accessors(property=minValue);

    CPButton    _buttonDown;
    CPButton    _buttonUp;
}

#pragma mark -
#pragma mark Initialization

/*! Initializes a CPStepper with given values
    @param aValue the initial value of the CPStepper
    @param minValue the minimal acceptable value of the stepper
    @param maxValue the maximal acceptable value of the stepper
    @return Initialized CPStepper
*/
+ (CPStepper)stepperWithInitialValue:(float)aValue minValue:(float)aMinValue maxValue:(float)aMaxValue
{
    var stepper = [[CPStepper alloc] initWithFrame:CPRectMake(0, 0, 19, 25)];
    [stepper setDoubleValue:aValue];
    [stepper setMinValue:aMinValue];
    [stepper setMaxValue:aMaxValue];

    return stepper;
}

/*! Initializes a CPStepper with default values:
        - minValue = 0.0
        - maxValue = 59.0
        - value = 0.0
    @return Initialized CPStepper
*/
+ (CPStepper)stepper
{
    return [CPStepper stepperWithInitialValue:0.0 minValue:0.0 maxValue:59.0];
}

/*! Initializes the CPStepper
    @param aFrame the frame of the control
    @return initialized CPStepper
*/
- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _maxValue       = 59.0;
        _minValue       = 0.0;
        _increment      = 1.0;
        _valueWraps     = YES;

        [self setDoubleValue:0.0];

        _buttonUp = [[CPButton alloc] initWithFrame:CPRectMake(aFrame.size.width - CPStepperButtonsSize.width, 0, CPStepperButtonsSize.width, CPStepperButtonsSize.height)];
        [_buttonUp setContinuous:YES];
        [_buttonUp setTarget:self];
        [_buttonUp setAction:@selector(_buttonDidClick:)];
        [_buttonUp setAutoresizingMask:CPViewNotSizable];
        [self addSubview:_buttonUp];

        _buttonDown = [[CPButton alloc] initWithFrame:CPRectMake(aFrame.size.width - CPStepperButtonsSize.width, CPStepperButtonsSize.height, CPStepperButtonsSize.width, CPStepperButtonsSize.height - 1)];
        [_buttonDown setContinuous:YES];
        [_buttonDown setTarget:self];
        [_buttonDown setAction:@selector(_buttonDidClick:)];
        [_buttonDown setAutoresizingMask:CPViewNotSizable];
        [self addSubview:_buttonDown];

        [self setNeedsLayout];
    }

    return self;
}

#pragma mark -
#pragma mark Superclass overrides

/*! set if the CPStepper is enabled or not
    @param shouldEnabled BOOL that define if stepper is enabled or not.
*/
- (void)setEnabled:(BOOL)shouldEnabled
{
    [super setEnabled:shouldEnabled];

    [_buttonUp setEnabled:shouldEnabled];
    [_buttonDown setEnabled:shouldEnabled];
}

/*! set the frame of the CPStepper and check if width is not smaller than theme min-size
    @param aFrame the frame
*/
- (void)setFrame:(CGRect)aFrame
{
    if (aFrame.size.width >= CGRectGetWidth(aFrame))
        [super setFrame:aFrame];
}

/*! @ignore
*/
- (void)layoutSubviews
{
    [_buttonUp setValue:[self valueForThemeAttribute:@"bezel-color-up-button" inState:CPThemeStateBordered] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
    [_buttonUp setValue:[self valueForThemeAttribute:@"bezel-color-up-button" inState:CPThemeStateBordered | CPThemeStateDisabled] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateDisabled];
    [_buttonUp setValue:[self valueForThemeAttribute:@"bezel-color-up-button" inState:CPThemeStateBordered | CPThemeStateHighlighted] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateHighlighted];
    [_buttonDown setValue:[self valueForThemeAttribute:@"bezel-color-down-button" inState:CPThemeStateBordered] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
    [_buttonDown setValue:[self valueForThemeAttribute:@"bezel-color-down-button" inState:CPThemeStateBordered | CPThemeStateDisabled] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateDisabled];
    [_buttonDown setValue:[self valueForThemeAttribute:@"bezel-color-down-button" inState:CPThemeStateBordered | CPThemeStateHighlighted] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateHighlighted];
}

/*! set if CPStepper should autorepeat
    @param shouldAutoRepeat if YES, the first mouse down does one increment (decrement) and, after each delay of 0.5 seconds
*/
- (void)setAutorepeat:(BOOL)shouldAutoRepeat
{
    [_buttonUp setContinuous:shouldAutoRepeat];
    [_buttonDown setContinuous:shouldAutoRepeat];
}

/*! set the current value of the stepper
    @param aValue a float containing the value
*/
- (void)setDoubleValue:(float)aValue
{
    if (aValue > _maxValue)
        [super setDoubleValue:_valueWraps ? _minValue : _maxValue];
    else if (aValue < _minValue)
        [super setDoubleValue:_valueWraps ? _maxValue : _minValue];
    else
        [super setDoubleValue:aValue];
}

#pragma mark -
#pragma mark Actions

/*! @ignore
*/
- (IBAction)_buttonDidClick:(id)aSender
{
    if (![self isEnabled])
        return;

    if (aSender == _buttonUp)
        [self setDoubleValue:([self doubleValue] + _increment)];
    else
        [self setDoubleValue:([self doubleValue] - _increment)];

    if (_target && _action && [_target respondsToSelector:_action])
        [self sendAction:_action to:_target];
}

/*! @perform a programatic click on up button
    @param aSender sender of the action
*/
- (IBAction)performClickUp:(id)aSender
{
    [_buttonUp performClick:aSender];
}

/*! @perform a programatic click on down button
    @param aSender sender of the action
*/
- (IBAction)performClickDown:(id)aSender
{
    [_buttonDown performClick:aSender];
}


#pragma mark -
#pragma mark Theming

+ (CPString)defaultThemeClass
{
    return @"stepper";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[[CPNull null], [CPNull null]]
                                       forKeys:[@"bezel-color-up-button", @"bezel-color-down-button"]];
}

@end


@implementation CPStepper (CPCodingCompliance)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _maxValue   = [aCoder decodeObjectForKey:@"_maxValue"];
        _minValue   = [aCoder decodeObjectForKey:@"_minValue"];
        _increment  = [aCoder decodeObjectForKey:@"_increment"];
        _buttonUp   = [aCoder decodeObjectForKey:@"_buttonUp"];
        _buttonDown = [aCoder decodeObjectForKey:@"_buttonDown"];
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_maxValue forKey:@"_maxValue"];
    [aCoder encodeObject:_minValue forKey:@"_minValue"];
    [aCoder encodeObject:_increment forKey:@"_increment"];
    [aCoder encodeObject:_buttonUp forKey:@"_buttonUp"];
    [aCoder encodeObject:_buttonDown forKey:@"_buttonDown"];
}

@end
