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

import "CPFont.j"
import "CPShadow.j"
import "CPView.j"

#include "Platform/Platform.h"


CPLeftTextAlignment         = 0;
CPRightTextAlignment        = 1;
CPCenterTextAlignment       = 2;
CPJustifiedTextAlignment    = 3;
CPNaturalTextAlignment      = 4;

CPRegularControlSize        = 0;
CPSmallControlSize          = 1;
CPMiniControlSize           = 2;

CPControlNormalBackgroundColor      = @"CPControlNormalBackgroundColor";
CPControlSelectedBackgroundColor    = @"CPControlSelectedBackgroundColor";
CPControlHighlightedBackgroundColor = @"CPControlHighlightedBackgroundColor";
CPControlDisabledBackgroundColor    = @"CPControlDisabledBackgroundColor";

var CPControlBlackColor     = [CPColor blackColor];

@implementation CPControl : CPView
{
    id          _value;

    BOOL        _isEnabled;
    
    int         _alignment;
    CPFont      _font;
    CPColor     _textColor;
    CPShadow    _textShadow;
    
    id          _target;
    SEL         _action;
    int         _sendActionOn;
    
    CPColor     _backgroundColor;
    CPColor     _highlightedBackgroundColor;
    
    CPDictionary    _backgroundColors;
    CPString        _currentBackgroundColorName;
}

- (id)initWithFrame:(CPRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _sendActionOn = CPLeftMouseUpMask;
        _isEnabled = YES;
        
        [self setFont:[CPFont systemFontOfSize:12.0]];
        [self setTextColor:CPControlBlackColor];
        
        _backgroundColors = [CPDictionary dictionary];
    }
    
    return self;
}

- (void)setEnabled:(BOOL)isEnabled
{
    [self setAlphaValue:(_isEnabled = isEnabled) ? 1.0 : 0.3];
}

- (BOOL)isEnabled
{
    return _isEnabled;
}

- (void)setTextColor:(CPColor)aColor
{
    if (_textColor == aColor)
        return;
    
    _textColor = aColor;

#if PLATFORM(DOM)
    _DOMElement.style.color = [aColor cssString];
#endif
}

- (CPColor)textColor
{
    return _textColor;
}

- (int)alignment
{
    return _alignment;
}

- (void)setAlignment:(int)anAlignment
{
    _alignment = anAlignment;
}

- (void)setFont:(CPFont)aFont
{
    if (_font == aFont)
        return;
    
    _font = aFont;
    
#if PLATFORM(DOM)
    _DOMElement.style.font = [_font ? _font : [CPFont systemFontOfSize:12.0] cssString];
#endif
}

- (CPFont)font
{
    return _font;
}

- (void)setTextShadow:(CPShadow)aTextShadow
{
    _DOMElement.style.textShadow = [_textShadow = aTextShadow cssString];
}

- (CPShadow)textShadow
{
    return _textShadow;
}

- (SEL)action
{
    return _action;
}

- (void)setAction:(SEL)anAction
{
    _action = anAction;
}

- (id)target
{
    return _target;
}

- (void)setTarget:(id)aTarget
{
    _target = aTarget;
}

- (void)mouseUp:(CPEvent)anEvent
{
    if (_sendActionOn & CPLeftMouseUpMask && CPRectContainsPoint([self bounds], [self convertPoint:[anEvent locationInWindow] fromView:nil]))
        [self sendAction:_action to:_target];
    
    [super mouseUp:anEvent];
}

- (void)sendAction:(SEL)anAction to:(id)anObject
{
    [CPApp sendAction:anAction to:anObject from:self];
}

- (float)floatValue
{
    return _value ? parseFloat(_value) : 0.0;
}

- (void)setFloatValue:(float)aValue
{
    _value = aValue;
}

- (void)setBackgroundColor:(CPColor)aColor
{
    _backgroundColors = [CPDictionary dictionary];
    
    [self setBackgroundColor:aColor forName:CPControlNormalBackgroundColor];
    
    [super setBackgroundColor:aColor];
}

- (void)setBackgroundColor:(CPColor)aColor forName:(CPString)aName
{
    if (!aColor)
        [_backgroundColors removeObjectForKey:aName];
    else
        [_backgroundColors setObject:aColor forKey:aName];
        
    if (_currentBackgroundColorName == aName)
        [self setBackgroundColorWithName:_currentBackgroundColorName];
}

- (CPColor)backgroundColorForName:(CPString)aName
{
    var backgroundColor = [_backgroundColors objectForKey:aName];
    
    if (!backgroundColor && aName != CPControlNormalBackgroundColor)
        return [_backgroundColors objectForKey:CPControlNormalBackgroundColor];
        
    return backgroundColor;
}

- (void)setBackgroundColorWithName:(CPString)aName
{
    _currentBackgroundColorName = aName;
    
    [super setBackgroundColor:[self backgroundColorForName:aName]];
}

/*
Ð doubleValue  
Ð setDoubleValue:
Ð intValue  
Ð setIntValue:  
Ð objectValue  
Ð setObjectValue:  
Ð stringValue  
Ð setStringValue:  
Ð setNeedsDisplay  
Ð attributedStringValue  
Ð setAttributedStringValue:  */

@end

var CPControlIsEnabledKey       = @"CPControlIsEnabledKey",
    CPControlAlignmentKey       = @"CPControlAlignmentKey",
    CPControlFontKey            = @"CPControlFontKey",
    CPControlTextColorKey       = @"CPControlTextColorKey",
    CPControlTargetKey          = @"CPControlTargetKey",
    CPControlActionKey          = @"CPControlActionKey",
    CPControlSendActionOnKey    = @"CPControlSendActionOnKey";

@implementation CPControl (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    
    if (self)
    {
        [self setEnabled:[aCoder decodeIntForKey:CPControlIsEnabledKey]];
        
        [self setAlignment:[aCoder decodeIntForKey:CPControlAlignmentKey]];
        [self setFont:[aCoder decodeObjectForKey:CPControlFontKey]];
        [self setTextColor:[aCoder decodeObjectForKey:CPControlTextColorKey]];
        
        [self setTarget:[aCoder decodeObjectForKey:CPControlTargetKey]];
        [self setAction:[aCoder decodeObjectForKey:CPControlActionKey]];
    
        _sendActionOn = [aCoder decodeIntForKey:CPControlSendActionOnKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeInt:_isEnabled forKey:CPControlIsEnabledKey];
    
    [aCoder encodeInt:_alignment forKey:CPControlAlignmentKey];
    [aCoder encodeObject:_font forKey:CPControlFontKey];
    [aCoder encodeObject:_textColor forKey:CPControlTextColorKey];
    
    [aCoder encodeConditionalObject:_target forKey:CPControlTargetKey];
    [aCoder encodeObject:_action forKey:CPControlActionKey];
    
    [aCoder encodeInt:_sendActionOn forKey:CPControlSendActionOnKey];
}

@end

var _CPControlSizeIdentifiers               = [],
    _CPControlCachedThreePartImages         = {},
    _CPControlCachedColorWithPatternImages  = {},
    _CPControlCachedThreePartImagePattern   = {};

_CPControlSizeIdentifiers[CPRegularControlSize] = @"Regular";
_CPControlSizeIdentifiers[CPSmallControlSize]   = @"Small";
_CPControlSizeIdentifiers[CPMiniControlSize]    = @"Mini";
    
function _CPControlIdentifierForControlSize(aControlSize)
{
    return _CPControlSizeIdentifiers[aControlSize];
}

function _CPControlColorWithPatternImage(sizes, aClassName)
{
    var index = 1,
        count = arguments.length,
        identifier = @"";
    
    for (; index < count; ++index)
        identifier += arguments[index];
    
    var color = _CPControlCachedColorWithPatternImages[identifier];
    
    if (!color)
    {
        var bundle = [CPBundle bundleForClass:[CPControl class]];
    
        color = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:aClassName + "/" + identifier + @".png"] size:sizes[identifier]]];

        _CPControlCachedColorWithPatternImages[identifier] = color;
    }
    
    return color;
}

function _CPControlThreePartImages(sizes, aClassName)
{
    var index = 1,
        count = arguments.length,
        identifier = @"";
    
    for (; index < count; ++index)
        identifier += arguments[index];

    var images = _CPControlCachedThreePartImages[identifier];
    
    if (!images)
    {
        var bundle = [CPBundle bundleForClass:[CPControl class]],
            path = aClassName + "/" + identifier;
        
        sizes = sizes[identifier];

        images = [
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + @"0.png"] size:sizes[0]],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + @"1.png"] size:sizes[1]],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + @"2.png"] size:sizes[2]]
                ];
                
        _CPControlCachedThreePartImages[identifier] = images;
    }
    
    return images;
}

function _CPControlThreePartImagePattern(isVertical, sizes, aClassName)
{
    var index = 2,
        count = arguments.length,
        identifier = @"";
    
    for (; index < count; ++index)
        identifier += arguments[index];

    var color = _CPControlCachedThreePartImagePattern[identifier];
    
    if (!color)
    {
        var bundle = [CPBundle bundleForClass:[CPControl class]],
            path = aClassName + "/" + identifier;
        
        sizes = sizes[identifier];

        color = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:[
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + @"0.png"] size:sizes[0]],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + @"1.png"] size:sizes[1]],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:path + @"2.png"] size:sizes[2]]
                ] isVertical:isVertical]];
                
        _CPControlCachedThreePartImagePattern[identifier] = color;
    }
    
    return color;
}

