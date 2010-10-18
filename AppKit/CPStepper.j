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
    int         _value          @accessors(getter=value);
    
    _CPContinuousButton    _buttonDown;
    _CPContinuousButton    _buttonUp;
}

#pragma mark -
#pragma mark Initialization

/*! Initializes a CPStepper with given values
    @param aValue the initial value of the CPStepper
    @param minValue the minimal acceptable value of the stepper
    @param maxValue the maximal acceptable value of the stepper
    @return Initialized CPStepper
*/
+ (CPStepper)stepperWithInitialValue:(int)aValue minValue:(int)aMinValue maxValue:(int)aMaxValue
{
    var stepper = [[CPStepper alloc] initWithFrame:CPRectMake(0, 0, 19, 25)];
    [stepper setValue:aValue];
    [stepper setMinValue:aMinValue];
    [stepper setMaxValue:aMaxValue];
    
    return stepper;
}

/*! Initializes a CPStepper with default values: 
        - minValue = -100
        - maxValue = 100
        - value = 0
    @return Initialized CPStepper
*/
+ (CPStepper)stepper
{
    return [CPStepper stepperWithInitialValue:0 minValue:-100 maxValue:100];
}

/*! Initializes the CPStepper
    @param aFrame the frame of the control
    @return initialized CPStepper
*/
- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _value          = 0;
        _maxValue       = 10;
        _minValue       = -10;
        _increment      = 1;
        _valueWraps     = YES;
        
        _buttonUp = [[_CPContinuousButton alloc] initWithFrame:CPRectMake(aFrame.size.width - CPStepperButtonsSize.width, 0, CPStepperButtonsSize.width, CPStepperButtonsSize.height)];
        [_buttonUp setContinuous:YES];
        [_buttonUp setTarget:self];
        [_buttonUp setAction:@selector(_buttonDidClick:)];
        [_buttonUp setAutoresizingMask:CPViewNotSizable];
        [_buttonUp setValue:[self valueForThemeAttribute:@"bezel-color-up-button" inState:CPThemeStateBordered] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
        [_buttonUp setValue:[self valueForThemeAttribute:@"bezel-color-up-button" inState:CPThemeStateBordered | CPThemeStateDisabled] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateDisabled];
        [_buttonUp setValue:[self valueForThemeAttribute:@"bezel-color-up-button" inState:CPThemeStateBordered | CPThemeStateHighlighted] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateHighlighted];
        [self addSubview:_buttonUp];
        
        _buttonDown = [[_CPContinuousButton alloc] initWithFrame:CPRectMake(aFrame.size.width - CPStepperButtonsSize.width, CPStepperButtonsSize.height, CPStepperButtonsSize.width, CPStepperButtonsSize.height - 1)];
        [_buttonDown setContinuous:YES];
        [_buttonDown setTarget:self];
        [_buttonDown setAction:@selector(_buttonDidClick:)];
        [_buttonDown setAutoresizingMask:CPViewNotSizable];
        [_buttonDown setValue:[self valueForThemeAttribute:@"bezel-color-down-button" inState:CPThemeStateBordered] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered];
        [_buttonDown setValue:[self valueForThemeAttribute:@"bezel-color-down-button" inState:CPThemeStateBordered | CPThemeStateDisabled] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateDisabled];
        [_buttonDown setValue:[self valueForThemeAttribute:@"bezel-color-down-button" inState:CPThemeStateBordered | CPThemeStateHighlighted] forThemeAttribute:@"bezel-color" inState:CPThemeStateBordered | CPThemeStateHighlighted];
        [self addSubview:_buttonDown];     
    }

    return self;
}

#pragma mark -
#pragma mark Superclass overrides

/*! set the CPStepper enabled or not
    @param shouldEnabled BOOL that define if stepper is enabled or not.
*/
- (void)setEnabled:(BOOL)shouldEnabled
{
    [super setEnabled:shouldEnabled];

    [_buttonUp setEnabled:shouldEnabled];
    [_buttonDown setEnabled:shouldEnabled];
}

/*! set the frame of the CPStepper and check if width is not smaller than theme min-size
    
*/
- (void)setFrame:(CGRect)aFrame
{
    if (aFrame.size.width >= CGRectGetWidth(aFrame))
        [super setFrame:aFrame];
}

/*!  set is CPStepper should autorepear
    @param shouldAutoRepeat if YES, the first mouse down does one increment (decrement) and, after each delay of 0.5 seconds
*/
- (void)setAutorepeat:(BOOL)shouldAutoRepeat
{
    [_buttonUp setContinuous:shouldAutoRepeat];
    [_buttonDown setContinuous:shouldAutoRepeat];
}

#pragma mark -
#pragma mark Accessors

- (void)setValue:(int)aValue
{
    if (aValue > _maxValue)
        [self setValue:_valueWraps ? _minValue : _maxValue forKeyPath:@"_value"];
    else if (aValue < _minValue)
        [self setValue:_valueWraps ? _maxValue : _minValue forKeyPath:@"_value"];
    else
        [self setValue:aValue forKeyPath:@"_value"];
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
        [self setValue:_value + _increment];
    else
        [self setValue:_value - _increment];

    if ([self target] && [self action] && [[self target] respondsToSelector:[self action]])
        [[self target] performSelector:[self action] withObject:self];
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




/*! CPTextFieldStepper is a subclass of CPStepper. it contains a textfield that displays the current stepper value
*/
@implementation CPTextFieldStepper : CPStepper
{
    CPTextField    _textField;
}


#pragma mark -
#pragma mark Initialization

/*! Initializes a CPTextFieldStepper with given values
    @param aValue the initial value of the CPStepper
    @param minValue the minimal acceptable value of the stepper
    @param maxValue the maximal acceptable value of the stepper
    @return Initialized CPStepper
*/
+ (CPTextFieldStepper)stepperWithInitialValue:(int)aValue minValue:(int)aMinValue maxValue:(int)aMaxValue
{
    var stepper = [[CPTextFieldStepper alloc] initWithFrame:CPRectMake(0, 0, 100, 25)];
    [stepper setValue:aValue];
    [stepper setMinValue:aMinValue];
    [stepper setMaxValue:aMaxValue];
    
    return stepper;
}

/*! Initializes a CPStepper with default values: 
        - minValue = -100
        - maxValue = 100
        - value = 0
    @return Initialized CPStepper
*/
+ (CPTextFieldStepper)stepper
{
    return [CPTextFieldStepper stepperWithInitialValue:0 minValue:-100 maxValue:100];
}


/*! Initializes the CPTextFieldStepper with the textfield
    @param aFrame the frame of the control
    @return initialized CPTextFieldStepper
*/
- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [_buttonUp setAutoresizingMask:CPViewMinXMargin];
        [_buttonDown setAutoresizingMask:CPViewMinXMargin];
        
        _textField = [[CPTextField alloc] initWithFrame:CPRectMake(0, 0, aFrame.size.width - CPStepperButtonsSize.width, aFrame.size.height)];
        [_textField setBezeled:YES];
        [_textField setEditable:NO];
        [_textField setAutoresizingMask:CPViewWidthSizable];
        [_textField bind:@"intValue" toObject:self withKeyPath:@"value" options:nil];
        [_textField setValue:CGInsetMake(0.0, 0.0, 0.0, 0.0) forThemeAttribute:@"bezel-inset"];
        [_textField setValue:[self valueForThemeAttribute:@"bezel-color-textfield" inState:CPThemeStateBezeled] forThemeAttribute:@"bezel-color"];
        [_textField setValue:[self valueForThemeAttribute:@"bezel-color-textfield" inState:CPThemeStateBezeled | CPThemeStateDisabled] forThemeAttribute:@"bezel-color" inState:CPThemeStateBezeled | CPThemeStateDisabled];
        [_textField setValue:CGInsetMake(7.0, 7.0, 5.0, 8.0) forThemeAttribute:@"content-inset"];
        
        [self addSubview:_textField];
    }
    
    return self;
}

/*! set the CPTextFieldStepper enabled or not
    @param shouldEnabled BOOL that define if stepper is enabled or not.
*/
- (void)setEnabled:(BOOL)shouldEnabled
{
    [super setEnabled:shouldEnabled];
    [_textField setEnabled:shouldEnabled];
}


#pragma mark -
#pragma mark Theming

+ (CPString)themeClass
{
    return @"textfieldstepper";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[[CPNull null], [CPNull null], [CPNull null]]
                                       forKeys:[@"bezel-color-up-button", @"bezel-color-down-button", @"bezel-color-textfield"]];
}

@end


@implementation CPTextFieldStepper (CPCodingCompliance)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _textField   = [aCoder decodeObjectForKey:@"_textField"];

    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:_textField forKey:@"_textField"];
}

@end



/*! This is a subclass of CPButton that allows to send continuous action.
    This may should be include in CPButton..
*/
@implementation _CPContinuousButton : CPButton
{
    CPTimer _continuousDelayTimer;
    CPTimer _continuousTimer;
    float   _periodicDelay;
    float   _periodicInterval;
}

- (void)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _periodicInterval   = 0.05;
        _periodicDelay      = 0.5;
    }
    
    return self;
}

- (void)setPeriodicDelay:(float)aDelay interval:(float)anInterval
{
    _periodicDelay      = aDelay;
    _periodicInterval   = anInterval;
}

- (void)mouseDown:(CPEvent)anEvent
{
    if ([self isContinuous])
    {
        _continuousDelayTimer = [CPTimer scheduledTimerWithTimeInterval:_periodicDelay callback: function(){
            if (!_continuousTimer)
                _continuousTimer = [CPTimer scheduledTimerWithTimeInterval:_periodicInterval target:self selector:@selector(onContinousEvent:) userInfo:anEvent repeats:YES];
        } 
        repeats:NO];
    }
    
    [super mouseDown:anEvent];
}

- (void)onContinousEvent:(CPTimer)aTimer
{
    if (_target && _action && [_target respondsToSelector:_action])
        [_target performSelector:_action withObject:self];
}

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    [self invalidateTimers];
    [super stopTracking:lastPoint at:aPoint mouseIsUp:mouseIsUp];
}

- (void)invalidateTimers
{
    if (_continuousTimer)
    {
        [_continuousTimer invalidate];    
        _continuousTimer = nil;
    }
    
    if (_continuousDelayTimer)
    {
        [_continuousDelayTimer invalidate];
        _continuousDelayTimer = nil;
    }
}

@end



@implementation _CPContinuousButton (CPCodingCompliance)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _periodicDelay      = [aCoder decodeObjectForKey:@"_periodicDelay"];
        _periodicInterval   = [aCoder decodeObjectForKey:@"_periodicInterval"];
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [self invalidateTimers];
    [aCoder encodeObject:_periodicDelay forKey:@"_periodicDelay"];
    [aCoder encodeObject:_periodicInterval forKey:@"_periodicInterval"];
}
@end
