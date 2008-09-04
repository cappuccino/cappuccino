/*
 * CPTextField.j
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

import "CPControl.j"
import "CPStringDrawing.j"

#include "Platform/Platform.h"
#include "Platform/DOM/CPDOMDisplayServer.h"


CPLineBreakByWordWrapping       = 0,
CPLineBreakByCharWrapping       = 1,
CPLineBreakByClipping           = 2,
CPLineBreakByTruncatingHead     = 3,
CPLineBreakByTruncatingTail     = 4,
CPLineBreakByTruncatingMiddle   = 5;

CPTextFieldSquareBezel          = 0;
CPTextFieldRoundedBezel         = 1;

var TOP_PADDING                 = 4.0,
    BOTTOM_PADDING              = 3.0;
    HORIZONTAL_PADDING          = 3.0;

#if PLATFORM(DOM)
var CPTextFieldDOMInputElement = nil;
#endif

var _CPTextFieldSquareBezelColor    = nil;

@implementation CPString (CPTextFieldAdditions)

- (CPString)string
{
    return self;
}

@end

@implementation CPTextField : CPControl
{
    BOOL                    _isBordered;
    BOOL                    _isBezeled;
    CPTextFieldBezelStyle   _bezelStyle;
    
    BOOL                    _isEditable;
    BOOL                    _isSelectable;
    
    id                      _value;
    
    CPLineBreakMode         _lineBreakMode;
#if PLATFORM(DOM)
    DOMElement              _DOMTextElement;
#endif
}

#if PLATFORM(DOM)
+ (DOMElement)_inputElement
{
    if (!CPTextFieldDOMInputElement)
    {
        CPTextFieldDOMInputElement = document.createElement("input");
        CPTextFieldDOMInputElement.style.position = "absolute";
        CPTextFieldDOMInputElement.style.top = "0px";
        CPTextFieldDOMInputElement.style.left = "0px";
        CPTextFieldDOMInputElement.style.width = "100%"
        CPTextFieldDOMInputElement.style.height = "100%";
        CPTextFieldDOMInputElement.style.border = "0px";
        CPTextFieldDOMInputElement.style.padding = "0px";
        CPTextFieldDOMInputElement.style.whiteSpace = "pre";
        CPTextFieldDOMInputElement.style.background = "transparent";
        CPTextFieldDOMInputElement.style.outline = "none";
        CPTextFieldDOMInputElement.style.paddingLeft = HORIZONTAL_PADDING - 1.0 + "px";
        CPTextFieldDOMInputElement.style.paddingTop = TOP_PADDING - 2.0 + "px";
    }
    
    return CPTextFieldDOMInputElement;
}
#endif

- (id)initWithFrame:(CPRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _value = @"";
        
#if PLATFORM(DOM)
        _DOMTextElement = document.createElement("div");
        _DOMTextElement.style.position = "absolute";
        _DOMTextElement.style.top = TOP_PADDING + "px";
        _DOMTextElement.style.left = HORIZONTAL_PADDING + "px";
        _DOMTextElement.style.width = MAX(0.0, CGRectGetWidth(aFrame) - 2.0 * HORIZONTAL_PADDING) + "px";
        _DOMTextElement.style.height = MAX(0.0, CGRectGetHeight(aFrame) - TOP_PADDING - BOTTOM_PADDING) + "px";
        _DOMTextElement.style.whiteSpace = "pre";
        _DOMTextElement.style.cursor = "default";
        _DOMTextElement.style.zIndex = 100;

        _DOMElement.appendChild(_DOMTextElement);
#endif
        [self setAlignment:CPLeftTextAlignment];
    }
    
    return self;
}

// Setting the Bezel Style

- (void)setBezeled:(BOOL)shouldBeBezeled
{
    if (_isBezeled == shouldBeBezeled)
        return;
    
    _isBezeled = shouldBeBezeled;
    
    [self _updateBackground];
}

- (BOOL)isBezeled
{
    return _isBezeled;
}

- (void)setBezelStyle:(CPTextFieldBezelStyle)aBezelStyle
{
    if (_bezelStyle == aBezelStyle)
        return;
    
    _bezelStyle = aBezelStyle;
    
    [self _updateBackground];
}

- (CPTextFieldBezelStyle)bezelStyle
{
    return _bezelStyle;
}

- (void)setBordered:(BOOL)shouldBeBordered
{
    if (_isBordered == shouldBeBordered)
        return;
        
    _isBordered = shouldBeBordered;
    
    [self _updateBackground];
}

- (BOOL)isBordered
{
    return _isBordered;
}

- (void)_updateBackground
{
    if (_isBordered && _bezelStyle == CPTextFieldSquareBezel && _isBezeled)
    {
        if (!_CPTextFieldSquareBezelColor)
        {
            var bundle = [CPBundle bundleForClass:[CPTextField class]];
            
            _CPTextFieldSquareBezelColor = [CPColor colorWithPatternImage:[[CPNinePartImage alloc] initWithImageSlices:
                [
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTextField/CPTextFieldBezelSquare0.png"] size:CGSizeMake(2.0, 3.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTextField/CPTextFieldBezelSquare1.png"] size:CGSizeMake(1.0, 3.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTextField/CPTextFieldBezelSquare2.png"] size:CGSizeMake(2.0, 3.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTextField/CPTextFieldBezelSquare3.png"] size:CGSizeMake(2.0, 1.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTextField/CPTextFieldBezelSquare4.png"] size:CGSizeMake(1.0, 1.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTextField/CPTextFieldBezelSquare5.png"] size:CGSizeMake(2.0, 1.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTextField/CPTextFieldBezelSquare6.png"] size:CGSizeMake(2.0, 2.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTextField/CPTextFieldBezelSquare7.png"] size:CGSizeMake(1.0, 2.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPTextField/CPTextFieldBezelSquare8.png"] size:CGSizeMake(2.0, 2.0)]
                ]]];
        }
        
        [self setBackgroundColor:_CPTextFieldSquareBezelColor];
    }
    else
        [self setBackgroundColor:nil];
}

- (BOOL)acceptsFirstResponder
{
    return _isEditable;
}

- (BOOL)becomeFirstResponder
{
    var string = [self stringValue];

    [self setStringValue:@""];
    
    var element = [[self class] _inputElement];

    element.value = string;
    element.style.color = _DOMElement.style.color;
    element.style.font = _DOMElement.style.font;
    element.style.zIndex = 1000;
    element.style.width = CGRectGetWidth([self bounds]) - 3.0 + "px";
//    element.style.left = _DOMTextElement.style.left;
//    element.style.top = _DOMTextElement.style.top;
      
    _DOMElement.appendChild(element);
    window.setTimeout(function() { element.focus(); }, 0.0);
//    element.onblur = function() { objj_debug_print_backtrace(); }
    //element.select();
    
    element.onkeypress = function(aDOMEvent) 
    { 
        aDOMEvent = aDOMEvent || window.event;
        
        if (aDOMEvent.keyCode == 13) 
        {
            if(aDOMEvent.preventDefault)
                aDOMEvent.preventDefault(); 
            else if(aDOMEvent.stopPropagation)
                aDOMEvent.stopPropagation();
            
            element.blur();
            
            [self sendAction:[self action] to:[self target]];
            [[self window] makeFirstResponder:nil];
        } 
    };
    
    [[CPDOMWindowBridge sharedDOMWindowBridge] _propagateCurrentDOMEvent:YES];
    
    return YES;
}

- (BOOL)resignFirstResponder
{
    var element = [[self class] _inputElement];
    
    _DOMElement.removeChild(element);
    [self setStringValue:element.value];
    
    return YES;
}

- (void)setEditable:(BOOL)shouldBeEditable
{
    _isEditable = shouldBeEditable;
}

- (BOOL)isEditable
{
    return _isEditable;
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    
    CPDOMDisplayServerSetStyleSize(_DOMTextElement, _frame.size.width - 2.0 * HORIZONTAL_PADDING, _frame.size.height - TOP_PADDING - BOTTOM_PADDING);
}

- (BOOL)isSelectable
{
    return _isSelectable;
}

- (void)setSelectable:(BOOL)aFlag
{
    _isSelectable = aFlag;
}

- (void)setAlignment:(int)anAlignment
{
    if ([self alignment] == anAlignment)
        return;
    
    [super setAlignment:anAlignment];
    
#if PLATFORM(DOM)
    switch ([self alignment])
    {
        case CPLeftTextAlignment:       _DOMTextElement.style.textAlign = "left";
                                        break;
        case CPRightTextAlignment:      _DOMTextElement.style.textAlign = "right";
                                        break;
        case CPCenterTextAlignment:     _DOMTextElement.style.textAlign = "center";
                                        break;
        case CPJustifiedTextAlignment:  _DOMTextElement.style.textAlign = "justify";
                                        break;
        case CPNaturalTextAlignment:    _DOMTextElement.style.textAlign = "";
                                        break;
    }
#endif
}

- (void)setLineBreakMode:(CPLineBreakMode)aLineBreakMode
{
    _lineBreakMode = aLineBreakMode;
    
#if PLATFORM(DOM)
    switch (aLineBreakMode)
    {
        case CPLineBreakByTruncatingTail:   _DOMTextElement.style.textOverflow = "ellipsis";
                                            _DOMTextElement.style.whiteSpace = "nowrap";
                                            _DOMTextElement.style.overflow = "hidden";
                                            break;
                                            
        case CPLineBreakByWordWrapping:     _DOMTextElement.style.whiteSpace = "normal";
                                            _DOMTextElement.style.overflow = "hidden";
                                            _DOMTextElement.style.textOverflow = "clip";
                                            break;
    }
#endif
}

- (CPString)stringValue
{
    // All of this needs to be better.
#if PLATFORM(DOM)
    if ([[self window] firstResponder] == self)
        return [[self class] _inputElement].value;
#endif

    return [_value string];
}

- (void)setStringValue:(CPString)aStringValue
{
    _value = aStringValue;
    
#if PLATFORM(DOM)
    var cssString = _value ? [_value cssString] : @"";

    if (CPFeatureIsCompatible(CPJavascriptInnerTextFeature))
        _DOMTextElement.innerText = cssString;
    else if (CPFeatureIsCompatible(CPJavascriptTextContentFeature))
        _DOMTextElement.textContent = cssString;
#endif
}

- (void)sizeToFit
{
#if PLATFORM(DOM)
    var size = [_value ? _value : @" " sizeWithFont:[self font]];
    
    [self setFrameSize:CGSizeMake(size.width + 2 * HORIZONTAL_PADDING, size.height + TOP_PADDING + BOTTOM_PADDING)];
#endif
}

@end

var CPTextFieldIsSelectableKey  = @"CPTextFieldIsSelectableKey",
    CPTextFieldLineBreakModeKey = @"CPTextFieldLineBreakModeKey",
    CPTextFieldStringValueKey   = @"CPTextFieldStringValueKey";

@implementation CPTextField (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
#if PLATFORM(DOM)
    _DOMTextElement = document.createElement("div");
#endif

    self = [super initWithCoder:aCoder];
    
    if (self)
    {
        var bounds = [self bounds];
        
        _value = @"";
        
#if PLATFORM(DOM)
        _DOMTextElement.style.position = "absolute";
        _DOMTextElement.style.top = TOP_PADDING + "px";
        _DOMTextElement.style.left = HORIZONTAL_PADDING + "px";
        _DOMTextElement.style.width = MAX(0.0, CGRectGetWidth(bounds) - 2.0 * HORIZONTAL_PADDING) + "px";
        _DOMTextElement.style.height = MAX(0.0, CGRectGetHeight(bounds) - TOP_PADDING - BOTTOM_PADDING) + "px";
        _DOMTextElement.style.whiteSpace = "pre";
        _DOMTextElement.style.cursor = "default";
        
        _DOMElement.appendChild(_DOMTextElement);
#endif

        [self setSelectable:[aCoder decodeBoolForKey:CPTextFieldIsSelectableKey]];    
        [self setLineBreakMode:[aCoder decodeIntForKey:CPTextFieldLineBreakModeKey]];

        [self setStringValue:[aCoder decodeObjectForKey:CPTextFieldStringValueKey]];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeBool:_isSelectable forKey:CPTextFieldIsSelectableKey];
    [aCoder encodeInt:_lineBreakMode forKey:CPTextFieldLineBreakModeKey];
    
    [aCoder encodeObject:_value forKey:CPTextFieldStringValueKey];
}

@end
