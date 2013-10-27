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
@import "CPText.j"
@import "CPWindow_Constants.j"
@import "_CPImageAndTextView.j"

@class CPPasteboard

@global CPApp
@global CPStringPboardType

CPTextFieldSquareBezel          = 0;    /*! A textfield bezel with squared corners. */
CPTextFieldRoundedBezel         = 1;    /*! A textfield bezel with rounded corners. */

CPTextFieldDidFocusNotification = @"CPTextFieldDidFocusNotification";
CPTextFieldDidBlurNotification  = @"CPTextFieldDidBlurNotification";

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
    CPTextFieldBlurHandler = nil,
    CPTextFieldInputFunction = nil;

var CPSecureTextFieldCharacter = "\u2022";


function CPTextFieldBlurFunction(anEvent, owner, domElement, inputElement, resigning, didBlurRef)
{
    if (owner && domElement != inputElement.parentNode)
        return;

    var ownerWindow = [owner window];

    if (!resigning && [ownerWindow isKeyWindow])
    {
        /*
            Browsers blur text fields when a click occurs anywhere outside the text field. That is normal for browsers, but in Cocoa the key view retains focus unless the click target accepts first responder. So if we lost focus but were not told to resign and our window is still key, restore focus,
            but only if the text field is completely within the browser window. If we restore focus when it
            is off screen, the entire body scrolls out of our control.
        */
        if ([owner _isWithinUsablePlatformRect])
        {
            window.setTimeout(function()
            {
                inputElement.focus();
            }, 0.0);
        }
    }

    CPTextFieldHandleBlur(anEvent, @ref(owner));
    @deref(didBlurRef) = YES;

    return true;
}

function CPTextFieldHandleBlur(anEvent, ownerRef)
{
    @deref(ownerRef) = nil;

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}


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
    BOOL                    _willBecomeFirstResponderByClick;

    BOOL                    _drawsBackground;

    CPColor                 _textFieldBackgroundColor;

    CPString                _placeholderString;
    CPString                _stringValue;

    id                      _delegate;

    // NS-style Display Properties
    CPTextFieldBezelStyle   _bezelStyle;
    BOOL                    _isBordered;
    CPControlSize           _controlSize;
}

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding === CPValueBinding)
        return [_CPTextFieldValueBinder class];
    else if ([aBinding hasPrefix:CPDisplayPatternValueBinding])
        return [_CPTextFieldPatternValueBinder class];
    else if ([aBinding hasPrefix:CPEditableBinding])
        return [CPMultipleValueAndBinding class];

    return [super _binderClassForBinding:aBinding];
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

+ (CPString)defaultThemeClass
{
    return "textfield";
}

+ (id)themeAttributes
{
    return @{
            @"bezel-inset": CGInsetMakeZero(),
            @"content-inset": CGInsetMake(1.0, 0.0, 0.0, 0.0),
            @"bezel-color": [CPNull null],
        };
}

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

        CPTextFieldBlurHandler = function(anEvent)
        {
            return CPTextFieldBlurFunction(
                        anEvent,
                        CPTextFieldInputOwner,
                        CPTextFieldInputOwner ? CPTextFieldInputOwner._DOMElement : nil,
                        CPTextFieldDOMInputElement,
                        CPTextFieldInputResigning,
                        @ref(CPTextFieldInputDidBlur));
        };

        if (CPFeatureIsCompatible(CPInputOnInputEventFeature))
        {
            CPTextFieldInputFunction = function(anEvent)
            {
                if (!CPTextFieldInputOwner)
                    return;

                var cappEvent = [CPEvent keyEventWithType:CPKeyUp
                                                 location:CGPointMakeZero()
                                            modifierFlags:0
                                                timestamp:[CPEvent currentTimestamp]
                                             windowNumber:[[CPApp keyWindow] windowNumber]
                                                  context:nil
                                               characters:nil
                              charactersIgnoringModifiers:nil
                                                isARepeat:NO
                                                  keyCode:nil];

                [CPTextFieldInputOwner keyUp:cappEvent];

                [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
            }

            CPTextFieldDOMInputElement.oninput = CPTextFieldInputFunction;
        }

        // FIXME make this not onblur
        CPTextFieldDOMInputElement.onblur = CPTextFieldBlurHandler;

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

            CPTextFieldDOMPasswordInputElement.onblur = CPTextFieldBlurHandler;
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

    if (_isEditable)
        [self setThemeState:CPThemeStateEditable];
    else
        [self unsetThemeState:CPThemeStateEditable];

    // We only allow first responder status if the field is enable, and editable or selectable.
    if (!(shouldBeEditable && ![self isSelectable]) && [[self window] firstResponder] === self)
        [[self window] makeFirstResponder:nil];

    if (shouldBeEditable)
        [self setThemeState:CPThemeStateEditable];
    else
        [self unsetThemeState:CPThemeStateEditable];
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

    // We only allow first responder status if the field is enabled.
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

/*! @ignore */
- (BOOL)acceptsFirstResponder
{
    return ([self isEnabled] && [self isEditable] || [self isSelectable]) && [self _isWithinUsablePlatformRect];
}

/*! @ignore */
- (BOOL)becomeFirstResponder
{
    if (![self isEnabled])
        return NO;

    // As long as we are the first responder we need to monitor the key status of our window.
    [self _setObserveWindowKeyNotifications:YES];

    _isEditing = NO;

    if ([[self window] isKeyWindow] && [self isEditable])
        return [self _becomeFirstKeyResponder];

    return YES;
}

/*
    A text field can be the first responder without necessarily being the focus of keyboard input. For example, it might be the first responder of window A but window B is the main and key window. It's important we don't put a focused input field into a text field in a non-key window, even if that field is the first responder, because the key window might also have a first responder text field which the user will expect to receive keyboard input.

    Since a first responder but non-key window text field can't receive input it should not even look like an active text field (Cocoa has a "slightly active" text field look it uses when another window is the key window, but Cappuccino doesn't today.)

    It's also possible for a text field to be non-editable but selectable in which case it can also become the first responder -
    this is what allows text to be copied from it.
*/
- (BOOL)_becomeFirstKeyResponder
{
    // If the text field is still not completely on screen, refuse to become
    // first responder, because the browser will scroll it into view out of our control.
    if (![self _isWithinUsablePlatformRect])
        return NO;

    // A selectable but non-editable text field may be the first responder, but never the
    // first key responder (first key responder indicating editability.)
    if (![self isEditable])
        return NO;

    [self setThemeState:CPThemeStateEditing];

    [self _updatePlaceholderState];

    [self setNeedsLayout];

    _stringValue = [self stringValue];

#if PLATFORM(DOM)

    var element = [self _inputElement],
        font = [self currentValueForThemeAttribute:@"font"],
        lineHeight = [font defaultLineHeightForFont];

    element.value = _stringValue;
    element.style.color = [[self currentValueForThemeAttribute:@"text-color"] cssString];

    if (CPFeatureIsCompatible(CPInputSetFontOutsideOfDOM))
        element.style.font = [font cssString];

    element.style.zIndex = 1000;

    switch ([self alignment])
    {
        case CPCenterTextAlignment:
            element.style.textAlign = "center";
            break;

        case CPRightTextAlignment:
            element.style.textAlign = "right";
            break;

        default:
            element.style.textAlign = "left";
    }

    var contentRect = [self contentRectForBounds:[self bounds]],
        verticalAlign = [self currentValueForThemeAttribute:"vertical-alignment"];

    switch (verticalAlign)
    {
        case CPTopVerticalTextAlignment:
            var topPoint = CGRectGetMinY(contentRect) + "px";
            break;

        case CPCenterVerticalTextAlignment:
            var topPoint = (CGRectGetMidY(contentRect) - (lineHeight / 2)) + "px";
            break;

        case CPBottomVerticalTextAlignment:
            var topPoint = (CGRectGetMaxY(contentRect) - lineHeight) + "px";
            break;

        default:
            var topPoint = CGRectGetMinY(contentRect) + "px";
            break;
    }

    element.style.top = topPoint;

    var left = CGRectGetMinX(contentRect);

    // If the browser has a built in left padding, compensate for it. We need the input text to be exactly on top of the original text.
    if (CPFeatureIsCompatible(CPInput1PxLeftPadding))
        left -= 1;

    element.style.left = left + "px";
    element.style.width = CGRectGetWidth(contentRect) + "px";
    element.style.height = ROUND(lineHeight) + "px";
    element.style.lineHeight = ROUND(lineHeight) + "px";
    element.style.verticalAlign = "top";
    element.style.cursor = "auto";

    _DOMElement.appendChild(element);

    // The font change above doesn't work for some browsers if the element isn't already appendChild'ed.
    if (!CPFeatureIsCompatible(CPInputSetFontOutsideOfDOM))
        element.style.font = [font cssString];

    CPTextFieldInputIsActive = YES;

    if (document.attachEvent)
    {
        CPTextFieldCachedSelectStartFunction = [[self window] platformWindow]._DOMBodyElement.onselectstart;
        CPTextFieldCachedDragFunction = [[self window] platformWindow]._DOMBodyElement.ondrag;

        [[self window] platformWindow]._DOMBodyElement.ondrag = function () {};
        [[self window] platformWindow]._DOMBodyElement.onselectstart = function () {};
    }

    CPTextFieldInputOwner = self;

    window.setTimeout(function()
    {
        /*
            setTimeout handlers are not guaranteed to fire in the order they were initiated. This can cause a race condition when several windows with text fields are opened quickly, resulting in several instances of this timeout function being fired, perhaps out of order. So we have to check that by the time this function is fired, CPTextFieldInputOwner has not been changed to another text field in the meantime.
        */
        if (CPTextFieldInputOwner !== self)
            return;

        element.focus();

        // Select the text if the textfield became first responder through keyboard interaction
        if (!_willBecomeFirstResponderByClick)
            [self _selectText:self immediately:YES];

        _willBecomeFirstResponderByClick = NO;

        [self textDidFocus:[CPNotification notificationWithName:CPTextFieldDidFocusNotification object:self userInfo:nil]];
    }, 0.0);

#endif

    return YES;
}

/*! @ignore */
- (BOOL)resignFirstResponder
{
#if PLATFORM(DOM)
    // We might have been the first responder without actually editing.
    if (_isEditing && CPTextFieldInputOwner === self)
    {
        var element = [self _inputElement],
            newValue = element.value,
            error = @"";

        if (newValue !== _stringValue)
        {
            [self _setStringValue:newValue];
        }

        // If there is a formatter, always give it a chance to reject the resignation,
        // even if the value has not changed.
        if ([self _valueIsValid:newValue] === NO)
        {
            element.focus();
            return NO;
        }
    }
#endif

    // When we are no longer the first responder we don't worry about the key status of our window anymore.
    [self _setObserveWindowKeyNotifications:NO];

    [self _resignFirstKeyResponder];

    _isEditing = NO;
    if ([self isEditable])
    {
        [self textDidEndEditing:[CPNotification notificationWithName:CPControlTextDidEndEditingNotification object:self userInfo:nil]];

        if ([self sendsActionOnEndEditing])
            [self sendAction:[self action] to:[self target]];
    }

    [self textDidBlur:[CPNotification notificationWithName:CPTextFieldDidBlurNotification object:self userInfo:nil]];

    return YES;
}

- (void)_resignFirstKeyResponder
{
    [self unsetThemeState:CPThemeStateEditing];

    // Cache the formatted string
    _stringValue = [self stringValue];

    _willBecomeFirstResponderByClick = NO;

    [self _updatePlaceholderState];
    [self setNeedsLayout];

#if PLATFORM(DOM)

    var element = [self _inputElement];

    CPTextFieldInputResigning = YES;

    if (CPTextFieldInputIsActive)
        element.blur();

    if (!CPTextFieldInputDidBlur)
        CPTextFieldBlurHandler();

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
}

- (void)_setObserveWindowKeyNotifications:(BOOL)shouldObserve
{
    if (shouldObserve)
    {
        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_windowDidResignKey:) name:CPWindowDidResignKeyNotification object:[self window]];
        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_windowDidBecomeKey:) name:CPWindowDidBecomeKeyNotification object:[self window]];
    }
    else
    {
        [[CPNotificationCenter defaultCenter] removeObserver:self name:CPWindowDidResignKeyNotification object:[self window]];
        [[CPNotificationCenter defaultCenter] removeObserver:self name:CPWindowDidBecomeKeyNotification object:[self window]];
    }
}

- (void)_windowDidResignKey:(CPNotification)aNotification
{
    if (![[self window] isKeyWindow])
        [self _resignFirstKeyResponder];
}

- (void)_windowDidBecomeKey:(CPNotification)aNotification
{
    if (!([self isEnabled] && [self isEditable]))
        return;

    var wind = [self window];

    if ([wind isKeyWindow] && [wind firstResponder] === self)
        if (![self _becomeFirstKeyResponder])
            [wind makeFirstResponder:nil];
}

- (BOOL)_valueIsValid:(CPString)aValue
{
#if PLATFORM(DOM)

    var error = @"";

    if ([self _setStringValue:aValue isNewValue:NO errorDescription:@ref(error)] === NO)
    {
        var acceptInvalidValue = NO;

        if ([_delegate respondsToSelector:@selector(control:didFailToFormatString:errorDescription:)])
            acceptInvalidValue = [_delegate control:self didFailToFormatString:aValue errorDescription:error];

        if (acceptInvalidValue === NO)
            return NO;
    }

#endif

    return YES;
}

/*!
    Text fields require panels to become key window, so this returns \c YES
    if the text field is ready to become the first responder as well.
*/
- (BOOL)needsPanelToBecomeKey
{
    return [self acceptsFirstResponder];
}

/*!
    Only text fields that can become first responder accept first mouse.
*/
- (BOOL)acceptsFirstMouse:(CPEvent)anEvent
{
    return [self acceptsFirstResponder];
}

- (void)_didEdit
{
    if (!_isEditing)
    {
        _isEditing = YES;
        [self textDidBeginEditing:[CPNotification notificationWithName:CPControlTextDidBeginEditingNotification object:self userInfo:nil]];
    }

    [self textDidChange:[CPNotification notificationWithName:CPControlTextDidChangeNotification object:self userInfo:nil]];
}

- (void)mouseDown:(CPEvent)anEvent
{
    // Don't track! (ever?)
    if ([self isEditable] && [self isEnabled])
    {
        _willBecomeFirstResponderByClick = YES;
        [[self window] makeFirstResponder:self];
    }
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
    if (![self isEnabled] || !([self isSelectable] || [self isEditable]))
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

        // TODO clickCount === 2 should select the clicked word.

        if ([[CPApp currentEvent] clickCount] === 3)
        {
            [self selectText:nil];
            return;
        }

        return [[[anEvent window] platformWindow] _propagateCurrentDOMEvent:YES];
    }
}

- (void)mouseDragged:(CPEvent)anEvent
{
    if (![self isEnabled] || !([self isSelectable] || [self isEditable]))
        [[self nextResponder] mouseDragged:anEvent];
    else if ([self isSelectable])
        return [[[anEvent window] platformWindow] _propagateCurrentDOMEvent:YES];
}

- (void)keyUp:(CPEvent)anEvent
{
    if (!([self isEnabled] && [self isEditable]))
        return;

#if PLATFORM(DOM)
    var newValue = [self _inputElement].value;

    if (newValue !== _stringValue)
    {
        [self _setStringValue:newValue];

        [self _didEdit];
    }

    [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
#endif
}

- (void)keyDown:(CPEvent)anEvent
{
    // CPTextField uses an HTML input element to take the input so we need to
    // propagate the dom event so the element is updated. This has to be done
    // before interpretKeyEvents: though so individual commands have a chance
    // to override this (escape to clear the text in a search field for example).
    [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];

    [self interpretKeyEvents:[anEvent]];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

/*!
    Invoke the action specified by aSelector on the current responder.

    This is implemented by CPResponder and by default it passes any unrecognized
    actions on to the next responder but text fields apparently aren't supposed
    to do that according to this documentation by Apple:

    http://developer.apple.com/mac/library/documentation/cocoa/reference/NSTextInputClient_Protocol/Reference/Reference.html#//apple_ref/occ/intfm/NSTextInputClient/doCommandBySelector:
*/
- (void)doCommandBySelector:(SEL)aSelector
{
    if ([self respondsToSelector:aSelector])
        [self performSelector:aSelector];
}

- (void)insertNewline:(id)sender
{
    if (!([self isEnabled] && [self isEditable]))
        return;

    var newValue = [self _inputElement].value;

    if (newValue !== _stringValue)
    {
        [self _setStringValue:newValue];
        [self _didEdit];
    }

    if ([self _valueIsValid:_stringValue])
    {
        // If _isEditing == YES then the target action can also be called via
        // resignFirstResponder, and it is possible that the target action
        // itself will change this textfield's responder status, so start by
        // setting the _isEditing flag to NO to prevent the target action being
        // called twice (once below and once from resignFirstResponder).
        if (_isEditing)
        {
            _isEditing = NO;
            [self textDidEndEditing:[CPNotification notificationWithName:CPControlTextDidEndEditingNotification object:self userInfo:nil]];
        }

        // If there is no target action, or the sendAction call returns
        // success.
        if (![self action] || [self sendAction:[self action] to:[self target]])
        {
            [self selectAll:nil];
        }
    }

    [[[self window] platformWindow] _propagateCurrentDOMEvent:NO];
}

- (void)insertNewlineIgnoringFieldEditor:(id)sender
{
    [self _insertCharacterIgnoringFieldEditor:CPNewlineCharacter];
}

- (void)insertTabIgnoringFieldEditor:(id)sender
{
    [self _insertCharacterIgnoringFieldEditor:CPTabCharacter];
}

- (void)_insertCharacterIgnoringFieldEditor:(CPString)aCharacter
{
    if (!([self isEnabled] && [self isEditable]))
        return;

#if PLATFORM(DOM)

    var oldValue = _stringValue,
        range = [self selectedRange],
        element = [self _inputElement];

    element.value = [element.value stringByReplacingCharactersInRange:[self selectedRange] withString:aCharacter];
    [self _setStringValue:element.value];

    // NOTE: _stringValue is now the current input element value
    if (oldValue !== _stringValue)
    {
        [self _didEdit];
    }

#endif
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

- (void)textDidChange:(CPNotification)note
{
    if ([note object] !== self)
        return;

    [self _continuouslyReverseSetBinding];

    [super textDidChange:note];
}

/*!
    Returns the string in the text field.
*/
- (id)objectValue
{
    return [super objectValue];
}

/*
    Sets the internal string value without updating the value in the input element.
    This should only be invoked when the underlying text element's value has changed.
*/
- (BOOL)_setStringValue:(CPString)aValue
{
    return [self _setStringValue:aValue isNewValue:YES errorDescription:nil];
}

/*!
    Sets the internal string value without updating the value in the input element.
    If there is a formatter and formatting fails, returns NO. Otherwise returns YES.
*/
- (BOOL)_setStringValue:(CPString)aValue isNewValue:(BOOL)isNewValue errorDescription:(CPStringRef)anError
{
    _stringValue = aValue;

    var objectValue = aValue,
        formatter = [self formatter],
        result = YES;

    if (formatter)
    {
        var object = nil;

        if ([formatter getObjectValue:@ref(object) forString:aValue errorDescription:anError])
            objectValue = object;
        else
        {
            objectValue = undefined;  // Mark the value as invalid
            result = NO;
        }

        isNewValue |= objectValue !== [super objectValue];
    }

    if (isNewValue)
    {
        [self willChangeValueForKey:@"objectValue"];
        [super setObjectValue:objectValue];
        [self _updatePlaceholderState];
        [self didChangeValueForKey:@"objectValue"];
    }

    return result;
}

- (void)setObjectValue:(id)aValue
{
    [super setObjectValue:aValue];

    var formatter = [self formatter];

    if (formatter)
    {
        // If there is a formatter, make sure the object value can be formatted successfully
        var formattedString = [self hasThemeState:CPThemeStateEditing] ? [formatter editingStringForObjectValue:aValue] : [formatter stringForObjectValue:aValue];

        if (formattedString === nil)
        {
            var value = nil;

            // Formatting failed, get an "empty" object by formatting an empty string.
            // If that fails, the value is undefined.
            if ([formatter getObjectValue:@ref(value) forString:@"" errorDescription:nil] === NO)
                value = undefined;

            [super setObjectValue:value];
            _stringValue = (value === nil || value === undefined) ? @"" : String(value);
        }
        else
            _stringValue = formattedString;
    }
    else
        _stringValue = [self stringValue];

#if PLATFORM(DOM)

    if (CPTextFieldInputOwner === self || [[self window] firstResponder] === self)
        [self _inputElement].value = _stringValue;

#endif

    [self _updatePlaceholderState];
}

- (void)_updatePlaceholderState
{
    if ((!_stringValue || _stringValue.length === 0) && ![self hasThemeState:CPThemeStateEditing])
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

/*!
    For non-bezeled text fields (typically a label), sizeToFit has two behaviors, depending
    on the line break mode of the receiver.

    For non-bezeled receivers with a non-wrapping line break mode, sizeToFit will change the frame of the
    receiver to perfectly fit the current text in stringValue in the current font, respecting
    the current theme value for content-inset. For receivers with a wrapping line break mode,
    sizeToFit will wrap the text within the current width (respecting the current content-inset),
    so it will ONLY change the HEIGHT.

    For bezeled text fields (typically editable fields), sizeToFit will ONLY change the HEIGHT
    of the text field. It will not change the width of the text field. sizeToFit will attempt to
    change the height to fit a single line of text, respecting the current theme values for min-size,
    max-size and content-inset.

    The logic behind this decision is that most of the time you do not know what content will be placed
    in a bezeled text field, so you want to just choose a fixed width and leave it at that size.
    However, since you don't know how tall it needs to be if you change the font, sizeToFit will still be
    useful for making the textfield an appropriate height.
*/
- (void)sizeToFit
{
    [self setFrameSize:[self _minimumFrameSize]];
}

- (CGSize)_minimumFrameSize
{
    var frameSize = [self frameSize],
        contentInset = [self currentValueForThemeAttribute:@"content-inset"],
        minSize = [self currentValueForThemeAttribute:@"min-size"],
        maxSize = [self currentValueForThemeAttribute:@"max-size"],
        lineBreakMode = [self lineBreakMode],
        text = (_stringValue || @" "),
        textSize = CGSizeMakeCopy(frameSize),
        font = [self currentValueForThemeAttribute:@"font"];

    textSize.width -= contentInset.left + contentInset.right;
    textSize.height -= contentInset.top + contentInset.bottom;

    if (frameSize.width !== 0 &&
        ![self isBezeled]     &&
        (lineBreakMode === CPLineBreakByWordWrapping || lineBreakMode === CPLineBreakByCharWrapping))
    {
        textSize = [text sizeWithFont:font inWidth:textSize.width];
    }
    else
    {
        textSize = [text sizeWithFont:font];

        // Account for possible fractional pixels at right edge
        textSize.width += 1;
    }

    // Account for possible fractional pixels at bottom edge
    textSize.height += 1;

    frameSize.height = textSize.height + contentInset.top + contentInset.bottom;

    if ([self isBezeled])
    {
        frameSize.height = MAX(frameSize.height, minSize.height);

        if (maxSize.width > 0.0)
            frameSize.width = MIN(frameSize.width, maxSize.width);

        if (maxSize.height > 0.0)
            frameSize.height = MIN(frameSize.height, maxSize.height);
    }
    else
        frameSize.width = textSize.width + contentInset.left + contentInset.right;

    frameSize.width = MAX(frameSize.width, minSize.width);

    return frameSize;
}

/*!
    Make the receiver the first responder and select all the text in the field.
*/
- (void)selectText:(id)sender
{
    [self _selectText:sender immediately:NO];
}

- (void)_selectText:(id)sender immediately:(BOOL)immediately
{
    // Selecting the text in a field makes it the first responder
    if ([self isEditable] || [self isSelectable])
    {
        var wind = [self window];

#if PLATFORM(DOM)
        if ([self isEditable])
        {
            var element = [self _inputElement];

            if ([wind firstResponder] === self)
            {
                if (immediately)
                    element.select();
                else
                    window.setTimeout(function() { element.select(); }, 0);
            }
            else if (wind !== nil && [wind makeFirstResponder:self])
                [self _selectText:sender immediately:immediately];
        }
        else
        {
            [self setSelectedRange:CPMakeRange(0, _stringValue.length)];
        }
#else
        // Even if we can't actually select the text we need to preserve the first
        // responder side effect.
        if (wind !== nil && [wind firstResponder] !== self)
            [wind makeFirstResponder:self];
#endif
    }

}

- (void)copy:(id)sender
{
    // First write to the Cappuccino clipboard.
    var stringToCopy = nil;

    if ([self isEditable])
    {
        var selectedRange = [self selectedRange];

        if (selectedRange.length < 1)
            return;

        stringToCopy = [_stringValue substringWithRange:selectedRange];
    }
    else
    {
        // selectedRange won't work if we're displaying our text using a <div>. Instead we have to ask the browser
        // what's selected and hope it's right in a Cappuccino context as well.
#if PLATFORM(DOM)
        stringToCopy = [[[self window] platformWindow] _selectedText];
#endif
    }

    var pasteboard = [CPPasteboard generalPasteboard];

    [pasteboard declareTypes:[CPStringPboardType] owner:nil];
    [pasteboard setString:stringToCopy forType:CPStringPboardType];

    if ([CPPlatform isBrowser])
    {
        // Then also allow the browser to capture the copied text into the system clipboard.
        [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
    }
}

- (void)cut:(id)sender
{
    if (![self isEnabled])
        return;

    [self copy:sender];

    if (![self isEditable])
        return;

    if (![[CPApp currentEvent] _platformIsEffectingCutOrPaste])
    {
        [self deleteBackward:sender];
    }
    else
    {
        // Allow the browser's standard cut handling. This should also result in the deleteBackward: happening.
        [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];

        // If we don't have an oninput listener, we won't detect the change made by the cut and need to fake a key up "soon".
        if (!CPFeatureIsCompatible(CPInputOnInputEventFeature))
            [CPTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(keyUp:) userInfo:nil repeats:NO];
    }
}

- (void)paste:(id)sender
{
    if (!([self isEnabled] && [self isEditable]))
        return;

    if (![[CPApp currentEvent] _platformIsEffectingCutOrPaste])
    {
        var pasteboard = [CPPasteboard generalPasteboard];

        if (![[pasteboard types] containsObject:CPStringPboardType])
            return;

        [self deleteBackward:sender];

        var selectedRange = [self selectedRange],
            pasteString = [pasteboard stringForType:CPStringPboardType],
            newValue = [_stringValue stringByReplacingCharactersInRange:selectedRange withString:pasteString];

        [self setStringValue:newValue];
        [self _didEdit];
        [self setSelectedRange:CPMakeRange(selectedRange.location + pasteString.length, 0)];
    }
    // If we don't have an oninput listener, we won't detect the change made by the cut and need to fake a key up "soon".
    else
    {
        // Allow the browser's standard paste handling.
        [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];

        if (!CPFeatureIsCompatible(CPInputOnInputEventFeature))
            [CPTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(keyUp:) userInfo:nil repeats:NO];
    }
}

- (CPRange)selectedRange
{
    // TODO Need a way to figure out the selected range if we're not using an input. Need
    // to get whole document selection and somehow see which part is inside of this text field.
    if ([[self window] firstResponder] !== self)
        return CPMakeRange(0, 0);

#if PLATFORM(DOM)

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

#endif

    return CPMakeRange(0, 0);
}

- (void)setSelectedRange:(CPRange)aRange
{
    if (![[self window] firstResponder] === self)
        return;

#if PLATFORM(DOM)

    if (![self isEditable])
    {
        // No input element - selectable text field only.
        var contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                         positioned:CPWindowAbove
                    relativeToEphemeralSubviewNamed:@"bezel-view"];

        if (contentView)
            [contentView setSelectedRange:aRange];
    }
    else
    {
        // Input element
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
#endif
}

- (void)selectAll:(id)sender
{
    [self selectText:sender];
}

- (void)deleteBackward:(id)sender
{
    if (!([self isEnabled] && [self isEditable]))
        return;

    var selectedRange = [self selectedRange];

    if (selectedRange.length < 1)
    {
        if (selectedRange.location < 1)
            return;

        // Delete a single element backward from the insertion point if there's no selection.
        selectedRange.location -= 1;
        selectedRange.length += 1;
    }

    var newValue = [_stringValue stringByReplacingCharactersInRange:selectedRange withString:""];

    [self setStringValue:newValue];
    [self setSelectedRange:CPMakeRange(selectedRange.location, 0)];
    [self _didEdit];

#if PLATFORM(DOM)
    // Since we just performed the deletion manually, we don't need the browser to do anything else.
    // (Previously we would allow the event to propagate for the browser to delete 1 character only,
    // and we'd delete the rest manually. But this meant that if deleteBackward: was called without
    // it being a browser backspace event, 1 character would be left behind.)
    [[[self window] platformWindow] _propagateCurrentDOMEvent:NO];
#endif
}

- (void)delete:(id)sender
{
    if (!([self isEnabled] && [self isEditable]))
        return;

    // delete: only works when there's a selection (as opposed to deleteForward: and deleteBackward:).
    var selectedRange = [self selectedRange];

    if (selectedRange.length < 1)
        return;

    var newValue = [_stringValue stringByReplacingCharactersInRange:selectedRange withString:""];

    [self setStringValue:newValue];
    [self setSelectedRange:CPMakeRange(selectedRange.location, 0)];
    [self _didEdit];

#if PLATFORM(DOM)
    // Since we just performed the deletion manually, we don't need the browser to do anything else.
    [[[self window] platformWindow] _propagateCurrentDOMEvent:NO];
#endif
}

- (void)deleteForward:(id)sender
{
    if (!([self isEnabled] && [self isEditable]))
        return;

    var selectedRange = [self selectedRange];

    if (selectedRange.length < 1)
    {
        if (selectedRange.location + 1 >= _stringValue.length)
            return;

        selectedRange.length += 1;
    }

    var newValue = [_stringValue stringByReplacingCharactersInRange:selectedRange withString:""];

    [self setStringValue:newValue];
    [self setSelectedRange:CPMakeRange(selectedRange.location, 0)];
    [self _didEdit];

#if PLATFORM(DOM)
    // Since we just performed the deletion manually, we don't need the browser to do anything else.
    [[[self window] platformWindow] _propagateCurrentDOMEvent:NO];
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

    return CGRectInsetByInset(bounds, contentInset);
}

- (CGRect)bezelRectForBounds:(CGRect)bounds
{
    var bezelInset = [self currentValueForThemeAttribute:@"bezel-inset"];

    return CGRectInsetByInset(bounds, bezelInset);
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
        var view = [[CPView alloc] initWithFrame:CGRectMakeZero()];

        [view setHitTests:NO];

        return view;
    }
    else
    {
        var view = [[_CPImageAndTextView alloc] initWithFrame:CGRectMakeZero()];

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
            string = _stringValue;

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

#pragma mark Overrides

- (void)viewDidHide
{
    [super viewDidHide];

    if ([[self window] firstResponder] === self)
        [self _resignFirstKeyResponder];
}

- (void)viewDidUnhide
{
    [super viewDidUnhide];

    if ([self isEditable] && [[self window] firstResponder] === self)
        [self _becomeFirstKeyResponder];
}

- (BOOL)validateUserInterfaceItem:(id <CPValidatedUserInterfaceItem>)anItem
{
    var theAction = [anItem action];

    if (![self isEditable] && (theAction == @selector(cut:) || theAction == @selector(paste:) || theAction == @selector(delete:)))
        return NO;

    // FIXME - [self selectedRange] is always empty if we're not an editable field, so we must assume yes here.
    if (![self isEditable])
        return YES;

    if (theAction == @selector(copy:) || theAction == @selector(cut:) || theAction == @selector(delete:))
        return [self selectedRange].length;

    return YES;
}

#pragma mark Private

- (BOOL)_isWithinUsablePlatformRect
{
    // Make sure the text field is completely within the platform window
    // so the browser will not scroll it into view.

    var wind = [self window];

    // If the field is not yet within a window, it can't be first responder
    if (!wind)
        return NO;

    var frame = [self convertRectToBase:[self bounds]],
        usableRect = [[wind platformWindow] usableContentFrame];

    frame.origin = [wind convertBaseToGlobal:frame.origin];

    return (CGRectGetMinX(frame) >= CGRectGetMinX(usableRect) &&
            CGRectGetMaxX(frame) <= CGRectGetMaxX(usableRect) &&
            CGRectGetMinY(frame) >= CGRectGetMinY(usableRect) &&
            CGRectGetMaxY(frame) <= CGRectGetMaxY(usableRect));
}

@end

var secureStringForString = function(aString)
{
    // This is true for when aString === "" and null/undefined.
    if (!aString)
        return "";

    return Array(aString.length + 1).join(CPSecureTextFieldCharacter);
};


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

@implementation _CPTextFieldValueBinder : CPBinder

- (void)_updatePlaceholdersWithOptions:(CPDictionary)options forBinding:(CPBinder)aBinding
{
    [super _updatePlaceholdersWithOptions:options];

    [self _setPlaceholder:@"Multiple Values" forMarker:CPMultipleValuesMarker isDefault:YES];
    [self _setPlaceholder:@"No Selection" forMarker:CPNoSelectionMarker isDefault:YES];
    [self _setPlaceholder:@"Not Applicable" forMarker:CPNotApplicableMarker isDefault:YES];
    [self _setPlaceholder:@"" forMarker:CPNullMarker isDefault:YES];
}

- (void)setPlaceholderValue:(id)aValue withMarker:(CPString)aMarker forBinding:(CPString)aBinding
{
    [_source setPlaceholderString:aValue];
    [_source setObjectValue:nil];
}

- (void)setValue:(id)aValue forBinding:(CPString)aBinding
{
    if (!aValue || (aValue.isa && [aValue isMemberOfClass:CPNull]))
        [_source setPlaceholderString:[self _placeholderForMarker:CPNullMarker]];

    [_source setObjectValue:aValue];
}

@end

@implementation _CPTextFieldPatternValueBinder : CPValueWithPatternBinding

- (void)setPlaceholderValue:(id)aValue withMarker:(CPString)aMarker forBinding:(CPString)aBinding
{
    [_source setPlaceholderString:aValue];
    [_source setObjectValue:nil];
}

- (void)setValue:(id)aValue forBinding:(CPString)aBinding
{
    if (!aValue || (aValue.isa && [aValue isMemberOfClass:CPNull]))
        [_source setPlaceholderString:[self _placeholderForMarker:CPNullMarker]];

    [_source setObjectValue:aValue];
}

@end
