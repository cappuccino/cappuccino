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

/*
    @global
    @group CPLineBreakMode
*/
CPLineBreakByWordWrapping       = 0;
/*
    @global
    @group CPLineBreakMode
*/
CPLineBreakByCharWrapping       = 1;
/*
    @global
    @group CPLineBreakMode
*/
CPLineBreakByClipping           = 2;
/*
    @global
    @group CPLineBreakMode
*/
CPLineBreakByTruncatingHead     = 3;
/*
    @global
    @group CPLineBreakMode
*/
CPLineBreakByTruncatingTail     = 4;
/*
    @global
    @group CPLineBreakMode
*/
CPLineBreakByTruncatingMiddle   = 5;

/*
    A textfield bezel with a squared corners.
	@global
	@group CPTextFieldBezelStyle
*/
CPTextFieldSquareBezel          = 0;
/*
    A textfield bezel with rounded corners.
	@global
	@group CPTextFieldBezelStyle
*/
CPTextFieldRoundedBezel         = 1;

var TOP_PADDING                 = 4.0,
    BOTTOM_PADDING              = 3.0;
    HORIZONTAL_PADDING          = 3.0;

#if PLATFORM(DOM)
var CPTextFieldDOMInputElement = nil;
#endif

var _CPTextFieldSquareBezelColor    = nil;

@implementation CPString (CPTextFieldAdditions)

/*
    Returns the string (<code>self</code>).
*/
- (CPString)string
{
    return self;
}

@end

/*
    This control displays editable text in a Cappuccino application.
*/
@implementation CPTextField : CPControl
{
    BOOL                    _isBordered;
    BOOL                    _isBezeled;
    CPTextFieldBezelStyle   _bezelStyle;
    
    BOOL                    _isEditable;
    BOOL                    _isSelectable;
    
    id                      _value;
    id                      _placeholderString;
    
    CPLineBreakMode         _lineBreakMode;
#if PLATFORM(DOM)
    DOMElement              _DOMTextElement;
#endif
}

/* @ignore */
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

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _value = @"";
        _placeholderString = @"";

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
/*
    Sets whether the textfield will have a bezeled border.
    @param shouldBeBezeled <code>YES</code> means the textfield will draw a bezeled border
*/
- (void)setBezeled:(BOOL)shouldBeBezeled
{
    if (_isBezeled == shouldBeBezeled)
        return;
    
    _isBezeled = shouldBeBezeled;
    
    [self _updateBackground];
}

/*
    Returns <code>YES</code> if the textfield draws a bezeled border.
*/
- (BOOL)isBezeled
{
    return _isBezeled;
}

/*
    Sets the textfield's bezel style.
    @param aBezelStyle the constant for the desired bezel style
*/
- (void)setBezelStyle:(CPTextFieldBezelStyle)aBezelStyle
{
    if (_bezelStyle == aBezelStyle)
        return;
    
    _bezelStyle = aBezelStyle;
    
    [self _updateBackground];
}

/*
    Returns the textfield's bezel style.
*/
- (CPTextFieldBezelStyle)bezelStyle
{
    return _bezelStyle;
}

/*
    Sets whether the textfield will have a border drawn.
    @param shouldBeBordered <code>YES</code> makes the textfield draw a border
*/
- (void)setBordered:(BOOL)shouldBeBordered
{
    if (_isBordered == shouldBeBordered)
        return;
        
    _isBordered = shouldBeBordered;
    
    [self _updateBackground];
}

/*
    Returns <code>YES</code> if the textfield has a border.
*/
- (BOOL)isBordered
{
    return _isBordered;
}

/* @ignore */
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

/* @ignore */
- (BOOL)acceptsFirstResponder
{
    return _isEditable;
}

/* @ignore */
- (BOOL)becomeFirstResponder
{
    var string = [self stringValue];

    [self setStringValue:@""];
    
#if PLATFORM(DOM)
    var element = [[self class] _inputElement];

    element.value = string;
    element.style.color = _DOMElement.style.color;
    element.style.font = _DOMElement.style.font;
    element.style.zIndex = 1000;
    element.style.width = CGRectGetWidth([self bounds]) - 3.0 + "px";
    element.style.marginTop = "0px";
    //element.style.left = _DOMTextElement.style.left;
    //element.style.top = _DOMTextElement.style.top;
      
    _DOMElement.appendChild(element);
    window.setTimeout(function() { element.focus(); }, 0.0);
    element.onblur = function () { [[self window] makeFirstResponder:[self window]]; };
    
    //element.onblur = function() { objj_debug_print_backtrace(); }
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
    
    // If current value is the placeholder value, remove it to allow user to update.
    if ([_value lowercaseString] == [[self placeholderString] lowercaseString])
        [self setStringValue:@""];    

    [[CPDOMWindowBridge sharedDOMWindowBridge] _propagateCurrentDOMEvent:YES];
#endif

    return YES;
}

/* @ignore */
- (BOOL)resignFirstResponder
{
#if PLATFORM(DOM)
    var element = [[self class] _inputElement];

    _DOMElement.removeChild(element);
    [self setStringValue:element.value];

    // If textfield has no value, then display the placeholderValue
    if (!_value || _value === "")
        [self setStringValue:[self placeholderString]];

#endif
    return YES;
}

/* 
    Sets whether or not the receiver text field can be edited
*/
- (void)setEditable:(BOOL)shouldBeEditable
{
    _isEditable = shouldBeEditable;
}

/*
    Returns <code>YES</code> if the textfield is currently editable by the user.
*/
- (BOOL)isEditable
{
    return _isEditable;
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    
#if PLATFORM(DOM)
    CPDOMDisplayServerSetStyleSize(_DOMTextElement, _frame.size.width - 2.0 * HORIZONTAL_PADDING, _frame.size.height - TOP_PADDING - BOTTOM_PADDING);
#endif
}

/*
    Returns <code>YES</code> if the field's text is selectable by the user.
*/
- (BOOL)isSelectable
{
    return _isSelectable;
}

/*
    Sets whether the field's text is selectable by the user.
    @param aFlag <code>YES</code> makes the text selectable
*/
- (void)setSelectable:(BOOL)aFlag
{
    _isSelectable = aFlag;
}

/*
    Sets the alignment of the text in the field.
    @param anAlignment
*/
- (void)setAlignment:(CPTextAlignment)anAlignment
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

/*
    Sets the way line breaks occur in the text field.
    @param aLineBreakMode the line break style
*/
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

/*
    Returns the string the text field.
*/
- (CPString)stringValue
{
    // All of this needs to be better.
#if PLATFORM(DOM)
    if ([[self window] firstResponder] == self)
        return [[self class] _inputElement].value;
#endif
    //if the content is the same as the placeholder value, return "" instead
    if ([_value lowercaseString] == [[self placeholderString] lowercaseString])
        return "";

    return [super stringValue];
}

/*
    @ignore
*/
- (void)setObjectValue:(id)aValue
{
    [super setObjectValue:aValue];
    
#if PLATFORM(DOM)
    var displayString = "";

    if (aValue && [aValue respondsToSelector:@selector(string)])
        displayString = [aValue string];
    else if (aValue)
        displayString += aValue;

    if ([[self window] firstResponder] == self)
        [[self class] _inputElement].value = displayString;

    if (CPFeatureIsCompatible(CPJavascriptInnerTextFeature))
        _DOMTextElement.innerText = displayString;
    else if (CPFeatureIsCompatible(CPJavascriptTextContentFeature))
        _DOMTextElement.textContent = displayString;
#endif
}

/*
    Returns the receiver's placeholder string
*/
- (CPString)placeholderString
{
    return _placeholderString;
}

/*
    Sets a placeholder string for the receiver.  The placeholder is displayed until editing begins,
    and after editing ends, if the text field has an empty string value
*/
-(void)setPlaceholderString:(CPString)aStringValue
{
    _placeholderString = aStringValue;

    //if there is no set value, automatically display the placeholder
    if (!_value) 
        [self setStringValue:aStringValue];
}

/*
    Adjusts the text field's size in the application.
*/
- (void)sizeToFit
{
#if PLATFORM(DOM)
    var size = [_value ? _value : @" " sizeWithFont:[self font]];
    
    [self setFrameSize:CGSizeMake(size.width + 2 * HORIZONTAL_PADDING, size.height + TOP_PADDING + BOTTOM_PADDING)];
#endif
}

/*
    Select all the text in the CPTextField.
*/
- (void)selectText:(id)sender
{
#if PLATFORM(DOM)
    var element = [[self class] _inputElement];
    
    if (element.parentNode == _DOMElement && ([self isEditable] || [self isSelectable]))
        element.select();
#endif
}

@end

var CPTextFieldIsSelectableKey  = @"CPTextFieldIsSelectableKey",
    CPTextFieldLineBreakModeKey = @"CPTextFieldLineBreakModeKey",
    CPTextFieldStringValueKey   = @"CPTextFieldStringValueKey",
    CPTextFieldIsEditableKey    = @"CPTextFieldIsEditableKey";

@implementation CPTextField (CPCoding)

/*
    Initializes the textfield with data from a coder.
    @param aCoder the coder from which to read the textfield data
    @return the initialized textfield
*/
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

        [self setEditable:[aCoder decodeBoolForKey:CPTextFieldIsEditableKey]];
        [self setSelectable:[aCoder decodeBoolForKey:CPTextFieldIsSelectableKey]];    
        [self setLineBreakMode:[aCoder decodeIntForKey:CPTextFieldLineBreakModeKey]];

        [self setStringValue:[aCoder decodeObjectForKey:CPTextFieldStringValueKey]];
    }
    
    return self;
}

/*
    Encodes the data of this textfield into the provided coder.
    @param aCoder the coder into which the data will be written
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeBool:_isSelectable forKey:CPTextFieldIsSelectableKey];
    [aCoder encodeInt:_lineBreakMode forKey:CPTextFieldLineBreakModeKey];
    
    [aCoder encodeObject:_value forKey:CPTextFieldStringValueKey];
    
    [aCoder encodeBool:_isEditable forKey:CPTextFieldIsEditableKey];
}

@end
