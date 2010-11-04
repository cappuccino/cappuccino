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

@import "CPButton.j"
@import "CPScrollView.j"
@import "CPTextField.j"
@import "CPWindow.j"
@import "_CPMenuWindow.j"


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

    CPTokenFieldBlurFunction = nil,
    CPTokenFieldKeyUpFunction = nil,
    CPTokenFieldKeyPressFunction = nil,
    CPTokenFieldKeyDownFunction = nil;

#endif

var CPThemeStateAutoCompleting          = @"CPThemeStateAutoCompleting",
    CPTokenFieldTableColumnIdentifier   = @"CPTokenFieldTableColumnIdentifier",

    CPScrollDestinationNone             = 0,
    CPScrollDestinationLeft             = 1,
    CPScrollDestinationRight            = 2;

@implementation CPTokenField : CPTextField
{
    CPScrollView        _tokenScrollView;
    int                 _shouldScrollTo;

    CPRange             _selectedRange;

    CPView              _autocompleteContainer;
    CPScrollView        _autocompleteScrollView;
    CPTableView         _autocompleteView;
    CPTimeInterval      _completionDelay;
    CPTimer             _showCompletionsTimer;

    CPArray             _cachedCompletions;

    CPCharacterSet      _tokenizingCharacterSet @accessors(property=tokenizingCharacterSet);

    CPEvent             _mouseDownEvent;

    BOOL                _preventResign;
}

+ (CPCharacterSet)defaultTokenizingCharacterSet
{
    return [CPCharacterSet characterSetWithCharactersInString:@","];
}

+ (CPString)defaultThemeClass
{
    return "tokenfield";
}

- (id)initWithFrame:(CPRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _selectedRange = CPMakeRange(0, 0);

        _tokenScrollView = [[CPScrollView alloc] initWithFrame:CGRectMakeZero()];
        [_tokenScrollView setHasHorizontalScroller:NO];
        [_tokenScrollView setHasVerticalScroller:NO];
        [_tokenScrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

        var contentView = [[CPView alloc] initWithFrame:CGRectMakeZero()];
        [contentView setAutoresizingMask:CPViewWidthSizable];
        [_tokenScrollView setDocumentView:contentView];

        [self addSubview:_tokenScrollView];

        _tokenIndex = 0;

        _cachedCompletions = [];
        _completionDelay = [CPTokenField defaultCompletionDelay];

        _tokenizingCharacterSet = [[self class] defaultTokenizingCharacterSet];

        _autocompleteContainer = [[CPView alloc] initWithFrame:CPRectMake(0.0, 0.0, frame.size.width, 92.0)];
        [_autocompleteContainer setBackgroundColor:[_CPMenuWindow backgroundColorForBackgroundStyle:_CPMenuWindowPopUpBackgroundStyle]];

        _autocompleteScrollView = [[CPScrollView alloc] initWithFrame:CPRectMake(1.0, 1.0, frame.size.width - 2.0, 90.0)];
        [_autocompleteScrollView setAutohidesScrollers:YES];
        [_autocompleteScrollView setHasHorizontalScroller:NO];
        [_autocompleteContainer addSubview:_autocompleteScrollView];

        _autocompleteView = [[CPTableView alloc] initWithFrame:CPRectMakeZero()];

        var tableColumn = [[CPTableColumn alloc] initWithIdentifier:CPTokenFieldTableColumnIdentifier];
        [tableColumn setResizingMask:CPTableColumnAutoresizingMask];
        [_autocompleteView addTableColumn:tableColumn];

        [_autocompleteView setDataSource:self];
        [_autocompleteView setDelegate:self];
        [_autocompleteView setAllowsMultipleSelection:NO];
        [_autocompleteView setHeaderView:nil];
        [_autocompleteView setCornerView:nil];
        [_autocompleteView setRowHeight:30.0];
        [_autocompleteView setGridStyleMask:CPTableViewSolidHorizontalGridLineMask];
        [_autocompleteView setBackgroundColor:[CPColor clearColor]];
        [_autocompleteView setGridColor:[CPColor colorWithRed:242.0 / 255.0 green:243.0 / 255.0 blue:245.0 / 255.0 alpha:1.0]];

        [_autocompleteScrollView setDocumentView:_autocompleteView];

        [self setBezeled:YES];

        [self setObjectValue:[]];
        [self setNeedsLayout];
    }

    return self;
}

// ===============
// = CONVENIENCE =
// ===============
- (void)_retrieveCompletions
{
    var indexOfSelectedItem = 0;

    _cachedCompletions = [self tokenField:self completionsForSubstring:[self _inputElement].value indexOfToken:_tokenIndex indexOfSelectedItem:indexOfSelectedItem];

    [_autocompleteView selectRowIndexes:[CPIndexSet indexSetWithIndex:indexOfSelectedItem] byExtendingSelection:NO];
    [_autocompleteView reloadData];
}

- (void)_autocompleteWithDOMEvent:(JSObject)DOMEvent
{
    if (!_cachedCompletions || ![self hasThemeState:CPThemeStateAutoCompleting])
        return;

    [self _hideCompletions];

    var token = _cachedCompletions[[_autocompleteView selectedRow]],
        shouldRemoveLastObject = token !== @"" && [self _inputElement].value !== @"";

    if (!token)
        token = [self _inputElement].value;

    // Make sure the user typed an actual token to prevent the previous token from being emptied
    // If the input area is empty, we want to fallback to the normal behaviour, resigning first responder or select the next or previous key view
    if (!token || token === @"")
    {
        if (DOMEvent && DOMEvent.keyCode === CPTabKeyCode)
        {
            if (!DOMEvent.shiftKey)
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
    // Explicitely remove the last object because the array contains strings and removeObject uses isEqual to compare objects
    if (shouldRemoveLastObject)
        [objectValue removeObjectAtIndex:_selectedRange.location];

    [objectValue insertObject:token atIndex:_selectedRange.location];
    var location = _selectedRange.location;
    [self setObjectValue:objectValue];
    _selectedRange = CPMakeRange(location + 1, 0);

    [self _inputElement].value = @"";
    [self setNeedsLayout];

    var theBinding = [CPKeyValueBinding getBinding:CPValueBinding forObject:self];

    if (theBinding)
        [theBinding reverseSetValueFor:@"objectValue"];
}

- (void)_autocomplete
{
    [self _autocompleteWithDOMEvent:nil];
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

    // If the token was selected, deselect it for selection preservation.
    [self _deselectToken:token];
    // Preserve selection.
    var selection = CPCopyRange(_selectedRange);
    [objectValue removeObjectAtIndex:indexOfToken];
    [self setObjectValue:objectValue];
    _selectedRange = selection;

    [self setNeedsLayout];
    [self _controlTextDidChange];
}

- (void)_controlTextDidChange
{
    var theBinding = [CPKeyValueBinding getBinding:CPValueBinding forObject:self];

    if (theBinding)
        [theBinding reverseSetValueFor:@"objectValue"];

    [self textDidChange:[CPNotification notificationWithName:CPControlTextDidChangeNotification object:self userInfo:nil]];
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

// =============
// = RESPONDER =
// =============

- (BOOL)becomeFirstResponder
{
    if (CPTokenFieldInputOwner && [CPTokenFieldInputOwner window] !== [self window])
        [[CPTokenFieldInputOwner window] makeFirstResponder:nil];

    [self setThemeState:CPThemeStateEditing];

    [self _updatePlaceholderState];

    [self setNeedsLayout];

#if PLATFORM(DOM)

    var string = [self stringValue],
        element = [self _inputElement];

    element.value = nil;
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

    element.style.top = CGRectGetMinY(contentRect) + "px";
    element.style.left = (CGRectGetMinX(contentRect) - 1) + "px"; // why -1?
    element.style.width = CGRectGetWidth(contentRect) + "px";
    element.style.height = CGRectGetHeight(contentRect) + "px";

    [_tokenScrollView documentView]._DOMElement.appendChild(element);

    window.setTimeout(function()
    {
        element.focus();
        CPTokenFieldInputOwner = self;
    }, 0.0);

    //post CPControlTextDidBeginEditingNotification
    [self textDidBeginEditing:[CPNotification notificationWithName:CPControlTextDidBeginEditingNotification object:self userInfo:nil]];

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
    if (_preventResign)
        return NO;

    [self unsetThemeState:CPThemeStateEditing];

    [self _autocomplete];

#if PLATFORM(DOM)

    var element = [self _inputElement];

    CPTokenFieldInputResigning = YES;
    element.blur();

    if (!CPTokenFieldInputDidBlur)
        CPTokenFieldBlurFunction();

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

    [self _updatePlaceholderState];

    [self setNeedsLayout];

    [self textDidEndEditing:[CPNotification notificationWithName:CPControlTextDidBeginEditingNotification object:self userInfo:nil]];

    return YES;
}

- (void)mouseDown:(CPEvent)anEvent
{
    _preventResign = YES;
    _mouseDownEvent = anEvent;

    [self _selectToken:nil byExtendingSelection:NO];

    [super mouseDown:anEvent];
}

- (void)mouseUp:(CPEvent)anEvent
{
    _preventResign = NO;
    _mouseDownEvent = nil;
}

- (void)mouseDownOnToken:(_CPTokenFieldToken)aToken withEvent:(CPEvent)anEvent
{
    _preventResign = YES;
    _mouseDownEvent = anEvent;
}

- (void)mouseUpOnToken:(_CPTokenFieldToken)aToken withEvent:(CPEvent)anEvent
{
    if (_mouseDownEvent && CGPointEqualToPoint([_mouseDownEvent locationInWindow], [anEvent locationInWindow]))
    {
        [self _selectToken:aToken byExtendingSelection:[anEvent modifierFlags] & CPShiftKeyMask];
        [[self window] makeFirstResponder:self];
        // Snap to the token if it's only half visible due to mouse wheel scrolling.
        _shouldScrollTo = aToken;
    }
    _preventResign = NO;
}

// ===========
// = CONTROL =
// ===========
- (CPArray)_tokens
{
    // We return super here because objectValue uses this method
    // If we called self we would loop infinitly
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

        [objectValue addObject:[token stringValue]];
    }

#if PLATFORM(DOM)

    if ([self _inputElement].value != @"")
        [objectValue insertObject:[self _inputElement].value atIndex:_selectedRange.location];

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

    var contentView = [_tokenScrollView documentView];

    // Preserve as many existing tokens as possible to reduce redraw flickering.
    var oldTokens = [self _tokens],
        newTokens = [];

    if (aValue !== nil)
    {
        for (var i = 0, count = [aValue count]; i < count; i++)
        {
            // Do we have this token among the old ones?
            var tokenValue = aValue[i],
                newToken = nil;

            for (var j = 0, oldCount = [oldTokens count]; j < oldCount; j++)
            {
                var oldToken = oldTokens[j];
                if ([oldToken stringValue] == tokenValue)
                {
                    // Yep. Reuse it.
                    [oldTokens removeObjectAtIndex:j];
                    newToken = oldToken;
                    break;
                }
            }

            if (newToken === nil)
            {
                newToken = [[_CPTokenFieldToken alloc] init];
                [newToken setTokenField:self];
                [newToken setStringValue:tokenValue];
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

// Incredible hack to disable supers implementation
// so it cannot change our object value and break the tokenfield
- (void)_setStringValue:(id)aValue
{
}


// ========
// = VIEW =
// ========
- (void)viewDidMoveToWindow
{
    [[[self window] contentView] addSubview:_autocompleteContainer];
    _autocompleteContainer._DOMElement.style.zIndex = 1000; // Anything else doesn't seem to work
}

- (void)removeFromSuperview
{
    [_autocompleteContainer removeFromSuperview];
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

        CPTokenFieldBlurFunction = function(anEvent)
        {
            if (CPTokenFieldInputOwner && [CPTokenFieldInputOwner._tokenScrollView documentView]._DOMElement != CPTokenFieldDOMInputElement.parentNode)
                return;

            if (CPTokenFieldInputOwner && CPTokenFieldInputOwner._preventResign)
                return false;

            if (!CPTokenFieldInputResigning && !CPTokenFieldFocusInput)
            {
                [[CPTokenFieldInputOwner window] makeFirstResponder:nil];
                return;
            }

            CPTokenFieldHandleBlur(anEvent, CPTokenFieldDOMInputElement);
            CPTokenFieldInputDidBlur = YES;

            return true;
        }

        CPTokenFieldKeyDownFunction = function(aDOMEvent)
        {
            aDOMEvent = aDOMEvent || window.event

            CPTokenFieldTextDidChangeValue = [CPTokenFieldInputOwner stringValue];

            // Update the selectedIndex if necesary
            var index = [[CPTokenFieldInputOwner autocompleteView] selectedRow];

            if (aDOMEvent.keyCode === CPUpArrowKeyCode)
                index -= 1;
            else if (aDOMEvent.keyCode === CPDownArrowKeyCode)
                index += 1;

            if (index > [[CPTokenFieldInputOwner autocompleteView] numberOfRows] - 1)
                index = [[CPTokenFieldInputOwner autocompleteView] numberOfRows] - 1;

            if (index < 0)
                index = 0;

            [[CPTokenFieldInputOwner autocompleteView] selectRowIndexes:[CPIndexSet indexSetWithIndex:index] byExtendingSelection:NO];

            var autocompleteView = [CPTokenFieldInputOwner autocompleteView],
                clipView = [[autocompleteView enclosingScrollView] contentView],
                rowRect = [autocompleteView rectOfRow:index],
                owner = CPTokenFieldInputOwner;

            if (rowRect && !CPRectContainsRect([clipView bounds], rowRect))
                [clipView scrollToPoint:[autocompleteView rectOfRow:index].origin];

            if (aDOMEvent.keyCode === CPReturnKeyCode || aDOMEvent.keyCode === CPTabKeyCode)
            {
                if (aDOMEvent.preventDefault)
                    aDOMEvent.preventDefault();
                if (aDOMEvent.stopPropagation)
                    aDOMEvent.stopPropagation();
                aDOMEvent.cancelBubble = true;

                // Only resign first responder if we weren't autocompleting
                if (![CPTokenFieldInputOwner hasThemeState:CPThemeStateAutoCompleting])
                {
                    if (aDOMEvent && aDOMEvent.keyCode === CPReturnKeyCode)
                    {
                        [owner sendAction:[owner action] to:[owner target]];
                        [[owner window] makeFirstResponder:nil];
                    }
                    else if (aDOMEvent && aDOMEvent.keyCode === CPTabKeyCode)
                    {
                        if (!aDOMEvent.shiftKey)
                            [[owner window] selectNextKeyView:owner];
                        else
                            [[owner window] selectPreviousKeyView:owner];
                    }
                }

                [owner _autocompleteWithDOMEvent:aDOMEvent];
                [owner setNeedsLayout];
            }
            else if (aDOMEvent.keyCode === CPEscapeKeyCode)
            {
                [CPTokenFieldInputOwner _hideCompletions];
            }
            else if (aDOMEvent.keyCode === CPUpArrowKeyCode || aDOMEvent.keyCode === CPDownArrowKeyCode)
            {
                if (aDOMEvent.preventDefault)
                    aDOMEvent.preventDefault();
                if (aDOMEvent.stopPropagation)
                    aDOMEvent.stopPropagation();
                aDOMEvent.cancelBubble = true;
            }
            else if (aDOMEvent.keyCode == CPLeftArrowKeyCode && owner._selectedRange.location > 0 && CPTokenFieldDOMInputElement.value == "")
            {
                // Move the cursor back one token if the input is empty and the left arrow key is pressed.
                if (!aDOMEvent.shiftKey)
                {
                    if (owner._selectedRange.length)
                        // Simply collapse the range.
                        owner._selectedRange.length = 0;
                    else
                        owner._selectedRange.location--;
                }
                else
                {
                    owner._selectedRange.location--;
                    // When shift is depressed, select the next token backwards.
                    owner._selectedRange.length++;
                }
                owner._shouldScrollTo = CPScrollDestinationLeft;
                [owner setNeedsLayout];
            }
            else if (aDOMEvent.keyCode == CPRightArrowKeyCode && owner._selectedRange.location < [[owner _tokens] count] && CPTokenFieldDOMInputElement.value == "")
            {
                if (!aDOMEvent.shiftKey)
                {
                    if (owner._selectedRange.length)
                    {
                        // Place the cursor at the end of the selection and collapse.
                        owner._selectedRange.location = CPMaxRange(owner._selectedRange);
                        owner._selectedRange.length = 0;
                    }
                    else
                    {
                        // Move the cursor forward one token if the input is empty and the right arrow key is pressed.
                        owner._selectedRange.location = MIN([[owner _tokens] count], owner._selectedRange.location + owner._selectedRange.length + 1);
                    }
                }
                else
                {
                    // Leave the selection location in place but include the next token to the right.
                    owner._selectedRange.length++;
                }
                owner._shouldScrollTo = CPScrollDestinationRight;
                [owner setNeedsLayout];
            }
            else if (aDOMEvent.keyCode === CPDeleteKeyCode)
            {
                // Highlight the previous token if backspace was pressed in an empty input element or re-show the completions view
                if (CPTokenFieldDOMInputElement.value == @"")
                {
                    [self _hideCompletions];

                    if (CPEmptyRange(CPTokenFieldInputOwner._selectedRange))
                    {
                        if (CPTokenFieldInputOwner._selectedRange.location > 0)
                        {
                            var tokens = [CPTokenFieldInputOwner _tokens],
                                tokenView = [tokens objectAtIndex:(CPTokenFieldInputOwner._selectedRange.location - 1)];
                            [CPTokenFieldInputOwner _selectToken:tokenView byExtendingSelection:NO];
                        }
                    }
                    else
                        [CPTokenFieldInputOwner _removeSelectedTokens:nil];
                }
                else
                    [CPTokenFieldInputOwner _delayedShowCompletions];
            }
            else if (aDOMEvent.keyCode === CPDeleteForwardKeyCode && CPTokenFieldDOMInputElement.value == @"")
            {
                // Delete forward if nothing is selected, else delete all selected.
                [self _hideCompletions];

                if (CPEmptyRange(CPTokenFieldInputOwner._selectedRange))
                {
                    var tokens = [CPTokenFieldInputOwner _tokens];
                    if (CPTokenFieldInputOwner._selectedRange.location < [tokens count])
                        [CPTokenFieldInputOwner _deleteToken:tokens[CPTokenFieldInputOwner._selectedRange.location]];
                }
                else
                    [CPTokenFieldInputOwner _removeSelectedTokens:nil];
            }

            return true;
        }

        CPTokenFieldKeyPressFunction = function(aDOMEvent)
        {
            aDOMEvent = aDOMEvent || window.event;

            var character = String.fromCharCode(aDOMEvent.keyCode || aDOMEvent.which),
                owner = CPTokenFieldInputOwner;

            if ([[owner tokenizingCharacterSet] characterIsMember:character])
            {
                if (aDOMEvent.preventDefault)
                    aDOMEvent.preventDefault();
                if (aDOMEvent.stopPropagation)
                    aDOMEvent.stopPropagation();
                aDOMEvent.cancelBubble = true;

                [owner _autocompleteWithDOMEvent:aDOMEvent];
                [owner setNeedsLayout];

                return true;
            }

            [CPTokenFieldInputOwner _delayedShowCompletions];
            // If there was a selection, collapse it now since we're typing in a new token.
            owner._selectedRange.length = 0;

            // Force immediate layout in case word wrapping is now necessary.
            [owner setNeedsLayout];
            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
        }

        CPTokenFieldKeyUpFunction = function()
        {
            if ([CPTokenFieldInputOwner stringValue] !== CPTokenFieldTextDidChangeValue)
            {
                CPTokenFieldTextDidChangeValue = [CPTokenFieldInputOwner stringValue];
                [CPTokenFieldInputOwner textDidChange:[CPNotification notificationWithName:CPControlTextDidChangeNotification object:CPTokenFieldInputOwner userInfo:nil]];
            }

            [self setNeedsLayout];

            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
        }

        CPTokenFieldHandleBlur = function(anEvent)
        {
            CPTokenFieldInputOwner = nil;

            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
        }

        if (document.attachEvent)
        {
            CPTokenFieldDOMInputElement.attachEvent("on" + CPDOMEventKeyUp, CPTokenFieldKeyUpFunction);
            CPTokenFieldDOMInputElement.attachEvent("on" + CPDOMEventKeyDown, CPTokenFieldKeyDownFunction);
            CPTokenFieldDOMInputElement.attachEvent("on" + CPDOMEventKeyPress, CPTokenFieldKeyPressFunction);
        }
        else
        {
            CPTokenFieldDOMInputElement.addEventListener(CPDOMEventKeyUp, CPTokenFieldKeyUpFunction, NO);
            CPTokenFieldDOMInputElement.addEventListener(CPDOMEventKeyDown, CPTokenFieldKeyDownFunction, NO);
            CPTokenFieldDOMInputElement.addEventListener(CPDOMEventKeyPress, CPTokenFieldKeyPressFunction, NO);
        }

        //FIXME make this not onblur
        CPTokenFieldDOMInputElement.onblur = CPTokenFieldBlurFunction;

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

- (NSTimeInterval)completionDelay
{
    return _completionDelay;
}

+ (NSTimeInterval)defaultCompletionDelay
{
    return 0.5;
}

// ===========================
// = SHOW / HIDE COMPLETIONS =
// ===========================
- (void)_showCompletions:(CPTimer)timer
{
    [self _retrieveCompletions]
    [self setThemeState:CPThemeStateAutoCompleting];

    [self setNeedsLayout];
}

- (void)_delayedShowCompletions
{
    _showCompletionsTimer = [CPTimer scheduledTimerWithTimeInterval:[self completionDelay] target:self
                                                           selector:@selector(_showCompletions:) userInfo:nil repeats:NO];
}

- (void)_cancelShowCompletions
{
    if ([_showCompletionsTimer isValid])
        [_showCompletionsTimer invalidate];
}

- (void)_hideCompletions
{
    [self _cancelShowCompletions];

    [self unsetThemeState:CPThemeStateAutoCompleting];
    [self setNeedsLayout];
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

    // Correctly size the tableview
    // FIXME Horizontal scrolling will not work because we are not actually looking at the content to set the width for the table column
    [[_autocompleteView tableColumnWithIdentifier:CPTokenFieldTableColumnIdentifier] setWidth:[[_autocompleteScrollView contentView] frame].size.width];

    if ([self hasThemeState:CPThemeStateAutoCompleting] && [_cachedCompletions count])
    {
        // Manually sizeToFit because CPTableView's sizeToFit doesn't work properly
        [_autocompleteContainer setHidden:NO];
        var frameOrigin = [self convertPoint:[self bounds].origin toView:[_autocompleteContainer superview]];
        [_autocompleteContainer setFrameOrigin:CPPointMake(frameOrigin.x, frameOrigin.y + frame.size.height)];
        [_autocompleteContainer setFrameSize:CPSizeMake(CPRectGetWidth([self bounds]), 92.0)];
        [_autocompleteScrollView setFrameSize:CPSizeMake([_autocompleteContainer frame].size.width - 2.0, 90.0)];
    }
    else
        [_autocompleteContainer setHidden:YES];

    // Hack to make sure we are handling an array
    if (![tokens isKindOfClass:[CPArray class]])
        return;

    // Move each token into the right position.
    var contentRect = CGRectMakeCopy([contentView bounds]),
        contentOrigin = contentRect.origin,
        contentSize = contentRect.size,
        offset = CPPointMake(contentOrigin.x, contentOrigin.y),
        spaceBetweenTokens = CPSizeMake(2.0, 2.0),
        isEditing = [[self window] firstResponder] == self,
        tokenToken = [_CPTokenFieldToken new];

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
        if (CGRectGetHeight([contentView bounds]) < offset.y + height)
            [contentView setFrame:CGRectMake(0, 0, CGRectGetWidth([_tokenScrollView bounds]), offset.y + height)];

        offset.x += width + spaceBetweenTokens.width;

        return r;
    }

    var placeEditor = function(useRemainingWidth)
    {
        var element = [self _inputElement],
            textWidth = 1;

        if (_selectedRange.length === 0)
        {
            // XXX The "X" here is used to estimate the space needed to fit the next character
            // without clipping. Since different fonts might have different sizes of "X" this
            // solution is not ideal, but it works.
            textWidth = [(element.value || @"") + "X" sizeWithFont:[self font]].width;
            if (useRemainingWidth)
                textWidth = MAX(contentSize.width - offset.x - 1, textWidth);
        }

        var inputFrame = fitAndFrame(textWidth, tokenHeight);

        element.style.left = inputFrame.origin.x + "px";
        element.style.top = inputFrame.origin.y + "px";
        element.style.width = inputFrame.size.width + "px";
        element.style.height = inputFrame.size.height + "px";

        // When editing, always scroll to the cursor.
        if (_selectedRange.length == 0)
            [[_tokenScrollView documentView] scrollRectToVisible:inputFrame];
    }

    for (var i = 0, count = [tokens count]; i < count; i++)
    {
        if (isEditing && i == CPMaxRange(_selectedRange))
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
    }

    if (isEditing && CPMaxRange(_selectedRange) >= [tokens count])
        placeEditor(true);

    // Hide the editor if there are selected tokens, but still keep it active
    // so we can continue using our standard keyboard handling events.
    if (isEditing && _selectedRange.length)
    {
        [self _inputElement].style.left = "-10000px";
        [self _inputElement].focus();
    }

    // Trim off any excess height downwards.
    if (CGRectGetHeight([contentView bounds]) > offset.y + tokenHeight)
        [contentView setFrame:CGRectMake(0, 0, CGRectGetWidth([_tokenScrollView bounds]), offset.y + tokenHeight)];

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

    return [[_tokenScrollView documentView] scrollRectToVisible:[aToken frame]];
}

// ======================
// = TABLEVIEW DATSOURCE / DELEGATE =
// ======================
- (int)numberOfRowsInTableView:(CPTableView)tableView
{
    return [_cachedCompletions count];
}

- (void)tableView:(CPTableView)tableView objectValueForTableColumn:(CPTableColumn)tableColumn row:(int)row
{
    return [_cachedCompletions objectAtIndex:row];
}

- (void)tableViewSelectionDidChange:(CPNotification)notification
{
    // make sure a mouse click in the tableview doesn't steal first responder state
    window.setTimeout(function()
    {
        [[self window] makeFirstResponder:self];
    }, 2.0);
}

// =============
// = ACCESSORS =
// =============
- (CPTableView)autocompleteView
{
    return _autocompleteView;
}

@end

@implementation CPTokenField (CPTokenFieldDelegate)

// // Each element in the array should be an NSString or an array of NSStrings.
// // substring is the partial string that is being completed.  tokenIndex is the index of the token being completed.
// // selectedIndex allows you to return by reference an index specifying which of the completions should be selected initially.
// // The default behavior is not to have any completions.
- (CPArray)tokenField:(CPTokenField)tokenField completionsForSubstring:(CPString)substring indexOfToken:(int)tokenIndex indexOfSelectedItem:(int)selectedIndex
{
    if ([[self delegate] respondsToSelector:@selector(tokenField:completionsForSubstring:indexOfToken:indexOfSelectedItem:)])
    {
        return [[self delegate] tokenField:tokenField completionsForSubstring:substring indexOfToken:_tokenIndex indexOfSelectedItem:selectedIndex];
    }

    return [];
}
//
// // return an array of represented objects you want to add.
// // If you want to reject the add, return an empty array.
// // returning nil will cause an error.
// - (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index;
//
// // If you return nil or don't implement these delegate methods, we will assume
// // editing string = display string = represented object
// - (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject;
// - (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject;
// - (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString: (NSString *)editingString;
//
// // We put the string on the pasteboard before calling this delegate method.
// // By default, we write the NSStringPboardType as well as an array of NSStrings.
// - (BOOL)tokenField:(NSTokenField *)tokenField writeRepresentedObjects:(NSArray *)objects toPasteboard:(NSPasteboard *)pboard;
//
// // Return an array of represented objects to add to the token field.
// - (NSArray *)tokenField:(NSTokenField *)tokenField readFromPasteboard:(NSPasteboard *)pboard;
//
// // By default the tokens have no menu.
// - (NSMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)representedObject;
// - (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject;
//
// // This method allows you to change the style for individual tokens as well as have mixed text and tokens.
// - (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject;

@end

@implementation _CPTokenFieldToken : CPTextField
{
    _CPTokenFieldTokenCloseButton   _deleteButton;
    CPTokenField                    _tokenField;
}

+ (CPString)defaultThemeClass
{
    return "tokenfield-token";
}

- (id)initWithFrame:(CPRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _deleteButton = [[_CPTokenFieldTokenCloseButton alloc] initWithFrame:CPRectMakeZero()];
        [self addSubview:_deleteButton];

        [self setEditable:NO];
        [self setHighlighted:NO];
        [self setBezeled:YES];
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

- (void)layoutSubviews
{
    [super layoutSubviews];

    var bezelView = [self layoutEphemeralSubviewNamed:@"bezel-view"
                                           positioned:CPWindowBelow
                      relativeToEphemeralSubviewNamed:@"content-view"];

    if (bezelView)
    {
        [_deleteButton setTarget:self];
        [_deleteButton setAction:@selector(_delete:)];

        var frame = [bezelView frame],
            buttonOffset = [_deleteButton currentValueForThemeAttribute:@"offset"],
            buttonSize = [_deleteButton currentValueForThemeAttribute:@"min-size"];

        [_deleteButton setFrame:CPRectMake(CPRectGetMaxX(frame) - buttonOffset.x, CPRectGetMinY(frame) + buttonOffset.y, buttonSize.width, buttonSize.height)];
    }
}

- (void)mouseDown:(CPEvent)anEvent
{
    [_tokenField mouseDownOnToken:self withEvent:anEvent];
}

- (void)mouseUp:(CPEvent)anEvent
{
    [_tokenField mouseUpOnToken:self withEvent:anEvent];
}

- (void)_delete:(id)sender
{
    [_tokenField _deleteToken:self];
}

@end

/*
    Theming hook.
*/
@implementation _CPTokenFieldTokenCloseButton : CPButton
{
}

+ (id)themeAttributes
{
    var attributes = [CPButton themeAttributes];

    [attributes setObject:CGPointMake(15, 5) forKey:@"offset"];

    return attributes;
}

+ (CPString)defaultThemeClass
{
    return "tokenfield-token-close-button";
}

@end
