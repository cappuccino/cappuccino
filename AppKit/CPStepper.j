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

/*! CPStepper is an  implementation of Cocoa NSStepper.

    This control display a two part button that can be used to increase or decrease a value with a given interval.
*/
@implementation CPStepper: CPControl
{
    int         _increment  @accessors(property=increment);
    int         _maxValue   @accessors(property=maxValue);
    int         _minValue   @accessors(property=minValue);
    int         _value      @accessors(getter=value);

    CPButton    _buttonDown;
    CPButton    _buttonUp;
}

#pragma mark -
#pragma mark Initialization

+ (CPStepper)stepperWithInitialValue:(int)aValue minValue:(int)aMinValue maxValue:(int)aMaxValue
{
    var stepper = [[CPStepper alloc] initWithFrame:CPRectMake(0, 0, 19, 25)];
    [stepper setValue:aValue];
    [stepper setMinValue:aMinValue];
    [stepper setMaxValue:aMaxValue];
    
    return stepper;
}

+ (CPStepper)stepper
{
    return [CPStepper stepperWithInitialValue:0 minValue:-100 maxValue:100];
}

/*! Initializes the CPStepper
    @param aFrame the frame of the control
    @return initialized CPStepper
*/
- (id)initWithFrame:(CPRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _value      = 0;
        _maxValue   = 10;
        _minValue   = -10;
        _increment  = 1;

        _buttonUp = [[CPButton alloc] initWithFrame:CPRectMake(0, 0, 19, 13)];
        [_buttonUp setTarget:self];
        [_buttonUp setAction:@selector(_buttonDidClick:)];
        [_buttonUp setValue:[self valueForThemeAttribute:@"bezel-color-up-button" inState:CPThemeStateBordered] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
        [_buttonUp setValue:[self valueForThemeAttribute:@"bezel-color-up-button" inState:CPThemeStateBordered | CPThemeStateDisabled] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateDisabled];
        [_buttonUp setValue:[self valueForThemeAttribute:@"bezel-color-up-button" inState:CPThemeStateBordered | CPThemeStateHighlighted] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateHighlighted];

        [self addSubview:_buttonUp];

        _buttonDown = [[CPButton alloc] initWithFrame:CPRectMake(0, 13, 19, 12)];
        [_buttonDown setTarget:self];
        [_buttonDown setAction:@selector(_buttonDidClick:)];
        [_buttonDown setValue:[self valueForThemeAttribute:@"bezel-color-down-button" inState:CPThemeStateBordered] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
        [_buttonDown setValue:[self valueForThemeAttribute:@"bezel-color-down-button" inState:CPThemeStateBordered | CPThemeStateDisabled] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateDisabled];
        [_buttonDown setValue:[self valueForThemeAttribute:@"bezel-color-down-button" inState:CPThemeStateBordered | CPThemeStateHighlighted] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateHighlighted];

        [self addSubview:_buttonDown];
    }

    return self;
}


#pragma mark -
#pragma mark CPControl overrides

/*! set the CPStepper enabled or not
    @param shouldEnabled BOOL that define if stepper is enabled or not.
*/
- (void)setEnabled:(BOOL)shouldEnabled
{
    [super setEnabled:shouldEnabled];

    [_buttonUp setEnabled:shouldEnabled];
    [_buttonDown setEnabled:shouldEnabled];
}

#pragma mark -
#pragma mark Accessors

- (void)setValue:(int)aValue
{
    if (aValue > _maxValue)
        _value = _maxValue;
    else if (aValue < _minValue)
        _value = _minValue;
    else
        _value = aValue;
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
        _value = ((_value + _increment) > _maxValue) ? _maxValue : _value + _increment;
    else
        _value = ((_value - _increment) < _minValue) ? _minValue : _value - _increment;

    if ([self target] && [self action] && [[self target] respondsToSelector:[self action]])
        [[self target] performSelector:[self action] withObject:self];
}

- (IBAction)performClickUp:(id)aSender
{
    [_buttonUp performClick:aSender];
}

- (IBAction)performClickDown:(id)aSender
{
    [_buttonDown performClick:aSender];
}


#pragma mark -
#pragma mark Theming

+ (CPString)themeClass
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
