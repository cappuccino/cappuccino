/*
 * CPControl.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

@import <Foundation/CPFormatter.j>
@import <Foundation/CPTimer.j>

@import "CPFont.j"
@import "CPShadow.j"
@import "CPView.j"
@import "CPKeyValueBinding.j"

@global CPApp

CPLeftTextAlignment      = 0;
CPRightTextAlignment     = 1;
CPCenterTextAlignment    = 2;
CPJustifiedTextAlignment = 3;
CPNaturalTextAlignment   = 4;

CPRegularControlSize = 0;
CPSmallControlSize   = 1;
CPMiniControlSize    = 2;

CPLineBreakByWordWrapping     = 0;
CPLineBreakByCharWrapping     = 1;
CPLineBreakByClipping         = 2;
CPLineBreakByTruncatingHead   = 3;
CPLineBreakByTruncatingTail   = 4;
CPLineBreakByTruncatingMiddle = 5;

CPTopVerticalTextAlignment    = 1;
CPCenterVerticalTextAlignment = 2;
CPBottomVerticalTextAlignment = 3;

// Deprecated for use with images, use the CPImageScale constants
CPScaleProportionally = 0;
CPScaleToFit          = 1;
CPScaleNone           = 2;

CPImageScaleProportionallyDown     = 0;
CPImageScaleAxesIndependently      = 1;
CPImageScaleNone                   = 2;
CPImageScaleProportionallyUpOrDown = 3;

CPNoImage       = 0;
CPImageOnly     = 1;
CPImageLeft     = 2;
CPImageRight    = 3;
CPImageBelow    = 4;
CPImageAbove    = 5;
CPImageOverlaps = 6;

CPOnState    = 1;
CPOffState   = 0;
CPMixedState = -1;

CPControlNormalBackgroundColor      = "CPControlNormalBackgroundColor";
CPControlSelectedBackgroundColor    = "CPControlSelectedBackgroundColor";
CPControlHighlightedBackgroundColor = "CPControlHighlightedBackgroundColor";
CPControlDisabledBackgroundColor    = "CPControlDisabledBackgroundColor";

CPControlTextDidBeginEditingNotification    = "CPControlTextDidBeginEditingNotification";
CPControlTextDidChangeNotification          = "CPControlTextDidChangeNotification";
CPControlTextDidEndEditingNotification      = "CPControlTextDidEndEditingNotification";

var CPControlBlackColor = [CPColor blackColor];

/*!
    @ingroup appkit
    @class CPControl

    CPControl is an abstract superclass used to implement user interface elements. As a subclass of CPView and CPResponder it has the ability to handle screen drawing and handling user input.
*/
@implementation CPControl : CPView
{
    id                  _value;
    CPFormatter         _formatter @accessors(property=formatter);

    // Target-Action Support
    id                  _target;
    SEL                 _action;
    int                 _sendActionOn;
    BOOL                _sendsActionOnEndEditing @accessors(property=sendsActionOnEndEditing);

    // Mouse Tracking Support
    BOOL                _continuousTracking;
    BOOL                _trackingWasWithinFrame;
    unsigned            _trackingMouseDownFlags;
    CGPoint             _previousTrackingLocation;
}

+ (CPDictionary)themeAttributes
{
    return @{
            @"alignment": CPLeftTextAlignment,
            @"vertical-alignment": CPTopVerticalTextAlignment,
            @"line-break-mode": CPLineBreakByClipping,
            @"text-color": [CPColor blackColor],
            @"font": [CPFont systemFontOfSize:CPFontCurrentSystemSize],
            @"text-shadow-color": [CPNull null],
            @"text-shadow-offset": CGSizeMakeZero(),
            @"image-position": CPImageLeft,
            @"image-scaling": CPScaleToFit,
            @"min-size": CGSizeMakeZero(),
            @"max-size": CGSizeMake(-1.0, -1.0),
        };
}

+ (void)initialize
{
    if (self !== [CPControl class])
        return;

    [self exposeBinding:@"value"];
    [self exposeBinding:@"objectValue"];
    [self exposeBinding:@"stringValue"];
    [self exposeBinding:@"integerValue"];
    [self exposeBinding:@"intValue"];
    [self exposeBinding:@"doubleValue"];
    [self exposeBinding:@"floatValue"];

    [self exposeBinding:@"enabled"];
}

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding === CPValueBinding)
        return [_CPValueBinder class];
    else if ([aBinding hasPrefix:CPEnabledBinding])
        return [CPMultipleValueAndBinding class];

    return [super _binderClassForBinding:aBinding];
}

/*!
    Reverse set the binding iff the CPContinuouslyUpdatesValueBindingOption is set.
*/
- (void)_continuouslyReverseSetBinding
{
    var binderClass = [[self class] _binderClassForBinding:CPValueBinding],
        theBinding = [binderClass getBinding:CPValueBinding forObject:self];

    if ([theBinding continuouslyUpdatesValue])
        [theBinding reverseSetValueFor:@"objectValue"];
}

- (void)_reverseSetBinding
{
    var binderClass = [[self class] _binderClassForBinding:CPValueBinding],
        theBinding = [binderClass getBinding:CPValueBinding forObject:self];

    [theBinding reverseSetValueFor:@"objectValue"];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _sendActionOn = CPLeftMouseUpMask;
        _trackingMouseDownFlags = 0;
    }

    return self;
}

/*!
    Sets the receiver's target action.

    @param anAction Sets the action message that gets sent to the target.
*/
- (void)setAction:(SEL)anAction
{
    _action = anAction;
}

/*!
    Returns the receiver's target action.
*/
- (SEL)action
{
    return _action;
}

/*!
    Sets the receiver's target. The target receives action messages from the receiver.

    @param aTarget the object that will receive the message specified by action
*/
- (void)setTarget:(id)aTarget
{
    _target = aTarget;
}

/*!
    Returns the receiver's target. The target receives action messages from the receiver.
*/
- (id)target
{
    return _target;
}

/*!
    Causes \c anAction to be sent to \c anObject.

    @param anAction the action to send
    @param anObject the object to which the action will be sent
*/
- (BOOL)sendAction:(SEL)anAction to:(id)anObject
{
    [self _reverseSetBinding];

    var binding = [CPBinder getBinding:CPTargetBinding forObject:self];
    [binding invokeAction];

    return [CPApp sendAction:anAction to:anObject from:self];
}

- (int)sendActionOn:(int)mask
{
    var previousMask = _sendActionOn;

    _sendActionOn = mask;

    return previousMask;
}

/*!
    Returns whether the control can continuously send its action messages.
*/
- (BOOL)isContinuous
{
    // Some subclasses should redefine this with CPLeftMouseDraggedMask
    return (_sendActionOn & CPPeriodicMask) !== 0;
}

/*!
    Sets whether the cell can continuously send its action messages.
*/
- (void)setContinuous:(BOOL)flag
{
    // Some subclasses should redefine this with CPLeftMouseDraggedMask
    if (flag)
        _sendActionOn |= CPPeriodicMask;
    else
        _sendActionOn &= ~CPPeriodicMask;
}

/*!
    Returns YES if the receiver tracks the mouse outside the frame, otherwise NO.
*/
- (BOOL)tracksMouseOutsideOfFrame
{
    return NO;
}

- (void)trackMouse:(CPEvent)anEvent
{
    var type = [anEvent type],
        currentLocation = [self convertPoint:[anEvent locationInWindow] fromView:nil],
        isWithinFrame = [self tracksMouseOutsideOfFrame] || CGRectContainsPoint([self bounds], currentLocation);

    if (type === CPLeftMouseUp)
    {
        [self stopTracking:_previousTrackingLocation at:currentLocation mouseIsUp:YES];

        _trackingMouseDownFlags = 0;

        if (isWithinFrame)
            [self setThemeState:CPThemeStateHovered];
    }
    else
    {
        [self unsetThemeState:CPThemeStateHovered];

        if (type === CPLeftMouseDown)
        {
            _trackingMouseDownFlags = [anEvent modifierFlags];
            _continuousTracking = [self startTrackingAt:currentLocation];
        }
        else if (type === CPLeftMouseDragged)
        {
            if (isWithinFrame)
            {
                if (!_trackingWasWithinFrame)
                    _continuousTracking = [self startTrackingAt:currentLocation];

                else if (_continuousTracking)
                    _continuousTracking = [self continueTracking:_previousTrackingLocation at:currentLocation];
            }
            else
                [self stopTracking:_previousTrackingLocation at:currentLocation mouseIsUp:NO];
        }

        [CPApp setTarget:self selector:@selector(trackMouse:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
    }

    if ((_sendActionOn & (1 << type)) && isWithinFrame)
        [self sendAction:_action to:_target];

    _trackingWasWithinFrame = isWithinFrame;
    _previousTrackingLocation = currentLocation;
}

- (void)setState:(int)state
{
}

- (int)nextState
{
    return 0;
}

/*!
    Perform a click on the receiver.

    @param sender - The sender object
*/
- (void)performClick:(id)sender
{
    if (![self isEnabled])
        return;

    [self highlight:YES];
    [self setState:[self nextState]];

    try
    {
        [self sendAction:[self action] to:[self target]];
    }
    catch (e)
    {
        throw e;
    }
    finally
    {
        [CPTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(unhighlightButtonTimerDidFinish:) userInfo:nil repeats:NO];
    }
}

/*!
    @ignore
    Fired when the button timer finished, usually after the user hits enter.
*/
- (void)unhighlightButtonTimerDidFinish:(id)sender
{
    [self highlight:NO];
}

/*!
    Returns the mask of modifier keys held down when the user clicked.
*/
- (unsigned)mouseDownFlags
{
    return _trackingMouseDownFlags;
}

- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    [self highlight:YES];

    return (_sendActionOn & CPPeriodicMask) || (_sendActionOn & CPLeftMouseDraggedMask);
}

- (BOOL)continueTracking:(CGPoint)lastPoint at:(CGPoint)aPoint
{
    return (_sendActionOn & CPPeriodicMask) || (_sendActionOn & CPLeftMouseDraggedMask);
}

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    if (mouseIsUp)
        [self highlight:NO];
    else
        [self highlight:YES];
}

/*!
    Enabled controls accept first mouse by default.
*/
- (BOOL)acceptsFirstMouse:(CPEvent)anEvent
{
    return [self isEnabled];
}

- (void)mouseDown:(CPEvent)anEvent
{
    if (![self isEnabled])
        return;

    [self trackMouse:anEvent];
}

- (void)mouseEntered:(CPEvent)anEvent
{
    if (![self isEnabled])
        return;

    [self setThemeState:CPThemeStateHovered];
}

- (void)mouseExited:(CPEvent)anEvent
{
    var currentLocation = [self convertPoint:[anEvent locationInWindow] fromView:nil],
        isWithinFrame = [self tracksMouseOutsideOfFrame] || CGRectContainsPoint([self bounds], currentLocation);

    // Make sure we're not still in the frame because Cappuccino will sent mouseExited events
    // for all of the (ephemeral) subviews of a view as well.
    if (!isWithinFrame)
        [self unsetThemeState:CPThemeStateHovered];
}

/*!
    Returns the receiver's object value.
*/
- (id)objectValue
{
    return _value;
}

/*!
    Sets the receiver's object value.
*/
- (void)setObjectValue:(id)anObject
{
    _value = anObject;

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns the receiver's float value.
*/
- (float)floatValue
{
    var floatValue = parseFloat(_value, 10);
    return isNaN(floatValue) ? 0.0 : floatValue;
}

/*!
    Sets the receiver's float value.
*/
- (void)setFloatValue:(float)aValue
{
    [self setObjectValue:aValue];
}

/*!
    Returns the receiver's double value.
*/
- (double)doubleValue
{
    var doubleValue = parseFloat(_value, 10);
    return isNaN(doubleValue) ? 0.0 : doubleValue;
}

/*!
    Sets the receiver's double value.
*/
- (void)setDoubleValue:(double)anObject
{
    [self setObjectValue:anObject];
}

/*!
    Returns the receiver's int value.
*/
- (int)intValue
{
    var intValue = parseInt(_value, 10);
    return isNaN(intValue) ? 0.0 : intValue;
}

/*!
    Sets the receiver's int value.
*/
- (void)setIntValue:(int)anObject
{
    [self setObjectValue:anObject];
}

/*!
    Returns the receiver's int value.
*/
- (int)integerValue
{
    var intValue = parseInt(_value, 10);
    return isNaN(intValue) ? 0.0 : intValue;
}

/*!
    Sets the receiver's int value.
*/
- (void)setIntegerValue:(int)anObject
{
    [self setObjectValue:anObject];
}

/*!
    Returns the receiver's string value.
*/
- (CPString)stringValue
{
    if (_formatter && _value !== undefined)
    {
        var formattedValue = [self hasThemeState:CPThemeStateEditing] ? [_formatter editingStringForObjectValue:_value] : [_formatter stringForObjectValue:_value];

        if (formattedValue !== nil && formattedValue !== undefined)
            return formattedValue;
    }

    return (_value === undefined || _value === nil) ? "" : String(_value);
}

/*!
    Sets the receiver's string value.
*/
- (void)setStringValue:(CPString)aString
{
    // Cocoa raises an invalid parameter assertion and returns if you pass nil.
    if (aString === nil || aString === undefined)
    {
        CPLog.warn("nil or undefined sent to CPControl -setStringValue");
        return;
    }

    var value;

    if (_formatter)
    {
        value = nil;

        if ([_formatter getObjectValue:@ref(value) forString:aString errorDescription:nil] === NO)
        {
            // If the given string is non-empty and doesn't work, Cocoa tries an empty string.
            if (!aString || [_formatter getObjectValue:@ref(value) forString:@"" errorDescription:nil] === NO)
                value = undefined;  // Means the value is invalid
        }
    }
    else
        value = aString;

    [self setObjectValue:value];
}

- (void)takeDoubleValueFrom:(id)sender
{
    if ([sender respondsToSelector:@selector(doubleValue)])
        [self setDoubleValue:[sender doubleValue]];
}


- (void)takeFloatValueFrom:(id)sender
{
    if ([sender respondsToSelector:@selector(floatValue)])
        [self setFloatValue:[sender floatValue]];
}

- (void)takeIntegerValueFrom:(id)sender
{
    if ([sender respondsToSelector:@selector(integerValue)])
        [self setIntegerValue:[sender integerValue]];
}

- (void)takeIntValueFrom:(id)sender
{
    if ([sender respondsToSelector:@selector(intValue)])
        [self setIntValue:[sender intValue]];
}

- (void)takeObjectValueFrom:(id)sender
{
    if ([sender respondsToSelector:@selector(objectValue)])
        [self setObjectValue:[sender objectValue]];
}

- (void)takeStringValueFrom:(id)sender
{
    if ([sender respondsToSelector:@selector(stringValue)])
        [self setStringValue:[sender stringValue]];
}

- (void)textDidBeginEditing:(CPNotification)note
{
    //this looks to prevent false propagation of notifications for other objects
    if ([note object] != self)
        return;

    [[CPNotificationCenter defaultCenter] postNotificationName:CPControlTextDidBeginEditingNotification object:self userInfo:@{ "CPFieldEditor": [note object] }];
}

- (void)textDidChange:(CPNotification)note
{
    //this looks to prevent false propagation of notifications for other objects
    if ([note object] != self)
        return;

    [[CPNotificationCenter defaultCenter] postNotificationName:CPControlTextDidChangeNotification object:self userInfo:@{ "CPFieldEditor": [note object] }];
}

- (void)textDidEndEditing:(CPNotification)note
{
    //this looks to prevent false propagation of notifications for other objects
    if ([note object] != self)
        return;

    [self _reverseSetBinding];

    [[CPNotificationCenter defaultCenter] postNotificationName:CPControlTextDidEndEditingNotification object:self userInfo:@{ "CPFieldEditor": [note object] }];
}

/*!
    Sets the text alignment of the control.

    <pre>
    CPLeftTextAlignment
    CPCenterTextAlignment
    CPRightTextAlignment
    CPJustifiedTextAlignment
    CPNaturalTextAlignment
    </pre>
*/
- (void)setAlignment:(CPTextAlignment)alignment
{
    [self setValue:alignment forThemeAttribute:@"alignment"];
}

/*!
    Returns the text alignment of the control.
*/
- (CPTextAlignment)alignment
{
    return [self valueForThemeAttribute:@"alignment"];
}

/*!
    Set the vertical text alignment of the control.

    <pre>
    CPTopVerticalTextAlignment
    CPCenterVerticalTextAlignment
    CPBottomVerticalTextAlignment
    </pre>
*/
- (void)setVerticalAlignment:(CPTextVerticalAlignment)alignment
{
    [self setValue:alignment forThemeAttribute:@"vertical-alignment"];
}

/*!
    Returns the vertical text alignment of the receiver.
*/
- (CPTextVerticalAlignment)verticalAlignment
{
    return [self valueForThemeAttribute:@"vertical-alignment"];
}

/*!
    Sets the line break mode of the receiver.

    <pre>
    CPLineBreakByWordWrapping
    CPLineBreakByCharWrapping
    CPLineBreakByClipping
    CPLineBreakByTruncatingHead
    CPLineBreakByTruncatingTail
    CPLineBreakByTruncatingMiddle
    </pre>
*/
- (void)setLineBreakMode:(CPLineBreakMode)mode
{
    [self setValue:mode forThemeAttribute:@"line-break-mode"];
}

/*!
    Returns the line break mode of the control.
*/
- (CPLineBreakMode)lineBreakMode
{
    return [self valueForThemeAttribute:@"line-break-mode"];
}

/*!
    Sets the text color of the receiver.

    @param aColor - A CPColor object.
*/
- (void)setTextColor:(CPColor)aColor
{
    [self setValue:aColor forThemeAttribute:@"text-color"];
}

/*!
    Returns the text color of the receiver.
*/
- (CPColor)textColor
{
    return [self valueForThemeAttribute:@"text-color"];
}

/*!
    Sets the shadow color of the text for the receiver.
*/
- (void)setTextShadowColor:(CPColor)aColor
{
    [self setValue:aColor forThemeAttribute:@"text-shadow-color"];
}

/*!
    Returns the shadow color of the text for the control.
*/
- (CPColor)textShadowColor
{
    return [self valueForThemeAttribute:@"text-shadow-color"];
}

/*!
    Sets the shadow offset for the text.

    @param offset - a CGSize with the x and y offsets.
*/
- (void)setTextShadowOffset:(CGSize)offset
{
    [self setValue:offset forThemeAttribute:@"text-shadow-offset"];
}

/*!
    Returns the text shadow offset of the receiver.
*/
- (CGSize)textShadowOffset
{
    return [self valueForThemeAttribute:@"text-shadow-offset"];
}

/*!
    Sets the font of the control.
*/
- (void)setFont:(CPFont)aFont
{
    [self setValue:aFont forThemeAttribute:@"font"];
}

/*!
    Returns the font of the control.
*/
- (CPFont)font
{
    return [self valueForThemeAttribute:@"font"];
}

/*!
    Sets the image position of the control.

    <pre>
    CPNoImage
    CPImageOnly
    CPImageLeft
    CPImageRight
    CPImageBelow
    CPImageAbove
    CPImageOverlaps
    </pre>
*/
- (void)setImagePosition:(CPCellImagePosition)position
{
    [self setValue:position forThemeAttribute:@"image-position"];
}

/*!
    Returns the image position of the receiver.
*/
- (CPCellImagePosition)imagePosition
{
    return [self valueForThemeAttribute:@"image-position"];
}

/*!
    Sets the image scaling of the control.

    <pre>
    CPImageScaleProportionallyDown
    CPImageScaleAxesIndependently
    CPImageScaleNone
    CPImageScaleProportionallyUpOrDown
    </pre>
*/
- (void)setImageScaling:(CPImageScaling)scaling
{
    [self setValue:scaling forThemeAttribute:@"image-scaling"];
}

/*!
    Returns the image scaling of the control.
*/
- (CPImageScaling)imageScaling
{
    return [self valueForThemeAttribute:@"image-scaling"];
}

/*!
    Sets the enabled status of the control.
    Controls that are not enabled can not be used by the user and obtain the CPThemeStateDisabled theme state.

    @param BOOL - YES if the control should be enabled, otherwise NO.
*/
- (void)setEnabled:(BOOL)isEnabled
{
    if (isEnabled)
        [self unsetThemeState:CPThemeStateDisabled];
    else
        [self setThemeState:CPThemeStateDisabled];
}

/*!
    Returns YES if the receiver is enabled, otherwise NO.
*/
- (BOOL)isEnabled
{
    return ![self hasThemeState:CPThemeStateDisabled];
}

/*!
    Highlights the receiver.

    @param BOOL - YES if the receiver should be highlighted, otherwise NO.
*/
- (void)highlight:(BOOL)shouldHighlight
{
    [self setHighlighted:shouldHighlight];
}

/*!
    Highlights the receiver.

    @param BOOL - YES if the receiver should be highlighted, otherwise NO.
*/
- (void)setHighlighted:(BOOL)isHighlighted
{
    if (isHighlighted)
        [self setThemeState:CPThemeStateHighlighted];
    else
        [self unsetThemeState:CPThemeStateHighlighted];
}

/*!
    Returns YES if the control is highlighted, otherwise NO.
*/
- (BOOL)isHighlighted
{
    return [self hasThemeState:CPThemeStateHighlighted];
}

@end

var CPControlValueKey                   = @"CPControlValueKey",
    CPControlControlStateKey            = @"CPControlControlStateKey",
    CPControlIsEnabledKey               = @"CPControlIsEnabledKey",
    CPControlTargetKey                  = @"CPControlTargetKey",
    CPControlActionKey                  = @"CPControlActionKey",
    CPControlSendActionOnKey            = @"CPControlSendActionOnKey",
    CPControlFormatterKey               = @"CPControlFormatterKey",
    CPControlSendsActionOnEndEditingKey = @"CPControlSendsActionOnEndEditingKey",

    __Deprecated__CPImageViewImageKey   = @"CPImageViewImageKey";

@implementation CPControl (CPCoding)

/*
    Initializes the control by unarchiving it from a coder.

    @param aCoder the coder from which to unarchive the control
    @return the initialized control
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        [self setObjectValue:[aCoder decodeObjectForKey:CPControlValueKey]];

        [self setTarget:[aCoder decodeObjectForKey:CPControlTargetKey]];
        [self setAction:[aCoder decodeObjectForKey:CPControlActionKey]];

        [self sendActionOn:[aCoder decodeIntForKey:CPControlSendActionOnKey]];
        [self setSendsActionOnEndEditing:[aCoder decodeBoolForKey:CPControlSendsActionOnEndEditingKey]];

        [self setFormatter:[aCoder decodeObjectForKey:CPControlFormatterKey]];
    }

    return self;
}

/*
    Archives the control to the provided coder.

    @param aCoder the coder to which the control will be archived.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    if (_sendsActionOnEndEditing)
        [aCoder encodeBool:_sendsActionOnEndEditing forKey:CPControlSendsActionOnEndEditingKey];

    var objectValue = [self objectValue];

    if (objectValue !== nil)
        [aCoder encodeObject:objectValue forKey:CPControlValueKey];

    if (_target !== nil)
        [aCoder encodeConditionalObject:_target forKey:CPControlTargetKey];

    if (_action !== nil)
        [aCoder encodeObject:_action forKey:CPControlActionKey];

    [aCoder encodeInt:_sendActionOn forKey:CPControlSendActionOnKey];

    if (_formatter !== nil)
        [aCoder encodeObject:_formatter forKey:CPControlFormatterKey];
}

@end

var _CPControlSizeIdentifiers               = [],
    _CPControlCachedColorWithPatternImages  = {},
    _CPControlCachedThreePartImagePattern   = {};

_CPControlSizeIdentifiers[CPRegularControlSize] = "Regular";
_CPControlSizeIdentifiers[CPSmallControlSize]   = "Small";
_CPControlSizeIdentifiers[CPMiniControlSize]    = "Mini";

function _CPControlIdentifierForControlSize(aControlSize)
{
    return _CPControlSizeIdentifiers[aControlSize];
}

function _CPControlColorWithPatternImage(sizes, aClassName)
{
    var index = 1,
        count = arguments.length,
        identifier = "";

    for (; index < count; ++index)
        identifier += arguments[index];

    var color = _CPControlCachedColorWithPatternImages[identifier];

    if (!color)
    {
        var bundle = [CPBundle bundleForClass:[CPControl class]];

        color = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:aClassName + "/" + identifier + ".png"] size:sizes[identifier]]];

        _CPControlCachedColorWithPatternImages[identifier] = color;
    }

    return color;
}

function _CPControlThreePartImagePattern(isVertical, sizes, aClassName)
{
    var index = 2,
        count = arguments.length,
        identifier = "";

    for (; index < count; ++index)
        identifier += arguments[index];

    var color = _CPControlCachedThreePartImagePattern[identifier];

    if (!color)
    {
        var bundle = [CPBundle bundleForClass:[CPControl class]],
            path = aClassName + "/" + identifier;

        sizes = sizes[identifier];

        color = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:[
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + "0.png"] size:sizes[0]],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + "1.png"] size:sizes[1]],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + "2.png"] size:sizes[2]]
                ] isVertical:isVertical]];

        _CPControlCachedThreePartImagePattern[identifier] = color;
    }

    return color;
}
