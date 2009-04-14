
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

#include "CoreGraphics/CGGeometry.j"
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


#if PLATFORM(DOM)

var CPTextFieldDOMInputElement = nil,
    CPTextFieldInputOwner = nil,
    CPTextFieldTextDidChangeValue = nil;
    
#endif

var CPSecureTextFieldCharacter = "\u2022";

@implementation CPString (CPTextFieldAdditions)

/*!
    Returns the string (<code>self</code>).
*/
- (CPString)string
{
    return self;
}

@end

CPTextFieldStateRounded     = 1 << 12;
CPTextFieldStatePlaceholder = 1 << 13;

/*!
    This control displays editable text in a Cappuccino application.
*/
@implementation CPTextField : CPControl
{
    BOOL                    _isEditable;
    BOOL                    _isSelectable;
    BOOL                    _isSecure;

    BOOL                    _drawsBackground;
    
    CPColor                 _textFieldBackgroundColor;
    
    id                      _placeholderString;
    
    id                      _delegate;
    
    CPString                _textDidChangeValue;

    // NS-style Display Properties
    CPTextFieldBezelStyle   _bezelStyle;
    BOOL                    _isBordered;
    CPControlSize           _controlSize;
}

+ (id)themedAttributes
{
    return [CPDictionary dictionaryWithObjects:[_CGInsetMakeZero(), _CGInsetMake(2.0, 2.0, 2.0, 2.0), _CGInsetMake(2.0, 2.0, 2.0, 2.0), nil]
                                       forKeys:[@"bezel-inset", @"content-inset", @"bezeled-content-inset", @"bezel-color"]];
}

/* @ignore */
#if PLATFORM(DOM)
+ (DOMElement)_inputElement
{
    if (!CPTextFieldDOMInputElement)
    {
        CPTextFieldDOMInputElement = document.createElement("input");
        CPTextFieldDOMInputElement.style.position = "absolute";
        CPTextFieldDOMInputElement.style.border = "0px";
        CPTextFieldDOMInputElement.style.padding = "0px";
        CPTextFieldDOMInputElement.style.margin = "0px";
        CPTextFieldDOMInputElement.style.whiteSpace = "pre";
        CPTextFieldDOMInputElement.style.background = "transparent";
        CPTextFieldDOMInputElement.style.outline = "none";

        var blurFunction = function(anEvent)
        {
            if (CPTextFieldInputOwner)
                CPTextFieldHandleBlur(anEvent, CPTextFieldDOMInputElement);

            return true;
        }

        var keydownFunction = function(anEvent)
        {
            CPTextFieldTextDidChangeValue = [CPTextFieldInputOwner stringValue];

            keypressFunction(anEvent);

            return true;
        }

        var keypressFunction = function(aDOMEvent)
        {
            aDOMEvent = aDOMEvent || window.event;

            if (aDOMEvent.keyCode == CPReturnKeyCode || aDOMEvent.keyCode == CPTabKeyCode) 
            {
                if (aDOMEvent.preventDefault)
                    aDOMEvent.preventDefault(); 
                if (aDOMEvent.stopPropagation)
                    aDOMEvent.stopPropagation();
                aDOMEvent.cancelBubble = true;

                CPTextFieldHandleBlur(aDOMEvent, CPTextFieldDOMInputElement);
            }    

            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
        }

        var keyupFunction = function()
        {
            if ([CPTextFieldInputOwner stringValue] !== CPTextFieldTextDidChangeValue)
            {
                CPTextFieldTextDidChangeValue = [CPTextFieldInputOwner stringValue];
                [CPTextFieldInputOwner textDidChange:[CPNotification notificationWithName:CPControlTextDidChangeNotification object:CPTextFieldInputOwner userInfo:nil]];
            }

            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
        }

        CPTextFieldHandleBlur = function(anEvent, anElement)
        {
            [CPTextFieldInputOwner setObjectValue:anElement.value];

            if (anEvent && anEvent.keyCode == CPReturnKeyCode)
            {
                [CPTextFieldInputOwner sendAction:[CPTextFieldInputOwner action] to:[CPTextFieldInputOwner targer]];    
                [[CPTextFieldInputOwner window] makeFirstResponder:nil];
            }
            else if (anEvent && anEvent.keyCode == CPTabKeyCode)
            {
                if (!anEvent.shiftKey)
                    [[CPTextFieldInputOwner window] selectNextKeyView:CPTextFieldInputOwner];
                else
                    [[CPTextFieldInputOwner window] selectPreviousKeyView:CPTextFieldInputOwner];
            }

            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
            CPTextFieldInputOwner = nil;
        }

        if (document.attachEvent)
        {
            CPTextFieldDOMInputElement.attachEvent("on" + CPDOMEventKeyUp, keyupFunction);
            CPTextFieldDOMInputElement.attachEvent("on" + CPDOMEventKeyDown, keydownFunction);
            CPTextFieldDOMInputElement.attachEvent("on" + CPDOMEventKeyPress, keypressFunction);
        }
        else
        {
            CPTextFieldDOMInputElement.addEventListener(CPDOMEventKeyUp, keyupFunction, NO);
            CPTextFieldDOMInputElement.addEventListener(CPDOMEventKeyDown, keydownFunction, NO);
            CPTextFieldDOMInputElement.addEventListener(CPDOMEventKeyPress, keypressFunction, NO);
        }
    }

    return CPTextFieldDOMInputElement;
}
#endif

+ (void)initialize
{
    if (CPBrowserIsEngine(CPGeckoBrowserEngine))
        CPSecureTextFieldCharacter = "*";
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        [self setStringValue:@""];
        [self setPlaceholderString:@""];

        _sendActionOn = CPKeyUpMask | CPKeyDownMask;

        [self setValue:CPLeftTextAlignment forThemedAttributeName:@"alignment"];
    }
    
    return self;
}

#pragma mark Controlling Editability and Selectability

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

/*!
    Sets whether the field's text is selectable by the user.
    @param aFlag <code>YES</code> makes the text selectable
*/
- (void)setSelectable:(BOOL)aFlag
{
    _isSelectable = aFlag;
}

/*!
    Returns <code>YES</code> if the field's text is selectable by the user.
*/
- (BOOL)isSelectable
{
    return _isSelectable;
}

/*!
    Sets whether the field's text is secure.
    @param aFlag <code>YES</code> makes the text secure
*/
- (void)setSecure:(BOOL)aFlag
{
    _isSecure = aFlag;
}

/*!
    Returns <code>YES</code> if the field's text is secure (password entry).
*/
- (BOOL)isSecure
{
    return _isSecure;
}

// Setting the Bezel Style
/*!
    Sets whether the textfield will have a bezeled border.
    @param shouldBeBezeled <code>YES</code> means the textfield will draw a bezeled border
*/
- (void)setBezeled:(BOOL)shouldBeBezeled
{
    if ((!!(_controlState & CPControlStateBezeled)) === shouldBeBezeled)
        return;
    
    if (shouldBeBezeled)
        _controlState |= CPControlStateBezeled;
    else
        _controlState &= ~CPControlStateBezeled;

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns <code>YES</code> if the textfield draws a bezeled border.
*/
- (BOOL)isBezeled
{
    return !!(_controlState & CPControlStateBezeled);
}

/*!
    Sets the textfield's bezel style.
    @param aBezelStyle the constant for the desired bezel style
*/
- (void)setBezelStyle:(CPTextFieldBezelStyle)aBezelStyle
{
    var shouldBeRounded = aBezelStyle === CPTextFieldRoundedBezel;
    
    if ((!!(_controlState & CPTextFieldStateRounded)) === shouldBeRounded)
        return;
    
    if (shouldBeRounded)
        _controlState |= CPTextFieldStateRounded;
    else
        _controlState &= ~CPTextFieldStateRounded;

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns the textfield's bezel style.
*/
- (CPTextFieldBezelStyle)bezelStyle
{
    if (_controlState & CPTextFieldStateRounded)
        return CPTextFieldRoundedBezel;

    return CPTextFieldSquareBezel;
}

/*!
    Sets whether the textfield will have a border drawn.
    @param shouldBeBordered <code>YES</code> makes the textfield draw a border
*/
- (void)setBordered:(BOOL)shouldBeBordered
{
    if ((!!(_controlState & CPControlStateBordered)) === shouldBeBordered)
        return;
    
    if (shouldBeBordered)
        _controlState |= CPControlStateBordered;
    else
        _controlState &= ~CPControlStateBordered;

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns <code>YES</code> if the textfield has a border.
*/
- (BOOL)isBordered
{
    return !!(_controlState & CPControlStateBordered);
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
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
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
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    Returns the background color.
*/
- (CPColor)textFieldBackgroundColor
{
    return _textFieldBackgroundColor;
}

/* @ignore */
- (BOOL)acceptsFirstResponder
{
    return [self isEditable] && [self isEnabled];
}

/* @ignore */
- (BOOL)becomeFirstResponder
{
    _controlState |= CPControlStateEditing;
    [self setNeedsLayout];

#if PLATFORM(DOM)
    CPTextFieldInputOwner = self;

    var string = [self stringValue],
        element = [[self class] _inputElement];

    element.value = string;
    element.style.color = [[self currentValueForThemedAttributeName:@"text-color"] cssString];
    element.style.font = [[self currentValueForThemedAttributeName:@"font"] cssString];
    element.style.zIndex = 1000;

    if ([self isSecure])
        element.type = "password";
    else
        element.type = "text";

    var contentRect = [self contentRectForBounds:[self bounds]];

    element.style.top = _CGRectGetMinY(contentRect) + "px";
    element.style.left = (_CGRectGetMinX(contentRect) - 1) + "px"; // why -1?
    element.style.width = _CGRectGetWidth(contentRect) + "px";
    element.style.height = _CGRectGetHeight(contentRect) + "px";

    _DOMElement.appendChild(element);

    window.setTimeout(function() { element.focus(); }, 0.0);
 
    //post CPControlTextDidBeginEditingNotification
    [self textDidBeginEditing:[CPNotification notificationWithName:CPControlTextDidBeginEditingNotification object:self userInfo:nil]];
    
    [[CPDOMWindowBridge sharedDOMWindowBridge] _propagateCurrentDOMEvent:YES];
#endif

    return YES;
}

/* @ignore */
- (BOOL)resignFirstResponder
{
    _controlState &= ~CPControlStateEditing;
    [self setNeedsLayout];

#if PLATFORM(DOM)

    var element = [[self class] _inputElement];

    if (CPTextFieldInputOwner == self)
        CPTextFieldHandleBlur(nil, [[self class] _inputElement]);

    _DOMElement.removeChild(element);

    CPTextFieldInputOwner = nil;

#endif

    //post CPControlTextDidEndEditingNotification
    [self textDidEndEditing:[CPNotification notificationWithName:CPControlTextDidBeginEditingNotification object:self userInfo:nil]];

    return YES;
}

- (void)mouseDown:(CPEvent)anEvent
{
    // Don't track! (ever?)
    if ([self isEditable] && [self isEnabled])
        return [[self window] makeFirstResponder:self];
    else
        return [[self nextResponder] mouseDown:anEvent];
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

    return [super objectValue];
}

/*
    @ignore
*/
- (void)setObjectValue:(id)aValue
{
    [super setObjectValue:aValue];

/*
#if PLATFORM(DOM)
    if ([[self window] firstResponder] == self)
        [[self class] _inputElement].value = displayString;
#endif
*/

    var string = [self stringValue];

    if (!string || [string length] === 0)
        _controlState |= CPTextFieldStatePlaceholder;
    else
        _controlState &= ~CPTextFieldStatePlaceholder;
}

/*!
    Sets a placeholder string for the receiver.  The placeholder is displayed until editing begins,
    and after editing ends, if the text field has an empty string value
*/
-(void)setPlaceholderString:(CPString)aStringValue
{
    if (_placeholderString === aStringValue)
        return;
    
    _placeholderString = aStringValue;

    // Only update things if we need to show the placeholder
    if (_controlState & CPTextFieldStatePlaceholder)
    {
        [self setNeedsLayout];
        [self setNeedsDisplay:YES];
    }
}

/*!
    Returns the receiver's placeholder string
*/
- (CPString)placeholderString
{
    return _placeholderString;
}

/*!
    Adjusts the text field's size in the application.
*/

- (void)sizeToFit
{
    var size = [(_value || " ") sizeWithFont:[self font]],
        contentInset = [self currentValueForThemedAttributeName:@"content-inset"];

    [self setFrameSize:CGSizeMake(size.width + contentInset.left + contentInset.right, size.height + contentInset.top + contentInset.bottom)];
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

#pragma mark Setting the Delegate

- (void)setDelegate:(id)aDelegate
{
    var defaultCenter = [CPNotificationCenter defaultCenter];
    
    //unsubscribe the existing delegate if it exists
    if (_delegate)
    {
        [defaultCenter removeObserver:_delegate name:CPControlTextDidBeginEditingNotification object:self];
        [defaultCenter removeObserver:_delegate name:CPControlTextDidChangeNotification object:self];
        [defaultCenter removeObserver:_delegate name:CPControlTextDidEndEditingNotification object:self];
    }
    
    _delegate = aDelegate;
    
    if ([_delegate respondsToSelector:@selector(controlTextDidBeginEditing:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(controlTextDidBeginEditing:)
                   name:CPControlTextDidBeginEditingNotification
                 object:self];
    
    if ([_delegate respondsToSelector:@selector(controlTextDidChange:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(controlTextDidChange:)
                   name:CPControlTextDidChangeNotification
                 object:self];
    
    
    if ([_delegate respondsToSelector:@selector(controlTextDidEndEditing:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(controlTextDidEndEditing:)
                   name:CPControlTextDidEndEditingNotification
                 object:self];

}

- (id)delegate
{
    return _delegate;
}

- (CGRect)contentRectForBounds:(CGRect)bounds
{
    var contentInset = [self currentValueForThemedAttributeName:@"content-inset"];
    
    if (!contentInset)
        return bounds;
    
    bounds.origin.x += contentInset.left;
    bounds.origin.y += contentInset.top;
    bounds.size.width -= contentInset.left + contentInset.right;
    bounds.size.height -= contentInset.top + contentInset.bottom;
    
    return bounds;
}

- (CGRect)bezelRectForBounds:(CFRect)bounds
{
    var bezelInset = [self currentValueForThemedAttributeName:@"bezel-inset"];
    
    if (!_CGInsetIsEmpty(bezelInset))
        return bounds;
    
    bounds.origin.x += bezelInset.left;
    bounds.origin.y += bezelInset.top;
    bounds.size.width -= bezelInset.left + bezelInset.right;
    bounds.size.height -= bezelInset.top + bezelInset.bottom;
    
    return bounds;
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "bezel-view")
        return [self bezelRectForBounds:[self bounds]];
    
    else if (aName === "content-view")
        return [self contentRectForBounds:[self bounds]];
    
    return [super rectForEphemeralSubviewNamed:aName];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "bezel-view")
    {
        var view = [[CPView alloc] initWithFrame:_CGRectMakeZero()];

        [view setHitTests:NO];
        
        return view;
    }
    else
    {
        var view = [[_CPImageAndTextView alloc] initWithFrame:_CGRectMakeZero()];
        //[view setImagePosition:CPNoImage];
        
        return view;
    }
    
    return [super createEphemeralSubviewNamed:aName];
}

- (void)layoutSubviews
{
    var bezelView = [self layoutEphemeralSubviewNamed:@"bezel-view"
                                           positioned:CPWindowBelow
                      relativeToEphemeralSubviewNamed:@"content-view"];
      
    if (bezelView)
        [bezelView setBackgroundColor:[self currentValueForThemedAttributeName:@"bezel-color"]];
    
    var contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                             positioned:CPWindowAbove
                        relativeToEphemeralSubviewNamed:@"bezel-view"];

    if (contentView)
    {
        [contentView setHidden:_controlState & CPControlStateEditing];

        var string = "";
        
        if (_controlState & CPTextFieldStatePlaceholder)
            string = [self placeholderString];
        else
            string = [self stringValue];

        if ([self isSecure])
            string = secureStringForString(string);

        [contentView setText:string];

        [contentView setTextColor:[self currentValueForThemedAttributeName:@"text-color"]];
        [contentView setFont:[self currentValueForThemedAttributeName:@"font"]];
        [contentView setAlignment:[self currentValueForThemedAttributeName:@"alignment"]];
        [contentView setVerticalAlignment:[self currentValueForThemedAttributeName:@"vertical-alignment"]];
        [contentView setLineBreakMode:[self currentValueForThemedAttributeName:@"line-break-mode"]];
        [contentView setTextShadowColor:[self currentValueForThemedAttributeName:@"text-shadow-color"]];
        [contentView setTextShadowOffset:[self currentValueForThemedAttributeName:@"text-shadow-offset"]];
    }
}

@end

var secureStringForString = function(aString)
{
    var secureString = "",
        length = aString.length;

    while (length--)
        secureString += CPSecureTextFieldCharacter;

    return secureString;
}


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
    self = [super initWithCoder:aCoder];
    
    if (self)
    {
        [self setEditable:[aCoder decodeBoolForKey:CPTextFieldIsEditableKey]];
        [self setSelectable:[aCoder decodeBoolForKey:CPTextFieldIsSelectableKey]];

        [self setDrawsBackground:[aCoder decodeBoolForKey:CPTextFieldDrawsBackgroundKey]];

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
    
    [aCoder encodeBool:_drawsBackground forKey:CPTextFieldDrawsBackgroundKey];
    
    [aCoder encodeObject:_textFieldBackgroundColor forKey:CPTextFieldBackgroundColorKey];
    
    [aCoder encodeObject:_placeholderString forKey:CPTextFieldPlaceholderStringKey];
}

@end

