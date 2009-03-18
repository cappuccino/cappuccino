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

@import "CPControl.j"
@import "CPStringDrawing.j"

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
CPTextFieldRoundedBezel             = 1;

var TOP_PADDING                     = 4.0,
    BOTTOM_PADDING                  = 3.0;
    HORIZONTAL_PADDING              = 3.0;
    ROUNDEDBEZEL_HORIZONTAL_PADDING = 8.0;

#if PLATFORM(DOM)
var CPTextFieldDOMInputElement = nil;
#endif

var _CPTextFieldSquareBezelColor = nil,
    _CPTextFieldRoundedBezelColor = nil;

@implementation CPString (CPTextFieldAdditions)

/*!
    Returns the string (<code>self</code>).
*/
- (CPString)string
{
    return self;
}

@end

/*!
    This control displays editable text in a Cappuccino application.
*/
@implementation CPTextField : CPControl
{
    BOOL                    _isEditable;
    BOOL                    _isSelectable;

    BOOL                    _isBordered;
    BOOL                    _isBezeled;
    CPTextFieldBezelStyle   _bezelStyle;
    BOOL                    _drawsBackground;
    
    CPLineBreakMode         _lineBreakMode;
    CPColor                 _textFieldBackgroundColor;
    
    id                      _placeholderString;
    
    id                      _delegate;
    
    CPString                _textDidChangeValue;
    
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
        _value = "";
        _placeholderString = "";

        _sendActionOn = CPKeyUpMask | CPKeyDownMask;
        
#if PLATFORM(DOM)
        _DOMTextElement = document.createElement("div");
        _DOMTextElement.style.position = "absolute";
        _DOMTextElement.style.top = TOP_PADDING + "px";
        if (_isBezeled && _bezelStyle == CPTextFieldRoundedBezel)
        {
            _DOMTextElement.style.left = ROUNDEDBEZEL_HORIZONTAL_PADDING + "px";
            _DOMTextElement.style.width = MAX(0.0, CGRectGetWidth(aFrame) - 2.0 * ROUNDEDBEZEL_HORIZONTAL_PADDING - 2.0) + "px";
        }
        else
        {
            _DOMTextElement.style.left = HORIZONTAL_PADDING + "px";
            _DOMTextElement.style.width = MAX(0.0, CGRectGetWidth(aFrame) - 2.0 * HORIZONTAL_PADDING) + "px";
        }
        _DOMTextElement.style.height = MAX(0.0, CGRectGetHeight(aFrame) - TOP_PADDING - BOTTOM_PADDING) + "px";
        _DOMTextElement.style.whiteSpace = "pre";
        _DOMTextElement.style.cursor = "default";
        _DOMTextElement.style.zIndex = 100;
        _DOMTextElement.style.overflow = "hidden";

        _DOMElement.appendChild(_DOMTextElement);
#endif
        [self setAlignment:CPLeftTextAlignment];
    }
    
    return self;
}

- (void)setDelegate:(id)aDelegate
{
    var center = [CPNotificationCenter defaultCenter];
    
    //unsubscribe the existing delegate if it exists
    if (_delegate)
    {
        [center removeObserver:_delegate name:CPControlTextDidBeginEditingNotification object:self];
        [center removeObserver:_delegate name:CPControlTextDidChangeNotification object:self];
        [center removeObserver:_delegate name:CPControlTextDidEndEditingNotification object:self];
    }
    
    _delegate = aDelegate;
    
    if ([_delegate respondsToSelector:@selector(controlTextDidBeginEditing:)])
        [center addObserver:_delegate selector:@selector(controlTextDidBeginEditing:) name:CPControlTextDidBeginEditingNotification object:self];
    if ([_delegate respondsToSelector:@selector(controlTextDidChange:)])
        [center addObserver:_delegate selector:@selector(controlTextDidChange:) name:CPControlTextDidChangeNotification object:self];
    if ([_delegate respondsToSelector:@selector(controlTextDidEndEditing:)])
        [center addObserver:_delegate selector:@selector(controlTextDidEndEditing:) name:CPControlTextDidEndEditingNotification object:self];

}

- (id)delegate
{
    return _delegate;
}

// Setting the Bezel Style
/*!
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

/*!
    Returns <code>YES</code> if the textfield draws a bezeled border.
*/
- (BOOL)isBezeled
{
    return _isBezeled;
}

/*!
    Sets the textfield's bezel style.
    @param aBezelStyle the constant for the desired bezel style
*/
- (void)setBezelStyle:(CPTextFieldBezelStyle)aBezelStyle
{
    if (_bezelStyle == aBezelStyle)
        return;
    
    _bezelStyle = aBezelStyle;
    
#if PLATFORM(DOM)
    if (aBezelStyle == CPTextFieldRoundedBezel)
        _DOMTextElement.style.paddingLeft = ROUNDEDBEZEL_HORIZONTAL_PADDING - 1.0 + "px";        
    else 
        _DOMTextElement.style.paddingLeft = "0px";        
#endif

    [self _updateBackground];
}

/*!
    Returns the textfield's bezel style.
*/
- (CPTextFieldBezelStyle)bezelStyle
{
    return _bezelStyle;
}

/*!
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

/*!
    Returns <code>YES</code> if the textfield has a border.
*/
- (BOOL)isBordered
{
    return _isBordered;
}

/*!
    Sets whether the textfield will have a background drawn.
    @param shouldDrawBackground <code>YES</code> makes the textfield draw a background
*/
- (void)setDrawsBackground:(BOOL)shouldDrawBackground
{
    if (_drawsBackground == shouldDrawBackground)
        return;
        
    _drawsBackground = shouldDrawBackground;
    
    [self _updateBackground];
}

/*!
    Returns <code>YES</code> if the textfield draws a background.
*/
- (BOOL)drawsBackground
{
    return _drawsBackground;
}

/*!
    Sets the background color, which is shown for non-bezeled text fields with drawsBackground set to YES
    @param aColor The background color
*/
- (void)setTextFieldBackgroundColor:(CPColor)aColor
{
    if (_textFieldBackgroundColor == aColor)
        return;
        
    _textFieldBackgroundColor = aColor;
    
    [self _updateBackground];
}

/*!
    Returns the background color.
*/
- (CPColor)textFieldBackgroundColor
{
    return _textFieldBackgroundColor;
}

/* @ignore */
- (void)_updateBackground
{
    if (_isBezeled)
    {
        if (_bezelStyle == CPTextFieldSquareBezel)
        {
            if (!_CPTextFieldSquareBezelColor)
            {
                var bundle = [CPBundle bundleForClass:[CPTextField class]];
            
                _CPTextFieldSquareBezelColor = [CPColor colorWithPatternImage:[[CPNinePartImage alloc] initWithImageSlices:
                    [
                        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"CPTextField/CPTextFieldBezelSquare0.png"] size:CGSizeMake(2.0, 3.0)],
                        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"CPTextField/CPTextFieldBezelSquare1.png"] size:CGSizeMake(1.0, 3.0)],
                        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"CPTextField/CPTextFieldBezelSquare2.png"] size:CGSizeMake(2.0, 3.0)],
                        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"CPTextField/CPTextFieldBezelSquare3.png"] size:CGSizeMake(2.0, 1.0)],
                        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"CPTextField/CPTextFieldBezelSquare4.png"] size:CGSizeMake(1.0, 1.0)],
                        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"CPTextField/CPTextFieldBezelSquare5.png"] size:CGSizeMake(2.0, 1.0)],
                        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"CPTextField/CPTextFieldBezelSquare6.png"] size:CGSizeMake(2.0, 2.0)],
                        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"CPTextField/CPTextFieldBezelSquare7.png"] size:CGSizeMake(1.0, 2.0)],
                        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"CPTextField/CPTextFieldBezelSquare8.png"] size:CGSizeMake(2.0, 2.0)]
                    ]]];
            }
            [self setBackgroundColor:_CPTextFieldSquareBezelColor];
        }
        else if (_bezelStyle == CPTextFieldRoundedBezel)
        {
            if (!_CPTextFieldRoundedBezelColor)
            {
                var bundle = [CPBundle bundleForClass:[CPTextField class]];

                _CPTextFieldRoundedBezelColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
                    [
                        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"CPTextField/CPTextFieldBezelRounded0.png"] size:CGSizeMake(12.0, 22.0)],
                        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"CPTextField/CPTextFieldBezelRounded1.png"] size:CGSizeMake(16.0, 22.0)],
                        [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"CPTextField/CPTextFieldBezelRounded2.png"] size:CGSizeMake(12.0, 22.0)]
                    ] isVertical:NO]];
            }
            [self setBackgroundColor:_CPTextFieldRoundedBezelColor];
        }
    }
    else
    {
        if (_drawsBackground)
            [self setBackgroundColor:_textFieldBackgroundColor];
        else
            [self setBackgroundColor:nil];
            
        // FIXME: do something for bordered textfields
        //if (_isBordered)
    }
}

/* @ignore */
- (BOOL)acceptsFirstResponder
{
    return _isEditable && _isEnabled;
}

/* @ignore */
- (BOOL)becomeFirstResponder
{    
#if PLATFORM(DOM)
    var string = [self stringValue];

    [self setStringValue:""];

    var element = [[self class] _inputElement];

    element.value = string;
    element.style.color = _DOMElement.style.color;
    element.style.font = _DOMElement.style.font;
    element.style.zIndex = 1000;
    element.style.marginTop = "0px";
    if (_isBezeled && _bezelStyle == CPTextFieldRoundedBezel)
    {
        // http://cappuccino.lighthouseapp.com/projects/16499/tickets/191-cptextfield-shifts-updown-when-receiveslosts-focus
        // uncommenting the following 2 lines will solve the problem in Firefox only ...
        // element.style.paddingTop = TOP_PADDING - 0.0 + "px" ;
        // element.style.paddingLeft = HORIZONTAL_PADDING - 3.0 + "px" ;
        
        element.style.top = "0px" ;
        element.style.left = ROUNDEDBEZEL_HORIZONTAL_PADDING + 1.0 + "px" ;
        element.style.width = CGRectGetWidth([self bounds]) - (2 * ROUNDEDBEZEL_HORIZONTAL_PADDING) - 2.0 + "px";
    }
    else 
    {
        element.style.width = CGRectGetWidth([self bounds]) - 3.0 + "px";
    }

    _DOMElement.appendChild(element);
    window.setTimeout(function() { element.focus(); }, 0.0);

    element.onblur = function () 
    { 
        [self setObjectValue:element.value];
        [self sendAction:[self action] to:[self target]];
        [[self window] makeFirstResponder:nil];
        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    };
    
    //element.onblur = function() { objj_debug_print_backtrace(); }
    //element.select();
    
    element.onkeydown = function(aDOMEvent) 
    {
        //all key presses might trigger the delegate method controlTextDidChange: 
        //record the current string value before we allow this keydown to propagate
        _textDidChangeValue = [self stringValue];    
        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
        return true;
    }
        
    element.onkeypress = function(aDOMEvent) 
    {
        aDOMEvent = aDOMEvent || window.event;
        
        if (aDOMEvent.keyCode == 13) 
        {
            if (aDOMEvent.preventDefault)
                aDOMEvent.preventDefault(); 
            if (aDOMEvent.stopPropagation)
                aDOMEvent.stopPropagation();
            aDOMEvent.cancelBubble = true;
            
            element.blur();
        }    
        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    };
    
    //inspect keyup to detect changes in order to trigger controlTextDidChange: delegate method
    element.onkeyup = function(aDOMEvent) 
    { 
        //check if we should fire a notification for CPControlTextDidChange
        if ([self stringValue] != _textDidChangeValue)
        {
            _textDidChangeValue = [self stringValue];

            //call to CPControls methods for posting the notification
            [self textDidChange:[CPNotification notificationWithName:CPControlTextDidChangeNotification object:self userInfo:nil]];
        }    
        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    };

    // If current value is the placeholder value, remove it to allow user to update.
    if ([string lowercaseString] == [[self placeholderString] lowercaseString])
        element.value = "";
    
    //post CPControlTextDidBeginEditingNotification
    [self textDidBeginEditing:[CPNotification notificationWithName:CPControlTextDidBeginEditingNotification object:self userInfo:nil]];
    
    [[CPDOMWindowBridge sharedDOMWindowBridge] _propagateCurrentDOMEvent:YES];
#endif

    return YES;
}

/* @ignore */
- (BOOL)resignFirstResponder
{
#if PLATFORM(DOM)
    var element = [[self class] _inputElement];

    //nil out dom handlers
    element.onkeyup = nil;
    element.onkeydown = nil;
    element.onkeypress = nil;
    
    _DOMElement.removeChild(element);
    [self setStringValue:element.value]; // redundant?

    // If textfield has no value, then display the placeholderValue
    if (!_value)
        [self setStringValue:[self placeholderString]];

#endif
    //post CPControlTextDidEndEditingNotification
    [self textDidEndEditing:[CPNotification notificationWithName:CPControlTextDidBeginEditingNotification object:self userInfo:nil]];

    return YES;
}

- (void)mouseDown:(CPEvent)anEvent
{
    if (![self isEditable])
        return [[self nextResponder] mouseDown:anEvent];

    [super mouseDown:anEvent];
}
/*
- (void)mouseUp:(CPEvent)anEvent
{    
    if (_isEditable && [[self window] firstResponder] == self)
        return;
        
    [super mouseUp:anEvent];
}
*/
/*! 
    Sets whether or not the receiver text field can be edited
*/
- (void)setEditable:(BOOL)shouldBeEditable
{
    _isEditable = shouldBeEditable;
}

/*!
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
    if (_isBezeled && _bezelStyle == CPTextFieldRoundedBezel)
    {
        CPDOMDisplayServerSetStyleSize(_DOMTextElement, _frame.size.width - 2.0 * ROUNDEDBEZEL_HORIZONTAL_PADDING, _frame.size.height - TOP_PADDING - BOTTOM_PADDING);
    }
    else
    {
        CPDOMDisplayServerSetStyleSize(_DOMTextElement, _frame.size.width - 2.0 * HORIZONTAL_PADDING, _frame.size.height - TOP_PADDING - BOTTOM_PADDING);
    }
#endif
}

/*!
    Returns <code>YES</code> if the field's text is selectable by the user.
*/
- (BOOL)isSelectable
{
    return _isSelectable;
}

/*!
    Sets whether the field's text is selectable by the user.
    @param aFlag <code>YES</code> makes the text selectable
*/
- (void)setSelectable:(BOOL)aFlag
{
    _isSelectable = aFlag;
}

/*!
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

/*!
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
                                            _DOMTextElement.style.whiteSpace   = "nowrap";
                                            _DOMTextElement.style.overflow     = "hidden";
                                            
                                            if (document.attachEvent)
                                                _DOMTextElement.style.wordWrap = "normal";    
                                                                                            
                                            break;
                                            
        case CPLineBreakByWordWrapping:     if (document.attachEvent)
                                            {                                            
                                                _DOMTextElement.style.whiteSpace = "pre";
                                                _DOMTextElement.style.wordWrap   = "break-word";
                                            }
                                            else
                                            {
                                                _DOMTextElement.style.whiteSpace = "-o-pre-wrap";
                                                _DOMTextElement.style.whiteSpace = "-pre-wrap";
                                                _DOMTextElement.style.whiteSpace = "-moz-pre-wrap";
                                                _DOMTextElement.style.whiteSpace = "pre-wrap";
                                            }

                                            _DOMTextElement.style.overflow     = "hidden";
                                            _DOMTextElement.style.textOverflow = "clip";
                                            
                                            break;
    }
#endif
}

/*!
    Returns the string the text field.
*/
- (id)objectValue
{
    // All of this needs to be better.
#if PLATFORM(DOM)
    if ([[self window] firstResponder] == self)
        return [[self class] _inputElement].value;
#endif
    //if the content is the same as the placeholder value, return "" instead
    if ([super objectValue] == [self placeholderString])
        return "";

    return [super objectValue];
}

/*
    @ignore
*/
- (void)setObjectValue:(id)aValue
{
    [super setObjectValue:aValue];
    
#if PLATFORM(DOM)
    var displayString = "";

    if (aValue !== nil && aValue !== undefined)
    {
        if ([aValue respondsToSelector:@selector(string)])
            displayString = [aValue string];
        else
            displayString += aValue;
    }

    if ([[self window] firstResponder] == self)
        [[self class] _inputElement].value = displayString;

    if (CPFeatureIsCompatible(CPJavascriptInnerTextFeature))
        _DOMTextElement.innerText = displayString;
    else if (CPFeatureIsCompatible(CPJavascriptTextContentFeature))
        _DOMTextElement.textContent = displayString;
#endif
}

/*!
    Returns the receiver's placeholder string
*/
- (CPString)placeholderString
{
    return _placeholderString;
}

/*!
    Sets a placeholder string for the receiver.  The placeholder is displayed until editing begins,
    and after editing ends, if the text field has an empty string value
*/
-(void)setPlaceholderString:(CPString)aStringValue
{
    if(_placeholderString && [self stringValue] === _placeholderString)
        _value = @"";

    _placeholderString = aStringValue;

    //if there is no set value, automatically display the placeholder
    if (!_value) 
        [self setStringValue:_placeholderString];
}

/*!
    Adjusts the text field's size in the application.
*/
- (void)sizeToFit
{
#if PLATFORM(DOM)
    var size = [(_value || " ") sizeWithFont:[self font]];
    
    if (_isBezeled && _bezelStyle == CPTextFieldRoundedBezel)
    {
        [self setFrameSize:CGSizeMake(size.width + 2 * ROUNDEDBEZEL_HORIZONTAL_PADDING, size.height + TOP_PADDING + BOTTOM_PADDING)];
    }
    else
    {
        [self setFrameSize:CGSizeMake(size.width + 2 * HORIZONTAL_PADDING, size.height + TOP_PADDING + BOTTOM_PADDING)];
    }
#endif
}

/*!
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

var CPTextFieldIsEditableKey            = "CPTextFieldIsEditableKey",
    CPTextFieldIsSelectableKey          = "CPTextFieldIsSelectableKey",
    CPTextFieldIsBorderedKey            = "CPTextFieldIsBorderedKey",
    CPTextFieldIsBezeledKey             = "CPTextFieldIsBezeledKey",
    CPTextFieldBezelStyleKey            = "CPTextFieldBezelStyleKey",
    CPTextFieldDrawsBackgroundKey       = "CPTextFieldDrawsBackgroundKey",
    CPTextFieldLineBreakModeKey         = "CPTextFieldLineBreakModeKey",
    CPTextFieldBackgroundColorKey       = "CPTextFieldBackgroundColorKey",
    CPTextFieldPlaceholderStringKey     = "CPTextFieldPlaceholderStringKey";

@implementation CPTextField (CPCoding)

/*!
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
#if PLATFORM(DOM)
        var bounds = [self bounds];
        _DOMTextElement.style.position = "absolute";
        _DOMTextElement.style.top = TOP_PADDING + "px";
        if (_isBezeled && _bezelStyle == CPTextFieldRoundedBezel)
        {
            _DOMTextElement.style.left = ROUNDEDBEZEL_HORIZONTAL_PADDING + "px";
            _DOMTextElement.style.width = MAX(0.0, CGRectGetWidth(bounds) - 2.0 * ROUNDEDBEZEL_HORIZONTAL_PADDING) + "px";
        }
        else
        {
            _DOMTextElement.style.left = HORIZONTAL_PADDING + "px";
            _DOMTextElement.style.width = MAX(0.0, CGRectGetWidth(bounds) - 2.0 * HORIZONTAL_PADDING) + "px";
        }
        _DOMTextElement.style.height = MAX(0.0, CGRectGetHeight(bounds) - TOP_PADDING - BOTTOM_PADDING) + "px";
        _DOMTextElement.style.whiteSpace = "pre";
        _DOMTextElement.style.cursor = "default";
        
        _DOMElement.appendChild(_DOMTextElement);
#endif

        [self setEditable:[aCoder decodeBoolForKey:CPTextFieldIsEditableKey]];
        [self setSelectable:[aCoder decodeBoolForKey:CPTextFieldIsSelectableKey]];

        [self setBordered:[aCoder decodeBoolForKey:CPTextFieldIsBorderedKey]];
        [self setBezeled:[aCoder decodeBoolForKey:CPTextFieldIsBezeledKey]];
        [self setBezelStyle:[aCoder decodeIntForKey:CPTextFieldBezelStyleKey]];
        [self setDrawsBackground:[aCoder decodeBoolForKey:CPTextFieldDrawsBackgroundKey]];

        [self setLineBreakMode:[aCoder decodeIntForKey:CPTextFieldLineBreakModeKey]];
        [self setTextFieldBackgroundColor:[aCoder decodeObjectForKey:CPTextFieldBackgroundColorKey]];

        [self setPlaceholderString:[aCoder decodeObjectForKey:CPTextFieldPlaceholderStringKey]];
    }
    
    return self;
}

/*!
    Encodes the data of this textfield into the provided coder.
    @param aCoder the coder into which the data will be written
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeBool:_isEditable forKey:CPTextFieldIsEditableKey];
    [aCoder encodeBool:_isSelectable forKey:CPTextFieldIsSelectableKey];
    
    [aCoder encodeBool:_isBordered forKey:CPTextFieldIsBorderedKey];
    [aCoder encodeBool:_isBezeled forKey:CPTextFieldIsBezeledKey];
    [aCoder encodeInt:_bezelStyle forKey:CPTextFieldBezelStyleKey];
    [aCoder encodeBool:_drawsBackground forKey:CPTextFieldDrawsBackgroundKey];
    
    [aCoder encodeInt:_lineBreakMode forKey:CPTextFieldLineBreakModeKey];
    [aCoder encodeObject:_textFieldBackgroundColor forKey:CPTextFieldBackgroundColorKey];
    
    [aCoder encodeObject:_placeholderString forKey:CPTextFieldPlaceholderStringKey];
}

@end
