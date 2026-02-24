/*
 *  CPTextView.j
 *  AppKit
 *
 *  Created by Daniel Boehringer on 27/12/2013.
 *  All modifications copyright Daniel Boehringer 2013.
 *  Extensive code formatting and review by Andrew Hankinson
 *  Based on original work by
 *  Created by Emmanuel Maillard on 27/02/2010.
 *  Copyright Emmanuel Maillard 2010.
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

@import "CPText.j"
@import "CPPasteboard.j"
@import "CPColorPanel.j"
@import "CPFontManager.j"
@import "CPTextStorage.j"
@import "CPTextContainer.j"
@import "CPLayoutManager.j"

@import "_CPRTFParser.j"
@import "_CPRTFProducer.j"


@class CPClipView;
@class CPMenu;
@class _CPSelectionBox;
@class _CPCaret;
@class _CPNativeInputManager;

@protocol CPTextViewDelegate <CPTextDelegate>

@optional
- (BOOL)textView:(CPTextView)aTextView doCommandBySelector:(SEL)aSelector;
- (BOOL)textView:(CPTextView)aTextView shouldChangeTextInRange:(CPRange)affectedCharRange replacementString:(CPString)replacementString;
- (CPDictionary)textView:(CPTextView)textView shouldChangeTypingAttributes:(CPDictionary)oldTypingAttributes toAttributes:(CPDictionary)newTypingAttributes;
- (CPRange)textView:(CPTextView)aTextView willChangeSelectionFromCharacterRange:(CPRange)oldSelectedCharRange toCharacterRange:(CPRange)newSelectedCharRange;
- (void)textViewDidChangeSelection:(CPNotification)aNotification;
- (void)textViewDidChangeTypingAttributes:(CPNotification)aNotification;
- (CPMenu)textView:(CPTextView)view menu:(CPMenu)menu forEvent:(CPEvent)event atIndex:(unsigned)charIndex;

@end

@global document

_MakeRangeFromAbs = function(a1, a2)
{
    return (a1 < a2) ? CPMakeRange(a1, a2 - a1) : CPMakeRange(a2, a1 - a2);
};

_MidRange = function(a1)
{
    return Math.floor((CPMaxRange(a1) + a1.location) / 2);
};

function _isWhitespaceCharacter(chr)
{
    return (chr === '\n' || chr === '\r' || chr === ' ' || chr === '\t');
}

_characterTripletFromStringAtIndex = function(string, index)
{
    if ([string isKindOfClass:CPAttributedString])
        string = string._string;

    var tripletRange = _MakeRangeFromAbs(MAX(0, index - 1), MIN(string.length, index + 2));

    return [string substringWithRange:tripletRange];
}

_regexMatchesStringAtIndex=function(regex, string, index)
{
    var triplet = _characterTripletFromStringAtIndex(string, index);

    return regex.exec(triplet)  !== null;
}


/*
    CPSelectionGranularity
*/
@typedef CPSelectionGranularity
CPSelectByCharacter = 0;
CPSelectByWord      = 1;
CPSelectByParagraph = 2;

var kDelegateRespondsTo_textShouldBeginEditing                                          = 1 << 0,
    kDelegateRespondsTo_textShouldEndEditing                                            = 1 << 1,
    kDelegateRespondsTo_textView_doCommandBySelector                                    = 1 << 2,
    kDelegateRespondsTo_textView_willChangeSelectionFromCharacterRange_toCharacterRange = 1 << 3,
    kDelegateRespondsTo_textView_shouldChangeTextInRange_replacementString              = 1 << 4,
    kDelegateRespondsTo_textView_shouldChangeTypingAttributes_toAttributes              = 1 << 5,
    kDelegateRespondsTo_textView_textDidChange                                          = 1 << 6,
    kDelegateRespondsTo_textView_didChangeSelection                                     = 1 << 7,
    kDelegateRespondsTo_textView_didChangeTypingAttributes                              = 1 << 8,
    kDelegateRespondsTo_textView_textDidBeginEditing                                    = 1 << 9,
    kDelegateRespondsTo_textView_textDidEndEditing                                      = 1 << 10;
    kDelegateRespondsTo_textView_menu_forEvent_atIndex                                  = 1 << 11;

@class _CPCaret;

/*!
    @ingroup appkit
    @class CPTextView
    Copy / Paste is only fully supported with a CPMenu (can be hidden)
*/
@implementation CPTextView : CPText
{
    BOOL                        _allowsUndo                   @accessors(property=allowsUndo);
    BOOL                        _isHorizontallyResizable      @accessors(getter=isHorizontallyResizable, setter=setHorizontallyResizable:);
    BOOL                        _isVerticallyResizable        @accessors(getter=isVerticallyResizable, setter=setVerticallyResizable:);
    BOOL                        _usesFontPanel                @accessors(property=usesFontPanel);
    CGPoint                     _textContainerOrigin          @accessors(getter=textContainerOrigin);
    CGSize                      _minSize                      @accessors(property=minSize);
    CGSize                      _maxSize                      @accessors(property=maxSize);
    CGSize                      _textContainerInset           @accessors(property=textContainerInset);
    CPColor                     _insertionPointColor          @accessors(property=insertionPointColor);
    CPColor                     _textColor                    @accessors(property=textColor);
    CPDictionary                _selectedTextAttributes       @accessors(property=selectedTextAttributes);
    CPDictionary                _typingAttributes             @accessors(property=typingAttributes);
    CPFont                      _font;
    CPLayoutManager             _layoutManager                @accessors(getter=layoutManager);
    CPRange                     _selectionRange               @accessors(getter=selectedRange);
    CPSelectionGranularity      _selectionGranularity         @accessors(property=selectionGranularity);

    CPSelectionGranularity      _previousSelectionGranularity;  // private

    CPTextContainer             _textContainer                @accessors(property=textContainer);
    CPTextStorage               _textStorage                  @accessors(getter=textStorage);
    id <CPTextViewDelegate>     _delegate                     @accessors(property=delegate);

    unsigned                    _delegateRespondsToSelectorMask;

    int                         _startTrackingLocation;

    _CPCaret                    _caret;
    CPTimer                     _scrollingTimer;

    BOOL                        _scrollingDownward;
    CPRange                     _movingSelection;

    int                         _stickyXLocation;

    CPArray                     _selectionSpans;
    CPView                      _observedClipView;
    CGRect                      _exposedRect;

    CPTimer                     _scrollingTimer;

    CPString                    _placeholderString;

    BOOL                        _firstResponderButNotEditingYet;

    CPRange                     _mouseDownOldSelection;
}

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding === CPValueBinding || aBinding === CPAttributedStringBinding)
        return [_CPTextViewValueBinder class];

    return [super _binderClassForBinding:aBinding];
}

+ (CPMenu)defaultMenu
{
    var editMenu = [CPMenu new];

    // FIXME I8N
    [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];

    [editMenu setAutoenablesItems:NO]

    return editMenu;
}

#pragma mark -
#pragma mark Class methods

// ADDED: Theming support
+ (CPString)defaultThemeClass
{
    return @"textview";
}

+ (CPDictionary)themeAttributes
{
    return @{
            @"background-color": [CPColor textBackgroundColor],
            @"content-inset": CGSizeMake(2, 0),
            @"text-color": [CPColor textColor]
        };
}

/* <!> FIXME
    just a testing characterSet
    all of this depend of the current language.
    Need some CPLocale support and maybe even a FSM...
 */

#pragma mark -
#pragma mark Init methods

- (id)initWithFrame:(CGRect)aFrame textContainer:(CPTextContainer)aContainer
{
    if (self = [super initWithFrame:aFrame])
    {
        [self _init];
        [aContainer setTextView:self];

        [self setEditable:YES];
        [self setSelectable:YES];
        [self setRichText:NO];
        // Removed hardcoded background color. Theming now handles this via _updateThemeState,
        // which is triggered by setEditable: during initialization.

        _usesFontPanel = YES;
        _allowsUndo = YES;

        _selectedTextAttributes = [CPDictionary dictionaryWithObject:[CPColor selectedTextBackgroundColor]
                                                              forKey:CPBackgroundColorAttributeName];

        _insertionPointColor = [CPColor insertionPointColor];

        _textColor = [CPColor textColor];
        _font = [CPFont systemFontOfSize:12.0];
        [self setFont:_font];

        _typingAttributes = [[CPDictionary alloc] initWithObjects:[_font, _textColor] forKeys:[CPFontAttributeName, CPForegroundColorAttributeName]];
   }

    return self;
}

- (id)initWithFrame:(CGRect)aFrame
{
    var container = [[CPTextContainer alloc] initWithContainerSize:CGSizeMake(aFrame.size.width, 1e7)];

    return [self initWithFrame:aFrame textContainer:container];
}

- (void)_init
{
#if PLATFORM(DOM)
        _DOMElement.style.cursor = "text";
#endif

    _selectionRange = CPMakeRange(0, 0);
    // The text container inset is now set from the theme in _updateThemeState.
    // We set a default here, which will be overridden by the theme on initialization.
    _textContainerInset = CGSizeMake(2, 0);
    _textContainerOrigin = CGPointMake(_bounds.origin.x, _bounds.origin.y);

    _selectionGranularity = CPSelectByCharacter;

    _minSize = CGSizeCreateCopy(_frame.size);
    _maxSize = CGSizeMake(_frame.size.width, 1e7);

    _isVerticallyResizable = YES;
    _isHorizontallyResizable = NO;

    _typingAttributes = [CPMutableDictionary new];
    _selectedTextAttributes = [CPMutableDictionary new];

    _caret = [[_CPCaret alloc] initWithTextView:self];
    [_caret setRect:CGRectMake(0, 0, 1, 11)];

    var pboardTypes = [CPStringPboardType, CPColorDragType];

    if ([self isRichText])
        pboardTypes.push(CPRTFPboardType);

    [self registerForDraggedTypes:pboardTypes];
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

- (void)_removeObservers
{
    if (!_isObserving)
        return;

    [super _removeObservers];
    [self _setObserveWindowKeyNotifications:NO];
    [self _removeDelegateObservers];
}

- (void)_addObservers
{
    if (_isObserving)
        return;

    [super _addObservers];
    [self _setObserveWindowKeyNotifications:YES];
    [self _startObservingClipView];
    [self _addDelegateObservers];
}

- (void)_addDelegateObservers
{
    if (!_delegate) return;

    var nc = [CPNotificationCenter defaultCenter];

    if (_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_textDidBeginEditing)
        [nc addObserver:_delegate selector:@selector(textDidBeginEditing:) name:CPTextDidBeginEditingNotification object:self];

    if (_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_textDidChange)
        [nc addObserver:_delegate selector:@selector(textDidChange:) name:CPTextDidChangeNotification object:self];

    if (_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_textDidEndEditing)
        [nc addObserver:_delegate selector:@selector(textDidEndEditing:) name:CPTextDidEndEditingNotification object:self];

    if (_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_didChangeSelection)
        [nc addObserver:_delegate selector:@selector(textViewDidChangeSelection:) name:CPTextViewDidChangeSelectionNotification object:self];

    if (_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_didChangeTypingAttributes)
        [nc addObserver:_delegate selector:@selector(textViewDidChangeTypingAttributes:) name:CPTextViewDidChangeTypingAttributesNotification object:self];
}

- (void)_removeDelegateObservers
{
    if (!_delegate) return;

    var nc = [CPNotificationCenter defaultCenter];

    if (_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_textDidBeginEditing)
        [nc removeObserver:_delegate name:CPTextDidBeginEditingNotification object:self];

    if (_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_textDidChange)
        [nc removeObserver:_delegate name:CPTextDidChangeNotification object:self];

    if (_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_textDidEndEditing)
        [nc removeObserver:_delegate name:CPTextDidEndEditingNotification object:self];

    if (_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_didChangeSelection)
        [nc removeObserver:_delegate name:CPTextViewDidChangeSelectionNotification object:self];

    if (_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_didChangeTypingAttributes)
        [nc removeObserver:_delegate name:CPTextViewDidChangeTypingAttributesNotification object:self];
}

- (void)_startObservingClipView
{
    if (!_observedClipView)
        return;

    var defaultCenter = [CPNotificationCenter defaultCenter];

    [_observedClipView setPostsFrameChangedNotifications:YES];
    [_observedClipView setPostsBoundsChangedNotifications:YES];

    [defaultCenter addObserver:self
                      selector:@selector(superviewFrameChanged:)
                          name:CPViewFrameDidChangeNotification
                        object:_observedClipView];

    [defaultCenter addObserver:self
                      selector:@selector(superviewBoundsChanged:)
                          name:CPViewBoundsDidChangeNotification
                        object:_observedClipView];
}
- (CGRect)exposedRect
{
    if (!_exposedRect)
    {
        var superview = [self superview];

        if ([superview isKindOfClass:[CPClipView class]])
            _exposedRect = [superview bounds];
        else
            _exposedRect = [self bounds];
    }

    return _exposedRect;
}

/*!
    @ignore
*/
- (void)superviewBoundsChanged:(CPNotification)aNotification
{
    _exposedRect = nil;
    [self setNeedsDisplay:YES];
}

/*!
    @ignore
*/
- (void)superviewFrameChanged:(CPNotification)aNotification
{
    _exposedRect = nil;
}

- (void)viewWillMoveToSuperview:(CPView)aView
{
    if ([aView isKindOfClass:[CPClipView class]])
        _observedClipView = aView;
    else
        [self _stopObservingClipView];

    [super viewWillMoveToSuperview:aView];
}

- (void)_stopObservingClipView
{
    if (!_observedClipView)
        return;

    var defaultCenter = [CPNotificationCenter defaultCenter];

    [defaultCenter removeObserver:self
                             name:CPViewFrameDidChangeNotification
                           object:_observedClipView];

    [defaultCenter removeObserver:self
                             name:CPViewBoundsDidChangeNotification
                           object:_observedClipView];

    _observedClipView = nil;
}

- (void)_windowDidResignKey:(CPNotification)aNotification
{
    if (![[self window] isKeyWindow])
        [self _resignFirstResponder];
}

- (void)_windowDidBecomeKey:(CPNotification)aNotification
{
    if ([self _isFocused])
        [self _becomeFirstResponder];
}

#pragma mark -
#pragma mark Copy and paste methods

- (void)copy:(id)sender
{
    [super copy:sender];

    var selectedRange = [self selectedRange],
        pasteboard = [CPPasteboard generalPasteboard],
        stringForPasting = [[self textStorage] attributedSubstringFromRange:CPMakeRangeCopy(selectedRange)],
        richData = [_CPRTFProducer produceRTF:stringForPasting documentAttributes:@{}];

    if ([self isRichText])
    {
        [pasteboard declareTypes:[CPStringPboardType, CPRTFPboardType, _CPSmartPboardType, _CPASPboardType] owner:nil];
        [pasteboard setString:[stringForPasting._string stringByReplacingOccurrencesOfString:_CPAttachmentCharacterAsString withString:''] forType:CPStringPboardType];
        [pasteboard setString:richData forType:CPRTFPboardType];
        [pasteboard setString:_previousSelectionGranularity + '' forType:_CPSmartPboardType];
        [pasteboard setString:[[CPKeyedArchiver archivedDataWithRootObject:stringForPasting] rawString] forType:_CPASPboardType];
    }
    else
    {
        [pasteboard declareTypes:[CPStringPboardType, _CPSmartPboardType] owner:nil];
        [pasteboard setString:stringForPasting._string forType:CPStringPboardType];
        [pasteboard setString:_previousSelectionGranularity + '' forType:_CPSmartPboardType];
    }
}

- (void)_pasteString:(id)stringForPasting
{
    if (!stringForPasting)
        return;

    var shouldUseSmartPasting = [self _shouldUseSmartPasting];

    if (shouldUseSmartPasting)
    {
        if (_isWhitespaceCharacter([[stringForPasting string] characterAtIndex:0]))
        {
            if (_selectionRange.location == 0 ||
                _isWhitespaceCharacter([[_textStorage string] characterAtIndex:_selectionRange.location - 1]) &&
                _selectionRange.location != [_layoutManager numberOfCharacters])
                [stringForPasting deleteCharactersInRange:CPMakeRange(0, 1)];
        }
        else
        {
            if (_selectionRange.location > 0 &
                !_isWhitespaceCharacter([[_textStorage string] characterAtIndex:_selectionRange.location - 1]))
                [self insertText:" "];
        }
    }

    [self insertText:stringForPasting];

    if (shouldUseSmartPasting)
    {
        if (!_isWhitespaceCharacter([[_textStorage string] characterAtIndex:CPMaxRange(_selectionRange)]) &&
            !_isNewlineCharacter([[_textStorage string] characterAtIndex:MAX(0, _selectionRange.location - 1)]) &&
            _selectionRange.location != [_layoutManager numberOfCharacters])
        {
            [self insertText:" "];
        }
    }
}
- (void)pasteAsPlainText:(id)sender
{
    if (![sender isKindOfClass:_CPNativeInputManager] && [[CPApp currentEvent] type] != CPAppKitDefined)
        return

    [self _pasteString:[self _plainStringForPasting]];
}

- (void)paste:(id)sender
{
    if ([[CPApp currentEvent] type] != CPAppKitDefined)
        return;

    [self _pasteString:[self _stringForPasting]];
}

#pragma mark -
#pragma mark Responders method

- (BOOL)acceptsFirstResponder
{
    return [self isSelectable]; // editable textviews are automatically selectable
}

- (BOOL)acceptsFirstMouse:(CPEvent)anEvent
{
    return YES;
}

- (void)_becomeFirstResponder
{
    [self updateInsertionPointStateAndRestartTimer:YES];
    [[CPFontManager sharedFontManager] setSelectedFont:[self font] isMultiple:NO];
    [self setNeedsDisplay:YES];
    [[CPRunLoop currentRunLoop] performSelector:@selector(focusForTextView:) target:[_CPNativeInputManager class] argument:self order:0 modes:[CPDefaultRunLoopMode]];
}


- (BOOL)becomeFirstResponder
{
    [super becomeFirstResponder];
    _firstResponderButNotEditingYet = YES;
    [self _becomeFirstResponder];

    return YES;
}

- (void)_resignFirstResponder
{
    [self _reverseSetBinding];
    [_caret stopBlinking];
    [self setNeedsDisplay:YES];
    [_CPNativeInputManager cancelCurrentInputSessionIfNeeded];
}

- (BOOL)resignFirstResponder
{
    if (_firstResponderButNotEditingYet)
        _firstResponderButNotEditingYet = NO;
    else
    {
        if ([self _sendDelegateTextShouldEndEditing])
            [[CPNotificationCenter defaultCenter] postNotificationName:CPTextDidEndEditingNotification object:self];
        else
            return NO;
    }

    [self _resignFirstResponder];

    // Call super to ensure proper responder chain cleanup and theme state update (removes CPThemeStateEditing).
    [super resignFirstResponder];

    return YES;
}


#pragma mark -
#pragma mark Delegate methods

/*!
    TODO : documentation
*/
- (void)setDelegate:(id <CPTextViewDelegate>)aDelegate
{
    if (aDelegate === _delegate)
        return;

    [self _removeDelegateObservers];

    _delegateRespondsToSelectorMask = 0;
    _delegate = aDelegate;

    if (_delegate)
    {
        if ([_delegate respondsToSelector:@selector(textDidChange:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textView_textDidChange;

        if ([_delegate respondsToSelector:@selector(textViewDidChangeSelection:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textView_didChangeSelection;

        if ([_delegate respondsToSelector:@selector(textViewDidChangeTypingAttributes:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textView_didChangeTypingAttributes;

        if ([_delegate respondsToSelector:@selector(textDidBeginEditing:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textView_textDidBeginEditing;

        if ([_delegate respondsToSelector:@selector(textDidEndEditing:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textView_textDidEndEditing;

        if ([_delegate respondsToSelector:@selector(textView:doCommandBySelector:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textView_doCommandBySelector;

        if ([_delegate respondsToSelector:@selector(textShouldBeginEditing:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textShouldBeginEditing;

        if ([_delegate respondsToSelector:@selector(textShouldEndEditing:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textShouldEndEditing;

        if ([_delegate respondsToSelector:@selector(textView:willChangeSelectionFromCharacterRange:toCharacterRange:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textView_willChangeSelectionFromCharacterRange_toCharacterRange;

        if ([_delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementString:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textView_shouldChangeTextInRange_replacementString;

        if ([_delegate respondsToSelector:@selector(textView:shouldChangeTypingAttributes:toAttributes:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textView_shouldChangeTypingAttributes_toAttributes;

        if ([_delegate respondsToSelector:@selector(textView:menu:forEvent:atIndex:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textView_menu_forEvent_atIndex;

        if (_superview)
            [self _addDelegateObservers];
    }
}


#pragma mark -
#pragma mark Key window methods

- (void)becomeKeyWindow
{
    [self setNeedsDisplay:YES];
}

/*!
    @ignore
*/
- (void)resignKeyWindow
{
    [self setNeedsDisplay:YES];
}

- (BOOL)_isFirstResponder
{
   return [[self window] firstResponder] === self;
}

- (BOOL)_isFocused
{
   return [[self window] isKeyWindow] && [self _isFirstResponder];
}


#pragma mark -
#pragma mark Undo redo methods

- (void)undo:(id)sender
{
    if (_allowsUndo)
        [[[self window] undoManager] undo];
}

- (void)redo:(id)sender
{
    if (_allowsUndo)
        [[[self window] undoManager] redo];
}


#pragma mark -
#pragma mark Accessors

- (CPString)stringValue
{
    return _textStorage._string;
}

- (CPString)objectValue
{
    if (_placeholderString)
        return nil;

    return [self isRichText]? _textStorage : _textStorage._string;
}
- (void)setObjectValue:(id)aValue
{
    if (_placeholderString)
        return;

    if (!aValue)
        aValue = @"";

    if (![aValue isKindOfClass:[CPAttributedString class]] && ![aValue isKindOfClass:[CPString class]] && [aValue respondsToSelector:@selector(description)])
        aValue = [aValue description];

    [self setString:aValue];
}

- (void)setString:(CPString)aString
{
    if ([aString isKindOfClass:[CPAttributedString class]])
    {
        [_textStorage replaceCharactersInRange:CPMakeRange(0, [_layoutManager numberOfCharacters]) withAttributedString:aString];
    }
    else
    {
        [_textStorage replaceCharactersInRange:CPMakeRange(0, [_layoutManager numberOfCharacters]) withString:aString];
    }

    if (CPMaxRange(_selectionRange) > [_layoutManager numberOfCharacters])
        [self setSelectedRange:CPMakeRange([_layoutManager numberOfCharacters], 0)];

    [self didChangeText];
    [_layoutManager _validateLayoutAndGlyphs];
    [self sizeToFit];
    [self setNeedsDisplay:YES];
}

- (CPString)string
{
    return [_textStorage string];
}

// ADDED: Override setEditable to manage theme state
- (void)setEditable:(BOOL)aFlag
{
    [super setEditable:aFlag];

    if (![self isEditable])
        [self setThemeState:CPThemeStateDisabled];
    else
        [self unsetThemeState:CPThemeStateDisabled];
}

- (void)setTextContainer:(CPTextContainer)aContainer
{
    _textContainer = aContainer;
    _layoutManager = [_textContainer layoutManager];
    _textStorage = [_layoutManager textStorage];
    [_textStorage setFont:[self font]];
    [_textStorage setForegroundColor:_textColor];

    [self invalidateTextContainerOrigin];
}

- (void)setTextContainerInset:(CGSize)aSize
{
    _textContainerInset = aSize;
    [self invalidateTextContainerOrigin];
    [self setNeedsDisplay:YES];
}

- (void)invalidateTextContainerOrigin
{
    _textContainerOrigin.x = _bounds.origin.x;
    _textContainerOrigin.x += _textContainerInset.width;

    _textContainerOrigin.y = _bounds.origin.y;
    _textContainerOrigin.y += _textContainerInset.height;
}

- (void)doCommandBySelector:(SEL)aSelector
{
    if (![self _sendDelegateDoCommandBySelector:aSelector])
        [super doCommandBySelector:aSelector];
}

- (void)didChangeText
{
    [[CPNotificationCenter defaultCenter] postNotificationName:CPTextDidChangeNotification object:self];
}

- (BOOL)_didBeginEditing
{
    if (_firstResponderButNotEditingYet)
    {
        if ([self _sendDelegateTextShouldBeginEditing])
        {
            [[CPNotificationCenter defaultCenter] postNotificationName:CPTextDidBeginEditingNotification object:self];
            _firstResponderButNotEditingYet = NO;
        } else
            return NO;
    }

    return YES;
}

- (BOOL)shouldChangeTextInRange:(CPRange)aRange replacementString:(CPString)aString
{
    if (![self isEditable])
        return NO;

    return [self _sendDelegateShouldChangeTextInRange:aRange replacementString:aString];
}


#pragma mark -
#pragma mark Insert characters methods

- (void)_fixupReplaceForRange:(CPRange)aRange
{
    [self setSelectedRange:aRange];
    [_layoutManager _validateLayoutAndGlyphs];
    [self sizeToFit];
    [self scrollRangeToVisible:_selectionRange];
    [self setNeedsDisplay:YES];
}

- (void)_replaceCharactersInRange:(CPRange)aRange withAttributedString:(CPString)aString selectionRange:(CPRange)selectionRange
{
    [[[[self window] undoManager] prepareWithInvocationTarget:self]
                _replaceCharactersInRange:CPMakeRange(aRange.location, [aString length])
                     withAttributedString:[_textStorage attributedSubstringFromRange:CPMakeRangeCopy(aRange)]
                           selectionRange:CPMakeRangeCopy(_selectionRange)];

    [_textStorage replaceCharactersInRange:aRange withAttributedString:aString];
    [self _fixupReplaceForRange:selectionRange];
}

- (void)insertText:(CPString)aString
{
    var isAttributed = [aString isKindOfClass:CPAttributedString],
        string = isAttributed ? [aString string]:aString;

    if (![self _didBeginEditing] || ![self shouldChangeTextInRange:CPMakeRangeCopy(_selectionRange) replacementString:string])
        return;

    if (!isAttributed)
        aString = [[CPAttributedString alloc] initWithString:aString attributes:_typingAttributes];
    else if (![self isRichText])
        aString = [[CPAttributedString alloc] initWithString:string attributes:_typingAttributes];

    var undoManager = [[self window] undoManager];
    [undoManager setActionName:@"Replace/insert text"];

    [[undoManager prepareWithInvocationTarget:self]
                    _replaceCharactersInRange:CPMakeRange(_selectionRange.location, [aString length])
                         withAttributedString:[_textStorage attributedSubstringFromRange:CPMakeRangeCopy(_selectionRange)]
                               selectionRange:CPMakeRangeCopy(_selectionRange)];

    [self willChangeValueForKey:@"objectValue"];
    [_textStorage replaceCharactersInRange:CPMakeRangeCopy(_selectionRange) withAttributedString:aString];
    [self didChangeValueForKey:@"objectValue"];
    [self _continuouslyReverseSetBinding];

    [self _setSelectedRange:CPMakeRange(_selectionRange.location + [string length], 0) affinity:0 stillSelecting:NO overwriteTypingAttributes:NO];
    _startTrackingLocation = _selectionRange.location;

    [self didChangeText];
    [_layoutManager _validateLayoutAndGlyphs];
    [self sizeToFit];
    [self scrollRangeToVisible:_selectionRange];
    _stickyXLocation = MAX(0, _caret._rect.origin.x - 1);
}

#pragma mark -
#pragma mark Drawing methods

- (void)drawInsertionPointInRect:(CGRect)aRect color:(CPColor)aColor turnedOn:(BOOL)flag
{
    [_caret setRect:aRect];
    [_caret setVisibility:flag stop:NO];
}

- (void)displayRectIgnoringOpacity:(CGRect)aRect inContext:(CPGraphicsContext)aGraphicsContext
{   if ([self isHidden])
       return;

    [self drawRect:aRect];
}

- (void)drawRect:(CGRect)aRect
{
#if PLATFORM(DOM)
    var range = [_layoutManager glyphRangeForBoundingRect:aRect inTextContainer:_textContainer];

    for (var i = 0; i < [_selectionSpans count]; i++)
        [_selectionSpans[i] removeFromTextView];

    _selectionSpans = [];

    if (_selectionRange.length)
    {
        var rects = [_layoutManager rectArrayForCharacterRange:_selectionRange
                                  withinSelectedCharacterRange:_selectionRange
                                               inTextContainer:_textContainer
                                                     rectCount:nil],
            effectiveSelectionColor = [self _isFocused] ? [_selectedTextAttributes objectForKey:CPBackgroundColorAttributeName] : [CPColor _selectedTextBackgroundColorUnfocussed],
            lengthRect = rects.length;

        for (var i = 0; i < lengthRect; i++)
        {
            rects[i].origin.x += _textContainerOrigin.x;
            rects[i].origin.y += _textContainerOrigin.y;

            var newSpan = [[_CPSelectionBox alloc] initWithTextView:self rect:rects[i] color:effectiveSelectionColor];
            [_selectionSpans addObject:newSpan];
        }
    }

    if (range.length)
        [_layoutManager drawGlyphsForGlyphRange:range atPoint:_textContainerOrigin];

    if ([self shouldDrawInsertionPoint])
    {
        [self updateInsertionPointStateAndRestartTimer:NO];
        [self drawInsertionPointInRect:_caret._rect color:_insertionPointColor turnedOn:_caret._drawCaret];
    }
    else
        [_caret setVisibility:NO];
#endif
}

- (void)_updateThemeState
{
    [super _updateThemeState];

#if PLATFORM(DOM)
    // Allow themes to use background images/patterns by making the element background transparent.
    _DOMElement.style.background = "transparent";
#endif

    // Apply the background color from the theme.
    [self setBackgroundColor:[self currentValueForThemeAttribute:@"background-color"]];

    // Apply the content inset from the theme.
    var inset = [self currentValueForThemeAttribute:@"content-inset"] || CGSizeMakeZero();
    if (!CGSizeEqualToSize(inset, _textContainerInset))
        [self setTextContainerInset:inset];
}


#pragma mark -
#pragma mark Select methods

- (void)selectAll:(id)sender
{
    if ([self isSelectable])
    {
        [_caret stopBlinking];
        [self setSelectedRange:CPMakeRange(0, [_layoutManager numberOfCharacters])];
    }
}

/*!
Sets the selection to a range of characters in response to user action.
@param range The range of characters to select. This range must begin and end on glyph boundaries and not split base glyphs and their nonspacing marks.
*/
- (void)setSelectedRange:(CPRange)range
{
    [_CPNativeInputManager cancelCurrentInputSessionIfNeeded];
    [self setSelectedRange:range affinity:0 stillSelecting:NO];
}

/*!
Sets the selection to a range of characters in response to user action.
@param range The range of characters to select. This range must begin and end on glyph boundaries and not split base glyphs and their nonspacing marks.
@param affinity The selection affinity for the selection. See selectionAffinity for more information about how affinities work.
@param selecting YES to behave appropriately for a continuing selection where the user is still dragging the mouse, NO otherwise. If YES, the receiver doesn’t send notifications or remove the marking from its marked text. If NO, the receiver posts an NSTextViewDidChangeSelectionNotification to the default notification center and removes the marking from marked text if the new selection is greater than the marked region.
*/
- (void)setSelectedRange:(CPRange)range affinity:(CPSelectionAffinity)affinity stillSelecting:(BOOL)selecting
{
    [self _setSelectedRange:range affinity:affinity stillSelecting:selecting overwriteTypingAttributes:YES];
}


/*!
Sets the selection to a range of characters in response to user action.
@param range The range of characters to select. This range must begin and end on glyph boundaries and not split base glyphs and their nonspacing marks.
@param affinity The selection affinity for the selection. See selectionAffinity for more information about how affinities work.
@param selecting YES to behave appropriately for a continuing selection where the user is still dragging the mouse, NO otherwise. If YES, the receiver doesn’t send notifications or remove the marking from its marked text. If NO, the receiver posts an NSTextViewDidChangeSelectionNotification to the default notification center and removes the marking from marked text if the new selection is greater than the marked region.
@param doOverwrite YES to override typing attributes. NO to not override.
*/
- (void)_setSelectedRange:(CPRange)range affinity:(CPSelectionAffinity)affinity stillSelecting:(BOOL)selecting overwriteTypingAttributes:(BOOL)doOverwrite
{
    var maxRange = CPMakeRange(0, [_layoutManager numberOfCharacters]),
        newSelectionRange;

    range = CPIntersectionRange(maxRange, range);

    if (!selecting && [self _delegateRespondsToWillChangeSelectionFromCharacterRangeToCharacterRange])
    {
        newSelectionRange = [self _sendDelegateWillChangeSelectionFromCharacterRange:_selectionRange toCharacterRange:range];
    }
    else
    {
        newSelectionRange = [self selectionRangeForProposedRange:range granularity:[self selectionGranularity]];
    }

    var isNewSelection = !CPEqualRanges(newSelectionRange, _selectionRange);

    if (isNewSelection)
        _selectionRange = newSelectionRange;

    if (newSelectionRange.length)
    {
        if (isNewSelection)
            [_layoutManager invalidateDisplayForGlyphRange:newSelectionRange];
    }
    else
        [self setNeedsDisplay:YES];

    if (!selecting)
    {
        if ([self _isFirstResponder])
            [self updateInsertionPointStateAndRestartTimer:((newSelectionRange.length === 0) && ![_caret isBlinking])];

        // If there is no new selection but the pervious mouseDown has saved a selection we check against the saved selection instead
        if (!isNewSelection && _mouseDownOldSelection)
            isNewSelection = !CPEqualRanges(newSelectionRange, _mouseDownOldSelection);

        if (doOverwrite && _placeholderString == nil && isNewSelection)
            [self setTypingAttributes:[_textStorage attributesAtIndex:CPMaxRange(range) effectiveRange:nil]];

        [[CPNotificationCenter defaultCenter] postNotificationName:CPTextViewDidChangeSelectionNotification object:self];
    }

    if (!selecting && newSelectionRange.length > 0)
       [_CPNativeInputManager focusForClipboardOfTextView:self];
}

#if PLATFORM(DOM)
- (CGPoint)_cumulativeOffset
{
    var top = 0,
        left = 0,
        element = self._DOMElement;

    do
    {
        top += element.offsetTop  || 0;
        left += element.offsetLeft || 0;
        element = element.offsetParent;
    }
    while(element);

    return CGPointMake(left, top);
}
#endif

- (CPArray)selectedRanges
{
    return [_selectionRange];
}

#pragma mark -
#pragma mark Keyboard events

- (void)keyDown:(CPEvent)event
{
    [[_window platformWindow] _propagateCurrentDOMEvent:YES];

    if ([event _isActionOrCommandEvent])
    {
        // This is a navigation key, action key, or command shortcut.
        // Let the Cappuccino framework's key binding system handle it.
        [self interpretKeyEvents:[event]];
    }

    // This is a normal printable character ('a', '1', '$', 'é').
    // We do nothing, preventing the double-insertion bug. The _CPNativeInputManager
    // will capture it from the hidden input field and insert it correctly.

    [_caret setPermanentlyVisible:YES];
}

- (void)keyUp:(CPEvent)event
{
    [super keyUp:event];

    setTimeout(function() {
                              [_caret setPermanentlyVisible:NO];
                          }, 1000);
}

- (CGPoint)_characterIndexFromRawPoint:(CGPoint)point
{
    var fraction = [],
        point = [self convertPoint:point fromView:nil];

    // convert to container coordinate
    point.x -= _textContainerOrigin.x;
    point.y -= _textContainerOrigin.y;

    var index = [_layoutManager glyphIndexForPoint:point inTextContainer:_textContainer fractionOfDistanceThroughGlyph:fraction];

    if (index === CPNotFound)
        index = [_layoutManager numberOfCharacters];
    else if (fraction[0] > 0.5)
        index++;

    return index;
}
- (CGPoint)_characterIndexFromEvent:(CPEvent)event
{
    return [self _characterIndexFromRawPoint:[event locationInWindow]];
}

- (BOOL)needsPanelToBecomeKey
{
    return YES;
}

- (void)_hideRange:(CPRange)rangeToHide inDragPlaceholderString:(CPTextView)placeholderString
{
    if (!rangeToHide.length)
        return;

    [placeholderString addAttribute:CPForegroundColorAttributeName
                              value:[CPColor colorWithRed:1 green:1 blue:1 alpha:0] // invisibleInk
                              range:rangeToHide];
    [placeholderString addAttribute:_CPAttachmentInvisible value:YES range:rangeToHide];
}

#pragma mark -
#pragma mark Mouse Events

- (void)mouseDown:(CPEvent)event
{
    if (![self isSelectable])
        return;

    // this is for the ipad-keyboard
    [_CPNativeInputManager focusForClipboardOfTextView:self];

    [_CPNativeInputManager cancelCurrentInputSessionIfNeeded];
    [_caret setVisibility:NO];

    _startTrackingLocation = [self _characterIndexFromEvent:event];

    var granularities = [CPNotFound, CPSelectByCharacter, CPSelectByWord, CPSelectByParagraph];
    [self setSelectionGranularity:granularities[[event clickCount]]];

    // dragging the selection
    if ([self selectionGranularity] == CPSelectByCharacter && CPLocationInRange(_startTrackingLocation, _selectionRange))
    {
        var visibleRange = [_layoutManager glyphRangeForBoundingRect:[self exposedRect] inTextContainer:_textContainer],
            firstFragment = [_layoutManager _firstLineFragmentForLineFromLocation:_selectionRange.location],
            lastFragment = [_layoutManager _lastLineFragmentForLineFromLocation:CPMaxRange(_selectionRange)],
            lineBeginningIndex = firstFragment._range.location,
            lineEndIndex = CPMaxRange(lastFragment._range),
            placeholderRange = CPIntersectionRange(_MakeRangeFromAbs(lineBeginningIndex, lineEndIndex), visibleRange),
            placeholderString = [_textStorage attributedSubstringFromRange:placeholderRange],
            placeholderFrame = CGRectIntersection([_layoutManager boundingRectForGlyphRange:placeholderRange inTextContainer:_textContainer], _frame),
            rangeToHideLHS = CPMakeRange(0, _selectionRange.location - lineBeginningIndex),
            rangeToHideRHS = _MakeRangeFromAbs(CPMaxRange(_selectionRange) - lineBeginningIndex, lineEndIndex - lineBeginningIndex),
            dragPlaceholder;

        // hide the left/right parts of the first/last lines of the selection that are not included
        [self _hideRange:rangeToHideLHS inDragPlaceholderString:placeholderString];
        [self _hideRange:rangeToHideRHS inDragPlaceholderString:placeholderString];

        _movingSelection = CPMakeRange(_startTrackingLocation, 0);

        dragPlaceholder = [[CPTextView alloc] initWithFrame:_frame];
        [dragPlaceholder._textStorage replaceCharactersInRange:CPMakeRange(0, 0) withAttributedString:placeholderString];

        // Removed hardcoded background color. The placeholder is a new CPTextView
        // instance and will be themed automatically on initialization.

        [dragPlaceholder setAlphaValue:0.5];

        var stringForPasting = [_textStorage attributedSubstringFromRange:CPMakeRangeCopy(_selectionRange)],
            draggingPasteboard = [CPPasteboard pasteboardWithName:CPDragPboard];
        [draggingPasteboard declareTypes:[_CPASPboardType, CPStringPboardType] owner:nil];
        [draggingPasteboard setString:[[CPKeyedArchiver archivedDataWithRootObject:stringForPasting] rawString] forType:_CPASPboardType];
        // this is necessary because the drag will not work without data of kind CPStringPboardType
        [draggingPasteboard setString:stringForPasting._string forType:CPStringPboardType];

        [self dragView:dragPlaceholder
                    at:placeholderFrame.origin
                offset:nil
                 event:event
            pasteboard:draggingPasteboard
                source:self
             slideBack:YES];

        return;
    }

    var setRange = CPMakeRange(_startTrackingLocation, 0);

    if ([event modifierFlags] & CPShiftKeyMask)
        setRange = _MakeRangeFromAbs(_startTrackingLocation < _MidRange(_selectionRange) ? CPMaxRange(_selectionRange) : _selectionRange.location, _startTrackingLocation);
    else
        _scrollingTimer = [CPTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_supportScrolling:) userInfo:nil repeats:YES];  // fixme: only start if we are in the scrolling areas

    // Save old selection so we can only send textViewDidChangeTypingAttribute notification when selection is changed on mouse up.
    _mouseDownOldSelection = _selectionRange;
    [self setSelectedRange:setRange affinity:0 stillSelecting:YES];
}

- (void)mouseEntered:(CPEvent)anEvent
{
    [super mouseEntered:anEvent];
    [self setThemeState:CPThemeStateHovered];
}

- (void)mouseExited:(CPEvent)anEvent
{
    [super mouseExited:anEvent];
    [self unsetThemeState:CPThemeStateHovered];
}

- (CPMenu)menuForEvent:(CPEvent)anEvent
 {
     var myMenu = [super menuForEvent:anEvent];
     if (_selectionRange.length === 0)
     {
         [[myMenu itemAtIndex:0] setEnabled:NO];
         [[myMenu itemAtIndex:1] setEnabled:NO];
     }

     if (_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_menu_forEvent_atIndex)
        myMenu = [_delegate textView:self menu:myMenu forEvent:anEvent atIndex:_selectionRange.location];

     return myMenu;
 }

- (void)_supportScrolling:(CPTimer)aTimer
{
    [self mouseDragged:[CPApp currentEvent]];
}

- (void)mouseDragged:(CPEvent)event
{
    if (![self isSelectable])
        return;

    if (_movingSelection)
        return;

    var oldRange = [self selectedRange],
        index = [self _characterIndexFromEvent:event];

    if (index > oldRange.location)
        _scrollingDownward = YES;

    if (index < CPMaxRange(oldRange))
        _scrollingDownward = NO;

    [self setSelectedRange:_MakeRangeFromAbs(index, _startTrackingLocation)
                  affinity:0
            stillSelecting:YES];

    [self scrollRangeToVisible:CPMakeRange(index, 0)];
}

// handle all the other methods from CPKeyBinding.j

- (void)mouseUp:(CPEvent)event
{
    _movingSelection = nil;

    // will post CPTextViewDidChangeSelectionNotification
    _previousSelectionGranularity = [self selectionGranularity];
    [self setSelectionGranularity:CPSelectByCharacter];
    [self setSelectedRange:[self selectedRange] affinity:0 stillSelecting:NO];
    _mouseDownOldSelection = nil;

    var point = [_layoutManager locationForGlyphAtIndex:[self selectedRange].location];
    _stickyXLocation = point.x;
    _startTrackingLocation = _selectionRange.location;

    if (_scrollingTimer)
    {
        [_scrollingTimer invalidate];
        _scrollingTimer = nil;
    }
}

- (void)moveDown:(id)sender
{
    if (![self isSelectable])
        return;

    var fraction = [],
        nglyphs = [_layoutManager numberOfCharacters],
        sindex = CPMaxRange([self selectedRange]),
        rectSource = [_layoutManager boundingRectForGlyphRange:CPMakeRange(sindex, 1) inTextContainer:_textContainer],
        rectEnd = nglyphs ? [_layoutManager boundingRectForGlyphRange:CPMakeRange(nglyphs - 1, 1) inTextContainer:_textContainer] : rectSource,
        point = rectSource.origin;

    if (_stickyXLocation)
        point.x = _stickyXLocation;

    // <!> FIXME: find a better way for getting the coordinates of the next line
    point.y += 2 + rectSource.size.height;

    var dindex = point.y >= CGRectGetMaxY(rectEnd) ? nglyphs : [_layoutManager glyphIndexForPoint:point inTextContainer:_textContainer fractionOfDistanceThroughGlyph:fraction],
        oldStickyLoc = _stickyXLocation;

    if (fraction[0] > 0.5)
        dindex++;

    [self _establishSelection:CPMakeRange(dindex, 0) byExtending:NO];
    _stickyXLocation = oldStickyLoc;
    [self scrollRangeToVisible:CPMakeRange(dindex, 0)]

}

- (void)moveDownAndModifySelection:(id)sender
{
    if (![self isSelectable])
        return;

    var oldStartTrackingLocation = _startTrackingLocation;

    [self _performSelectionFixupForRange:CPMakeRange(_selectionRange.location < _startTrackingLocation ? _selectionRange.location : CPMaxRange(_selectionRange), 0)];
    [self moveDown:sender];
    _startTrackingLocation = oldStartTrackingLocation;
    [self _performSelectionFixupForRange:_MakeRangeFromAbs(_startTrackingLocation, (_selectionRange.location < _startTrackingLocation ? _selectionRange.location : CPMaxRange(_selectionRange)))];
}

- (void)moveUp:(id)sender
{
    if (![self isSelectable])
        return;

    var dindex = [self selectedRange].location;

    if (dindex < 1)
        return;

    var rectSource = [_layoutManager boundingRectForGlyphRange:CPMakeRange(dindex, 1) inTextContainer:_textContainer];

    if (!(dindex === [_layoutManager numberOfCharacters] && _isNewlineCharacter([[_textStorage string] characterAtIndex:dindex - 1])))
        dindex = [_layoutManager glyphIndexForPoint:CGPointMake(0, rectSource.origin.y + 1) inTextContainer:_textContainer fractionOfDistanceThroughGlyph:nil];

    if (dindex < 1)
       return;

    var fraction = [];
    rectSource = [_layoutManager boundingRectForGlyphRange:CPMakeRange(dindex - 1, 1) inTextContainer:_textContainer];
    dindex = [_layoutManager glyphIndexForPoint:CGPointMake(_stickyXLocation, rectSource.origin.y + 1) inTextContainer:_textContainer fractionOfDistanceThroughGlyph:fraction];

    if (fraction[0] > 0.5)
        dindex++;

    var  oldStickyLoc = _stickyXLocation;
    [self _establishSelection:CPMakeRange(dindex,0) byExtending:NO];
    _stickyXLocation = oldStickyLoc;

    [self scrollRangeToVisible:CPMakeRange(dindex, 0)];
}

- (void)moveUpAndModifySelection:(id)sender
{
    if (![self isSelectable])
        return;

    var oldStartTrackingLocation = _startTrackingLocation;

    [self _performSelectionFixupForRange:CPMakeRange(_selectionRange.location < _startTrackingLocation ? _selectionRange.location : CPMaxRange(_selectionRange), 0)];
    [self moveUp:sender];
    _startTrackingLocation = oldStartTrackingLocation;
    [self _performSelectionFixupForRange:_MakeRangeFromAbs(_startTrackingLocation, (_selectionRange.location < _startTrackingLocation ? _selectionRange.location : CPMaxRange(_selectionRange)))];
}

- (void)_performSelectionFixupForRange:(CPRange)aSel
{
    aSel.location = MAX(0, aSel.location);

    if (CPMaxRange(aSel) > [_layoutManager numberOfCharacters])
        aSel = CPMakeRange([_layoutManager numberOfCharacters], 0);

    [self setSelectedRange:aSel];

    var point = [_layoutManager locationForGlyphAtIndex:aSel.location];

    _stickyXLocation = point.x;
}

- (void)_establishSelection:(CPSelection)aSel byExtending:(BOOL)flag
{
    if (flag)
        aSel = CPUnionRange(aSel, _selectionRange);

    [self _performSelectionFixupForRange:aSel];
    _startTrackingLocation = _selectionRange.location;
}

- (unsigned)_calculateMoveSelectionFromRange:(CPRange)aRange intoDirection:(int)move granularity:(CPSelectionGranularity)granularity
{
    var inWord = [self _isCharacterAtIndex:(move > 0 ? CPMaxRange(aRange) : aRange.location) + move granularity:granularity],
        aSel = [self selectionRangeForProposedRange:CPMakeRange((move > 0 ? CPMaxRange(aRange) : aRange.location) + move, 0) granularity:granularity],
        bSel = [self selectionRangeForProposedRange:CPMakeRange((move > 0 ? CPMaxRange(aSel) : aSel.location) + move, 0) granularity:granularity];

    return move > 0 ? CPMaxRange(inWord? aSel:bSel) : (inWord? aSel:bSel).location;
}

- (void)_moveSelectionIntoDirection:(int)move granularity:(CPSelectionGranularity)granularity
{
    var pos = [self _calculateMoveSelectionFromRange:_selectionRange intoDirection:move granularity:granularity];

    [self _performSelectionFixupForRange:CPMakeRange(pos, 0)];
    _startTrackingLocation = _selectionRange.location;
}

- (void)_extendSelectionIntoDirection:(int)move granularity:(CPSelectionGranularity)granularity
{
    var aSel = CPMakeRangeCopy(_selectionRange);

    if (granularity !== CPSelectByCharacter)
    {
        var pos = [self _calculateMoveSelectionFromRange:CPMakeRange(aSel.location < _startTrackingLocation ? aSel.location : CPMaxRange(aSel), 0)
                                           intoDirection:move
                                             granularity:granularity];
        aSel = CPMakeRange(pos, 0);
    }

    else
        aSel = CPMakeRange((aSel.location < _startTrackingLocation? aSel.location : CPMaxRange(aSel)) + move, 0);

    aSel = _MakeRangeFromAbs(_startTrackingLocation, aSel.location);
    [self _performSelectionFixupForRange:aSel];
}

- (void)moveLeftAndModifySelection:(id)sender
{
    if ([self isSelectable])
       [self _extendSelectionIntoDirection:-1 granularity:CPSelectByCharacter];
}

- (void)moveBackward:(id)sender
{
    [self moveLeft:sender];
}

- (void)moveBackwardAndModifySelection:(id)sender
{
    [self moveLeftAndModifySelection:sender];
}

- (void)moveRightAndModifySelection:(id)sender
{
    if ([self isSelectable])
       [self _extendSelectionIntoDirection:1 granularity:CPSelectByCharacter];
}

- (void)moveLeft:(id)sender
{
    if ([self isSelectable])
        [self _establishSelection:CPMakeRange(_selectionRange.location - (_selectionRange.length ? 0 : 1), 0) byExtending:NO];
}

- (void)moveToEndOfParagraph:(id)sender
{
    if (![self isSelectable])
        return;

    if (!_isNewlineCharacter([[_textStorage string] characterAtIndex:_selectionRange.location]))
       [self _moveSelectionIntoDirection:1 granularity:CPSelectByParagraph];

    if (_isNewlineCharacter([[_textStorage string] characterAtIndex:MAX(0, _selectionRange.location - 1)]))
       [self moveLeft:sender];
}

- (void)moveToEndOfParagraphAndModifySelection:(id)sender
{
    if ([self isSelectable])
       [self _extendSelectionIntoDirection:1 granularity:CPSelectByParagraph];
}

- (void)moveParagraphForwardAndModifySelection:(id)sender
{
    if ([self isSelectable])
       [self _extendSelectionIntoDirection:1 granularity:CPSelectByParagraph];
}

- (void)moveParagraphForward:(id)sender
{
    if ([self isSelectable])
       [self _moveSelectionIntoDirection:1 granularity:CPSelectByParagraph];
}

- (void)moveWordBackwardAndModifySelection:(id)sender
{
    [self moveWordLeftAndModifySelection:sender];
}

- (void)moveWordBackward:(id)sender
{
    [self moveWordLeft:sender];
}

- (void)moveWordForwardAndModifySelection:(id)sender
{
    [self moveWordRightAndModifySelection:sender];
}

- (void)moveWordForward:(id)sender
{
    [self moveWordRight:sender];
}

- (void)moveToBeginningOfDocument:(id)sender
{
    if ([self isSelectable])
         [self _establishSelection:CPMakeRange(0, 0) byExtending:NO];
}

- (void)moveToBeginningOfDocumentAndModifySelection:(id)sender
{
    if ([self isSelectable])
         [self _establishSelection:CPMakeRange(0, 0) byExtending:YES];
}

- (void)moveToEndOfDocument:(id)sender
{
    if ([self isSelectable])
         [self _establishSelection:CPMakeRange([_layoutManager numberOfCharacters], 0) byExtending:NO];
}

- (void)moveToEndOfDocumentAndModifySelection:(id)sender
{
    if ([self isSelectable])
         [self _establishSelection:CPMakeRange([_layoutManager numberOfCharacters], 0) byExtending:YES];
}

- (void)moveWordRight:(id)sender
{
    if ([self isSelectable])
        [self _moveSelectionIntoDirection:1 granularity:CPSelectByWord];
}

- (void)moveToBeginningOfParagraph:(id)sender
{
    if (![self isSelectable])
        return;

    if (!_isNewlineCharacter([[_textStorage string] characterAtIndex:MAX(0, _selectionRange.location - 1)]))
        [self _moveSelectionIntoDirection:-1 granularity:CPSelectByParagraph];
}

- (void)moveToBeginningOfParagraphAndModifySelection:(id)sender
{
    if ([self isSelectable])
       [self _extendSelectionIntoDirection:-1 granularity:CPSelectByParagraph];
}

- (void)moveParagraphBackward:(id)sender
{
    if ([self isSelectable])
        [self _moveSelectionIntoDirection:-1 granularity:CPSelectByParagraph];
}

- (void)moveParagraphBackwardAndModifySelection:(id)sender
{
    if ([self isSelectable])
       [self _extendSelectionIntoDirection:-1 granularity:CPSelectByParagraph];
}

- (void)moveWordRightAndModifySelection:(id)sender
{
    if ([self isSelectable])
         [self _extendSelectionIntoDirection:+1 granularity:CPSelectByWord];
}

- (void)deleteToEndOfParagraph:(id)sender
{
    if (![self isSelectable] || ![self isEditable])
        return;

    [self moveToEndOfParagraphAndModifySelection:self];
    [self delete:self];
}

- (void)deleteToBeginningOfParagraph:(id)sender
{
    if (![self isSelectable] || ![self isEditable])
        return;

    [self moveToBeginningOfParagraphAndModifySelection:self];
    [self delete:self];
}

- (void)deleteToBeginningOfLine:(id)sender
{
    if (![self isSelectable] || ![self isEditable])
        return;

    [self moveToLeftEndOfLineAndModifySelection:self];
    [self delete:self];
}

- (void)deleteToEndOfLine:(id)sender
{
    if (![self isSelectable] || ![self isEditable])
        return;

    [self moveToRightEndOfLineAndModifySelection:self];
    [self delete:self];
}

- (void)deleteWordBackward:(id)sender
{
    if (![self isSelectable] || ![self isEditable])
        return;

    [self moveWordLeftAndModifySelection:self];
    [self delete:self];
}

- (void)deleteWordForward:(id)sender
{
    if (![self isSelectable] || ![self isEditable])
        return;

    [self moveWordRightAndModifySelection:self];
    [self delete:self];
}

- (void)moveToLeftEndOfLine:(id)sender byExtending:(BOOL)flag
{
    if (![self isSelectable])
        return;

    var nglyphs = [_layoutManager numberOfCharacters],
        loc = nglyphs == _selectionRange.location ? MAX(0, _selectionRange.location - 1) : _selectionRange.location,
        fragment = [_layoutManager _firstLineFragmentForLineFromLocation:loc];

    if (fragment)
        [self _establishSelection:CPMakeRange(fragment._range.location, 0) byExtending:flag];
}

- (void)moveToLeftEndOfLine:(id)sender
{
    [self moveToLeftEndOfLine:sender byExtending:NO];
}

- (void)moveToLeftEndOfLineAndModifySelection:(id)sender
{
    [self moveToLeftEndOfLine:sender byExtending:YES];
}

- (void)moveToRightEndOfLine:(id)sender byExtending:(BOOL)flag
{
    if (![self isSelectable])
        return;

    var fragment = [_layoutManager _lastLineFragmentForLineFromLocation:_selectionRange.location];

    if (!fragment)
        return;

    var nglyphs = [_layoutManager numberOfCharacters],
        loc = nglyphs == CPMaxRange(fragment._range) ? nglyphs : MAX(0, CPMaxRange(fragment._range) - 1);

    [self _establishSelection:CPMakeRange(loc, 0) byExtending:flag];
}

- (void)moveToRightEndOfLine:(id)sender
{
    [self moveToRightEndOfLine:sender byExtending:NO];
}

- (void)moveToRightEndOfLineAndModifySelection:(id)sender
{
    [self moveToRightEndOfLine:sender byExtending:YES];
}

- (void)moveWordLeftAndModifySelection:(id)sender
{
    if ([self isSelectable])
        [self _extendSelectionIntoDirection:-1 granularity:CPSelectByWord];
}

- (void)moveWordLeft:(id)sender
{
    if ([self isSelectable])
        [self _moveSelectionIntoDirection:-1 granularity:CPSelectByWord];
}

- (void)moveRight:(id)sender
{
    if ([self isSelectable])
        [self _establishSelection:CPMakeRange(CPMaxRange(_selectionRange) + (_selectionRange.length ? 0 : 1), 0) byExtending:NO];
}

- (void)_deleteForRange:(CPRange)changedRange
{
    if (![self _didBeginEditing] || ![self shouldChangeTextInRange:changedRange replacementString:@""])
        return;

    changedRange = CPIntersectionRange(CPMakeRange(0, [_layoutManager numberOfCharacters]), changedRange);

    [[[_window undoManager] prepareWithInvocationTarget:self] _replaceCharactersInRange:CPMakeRange(changedRange.location, 0)
                                                                   withAttributedString:[_textStorage attributedSubstringFromRange:CPMakeRangeCopy(changedRange)]
                                                                         selectionRange:CPMakeRangeCopy(_selectionRange)];
    [self willChangeValueForKey:@"objectValue"];
    [_textStorage deleteCharactersInRange:CPMakeRangeCopy(changedRange)];
    [self didChangeValueForKey:@"objectValue"];
    [self _continuouslyReverseSetBinding];

    [self setSelectedRange:CPMakeRange(changedRange.location, 0)];
    [self didChangeText];
    [_layoutManager _validateLayoutAndGlyphs];
    [self sizeToFit];
    [self scrollRangeToVisible:CPMakeRange(changedRange.location, 0)];
    _stickyXLocation = _caret._rect.origin.x;
}

- (void)cancelOperation:(id)sender
{
    [_CPNativeInputManager cancelCurrentInputSessionIfNeeded];  // handle ESC during native input
}

- (void)deleteBackward:(id)sender handleSmart:(BOOL)handleSmart
{
    var changedRange;

    if (CPEmptyRange(_selectionRange) && _selectionRange.location > 0)
        changedRange = CPMakeRange(_selectionRange.location - 1, 1);
    else
        changedRange = _selectionRange;

    // smart delete
    if (handleSmart &&
        changedRange.location > 0 && _isWhitespaceCharacter([[_textStorage string] characterAtIndex:_selectionRange.location - 1]) &&
        changedRange.location < [[self string] length] && _isWhitespaceCharacter([[_textStorage string] characterAtIndex:CPMaxRange(changedRange)]))
        changedRange.length++;

    [self _deleteForRange:changedRange];
    _startTrackingLocation = _selectionRange.location;
}

- (void)deleteBackward:(id)sender
{
    [self deleteBackward:self handleSmart:[self _shouldUseSmartPasting] && _selectionRange.length > 0];
}

- (void)deleteForward:(id)sender
{
    var changedRange;

    if (CPEmptyRange(_selectionRange) && _selectionRange.location < [_layoutManager numberOfCharacters])
         changedRange = CPMakeRange(_selectionRange.location, 1);
    else
        changedRange = _selectionRange;

    [self _deleteForRange:changedRange];
}

- (void)cut:(id)sender
{
    if ([[CPApp currentEvent] type] != CPAppKitDefined)
        return;

    var selectedRange = [self selectedRange];

    if (selectedRange.length < 1)
        return;

    [self copy:sender];
    [self deleteBackward:sender handleSmart:_previousSelectionGranularity];
}

- (void)insertLineBreak:(id)sender
{
    [self insertText:@"\n"];
    // make sure that the return key is "swallowed" and the default button not triggered as is the case in cocoa
    [[self window] _temporarilyDisableKeyEquivalentForDefaultButton];
}

- (void)insertTab:(id)sender
{
    [self insertText:@"\t"];
}

- (void)insertTabIgnoringFieldEditor:(id)sender
{
    [self insertTab:sender];
}

- (void)insertNewlineIgnoringFieldEditor:(id)sender
{
    [self insertLineBreak:sender];
}

- (void)insertNewline:(id)sender
{
    [self insertLineBreak:sender];
}

- (void)_enrichEssentialTypingAttributes:(CPDictionary)attributes
{
    if (![attributes containsKey:CPFontAttributeName])
        [attributes setObject:[self font] forKey:CPFontAttributeName];

    if (![attributes containsKey:CPForegroundColorAttributeName])
        [attributes setObject:[self textColor] forKey:CPForegroundColorAttributeName];
}

- (void)setTypingAttributes:(CPDictionary)attributes
{
    if (!attributes)
        attributes = [CPDictionary dictionary];

    if ([self _delegateRespondsToShouldChangeTypingAttributesToAttributes])
    {
        _typingAttributes = [self _sendDelegateShouldChangeTypingAttributes:_typingAttributes toAttributes:attributes];
    }
    else
    {
        _typingAttributes = [attributes copy];

        [self _enrichEssentialTypingAttributes:_typingAttributes];
    }

    [[CPNotificationCenter defaultCenter] postNotificationName:CPTextViewDidChangeTypingAttributesNotification object:self];

    // We always clear the saved selection range from the last mouse down event here.
    // This is normally done in mouseUp: but this is if that event was never sent.
    _mouseDownOldSelection = nil;
}

- (CPDictionary)_attributesForFontPanel
{
    var attributes = [[_textStorage attributesAtIndex:CPMaxRange(_selectionRange) effectiveRange:nil] copy];

    [self _enrichEssentialTypingAttributes:attributes];

    return attributes;
}

- (void)delete:(id)sender
{
    [self deleteBackward:sender];
}


#pragma mark -
#pragma mark Font methods

- (CPFont)font
{
    return _font || [CPFont systemFontOfSize:12.0];
}

- (void)setFont:(CPFont)font
{
    _font = font;

    var length = [_layoutManager numberOfCharacters];

    if (length)
    {
        [_textStorage addAttribute:CPFontAttributeName value:_font range:CPMakeRange(0, length)];
        [_textStorage setFont:_font];
        [self scrollRangeToVisible:CPMakeRange(length, 0)];
    }
}

- (void)setFont:(CPFont)font range:(CPRange)range
{
    if (![self isRichText])
    {
        _font = font;
        [_textStorage setFont:_font];
    }

    var currentAttributes = [_textStorage attributesAtIndex:range.location effectiveRange:nil] || _typingAttributes;

    [[[[self window] undoManager] prepareWithInvocationTarget:self]
                                                      setFont:[currentAttributes objectForKey:CPFontAttributeName] || [self font]
                                                        range:CPMakeRangeCopy(range)];

    [_textStorage addAttribute:CPFontAttributeName value:font range:CPMakeRangeCopy(range)];
    [_layoutManager _validateLayoutAndGlyphs];
}

- (void)changeFont:(id)sender
{
    var currRange = CPMakeRange(_selectionRange.location, 0),
        oldFont,
        attributes,
        scrollRange = CPMakeRange(CPMaxRange(_selectionRange), 0),
        undoManager = [[self window] undoManager];

    [undoManager beginUndoGrouping];

    if ([self isRichText])
    {
        if (!CPEmptyRange(_selectionRange))
        {
            while (CPMaxRange(currRange) < CPMaxRange(_selectionRange))  // iterate all "runs"
            {
                attributes = [_textStorage attributesAtIndex:CPMaxRange(currRange)
                                       longestEffectiveRange:currRange
                                                     inRange:_selectionRange];
                oldFont = [attributes objectForKey:CPFontAttributeName] || [self font];

                [self setFont:[sender convertFont:oldFont] range:currRange];
            }
        }
        else
        {
            attributes = [_textStorage attributesAtIndex:_selectionRange.location
                                       longestEffectiveRange:_selectionRange
                                                     inRange:_selectionRange];
            oldFont = [attributes objectForKey:CPFontAttributeName] || [self font];
            [_typingAttributes setObject:[sender convertFont:oldFont] forKey:CPFontAttributeName];
        }
    }
    else
    {
        var length = [_textStorage length];

        oldFont = [self font];
        [self setFont:[sender convertFont:oldFont] range:CPMakeRange(0, length)];
        scrollRange = CPMakeRange(length, 0);
    }

    [undoManager endUndoGrouping];

    [_layoutManager _validateLayoutAndGlyphs];
    [self sizeToFit];
    [self setNeedsDisplay:YES];
    [self scrollRangeToVisible:scrollRange];
}


#pragma mark -
#pragma mark Color methods

- (void)changeColor:(id)sender
{
    [self setTextColor:[sender color] range:_selectionRange];
}

- (void)setTextColor:(CPColor)aColor
{
    _textColor = [aColor copy];
    [self setTextColor:aColor range:CPMakeRange(0, [_layoutManager numberOfCharacters])];
    [_typingAttributes setObject:_textColor forKey:CPForegroundColorAttributeName];
}

- (void)setTextColor:(CPColor)aColor range:(CPRange)range
{
    var currentAttributes = [_textStorage attributesAtIndex:range.location effectiveRange:nil] || _typingAttributes;

    [[[[self window] undoManager] prepareWithInvocationTarget:self]
                                                 setTextColor:[currentAttributes objectForKey:CPForegroundColorAttributeName] || _textColor
                                                        range:CPMakeRangeCopy(range)];

    if (!CPEmptyRange(range))
    {
        if (aColor)
            [_textStorage addAttribute:CPForegroundColorAttributeName value:aColor range:CPMakeRangeCopy(range)];
        else
            [_textStorage removeAttribute:CPForegroundColorAttributeName range:CPMakeRangeCopy(range)];
    }
    else
        [_typingAttributes setObject:aColor forKey:CPForegroundColorAttributeName];

    [_layoutManager textStorage:_textStorage edited:0 range:CPMakeRangeCopy(range) changeInLength:0 invalidatedRange:CPMakeRangeCopy(range)];
}

#pragma mark -
#pragma mark Style & Alignment methods

- (void)bold:(id)sender
{
    // This will trigger changeFont: via the FontManager
    [[CPFontManager sharedFontManager] addFontTrait:CPBoldFontMask];
}

- (void)italic:(id)sender
{
    // This will trigger changeFont: via the FontManager
    [[CPFontManager sharedFontManager] addFontTrait:CPItalicFontMask];
}

- (void)alignLeft:(id)sender
{
    [self _setAlignment:CPLeftTextAlignment];
}

- (void)alignCenter:(id)sender
{
    [self _setAlignment:CPCenterTextAlignment];
}

- (void)alignRight:(id)sender
{
    [self _setAlignment:CPRightTextAlignment];
}

- (void)alignJustified:(id)sender
{
    [self _setAlignment:CPJustifiedTextAlignment];
}

- (void)_setAlignment:(CPTextAlignment)anAlignment
{
    if (![self _didBeginEditing] || ![self shouldChangeTextInRange:_selectionRange replacementString:nil])
        return;

    var style = [CPParagraphStyle defaultParagraphStyle],
        currentAttributes = _typingAttributes;

    // Attempt to grab existing style from selection to preserve other paragraph settings
    if (_selectionRange.length > 0)
        currentAttributes = [_textStorage attributesAtIndex:_selectionRange.location effectiveRange:nil];
    
    if ([currentAttributes objectForKey:CPParagraphStyleAttributeName])
        style = [currentAttributes objectForKey:CPParagraphStyleAttributeName];

    // Create new style with modified alignment
    var newStyle = [style mutableCopy];
    [newStyle setAlignment:anAlignment];

    if (_selectionRange.length > 0)
    {
        // Add rudimentary undo support
        var undoManager = [[self window] undoManager];
        if (undoManager)
        {
             [[undoManager prepareWithInvocationTarget:self]
                 _setAlignment:[style alignment]];
        }

        [_textStorage addAttribute:CPParagraphStyleAttributeName value:newStyle range:CPMakeRangeCopy(_selectionRange)];
        
        // Notify layout manager of changes
        [_layoutManager textStorage:_textStorage 
                             edited:0 
                              range:CPMakeRangeCopy(_selectionRange) 
                     changeInLength:0 
                   invalidatedRange:CPMakeRangeCopy(_selectionRange)];
    }
    else
    {
        // Update typing attributes for next character
        [_typingAttributes setObject:newStyle forKey:CPParagraphStyleAttributeName];
        [[CPNotificationCenter defaultCenter] postNotificationName:CPTextViewDidChangeTypingAttributesNotification object:self];
    }
}

- (void)underline:(id)sender
{
    if (![self _didBeginEditing] || ![self shouldChangeTextInRange:_selectionRange replacementString:nil])
        return;

    if (!CPEmptyRange(_selectionRange))
    {
        var attrib = [_textStorage attributesAtIndex:_selectionRange.location effectiveRange:nil];

        if ([attrib containsKey:CPUnderlineStyleAttributeName] && [[attrib objectForKey:CPUnderlineStyleAttributeName] intValue])
            [_textStorage removeAttribute:CPUnderlineStyleAttributeName range:_selectionRange];
        else
            [_textStorage addAttribute:CPUnderlineStyleAttributeName value:CPUnderlineStyleSingle range:CPMakeRangeCopy(_selectionRange)];
    }
    else
    {
        if ([_typingAttributes containsKey:CPUnderlineStyleAttributeName] && [[_typingAttributes  objectForKey:CPUnderlineStyleAttributeName] intValue])
            [_typingAttributes setObject:CPUnderlineStyleNone forKey:CPUnderlineStyleAttributeName];
        else
            [_typingAttributes setObject:CPUnderlineStyleSingle forKey:CPUnderlineStyleAttributeName];
    }

    [_layoutManager textStorage:_textStorage edited:0 range:CPMakeRangeCopy(_selectionRange) changeInLength:0 invalidatedRange:CPMakeRangeCopy(_selectionRange)];
}

- (CPSelectionAffinity)selectionAffinity
{
    return 0;
}

- (BOOL)isRulerVisible
{
    return NO;
}

- (void)replaceCharactersInRange:(CPRange)aRange withString:(CPString)aString
{
    [_textStorage replaceCharactersInRange:aRange withString:aString];
}

- (void)setConstrainedFrameSize:(CGSize)desiredSize
{
    [self setFrameSize:desiredSize];
}

- (void)sizeToFit
{
    [self setFrameSize:[self frameSize]];
}

- (void)setFrameSize:(CGSize)aSize
{
    var desiredSize = CGSizeCreateCopy(aSize);

    if (_isHorizontallyResizable || _isVerticallyResizable)
    {
        var minSize = [self minSize],
            maxSize = [self maxSize],
            rect = CGRectUnion([_layoutManager boundingRectForGlyphRange:CPMakeRange(0, 1) inTextContainer:_textContainer],
                           [_layoutManager boundingRectForGlyphRange:CPMakeRange(MAX(0, [_layoutManager numberOfCharacters] - 2), 1) inTextContainer:_textContainer]);

        if ([_layoutManager extraLineFragmentTextContainer] === _textContainer)
            rect = CGRectUnion(rect, [_layoutManager extraLineFragmentRect]);

        if (_isHorizontallyResizable)
        {
            rect = [_layoutManager boundingRectForGlyphRange:CPMakeRange(0, MAX(0, [_layoutManager numberOfCharacters] - 1)) inTextContainer:_textContainer]; // needs expensive "deep" recalculation

            desiredSize.width = rect.size.width + 2 * _textContainerInset.width;

            if (desiredSize.width < minSize.width)
                desiredSize.width = minSize.width;
            else if (desiredSize.width > maxSize.width)
                desiredSize.width = maxSize.width;
        }

        if (_isVerticallyResizable)
        {
            desiredSize.height = rect.size.height + 2 * _textContainerInset.height;

            if (desiredSize.height < minSize.height)
                desiredSize.height = minSize.height;
            else if (desiredSize.height > maxSize.height)
                desiredSize.height = maxSize.height;
        }
    }

    if ([[self superview] isKindOfClass:[CPClipView class]])
    {
        var myClipviewSize = [[self superview] frame].size;

        if (desiredSize.width < myClipviewSize.width)
            desiredSize.width = myClipviewSize.width;
        if (desiredSize.height < myClipviewSize.height)
            desiredSize.height = myClipviewSize.height;
    }

    [super setFrameSize:desiredSize];
}

- (void)scrollRangeToVisible:(CPRange)aRange
{
    var rect;

    if (CPEmptyRange(aRange))
    {
        if (aRange.location >= [_layoutManager numberOfCharacters])
            rect = [_layoutManager extraLineFragmentRect];
        else
            rect = [_layoutManager lineFragmentRectForGlyphAtIndex:aRange.location effectiveRange:nil];
    }
    else
    {
        rect = [_layoutManager boundingRectForGlyphRange:aRange inTextContainer:_textContainer];
    }

    rect.origin.x += _textContainerOrigin.x;
    rect.origin.y += _textContainerOrigin.y;

    [self scrollRectToVisible:rect];
}

- (BOOL)_isCharacterAtIndex:(unsigned)index granularity:(CPSelectionGranularity)granularity
{
    var characterSet;

    switch (granularity)
    {
        case CPSelectByWord:
            characterSet = [[self class] _wordBoundaryRegex];
            break;

        case CPSelectByParagraph:
            characterSet = [[self class] _paragraphBoundaryRegex];
            break;
        default:
            // FIXME if (!characterSet) croak!
    }

    return _regexMatchesStringAtIndex(characterSet, [_textStorage string], index);
}

+ (JSObject)_wordBoundaryRegex
{
    return new RegExp("(^[0-9][\\.,])|(^.[^-\\.,+#'\"!§$%&/\\(<\\[\\]>\\)=?`´*\\s{}\\|¶])", "m");
}

+ (JSObject)_paragraphBoundaryRegex
{
    return new RegExp("^.[^\\n\\r]", "m");
}

+ (JSObject)_whitespaceRegex
{
    // do not include \n here or we will get cross paragraph selections
    return new RegExp("^.[ \\t]+", "m");
}

- (CPRange)_characterRangeForIndex:(unsigned)index asDefinedByRegex:(JSObject)regex
{
    return [self _characterRangeForIndex:index asDefinedByLRegex:regex andRRegex:regex]
}

- (CPRange)_characterRangeForIndex:(unsigned)index asDefinedByLRegex:(JSObject)lregex andRRegex:(JSObject)rregex
{
    var wordRange = CPMakeRange(index, 0),
        numberOfCharacters = [_layoutManager numberOfCharacters],
        string = [_textStorage string];

    // extend to the left
    for (var searchIndex = index - 1; searchIndex >= 0 && _regexMatchesStringAtIndex(lregex, string, searchIndex); searchIndex--)
        wordRange.location = searchIndex;

    // extend to the right
    searchIndex = index + 1;

    while (searchIndex < numberOfCharacters && _regexMatchesStringAtIndex(rregex, string, searchIndex))
        searchIndex++;

    return _MakeRangeFromAbs(wordRange.location, MIN(MAX(0, numberOfCharacters), searchIndex));
}

- (CPRange)selectionRangeForProposedRange:(CPRange)proposedRange granularity:(CPSelectionGranularity)granularity
{
    var textStorageLength = [_layoutManager numberOfCharacters];

    if (textStorageLength == 0)
        return CPMakeRange(0, 0);

    if (proposedRange.location >= textStorageLength)
        proposedRange = CPMakeRange(textStorageLength, 0);

    if (CPMaxRange(proposedRange) > textStorageLength)
        proposedRange.length = textStorageLength - proposedRange.location;

    var string = [_textStorage string],
        lregex,
        rregex,
        lloc = proposedRange.location,
        rloc = CPMaxRange(proposedRange);

    switch (granularity)
    {
        case CPSelectByWord:
            lregex = _isWhitespaceCharacter([string characterAtIndex:lloc])? [[self class] _whitespaceRegex] : [[self class] _wordBoundaryRegex];
            rregex = _isWhitespaceCharacter([string characterAtIndex:CPMaxRange(proposedRange)])? [[self class] _whitespaceRegex] : [[self class] _wordBoundaryRegex];
            break;
        case CPSelectByParagraph:
            lregex = rregex = [[self class] _paragraphBoundaryRegex];

            // triple click right in last line of a paragraph-> select this paragraph completely
            if (lloc > 0 && _isNewlineCharacter([string characterAtIndex:lloc]) &&
                !_isNewlineCharacter([string characterAtIndex:lloc - 1]))
                lloc--;

            if (rloc > 0 && _isNewlineCharacter([string characterAtIndex:rloc]))
                rloc--;

            break;
        default:
            return proposedRange;
    }

    var granularRange = [self _characterRangeForIndex:lloc
                                    asDefinedByLRegex:lregex
                                            andRRegex:rregex];

    if (proposedRange.length == 0 && _isNewlineCharacter([string characterAtIndex:proposedRange.location]))
        return _MakeRangeFromAbs(_isNewlineCharacter([string characterAtIndex:lloc])? proposedRange.location : granularRange.location, proposedRange.location + 1);

    if (proposedRange.length)
        granularRange = CPUnionRange(granularRange, [self _characterRangeForIndex:rloc
                                                                asDefinedByLRegex:lregex
                                                                        andRRegex:rregex]);

    // include the newline character in case of triple click selecting as is done by apple
    if (granularity == CPSelectByParagraph && _isNewlineCharacter([string characterAtIndex:CPMaxRange(granularRange)]))
        granularRange.length++;

    return granularRange;
}

- (BOOL)shouldDrawInsertionPoint
{
    if (![self isEditable])
        return NO;

    return (_selectionRange.length === 0 && [self _isFocused] && !_placeholderString);
}

- (CPRect)_getCaretRect
{
    var numberOfGlyphs = [_layoutManager numberOfCharacters];

    if (!numberOfGlyphs)
    {
        var font = [_typingAttributes objectForKey:CPFontAttributeName] || [self font];
        return CGRectMake(1, ([font ascender] - [font descender]) * 0.5 + _textContainerOrigin.y, 1, [font size]);
    }

    // cursor is at a newline character -> jump to next line
    if (_selectionRange.location == numberOfGlyphs && _isNewlineCharacter([[_textStorage string] characterAtIndex:_selectionRange.location - 1]))
        return CGRectCreateCopy([_layoutManager extraLineFragmentRect]);

    var caretRect = [_layoutManager boundingRectForGlyphRange:CPMakeRange(_selectionRange.location, 1) inTextContainer:_textContainer];

    var loc = (_selectionRange.location == numberOfGlyphs) ? _selectionRange.location - 1 : _selectionRange.location,
        caretOffset = [_layoutManager _characterOffsetAtLocation:loc],
        oldYPosition = CGRectGetMaxY(caretRect),
        caretDescend = [_layoutManager _descentAtLocation:loc];

    if (caretOffset > 0)
    {
        caretRect.origin.y += caretOffset;
        caretRect.size.height = oldYPosition - caretRect.origin.y;
    }

    if (caretDescend < 0)
        caretRect.size.height -= caretDescend;

    if (_selectionRange.location == numberOfGlyphs)
        caretRect.origin.x += caretRect.size.width;

    caretRect.origin.x += _textContainerOrigin.x;
    caretRect.origin.y += _textContainerOrigin.y;

    return caretRect;
}
- (void)updateInsertionPointStateAndRestartTimer:(BOOL)flag
{
    if (_selectionRange.length)
        [_caret setVisibility:NO];

    [_caret setRect:[self _getCaretRect]];

    if (flag)
        [_caret startBlinking];
}

- (void)draggingUpdated:(CPDraggingInfo)info
{
    var point = [info draggingLocation],
        location = [self _characterIndexFromRawPoint:CGPointCreateCopy(point)];

    _movingSelection = CPMakeRange(location, 0);

    if (CPLocationInRange(location, _selectionRange))
        return;

    [_caret _drawCaretAtLocation:_movingSelection.location];
    [_caret setVisibility:YES];
}

#pragma mark -
#pragma mark Dragging operation

- (void)performDragOperation:(CPDraggingInfo)aSender
{
    var location = [self convertPoint:[aSender draggingLocation] fromView:nil],
        pasteboard = [aSender draggingPasteboard];

    if ([pasteboard availableTypeFromArray:[_CPASPboardType]])
    {
        [_caret setVisibility:NO];

        if (CPLocationInRange(_movingSelection.location, _selectionRange))
        {
            [self setSelectedRange:_movingSelection];
            _movingSelection = nil;
            return;
        }

        if (_movingSelection.location > CPMaxRange(_selectionRange))
            _movingSelection.location -= _selectionRange.length;

        [self _deleteForRange:_selectionRange];
        [self setSelectedRange:_movingSelection];

        var stringForPasting = [CPKeyedUnarchiver unarchiveObjectWithData:[CPData dataWithRawString:[pasteboard stringForType:_CPASPboardType]]];
        //  setTimeout is to a work around a transaction issue with the undomanager
        setTimeout(function(){
            [self insertText:stringForPasting];
        }, 0);
    }

    if ([pasteboard availableTypeFromArray:[CPColorDragType]])
        [self setTextColor:[CPKeyedUnarchiver unarchiveObjectWithData:[pasteboard dataForType:CPColorDragType]] range:_selectionRange];
}

- (BOOL)isSelectable
{
    return [super isSelectable] && !_placeholderString;
}
- (BOOL)isEditable
{
    return [super isEditable] && !_placeholderString;
}

- (void)_setPlaceholderString:(CPString)aString
{
    if (_placeholderString === aString)
        return;

    _placeholderString = aString;

    // Use themeable color for placeholder text.
    [self setString:[[CPAttributedString alloc] initWithString:_placeholderString attributes:@{CPForegroundColorAttributeName:[CPColor disabledControlTextColor]}]];
}

- (void)_continuouslyReverseSetBinding
{
    var binderClass = [[self class] _binderClassForBinding:CPAttributedStringBinding] ||
                      [[self class] _binderClassForBinding:CPValueBinding],
        theBinding = [binderClass getBinding:CPAttributedStringBinding forObject:self] || [binderClass getBinding:CPValueBinding forObject:self];

    if ([theBinding continuouslyUpdatesValue])
        [theBinding reverseSetValueFor:@"objectValue"];
}

- (void)_reverseSetBinding
{
    var binderClass = [[self class] _binderClassForBinding:CPAttributedStringBinding] ||
                      [[self class] _binderClassForBinding:CPValueBinding],
        theBinding = [binderClass getBinding:CPAttributedStringBinding forObject:self] || [binderClass getBinding:CPValueBinding forObject:self];

    if (theBinding && [self isEditable])
        [theBinding reverseSetValueFor:@"objectValue"];
}

@end


@implementation CPTextView (CPTextViewDelegate)

- (BOOL)_delegateRespondsToShouldChangeTypingAttributesToAttributes
{
    return _delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_shouldChangeTypingAttributes_toAttributes;
}

- (BOOL)_delegateRespondsToWillChangeSelectionFromCharacterRangeToCharacterRange
{
    return _delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_willChangeSelectionFromCharacterRange_toCharacterRange;
}

- (BOOL)_sendDelegateDoCommandBySelector:(SEL)aSelector
{
    if (!(_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_doCommandBySelector))
        return NO;

    return [_delegate textView:self doCommandBySelector:aSelector];
}

- (BOOL)_sendDelegateTextShouldBeginEditing
{
    if (!(_delegateRespondsToSelectorMask & kDelegateRespondsTo_textShouldBeginEditing))
        return YES;

    return [_delegate textShouldBeginEditing:self];
}

- (BOOL)_sendDelegateTextShouldEndEditing
{
    if (!(_delegateRespondsToSelectorMask & kDelegateRespondsTo_textShouldEndEditing))
        return YES;

    return [_delegate textShouldEndEditing:self];
}

- (BOOL)_sendDelegateShouldChangeTextInRange:(CPRange)aRange replacementString:(CPString)aString
{
    if (!(_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_shouldChangeTextInRange_replacementString))
        return YES;

    return [_delegate textView:self shouldChangeTextInRange:aRange replacementString:aString];
}

- (CPDictionary)_sendDelegateShouldChangeTypingAttributes:(CPDictionary)typingAttributes toAttributes:(CPDictionary)attributes
{
    if (!(_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_shouldChangeTypingAttributes_toAttributes))
        return [CPDictionary dictionary];

    return [_delegate textView:self shouldChangeTypingAttributes:typingAttributes toAttributes:attributes];
}

- (CPRange)_sendDelegateWillChangeSelectionFromCharacterRange:(CPRange)selectionRange toCharacterRange:(CPRange)range
{
    if (!(_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_willChangeSelectionFromCharacterRange_toCharacterRange))
        return CPMakeRange(0, 0);

    return [_delegate textView:self willChangeSelectionFromCharacterRange:selectionRange toCharacterRange:range];
}

@end


var CPTextViewAllowsUndoKey = @"CPTextViewAllowsUndoKey",
    CPTextViewUsesFontPanelKey = @"CPTextViewUsesFontPanelKey",
    CPTextViewContainerKey = @"CPTextViewContainerKey",
    CPTextViewLayoutManagerKey = @"CPTextViewLayoutManagerKey",
    CPTextViewTextStorageKey = @"CPTextViewTextStorageKey",
    CPTextViewInsertionPointColorKey = @"CPTextViewInsertionPointColorKey",
    CPTextViewSelectedTextAttributesKey = @"CPTextViewSelectedTextAttributesKey",
    CPTextViewDelegateKey = @"CPTextViewDelegateKey",
    CPTextViewHorizontallyResizableKey = @"CPTextViewHorizontallyResizableKey",
    CPTextViewVerticallyResizableKey = @"CPTextViewVerticallyResizableKey",
    CPMaxSize = @"CPMaxSize";


@implementation CPTextView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        [self _init];

        [self setInsertionPointColor:[aCoder decodeObjectForKey:CPTextViewInsertionPointColorKey]];

        var selectedTextAttributes = [aCoder decodeObjectForKey:CPTextViewSelectedTextAttributesKey],
            enumerator = [selectedTextAttributes keyEnumerator],
            key;

        while (key = [enumerator nextObject])
            [_selectedTextAttributes setObject:[selectedTextAttributes valueForKey:key] forKey:key];

        if (![_selectedTextAttributes valueForKey:CPBackgroundColorAttributeName])
            [_selectedTextAttributes setObject:[CPColor selectedTextBackgroundColor] forKey:CPBackgroundColorAttributeName];

        [self setAllowsUndo:[aCoder decodeBoolForKey:CPTextViewAllowsUndoKey]];
        [self setUsesFontPanel:[aCoder decodeBoolForKey:CPTextViewUsesFontPanelKey]];

        [self setDelegate:[aCoder decodeObjectForKey:CPTextViewDelegateKey]];

        var container = [aCoder decodeObjectForKey:CPTextViewContainerKey];
        [container setTextView:self];

        _typingAttributes = [[_textStorage attributesAtIndex:0 effectiveRange:nil] copy];

        if (![_typingAttributes valueForKey:CPForegroundColorAttributeName])
            [_typingAttributes setObject:[CPColor textColor] forKey:CPForegroundColorAttributeName];

        _textColor = [_typingAttributes valueForKey:CPForegroundColorAttributeName];
        [self setFont:[_typingAttributes valueForKey:CPFontAttributeName]];

        [self setString:[_textStorage string]];

        [self setMaxSize:[aCoder decodeSizeForKey:CPMaxSize]];
        [self setHorizontallyResizable:[aCoder decodeBoolForKey:CPTextViewHorizontallyResizableKey]];
        [self setVerticallyResizable:[aCoder decodeBoolForKey:CPTextViewVerticallyResizableKey]]
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_delegate forKey:CPTextViewDelegateKey];
    [aCoder encodeObject:_textContainer forKey:CPTextViewContainerKey];
    [aCoder encodeObject:_insertionPointColor forKey:CPTextViewInsertionPointColorKey];
    [aCoder encodeObject:_selectedTextAttributes forKey:CPTextViewSelectedTextAttributesKey];
    [aCoder encodeBool:_allowsUndo forKey:CPTextViewAllowsUndoKey];
    [aCoder encodeBool:_usesFontPanel forKey:CPTextViewUsesFontPanelKey];
    [aCoder encodeBool:_isHorizontallyResizable forKey:CPTextViewHorizontallyResizableKey];
    [aCoder encodeBool:_isVerticallyResizable forKey:CPTextViewVerticallyResizableKey];
    [aCoder encodeSize:_maxSize forKey:CPMaxSize];
}

@end


@implementation _CPSelectionBox : CPObject
{
    DOMElement  _selectionBoxDOM;
    CGRect      _rect;
    CPColor     _color;
    CPTextView  _textView;
}

- (id)initWithTextView:(CPTextView)aTextView rect:(CGRect)aRect color:(CPColor)aColor
{
    if (self = [super init])
    {
        _textView = aTextView;
        _rect = aRect;
        _color = aColor;

        [self _createSpan];
        _textView._DOMElement.appendChild(_selectionBoxDOM);
    }

    return self;
}

- (void)removeFromTextView
{
    _textView._DOMElement.removeChild(_selectionBoxDOM);
}

- (void)_createSpan
{

#if PLATFORM(DOM)
    _selectionBoxDOM = document.createElement("span");
    _selectionBoxDOM.style.position = "absolute";
    _selectionBoxDOM.style.visibility = "visible";
    _selectionBoxDOM.style.padding = "0px";
    _selectionBoxDOM.style.margin = "0px";
    _selectionBoxDOM.style.whiteSpace = "pre";
    _selectionBoxDOM.style.backgroundColor = [_color cssString];

    _selectionBoxDOM.style.width = (_rect.size.width) + "px";
    _selectionBoxDOM.style.left = (_rect.origin.x) + "px";
    _selectionBoxDOM.style.top = (_rect.origin.y) + "px";
    _selectionBoxDOM.style.height = (_rect.size.height) + "px";
    _selectionBoxDOM.style.zIndex = -1000;
    _selectionBoxDOM.oncontextmenu = _selectionBoxDOM.onmousedown = _selectionBoxDOM.onselectstart = function () { return false; };
#endif

}

@end


@implementation _CPCaret : CPObject
{
    BOOL        _drawCaret;
    BOOL        _permanentlyVisible @accessors(property=permanentlyVisible);
    CGRect      _rect;
    CPTextView  _textView;
    CPTimer     _caretTimer;
    DOMElement  _caretDOM;
}

- (void)setRect:(CGRect)aRect
{
    _rect = CGRectCreateCopy(aRect);

#if PLATFORM(DOM)
    _caretDOM.style.left = (aRect.origin.x) + "px";
    _caretDOM.style.top = (aRect.origin.y) + "px";
    _caretDOM.style.height = (aRect.size.height) + "px";
#endif
}

- (id)initWithTextView:(CPTextView)aView
{
    if (self = [super init])
    {
#if PLATFORM(DOM)
        var style;

        if (!_caretDOM)
        {
            _caretDOM = document.createElement("span");
            style = _caretDOM.style;
            style.position = "absolute";
            style.visibility = "visible";
            style.padding = "0px";
            style.margin = "0px";
            style.whiteSpace = "pre";
            style.backgroundColor = "black";
            _caretDOM.style.width = "1px";
            _caretDOM.style.zIndex = 10001;
            _textView = aView;
            _textView._DOMElement.appendChild(_caretDOM);
        }
#endif
    }

    return self;
}

- (void)setVisibility:(BOOL)visibilityFlag stop:(BOOL)stopFlag
{

#if PLATFORM(DOM)
    _caretDOM.style.visibility = visibilityFlag ? "visible" : "hidden";
#endif

    if (!visibilityFlag && stopFlag)
        [self stopBlinking];
}

- (void)setVisibility:(BOOL)visibilityFlag
{
    [self setVisibility:visibilityFlag stop:YES];
}

- (void)_blinkCaret:(CPTimer)aTimer
{
    _drawCaret = (!_drawCaret) || _permanentlyVisible;
    [_textView setNeedsDisplayInRect:_rect];
}

- (void)startBlinking
{
    _drawCaret = YES;

    if ([self isBlinking])
        return;

    _caretTimer = [CPTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_blinkCaret:) userInfo:nil repeats:YES];
}

- (BOOL)isBlinking
{
    return [_caretTimer isValid];
}

- (void)stopBlinking
{
    _drawCaret = NO;

    if (_caretTimer)
    {
        [_caretTimer invalidate];
        _caretTimer = nil;
    }
}

- (void)_drawCaretAtLocation:(int)aLoc
{
    var rect = [_textView._layoutManager boundingRectForGlyphRange:CPMakeRange(aLoc, 1) inTextContainer:_textView._textContainer];

	if (aLoc >= [_textView._layoutManager numberOfCharacters])
		rect.origin.x = CGRectGetMaxX(rect);

    [self setRect:rect];
}

@end


var _CPNativeInputField,
    _isComposing = NO; // Flag to track if an IME/dead key session is active.

var _CPCopyPlaceholder = '-';

@implementation _CPNativeInputManager : CPObject

+ (void)isDeadKey:(CPEvent)event
{
#if PLATFORM(DOM)
    return event._DOMEvent && (event._DOMEvent.key === 'Dead' || event._DOMEvent.key === 'Process');
#endif
    return NO;
}

+ (void)cancelCurrentInputSessionIfNeeded
{
#if PLATFORM(DOM)
    if (_CPNativeInputField) {
        _CPNativeInputField.innerHTML = '';
    }
    _isComposing = NO;
#endif
}

+ (void)initialize
{
#if PLATFORM(DOM)
    _CPNativeInputField = document.createElement("div");
    _CPNativeInputField.contentEditable = YES;

    // Style the input field to be invisible but focusable
    _CPNativeInputField.style.position = "absolute";
    _CPNativeInputField.style.top = "-1000px";
    _CPNativeInputField.style.left = "-1000px";
    _CPNativeInputField.style.width = "1px";
    _CPNativeInputField.style.height = "1px";
    _CPNativeInputField.style.opacity = "0";
    _CPNativeInputField.style.overflow = "hidden";
    _CPNativeInputField.style.whiteSpace = "pre";
    _CPNativeInputField.style.zIndex = -1; // Put it behind everything

    document.body.appendChild(_CPNativeInputField);

    // Central function to handle inserting text into the CPTextView
    var handleInput = function(textToInsert)
    {
        if (!textToInsert)
            return;

        var currentFirstResponder = [[CPApp keyWindow] firstResponder];

        if (currentFirstResponder && [currentFirstResponder respondsToSelector:@selector(insertText:)])
            var event = [CPApp currentEvent];

            if (!event._isKeyEquivalent)
                setTimeout(function(){
                    [currentFirstResponder insertText:textToInsert]
                }, 20);

        // Clear the field immediately after grabbing its content.
        _CPNativeInputField.innerHTML = '';
    };

    // Intercept problematic keys before the browser acts.
    _CPNativeInputField.addEventListener('keydown', function(e) {

        if (e.key === 'Enter' || (e.key === 'Backspace' && _CPNativeInputField.innerHTML === '')) {
            // Prevent browser default action:
            // - 'Enter': Prevents inserting <div><br></div>.
            // - 'Backspace' on empty: Prevents inserting junk characters on iPadOS.
            e.preventDefault();
        }
    });

    // This listener handles all other character input.
    _CPNativeInputField.addEventListener('input', function(e)
    {
        // If we are in a composition (e.g., IME), do nothing yet.
        if (_isComposing)
            return;

        // Safety net: ignore deletion events, as they are handled by keydown.
        if (e.inputType && e.inputType.startsWith('delete'))
        {
            _CPNativeInputField.innerHTML = '';
            return;
        }
        
        // Robustness: Use 'textContent' instead of 'innerHTML' to strip any
        // unexpected HTML tags the browser might have inserted.
        var textToInsert = e.target.textContent;
        handleInput(textToInsert);
    });

    // Fires when a composition session starts (e.g., user presses a dead key or starts an IME).
    _CPNativeInputField.addEventListener('compositionstart', function(e) {
        _isComposing = YES;
    });

    // Fires when the composition is finished.
    _CPNativeInputField.addEventListener('compositionend', function(e) {
        // The composition is over. `e.data` has the final string (e.g., "é").
        handleInput(e.data);
        _isComposing = NO;
    });

    // PASTE handler
    _CPNativeInputField.onpaste = function(e)
    {
        e.preventDefault();
        var nativeClipboard = (e.originalEvent || e).clipboardData;
        var currentFirstResponder = [[CPApp keyWindow] firstResponder];

        // Can we accept richtext? Then this is our preference (fixme: shift key to force plain text paste)
        if ([currentFirstResponder isRichText])
        {
            var richtext = nativeClipboard.getData('text/rtf');

            // prefer RTF form the outside of cappuccino
            if (richtext)
                richtext = [[_CPRTFParser new] parseRTF:richtext];
            else
            {
                var pasteboard = [CPPasteboard generalPasteboard];
                // If no RTF is available, try to get the internal represatation of richtext from the pasteboard
                var richData = [pasteboard stringForType:_CPASPboardType];

                if (richData)
                    richtext = [CPKeyedUnarchiver unarchiveObjectWithData:[CPData dataWithRawString:richData]];
            }

            if (richtext)
            {
                [currentFirstResponder _pasteString:richtext];

                return;
            }
            // If no richtext is available, fall back to plain text
        }

        var nativeString = nativeClipboard.getData('text/plain');
        [currentFirstResponder _pasteString:nativeString || [pasteboard stringForType:CPStringPboardType] || ''];
    };

    // COPY handler
    _CPNativeInputField.oncopy = function(e)
    {
        e.preventDefault();
        var pasteboard = [CPPasteboard generalPasteboard];
        var nativeClipboard = (e.originalEvent || e).clipboardData;

        // First, copy the data to populate the CP clipboard
        [[[CPApp keyWindow] firstResponder] copy:self];

        // Now, copy the data over to the native clipboard
        var stringForPasting = [pasteboard stringForType:CPStringPboardType] || '';
        nativeClipboard.setData('text/plain', stringForPasting);

        var rtfForPasting = [pasteboard stringForType:CPRTFPboardType];

        if (rtfForPasting)
            nativeClipboard.setData('text/rtf', rtfForPasting);
    };

    // CUT handler
    _CPNativeInputField.oncut = function(e)
    {
        e.preventDefault();
        var pasteboard = [CPPasteboard generalPasteboard];
        var nativeClipboard = (e.originalEvent || e).clipboardData;
        var currentFirstResponder = [[CPApp keyWindow] firstResponder];

        // First, copy the data to populate the CP clipboard
        [currentFirstResponder copy:self];

        // Now, copy the data to the native clipboard
        var stringForPasting = [pasteboard stringForType:CPStringPboardType] || '';
        nativeClipboard.setData('text/plain', stringForPasting);
        var rtfForPasting = [pasteboard stringForType:CPRTFPboardType];

        if (rtfForPasting)
            nativeClipboard.setData('text/rtf', rtfForPasting);

        // Then, perform the delete part of the cut operation in the text view
        [currentFirstResponder deleteBackward:self];
    };
#endif
}

+ (void)focusForTextView:(CPTextView)currentFirstResponder
{
#if PLATFORM(DOM)

    if (_CPNativeInputField && document.activeElement !== _CPNativeInputField)
        _CPNativeInputField.focus();
#endif
}

+ (void)focusForClipboardOfTextView:(CPTextView)textview
{
#if PLATFORM(DOM)
    var selectedRange = [textview selectedRange];
    if (selectedRange.length > 0) {
        // Put the selected text into the hidden div so the browser can natively copy it.
        var textToCopy = [[[textview textStorage] string] substringWithRange:selectedRange];
        _CPNativeInputField.innerHTML = textToCopy;
    } else {
        // For paste, we just need the field to be focusable.
        _CPNativeInputField.innerHTML = _CPCopyPlaceholder;
    }

    [self focusForTextView:textview];

    // Select the content of the hidden div so copy/cut works.
    if (window.getSelection && document.createRange) {
        var selection = window.getSelection();
        var range = document.createRange();
        range.selectNodeContents(_CPNativeInputField);
        selection.removeAllRanges();
        selection.addRange(range);
    }
#endif
}

@end


@class _CPTextFieldValueBinder;

@implementation _CPTextViewValueBinder : _CPTextFieldValueBinder

- (void)setPlaceholderValue:(id)aValue withMarker:(CPString)aMarker forBinding:(CPString)aBinding
{
    [_source _setPlaceholderString:aValue];
}

- (void)setValue:(id)aValue forBinding:(CPString)aBinding
{
    if (aValue == nil || (aValue.isa && [aValue isMemberOfClass:CPNull]))
        [_source _setPlaceholderString:[self _placeholderForMarker:CPNullMarker]];
    else
        [_source _setPlaceholderString:nil];

    [_source setObjectValue:aValue];
}

@end
