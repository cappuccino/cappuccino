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

@import "CPFont.j"
@import "CPShadow.j"
@import "CPView.j"
@import "CPThemedValue.j"

#include "CoreGraphics/CGGeometry.h"
#include "CPThemedValue.h"
#include "Platform/Platform.h"

/*
    @global
    @group CPTextAlignment
*/
CPLeftTextAlignment         = 0;
/*
    @global
    @group CPTextAlignment
*/
CPRightTextAlignment        = 1;
/*
    @global
    @group CPTextAlignment
*/
CPCenterTextAlignment       = 2;
/*
    @global
    @group CPTextAlignment
*/
CPJustifiedTextAlignment    = 3;
/*
    @global
    @group CPTextAlignment
*/
CPNaturalTextAlignment      = 4;

/*
    @global
    @group CPControlSize
*/
CPRegularControlSize        = 0;
/*
    @global
    @group CPControlSize
*/
CPSmallControlSize          = 1;
/*
    @global
    @group CPControlSize
*/
CPMiniControlSize           = 2;

CPControlNormalBackgroundColor      = "CPControlNormalBackgroundColor";
CPControlSelectedBackgroundColor    = "CPControlSelectedBackgroundColor";
CPControlHighlightedBackgroundColor = "CPControlHighlightedBackgroundColor";
CPControlDisabledBackgroundColor    = "CPControlDisabledBackgroundColor";

CPControlTextDidBeginEditingNotification    = "CPControlTextDidBeginEditingNotification";
CPControlTextDidChangeNotification          = "CPControlTextDidChangeNotification";
CPControlTextDidEndEditingNotification      = "CPControlTextDidEndEditingNotification";

var CPControlBlackColor     = [CPColor blackColor];

/*! @class CPControl

    CPControl is an abstract superclass used to implement user interface elements. As a subclass of CPView and CPResponder it has the ability to handle screen drawing and handling user input.
*/
@implementation CPControl : CPView
{
    id                  _value;
    
    // Target-Action Support
    id                  _target;
    SEL                 _action;
    int                 _sendActionOn;
    
    // Mouse Tracking Support
    BOOL                _continuousTracking;
    BOOL                _trackingWasWithinFrame;
    unsigned            _trackingMouseDownFlags;
    CGPoint             _previousTrackingLocation;
    
    // Properties
    CPThemedValue   _alignment;
    CPThemedValue   _verticalAlignment;
    
    CPControlStateValue _lineBreakMode;
    CPControlStateValue _textColor;
    CPControlStateValue _font;
    
    CPControlStateValue _textShadowColor;
    CPControlStateValue _textShadowOffset;
    
    CPControlStateValue _imagePosition;
    CPControlStateValue _imageScaling;
    
    CPControlState      _controlState;
    
    // FIXME: Who uses this?
    BOOL _isBezeled;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _controlState = CPControlStateNormal;
        
        var theme = [self theme],
            theClass = [self class];
        
        _alignment = CPThemedValueMake(CPLeftTextAlignment, "alignment", theme, theClass);
        _verticalAlignment = CPThemedValueMake(CPTopVerticalTextAlignment, "vertical-alignment", theme, theClass);
        
        _lineBreakMode = CPThemedValueMake(CPLineBreakByClipping, "line-break-mode", theme, theClass);
        _textColor = CPThemedValueMake([CPColor blackColor], "text-color", theme, theClass);
        _font = CPThemedValueMake([CPFont systemFontOfSize:12.0], "font", theme, theClass);
        
        _textShadowColor = CPThemedValueMake(nil, @"text-shadow-color", theme, theClass);
        _textShadowOffset = CPThemedValueMake(_CGSizeMake(0.0, 0.0), "text-shadow-offset", theme, theClass);
        
        _imagePosition = CPThemedValueMake(CPImageLeft, @"image-position", theme, theClass);
        _imageScaling = CPThemedValueMake(CPScaleToFit, "image-scaling", theme, theClass);
        
        [theme setActiveClass:nil];
        //
        
        _sendActionOn = CPLeftMouseUpMask;
        _trackingMouseDownFlags = 0;
    }
    
    return self;
}

/*!
    Sets the receiver's target action
    @param anAction Sets the action message that gets sent to the target.
*/
- (void)setAction:(SEL)anAction
{
    _action = anAction;
}

/*!
    Returns the receiver's target action
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
    Causes <code>anAction</code> to be sent to <code>anObject</code>.
    @param anAction the action to send
    @param anObject the object to which the action will be sent
*/
- (void)sendAction:(SEL)anAction to:(id)anObject
{
    [CPApp sendAction:anAction to:anObject from:self];
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

- (BOOL)tracksMouseOutsideOfFrame
{
    return NO;
}

- (void)trackMouse:(CPEvent)anEvent
{
    var type = [anEvent type],
        currentLocation = [self convertPoint:[anEvent locationInWindow] fromView:nil];
        isWithinFrame = [self tracksMouseOutsideOfFrame] || CGRectContainsPoint([self bounds], currentLocation);

    if (type === CPLeftMouseUp)
    {
        [self stopTracking:_previousTrackingLocation at:currentLocation mouseIsUp:YES];
        
        _trackingMouseDownFlags = 0;
    }
    
    else
    {
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
    [self highlight:NO];
}

- (void)mouseDown:(CPEvent)anEvent
{
    if (![self isEnabled])
        return;
    
    [self trackMouse:anEvent];
}

/*!
    Returns the receiver's object value
*/
- (id)objectValue
{
    return _value;
}

/*!
    Set's the receiver's object value
*/
- (void)setObjectValue:(id)anObject
{
    _value = anObject;
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns the receiver's float value
*/
- (float)floatValue
{
    var floatValue = parseFloat(_value, 10);
    return isNaN(floatValue) ? 0.0 : floatValue;
}

/*!
    Sets the receiver's float value
*/
- (void)setFloatValue:(float)aValue
{
    [self setObjectValue:aValue];
}

/*!
    Returns the receiver's double value
*/
- (double)doubleValue
{
    var doubleValue = parseFloat(_value, 10);
    return isNaN(doubleValue) ? 0.0 : doubleValue;
}

/*!
    Set's the receiver's double value
*/
- (void)setDoubleValue:(double)anObject
{
    [self setObjectValue:anObject];
}

/*!
    Returns the receiver's int value
*/
- (int)intValue
{
    var intValue = parseInt(_value, 10);
    return isNaN(intValue) ? 0.0 : intValue;
}

/*!
    Set's the receiver's int value
*/
- (void)setIntValue:(int)anObject
{
    [self setObjectValue:anObject];
}

/*!
    Returns the receiver's int value
*/
- (int)integerValue
{
    var intValue = parseInt(_value, 10);
    return isNaN(intValue) ? 0.0 : intValue;
}

/*!
    Set's the receiver's int value
*/
- (void)setIntegerValue:(int)anObject
{
    [self setObjectValue:anObject];
}

/*!
    Returns the receiver's int value
*/
- (CPString)stringValue
{
    return _value ? String(_value) : "";
}

/*!
    Set's the receiver's int value
*/
- (void)setStringValue:(CPString)anObject
{
    [self setObjectValue:anObject];
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
    if([note object] != self)
        return;

    [[CPNotificationCenter defaultCenter] postNotificationName:CPControlTextDidBeginEditingNotification object:self userInfo:[CPDictionary dictionaryWithObject:[note object] forKey:"CPFieldEditor"]];
}

- (void)textDidChange:(CPNotification)note 
{
    //this looks to prevent false propagation of notifications for other objects
    if([note object] != self)
        return;

    [[CPNotificationCenter defaultCenter] postNotificationName:CPControlTextDidChangeNotification object:self userInfo:[CPDictionary dictionaryWithObject:[note object] forKey:"CPFieldEditor"]];
}

- (void)textDidEndEditing:(CPNotification)note 
{
    //this looks to prevent false propagation of notifications for other objects
    if([note object] != self)
        return;

    [[CPNotificationCenter defaultCenter] postNotificationName:CPControlTextDidEndEditingNotification object:self userInfo:[CPDictionary dictionaryWithObject:[note object] forKey:"CPFieldEditor"]];
}

THEMED_STATED_VALUE(Alignment, alignment)
THEMED_STATED_VALUE(VerticalAlignment, verticalAlignment)
THEMED_STATED_VALUE(LineBreakMode, lineBreakMode)
THEMED_STATED_VALUE(TextColor, textColor)
THEMED_STATED_VALUE(Font, font)
THEMED_STATED_VALUE(TextShadowColor, textShadowColor)
THEMED_STATED_VALUE(TextShadowOffset, textShadowOffset)
THEMED_STATED_VALUE(ImagePosition, imagePosition)
THEMED_STATED_VALUE(ImageScaling, imageScaling)

- (int)controlState
{
    return _controlState;
}

- (void)setEnabled:(BOOL)isEnabled
{
    if ((!(_controlState & CPControlStateDisabled)) === isEnabled)
        return;
    
    if (isEnabled)
        _controlState &= ~CPControlStateDisabled;
    else
        _controlState |= CPControlStateDisabled;
        
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (BOOL)isEnabled
{
    return !(_controlState & CPControlStateDisabled);
}

- (void)highlight:(BOOL)shouldHighlight
{
    [self setHighlighted:shouldHighlight];
}

- (void)setHighlighted:(BOOL)isHighlighted
{
    if ((!!(_controlState & CPControlStateHighlighted)) === isHighlighted)
        return;

    if (isHighlighted)
        _controlState |= CPControlStateHighlighted;
    else
        _controlState &= ~CPControlStateHighlighted;
        
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (BOOL)isHighlighted
{
    return !!(_controlState & CPControlStateHighlighted);
}

@end

@implementation CPControl (Theming)

- (void)viewDidChangeTheme
{
    [super viewDidChangeTheme];
    
    var theme = [self theme];
    
    [_alignment setTheme:theme];
    [_verticalAlignment setTheme:theme];
    
    [_lineBreakMode setTheme:theme];
    [_textColor setTheme:theme];
    [_font setTheme:theme];
    
    [_textShadowColor setTheme:theme];
    [_textShadowOffset setTheme:theme];
    
    [_imagePositions setTheme:theme];
    [_imageScaling setTheme:theme];
}

- (CPDictionary)themedValues
{
    var values = [super themedValues];

    [values setObject:_alignment forKey:@"alignment"];
    [values setObject:_verticalAlignment forKey:@"vertical-alignment"];
    
    [values setObject:_lineBreakMode forKey:@"line-break-mode"];
    [values setObject:_textColor forKey:@"text-color"];
    [values setObject:_font forKey:@"font"];
    
    [values setObject:_textShadowColor forKey:@"text-shadow-color"];
    [values setObject:_textShadowOffset forKey:@"text-shadow-offset"];
    
    [values setObject:_imagePosition forKey:@"image-position"];
    [values setObject:_imageScaling forKey:@"image-scaling"];

    return values;
}

@end

var CPControlValueKey           = "CPControlValueKey",
    CPControlIsEnabledKey       = "CPControlIsEnabledKey",
    
    CPControlAlignmentKey           = @"CPControlAlignmentKey",
    CPControlVerticalAlignmentKey   = @"CPControlVerticalAlignmentKey",
    CPControlLineBreakModeKey       = @"CPControlLineBreakModeKey",
    CPControlFontKey                = @"CPControlFontKey",
    CPControlTextColorKey           = @"CPControlTextColorKey",
    CPControlTextShadowColorKey     = @"CPControlTextShadowColorKey",
    CPControlTextShadowOffsetKey    = @"CPControlTextShadowOffsetKey",
    CPControlImagePositionKey       = @"CPControlImagePositionKey",
    CPControlImageScalingKey        = @"CPControlImageScalingKey",
    
    CPControlTargetKey          = "CPControlTargetKey",
    CPControlActionKey          = "CPControlActionKey",
    CPControlSendActionOnKey    = "CPControlSendActionOnKey";

var __Deprecated__CPImageViewImageKey   = @"CPImageViewImageKey";

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
        _controlState = CPControlStateNormal;
        
        var theme = [self theme],
            theClass = [self class];
        
        [self setObjectValue:[aCoder decodeObjectForKey:CPControlValueKey]];

        _alignment = CPThemedValueDecode(aCoder, CPControlAlignmentKey, CPLeftTextAlignment, @"alignment", theme, theClass);
        _verticalAlignment = CPThemedValueDecode(aCoder, CPControlVerticalAlignmentKey, CPTopVerticalTextAlignment, @"vertical-alignment", theme, theClass);
    
        _lineBreakMode = CPThemedValueDecode(aCoder, CPControlLineBreakModeKey, CPLineBreakByClipping, @"line-break-mode", theme, theClass);
        _textColor = CPThemedValueDecode(aCoder, CPControlTextColorKey, [CPColor blackColor], @"text-color", theme, theClass);
        _font = CPThemedValueDecode(aCoder, CPControlFontKey, [CPFont systemFontOfSize:12.0], @"font", theme, theClass);

        _textShadowColor = CPThemedValueDecode(aCoder, CPControlTextShadowColorKey, nil, @"text-shadow-color", theme, theClass);
        _textShadowOffset = CPThemedValueDecode(aCoder, CPControlTextShadowOffsetKey, _CGSizeMake(0.0, 0.0), @"text-shadow-offset", theme, theClass);
    
        _imagePosition = CPThemedValueDecode(aCoder, CPControlImagePositionKey, CPImageLeft, @"image-position", theme, theClass);
        _imageScaling = CPThemedValueDecode(aCoder, CPControlImageScalingKey, CPScaleToFit, @"image-scaling", theme, theClass);

        /*
        [self setTarget:[aCoder decodeObjectForKey:CPControlTargetKey]];
        [self setAction:[aCoder decodeObjectForKey:CPControlActionKey]];
        [self sendActionOn:[aCoder decodeIntForKey:CPControlSendActionOnKey]];*/
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
    
    [aCoder encodeObject:_value forKey:CPControlValueKey];

    CPThemedValueEncode(aCoder, CPControlAlignmentKey, _alignment);
    CPThemedValueEncode(aCoder, CPControlVerticalAlignmentKey, _verticalAlignment);

    CPThemedValueEncode(aCoder, CPControlLineBreakModeKey, _lineBreakMode);
    CPThemedValueEncode(aCoder, CPControlTextColorKey, _textColor);
    CPThemedValueEncode(aCoder, CPControlFontKey, _font);

    CPThemedValueEncode(aCoder, CPControlTextShadowColorKey, _textShadowColor);
    CPThemedValueEncode(aCoder, CPControlTextShadowOffsetKey, _textShadowOffset);
    
    CPThemedValueEncode(aCoder, CPControlImagePositionKey, _imagePosition);
    CPThemedValueEncode(aCoder, CPControlImageScalingKey, _imageScaling);

    /*
    [aCoder encodeBool:_isEnabled forKey:CPControlIsEnabledKey];
    
    [aCoder encodeInt:_alignment forKey:CPControlAlignmentKey];
    [aCoder encodeInt:_verticalAlignment forKey:CPControlVerticalAlignmentKey];
    
    [aCoder encodeObject:_font forKey:CPControlFontKey];
    [aCoder encodeObject:_textColor forKey:CPControlTextColorKey];
    
    [aCoder encodeConditionalObject:_target forKey:CPControlTargetKey];
    [aCoder encodeObject:_action forKey:CPControlActionKey];
    
    [aCoder encodeInt:_sendActionOn forKey:CPControlSendActionOnKey];*/
}

@end

var _CPControlSizeIdentifiers               = [],
    _CPControlCachedThreePartImages         = {},
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

function _CPControlThreePartImages(sizes, aClassName)
{
    var index = 1,
        count = arguments.length,
        identifier = "";
    
    for (; index < count; ++index)
        identifier += arguments[index];

    var images = _CPControlCachedThreePartImages[identifier];
    
    if (!images)
    {
        var bundle = [CPBundle bundleForClass:[CPControl class]],
            path = aClassName + "/" + identifier;
        
        sizes = sizes[identifier];

        images = [
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + "0.png"] size:sizes[0]],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + "1.png"] size:sizes[1]],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + "2.png"] size:sizes[2]]
                ];
                
        _CPControlCachedThreePartImages[identifier] = images;
    }
    
    return images;
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
