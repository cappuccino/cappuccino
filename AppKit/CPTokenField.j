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

#include "Platform/Platform.h"

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

var CPThemeStateAutoCompleting = @"CPThemeStateAutoCompleting",
    CPTokenFieldTableColumnIdentifier = @"CPTokenFieldTableColumnIdentifier";

@implementation CPTokenField : CPTextField
{
    CPView              _autocompleteContainer;
    CPScrollView        _autocompleteScrollView;
    CPTableView         _autocompleteView;
    CPTimeInterval      _completionDelay;
    CPTimer             _showCompletionsTimer;

    CPArray             _cachedCompletions;

    CPIndexSet          _selectedTokenIndexes;

    CPCharacterSet      _tokenizingCharacterSet @accessors(property=tokenizingCharacterSet);
}

+ (CPCharacterSet)defaultTokenizingCharacterSet
{
    return [CPCharacterSet characterSetWithCharactersInString:@","];
}

+ (CPString)themeClass
{
    return "tokenfield";
}

- (id)initWithFrame:(CPRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _tokenIndex = 0;
        _selectedTokenIndexes = [CPIndexSet indexSet];

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
    {
        var indexOfLastObject = [objectValue count] - 1;
        if (!indexOfLastObject)
            indexOfLastObject = 0;

        [objectValue removeObjectAtIndex:indexOfLastObject];
    }

    [objectValue addObject:token];
    [self setObjectValue:objectValue];

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

    if (extend)
        [_selectedTokenIndexes addIndex:indexOfToken];
    else
        _selectedTokenIndexes = [CPIndexSet indexSetWithIndex:indexOfToken];

    [self setNeedsLayout];
}

- (void)_deselectToken:(_CPTokenFieldToken)token
{
    var indexOfToken = [[self _tokens] indexOfObject:token];
    [_selectedTokenIndexes removeIndex:indexOfToken];

    [self setNeedsLayout];
}

- (void)_deleteToken:(_CPTokenFieldToken)token
{
    var indexOfToken = [[self _tokens] indexOfObject:token],
        objectValue = [self objectValue];

    [objectValue removeObjectAtIndex:indexOfToken];
    [self setObjectValue:objectValue];

    var theBinding = [CPKeyValueBinding getBinding:CPValueBinding forObject:self];

    if (theBinding)
        [theBinding reverseSetValueFor:@"objectValue"];

    [self textDidChange:[CPNotification notificationWithName:CPControlTextDidChangeNotification object:self userInfo:nil]];
}

- (CPIndexSet)_selectedTokenIndexes
{
    return _selectedTokenIndexes;
}

- (void)_setSelectedTokenIndexes:(CPIndexSet)selectedIndexes
{
    _selectedTokenIndexes = selectedIndexes;
    [self setNeedsLayout];
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

    _DOMElement.appendChild(element);

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
    [self unsetThemeState:CPThemeStateEditing];

    [self _updatePlaceholderState];

    [self setNeedsLayout];

    [self _autocomplete];

#if PLATFORM(DOM)

    var element = [self _inputElement];

    CPTokenFieldInputResigning = YES;
    element.blur();

    if (!CPTokenFieldInputDidBlur)
        CPTokenFieldBlurFunction();

    CPTokenFieldInputDidBlur = NO;
    CPTokenFieldInputResigning = NO;

    if (element.parentNode == _DOMElement)
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
    _selectedTokenIndexes = [CPIndexSet indexSet];

    [self textDidEndEditing:[CPNotification notificationWithName:CPControlTextDidBeginEditingNotification object:self userInfo:nil]];

    return YES;
}

- (void)mouseDown:(CPEvent)anEvent
{
    _selectedTokenIndexes = [CPIndexSet indexSet];

    // CPTokenFieldFocusInput = YES;
    [super mouseDown:anEvent];
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
    for (var i = 0; i < [[self _tokens] count]; i++)
    {
        var token = [[self _tokens] objectAtIndex:i];

        if ([token isKindOfClass:[CPString class]])
            continue;

        [objectValue addObject:[token stringValue]];
    }

#if PLATFORM(DOM)

    if ([self _inputElement].value != @"")
        [objectValue addObject:[self _inputElement].value];

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

    var objectValue = [aValue copy];

    // Because we do not know for sure which tokens are removed we remove them all
    for (var i = 0; i < [[self _tokens] count]; i++)
        [[[self _tokens] objectAtIndex:i] removeFromSuperview];

    objectValue = [];

    if (aValue !== nil)
    {
        // Re-add all tokens
        for (var i = 0; i < [aValue count]; i++)
        {
            var token = [aValue objectAtIndex:i],
                tokenView = [[_CPTokenFieldToken alloc] init];

            [tokenView setTokenField:self];
            [tokenView setStringValue:token];
            [objectValue addObject:tokenView];

            [self addSubview:tokenView];
        }
    }

    /*
    [CPTextField setObjectValue] will try to set the _inputElement.value to
    the new objectValue, if the _inputElement exists. This is wrong for us
    since our objectValue is an array of tokens, so we can't use
    [super setObjectValue:objectValue];

    Instead do what CPControl setObjectValue would.
    */
    _value = objectValue;

    [self _updatePlaceholderState];

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
            if (CPTokenFieldInputOwner && CPTokenFieldInputOwner._DOMElement != CPTokenFieldDOMInputElement.parentNode)
                return;

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
            CPTokenFieldTextDidChangeValue = [CPTokenFieldInputOwner stringValue];

            // CPTokenFieldKeyPressFunction(anEvent);
            aDOMEvent = aDOMEvent || window.event

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
                rowRect = [autocompleteView rectOfRow:index];

            // The clipview's and row it's width are equal, this makes sure the clipview can contain the row rect
            // rowRect.size.width -= 2.0;
            if (rowRect && !CPRectContainsRect([clipView bounds], rowRect))
                [clipView scrollToPoint:[autocompleteView rectOfRow:index].origin];

            if (aDOMEvent.keyCode === CPReturnKeyCode || aDOMEvent.keyCode === CPTabKeyCode)
            {
                if (aDOMEvent.preventDefault)
                    aDOMEvent.preventDefault();
                if (aDOMEvent.stopPropagation)
                    aDOMEvent.stopPropagation();
                aDOMEvent.cancelBubble = true;

                var owner = CPTokenFieldInputOwner;

                if (aDOMEvent && aDOMEvent.keyCode === CPReturnKeyCode)
                {
                    // Only resign first responder if we weren't autocompleting
                    if (![CPTokenFieldInputOwner hasThemeState:CPThemeStateAutoCompleting])
                    {
                        [owner sendAction:[owner action] to:[owner target]];
                        [[owner window] makeFirstResponder:nil];
                    }
                }
                else if (aDOMEvent && aDOMEvent.keyCode === CPTabKeyCode)
                {
                    // Only resign first responder if we weren't autocompleting
                    if (![CPTokenFieldInputOwner hasThemeState:CPThemeStateAutoCompleting])
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
            else if (aDOMEvent.keyCode === CPDeleteKeyCode)
            {
                // Highlight the previous token if backspace was pressed in an empty input element or re-show the completions view
                if (CPTokenFieldDOMInputElement.value == @"")
                {
                    [self _hideCompletions];

                    // var tokenViews = [[CPTokenFieldInputOwner _tokens] lastObject];
                    var tokens = [CPTokenFieldInputOwner _tokens];

                    if (![[CPTokenFieldInputOwner _selectedTokenIndexes] count])
                    {
                        var tokenView = [tokens lastObject];
                        [CPTokenFieldInputOwner _setSelectedTokenIndexes:[CPIndexSet indexSetWithIndex:[tokens indexOfObject:tokenView]]];
                        [CPTokenFieldInputOwner _hideCompletions];
                    }
                    else
                    {
                        var tokenViews = [tokens objectsAtIndexes:[CPTokenFieldInputOwner _selectedTokenIndexes]];

                        for (var i = 0; i < [tokenViews count]; i++)
                        {
                            var tokenView = [tokenViews objectAtIndex:i];

                            [tokenView removeFromSuperview];
                            [[CPTokenFieldInputOwner _tokens] removeObject:tokenView];
                        }

                        [CPTokenFieldInputOwner _setSelectedTokenIndexes:[CPIndexSet indexSet]];
                    }

                }
                else
                    [CPTokenFieldInputOwner _delayedShowCompletions];
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
            _selectedTokenIndexes = [CPIndexSet indexSet];

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
            var owner = CPTokenFieldInputOwner;
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
    {
        [_showCompletionsTimer invalidate];
    }
}

- (void)_hideCompletions
{
    [self _cancelShowCompletions];

    [self unsetThemeState:CPThemeStateAutoCompleting];
    [self setNeedsLayout];
}


// - (void)setTokenizingCharacterSet:(NSCharacterSet *)characterSet;
// - (NSCharacterSet *)tokenizingCharacterSet;
// + (NSCharacterSet *)defaultTokenizingCharacterSet

// ==========
// = LAYOUT =
// ==========
- (void)layoutSubviews
{
    [super layoutSubviews];

    var frame = [self frame],

        contentView = [self layoutEphemeralSubviewNamed:@"content-view"
                                             positioned:CPWindowAbove
                        relativeToEphemeralSubviewNamed:@"bezel-view"];

    if (contentView)
        [contentView setHidden:[self stringValue] !== @""];

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

    // Add every token as a seperate view
    var contentRect = [self contentRectForBounds:[self bounds]],
        contentOrigin = contentRect.origin,
        contentSize = contentRect.size,
        offset = CPPointMake(contentOrigin.x, contentOrigin.y),
        spaceBetweenTokens = CPSizeMake(2.0, 2.0);

    // Hack to make sure we are handling with an array
    if (![[self _tokens] isKindOfClass:[CPArray class]])
        return;

    for (var i = 0; i < [[self _tokens] count]; i++)
    {
        var tokenView = [[self _tokens] objectAtIndex:i];

        // Make sure we are only changing completed tokens
        if ([tokenView isKindOfClass:[CPString class]])
            continue;

        [tokenView setHighlighted:[_selectedTokenIndexes containsIndex:i]];
        [tokenView sizeToFit];

        // Increase the token fields height if the token view is outside of the bounds
        var size = [self bounds].size,
            tokenViewSize = [tokenView bounds].size;

        if (contentSize.width < offset.x + tokenViewSize.width)
        {
            // Reset the x coordinate to the beginnning of the field
            offset.x = contentOrigin.x;

            // Increase the y offset to fall below the current tokens
            offset.y += tokenViewSize.height + spaceBetweenTokens.height;

            if (offset.y + tokenViewSize.height > contentSize.height)
            {
                size.height += offset.y + tokenViewSize.height;
                [self setFrameSize:size];
            }
        }

        [tokenView setFrameOrigin:offset];
        offset.x += [tokenView bounds].size.width + spaceBetweenTokens.width;
    }

    if ([[self window] firstResponder] != self)
        return;

    var element = [self _inputElement];

    element.style.left = offset.x + @"px";
    element.style.top = offset.y + @"px";
    element.style.width = [self bounds].size.width - offset.x - 8.0 + "px";
    element.style.height = contentRect.size.height;
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
    window.setTimeout(function() { [[self window] makeFirstResponder:self]; }, 2.0);
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

+ (CPString)themeClass
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
    var size = CGRectMakeZero(),
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
    [_tokenField mouseDown:anEvent];
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

+ (CPString)themeClass
{
    return "tokenfield-token-close-button";
}

@end
