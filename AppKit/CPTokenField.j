/*
 * CPTokenField.j
 * AppKit
 *
 * Created by Klaas Pieter Annema.
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

@import <Foundation/CPCharacterSet.j>
@import <Foundation/CPIndexSet.j>
@import <Foundation/CPTimer.j>

@import "_CPAutocompleteMenu.j"
@import "CPButton.j"
@import "CPPopUpButton.j"
@import "CPScrollView.j"
@import "CPTableView.j"
@import "CPText.j"
@import "CPTextField.j"
@import "CPWindow_Constants.j"

@global CPApp
@global CPTextFieldDidFocusNotification
@global CPTextFieldDidBlurNotification

#if PLATFORM(DOM)

var CPTokenFieldDOMInputElement = nil,
    CPTokenFieldDOMPasswordInputElement = nil,
    CPTokenFieldDOMStandardInputElement = nil,
    CPTokenFieldInputOwner = nil,
    CPTokenFieldTextDidChangeValue = nil,
    CPTokenFieldInputResigning = NO,
    CPTokenFieldInputDidBlur = NO,
    CPTokenFieldInputIsActive = NO,
    CPTokenFieldCachedSelectStartFunction = nil,
    CPTokenFieldCachedDragFunction = nil,
    CPTokenFieldFocusInput = NO,

    CPTokenFieldBlurHandler = nil;

#endif

var CPScrollDestinationNone             = 0,
    CPScrollDestinationLeft             = 1,
    CPScrollDestinationRight            = 2;

CPTokenFieldDisclosureButtonType = 0;
CPTokenFieldDeleteButtonType     = 1;

@implementation CPTokenField : CPTextField
{
    CPScrollView        _tokenScrollView;
    int                 _shouldScrollTo;

    CPRange             _selectedRange;

    _CPAutocompleteMenu _autocompleteMenu;
    CGRect              _inputFrame;

    CPTimeInterval      _completionDelay;

    CPCharacterSet      _tokenizingCharacterSet @accessors(property=tokenizingCharacterSet);

    CPEvent             _mouseDownEvent;

    BOOL                _shouldNotifyTarget;

    int                 _buttonType @accessors(property=buttonType);
}

+ (CPCharacterSet)defaultTokenizingCharacterSet
{
    return [CPCharacterSet characterSetWithCharactersInString:@","];
}

+ (CPTimeInterval)defaultCompletionDelay
{
    return 0.5;
}

+ (CPString)defaultThemeClass
{
    return "tokenfield";
}

+ (CPDictionary)themeAttributes
{
    return @{ @"editor-inset": CGInsetMakeZero() };
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _completionDelay = [[self class] defaultCompletionDelay];
        _tokenizingCharacterSet = [[self class] defaultTokenizingCharacterSet];
        _buttonType = CPTokenFieldDisclosureButtonType;
        [self setBezeled:YES];

        [self _init];

        [self setObjectValue:[]];

        [self setNeedsLayout];
    }

    return self;
}

- (void)_init
{
    _selectedRange = CPMakeRange(0, 0);

    var frame = [self frame];

    _tokenScrollView = [[CPScrollView alloc] initWithFrame:CGRectMakeZero()];
    [_tokenScrollView setHasHorizontalScroller:NO];
    [_tokenScrollView setHasVerticalScroller:NO];
    [_tokenScrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    var contentView = [[CPView alloc] initWithFrame:CGRectMakeZero()];
    [contentView setAutoresizingMask:CPViewWidthSizable];
    [_tokenScrollView setDocumentView:contentView];

    [self addSubview:_tokenScrollView];
}

- (_CPAutocompleteMenu)_autocompleteMenu
{
    if (!_autocompleteMenu)
        _autocompleteMenu = [[_CPAutocompleteMenu alloc] initWithTextField:self];
    return _autocompleteMenu;
}

- (void)_complete:(_CPAutocompleteMenu)anAutocompleteMenu
{
    [self _autocompleteWithEvent:nil];
}

- (void)_autocompleteWithEvent:(CPEvent)anEvent
{
    if (![self _editorValue] && (![_autocompleteMenu contentArray] || ![self hasThemeState:CPThemeStateAutocompleting]))
        return;

    [self _hideCompletions];

    var token = [_autocompleteMenu selectedItem],
        shouldRemoveLastObject = token !== @"" && [self _editorValue] !== @"";

    if (!token)
        token = [self _editorValue];

    // Make sure the user typed an actual token to prevent the previous token from being emptied
    // If the input area is empty, we want to fall back to the normal behavior, resigning first
    // responder or selecting the next or previous key view.
    if (!token || token === @"")
    {
        var character = [anEvent charactersIgnoringModifiers],
            modifierFlags = [anEvent modifierFlags];

        if (character === CPTabCharacter)
        {
            if (!(modifierFlags & CPShiftKeyMask))
                [[self window] selectNextKeyView:self];
            else
                [[self window] selectPreviousKeyView:self];
        }
        else
            [[self window] makeFirstResponder:nil];
        return;
    }

    var objectValue = [self objectValue];

    // Remove the uncompleted token and add the token string.
    // Explicitly remove the last object because the array contains strings and removeObject uses isEqual to compare objects
    if (shouldRemoveLastObject)
        [objectValue removeObjectAtIndex:_selectedRange.location];

    // Convert typed text into a represented object.
    token = [self _representedObjectForEditingString:token];

    // Give the delegate a chance to confirm, replace or add to the list of tokens being added.
    var delegateApprovedObjects = [self _shouldAddObjects:[CPArray arrayWithObject:token] atIndex:_selectedRange.location],
        delegateApprovedObjectsCount = [delegateApprovedObjects count];

    if (delegateApprovedObjects)
    {
        for (var i = 0; i < delegateApprovedObjectsCount; i++)
        {
            [objectValue insertObject:[delegateApprovedObjects objectAtIndex:i] atIndex:_selectedRange.location + i];
        }
    }

    // Put the cursor after the last inserted token.
    var location = _selectedRange.location;

    [self setObjectValue:objectValue];

    if (delegateApprovedObjectsCount)
        location += delegateApprovedObjectsCount;
    _selectedRange = CPMakeRange(location, 0);

    [self _inputElement].value = @"";
    [self setNeedsLayout];

    [self _controlTextDidChange];
}

- (void)_autocomplete
{
    [self _autocompleteWithEvent:nil];
}

- (void)_selectToken:(_CPTokenFieldToken)token byExtendingSelection:(BOOL)extend
{
    var indexOfToken = [[self _tokens] indexOfObject:token];

    if (indexOfToken == CPNotFound)
    {
        if (!extend)
            _selectedRange = CPMakeRange([[self _tokens] count], 0);
    }
    else if (extend)
        _selectedRange = CPUnionRange(_selectedRange, CPMakeRange(indexOfToken, 1));
    else
        _selectedRange = CPMakeRange(indexOfToken, 1);

    [self setNeedsLayout];
}

- (void)_deselectToken:(_CPTokenFieldToken)token
{
    var indexOfToken = [[self _tokens] indexOfObject:token];

    if (CPLocationInRange(indexOfToken, _selectedRange))
        _selectedRange = CPMakeRange(MAX(indexOfToken, _selectedRange.location), MIN(_selectedRange.length, indexOfToken - _selectedRange.location));

    [self setNeedsLayout];
}

- (void)_deleteToken:(_CPTokenFieldToken)token
{
    var indexOfToken = [[self _tokens] indexOfObject:token],
        objectValue = [self objectValue];

    // If the selection was to the right of the deleted token, move it to the left. If the deleted token was
    // selected, deselect it.
    if (indexOfToken < _selectedRange.location)
        _selectedRange.location--;
    else
        [self _deselectToken:token];

    // Preserve selection.
    var selection = CPMakeRangeCopy(_selectedRange);

    [objectValue removeObjectAtIndex:indexOfToken];
    [self setObjectValue:objectValue];
    _selectedRange = selection;

    [self setNeedsLayout];
    [self _controlTextDidChange];
}

- (void)_controlTextDidChange
{
    var binderClass = [[self class] _binderClassForBinding:CPValueBinding],
        theBinding = [binderClass getBinding:CPValueBinding forObject:self];

    if (theBinding)
        [theBinding reverseSetValueFor:@"objectValue"];

    [self textDidChange:[CPNotification notificationWithName:CPControlTextDidChangeNotification object:self userInfo:nil]];

    _shouldNotifyTarget = YES;
}

- (void)_removeSelectedTokens:(id)sender
{
    var tokens = [self objectValue];

    for (var i = _selectedRange.length - 1; i >= 0; i--)
        [tokens removeObjectAtIndex:_selectedRange.location + i];

    var collapsedSelection = _selectedRange.location;

    [self setObjectValue:tokens];
    // setObjectValue moves the cursor to the end of the selection. We want it to stay
    // where the selected tokens were.
    _selectedRange = CPMakeRange(collapsedSelection, 0);

    [self _controlTextDidChange];
}

- (void)_updatePlaceholderState
{
    if (([[self _tokens] count] === 0) && ![self hasThemeState:CPThemeStateEditing])
        [self setThemeState:CPTextFieldStatePlaceholder];
    else
        [self unsetThemeState:CPTextFieldStatePlaceholder];
}

// =============
// = RESPONDER =
// =============

- (BOOL)becomeFirstResponder
{
#if PLATFORM(DOM)
    if (CPTokenFieldInputOwner && [CPTokenFieldInputOwner window] !== [self window])
        [[CPTokenFieldInputOwner window] makeFirstResponder:nil];
#endif

    // As long as we are the first responder we need to monitor the key status of our window.
    [self _setObserveWindowKeyNotifications:YES];

    [self scrollRectToVisible:[self bounds]];

    if ([[self window] isKeyWindow])
        return [self _becomeFirstKeyResponder];

    return YES;
}

- (BOOL)_becomeFirstKeyResponder
{
    // If the token field is still not completely on screen, refuse to become
    // first responder, because the browser will scroll it into view out of our control.
    if (![self _isWithinUsablePlatformRect])
        return NO;

    [self setThemeState:CPThemeStateEditing];

    [self _updatePlaceholderState];

    [self setNeedsLayout];

#if PLATFORM(DOM)

    var string = [self stringValue],
        element = [self _inputElement],
        font = [self currentValueForThemeAttribute:@"font"];

    element.value = nil;
    element.style.color = [[self currentValueForThemeAttribute:@"text-color"] cssString];
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

    var contentRect = [self contentRectForBounds:[self bounds]];

    element.style.top = CGRectGetMinY(contentRect) + "px";
    element.style.left = (CGRectGetMinX(contentRect) - 1) + "px"; // <input> element effectively imposes a 1px left margin
    element.style.width = CGRectGetWidth(contentRect) + "px";
    element.style.height = [font defaultLineHeightForFont] + "px";

    window.setTimeout(function()
    {
        [_tokenScrollView documentView]._DOMElement.appendChild(element);

        //post CPControlTextDidBeginEditingNotification
        [self textDidBeginEditing:[CPNotification notificationWithName:CPControlTextDidBeginEditingNotification object:self userInfo:nil]];

        window.setTimeout(function()
        {
            element.focus();
            CPTokenFieldInputOwner = self;
        }, 0.0);

        [self textDidFocus:[CPNotification notificationWithName:CPTextFieldDidFocusNotification object:self userInfo:nil]];
    }, 0.0);

    [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];

    CPTokenFieldInputIsActive = YES;

    if (document.attachEvent)
    {
        CPTokenFieldCachedSelectStartFunction = document.body.onselectstart;
        CPTokenFieldCachedDragFunction = document.body.ondrag;

        document.body.ondrag = function () {};
        document.body.onselectstart = function () {};
    }

#endif

    return YES;
}

- (BOOL)resignFirstResponder
{
    [self _autocomplete];

    // From CPTextField superclass.
    [self _setObserveWindowKeyNotifications:NO];

    [self _resignFirstKeyResponder];

    if (_shouldNotifyTarget)
    {
        _shouldNotifyTarget = NO;
        [self textDidEndEditing:[CPNotification notificationWithName:CPControlTextDidEndEditingNotification object:self userInfo:@{"CPTextMovement": [self _currentTextMovement]}]];

        if ([self sendsActionOnEndEditing])
            [self sendAction:[self action] to:[self target]];
    }

    [self textDidBlur:[CPNotification notificationWithName:CPTextFieldDidBlurNotification object:self userInfo:nil]];

    return YES;
}

- (void)_resignFirstKeyResponder
{
    [self unsetThemeState:CPThemeStateEditing];

    [self _updatePlaceholderState];
    [self setNeedsLayout];

#if PLATFORM(DOM)

    var element = [self _inputElement];

    CPTokenFieldInputResigning = YES;
    element.blur();

    if (!CPTokenFieldInputDidBlur)
        CPTokenFieldBlurHandler();

    CPTokenFieldInputDidBlur = NO;
    CPTokenFieldInputResigning = NO;

    if (element.parentNode == [_tokenScrollView documentView]._DOMElement)
        element.parentNode.removeChild(element);

    CPTokenFieldInputIsActive = NO;

    if (document.attachEvent)
    {
        CPTokenFieldCachedSelectStartFunction = nil;
        CPTokenFieldCachedDragFunction = nil;

        document.body.ondrag = CPTokenFieldCachedDragFunction
        document.body.onselectstart = CPTokenFieldCachedSelectStartFunction
    }

#endif
}

- (void)mouseDown:(CPEvent)anEvent
{
    _mouseDownEvent = anEvent;

    [self _selectToken:nil byExtendingSelection:NO];

    [super mouseDown:anEvent];
}

- (void)mouseUp:(CPEvent)anEvent
{
    _mouseDownEvent = nil;
}

- (void)_mouseDownOnToken:(_CPTokenFieldToken)aToken withEvent:(CPEvent)anEvent
{
    _mouseDownEvent = anEvent;
}

- (void)_mouseUpOnToken:(_CPTokenFieldToken)aToken withEvent:(CPEvent)anEvent
{
    if (_mouseDownEvent && CGPointEqualToPoint([_mouseDownEvent locationInWindow], [anEvent locationInWindow]))
    {
        [self _selectToken:aToken byExtendingSelection:[anEvent modifierFlags] & CPShiftKeyMask];
        [[self window] makeFirstResponder:self];
        // Snap to the token if it's only half visible due to mouse wheel scrolling.
        _shouldScrollTo = aToken;
    }
}

// ===========
// = CONTROL =
// ===========
- (CPArray)_tokens
{
    // We return super here because objectValue uses this method
    // If we called self we would loop infinitely
    return [super objectValue];
}

- (CPString)stringValue
{
    return [[self objectValue] componentsJoinedByString:@","];
}

- (id)objectValue
{
    var objectValue = [];

    for (var i = 0, count = [[self _tokens] count]; i < count; i++)
    {
        var token = [[self _tokens] objectAtIndex:i];

        if ([token isKindOfClass:[CPString class]])
            continue;

        [objectValue addObject:[token representedObject]];
    }

#if PLATFORM(DOM)

    if ([self _editorValue])
    {
        var token = [self _representedObjectForEditingString:[self _editorValue]];
        [objectValue insertObject:token atIndex:_selectedRange.location];
    }

#endif

    return objectValue;
}

- (void)setObjectValue:(id)aValue
{
    if (aValue !== nil && ![aValue isKindOfClass:[CPArray class]])
    {
        [super setObjectValue:nil];
        return;
    }

    var superValue = [super objectValue];
    if (aValue === superValue || [aValue isEqualToArray:superValue])
        return;

    var contentView = [_tokenScrollView documentView],
        oldTokens = [self _tokens],
        newTokens = [];

    // Preserve as many existing tokens as possible to reduce redraw flickering.
    if (aValue !== nil)
    {
        for (var i = 0, count = [aValue count]; i < count; i++)
        {
            // Do we have this token among the old ones?
            var tokenObject = aValue[i],
                tokenValue = [self _displayStringForRepresentedObject:tokenObject],
                newToken = nil;

            for (var j = 0, oldCount = [oldTokens count]; j < oldCount; j++)
            {
                var oldToken = oldTokens[j];
                if ([oldToken representedObject] == tokenObject)
                {
                    // Yep. Reuse it.
                    [oldTokens removeObjectAtIndex:j];
                    newToken = oldToken;
                    break;
                }
            }

            if (newToken === nil)
            {
                newToken = [_CPTokenFieldToken new];
                [newToken setTokenField:self];
                [newToken setRepresentedObject:tokenObject];
                [newToken setStringValue:tokenValue];
                [newToken setEditable:[self isEditable]];
                [contentView addSubview:newToken];
            }

            newTokens.push(newToken);
        }
    }

    // Remove any now unused tokens.
    for (var j = 0, oldCount = [oldTokens count]; j < oldCount; j++)
        [oldTokens[j] removeFromSuperview];

    /*
    [CPTextField setObjectValue] will try to set the _inputElement.value to
    the new objectValue, if the _inputElement exists. This is wrong for us
    since our objectValue is an array of tokens, so we can't use
    [super setObjectValue:objectValue];

    Instead do what CPControl setObjectValue would.
    */
    _value = newTokens;

    // Reset the selection.
    [self _selectToken:nil byExtendingSelection:NO];

    [self _updatePlaceholderState];

    _shouldScrollTo = CPScrollDestinationRight;
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (void)setEnabled:(BOOL)shouldBeEnabled
{
    [super setEnabled:shouldBeEnabled];

    // Set the enabled state of the tokens
    for (var i = 0, count = [[self _tokens] count]; i < count; i++)
    {
        var token = [[self _tokens] objectAtIndex:i];

        if ([token respondsToSelector:@selector(setEnabled:)])
            [token setEnabled:shouldBeEnabled];
    }
}

- (void)setEditable:(BOOL)shouldBeEditable
{
    [super setEditable:shouldBeEditable];

    [[self _tokens] makeObjectsPerformSelector:@selector(setEditable:) withObject:shouldBeEditable];
}

- (BOOL)sendAction:(SEL)anAction to:(id)anObject
{
    _shouldNotifyTarget = NO;
    [super sendAction:anAction to:anObject];
}

// Incredible hack to disable supers implementation
// so it cannot change our object value and break the tokenfield
- (BOOL)_setStringValue:(CPString)aValue
{
}

// =============
// = TEXTFIELD =
// =============
#if PLATFORM(DOM)
- (DOMElement)_inputElement
{
    if (!CPTokenFieldDOMInputElement)
    {
        CPTokenFieldDOMInputElement = document.createElement("input");
        CPTokenFieldDOMInputElement.style.position = "absolute";
        CPTokenFieldDOMInputElement.style.border = "0px";
        CPTokenFieldDOMInputElement.style.padding = "0px";
        CPTokenFieldDOMInputElement.style.margin = "0px";
        CPTokenFieldDOMInputElement.style.whiteSpace = "pre";
        CPTokenFieldDOMInputElement.style.background = "transparent";
        CPTokenFieldDOMInputElement.style.outline = "none";

        CPTokenFieldBlurHandler = function(anEvent)
        {
            return CPTextFieldBlurFunction(
                        anEvent,
                        CPTokenFieldInputOwner,
                        CPTokenFieldInputOwner ? [CPTokenFieldInputOwner._tokenScrollView documentView]._DOMElement : nil,
                        CPTokenFieldDOMInputElement,
                        CPTokenFieldInputResigning,
                        @ref(CPTokenFieldInputDidBlur));
        };

        // FIXME make this not onblur
        CPTokenFieldDOMInputElement.onblur = CPTokenFieldBlurHandler;

        CPTokenFieldDOMStandardInputElement = CPTokenFieldDOMInputElement;
    }

    if (CPFeatureIsCompatible(CPInputTypeCanBeChangedFeature))
    {
        if ([CPTokenFieldInputOwner isSecure])
            CPTokenFieldDOMInputElement.type = "password";
        else
            CPTokenFieldDOMInputElement.type = "text";

        return CPTokenFieldDOMInputElement;
    }

    return CPTokenFieldDOMInputElement;
}
#endif

- (CPString)_editorValue
{
    if (![self hasThemeState:CPThemeStateEditing])
        return @"";
    return [self _inputElement].value;
}

- (void)moveUp:(id)sender
{
    [[self _autocompleteMenu] selectPrevious];
    [[[self window] platformWindow] _propagateCurrentDOMEvent:NO];
}

- (void)moveDown:(id)sender
{
    [[self _autocompleteMenu] selectNext];
    [[[self window] platformWindow] _propagateCurrentDOMEvent:NO];
}

- (void)insertNewline:(id)sender
{
    if ([self hasThemeState:CPThemeStateAutocompleting])
    {
        [self _autocompleteWithEvent:[CPApp currentEvent]];
    }
    else
    {
        [self sendAction:[self action] to:[self target]];
        [[self window] makeFirstResponder:nil];
    }
}

- (void)insertTab:(id)sender
{
    var anEvent = [CPApp currentEvent];
    if ([self hasThemeState:CPThemeStateAutocompleting])
    {
        [self _autocompleteWithEvent:anEvent];
    }
    else
    {
        // Default to standard tabbing behaviour.
        if (!([anEvent modifierFlags] & CPShiftKeyMask))
            [[self window] selectNextKeyView:self];
        else
            [[self window] selectPreviousKeyView:self];
    }
}

- (void)insertText:(CPString)characters
{
    // Note that in Cocoa NStokenField uses a hidden input field not accessible to the user,
    // so insertText: is called on that field instead. That seems rather silly since it makes
    // it pretty much impossible to override insertText:. This version is better.
    if ([_tokenizingCharacterSet characterIsMember:[characters substringToIndex:1]])
    {
        [self _autocompleteWithEvent:[CPApp currentEvent]];
    }
    else
    {
        // If you type something while tokens are selected, overwrite them.
        if (_selectedRange.length)
        {
            [self _removeSelectedTokens:self];
            // Make sure the editor is placed so it can capture the characters we're overwriting with.
            [self layoutSubviews];
        }

        // If we didn't handle it, allow _propagateCurrentDOMEvent the input field to receive
        // the new character.

        // This method also allows a subclass to override insertText: to do nothing.
        // Unfortunately calling super with some different characters won't work since
        // the browser will see the original key event.
        [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
    }
}

- (void)cancelOperation:(id)sender
{
    [self _hideCompletions];
}

- (void)moveLeft:(id)sender
{
    // Left arrow
    if ((_selectedRange.location > 0 || _selectedRange.length) && [self _editorValue] == "")
    {
        if (_selectedRange.length)
            // Simply collapse the range.
            _selectedRange.length = 0;
        else
            _selectedRange.location--;
        [self setNeedsLayout];
        _shouldScrollTo = CPScrollDestinationLeft;
    }
    else
    {
        // Allow cursor movement within the text field.
        [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
    }
}

- (void)moveLeftAndModifySelection:(id)sender
{
    if (_selectedRange.location > 0 && [self _editorValue] == "")
    {
        _selectedRange.location--;
        // When shift is depressed, select the next token backwards.
        _selectedRange.length++;
        [self setNeedsLayout];
        _shouldScrollTo = CPScrollDestinationLeft;
    }
    else
    {
        // Allow cursor movement within the text field.
        [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
    }
}

- (void)moveRight:(id)sender
{
    // Right arrow
    if ((_selectedRange.location < [[self _tokens] count] || _selectedRange.length) && [self _editorValue] == "")
    {
        if (_selectedRange.length)
        {
            // Place the cursor at the end of the selection and collapse.
            _selectedRange.location = CPMaxRange(_selectedRange);
            _selectedRange.length = 0;
        }
        else
        {
            // Move the cursor forward one token if the input is empty and the right arrow key is pressed.
            _selectedRange.location = MIN([[self _tokens] count], _selectedRange.location + _selectedRange.length + 1);
        }

        [self setNeedsLayout];
        _shouldScrollTo = CPScrollDestinationRight;
    }
    else
    {
        // Allow cursor movement within the text field.
        [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
    }
}

- (void)moveRightAndModifySelection:(id)sender
{
    if (CPMaxRange(_selectedRange) < [[self _tokens] count] && [self _editorValue] == "")
    {
        // Leave the selection location in place but include the next token to the right.
        _selectedRange.length++;
        [self setNeedsLayout];
        _shouldScrollTo = CPScrollDestinationRight;
    }
    else
    {
        // Allow selection to happen within the text field.
        [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
    }
}

- (void)deleteBackward:(id)sender
{
    // TODO Even if the editor isn't empty you should be able to delete the previous token by placing the cursor
    // at the beginning of the editor.
    if ([self _editorValue] == @"")
    {
        [self _hideCompletions];

        if (CPEmptyRange(_selectedRange))
        {
            if (_selectedRange.location > 0)
            {
                var tokenView = [[self _tokens] objectAtIndex:(_selectedRange.location - 1)];
                [self _selectToken:tokenView byExtendingSelection:NO];
            }
        }
        else
            [self _removeSelectedTokens:nil];
    }
    else
    {
        // Allow deletion to happen within the text field.
        [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
    }
}

- (void)deleteForward:(id)sender
{
    // TODO Even if the editor isn't empty you should be able to delete the next token by placing the cursor
    // at the end of the editor.
    if ([self _editorValue] == @"")
    {
        // Delete forward if nothing is selected, else delete all selected.
        [self _hideCompletions];

        if (CPEmptyRange(_selectedRange))
        {
            if (_selectedRange.location < [[self _tokens] count])
                [self _deleteToken:[[self _tokens] objectAtIndex:[_selectedRange.location]]];
        }
        else
            [self _removeSelectedTokens:nil];
    }
    else
    {
        // Allow deletion to happen within the text field.
        [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
    }
}

- (void)_selectText:(id)sender immediately:(BOOL)immediately
{
    // Override CPTextField's version. The correct behaviour is that the text currently being
    // edited is turned into a token if possible, or left as plain selected text if not.
    // Regardless of if there is on-going text entry, all existing tokens are also selected.
    // At this point we don't support having tokens and text selected at the same time (or
    // any situation where the cursor isn't within the text being edited) so we just finish
    // editing and select all tokens.

    if (([self isEditable] || [self isSelectable]))
    {
        [super _selectText:sender immediately:immediately];

        // Finish any editing.
        [self _autocomplete];
        _selectedRange = CPMakeRange(0, [[self _tokens] count]);

        [self setNeedsLayout];
    }
}

- (void)keyDown:(CPEvent)anEvent
{
#if PLATFORM(DOM)
    CPTokenFieldTextDidChangeValue = [self stringValue];
#endif

    // Leave the default _propagateCurrentDOMEvent setting in place. This might be YES or NO depending
    // on if something that could be a browser shortcut was pressed or not, such as Cmd-R to reload.
    // If it was NO we want to leave it at NO however and only enable it in insertText:. This is what
    // allows a subclass to prevent characters from being inserted by overriding and not calling super.

    [self interpretKeyEvents:[anEvent]];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

- (void)keyUp:(CPEvent)anEvent
{
#if PLATFORM(DOM)
    if ([self stringValue] !== CPTokenFieldTextDidChangeValue)
    {
        [self textDidChange:[CPNotification notificationWithName:CPControlTextDidChangeNotification object:self userInfo:nil]];
    }
#endif

    [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
}

- (void)textDidChange:(CPNotification)aNotification
{
    if ([aNotification object] !== self)
        return;

    [super textDidChange:aNotification];

    // For future reference: in Cocoa, textDidChange: appears to call [self complete:].
    [self _delayedShowCompletions];
    // If there was a selection, collapse it now since we're typing in a new token.
    _selectedRange.length = 0;

    // Force immediate layout in case word wrapping is now necessary.
    [self setNeedsLayout];
}

// - (void)setTokenStyle: (NSTokenStyle) style;
// - (NSTokenStyle)tokenStyle;
//

// ====================
// = COMPLETION DELAY =
// ====================
- (void)setCompletionDelay:(CPTimeInterval)delay
{
    _completionDelay = delay;
}

- (CPTimeInterval)completionDelay
{
    return _completionDelay;
}

// ==========
// = LAYOUT =
// ==========
- (void)layoutSubviews
{
    [super layoutSubviews];

    [_tokenScrollView setFrame:[self rectForEphemeralSubviewNamed:"content-view"]];

    var textFieldContentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                                      positioned:CPWindowAbove
                                 relativeToEphemeralSubviewNamed:@"bezel-view"];

    if (textFieldContentView)
        [textFieldContentView setHidden:[self stringValue] !== @""];

    var frame = [self frame],
        contentView = [_tokenScrollView documentView],
        tokens = [self _tokens];

    // Hack to make sure we are handling an array
    if (![tokens isKindOfClass:[CPArray class]])
        return;

    // Move each token into the right position.
    var contentRect = CGRectMakeCopy([contentView bounds]),
        contentOrigin = contentRect.origin,
        contentSize = contentRect.size,
        offset = CGPointMake(contentOrigin.x, contentOrigin.y),
        spaceBetweenTokens = CGSizeMake(2.0, 2.0),
        isEditing = [[self window] firstResponder] == self,
        tokenToken = [_CPTokenFieldToken new],
        font = [self currentValueForThemeAttribute:@"font"],
        lineHeight = [font defaultLineHeightForFont],
        editorInset = [self currentValueForThemeAttribute:@"editor-inset"];

    // Put half a spacing above the tokens.
    offset.y += CEIL(spaceBetweenTokens.height / 2.0);

    // Get the height of a typical token, or a token token if you will.
    [tokenToken sizeToFit];

    var tokenHeight = CGRectGetHeight([tokenToken bounds]);

    var fitAndFrame = function(width, height)
    {
        var r = CGRectMake(0, 0, width, height);

        if (offset.x + width >= contentSize.width && offset.x > contentOrigin.x)
        {
            offset.x = contentOrigin.x;
            offset.y += height + spaceBetweenTokens.height;
        }

        r.origin.x = offset.x;
        r.origin.y = offset.y;

        // Make sure the frame fits.
        var scrollHeight = offset.y + tokenHeight + CEIL(spaceBetweenTokens.height / 2.0);
        if (CGRectGetHeight([contentView bounds]) < scrollHeight)
            [contentView setFrameSize:CGSizeMake(CGRectGetWidth([_tokenScrollView bounds]), scrollHeight)];

        offset.x += width + spaceBetweenTokens.width;

        return r;
    };

    var placeEditor = function(useRemainingWidth)
    {
        var element = [self _inputElement],
            textWidth = 1;

        if (_selectedRange.length === 0)
        {
            // XXX The "X" here is used to estimate the space needed to fit the next character
            // without clipping. Since different fonts might have different sizes of "X" this
            // solution is not ideal, but it works.
            textWidth = [(element.value || @"") + "X" sizeWithFont:font].width;

            if (useRemainingWidth)
                textWidth = MAX(contentSize.width - offset.x - 1, textWidth);
        }

        _inputFrame = fitAndFrame(textWidth, tokenHeight);

        _inputFrame.size.height = lineHeight;

        element.style.left = (_inputFrame.origin.x + editorInset.left) + "px";
        element.style.top = (_inputFrame.origin.y + editorInset.top) + "px";
        element.style.width = _inputFrame.size.width + "px";
        element.style.height = _inputFrame.size.height + "px";

        // When editing, always scroll to the cursor.
        if (_selectedRange.length == 0)
            [[_tokenScrollView documentView] scrollPoint:CGPointMake(0, _inputFrame.origin.y)];
    };

    for (var i = 0, count = [tokens count]; i < count; i++)
    {
        if (isEditing && !_selectedRange.length && i == CPMaxRange(_selectedRange))
            placeEditor(false);

        var tokenView = [tokens objectAtIndex:i];

        // Make sure we are only changing completed tokens
        if ([tokenView isKindOfClass:[CPString class]])
            continue;

        [tokenView setHighlighted:CPLocationInRange(i, _selectedRange)];
        [tokenView sizeToFit];

        var size = [contentView bounds].size,
            tokenViewSize = [tokenView bounds].size,
            tokenFrame = fitAndFrame(tokenViewSize.width, tokenViewSize.height);

        [tokenView setFrame:tokenFrame];

        [tokenView setButtonType:_buttonType];
    }

    if (isEditing && !_selectedRange.length && CPMaxRange(_selectedRange) >= [tokens count])
        placeEditor(true);

    // Hide the editor if there are selected tokens, but still keep it active
    // so we can continue using our standard keyboard handling events.
    if (isEditing && _selectedRange.length)
    {
        _inputFrame = nil;
        var inputElement = [self _inputElement];
        inputElement.style.display = "none";
    }
    else if (isEditing)
    {
        var inputElement = [self _inputElement];
        inputElement.style.display = "block";
        if (document.activeElement !== inputElement)
            inputElement.focus();
    }

    // Trim off any excess height downwards (in case we shrank).
    var scrollHeight = offset.y + tokenHeight;
    if (CGRectGetHeight([contentView bounds]) > scrollHeight)
        [contentView setFrameSize:CGSizeMake(CGRectGetWidth([_tokenScrollView bounds]), scrollHeight)];

    if (_shouldScrollTo !== CPScrollDestinationNone)
    {
        // Only carry out the scroll if the cursor isn't visible.
        if (!(isEditing && _selectedRange.length == 0))
        {
            var scrollToToken = _shouldScrollTo;

            if (scrollToToken === CPScrollDestinationLeft)
                scrollToToken = tokens[_selectedRange.location]
            else if (scrollToToken === CPScrollDestinationRight)
                scrollToToken = tokens[MAX(0, CPMaxRange(_selectedRange) - 1)];
            [self _scrollTokenViewToVisible:scrollToToken];
        }

        _shouldScrollTo = CPScrollDestinationNone;
    }
}

- (BOOL)_scrollTokenViewToVisible:(_CPTokenFieldToken)aToken
{
    if (!aToken)
        return;

    return [[_tokenScrollView documentView] scrollPoint:CGPointMake(0, [aToken frameOrigin].y)];
}

@end

@implementation CPTokenField (CPTokenFieldDelegate)

/*!
    Private API to get the delegate tokenField:completionsForSubstring:indexOfToken:indexOfSelectedItem: result.

    The delegate method should return an array of strings matching the provided substring for autocompletion.
    tokenIndex is the index of the token being completed. selectedIndex allows the selected autocompletion option
    to be indicated by reference.

    @ignore
*/
- (CPArray)_completionsForSubstring:(CPString)substring indexOfToken:(int)tokenIndex indexOfSelectedItem:(int)selectedIndex
{
    if ([[self delegate] respondsToSelector:@selector(tokenField:completionsForSubstring:indexOfToken:indexOfSelectedItem:)])
    {
        return [[self delegate] tokenField:self completionsForSubstring:substring indexOfToken:tokenIndex indexOfSelectedItem:selectedIndex];
    }

    return [];
}

/*!
    Private API used by the _CPAutocompleteMenu to determine where to place the menu in local coordinates.
*/
- (CGPoint)_completionOrigin:(_CPAutocompleteMenu)anAutocompleteMenu
{
    var relativeFrame = _inputFrame ? [[_tokenScrollView documentView] convertRect:_inputFrame toView:self ] : [self bounds];
    return CGPointMake(CGRectGetMinX(relativeFrame), CGRectGetMaxY(relativeFrame));
}

/*!
    Private API to get the delegate tokenField:displayStringForRepresentedObject: result.

    The delegate method should return a string to be displayed for the given represtented object.
    If this delegate method is not implemented, the representedObject is displayed as a string.

    @ignore
*/
- (CPString)_displayStringForRepresentedObject:(id)representedObject
{
    if ([[self delegate] respondsToSelector:@selector(tokenField:displayStringForRepresentedObject:)])
    {
        var stringForRepresentedObject = [[self delegate] tokenField:self displayStringForRepresentedObject:representedObject];
        if (stringForRepresentedObject !== nil)
        {
            return stringForRepresentedObject;
        }
    }

    return representedObject;
}

/*!
    Private API to get the delegate tokenField:shouldAddObjects:atIndex: result.

    The delegate should return an array of represented objects which should be added based on the
    suggested tokens to add and the insertion position specified by index. To add no tokens,
    return an empty array. Returning nil is an error.

    @ignore
*/
- (CPArray)_shouldAddObjects:(CPArray)tokens atIndex:(int)index
{
    var  delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(tokenField:shouldAddObjects:atIndex:)])
    {
        var approvedObjects = [delegate tokenField:self shouldAddObjects:tokens atIndex:index];
        if (approvedObjects !== nil)
            return approvedObjects;
    }

    return tokens;
}

/*!
    Private API to get the delegate tokenField:representedObjectForEditingString: result.

    The delegate method should return a represented object for the provided string which
    may have been typed by the user or selected from the completion menu. If the method is
    not implemented, or returns nil, the string is assumed to be the represented object.

    @ignore
*/
- (id)_representedObjectForEditingString:(CPString)aString
{
    var delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(tokenField:representedObjectForEditingString:)])
    {
        var token = [delegate tokenField:self representedObjectForEditingString:aString];
        if (token !== nil && token !== undefined)
            return token;
        // If nil was returned, assume the string is the represented object. The alternative would have been
        // to not add anything to the object value array for a nil response.
    }

    return aString;
}

- (BOOL)_hasMenuForRepresentedObject:(id)aRepresentedObject
{
    var delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(tokenField:hasMenuForRepresentedObject:)] &&
        [delegate respondsToSelector:@selector(tokenField:menuForRepresentedObject:)])
        return [delegate tokenField:self hasMenuForRepresentedObject:aRepresentedObject];

    return NO;
}

- (CPMenu)_menuForRepresentedObject:(id)aRepresentedObject
{
    var delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(tokenField:hasMenuForRepresentedObject:)] &&
        [delegate respondsToSelector:@selector(tokenField:menuForRepresentedObject:)])
    {
        var hasMenu = [delegate tokenField:self hasMenuForRepresentedObject:aRepresentedObject];
        if (hasMenu)
            return [delegate tokenField:self menuForRepresentedObject:aRepresentedObject] || nil;
    }

    return nil;
}

// We put the string on the pasteboard before calling this delegate method.
// By default, we write the NSStringPboardType as well as an array of NSStrings.
// - (BOOL)tokenField:(NSTokenField *)tokenField writeRepresentedObjects:(NSArray *)objects toPasteboard:(NSPasteboard *)pboard;
//
// Return an array of represented objects to add to the token field.
// - (NSArray *)tokenField:(NSTokenField *)tokenField readFromPasteboard:(NSPasteboard *)pboard;
//
// By default the tokens have no menu.
// - (NSMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)representedObject;
// - (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject;
//
// This method allows you to change the style for individual tokens as well as have mixed text and tokens.
// - (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject;

- (void)_delayedShowCompletions
{
    [[self _autocompleteMenu] _delayedShowCompletions];
}

- (void)_hideCompletions
{
    [_autocompleteMenu _hideCompletions];
}


- (void)setButtonType:(int)aButtonType
{
    if (_buttonType === aButtonType)
        return;

    _buttonType = aButtonType;
    [self setNeedsLayout];
}

@end

@implementation _CPTokenFieldToken : CPTextField
{
    _CPTokenFieldTokenCloseButton       _deleteButton;
    _CPTokenFieldTokenDisclosureButton  _disclosureButton;
    CPTokenField                        _tokenField;
    id                                  _representedObject;
    int                                 _buttonType;
}

+ (CPString)defaultThemeClass
{
    return "tokenfield-token";
}

- (BOOL)acceptsFirstResponder
{
    return NO;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setEditable:NO];
        [self setHighlighted:NO];
        [self setBezeled:YES];
        [self setButtonType:CPTokenFieldDisclosureButtonType];
    }

    return self;
}

- (CPTokenField)tokenField
{
    return _tokenField;
}

- (void)setTokenField:(CPTokenField)tokenField
{
    _tokenField = tokenField;
}

- (id)representedObject
{
    return _representedObject;
}

- (void)setRepresentedObject:(id)representedObject
{
    _representedObject = representedObject;
    [self setNeedsLayout];
}

- (void)setEditable:(BOOL)shouldBeEditable
{
    [super setEditable:shouldBeEditable];
    [self setNeedsLayout];
}

- (BOOL)setThemeState:(CPThemeState)aState
{
    var r = [super setThemeState:aState];

    // Share hover state with the disclosure and delete buttons.
    if (aState.hasThemeState(CPThemeStateHovered))
    {
        [_disclosureButton setThemeState:CPThemeStateHovered];
        [_deleteButton setThemeState:CPThemeStateHovered];
    }

    return r;
}

- (BOOL)unsetThemeState:(CPThemeState)aState
{
    var r = [super unsetThemeState:aState];

    // Share hover state with the disclosure and delete button.
    if (aState.hasThemeState(CPThemeStateHovered))
    {
        [_disclosureButton unsetThemeState:CPThemeStateHovered];
        [_deleteButton unsetThemeState:CPThemeStateHovered];
    }

    return r;
}

- (CGSize)_minimumFrameSize
{
    var size = CGSizeMakeZero(),
        minSize = [self currentValueForThemeAttribute:@"min-size"],
        contentInset = [self currentValueForThemeAttribute:@"content-inset"];

    // Tokens are fixed height, so we could as well have used max-size here.
    size.height = minSize.height;
    size.width = MAX(minSize.width, [([self stringValue] || @" ") sizeWithFont:[self font]].width + contentInset.left + contentInset.right);

    return size;
}

- (void)setButtonType:(int)aButtonType
{
    if (_buttonType === aButtonType)
        return;

    _buttonType = aButtonType;

    if (_buttonType === CPTokenFieldDisclosureButtonType)
    {
        if (_deleteButton)
        {
            [_deleteButton removeFromSuperview];
            _deleteButton = nil;
        }

        if (!_disclosureButton)
        {
            _disclosureButton = [[_CPTokenFieldTokenDisclosureButton alloc] initWithFrame:CGRectMakeZero()];
            [self addSubview:_disclosureButton];
        }
    }
    else
    {
        if (_disclosureButton)
        {
            [_disclosureButton removeFromSuperview];
            _disclosureButton = nil;
        }

        if (!_deleteButton)
        {
            _deleteButton = [[_CPTokenFieldTokenCloseButton alloc] initWithFrame:CGRectMakeZero()];
            [self addSubview:_deleteButton];
            [_deleteButton setTarget:self];
            [_deleteButton setAction:@selector(_delete:)];
        }
    }

    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    var bezelView = [self layoutEphemeralSubviewNamed:@"bezel-view"
                                           positioned:CPWindowBelow
                      relativeToEphemeralSubviewNamed:@"content-view"];

    if (bezelView && _tokenField)
    {
        switch (_buttonType)
        {
            case CPTokenFieldDisclosureButtonType:
                var shouldBeEnabled = [self hasMenu];
                [_disclosureButton setHidden:!shouldBeEnabled];

                if (shouldBeEnabled)
                    [_disclosureButton setMenu:[self menu]];

                var frame = [bezelView frame],
                    buttonOffset = [_disclosureButton currentValueForThemeAttribute:@"offset"],
                    buttonSize = [_disclosureButton currentValueForThemeAttribute:@"min-size"];

                [_disclosureButton setFrame:CGRectMake(CGRectGetMaxX(frame) - buttonOffset.x, CGRectGetMinY(frame) + buttonOffset.y, buttonSize.width, buttonSize.height)];
                break;
            case CPTokenFieldDeleteButtonType:
                [_deleteButton setEnabled:[self isEditable] && [self isEnabled]];

                var frame = [bezelView frame],
                    buttonOffset = [_deleteButton currentValueForThemeAttribute:@"offset"],
                    buttonSize = [_deleteButton currentValueForThemeAttribute:@"min-size"];

                [_deleteButton setFrame:CGRectMake(CGRectGetMaxX(frame) - buttonOffset.x, CGRectGetMinY(frame) + buttonOffset.y, buttonSize.width, buttonSize.height)];
                break;
        }
    }
}

- (void)mouseDown:(CPEvent)anEvent
{
    [_tokenField _mouseDownOnToken:self withEvent:anEvent];
}

- (void)mouseUp:(CPEvent)anEvent
{
    [_tokenField _mouseUpOnToken:self withEvent:anEvent];
}

- (void)_delete:(id)sender
{
    if ([self isEditable])
        [_tokenField _deleteToken:self];
}

- (BOOL)hasMenu
{
    return [_tokenField _hasMenuForRepresentedObject:_representedObject];
}

- (CPMenu)menu
{
    return [_tokenField _menuForRepresentedObject:_representedObject];
}

@end

@implementation _CPTokenFieldTokenCloseButton : CPButton
{
}

+ (CPDictionary)themeAttributes
{
    var attributes = [CPButton themeAttributes];

    [attributes setObject:CGPointMake(15, 5) forKey:@"offset"];

    return attributes;
}

+ (CPString)defaultThemeClass
{
    return "tokenfield-token-close-button";
}

- (void)mouseEntered:(CPEvent)anEvent
{
    // Don't toggle hover state from within the button - we use the hover state of the token field as a whole.
}

- (void)mouseExited:(CPEvent)anEvent
{
    // Don't toggle hover state from within the button - we use the hover state of the token field as a whole.
}

@end

@implementation _CPTokenFieldTokenDisclosureButton : CPPopUpButton
{
}

+ (CPDictionary)themeAttributes
{
    var attributes = [CPButton themeAttributes];

    [attributes setObject:CGPointMake(15, 5) forKey:@"offset"];

    return attributes;
}

+ (CPString)defaultThemeClass
{
    return "tokenfield-token-disclosure-button";
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [self initWithFrame:aFrame pullsDown:YES])
    {
        [self setBordered:YES];
        [super setTitle:@""];
    }

    return self;
}

- (void)setTitle:(CPString)aTitle
{
    // skip
}

- (void)synchronizeTitleAndSelectedItem
{
    // skip
}

- (void)mouseEntered:(CPEvent)anEvent
{
    // Don't toggle hover state from within the button - we use the hover state of the token field as a whole.
}

- (void)mouseExited:(CPEvent)anEvent
{
    // Don't toggle hover state from within the button - we use the hover state of the token field as a whole.
}

@end


var CPTokenFieldTokenizingCharacterSetKey   = "CPTokenFieldTokenizingCharacterSetKey",
    CPTokenFieldCompletionDelayKey          = "CPTokenFieldCompletionDelay",
    CPTokenFieldButtonTypeKey               = "CPTokenFieldButtonTypeKey";

@implementation CPTokenField (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _tokenizingCharacterSet = [aCoder decodeObjectForKey:CPTokenFieldTokenizingCharacterSetKey] || [[self class] defaultTokenizingCharacterSet];
        _completionDelay = [aCoder decodeDoubleForKey:CPTokenFieldCompletionDelayKey] || [[self class] defaultCompletionDelay];
        _buttonType = [aCoder decodeIntForKey:CPTokenFieldButtonTypeKey] || CPTokenFieldDisclosureButtonType;

        [self _init];

        [self setNeedsLayout];
        [self setNeedsDisplay:YES];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeInt:_tokenizingCharacterSet forKey:CPTokenFieldTokenizingCharacterSetKey];
    [aCoder encodeDouble:_completionDelay forKey:CPTokenFieldCompletionDelayKey];
    [aCoder encodeInt:_buttonType forKey:CPTokenFieldButtonTypeKey];
}

@end
