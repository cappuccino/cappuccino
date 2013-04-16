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

@import "CPControl.j"
@import "CPButton.j"
@import "CPTextField.j"



/*!
    CPStepper is an implementation of Cocoa NSStepper.

    This control displays a two part button that can be used to increase or decrease a value with a given interval.
*/
@implementation CPStepper: CPControl
{
    BOOL        _valueWraps     @accessors(property=valueWraps);
    BOOL        _autorepeat     @accessors(getter=autorepeat);
    int         _increment      @accessors(property=increment);
    int         _maxValue       @accessors(property=maxValue);
    int         _minValue       @accessors(property=minValue);

    CPButton    _buttonDown;
    CPButton    _buttonUp;
}

#pragma mark -
#pragma mark Initialization

/*!
    Initializes a CPStepper with given values.
    @param aValue the initial value of the CPStepper
    @param minValue the minimal acceptable value of the stepper
    @param maxValue the maximal acceptable value of the stepper
    @return Initialized CPStepper
*/
+ (CPStepper)stepperWithInitialValue:(float)aValue minValue:(float)aMinValue maxValue:(float)aMaxValue
{
    var stepper = [[CPStepper alloc] initWithFrame:CGRectMakeZero()];

    [stepper setDoubleValue:aValue];
    [stepper setMinValue:aMinValue];
    [stepper setMaxValue:aMaxValue];

    // _sizeToFit will put the good size for the stepper depending of the current theme
    [stepper _sizeToFit];

    return stepper;
}

/*!
    Initializes a CPStepper with default values:
        - minValue = 0.0
        - maxValue = 59.0
        - value = 0.0

    @return Initialized CPStepper
*/
+ (CPStepper)stepper
{
    return [CPStepper stepperWithInitialValue:0.0 minValue:0.0 maxValue:59.0];
}

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding == CPValueBinding || aBinding == CPMinValueBinding || aBinding == CPMaxValueBinding)
        return [_CPStepperValueBinder class];

    return [super _binderClassForBinding:aBinding];
}

- (CPString)_replacementKeyPathForBinding:(CPString)aBinding
{
    if (aBinding == CPValueBinding)
        return @"doubleValue";

    return [super _replacementKeyPathForBinding:aBinding];
}

/*!
    Initializes a CPStepper.
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
        _autorepeat     = YES;

        [self setDoubleValue:0.0];
        [self _init];
    }

    return self;
}

/*! @ignore */

- (void)_init
{
    _buttonUp = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
    [_buttonUp setContinuous:_autorepeat];
    [_buttonUp setTarget:self];
    [_buttonUp setAction:@selector(_buttonDidClick:)];
    [_buttonUp setAutoresizingMask:CPViewNotSizable];
    [self addSubview:_buttonUp];

    _buttonDown = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
    [_buttonDown setContinuous:_autorepeat];
    [_buttonDown setTarget:self];
    [_buttonDown setAction:@selector(_buttonDidClick:)];
    [_buttonDown setAutoresizingMask:CPViewNotSizable];

    [self setContinuous:_autorepeat];
    [self addSubview:_buttonDown];

    [self setNeedsLayout];
}

#pragma mark -
#pragma mark Superclass overrides

/*!
    Set if the CPStepper is enabled or not.
    @param shouldEnabled BOOL that define if stepper is enabled or not.
*/
- (void)setEnabled:(BOOL)shouldEnabled
{
    [super setEnabled:shouldEnabled];

    [_buttonUp setEnabled:shouldEnabled];
    [_buttonDown setEnabled:shouldEnabled];
}


- (void)setFrame:(CGRect)aFrame
{
    var upSize = [self valueForThemeAttribute:@"up-button-size"],
        downSize = [self valueForThemeAttribute:@"down-button-size"],
        minSize = CGSizeMake(upSize.width, upSize.height + downSize.height),
        frame = CGRectMakeCopy(aFrame);

    frame.size.width = MAX(minSize.width, frame.size.width);
    frame.size.height = MAX(minSize.height, frame.size.height);
    [super setFrame:frame];
}

/*! @ignore */
- (void)layoutSubviews
{
    var aFrame = [self frame],
        upSize = [self valueForThemeAttribute:@"up-button-size"],
        downSize = [self valueForThemeAttribute:@"down-button-size"],
        upFrame = CGRectMake(aFrame.size.width - upSize.width, 0, upSize.width, upSize.height),
        downFrame = CGRectMake(aFrame.size.width - downSize.width, upSize.height, downSize.width, downSize.height);

    [_buttonUp setFrame:upFrame];
    [_buttonDown setFrame:downFrame];

    [_buttonUp setValue:[self valueForThemeAttribute:@"bezel-color-up-button" inState:CPThemeStateBordered] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
    [_buttonUp setValue:[self valueForThemeAttribute:@"bezel-color-up-button" inState:CPThemeStateBordered | CPThemeStateDisabled] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateDisabled];
    [_buttonUp setValue:[self valueForThemeAttribute:@"bezel-color-up-button" inState:CPThemeStateBordered | CPThemeStateHighlighted] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateHighlighted];
    [_buttonDown setValue:[self valueForThemeAttribute:@"bezel-color-down-button" inState:CPThemeStateBordered] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
    [_buttonDown setValue:[self valueForThemeAttribute:@"bezel-color-down-button" inState:CPThemeStateBordered | CPThemeStateDisabled] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateDisabled];
    [_buttonDown setValue:[self valueForThemeAttribute:@"bezel-color-down-button" inState:CPThemeStateBordered | CPThemeStateHighlighted] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateHighlighted];
}

- (void)_sizeToFit
{
    [self setFrame:CGRectMake([self frameOrigin].x, [self frameOrigin].y, 0, 0)];
}

/*!
    Set if CPStepper should autorepeat.
    @param shouldAutoRepeat if YES, the first mouse down does one increment (decrement) and, after each delay of 0.5 seconds
*/
- (void)setAutorepeat:(BOOL)shouldAutoRepeat
{
    if (shouldAutoRepeat !== _autorepeat)
    {
        [_buttonUp setContinuous:shouldAutoRepeat];
        [_buttonDown setContinuous:shouldAutoRepeat];
    }

    [self setContinuous:shouldAutoRepeat];
}

/*!
    Set the current value of the stepper.
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

/*! @ignore */
- (IBAction)_buttonDidClick:(id)aSender
{
    if (![self isEnabled])
        return;

    if (aSender == _buttonUp)
        [self setDoubleValue:([self doubleValue] + _increment)];
    else
        [self setDoubleValue:([self doubleValue] - _increment)];

    [self sendAction:[self action] to:[self target]];
}

/*!
    Perform a programatic click on up button.
    @param aSender sender of the action
*/
- (IBAction)performClickUp:(id)aSender
{
    [_buttonUp performClick:aSender];
}

/*!
    Perform a programatic click on down button.
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
    return @{
            @"bezel-color-up-button": [CPNull null],
            @"bezel-color-down-button": [CPNull null],
            @"up-button-size": CGSizeMakeZero(),
            @"down-button-size": CGSizeMakeZero(),
        };
}

@end

@implementation _CPStepperValueBinder : CPBinder
{
}

- (void)_updatePlaceholdersWithOptions:(CPDictionary)options forBinding:(CPString)aBinding
{
    var placeholder = (aBinding == CPMaxValueBinding) ? [_source maxValue] : [_source minValue];

    [super _updatePlaceholdersWithOptions:options];

    [self _setPlaceholder:placeholder forMarker:CPMultipleValuesMarker isDefault:YES];
    [self _setPlaceholder:placeholder forMarker:CPNoSelectionMarker isDefault:YES];
    [self _setPlaceholder:placeholder forMarker:CPNotApplicableMarker isDefault:YES];
    [self _setPlaceholder:placeholder forMarker:CPNullMarker isDefault:YES];
}

@end

var CPStepperMinValue   = @"CPStepperMinValue",
    CPStepperMaxValue   = @"CPStepperMaxValue",
    CPStepperValueWraps = @"CPStepperValueWraps",
    CPStepperAutorepeat = @"CPStepperAutorepeat",
    CPStepperIncrement  = @"CPStepperIncrement";

@implementation CPStepper (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _increment  = [aCoder decodeIntForKey:CPStepperIncrement];
        _minValue   = [aCoder decodeIntForKey:CPStepperMinValue];
        _maxValue   = [aCoder decodeIntForKey:CPStepperMaxValue];
        _valueWraps = [aCoder decodeBoolForKey:CPStepperValueWraps];
        _autorepeat = [aCoder decodeBoolForKey:CPStepperAutorepeat];

        [self _init];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeInt:_increment forKey:CPStepperIncrement];

    if (_minValue)
        [aCoder encodeInt:_minValue forKey:CPStepperMinValue];
    if (_maxValue)
        [aCoder encodeInt:_maxValue forKey:CPStepperMaxValue];
    if (_valueWraps)
        [aCoder encodeBool:_valueWraps forKey:CPStepperValueWraps];
    if (_autorepeat)
        [aCoder encodeBool:_autorepeat forKey:CPStepperAutorepeat];
}

@end
