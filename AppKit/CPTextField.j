
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
@import "CPCompatibility.j"
@import "_CPImageAndTextView.j"

#include "CoreGraphics/CGGeometry.h"
#include "Platform/Platform.h"
#include "Platform/DOM/CPDOMDisplayServer.h"

CPTextFieldSquareBezel          = 0;    /*! A textfield bezel with a squared corners. */
CPTextFieldRoundedBezel         = 1;    /*! A textfield bezel with rounded corners. */

CPTextFieldDidFocusNotification = @"CPTextFieldDidFocusNotification";
CPTextFieldDidBlurNotification  = @"CPTextFieldDidBlurNotification";

#if PLATFORM(DOM)

var CPTextFieldDOMInputElement = nil,
    CPTextFieldDOMPasswordInputElement = nil,
    CPTextFieldDOMStandardInputElement = nil,
    CPTextFieldInputOwner = nil,
    CPTextFieldTextDidChangeValue = nil,
    CPTextFieldInputResigning = NO,
    CPTextFieldInputDidBlur = NO,
    CPTextFieldInputIsActive = NO,
    CPTextFieldCachedSelectStartFunction = nil,
    CPTextFieldCachedDragFunction = nil,
    CPTextFieldBlurFunction = nil;

#endif

var CPSecureTextFieldCharacter = "\u2022";

@implementation CPString (CPTextFieldAdditions)

/*!
    Returns the string (\c self).
*/
- (CPString)string
{
    return self;
}

@end

CPTextFieldStateRounded     = CPThemeState("rounded");
CPTextFieldStatePlaceholder = CPThemeState("placeholder");

/*!
    @ingroup appkit
    This control displays editable text in a Cappuccino application.
*/
@implementation CPTextField : CPControl
{
    BOOL                    _isEditing;

    BOOL                    _isEditable;
    BOOL                    _isSelectable;
    BOOL                    _isSecure;

    BOOL                    _drawsBackground;

    CPColor                 _textFieldBackgroundColor;

    id                      _placeholderString;
    id                      _originalPlaceholderString;
    BOOL                    _currentValueIsPlaceholder;

    id                      _delegate;

    CPString                _textDidChangeValue;

    // NS-style Display Properties
    CPTextFieldBezelStyle   _bezelStyle;
    BOOL                    _isBordered;
    CPControlSize           _controlSize;
}

+ (CPTextField)textFieldWithStringValue:(CPString)aStringValue placeholder:(CPString)aPlaceholder width:(float)aWidth
{
    return [self textFieldWithStringValue:aStringValue placeholder:aPlaceholder width:aWidth theme:[CPTheme defaultTheme]];
}

+ (CPTextField)textFieldWithStringValue:(CPString)aStringValue placeholder:(CPString)aPlaceholder width:(float)aWidth theme:(CPTheme)aTheme
{
    var textField = [[self alloc] initWithFrame:CGRectMake(0.0, 0.0, aWidth, 29.0)];

    [textField setTheme:aTheme];
    [textField setStringValue:aStringValue];
    [textField setPlaceholderString:aPlaceholder];
    [textField setBordered:YES];
    [textField setBezeled:YES];
    [textField setEditable:YES];

    [textField sizeToFit];

    return textField;
}

+ (CPTextField)roundedTextFieldWithStringValue:(CPString)aStringValue placeholder:(CPString)aPlaceholder width:(float)aWidth
{
    return [self roundedTextFieldWithStringValue:aStringValue placeholder:aPlaceholder width:aWidth theme:[CPTheme defaultTheme]];
}

+ (CPTextField)roundedTextFieldWithStringValue:(CPString)aStringValue placeholder:(CPString)aPlaceholder width:(float)aWidth theme:(CPTheme)aTheme
{
    var textField = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, aWidth, 29.0)];

    [textField setTheme:aTheme];
    [textField setStringValue:aStringValue];
    [textField setPlaceholderString:aPlaceholder];
    [textField setBezelStyle:CPTextFieldRoundedBezel];
    [textField setBordered:YES];
    [textField setBezeled:YES];
    [textField setEditable:YES];

    [textField sizeToFit];

    return textField;
}

+ (CPTextField)labelWithTitle:(CPString)aTitle
{
    return [self labelWithTitle:aTitle theme:[CPTheme defaultTheme]];
}

+ (CPTextField)labelWithTitle:(CPString)aTitle theme:(CPTheme)aTheme
{
    var textField = [[self alloc] init];

    [textField setStringValue:aTitle];
    [textField sizeToFit];

    return textField;
}

+ (CPString)themeClass
{
    return "textfield";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[_CGInsetMakeZero(), _CGInsetMake(2.0, 2.0, 2.0, 2.0), [CPNull null]]
                                       forKeys:[@"bezel-inset", @"content-inset", @"bezel-color"]];
}

/* @ignore */
#if PLATFORM(DOM)
- (DOMElement)_inputElement
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

        CPTextFieldBlurFunction = function(anEvent)
        {
            if (CPTextFieldInputOwner && CPTextFieldInputOwner._DOMElement != CPTextFieldDOMInputElement.parentNode)
                return;

            if (!CPTextFieldInputResigning)
            {
                [[CPTextFieldInputOwner window] makeFirstResponder:nil];
                return;
            }

            CPTextFieldHandleBlur(anEvent, CPTextFieldDOMInputElement);
            CPTextFieldInputDidBlur = YES;

            return true;
        }

        CPTextFieldHandleBlur = function(anEvent)
        {
            CPTextFieldInputOwner = nil;

            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
        }

        //FIXME make this not onblur
        CPTextFieldDOMInputElement.onblur = CPTextFieldBlurFunction;

        CPTextFieldDOMStandardInputElement = CPTextFieldDOMInputElement;
    }

    if (CPFeatureIsCompatible(CPInputTypeCanBeChangedFeature))
    {
        if ([self isSecure])
            CPTextFieldDOMInputElement.type = "password";
        else
            CPTextFieldDOMInputElement.type = "text";

        return CPTextFieldDOMInputElement;
    }

    if ([self isSecure])
    {
        if (!CPTextFieldDOMPasswordInputElement)
        {
            CPTextFieldDOMPasswordInputElement = document.createElement("input");
            CPTextFieldDOMPasswordInputElement.style.position = "absolute";
            CPTextFieldDOMPasswordInputElement.style.border = "0px";
            CPTextFieldDOMPasswordInputElement.style.padding = "0px";
            CPTextFieldDOMPasswordInputElement.style.margin = "0px";
            CPTextFieldDOMPasswordInputElement.style.whiteSpace = "pre";
            CPTextFieldDOMPasswordInputElement.style.background = "transparent";
            CPTextFieldDOMPasswordInputElement.style.outline = "none";
            CPTextFieldDOMPasswordInputElement.type = "password";

            CPTextFieldDOMPasswordInputElement.onblur = CPTextFieldBlurFunction;
        }

        CPTextFieldDOMInputElement = CPTextFieldDOMPasswordInputElement;
    }
    else
    {
        CPTextFieldDOMInputElement = CPTextFieldDOMStandardInputElement;
    }

    return CPTextFieldDOMInputElement;
}
#endif

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        [self setStringValue:@""];
        [self setPlaceholderString:@""];

        _sendActionOn = CPKeyUpMask | CPKeyDownMask;

        [self setValue:CPLeftTextAlignment forThemeAttribute:@"alignment"];
    }

    return self;
}

#pragma mark Controlling Editability and Selectability

/*!
    Sets whether or not the receiver text field can be edited. If NO, any
    ongoing edit is ended.
*/
- (void)setEditable:(BOOL)shouldBeEditable
{
    if (_isEditable === shouldBeEditable)
        return;

    _isEditable = shouldBeEditable;

    if (shouldBeEditable)
        _isSelectable = YES;

    // We only allow first responder status if the field is editable and enabled.
    if (!shouldBeEditable && [[self window] firstResponder] === self)
        [[self window] makeFirstResponder:nil];
}

/*!
    Returns \c YES if the textfield is currently editable by the user.
*/
- (BOOL)isEditable
{
    return _isEditable;
}

/*!
    Sets whether the field reacts to events. If NO, any ongoing edit is
    ended.
*/
- (void)setEnabled:(BOOL)shouldBeEnabled
{
    [super setEnabled:shouldBeEnabled];

    // We only allow first responder status if the field is editable and enabled.
    if (!shouldBeEnabled && [[self window] firstResponder] === self)
        [[self window] makeFirstResponder:nil];
}

/*!
    Sets whether the field's text is selectable by the user.
    @param aFlag \c YES makes the text selectable
*/
- (void)setSelectable:(BOOL)aFlag
{
    _isSelectable = aFlag;
}

/*!
    Returns \c YES if the field's text is selectable by the user.
*/
- (BOOL)isSelectable
{
    return _isSelectable;
}

/*!
    Sets whether the field's text is secure.
    @param aFlag \c YES makes the text secure
*/
- (void)setSecure:(BOOL)aFlag
{
    _isSecure = aFlag;
}

/*!
    Returns \c YES if the field's text is secure (password entry).
*/
- (BOOL)isSecure
{
    return _isSecure;
}

// Setting the Bezel Style
/*!
    Sets whether the textfield will have a bezeled border.
    @param shouldBeBezeled \c YES means the textfield will draw a bezeled border
*/
- (void)setBezeled:(BOOL)shouldBeBezeled
{
    if (shouldBeBezeled)
        [self setThemeState:CPThemeStateBezeled];
    else
        [self unsetThemeState:CPThemeStateBezeled];
}

/*!
    Returns \c YES if the textfield draws a bezeled border.
*/
- (BOOL)isBezeled
{
    return [self hasThemeState:CPThemeStateBezeled];
}

/*!
    Sets the textfield's bezel style.
    @param aBezelStyle the constant for the desired bezel style
*/
- (void)setBezelStyle:(CPTextFieldBezelStyle)aBezelStyle
{
    var shouldBeRounded = aBezelStyle === CPTextFieldRoundedBezel;

    if (shouldBeRounded)
        [self setThemeState:CPTextFieldStateRounded];
    else
        [self unsetThemeState:CPTextFieldStateRounded];
}

/*!
    Returns the textfield's bezel style.
*/
- (CPTextFieldBezelStyle)bezelStyle
{
    if ([self hasThemeState:CPTextFieldStateRounded])
        return CPTextFieldRoundedBezel;

    return CPTextFieldSquareBezel;
}

/*!
    Sets whether the textfield will have a border drawn.
    @param shouldBeBordered \c YES makes the textfield draw a border
*/
- (void)setBordered:(BOOL)shouldBeBordered
{
    if (shouldBeBordered)
        [self setThemeState:CPThemeStateBordered];
    else
        [self unsetThemeState:CPThemeStateBordered];
}

/*!
    Returns \c YES if the textfield has a border.
*/
- (BOOL)isBordered
{
    return [self hasThemeState:CPThemeStateBordered];
}

/*!
    Sets whether the textfield will have a background drawn.
    @param shouldDrawBackground \c YES makes the textfield draw a background
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
    Returns \c YES if the textfield draws a background.
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
#if PLATFORM(DOM)
    if (CPTextFieldInputOwner && [CPTextFieldInputOwner window] !== [self window])
        [[CPTextFieldInputOwner window] makeFirstResponder:nil];
#endif

    [self setThemeState:CPThemeStateEditing];

    [self _updatePlaceholderState];

    [self setNeedsLayout];

    _isEditing = NO;

#if PLATFORM(DOM)

    var string = [self stringValue],
        element = [self _inputElement];

    element.value = string;
    element.style.color = [[self currentValueForThemeAttribute:@"text-color"] cssString];
    element.style.font = [[self currentValueForThemeAttribute:@"font"] cssString];
    element.style.zIndex = 1000;

    switch ([self alignment])
    {
        case CPCenterTextAlignment: element.style.textAlign = "center";
                                    break;
        case CPRightTextAlignment:  element.style.textAlign = "right";
                                    break;
        default:                    element.style.textAlign = "left";
    }

    var contentRect = [self contentRectForBounds:[self bounds]];

    element.style.top = _CGRectGetMinY(contentRect) + "px";
    element.style.left = (_CGRectGetMinX(contentRect) - 1) + "px"; // why -1?
    element.style.width = _CGRectGetWidth(contentRect) + "px";
    element.style.height = _CGRectGetHeight(contentRect) + "px";

    _DOMElement.appendChild(element);

    window.setTimeout(function()
    {
        element.focus();
        [self textDidFocus:[CPNotification notificationWithName:CPTextFieldDidFocusNotification object:self userInfo:nil]];
        CPTextFieldInputOwner = self;
    }, 0.0);

    element.value = [self stringValue];

    [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];

    CPTextFieldInputIsActive = YES;

    if (document.attachEvent)
    {
        CPTextFieldCachedSelectStartFunction = [[self window] platformWindow]._DOMBodyElement.onselectstart;
        CPTextFieldCachedDragFunction = [[self window] platformWindow]._DOMBodyElement.ondrag;

        [[self window] platformWindow]._DOMBodyElement.ondrag = function () {};
        [[self window] platformWindow]._DOMBodyElement.onselectstart = function () {};
    }
#endif

    return YES;
}

/* @ignore */
- (BOOL)resignFirstResponder
{
    [self unsetThemeState:CPThemeStateEditing];

    [self _updatePlaceholderState];

    [self setNeedsLayout];

#if PLATFORM(DOM)

    var element = [self _inputElement];

    if ([self stringValue] !== element.value)
        [self _setStringValue:element.value];

    CPTextFieldInputResigning = YES;
    element.blur();

    if (!CPTextFieldInputDidBlur)
        CPTextFieldBlurFunction();

    CPTextFieldInputDidBlur = NO;
    CPTextFieldInputResigning = NO;

    if (element.parentNode == _DOMElement)
        element.parentNode.removeChild(element);

    CPTextFieldInputIsActive = NO;

    if (document.attachEvent)
    {
        [[self window] platformWindow]._DOMBodyElement.ondrag = CPTextFieldCachedDragFunction;
        [[self window] platformWindow]._DOMBodyElement.onselectstart = CPTextFieldCachedSelectStartFunction;

        CPTextFieldCachedSelectStartFunction = nil;
        CPTextFieldCachedDragFunction = nil;
    }

#endif

    //post CPControlTextDidEndEditingNotification
    if (_isEditing)
    {
        _isEditing = NO;
        [self textDidEndEditing:[CPNotification notificationWithName:CPControlTextDidEndEditingNotification object:self userInfo:nil]];

        if ([self sendsActionOnEndEditing])
            [self sendAction:[self action] to:[self target]];
    }

    [self textDidBlur:[CPNotification notificationWithName:CPTextFieldDidBlurNotification object:self userInfo:nil]];

    return YES;
}

/*!
    Text fields require panels to become key window, so this returns \c YES.
*/
- (BOOL)needsPanelToBecomeKey
{
    return YES;
}

- (void)mouseDown:(CPEvent)anEvent
{
    // Don't track! (ever?)
    if ([self isEditable] && [self isEnabled])
        return [[self window] makeFirstResponder:self];
    else if ([self isSelectable])
    {
        if (document.attachEvent)
        {
            CPTextFieldCachedSelectStartFunction = [[self window] platformWindow]._DOMBodyElement.onselectstart;
            CPTextFieldCachedDragFunction = [[self window] platformWindow]._DOMBodyElement.ondrag;

            [[self window] platformWindow]._DOMBodyElement.ondrag = function () {};
            [[self window] platformWindow]._DOMBodyElement.onselectstart = function () {};
        }
        return [[[anEvent window] platformWindow] _propagateCurrentDOMEvent:YES];
    }
    else
        return [[self nextResponder] mouseDown:anEvent];
}

- (void)mouseUp:(CPEvent)anEvent
{
    if (![self isSelectable] && (![self isEditable] || ![self isEnabled]))
        [[self nextResponder] mouseUp:anEvent];
    else if ([self isSelectable])
    {
        if (document.attachEvent)
        {
            [[self window] platformWindow]._DOMBodyElement.ondrag = CPTextFieldCachedDragFunction;
            [[self window] platformWindow]._DOMBodyElement.onselectstart = CPTextFieldCachedSelectStartFunction;

            CPTextFieldCachedSelectStartFunction = nil
            CPTextFieldCachedDragFunction = nil;
        }
        return [[[anEvent window] platformWindow] _propagateCurrentDOMEvent:YES];
    }
}

- (void)mouseDragged:(CPEvent)anEvent
{
    if (![self isSelectable] && (![self isEditable] || ![self isEnabled]))
        [[self nextResponder] mouseDragged:anEvent];
    else if ([self isSelectable])
        return [[[anEvent window] platformWindow] _propagateCurrentDOMEvent:YES];
}

- (void)keyUp:(CPEvent)anEvent
{
    var oldValue = [self stringValue];
    [self _setStringValue:[self _inputElement].value];

    if (oldValue !== [self stringValue])
    {
        if (!_isEditing)
        {
            _isEditing = YES;
            [self textDidBeginEditing:[CPNotification notificationWithName:CPControlTextDidBeginEditingNotification object:self userInfo:nil]];
        }

        [self textDidChange:[CPNotification notificationWithName:CPControlTextDidChangeNotification object:self userInfo:nil]];
    }

    [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
}

- (void)keyDown:(CPEvent)anEvent
{
    if ([anEvent keyCode] === CPReturnKeyCode)
    {
        if (_isEditing)
        {
            _isEditing = NO;
            [self textDidEndEditing:[CPNotification notificationWithName:CPControlTextDidEndEditingNotification object:self userInfo:nil]];
        }

        [self sendAction:[self action] to:[self target]];
        [self selectText:nil];

        [[[self window] platformWindow] _propagateCurrentDOMEvent:NO];
    }
    else if ([anEvent keyCode] === CPTabKeyCode)
    {
        if ([anEvent modifierFlags] & CPShiftKeyMask)
            [[self window] selectPreviousKeyView:self];
        else
            [[self window] selectNextKeyView:self];

        if ([[[self window] firstResponder] respondsToSelector:@selector(selectText:)])
            [[[self window] firstResponder] selectText:self];

        [[[self window] platformWindow] _propagateCurrentDOMEvent:NO];
    }
    else
        [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}


- (void)textDidBlur:(CPNotification)note
{
    // this looks to prevent false propagation of notifications for other objects
    if ([note object] != self)
        return;

    [[CPNotificationCenter defaultCenter] postNotification:note];
}

- (void)textDidFocus:(CPNotification)note
{
    // this looks to prevent false propagation of notifications for other objects
    if ([note object] != self)
        return;

    [[CPNotificationCenter defaultCenter] postNotification:note];
}

- (void)sendAction:(SEL)anAction to:(id)anObject
{
    // Don't reverse set our empty value
    if (!_currentValueIsPlaceholder)
        [self _reverseSetBinding];

    [CPApp sendAction:anAction to:anObject from:self];
}

/*!
    Returns the string the text field.
*/
- (id)objectValue
{
    return [super objectValue];
}

/*
    @ignore
*/
- (void)_setStringValue:(id)aValue
{
    [self willChangeValueForKey:@"objectValue"];
    [super setObjectValue:String(aValue)];
    [self _updatePlaceholderState];
    [self didChangeValueForKey:@"objectValue"];
}

- (void)setObjectValue:(id)aValue
{
    [super setObjectValue:aValue];

#if PLATFORM(DOM)

    if (CPTextFieldInputOwner === self || [[self window] firstResponder] === self)
        [self _inputElement].value = aValue;
#endif

    [self _updatePlaceholderState];
}

- (void)_updatePlaceholderState
{
    var string = [self stringValue];

    if ((!string || string.length === 0) && ![self hasThemeState:CPThemeStateEditing])
        [self setThemeState:CPTextFieldStatePlaceholder];
    else
        [self unsetThemeState:CPTextFieldStatePlaceholder];
}

/*!
    Sets a placeholder string for the receiver.  The placeholder is displayed until editing begins,
    and after editing ends, if the text field has an empty string value
*/
- (void)setPlaceholderString:(CPString)aStringValue
{
    if (_placeholderString === aStringValue)
        return;

    _placeholderString = aStringValue;

    // Only update things if we need to show the placeholder
    if ([self hasThemeState:CPTextFieldStatePlaceholder])
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

- (void)_setCurrentValueIsPlaceholder:(BOOL)isPlaceholder
{
    if (isPlaceholder)
    {
        // Save the original placeholder value so we can restore it later
        // Only do this if the placeholder is not already overridden because the bindings logic might call this method 
        // several times and we don't want the bindings placeholder to ever become the original placeholder
        if (!_currentValueIsPlaceholder)
            _originalPlaceholderString = [self placeholderString];

        // Set the current string value as the current placeholder and clear the string value
        [self setPlaceholderString:[self stringValue]];
        [self setStringValue:@""];
    }
    else
    {
        // Restore the original placeholder, the actual textfield value is already correct
        // because it was set using setValue:forKey:
        [self setPlaceholderString:_originalPlaceholderString];
    }

    _currentValueIsPlaceholder = isPlaceholder;
}

/*!
    Size to fit has two behavior, depending on if the receiver is an editable text field or not.

    For non-editable text fields (typically, a label), sizeToFit will change the frame of the
    receiver to perfectly fit the current text in stringValue in the current font, and respecting
    the current theme values for content-inset, min-size, and max-size.

    For editable text fields, sizeToFit will ONLY change the HEIGHT of the text field. It will not
    change the width of the text field. You can use setFrameSize: with the current height to set the
    width, and you can get the size of a string with [CPString sizeWithFont:].

    The logic behind this decision is that most of the time you do not know what content will be placed
    in an editable text field, so you want to just choose a fixed width and leave it at that size.
    However, since you don't know how tall it needs to be if you change the font, sizeToFit will still be
    useful for making the textfield an appropriate height.
*/

- (void)sizeToFit
{
    var size = [([self stringValue] || " ") sizeWithFont:[self currentValueForThemeAttribute:@"font"]],
        contentInset = [self currentValueForThemeAttribute:@"content-inset"],
        minSize = [self currentValueForThemeAttribute:@"min-size"],
        maxSize = [self currentValueForThemeAttribute:@"max-size"];

    size.width = MAX(size.width + contentInset.left + contentInset.right, minSize.width);
    size.height = MAX(size.height + contentInset.top + contentInset.bottom, minSize.height);

    if (maxSize.width >= 0.0)
        size.width = MIN(size.width, maxSize.width);

    if (maxSize.height >= 0.0)
        size.height = MIN(size.height, maxSize.height);

    if ([self isEditable])
        size.width = CGRectGetWidth([self frame]);

    [self setFrameSize:size];
}

/*!
    Select all the text in the CPTextField.
*/
- (void)selectText:(id)sender
{
#if PLATFORM(DOM)
    var element = [self _inputElement];

    if (([self isEditable] || [self isSelectable]))
    {
        if ([[self window] firstResponder] === self)
            window.setTimeout(function() { element.select(); }, 0);
        else if ([self window] !== nil && [[self window] makeFirstResponder:self])
            window.setTimeout(function() {[self selectText:sender];}, 0);
    }
#endif
}

- (void)copy:(id)sender
{
    if (![CPPlatform isBrowser])
    {
        var selectedRange = [self selectedRange];

        if (selectedRange.length < 1)
            return;

        var pasteboard = [CPPasteboard generalPasteboard],
            stringValue = [self stringValue],
            stringForPasting = [stringValue substringWithRange:selectedRange];

        [pasteboard declareTypes:[CPStringPboardType] owner:nil];
        [pasteboard setString:stringForPasting forType:CPStringPboardType];
    }
}

- (void)cut:(id)sender
{
    if (![CPPlatform isBrowser])
    {
        [self copy:sender];
        [self deleteBackward:sender];
    }
}

- (void)paste:(id)sender
{
    if (![CPPlatform isBrowser])
    {
        var pasteboard = [CPPasteboard generalPasteboard];

        if (![[pasteboard types] containsObject:CPStringPboardType])
            return;

        [self deleteBackward:sender];

        var selectedRange = [self selectedRange],
            stringValue = [self stringValue],
            pasteString = [pasteboard stringForType:CPStringPboardType],
            newValue = [stringValue stringByReplacingCharactersInRange:selectedRange withString:pasteString];

        [self setStringValue:newValue];
        [self setSelectedRange:CPMakeRange(selectedRange.location + pasteString.length, 0)];
    }
}

- (CPRange)selectedRange
{
    if ([[self window] firstResponder] !== self)
        return CPMakeRange(0, 0);

    // we wrap this in try catch because firefox will throw an exception in certain instances
    try
    {
        var inputElement = [self _inputElement],
            selectionStart = inputElement.selectionStart,
            selectionEnd = inputElement.selectionEnd;

        if ([selectionStart isKindOfClass:CPNumber])
            return CPMakeRange(selectionStart, selectionEnd - selectionStart);

        // browsers which don't support selectionStart/selectionEnd (aka IE).
        var theDocument = inputElement.ownerDocument || inputElement.document,
            selectionRange = theDocument.selection.createRange(),
            range = inputElement.createTextRange();

        if (range.inRange(selectionRange))
        {
            range.setEndPoint('EndToStart', selectionRange);
            return CPMakeRange(range.text.length, selectionRange.text.length);
        }
    }
    catch (e)
    {
        // fall through to the return
    }

    return CGMakeRange(0, 0);
}

- (void)setSelectedRange:(CPRange)aRange
{
    if (![[self window] firstResponder] === self)
        return;

    var inputElement = [self _inputElement];

    try
    {
        if ([inputElement.selectionStart isKindOfClass:CPNumber])
        {
            inputElement.selectionStart = aRange.location;
            inputElement.selectionEnd = CPMaxRange(aRange);
        }
        else
        {
            // browsers which don't support selectionStart/selectionEnd (aka IE).
            var theDocument = inputElement.ownerDocument || inputElement.document,
                existingRange = theDocument.selection.createRange(),
                range = inputElement.createTextRange();

            if (range.inRange(existingRange))
            {
                range.collapse(true);
                range.move('character', aRange.location);
                range.moveEnd('character', aRange.length);
                range.select();
            }
        }
    }
    catch (e)
    {
    }
}

- (void)selectAll:(id)sender
{
    [self selectText:sender];
}

- (void)deleteBackward:(id)sender
{
    var selectedRange = [self selectedRange],
        stringValue = [self stringValue],
        newValue = [stringValue stringByReplacingCharactersInRange:selectedRange withString:""];

    [self setStringValue:newValue];
    [self setSelectedRange:CPMakeRange(selectedRange.location, 0)];
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
        [defaultCenter removeObserver:_delegate name:CPTextFieldDidFocusNotification object:self];
        [defaultCenter removeObserver:_delegate name:CPTextFieldDidBlurNotification object:self];
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

    if ([_delegate respondsToSelector:@selector(controlTextDidFocus:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(controlTextDidFocus:)
                   name:CPTextFieldDidFocusNotification
                 object:self];

    if ([_delegate respondsToSelector:@selector(controlTextDidBlur:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(controlTextDidBlur:)
                   name:CPTextFieldDidBlurNotification
                 object:self];
}

- (id)delegate
{
    return _delegate;
}

- (CGRect)contentRectForBounds:(CGRect)bounds
{
    var contentInset = [self currentValueForThemeAttribute:@"content-inset"];

    if (!contentInset)
        return bounds;

    bounds.origin.x += contentInset.left;
    bounds.origin.y += contentInset.top;
    bounds.size.width -= contentInset.left + contentInset.right;
    bounds.size.height -= contentInset.top + contentInset.bottom;

    return bounds;
}

- (CGRect)bezelRectForBounds:(CGRect)bounds
{
    var bezelInset = [self currentValueForThemeAttribute:@"bezel-inset"];

    if (_CGInsetIsEmpty(bezelInset))
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

        [view setHitTests:NO];

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
        [bezelView setBackgroundColor:[self currentValueForThemeAttribute:@"bezel-color"]];

    var contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                             positioned:CPWindowAbove
                        relativeToEphemeralSubviewNamed:@"bezel-view"];

    if (contentView)
    {
        [contentView setHidden:[self hasThemeState:CPThemeStateEditing]];

        var string = "";

        if ([self hasThemeState:CPTextFieldStatePlaceholder])
            string = [self placeholderString];
        else
        {
            string = [self stringValue];

            if ([self isSecure])
                string = secureStringForString(string);
        }

        [contentView setText:string];

        [contentView setTextColor:[self currentValueForThemeAttribute:@"text-color"]];
        [contentView setFont:[self currentValueForThemeAttribute:@"font"]];
        [contentView setAlignment:[self currentValueForThemeAttribute:@"alignment"]];
        [contentView setVerticalAlignment:[self currentValueForThemeAttribute:@"vertical-alignment"]];
        [contentView setLineBreakMode:[self currentValueForThemeAttribute:@"line-break-mode"]];
        [contentView setTextShadowColor:[self currentValueForThemeAttribute:@"text-shadow-color"]];
        [contentView setTextShadowOffset:[self currentValueForThemeAttribute:@"text-shadow-offset"]];
    }
}

- (void)takeValueFromKeyPath:(CPString)aKeyPath ofObjects:(CPArray)objects
{
    var count = objects.length,
        value = [objects[0] valueForKeyPath:aKeyPath];

    [self setStringValue:value];
    [self setPlaceholderString:@""];

    while (count-- > 1)
        if (value !== [objects[count] valueForKeyPath:aKeyPath])
        {
            [self setPlaceholderString:@"Multiple Values"];
            [self setStringValue:@""];
        }
}

@end

var secureStringForString = function(aString)
{
    // This is true for when aString === "" and null/undefined.
    if (!aString)
        return "";

    return Array(aString.length + 1).join(CPSecureTextFieldCharacter);
}


var CPTextFieldIsEditableKey            = "CPTextFieldIsEditableKey",
    CPTextFieldIsSelectableKey          = "CPTextFieldIsSelectableKey",
    CPTextFieldIsBorderedKey            = "CPTextFieldIsBorderedKey",
    CPTextFieldIsBezeledKey             = "CPTextFieldIsBezeledKey",
    CPTextFieldBezelStyleKey            = "CPTextFieldBezelStyleKey",
    CPTextFieldDrawsBackgroundKey       = "CPTextFieldDrawsBackgroundKey",
    CPTextFieldLineBreakModeKey         = "CPTextFieldLineBreakModeKey",
    CPTextFieldAlignmentKey             = "CPTextFieldAlignmentKey",
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

        [self setLineBreakMode:[aCoder decodeIntForKey:CPTextFieldLineBreakModeKey]];
        [self setAlignment:[aCoder decodeIntForKey:CPTextFieldAlignmentKey]];

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

    [aCoder encodeInt:[self lineBreakMode] forKey:CPTextFieldLineBreakModeKey];
    [aCoder encodeInt:[self alignment] forKey:CPTextFieldAlignmentKey];

    [aCoder encodeObject:_placeholderString forKey:CPTextFieldPlaceholderStringKey];
}

@end

