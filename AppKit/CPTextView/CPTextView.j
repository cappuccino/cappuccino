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
@import "CPLayoutManager.j"
@import "CPParagraphStyle.j"
@import "CPTextList.j"
@import "CPTextContainer.j"
@import "CPRulerView.j"

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
    return (chr === '\n' || chr === '\r' || chr === ' '); //  || chr === '\t'
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
    BOOL                        _usesRuler;
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

// MARK: -
// MARK: Class methods

/* <!> FIXME
    just a testing characterSet
    all of this depend of the current language.
    Need some CPLocale support and maybe even a FSM...
 */

// MARK: -
// MARK: Init methods

- (id)initWithFrame:(CGRect)aFrame textContainer:(CPTextContainer)aContainer
{
    if (self = [super initWithFrame:aFrame])
    {
        [self _init];
        [aContainer setTextView:self];

        // Fit a container that tracks the text view's size inside the text container inset.
        [aContainer textViewFrameChanged:nil];

        [self setEditable:YES];
        [self setSelectable:YES];
        [self setRichText:NO];
        [self setBackgroundColor:[CPColor whiteColor]];

        _usesFontPanel = YES;
        _allowsUndo = YES;

        _selectedTextAttributes = [CPDictionary dictionaryWithObject:[CPColor selectedTextBackgroundColor]
                                                              forKey:CPBackgroundColorAttributeName];

        _insertionPointColor = [CPColor blackColor];

        _textColor = [CPColor blackColor];
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
    if (CPDOMAvailable)
    {
        _DOMElement.style.cursor = "text";
    }

    _selectionRange = CPMakeRange(0, 0);
    _usesRuler = YES;
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
    [self sizeToFit];
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

// MARK: -
// MARK: Copy and paste methods

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

    if (![stringForPasting isKindOfClass:[CPAttributedString class]])
        stringForPasting = [[CPAttributedString alloc] initWithString:stringForPasting attributes:nil];

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

// MARK: -
// MARK: Responders method

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
    
    // SYNCHRONIZE ACTIVE PARAGRAPH MARKERS ON EDITOR FOCUS
    [self updateRuler];
    
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

    return YES;
}


// MARK: -
// MARK: Delegate methods

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


// MARK: -
// MARK: Key window methods

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


// MARK: -
// MARK: Undo redo methods

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

/*
    @ignore
    Returns the undo manager that records the text view's changes, or nil when allowsUndo is NO,
    so that a text view that does not allow undo registers nothing.
*/
- (CPUndoManager)_registeringUndoManager
{
    return _allowsUndo ? [[self window] undoManager] : nil;
}

/*!
    A text view that does not allow undo does not respond to \c -undo: or \c -redo:, so those
    actions continue along the responder chain to the window, as in Cocoa.
*/
- (BOOL)respondsToSelector:(SEL)aSelector
{
    if (!_allowsUndo && (aSelector === @selector(undo:) || aSelector === @selector(redo:)))
        return NO;

    return [super respondsToSelector:aSelector];
}

/*!
    Enables the Undo and Redo items only when the undo manager has a change to undo or redo.
    For \c -toggleRuler:, the item's title becomes "Hide Ruler" or "Show Ruler" to reflect the
    ruler's visibility, and the item is enabled only when the text view uses a ruler and lies
    in a scroll view. \c -copyRuler: is enabled in rich text, and \c -pasteRuler: in editable
    rich text when the ruler pasteboard holds a ruler. \c -changeTextList: is enabled in editable
    rich text, and its item is checked when it shows the list style at the selection.
    \c -copyFont: is enabled in rich text, and
    \c -pasteFont: in editable rich text when the font pasteboard holds a style. The superscript,
    subscript and baseline actions are enabled in editable rich text. Every other item is enabled.
    @param anItem the item to validate
    @return \c YES if the item should be enabled
*/
- (BOOL)validateUserInterfaceItem:(id /*<CPValidatedUserInterfaceItem>*/)anItem
{
    var action = [anItem action];

    if (action === @selector(undo:))
        return [[[self window] undoManager] canUndo];

    if (action === @selector(redo:))
        return [[[self window] undoManager] canRedo];

    // Baseline changes apply only to editable rich text.
    if (action === @selector(superscript:) || action === @selector(subscript:) || action === @selector(unscript:) ||
        action === @selector(raiseBaseline:) || action === @selector(lowerBaseline:))
        return [self isEditable] && [self isRichText];

    // As in Cocoa, rulers can be copied and pasted only in rich text.
    if (action === @selector(copyRuler:))
        return [self isRichText];

    if (action === @selector(pasteRuler:))
        return [self isRichText] && [self isEditable] && !![[CPPasteboard pasteboardWithName:CPRulerPboard] availableTypeFromArray:[CPRulerPboardType]];

    // Lists apply only to editable rich text. The item for the list style at the selection is checked.
    if (action === @selector(changeTextList:))
    {
        if ([anItem respondsToSelector:@selector(setState:)])
            [anItem setState:[self _textListStyleMatchesItem:anItem] ? CPOnState : CPOffState];

        return [self isEditable] && [self isRichText];
    }

    // As in Cocoa, styles can be copied and pasted only in rich text.
    if (action === @selector(copyFont:))
        return [self isRichText];

    if (action === @selector(pasteFont:))
        return [self isRichText] && [self isEditable] && !![[CPPasteboard pasteboardWithName:CPFontPboard] availableTypeFromArray:[CPFontPboardType]];

    if (action === @selector(toggleRuler:))
    {
        if ([anItem respondsToSelector:@selector(setTitle:)])
            [anItem setTitle:[self isRulerVisible] ? @"Hide Ruler" : @"Show Ruler"];

        return _usesRuler && !![self enclosingScrollView];
    }

    return YES;
}


// MARK: -
// MARK: Accessors

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

    // A container that tracks the text view's size must shrink or grow with the new inset.
    [_textContainer textViewFrameChanged:nil];
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


// MARK: -
// MARK: Insert characters methods

- (void)_fixupReplaceForRange:(CPRange)aRange
{
    [self setSelectedRange:aRange];
    [_layoutManager _validateLayoutAndGlyphs];
    [self sizeToFit];
    [self scrollRangeToVisible:_selectionRange];
    [self setNeedsDisplay:YES];

    // An undone or redone change may alter the paragraph style even when the selection stays the same.
    [self updateRuler];
}

- (void)_replaceCharactersInRange:(CPRange)aRange withAttributedString:(CPString)aString selectionRange:(CPRange)selectionRange
{
    [[[self _registeringUndoManager] prepareWithInvocationTarget:self]
                _replaceCharactersInRange:CPMakeRange(aRange.location, [aString length])
                     withAttributedString:[_textStorage attributedSubstringFromRange:CPMakeRangeCopy(aRange)]
                           selectionRange:CPMakeRangeCopy(_selectionRange)];

    [_textStorage replaceCharactersInRange:aRange withAttributedString:aString];
    [self _fixupReplaceForRange:selectionRange];
    [self _updateTextListMarkersAroundRange:CPMakeRange(aRange.location, [aString length])];
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

    var undoManager = [self _registeringUndoManager];
    [undoManager setActionName:@"Replace/insert text"];

    [[undoManager prepareWithInvocationTarget:self]
                    _replaceCharactersInRange:CPMakeRange(_selectionRange.location, [aString length])
                         withAttributedString:[_textStorage attributedSubstringFromRange:CPMakeRangeCopy(_selectionRange)]
                               selectionRange:CPMakeRangeCopy(_selectionRange)];

    [self willChangeValueForKey:@"objectValue"];
    [_textStorage replaceCharactersInRange:CPMakeRangeCopy(_selectionRange) withAttributedString:aString];
    [self didChangeValueForKey:@"objectValue"];
    [self _continuouslyReverseSetBinding];

    var insertionLocation = _selectionRange.location;

    [self _setSelectedRange:CPMakeRange(_selectionRange.location + [string length], 0) affinity:0 stillSelecting:NO overwriteTypingAttributes:NO];
    [self _updateTextListMarkersAroundRange:CPMakeRange(insertionLocation, [string length])];
    _startTrackingLocation = _selectionRange.location;

    [self didChangeText];
    [_layoutManager _validateLayoutAndGlyphs];
    [self sizeToFit];
    [self scrollRangeToVisible:_selectionRange];
    _stickyXLocation = MAX(0, _caret._rect.origin.x - 1);
}

// MARK: -
// MARK: Drawing methods

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
    if (!CPDOMAvailable)
        return;

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
}


// MARK: -
// MARK: Select methods

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
/* @ignore
    Returns the typing attributes for a selection, as in Cocoa: those of the first character of
    a selection, or of the character before an insertion point. At the start of a paragraph the
    insertion point takes the attributes of the paragraph's first character, so that it keeps
    the paragraph's own style. At the end of the text it takes those of the last character.
*/
- (CPDictionary)_typingAttributesForSelectionRange:(CPRange)aRange
{
    var string = [_textStorage string],
        length = string.length,
        index = aRange.location;

    if (!length)
        return [_typingAttributes copy];

    if (!aRange.length && index > 0)
    {
        var previousCharCode = string.charCodeAt(index - 1),
            isParagraphStart = previousCharCode === 10 || previousCharCode === 13 || previousCharCode === 0x2029;

        if (!isParagraphStart || index >= length)
            index--;
    }

    return [_textStorage attributesAtIndex:MIN(index, length - 1) effectiveRange:nil];
}

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
            [self setTypingAttributes:[self _typingAttributesForSelectionRange:newSelectionRange]];

        // The ruler shows the paragraph style at the selection.
        if (isNewSelection)
            [self updateRuler];

        // Update the shared CPColorPanel with the active selection color
        if ([self _isFirstResponder] && [_textStorage length] > 0)
        {
            var currentTextColor = [self textColor] || [CPColor blackColor];

            if ([self isRichText])
            {
                var charIndex = _selectionRange.location;
                if (charIndex >= [_textStorage length])
                    charIndex = MAX(0, charIndex - 1);

                var attributes = [_textStorage attributesAtIndex:charIndex effectiveRange:nil];
                if ([attributes objectForKey:CPForegroundColorAttributeName])
                    currentTextColor = [attributes objectForKey:CPForegroundColorAttributeName];
            }

            [[CPColorPanel sharedColorPanel] setColor:currentTextColor];
        }

        [[CPNotificationCenter defaultCenter] postNotificationName:CPTextViewDidChangeSelectionNotification object:self];
    }

    if (!selecting && newSelectionRange.length > 0)
       [_CPNativeInputManager focusForClipboardOfTextView:self];
}

- (CGPoint)_cumulativeOffset
{
    if (!CPDOMAvailable) return CGPointMake(0, 0);

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

- (CPArray)selectedRanges
{
    return [_selectionRange];
}

// MARK: -
// MARK: Keyboard events

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

// MARK: -
// MARK: Mouse Events

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

        [dragPlaceholder setBackgroundColor:[CPColor colorWithRed:1 green:1 blue:1 alpha:0]];
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
    {
       [self _extendSelectionIntoDirection:-1 granularity:CPSelectByCharacter];
       [self scrollRangeToVisible:_selectionRange];
    }
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
    {
        [self _establishSelection:CPMakeRange(_selectionRange.location - (_selectionRange.length ? 0 : 1), 0) byExtending:NO];
        [self scrollRangeToVisible:_selectionRange];
    }
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
    {
        [self _establishSelection:CPMakeRange(CPMaxRange(_selectionRange) + (_selectionRange.length ? 0 : 1), 0) byExtending:NO];
        [self scrollRangeToVisible:_selectionRange];
    }
}

- (void)_deleteForRange:(CPRange)changedRange
{
    if (![self _didBeginEditing] || ![self shouldChangeTextInRange:changedRange replacementString:@""])
        return;

    changedRange = CPIntersectionRange(CPMakeRange(0, [_layoutManager numberOfCharacters]), changedRange);

    [[[self _registeringUndoManager] prepareWithInvocationTarget:self] _replaceCharactersInRange:CPMakeRange(changedRange.location, 0)
                                                                   withAttributedString:[_textStorage attributedSubstringFromRange:CPMakeRangeCopy(changedRange)]
                                                                         selectionRange:CPMakeRangeCopy(_selectionRange)];
    [self willChangeValueForKey:@"objectValue"];
    [_textStorage deleteCharactersInRange:CPMakeRangeCopy(changedRange)];
    [self didChangeValueForKey:@"objectValue"];
    [self _continuouslyReverseSetBinding];

    [self setSelectedRange:CPMakeRange(changedRange.location, 0)];
    [self _updateTextListMarkersAroundRange:CPMakeRange(changedRange.location, 0)];
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
    if ([self _deleteBackwardInTextList])
        return;

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
    if ([self _insertTabInTextList])
        return;

    [self insertText:@"\t"];
}

/*!
    Shift-Tab in a list item returns the item to the enclosing list. Elsewhere it moves to the
    previous key view.
    @param sender the object requesting this
*/
- (void)insertBacktab:(id)sender
{
    if ([self _insertBacktabInTextList])
        return;

    [[self window] selectPreviousKeyView:self];
}

/*
    @ignore
    As in Cocoa, an editable text view takes the Tab key and inserts a tab character.
    Control-Tab still moves to the next key view.
*/
- (BOOL)_wantsTabKey
{
    return [self isEditable];
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
    if ([self _insertNewlineInTextList])
    {
        [[self window] _temporarilyDisableKeyEquivalentForDefaultButton];
        return;
    }

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

    // SYNCHRONIZE ACTIVE PARAGRAPH MARKERS ON TYPING ATTRIBUTES CHANGE
    [self updateRuler];

    // Synchronize CPColorPanel if text view is active
    if ([self _isFirstResponder])
    {
        var currentTextColor = [_typingAttributes objectForKey:CPForegroundColorAttributeName] || [self textColor] || [CPColor blackColor];
        [[CPColorPanel sharedColorPanel] setColor:currentTextColor];
    }

    [[CPNotificationCenter defaultCenter] postNotificationName:CPTextViewDidChangeTypingAttributesNotification object:self];

    // We always clear the saved selection range from the last mouse down event here.
    // This is normally done in mouseUp: but this is if that event was never sent.
    _mouseDownOldSelection = nil;
}

- (CPDictionary)_attributesForFontPanel
{
    // The font panel shows the font that typing would use: that of the first selected character,
    // or of the character before the insertion point.
    var attributes = [[self _typingAttributesForSelectionRange:_selectionRange] mutableCopy];

    [self _enrichEssentialTypingAttributes:attributes];

    return attributes;
}

- (void)delete:(id)sender
{
    [self deleteBackward:sender];
}


// MARK: -
// MARK: Font methods

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

    [[[self _registeringUndoManager] prepareWithInvocationTarget:self]
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
        undoManager = [self _registeringUndoManager];

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


// MARK: -
// MARK: Color methods

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

    [[[self _registeringUndoManager] prepareWithInvocationTarget:self]
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

// MARK: -
// MARK: Style & Alignment methods

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

// MARK: -
// MARK: Style methods

/*!
    Copies the character attributes at the start of the selection, or the typing attributes
    when nothing is selected, to the font pasteboard, so that Paste Style can apply them to
    other text. The attributes include the font, colours, underline and baseline. As in Cocoa,
    the paragraph style is not included: Copy Ruler copies it.
    @param aSender the object requesting this
*/
- (@action)copyFont:(id)aSender
{
    var attributes = _selectionRange.length ? [_textStorage attributesAtIndex:_selectionRange.location effectiveRange:nil] : _typingAttributes,
        pasteboard = [CPPasteboard pasteboardWithName:CPFontPboard];

    [pasteboard declareTypes:[CPFontPboardType] owner:nil];
    [pasteboard setData:[CPKeyedArchiver archivedDataWithRootObject:[self _characterStyleFromAttributes:attributes]] forType:CPFontPboardType];
}

/*!
    Applies the character attributes on the font pasteboard to the selected text, or to the
    text typed next when nothing is selected. They replace the text's own character
    attributes. Each paragraph keeps its paragraph style.
    @param aSender the object requesting this
*/
- (@action)pasteFont:(id)aSender
{
    var data = [[CPPasteboard pasteboardWithName:CPFontPboard] dataForType:CPFontPboardType];

    if (!data)
        return;

    var characterStyle = [CPKeyedUnarchiver unarchiveObjectWithData:data],
        range = CPMakeRangeCopy(_selectionRange);

    if (!range.length)
    {
        var typingAttributes = [characterStyle mutableCopy],
            paragraphStyle = [_typingAttributes objectForKey:CPParagraphStyleAttributeName];

        if (paragraphStyle)
            [typingAttributes setObject:paragraphStyle forKey:CPParagraphStyleAttributeName];

        [self setTypingAttributes:typingAttributes];
        return;
    }

    if (![self _beginCharacterAttributeChangeInRange:range])
        return;

    // Each run keeps the attributes that are not part of a style: its paragraph style and, for an
    // attachment character, the attachment.
    var location = range.location,
        end = CPMaxRange(range);

    while (location < end)
    {
        var effectiveRange = CPMakeRange(0, 0),
            runAttributes = [_textStorage attributesAtIndex:location effectiveRange:effectiveRange],
            runRange = CPIntersectionRange(effectiveRange, range),
            newAttributes = [characterStyle mutableCopy],
            keptKeys = [CPParagraphStyleAttributeName, CPAttachmentAttributeName, _CPAttachmentView, _CPAttachmentInvisible];

        if (!runRange.length)
            runRange = CPMakeRange(location, end - location);

        for (var i = 0; i < keptKeys.length; i++)
        {
            var value = [runAttributes objectForKey:keptKeys[i]];

            if (value)
                [newAttributes setObject:value forKey:keptKeys[i]];
        }

        [_textStorage setAttributes:newAttributes range:runRange];

        location = CPMaxRange(runRange);
    }

    [self _endCharacterAttributeChangeInRange:range];
}

/* @ignore
    Returns a copy of someAttributes without the attributes that are not part of a character
    style: the paragraph style and the attachment.
*/
- (CPDictionary)_characterStyleFromAttributes:(CPDictionary)someAttributes
{
    var characterStyle = [someAttributes mutableCopy] || [CPDictionary dictionary];

    [characterStyle removeObjectForKey:CPParagraphStyleAttributeName];
    [characterStyle removeObjectForKey:CPAttachmentAttributeName];
    [characterStyle removeObjectForKey:_CPAttachmentView];
    [characterStyle removeObjectForKey:_CPAttachmentInvisible];

    return characterStyle;
}

// MARK: -
// MARK: Baseline methods

/*!
    Raises the superscript level of the selected text by one, or of the text typed next when
    nothing is selected. Each run of the selection keeps its own level, raised by one.
    @param aSender the object requesting this
*/
- (@action)superscript:(id)aSender
{
    [self _changeCharacterAttribute:CPSuperscriptAttributeName byAmount:1];
}

/*!
    Lowers the superscript level of the selected text by one, or of the text typed next when
    nothing is selected. A negative level is a subscript.
    @param aSender the object requesting this
*/
- (@action)subscript:(id)aSender
{
    [self _changeCharacterAttribute:CPSuperscriptAttributeName byAmount:-1];
}

/*!
    Removes the superscript level and the baseline offset of the selected text, or of the text
    typed next when nothing is selected.
    @param aSender the object requesting this
*/
- (@action)unscript:(id)aSender
{
    [self _removeCharacterAttributes:[CPSuperscriptAttributeName, CPBaselineOffsetAttributeName]];
}

/*!
    Raises the baseline of the selected text by one point, or of the text typed next when
    nothing is selected.
    @param aSender the object requesting this
*/
- (@action)raiseBaseline:(id)aSender
{
    [self _changeCharacterAttribute:CPBaselineOffsetAttributeName byAmount:1.0];
}

/*!
    Lowers the baseline of the selected text by one point, or of the text typed next when
    nothing is selected.
    @param aSender the object requesting this
*/
- (@action)lowerBaseline:(id)aSender
{
    [self _changeCharacterAttribute:CPBaselineOffsetAttributeName byAmount:-1.0];
}

/* @ignore
    Adds anAmount to a numeric character attribute, run by run across the selection, or in the
    typing attributes when nothing is selected. A value that reaches zero removes the attribute.
*/
- (void)_changeCharacterAttribute:(CPString)anAttributeName byAmount:(float)anAmount
{
    var range = CPMakeRangeCopy(_selectionRange);

    if (!range.length)
    {
        var newValue = ([_typingAttributes objectForKey:anAttributeName] || 0) + anAmount;

        if (newValue)
            [_typingAttributes setObject:newValue forKey:anAttributeName];
        else
            [_typingAttributes removeObjectForKey:anAttributeName];

        [[CPNotificationCenter defaultCenter] postNotificationName:CPTextViewDidChangeTypingAttributesNotification object:self];
        return;
    }

    if (![self _beginCharacterAttributeChangeInRange:range])
        return;

    var location = range.location,
        end = CPMaxRange(range);

    while (location < end)
    {
        var effectiveRange = CPMakeRange(0, 0),
            value = [_textStorage attribute:anAttributeName atIndex:location effectiveRange:effectiveRange] || 0,
            runRange = CPIntersectionRange(effectiveRange, range),
            newValue = value + anAmount;

        if (!runRange.length)
            runRange = CPMakeRange(location, end - location);

        if (newValue)
            [_textStorage addAttribute:anAttributeName value:newValue range:runRange];
        else
            [_textStorage removeAttribute:anAttributeName range:runRange];

        location = CPMaxRange(runRange);
    }

    [self _endCharacterAttributeChangeInRange:range];
}

/* @ignore
    Removes character attributes from the selection, or from the typing attributes when nothing
    is selected.
*/
- (void)_removeCharacterAttributes:(CPArray)attributeNames
{
    var range = CPMakeRangeCopy(_selectionRange);

    if (!range.length)
    {
        for (var i = 0; i < attributeNames.length; i++)
            [_typingAttributes removeObjectForKey:attributeNames[i]];

        [[CPNotificationCenter defaultCenter] postNotificationName:CPTextViewDidChangeTypingAttributesNotification object:self];
        return;
    }

    if (![self _beginCharacterAttributeChangeInRange:range])
        return;

    for (var i = 0; i < attributeNames.length; i++)
        [_textStorage removeAttribute:attributeNames[i] range:CPMakeRangeCopy(range)];

    [self _endCharacterAttributeChangeInRange:range];
}

/* @ignore
    Asks whether the change may happen, and registers undo for the attributes in aRange.
*/
- (BOOL)_beginCharacterAttributeChangeInRange:(CPRange)aRange
{
    if (![self isEditable] || ![self isRichText] || ![self shouldChangeTextInRange:aRange replacementString:nil])
        return NO;

    // Undo restores the text's previous attributes, and registers the reverse for redo.
    [[[self _registeringUndoManager] prepareWithInvocationTarget:self]
                _replaceCharactersInRange:CPMakeRangeCopy(aRange)
                     withAttributedString:[_textStorage attributedSubstringFromRange:CPMakeRangeCopy(aRange)]
                           selectionRange:CPMakeRangeCopy(_selectionRange)];

    return YES;
}

/* @ignore
    Lays the changed text out again and shows it.
*/
- (void)_endCharacterAttributeChangeInRange:(CPRange)aRange
{
    [_layoutManager textStorage:_textStorage edited:0 range:CPMakeRangeCopy(aRange) changeInLength:0 invalidatedRange:CPMakeRangeCopy(aRange)];
    [_layoutManager _validateLayoutAndGlyphs];
    [self sizeToFit];
    [self setNeedsDisplay:YES];
    [self didChangeText];
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
        var undoManager = [self _registeringUndoManager];
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

- (void)setBoundsSize:(CGSize)aSize
{
    _exposedRect = nil; // Clear the cached visible rect when bounds change
    [super setBoundsSize:aSize];
}

- (void)setFrameSize:(CGSize)aSize
{
    _exposedRect = nil; // Clear the cached visible rect so it gets recalculated at the new size

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
        {
            rect = CGRectCreateCopy([_layoutManager extraLineFragmentRect]);
            rect.size.width = 1.0;
        }
        else
        {
            rect = CGRectCreateCopy([_layoutManager boundingRectForGlyphRange:CPMakeRange(aRange.location, 1) inTextContainer:_textContainer]);
            rect.size.width = 1.0;
        }
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
        // Like the empty line after text, the caret starts inside the line fragment padding.
        return CGRectMake(MAX(1.0, [_textContainer lineFragmentPadding]), ([font ascender] - [font descender]) * 0.5 + _textContainerOrigin.y, 1, [font size]);
    }

    // cursor is at a newline character -> jump to next line
    if (_selectionRange.location == numberOfGlyphs && _isNewlineCharacter([[_textStorage string] characterAtIndex:_selectionRange.location - 1]))
        return CGRectCreateCopy([_layoutManager extraLineFragmentRect]);

    var caretRect = [_layoutManager boundingRectForGlyphRange:CPMakeRange(_selectionRange.location, 1) inTextContainer:_textContainer];

    var loc = (_selectionRange.location == numberOfGlyphs) ? _selectionRange.location - 1 : _selectionRange.location,
        caretOffset = [_layoutManager _characterOffsetAtLocation:loc],
        font = [_textStorage attribute:CPFontAttributeName atIndex:loc effectiveRange:nil] || [self font];

    if (caretOffset > 0)
    {
        caretRect.origin.y += caretOffset;
    }

    // Set the caret height to match the size of the active font
    caretRect.size.height = [font size];

    if (_selectionRange.location == numberOfGlyphs)
        caretRect.origin.x += caretRect.size.width;

    caretRect.origin.x += _textContainerOrigin.x;
    caretRect.origin.y += _textContainerOrigin.y;

    caretRect.size.width = MAX(1.0, caretRect.size.width);
    caretRect.size.height = MAX(1.0, caretRect.size.height) + 2;

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

// MARK: -
// MARK: Dragging operation

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

    [self setString:[[CPAttributedString alloc] initWithString:_placeholderString attributes:@{CPForegroundColorAttributeName:[CPColor colorWithRed:0.66 green:0.66 blue:0.66 alpha:1]}]];
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

/*
    The represented objects of the paragraph indent markers. Tab stop markers represent
    their CPTextTab.
*/
var CPTextViewFirstLineIndentMarker = @"CPTextViewFirstLineIndentMarker",
    CPTextViewHeadIndentMarker      = @"CPTextViewHeadIndentMarker",
    CPTextViewTailIndentMarker      = @"CPTextViewTailIndentMarker";

/*
    The thickness the text view reserves for its markers above the ruler's baseline.
*/
var CPTextViewRulerMarkerThickness = 9.0;

/*
    The marker images, created on first use: { image, origin } by name.
*/
var CPTextViewRulerMarkerImages = nil;

var compareTabStops = function(obj1, obj2, context)
{
    if ([obj1 location] < [obj2 location])
        return CPOrderedAscending;

    if ([obj1 location] > [obj2 location])
        return CPOrderedDescending;

    return CPOrderedSame;
};

/*
    Returns an SVG image of the given size. SVG images stay sharp at any display resolution.
*/
var _CPTextViewRulerSVGImage = function(aWidth, aHeight, aBody)
{
    var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="' + aWidth + '" height="' + aHeight + '" viewBox="0 0 ' + aWidth + ' ' + aHeight + '">' + aBody + '</svg>';

    return [[CPImage alloc] initWithContentsOfFile:@"data:image/svg+xml;charset=utf-8," + encodeURIComponent(svg) size:CGSizeMake(aWidth, aHeight)];
};

/*
    Returns the image and image origin for a marker. Tab stop images are triangles above
    the ruler's baseline: a left tab's flat side and a right tab's flat side lie at the
    stop, and a centre or decimal tab points down at it. The first line indent marker
    points down at the baseline from above, and the head and tail indent markers point up
    at it from below.
*/
var _CPTextViewRulerMarkerImage = function(aName)
{
    if (!CPTextViewRulerMarkerImages)
    {
        // Tab stops keep the triangles that the ruler has always shown: pointing right for a left tab, left for a
        // right tab and down for a centre or decimal tab, with the flat side or the point at the stop.
        var tab = 'fill="#505050" stroke="#303030" stroke-width="1" stroke-linejoin="round"',
            triangle = 'fill="#606060" stroke="#303030" stroke-width="1"';

        CPTextViewRulerMarkerImages = {
            leftTab:    { image: _CPTextViewRulerSVGImage(8, 8, '<path d="M0.5 0.5 L7.5 4 L0.5 7.5 Z" ' + tab + '/>'), origin: CGPointMake(0.0, 8.0) },
            rightTab:   { image: _CPTextViewRulerSVGImage(8, 8, '<path d="M7.5 0.5 L0.5 4 L7.5 7.5 Z" ' + tab + '/>'), origin: CGPointMake(8.0, 8.0) },
            centerTab:  { image: _CPTextViewRulerSVGImage(9, 8, '<path d="M0.5 0.5 H8.5 L4.5 7.5 Z" ' + tab + '/>'), origin: CGPointMake(4.0, 8.0) },
            decimalTab: { image: _CPTextViewRulerSVGImage(9, 8, '<path d="M0.5 0.5 H8.5 L4.5 7.5 Z" ' + tab + '/><circle cx="4.5" cy="3" r="1.2" fill="#f4f4f4"/>'), origin: CGPointMake(4.0, 8.0) },
            downIndent: { image: _CPTextViewRulerSVGImage(9, 6, '<path d="M0.5 0.5 H8.5 L4.5 5.5 Z" ' + triangle + '/>'), origin: CGPointMake(4.0, 6.0) },
            upIndent:   { image: _CPTextViewRulerSVGImage(9, 6, '<path d="M4.5 0.5 L8.5 5.5 H0.5 Z" ' + triangle + '/>'), origin: CGPointMake(4.0, 0.0) }
        };
    }

    return CPTextViewRulerMarkerImages[aName];
};

/*
    Returns the name of the marker image for a tab stop of the given type.
*/
var _CPTextViewRulerImageNameForTab = function(aTab)
{
    switch ([aTab tabStopType])
    {
        case CPRightTabStopType:
            return "rightTab";

        case CPCenterTabStopType:
            return "centerTab";

        case CPDecimalTabStopType:
            return "decimalTab";

        default:
            return "leftTab";
    }
};

/*!
    Ruler support. A text view in a scroll view can show a horizontal ruler with the tab
    stops and indents of the paragraph at the selection. The user changes them by dragging
    the markers, adds a left tab stop by clicking the ruler, and removes a tab stop by
    dragging it off the ruler. Marker locations are in the text view's coordinate system,
    and the ruler's zero lines up with the start of the text.
*/
@implementation CPTextView (CPRulerSupport)

// MARK: Ruler Control

/*!
    Returns \c YES if the text view uses a ruler. The default is \c YES.
*/
- (BOOL)usesRuler
{
    return _usesRuler;
}

/*!
    Sets whether the text view uses a ruler. A text view that does not use a ruler hides it.
    @param shouldUseRuler \c YES to use a ruler
*/
- (void)setUsesRuler:(BOOL)shouldUseRuler
{
    if (_usesRuler === shouldUseRuler)
        return;

    _usesRuler = shouldUseRuler;

    if (_usesRuler)
        [self updateRuler];
    else
        [self setRulerVisible:NO];
}

/*!
    Returns \c YES if the enclosing scroll view shows its horizontal ruler.
*/
- (BOOL)isRulerVisible
{
    var scrollView = [self enclosingScrollView];

    return !!scrollView && [scrollView hasHorizontalRuler] && [scrollView rulersVisible];
}

/*!
    Shows or hides the enclosing scroll view's horizontal ruler. The ruler is shown only if
    the text view uses a ruler.
    @param shouldBeVisible \c YES to show the ruler
*/
- (void)setRulerVisible:(BOOL)shouldBeVisible
{
    var scrollView = [self enclosingScrollView];

    if (!scrollView || (shouldBeVisible && !_usesRuler))
        return;

    if (shouldBeVisible)
        [scrollView setHasHorizontalRuler:YES];

    [scrollView setRulersVisible:shouldBeVisible];

    if (shouldBeVisible)
        [self updateRuler];
}

/*!
    Shows the ruler if it is hidden, and hides it if it is shown.
    @param aSender the object requesting this
*/
- (@action)toggleRuler:(id)aSender
{
    [self setRulerVisible:![self isRulerVisible]];
}

/*!
    Copies the paragraph style at the selection, with its tab stops, indents and alignment,
    to the ruler pasteboard, so that Paste Ruler can apply it to other paragraphs.
    @param aSender the object requesting this
*/
- (@action)copyRuler:(id)aSender
{
    var pasteboard = [CPPasteboard pasteboardWithName:CPRulerPboard];

    [pasteboard declareTypes:[CPRulerPboardType] owner:nil];
    [pasteboard setData:[CPKeyedArchiver archivedDataWithRootObject:[self _rulerParagraphStyle]] forType:CPRulerPboardType];
}

/*!
    Applies the paragraph style on the ruler pasteboard to the selected paragraphs, or to
    the paragraph at the insertion point. When the style or the paragraphs belong to text
    lists, the whole paragraphs change, and their list markers are added, removed and
    numbered as for Format > List.
    @param aSender the object requesting this
*/
- (@action)pasteRuler:(id)aSender
{
    var data = [[CPPasteboard pasteboardWithName:CPRulerPboard] dataForType:CPRulerPboardType];

    if (!data)
        return;

    var paragraphStyle = [CPKeyedUnarchiver unarchiveObjectWithData:data];

    if ([[paragraphStyle textLists] count] || [self _selectionTouchesTextList])
        [self _pasteRulerParagraphStyleWithTextLists:paragraphStyle];
    else
        [self _applyRulerParagraphStyle:paragraphStyle];
}

/*!
    Shows the tab stops and indents of the paragraph at the selection on the ruler, and
    lines the ruler's zero up with the start of the text. Does nothing while the user drags
    a marker, or when the ruler is hidden.
*/
- (void)updateRuler
{
    if (!_usesRuler || ![self isRulerVisible])
        return;

    var scrollView = [self enclosingScrollView],
        ruler = [scrollView horizontalRulerView];

    if (!ruler || [self _rulerHasDraggedMarker:ruler])
        return;

    [ruler setClientView:self];
    [ruler setReservedThicknessForMarkers:CPTextViewRulerMarkerThickness];
    [ruler setOriginOffset:[self convertPoint:CGPointMake([self _rulerTextStart], 0.0) toView:[scrollView documentView]].x];

    var paragraphStyle = [self _rulerParagraphStyle],
        markers = [],
        tabStops = [paragraphStyle tabStops],
        count = [tabStops count];

    for (var i = 0; i < count; i++)
        markers.push([self _rulerMarkerForTab:tabStops[i] inRuler:ruler]);

    markers.push([self _rulerIndentMarker:CPTextViewFirstLineIndentMarker imageName:"downIndent" location:[self _rulerLocationForIndent:[paragraphStyle firstLineHeadIndent]] inRuler:ruler]);
    markers.push([self _rulerIndentMarker:CPTextViewHeadIndentMarker imageName:"upIndent" location:[self _rulerLocationForIndent:[paragraphStyle headIndent]] inRuler:ruler]);
    markers.push([self _rulerIndentMarker:CPTextViewTailIndentMarker imageName:"upIndent" location:[self _rulerLocationForTailIndent:[paragraphStyle tailIndent]] inRuler:ruler]);

    [ruler setMarkers:markers];
}

// MARK: Ruler Client Methods

/*!
    Adds a left tab stop where the user clicks the ruler, and lets the user drag it into
    place before releasing it.
*/
- (void)rulerView:(CPRulerView)aRulerView handleMouseDown:(CPEvent)anEvent
{
    if (![self isEditable])
        return;

    var point = [aRulerView convertPoint:[anEvent locationInWindow] fromView:nil],
        location = [aRulerView _locationForRulerPoint:point.x],
        tab = [[CPTextTab alloc] initWithType:CPLeftTabStopType location:location - [self _rulerTextStart]],
        marker = [self _rulerMarkerForTab:tab inRuler:aRulerView];

    [marker setMarkerLocation:location];
    [aRulerView trackMarker:marker withMouseEvent:anEvent];
}

- (BOOL)rulerView:(CPRulerView)aRulerView shouldAddMarker:(CPRulerMarker)aMarker
{
    return [self isEditable];
}

- (float)rulerView:(CPRulerView)aRulerView willAddMarker:(CPRulerMarker)aMarker atLocation:(float)aLocation
{
    return [self _constrainedRulerLocation:aLocation forMarker:aMarker];
}

- (void)rulerView:(CPRulerView)aRulerView didAddMarker:(CPRulerMarker)aMarker
{
    var paragraphStyle = [[self _rulerParagraphStyle] mutableCopy],
        tab = [[CPTextTab alloc] initWithType:[[aMarker representedObject] tabStopType] location:[aMarker markerLocation] - [self _rulerTextStart]],
        tabs = [[paragraphStyle tabStops] mutableCopy];

    [tabs addObject:tab];
    [tabs sortUsingFunction:compareTabStops context:nil];
    [paragraphStyle setTabStops:tabs];

    [aMarker setRepresentedObject:tab];
    [self _applyRulerParagraphStyle:paragraphStyle];
}

- (BOOL)rulerView:(CPRulerView)aRulerView shouldMoveMarker:(CPRulerMarker)aMarker
{
    return [self isEditable];
}

- (float)rulerView:(CPRulerView)aRulerView willMoveMarker:(CPRulerMarker)aMarker toLocation:(float)aLocation
{
    return [self _constrainedRulerLocation:aLocation forMarker:aMarker];
}

- (void)rulerView:(CPRulerView)aRulerView didMoveMarker:(CPRulerMarker)aMarker
{
    var paragraphStyle = [[self _rulerParagraphStyle] mutableCopy],
        representedObject = [aMarker representedObject],
        location = [aMarker markerLocation];

    if ([representedObject isKindOfClass:[CPTextTab class]])
    {
        var tab = [[CPTextTab alloc] initWithType:[representedObject tabStopType] location:location - [self _rulerTextStart]],
            tabs = [[paragraphStyle tabStops] mutableCopy];

        [tabs removeObjectAtIndex:[self _indexOfTab:representedObject inTabs:tabs]];
        [tabs addObject:tab];
        [tabs sortUsingFunction:compareTabStops context:nil];
        [paragraphStyle setTabStops:tabs];
        [aMarker setRepresentedObject:tab];
    }
    else if (representedObject === CPTextViewFirstLineIndentMarker)
        [paragraphStyle setFirstLineHeadIndent:location - [self _rulerTextStart]];

    else if (representedObject === CPTextViewHeadIndentMarker)
        [paragraphStyle setHeadIndent:location - [self _rulerTextStart]];

    else if (representedObject === CPTextViewTailIndentMarker)
        [paragraphStyle setTailIndent:[self _tailIndentForRulerLocation:location currentTailIndent:[paragraphStyle tailIndent]]];

    [self _applyRulerParagraphStyle:paragraphStyle];
}

- (BOOL)rulerView:(CPRulerView)aRulerView shouldRemoveMarker:(CPRulerMarker)aMarker
{
    return [self isEditable] && [[aMarker representedObject] isKindOfClass:[CPTextTab class]];
}

- (void)rulerView:(CPRulerView)aRulerView didRemoveMarker:(CPRulerMarker)aMarker
{
    [self _removeRulerTab:[aMarker representedObject]];
}

/* @ignore
    Returns the context menu for a marker: tab stop types and removal for a tab stop, and
    a reset for an indent.
*/
- (CPMenu)_rulerView:(CPRulerView)aRulerView menuForMarker:(CPRulerMarker)aMarker
{
    if (![self isEditable])
        return nil;

    var menu = [[CPMenu alloc] initWithTitle:@""],
        representedObject = [aMarker representedObject];

    if ([representedObject isKindOfClass:[CPTextTab class]])
    {
        var types = [[CPLeftTabStopType, @"Left Tab"], [CPCenterTabStopType, @"Center Tab"], [CPRightTabStopType, @"Right Tab"], [CPDecimalTabStopType, @"Decimal Tab"]];

        for (var i = 0; i < types.length; i++)
        {
            var item = [menu addItemWithTitle:types[i][1] action:@selector(_changeRulerTabType:) keyEquivalent:@""];

            [item setTarget:self];
            [item setTag:types[i][0]];
            [item setRepresentedObject:aMarker];
            [item setState:[representedObject tabStopType] === types[i][0] ? CPOnState : CPOffState];
        }

        [menu addItem:[CPMenuItem separatorItem]];

        var removeItem = [menu addItemWithTitle:@"Remove Tab" action:@selector(_removeRulerTabFromMenu:) keyEquivalent:@""];

        [removeItem setTarget:self];
        [removeItem setRepresentedObject:aMarker];
    }
    else
    {
        var resetItem = [menu addItemWithTitle:@"Reset Indent" action:@selector(_resetRulerIndent:) keyEquivalent:@""];

        [resetItem setTarget:self];
        [resetItem setRepresentedObject:aMarker];
    }

    return menu;
}

/* @ignore */
- (void)_changeRulerTabType:(id)aSender
{
    var marker = [aSender representedObject],
        oldTab = [marker representedObject],
        paragraphStyle = [[self _rulerParagraphStyle] mutableCopy],
        tabs = [[paragraphStyle tabStops] mutableCopy],
        index = [self _indexOfTab:oldTab inTabs:tabs];

    if (index === CPNotFound)
        return;

    [tabs replaceObjectAtIndex:index withObject:[[CPTextTab alloc] initWithType:[aSender tag] location:[oldTab location]]];
    [paragraphStyle setTabStops:tabs];
    [self _applyRulerParagraphStyle:paragraphStyle];
}

/* @ignore */
- (void)_removeRulerTabFromMenu:(id)aSender
{
    [self _removeRulerTab:[[aSender representedObject] representedObject]];
}

/* @ignore */
- (void)_resetRulerIndent:(id)aSender
{
    var representedObject = [[aSender representedObject] representedObject],
        paragraphStyle = [[self _rulerParagraphStyle] mutableCopy];

    if (representedObject === CPTextViewFirstLineIndentMarker)
        [paragraphStyle setFirstLineHeadIndent:0.0];

    else if (representedObject === CPTextViewHeadIndentMarker)
        [paragraphStyle setHeadIndent:0.0];

    else if (representedObject === CPTextViewTailIndentMarker)
        [paragraphStyle setTailIndent:0.0];

    [self _applyRulerParagraphStyle:paragraphStyle];
}

// MARK: Ruler Support

/* @ignore */
- (BOOL)_rulerHasDraggedMarker:(CPRulerView)aRulerView
{
    var markers = [aRulerView markers];

    for (var i = 0; i < markers.length; i++)
        if ([markers[i] isDragging])
            return YES;

    return NO;
}

/* @ignore */
- (void)_removeRulerTab:(CPTextTab)aTab
{
    var paragraphStyle = [[self _rulerParagraphStyle] mutableCopy],
        tabs = [[paragraphStyle tabStops] mutableCopy],
        index = [self _indexOfTab:aTab inTabs:tabs];

    if (index === CPNotFound)
        return;

    [tabs removeObjectAtIndex:index];
    [paragraphStyle setTabStops:tabs];
    [self _applyRulerParagraphStyle:paragraphStyle];
}

/* @ignore */
- (CPRulerMarker)_rulerMarkerForTab:(CPTextTab)aTab inRuler:(CPRulerView)aRulerView
{
    var imageInfo = _CPTextViewRulerMarkerImage(_CPTextViewRulerImageNameForTab(aTab)),
        marker = [[CPRulerMarker alloc] initWithRulerView:aRulerView
                                           markerLocation:[self _rulerLocationForIndent:[aTab location]]
                                                    image:imageInfo.image
                                              imageOrigin:imageInfo.origin];

    [marker setRemovable:YES];
    [marker setRepresentedObject:aTab];

    return marker;
}

/* @ignore */
- (CPRulerMarker)_rulerIndentMarker:(CPString)aRepresentedObject imageName:(CPString)anImageName location:(float)aLocation inRuler:(CPRulerView)aRulerView
{
    var imageInfo = _CPTextViewRulerMarkerImage(anImageName),
        marker = [[CPRulerMarker alloc] initWithRulerView:aRulerView markerLocation:aLocation image:imageInfo.image imageOrigin:imageInfo.origin];

    [marker setRepresentedObject:aRepresentedObject];

    return marker;
}

/* @ignore
    Returns the position, in the text view's coordinate system, where lines of text start.
*/
- (float)_rulerTextStart
{
    return _textContainerOrigin.x + [_textContainer lineFragmentPadding];
}

/* @ignore
    Returns the width available to lines of text.
*/
- (float)_rulerTextWidth
{
    return [_textContainer containerSize].width - 2.0 * [_textContainer lineFragmentPadding];
}

/* @ignore */
- (float)_rulerLocationForIndent:(float)anIndent
{
    return [self _rulerTextStart] + anIndent;
}

/* @ignore
    A positive tail indent is measured from the start of the text, and a zero or negative
    one from its end.
*/
- (float)_rulerLocationForTailIndent:(float)aTailIndent
{
    if (aTailIndent > 0.0)
        return [self _rulerTextStart] + aTailIndent;

    return [self _rulerTextStart] + [self _rulerTextWidth] + aTailIndent;
}

/* @ignore
    Converts a tail indent marker location back to a tail indent, keeping the way the
    current tail indent is measured.
*/
- (float)_tailIndentForRulerLocation:(float)aLocation currentTailIndent:(float)aTailIndent
{
    var fromStart = aLocation - [self _rulerTextStart];

    if (aTailIndent > 0.0)
        return fromStart;

    return MIN(0.0, fromStart - [self _rulerTextWidth]);
}

/* @ignore */
- (CPUInteger)_indexOfTab:(CPTextTab)aTab inTabs:(CPArray)tabs
{
    for (var i = 0; i < tabs.length; i++)
        if ([tabs[i] location] === [aTab location] && [tabs[i] tabStopType] === [aTab tabStopType])
            return i;

    return CPNotFound;
}

/* @ignore
    Returns the paragraph style at the selection, or the typing attributes' style in empty text.
*/
- (CPParagraphStyle)_rulerParagraphStyle
{
    var attributes = _typingAttributes,
        textLength = [_textStorage length];

    if (textLength > 0)
        attributes = [_textStorage attributesAtIndex:MAX(0, MIN(_selectionRange.location, textLength - 1)) effectiveRange:nil];

    return [attributes objectForKey:CPParagraphStyleAttributeName] || [CPParagraphStyle defaultParagraphStyle];
}

/* @ignore
    Returns the range that ruler changes apply to: the selection, or the paragraph at the
    insertion point.
*/
- (CPRange)_rulerTargetRange
{
    if (_selectionRange.length > 0 || ![_textStorage length])
        return CPMakeRangeCopy(_selectionRange);

    return [self selectionRangeForProposedRange:CPMakeRange(_selectionRange.location, 0) granularity:CPSelectByParagraph];
}

/* @ignore
    Applies a paragraph style changed through the ruler to the target range and the typing
    attributes, lays the text out again and refreshes the ruler.
*/
- (void)_applyRulerParagraphStyle:(CPParagraphStyle)aParagraphStyle
{
    var targetRange = [self _rulerTargetRange];

    if (targetRange.length > 0)
    {
        // Undo restores the paragraphs' previous attributes, and registers the reverse for redo.
        [[[self _registeringUndoManager] prepareWithInvocationTarget:self]
                    _replaceCharactersInRange:CPMakeRangeCopy(targetRange)
                         withAttributedString:[_textStorage attributedSubstringFromRange:CPMakeRangeCopy(targetRange)]
                               selectionRange:CPMakeRangeCopy(_selectionRange)];

        [_textStorage addAttribute:CPParagraphStyleAttributeName value:aParagraphStyle range:CPMakeRangeCopy(targetRange)];
        [_layoutManager textStorage:_textStorage edited:0 range:CPMakeRangeCopy(targetRange) changeInLength:0 invalidatedRange:CPMakeRangeCopy(targetRange)];
    }

    [_typingAttributes setObject:aParagraphStyle forKey:CPParagraphStyleAttributeName];
    [[CPNotificationCenter defaultCenter] postNotificationName:CPTextViewDidChangeTypingAttributesNotification object:self];

    [_layoutManager _validateLayoutAndGlyphs];
    [self sizeToFit];
    [self setNeedsDisplay:YES];
    [self updateRuler];
}

/* @ignore
    Constrains a marker location, in the text view's coordinate system. Indent markers stay
    within the text width. Tab stops stay between their neighbouring tab stops, within the
    right margin, and after the text that precedes them on the lines they affect.
*/
- (float)_constrainedRulerLocation:(float)aLocation forMarker:(CPRulerMarker)aMarker
{
    var textStart = [self _rulerTextStart],
        textWidth = [self _rulerTextWidth],
        proposed = aLocation - textStart,
        representedObject = [aMarker representedObject];

    if (![representedObject isKindOfClass:[CPTextTab class]])
        return textStart + MAX(0.0, MIN(textWidth, proposed));

    var paragraphStyle = [self _rulerParagraphStyle],
        tabStops = [paragraphStyle tabStops] || [],
        tabCount = [tabStops count],
        isMoving = [[[aMarker ruler] markers] containsObjectIdenticalTo:aMarker],
        targetTabIndex = isMoving ? [self _indexOfTab:representedObject inTabs:tabStops] : CPNotFound,
        safetySpacer = 2.0,
        minLocation = 0.0,
        maxLocation = textWidth,
        tailIndent = [paragraphStyle tailIndent];

    // Right boundary: the tail indent.
    if (tailIndent > 0.0)
        maxLocation = MIN(maxLocation, tailIndent);
    else if (tailIndent < 0.0)
        maxLocation = MIN(maxLocation, textWidth + tailIndent);

    // Neighbouring tab stops.
    if (targetTabIndex !== CPNotFound)
    {
        if (targetTabIndex > 0)
            minLocation = MAX(minLocation, [tabStops[targetTabIndex - 1] location] + safetySpacer);

        if (targetTabIndex + 1 < tabCount)
            maxLocation = MIN(maxLocation, [tabStops[targetTabIndex + 1] location] - safetySpacer);
    }
    else
    {
        for (var i = 0; i < tabCount; i++)
        {
            var tabLocation = [tabStops[i] location];

            if (tabLocation < proposed)
                minLocation = MAX(minLocation, tabLocation + safetySpacer);
            else if (tabLocation > proposed)
                maxLocation = MIN(maxLocation, tabLocation - safetySpacer);
        }
    }

    // Text before the tab characters that use this tab stop.
    var targetRange = [self _rulerTargetRange],
        theString = [_textStorage string],
        end = CPMaxRange(targetRange),
        tabCountInLine = 0,
        lineStart = targetRange.location;

    if (targetRange.length > 0)
        [_layoutManager _validateLayoutAndGlyphs];

    for (var i = targetRange.location; i < end; i++)
    {
        var charCode = theString.charCodeAt(i);

        if (charCode === 10 || charCode === 13)
        {
            tabCountInLine = 0;
            lineStart = i + 1;
            continue;
        }

        if (charCode !== 9)
            continue;

        if (tabCountInLine === targetTabIndex || targetTabIndex === CPNotFound)
        {
            var precedingX;

            if (i === lineStart)
            {
                var isFirstLine = lineStart === 0 || theString.charCodeAt(lineStart - 1) === 10 || theString.charCodeAt(lineStart - 1) === 13;
                precedingX = isFirstLine ? [paragraphStyle firstLineHeadIndent] : [paragraphStyle headIndent];
            }
            else
                precedingX = CGRectGetMaxX([_layoutManager boundingRectForGlyphRange:CPMakeRange(i - 1, 1) inTextContainer:_textContainer]);

            minLocation = MAX(minLocation, precedingX + safetySpacer);
        }

        tabCountInLine++;
    }

    if (minLocation > maxLocation)
        minLocation = maxLocation;

    return textStart + MIN(maxLocation, MAX(minLocation, proposed));
}

@end

/*
    The indent of each list level, and the distance from the start of a level to its markers,
    in points. As in TextEdit, the first level's markers start 11 points in, and its text starts
    36 points in.
*/
var CPTextViewTextListLevelIndent = 36.0,
    CPTextViewTextListMarkerIndent = 11.0;

/*
    The list styles that -changeTextList: applies, by the tag of the sender. Tag 0, or any tag
    not listed, removes the list.
*/
var CPTextViewTextListStyles = {
        1:  {format: @"{disc}",          options: 0},
        2:  {format: @"{circle}",        options: 0},
        3:  {format: @"{square}",        options: 0},
        4:  {format: @"{hyphen}",        options: 0},
        10: {format: @"{decimal}.",      options: 0},
        11: {format: @"{lower-alpha}.",  options: 0},
        12: {format: @"{upper-alpha}.",  options: 0},
        13: {format: @"{lower-roman}.",  options: 0},
        14: {format: @"{upper-roman}.",  options: 0},
        20: {format: @"{decimal}.",      options: CPTextListPrependEnclosingMarker}
    };

/*!
    Text list support. As in Cocoa, the markers of a list are ordinary text at the start of each
    item: a tab, the marker and another tab. The paragraph style of an item lists its text lists,
    outermost first, and sets the indents and tab stops that place the marker and the text.
    Return in an item starts the next item, and Return in an empty item ends the list. Tab at the
    start of an item makes it an item of a nested list, and Shift-Tab returns it to the enclosing
    list. Delete at the start of an item's text removes the item from its list. After every change,
    the markers of the lists around the change are numbered again.
*/
@implementation CPTextView (CPTextListSupport)

// MARK: Changing Lists

/*!
    Applies the list style that the sender's tag selects to the selected paragraphs, or to the
    paragraph at the insertion point. The tags are: 0 for no list; 1 bullet, 2 circle, 3 square
    and 4 hyphen; 10 for 1. 2. 3., 11 for a. b. c., 12 for A. B. C., 13 for i. ii. iii. and 14
    for I. II. III.; 20 for 1. with nested items numbered 1.1. A paragraph next to a list of the
    same style at the same level joins that list, so that its numbering continues.
    @param aSender the menu item or control that requests the change
*/
- (@action)changeTextList:(id)aSender
{
    var style = CPTextViewTextListStyles[[aSender tag]];

    [self setTextList:style ? [self _textListWithMarkerFormat:style.format options:style.options] : nil];
}

/* @ignore
    Returns the list of the paragraph just before or after the selected paragraphs when it has
    the marker format and options at the selection's level, or a new list.
*/
- (CPTextList)_textListWithMarkerFormat:(CPString)aFormat options:(unsigned)anOptions
{
    var paragraphsRange = [self _textListParagraphsRangeForRange:_selectionRange],
        level = MAX(1, [[_textStorage _textListsOfParagraphAtIndex:paragraphsRange.location] count]),
        neighbours = [];

    if (paragraphsRange.location > 0)
        neighbours.push([_textStorage _paragraphRangeForIndex:paragraphsRange.location - 1].location);

    if (CPMaxRange(paragraphsRange) < [_textStorage length])
        neighbours.push(CPMaxRange(paragraphsRange));

    for (var i = 0; i < neighbours.length; i++)
    {
        var lists = [_textStorage _textListsOfParagraphAtIndex:neighbours[i]],
            list = [lists lastObject];

        if ([lists count] === level && [list markerFormat] === aFormat && [list listOptions] === anOptions)
            return list;
    }

    return [[CPTextList alloc] initWithMarkerFormat:aFormat options:anOptions];
}

/* @ignore
    Returns YES if the menu item's tag selects the style of the innermost list at the
    selection, or no list when the selection is not in a list.
*/
- (BOOL)_textListStyleMatchesItem:(id)anItem
{
    var paragraphStart = [_textStorage _paragraphRangeForIndex:_selectionRange.location].location,
        list = [[_textStorage _textListsOfParagraphAtIndex:paragraphStart] lastObject],
        style = CPTextViewTextListStyles[[anItem tag]];

    if (!list)
        return !style;

    return !!style && [list markerFormat] === style.format && [list listOptions] === style.options;
}

/*!
    Makes the selected paragraphs, or the paragraph at the insertion point, items of aList. A
    paragraph that is already an item of a list changes to aList at the same level. With \c nil,
    the paragraphs are removed from their lists, at every level.
    @param aList the list, or \c nil
*/
- (void)setTextList:(CPTextList)aList
{
    if (![self isRichText])
        return;

    var paragraphsRange = [self _textListParagraphsRangeForRange:_selectionRange],
        listsForParagraphs = [],
        location = paragraphsRange.location;

    do
    {
        var paragraphRange = [_textStorage _paragraphRangeForIndex:location],
            lists = [[_textStorage _textListsOfParagraphAtIndex:paragraphRange.location] copy];

        if (!aList)
            lists = [];
        else if ([lists count])
            lists[[lists count] - 1] = aList;
        else
            lists = [aList];

        listsForParagraphs.push(lists);
        location = CPMaxRange(paragraphRange);
    }
    while (location < CPMaxRange(paragraphsRange));

    [self _setTextLists:listsForParagraphs forParagraphsInRange:paragraphsRange];
}

/* @ignore
    Makes the item at the insertion point an item of a list nested in its list. The item joins
    the nested list of the item before it, when there is one, so that its numbering continues.
    Otherwise a new nested list takes the marker format and options of the enclosing list.
*/
- (void)_indentTextListItemAtIndex:(unsigned)anIndex
{
    var paragraphRange = [_textStorage _paragraphRangeForIndex:anIndex],
        lists = [_textStorage _textListsOfParagraphAtIndex:paragraphRange.location],
        level = [lists count],
        nestedList = nil;

    if (paragraphRange.location > 0)
    {
        var previousRange = [_textStorage _paragraphRangeForIndex:paragraphRange.location - 1],
            previousLists = [_textStorage _textListsOfParagraphAtIndex:previousRange.location];

        if ([previousLists count] > level && [[previousLists subarrayWithRange:CPMakeRange(0, level)] isEqualToArray:lists])
            nestedList = previousLists[level];
    }

    if (!nestedList)
    {
        var enclosingList = [lists lastObject];

        nestedList = [[CPTextList alloc] initWithMarkerFormat:[enclosingList markerFormat] options:[enclosingList listOptions]];
    }

    [self _setTextLists:[[lists arrayByAddingObject:nestedList]] forParagraphsInRange:paragraphRange];
}

/* @ignore
    Returns the item at anIndex to the enclosing list, or removes it from its list when the list
    is not nested.
*/
- (void)_outdentTextListItemAtIndex:(unsigned)anIndex
{
    var paragraphRange = [_textStorage _paragraphRangeForIndex:anIndex],
        lists = [_textStorage _textListsOfParagraphAtIndex:paragraphRange.location];

    [self _setTextLists:[[lists subarrayWithRange:CPMakeRange(0, MAX(0, [lists count] - 1))]] forParagraphsInRange:paragraphRange];
}

/* @ignore
    Gives each paragraph in aParagraphsRange the text lists at the same position in
    listsForParagraphs, with a matching paragraph style and marker. The change can be undone.
    The insertion point or selection keeps its place in the text after the markers.
*/
- (void)_setTextLists:(CPArray)listsForParagraphs forParagraphsInRange:(CPRange)aParagraphsRange
{
    [self _setTextLists:listsForParagraphs forParagraphsInRange:aParagraphsRange paragraphStyle:nil];
}

/* @ignore
    As -_setTextLists:forParagraphsInRange:, but every paragraph takes a copy of aParagraphStyle,
    with its text lists, in place of the indents and tab stops that the lists would set. With
    \c nil, each paragraph keeps its own style and takes the indents and tab stops of its lists.
*/
- (void)_setTextLists:(CPArray)listsForParagraphs forParagraphsInRange:(CPRange)aParagraphsRange paragraphStyle:(CPParagraphStyle)aParagraphStyle
{
    if (![self _didBeginEditing] || ![self shouldChangeTextInRange:aParagraphsRange replacementString:nil])
        return;

    var result = [[CPAttributedString alloc] initWithString:@""],
        selectionStart = _selectionRange.location,
        selectionEnd = CPMaxRange(_selectionRange),
        newSelectionStart = selectionStart,
        newSelectionEnd = selectionEnd,
        location = aParagraphsRange.location,
        caretParagraphStyle = nil,
        index = 0;

    do
    {
        var paragraphRange = [_textStorage _paragraphRangeForIndex:location],
            markerRange = [self _textListMarkerRangeInParagraphRange:paragraphRange],
            oldMarkerLength = markerRange.location === CPNotFound ? 0 : markerRange.length,
            paragraph = [[CPAttributedString alloc] initWithAttributedString:[_textStorage attributedSubstringFromRange:paragraphRange]],
            textStart = paragraphRange.location + oldMarkerLength,
            lists = listsForParagraphs[index++],
            attributes = [self _textListAttributesForParagraphRange:paragraphRange textStart:textStart],
            paragraphStyle = aParagraphStyle ? [aParagraphStyle mutableCopy] : [self _paragraphStyle:[attributes objectForKey:CPParagraphStyleAttributeName] withTextLists:lists],
            newMarkerLength = [lists count] ? 2 : 0,
            newParagraphStart = aParagraphsRange.location + [result length];

        if (oldMarkerLength)
            [paragraph deleteCharactersInRange:CPMakeRange(0, oldMarkerLength)];

        if ([paragraph length])
            [paragraph addAttribute:CPParagraphStyleAttributeName value:paragraphStyle range:CPMakeRange(0, [paragraph length])];

        // The marker is filled in when the list is numbered, after the change.
        if (newMarkerLength)
        {
            var markerAttributes = [attributes mutableCopy];

            [markerAttributes setObject:paragraphStyle forKey:CPParagraphStyleAttributeName];
            [paragraph insertAttributedString:[[CPAttributedString alloc] initWithString:@"\t\t" attributes:markerAttributes] atIndex:0];
        }

        // Positions in the text keep their place after the marker; positions in the old marker
        // move to the start of the text.
        if (CPLocationInRange(selectionStart, paragraphRange) || (selectionStart === CPMaxRange(paragraphRange) && selectionStart === CPMaxRange(aParagraphsRange)))
        {
            newSelectionStart = newParagraphStart + newMarkerLength + MAX(0, selectionStart - textStart);
            caretParagraphStyle = paragraphStyle;
        }

        if (CPLocationInRange(selectionEnd, paragraphRange) || (selectionEnd === CPMaxRange(paragraphRange) && selectionEnd === CPMaxRange(aParagraphsRange)))
            newSelectionEnd = newParagraphStart + newMarkerLength + MAX(0, selectionEnd - textStart);

        [result appendAttributedString:paragraph];
        location = CPMaxRange(paragraphRange);
    }
    while (location < CPMaxRange(aParagraphsRange));

    [self _replaceCharactersInRange:CPMakeRangeCopy(aParagraphsRange)
               withAttributedString:result
                     selectionRange:CPMakeRange(newSelectionStart, MAX(0, newSelectionEnd - newSelectionStart))];

    if (caretParagraphStyle)
    {
        [_typingAttributes setObject:caretParagraphStyle forKey:CPParagraphStyleAttributeName];
        [[CPNotificationCenter defaultCenter] postNotificationName:CPTextViewDidChangeTypingAttributesNotification object:self];
    }

    [self updateRuler];
    [self didChangeText];
}

/* @ignore
    Returns YES if any paragraph that the selection touches is a list item.
*/
- (BOOL)_selectionTouchesTextList
{
    var paragraphsRange = [self _textListParagraphsRangeForRange:_selectionRange],
        location = paragraphsRange.location;

    do
    {
        var paragraphRange = [_textStorage _paragraphRangeForIndex:location];

        if ([[_textStorage _textListsOfParagraphAtIndex:paragraphRange.location] count])
            return YES;

        location = CPMaxRange(paragraphRange);
    }
    while (location < CPMaxRange(paragraphsRange));

    return NO;
}

/* @ignore
    Applies a pasted paragraph style that has text lists, or replaces the lists of the selected
    paragraphs, through the list path, so that markers follow. The pasted lists are new objects,
    decoded from the pasteboard. At each level, the list of the paragraph just before or after
    the selection takes the place of a pasted list with the same marker format and options, so
    that the pasted paragraphs join a neighbouring list and continue its numbering.
*/
- (void)_pasteRulerParagraphStyleWithTextLists:(CPParagraphStyle)aParagraphStyle
{
    var paragraphsRange = [self _textListParagraphsRangeForRange:_selectionRange],
        pastedLists = [aParagraphStyle textLists],
        neighbourLists = [],
        lists = [];

    if (paragraphsRange.location > 0)
        neighbourLists = [_textStorage _textListsOfParagraphAtIndex:[_textStorage _paragraphRangeForIndex:paragraphsRange.location - 1].location];

    if (![neighbourLists count] && CPMaxRange(paragraphsRange) < [_textStorage length])
        neighbourLists = [_textStorage _textListsOfParagraphAtIndex:CPMaxRange(paragraphsRange)];

    for (var level = 0; level < [pastedLists count]; level++)
    {
        var pastedList = pastedLists[level],
            neighbourList = level < [neighbourLists count] ? neighbourLists[level] : nil,
            enclosingMatches = level === 0 || lists[level - 1] === neighbourLists[level - 1];

        if (enclosingMatches && neighbourList && [neighbourList markerFormat] === [pastedList markerFormat] && [neighbourList listOptions] === [pastedList listOptions])
            lists.push(neighbourList);
        else
            lists.push(pastedList);
    }

    var paragraphStyle = [aParagraphStyle mutableCopy],
        listsForParagraphs = [],
        location = paragraphsRange.location;

    [paragraphStyle setTextLists:lists];

    do
    {
        var paragraphRange = [_textStorage _paragraphRangeForIndex:location];

        listsForParagraphs.push(lists);
        location = CPMaxRange(paragraphRange);
    }
    while (location < CPMaxRange(paragraphsRange));

    [self _setTextLists:listsForParagraphs forParagraphsInRange:paragraphsRange paragraphStyle:paragraphStyle];
}

// MARK: Editing in Lists

/* @ignore
    Return in a list item starts the next item, with the same paragraph style. Return in an
    empty item ends the list there, or returns a nested item to the enclosing list. Returns
    \c NO if the insertion point is not in the text of a list item.
*/
- (BOOL)_insertNewlineInTextList
{
    var paragraphRange = [self _textListItemRangeAtIndex:_selectionRange.location],
        markerRange = paragraphRange ? [self _textListMarkerRangeInParagraphRange:paragraphRange] : nil;

    if (!markerRange || markerRange.location === CPNotFound || _selectionRange.location < CPMaxRange(markerRange))
        return NO;

    var string = [_textStorage string],
        textEnd = CPMaxRange(paragraphRange);

    if (textEnd > paragraphRange.location && string.charCodeAt(textEnd - 1) === 10)
        textEnd--;

    if (!_selectionRange.length && CPMaxRange(markerRange) === textEnd)
    {
        [self _outdentTextListItemAtIndex:_selectionRange.location];
        return YES;
    }

    var attributes = [_typingAttributes mutableCopy];

    [attributes setObject:[_textStorage attribute:CPParagraphStyleAttributeName atIndex:paragraphRange.location effectiveRange:nil] forKey:CPParagraphStyleAttributeName];

    // The new item's marker is filled in when the list is numbered, after the insertion.
    [self insertText:[[CPAttributedString alloc] initWithString:@"\n\t\t" attributes:attributes]];

    return YES;
}

/* @ignore
    Tab at the start of a list item makes it an item of a nested list. Returns \c NO if the
    insertion point is not at the start of a list item.
*/
- (BOOL)_insertTabInTextList
{
    var paragraphRange = [self _textListItemRangeAtIndex:_selectionRange.location],
        markerRange = paragraphRange ? [self _textListMarkerRangeInParagraphRange:paragraphRange] : nil;

    if (_selectionRange.length || !markerRange || markerRange.location === CPNotFound || _selectionRange.location > CPMaxRange(markerRange))
        return NO;

    [self _indentTextListItemAtIndex:_selectionRange.location];
    return YES;
}

/* @ignore
    Shift-Tab in an item of a nested list returns it to the enclosing list. In an item of a list
    that is not nested, it does nothing. Returns \c NO if the insertion point is not in a list item.
*/
- (BOOL)_insertBacktabInTextList
{
    var paragraphRange = [self _textListItemRangeAtIndex:_selectionRange.location];

    if (!paragraphRange)
        return NO;

    if ([[_textStorage _textListsOfParagraphAtIndex:paragraphRange.location] count] > 1)
        [self _outdentTextListItemAtIndex:_selectionRange.location];

    return YES;
}

/* @ignore
    Delete at the start of a list item's text returns a nested item to the enclosing list, or
    removes the item from its list, with its marker. Returns \c NO if the insertion point is
    not at the start of a list item's text.
*/
- (BOOL)_deleteBackwardInTextList
{
    var paragraphRange = [self _textListItemRangeAtIndex:_selectionRange.location],
        markerRange = paragraphRange ? [self _textListMarkerRangeInParagraphRange:paragraphRange] : nil;

    if (_selectionRange.length || !markerRange || markerRange.location === CPNotFound || _selectionRange.location !== CPMaxRange(markerRange))
        return NO;

    [self _outdentTextListItemAtIndex:_selectionRange.location];
    return YES;
}

// MARK: Numbering

/* @ignore
    Numbers again the markers of the lists in and next to aRange, which a change has just
    affected. Only marker text changes, without undo: undoing the change restores the text, and
    the lists are numbered again afterwards. The selection keeps its place in the text.
*/
- (void)_updateTextListMarkersAroundRange:(CPRange)aRange
{
    var length = [_textStorage length];

    if (!length || ![self isRichText])
        return;

    // The paragraphs from the one before the change to the one after it.
    var scanStart = [_textStorage _paragraphRangeForIndex:MAX(0, aRange.location - 1)].location,
        scanEnd = CPMaxRange([_textStorage _paragraphRangeForIndex:MIN(length, CPMaxRange(aRange))]),
        listRanges = [],
        location = scanStart;

    if (scanEnd < length)
        scanEnd = CPMaxRange([_textStorage _paragraphRangeForIndex:scanEnd]);

    while (location < scanEnd)
    {
        var paragraphRange = [_textStorage _paragraphRangeForIndex:location],
            lists = [_textStorage _textListsOfParagraphAtIndex:location];

        if ([lists count])
        {
            var listRange = [_textStorage rangeOfTextList:lists[0] atIndex:location];

            listRanges.push(listRange);
            location = MAX(CPMaxRange(listRange), CPMaxRange(paragraphRange));
        }
        else
            location = CPMaxRange(paragraphRange);

        if (!paragraphRange.length)
            break;
    }

    if (!listRanges.length)
        return;

    var replacements = [];

    for (var i = 0; i < listRanges.length; i++)
        [self _collectTextListMarkerReplacements:replacements inRange:listRanges[i]];

    if (!replacements.length)
        return;

    var selectionStart = _selectionRange.location,
        selectionEnd = CPMaxRange(_selectionRange);

    // Replace from the end, so that the earlier ranges stay valid.
    [_textStorage beginEditing];

    for (var i = replacements.length - 1; i >= 0; i--)
    {
        var replacement = replacements[i],
            range = replacement.range,
            delta = replacement.string.length - range.length;

        [_textStorage replaceCharactersInRange:range
                          withAttributedString:[[CPAttributedString alloc] initWithString:replacement.string attributes:[_textStorage attributesAtIndex:range.location effectiveRange:nil]]];

        if (selectionStart >= CPMaxRange(range))
            selectionStart += delta;
        else if (selectionStart > range.location)
            selectionStart = range.location + replacement.string.length;

        if (selectionEnd >= CPMaxRange(range))
            selectionEnd += delta;
        else if (selectionEnd > range.location)
            selectionEnd = range.location + replacement.string.length;
    }

    [_textStorage endEditing];

    [self _setSelectedRange:CPMakeRange(selectionStart, selectionEnd - selectionStart) affinity:0 stillSelecting:NO overwriteTypingAttributes:NO];
    [_layoutManager _validateLayoutAndGlyphs];
    [self sizeToFit];
    [self setNeedsDisplay:YES];
}

/* @ignore
    Adds to someReplacements the marker of each item in aListRange whose text differs from its
    number. The items are counted in one pass, with a counter for each list. As in Cocoa, a list
    with the CPTextListPrependEnclosingMarker option puts the enclosing item's marker before its
    own.
*/
- (void)_collectTextListMarkerReplacements:(CPArray)someReplacements inRange:(CPRange)aListRange
{
    var string = [_textStorage string],
        counters = {},
        location = aListRange.location;

    while (location < CPMaxRange(aListRange))
    {
        var paragraphRange = [_textStorage _paragraphRangeForIndex:location],
            lists = [_textStorage _textListsOfParagraphAtIndex:location],
            count = [lists count],
            innermostUID = [lists[count - 1] UID],
            marker = @"";

        counters[innermostUID] = (counters.hasOwnProperty(innermostUID) ? counters[innermostUID] : [lists[count - 1] startingItemNumber] - 1) + 1;

        for (var level = 0; level < count; level++)
        {
            var list = lists[level],
                uid = [list UID],
                itemNumber = counters.hasOwnProperty(uid) ? counters[uid] : [list startingItemNumber],
                levelMarker = [list markerForItemNumber:itemNumber];

            marker = ([list listOptions] & CPTextListPrependEnclosingMarker) ? marker + levelMarker : levelMarker;
        }

        var markerRange = [self _textListMarkerRangeInParagraphRange:paragraphRange],
            newMarker = "\t" + marker + "\t";

        if (markerRange.location !== CPNotFound && string.substr(markerRange.location, markerRange.length) !== newMarker)
            someReplacements.push({range: markerRange, string: newMarker});

        if (!paragraphRange.length)
            break;

        location = CPMaxRange(paragraphRange);
    }
}

// MARK: Helpers

/* @ignore
    Returns the range of the list item paragraph at anIndex, or \c nil if the paragraph is not
    a list item or the text is not rich.
*/
- (CPRange)_textListItemRangeAtIndex:(unsigned)anIndex
{
    if (![self isRichText])
        return nil;

    var paragraphRange = [_textStorage _paragraphRangeForIndex:anIndex];

    // At the end of the text after a paragraph separator, the insertion point is in an empty
    // paragraph that has no attributes of its own.
    if (![[_textStorage _textListsOfParagraphAtIndex:paragraphRange.location] count])
        return nil;

    return paragraphRange;
}

/* @ignore
    Returns the range of the marker at the start of a list item: a tab, the marker and another
    tab. Returns a range with the location CPNotFound if the paragraph is not a list item, or
    its text does not start with a marker.
*/
- (CPRange)_textListMarkerRangeInParagraphRange:(CPRange)aParagraphRange
{
    var string = [_textStorage string],
        start = aParagraphRange.location,
        end = CPMaxRange(aParagraphRange);

    if (![[_textStorage _textListsOfParagraphAtIndex:start] count] || string.charCodeAt(start) !== 9)
        return CPMakeRange(CPNotFound, 0);

    for (var i = start + 1; i < end; i++)
    {
        var charCode = string.charCodeAt(i);

        if (charCode === 9)
            return CPMakeRange(start, i - start + 1);

        if (charCode === 10 || charCode === 13 || charCode === 0x2029)
            break;
    }

    return CPMakeRange(CPNotFound, 0);
}

/* @ignore
    Returns the range of whole paragraphs that aRange touches. A selection that ends at the
    start of a paragraph does not include that paragraph.
*/
- (CPRange)_textListParagraphsRangeForRange:(CPRange)aRange
{
    var first = [_textStorage _paragraphRangeForIndex:aRange.location],
        lastIndex = aRange.length ? CPMaxRange(aRange) - 1 : aRange.location,
        last = [_textStorage _paragraphRangeForIndex:MAX(first.location, lastIndex)];

    return CPMakeRange(first.location, CPMaxRange(last) - first.location);
}

/* @ignore
    Returns the attributes for a list item's marker and paragraph style: those of the first
    character of its text, or of the paragraph, or the typing attributes for an empty paragraph.
*/
- (CPDictionary)_textListAttributesForParagraphRange:(CPRange)aParagraphRange textStart:(unsigned)aTextStart
{
    var length = [_textStorage length];

    if (aTextStart < CPMaxRange(aParagraphRange) && aTextStart < length && [_textStorage string].charCodeAt(aTextStart) !== 10)
        return [_textStorage attributesAtIndex:aTextStart effectiveRange:nil];

    if (aParagraphRange.location < length)
        return [_textStorage attributesAtIndex:aParagraphRange.location effectiveRange:nil];

    return [_typingAttributes mutableCopy];
}

/* @ignore
    Returns a copy of aParagraphStyle for the text lists someLists. The indents and tab stops of
    a list item place its marker CPTextViewTextListMarkerIndent points into its level, and its
    text, including later lines, at the start of the next level. A paragraph without lists gets
    no indents and the default tab stops.
*/
- (CPParagraphStyle)_paragraphStyle:(CPParagraphStyle)aParagraphStyle withTextLists:(CPArray)someLists
{
    var paragraphStyle = [(aParagraphStyle || [CPParagraphStyle defaultParagraphStyle]) mutableCopy],
        level = [someLists count];

    [paragraphStyle setTextLists:someLists];

    if (level)
    {
        var levelStart = (level - 1) * CPTextViewTextListLevelIndent,
            textStart = level * CPTextViewTextListLevelIndent;

        [paragraphStyle setFirstLineHeadIndent:levelStart];
        [paragraphStyle setHeadIndent:textStart];
        [paragraphStyle setTabStops:[[[CPTextTab alloc] initWithType:CPLeftTabStopType location:levelStart + CPTextViewTextListMarkerIndent],
                                     [[CPTextTab alloc] initWithType:CPLeftTabStopType location:textStart]]];
    }
    else
    {
        [paragraphStyle setFirstLineHeadIndent:0.0];
        [paragraphStyle setHeadIndent:0.0];
        [paragraphStyle setTabStops:[[CPParagraphStyle defaultParagraphStyle] tabStops]];
    }

    return paragraphStyle;
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
    CPTextViewUsesRulerKey = @"CPTextViewUsesRulerKey",
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

        // Archives made before usesRuler was archived keep the default from _init.
        if ([aCoder containsValueForKey:CPTextViewUsesRulerKey])
            _usesRuler = [aCoder decodeBoolForKey:CPTextViewUsesRulerKey];

        [self setDelegate:[aCoder decodeObjectForKey:CPTextViewDelegateKey]];

        var container = [aCoder decodeObjectForKey:CPTextViewContainerKey];
        [container setTextView:self];

        _typingAttributes = [[_textStorage attributesAtIndex:0 effectiveRange:nil] copy];

        if (!_typingAttributes)
            _typingAttributes = [CPMutableDictionary dictionary];

        if (![_typingAttributes valueForKey:CPForegroundColorAttributeName])
            [_typingAttributes setObject:[CPColor blackColor] forKey:CPForegroundColorAttributeName];

        _textColor = [_typingAttributes valueForKey:CPForegroundColorAttributeName];

        var decodedFont = [_typingAttributes valueForKey:CPFontAttributeName] || [CPFont systemFontOfSize:12.0];
        [self setFont:decodedFont];

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
    [aCoder encodeBool:_usesRuler forKey:CPTextViewUsesRulerKey];
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
    if (!CPDOMAvailable)
        return;

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

    if (CPDOMAvailable)
    {
        _caretDOM.style.left = (aRect.origin.x) + "px";
        _caretDOM.style.top = (aRect.origin.y) + "px";
        _caretDOM.style.height = (aRect.size.height) + "px";
    }
}

- (id)initWithTextView:(CPTextView)aView
{
    if (self = [super init])
    {
        if (CPDOMAvailable)
        {
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
        }
    }

    return self;
}

- (void)setVisibility:(BOOL)visibilityFlag stop:(BOOL)stopFlag
{
    if (CPDOMAvailable)
    {
        _caretDOM.style.visibility = visibilityFlag ? "visible" : "hidden";
    }

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
    if (CPDOMAvailable)
        return event._DOMEvent && (event._DOMEvent.key === 'Dead' || event._DOMEvent.key === 'Process');

    return NO;
}

+ (void)cancelCurrentInputSessionIfNeeded
{
    if (!CPDOMAvailable)
        return;

    if (_CPNativeInputField) {
        _CPNativeInputField.innerHTML = '';
    }
    _isComposing = NO;
}

+ (void)initialize
{
    if (!CPDOMAvailable)
        return;

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

        if (e.key === 'Tab' || e.key === 'Enter' || (e.key === 'Backspace' && _CPNativeInputField.innerHTML === ''))
        {
            // Prevent browser default action:
            // - 'Tab': Prevents browser focus navigation, allowing Cappuccino key bindings (like option-tab or tab) to work.
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

        // Prefer e.data to capture the exact inserted character(s) from key entry.
        // This avoids harvesting structural markup or stale carriage returns
        // introduced by the browser's selection layout.
        var textToInsert = (e.data !== undefined && e.data !== null) ? e.data : e.target.textContent;

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
        if ([currentFirstResponder respondsToSelector:@selector(isRichText)] && [currentFirstResponder isRichText])
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
                var shouldPastePlainText = [[CPApp currentEvent] modifierFlags] & (CPShiftKeyMask | CPAlternateKeyMask);

                if (shouldPastePlainText && richtext._string)
                    richtext = richtext._string;

                [currentFirstResponder _pasteString:richtext];

                return;
            }
            // If no richtext is available, fall back to plain text
        }

        var nativeString = nativeClipboard.getData('text/plain');

        // Use setTimeout to prevent flickering
        setTimeout(function()
        {
            [currentFirstResponder _pasteString:nativeString || [pasteboard stringForType:CPStringPboardType] || ''];
        }, 20);
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
        // Use setTimeout to prevent flickering
        setTimeout(function()
        {
            [currentFirstResponder deleteBackward:self];
        }, 20);
    };
}

+ (void)focusForTextView:(CPTextView)currentFirstResponder
{
    if (!CPDOMAvailable)
        return;

    if (_CPNativeInputField && document.activeElement !== _CPNativeInputField)
        _CPNativeInputField.focus();
}

+ (void)focusForClipboardOfTextView:(CPTextView)textview
{
    if (!CPDOMAvailable)
        return;

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
