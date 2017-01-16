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
@class _CPSelectionBox;
@class _CPCaret;
@class _CPNativeInputManager;

@protocol CPTextViewDelegate <CPTextDelegate>

- (BOOL)textView:(CPTextView)aTextView doCommandBySelector:(SEL)aSelector;
- (BOOL)textView:(CPTextView)aTextView shouldChangeTextInRange:(CPRange)affectedCharRange replacementString:(CPString)replacementString;
- (CPDictionary)textView:(CPTextView)textView shouldChangeTypingAttributes:(CPDictionary)oldTypingAttributes toAttributes:(CPDictionary)newTypingAttributes;
- (CPRange)textView:(CPTextView)aTextView willChangeSelectionFromCharacterRange:(CPRange)oldSelectedCharRange toCharacterRange:(CPRange)newSelectedCharRange;
- (void)textViewDidChangeSelection:(CPNotification)aNotification;
- (void)textViewDidChangeTypingAttributes:(CPNotification)aNotification;

@end

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
    kDelegateRespondsTo_textView_doCommandBySelector                                    = 1 << 1,
    kDelegateRespondsTo_textView_willChangeSelectionFromCharacterRange_toCharacterRange = 1 << 2,
    kDelegateRespondsTo_textView_shouldChangeTextInRange_replacementString              = 1 << 3,
    kDelegateRespondsTo_textView_shouldChangeTypingAttributes_toAttributes              = 1 << 4,
    kDelegateRespondsTo_textView_textDidChange                                          = 1 << 5,
    kDelegateRespondsTo_textView_didChangeSelection                                     = 1 << 6,
    kDelegateRespondsTo_textView_didChangeTypingAttributes                              = 1 << 7;

@class _CPCaret;

/*!
    @ingroup appkit
    @class CPTextView
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
    CPSelectionGranularity      _copySelectionGranularity;      // private

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
}

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding === CPValueBinding || aBinding === CPAttributedStringBinding)
        return [_CPTextViewValueBinder class];

    return [super _binderClassForBinding:aBinding];
}

#pragma mark -
#pragma mark Class methods

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
#if PLATFORM(DOM)
        _DOMElement.style.cursor = "text";
#endif

    _selectionRange = CPMakeRange(0, 0);
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
    [_caret setRect:CGRectMake(0, 0, 1, 11)]

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
}

- (void)_addObservers
{
    if (_isObserving)
        return;

    [super _addObservers];
    [self _setObserveWindowKeyNotifications:YES];
    [self _startObservingClipView];
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
        [self resignFirstResponder];
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
    _copySelectionGranularity = _previousSelectionGranularity;
    [super copy:sender];

    if (![self isRichText])
        return;

    var selectedRange = [self selectedRange],
        pasteboard = [CPPasteboard generalPasteboard],
        stringForPasting = [[self textStorage] attributedSubstringFromRange:CPMakeRangeCopy(selectedRange)],
        richData = [_CPRTFProducer produceRTF:stringForPasting documentAttributes:@{}];

        [pasteboard declareTypes:[CPStringPboardType, CPRTFPboardType] owner:nil];
        [pasteboard setString:stringForPasting._string forType:CPStringPboardType];
        [pasteboard setString:richData forType:CPRTFPboardType];
}

- (void)_pasteString:(id)stringForPasting
{
    if (!stringForPasting)
        return;

    if (_copySelectionGranularity > 0 && _selectionRange.location > 0)
    {
        if (!_isWhitespaceCharacter([[_textStorage string] characterAtIndex:_selectionRange.location - 1]) &&
            _selectionRange.location != [_layoutManager numberOfCharacters])
        {
            [self insertText:" "];
        }
    }

    if (_copySelectionGranularity == CPSelectByParagraph)
    {
        var peekStr = stringForPasting,
            i = 0;

        if (![stringForPasting isKindOfClass:[CPString class]])
            peekStr = stringForPasting._string;

        while (_isWhitespaceCharacter([peekStr characterAtIndex:i]))
            i++;

        if (i)
        {
            if ([stringForPasting isKindOfClass:[CPString class]])
                stringForPasting = [stringForPasting stringByReplacingCharactersInRange:CPMakeRange(0, i) withString:''];
            else
                [stringForPasting replaceCharactersInRange:CPMakeRange(0, i) withString:''];
        }
    }

    [self insertText:stringForPasting];

    if (_copySelectionGranularity > 0)
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
    if (![sender isKindOfClass:_CPNativeInputManager] && [[CPApp currentEvent] type] != CPAppKitDefined)
        return

    [self _pasteString:[self _stringForPasting]];
}

#pragma mark -
#pragma mark Responders method

- (BOOL)acceptsFirstResponder
{
    return [self isSelectable]; // editable textviews are automatically selectable
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
    [self _becomeFirstResponder];

    return YES;
}

- (BOOL)resignFirstResponder
{
    [self _reverseSetBinding];
    [_caret stopBlinking];
    [self setNeedsDisplay:YES];
    [_CPNativeInputManager cancelCurrentInputSessionIfNeeded];

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

        if ([_delegate respondsToSelector:@selector(textView:doCommandBySelector:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textView_doCommandBySelector;

        if ([_delegate respondsToSelector:@selector(textShouldBeginEditing:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textShouldBeginEditing;

        if ([_delegate respondsToSelector:@selector(textView:willChangeSelectionFromCharacterRange:toCharacterRange:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textView_willChangeSelectionFromCharacterRange_toCharacterRange;

        if ([_delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementString:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textView_shouldChangeTextInRange_replacementString;

        if ([_delegate respondsToSelector:@selector(textView:shouldChangeTypingAttributes:toAttributes:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textView_shouldChangeTypingAttributes_toAttributes;
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

- (void)setString:(id)aString
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

    if (_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_textDidChange)
        [_delegate textDidChange:[[CPNotification alloc] initWithName:CPTextDidChangeNotification object:self userInfo:nil]];
}

- (BOOL)shouldChangeTextInRange:(CPRange)aRange replacementString:(CPString)aString
{
    if (![self isEditable])
        return NO;

    return [self _sendDelegateTextShouldBeginEditing] && [self _sendDelegateShouldChangeTextInRange:aRange replacementString:aString];
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

    if (![self shouldChangeTextInRange:CPMakeRangeCopy(_selectionRange) replacementString:string])
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

- (void)setSelectedRange:(CPRange)range
{
    [_CPNativeInputManager cancelCurrentInputSessionIfNeeded];
    [self setSelectedRange:range affinity:0 stillSelecting:NO];
}

- (void)setSelectedRange:(CPRange)range affinity:(CPSelectionAffinity)affinity stillSelecting:(BOOL)selecting
{
    [self _setSelectedRange:range affinity:affinity stillSelecting:selecting overwriteTypingAttributes:YES];
}

- (void)_setSelectedRange:(CPRange)range affinity:(CPSelectionAffinity)affinity stillSelecting:(BOOL)selecting overwriteTypingAttributes:(BOOL)doOverwrite
{
    var maxRange = CPMakeRange(0, [_layoutManager numberOfCharacters]);

    range = CPIntersectionRange(maxRange, range);

    if (!selecting && [self _delegateRespondsToWillChangeSelectionFromCharacterRangeToCharacterRange])
    {
        _selectionRange = [self _sendDelegateWillChangeSelectionFromCharacterRange:_selectionRange toCharacterRange:range];
    }
    else
    {
        _selectionRange = CPMakeRangeCopy(range);
        _selectionRange = [self selectionRangeForProposedRange:_selectionRange granularity:[self selectionGranularity]];
    }

    if (_selectionRange.length)
        [_layoutManager invalidateDisplayForGlyphRange:_selectionRange];
    else
        [self setNeedsDisplay:YES];

    if (!selecting)
    {
        if ([self _isFirstResponder])
            [self updateInsertionPointStateAndRestartTimer:((_selectionRange.length === 0) && ![_caret isBlinking])];

        if (doOverwrite && _placeholderString === nil)
            [self setTypingAttributes:[_textStorage attributesAtIndex:CPMaxRange(range) effectiveRange:nil]];

        [[CPNotificationCenter defaultCenter] postNotificationName:CPTextViewDidChangeSelectionNotification object:self];

        if (_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_didChangeSelection)
            [_delegate textViewDidChangeSelection:[[CPNotification alloc] initWithName:CPTextViewDidChangeSelectionNotification object:self userInfo:nil]];
    }

    if (!selecting && _selectionRange.length > 0)
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


// interface to the _CPNativeInputManager
- (void)_activateNativeInputElement:(DOMElemet)aNativeField
{
    var attributes = [[self typingAttributes] copy];

    // make it invisible
    [attributes setObject:[CPColor colorWithRed:1 green:1 blue:1 alpha:0] forKey:CPForegroundColorAttributeName];

    // FIXME: this hack to provide the visual space for the inputmanager should at least bypass the undomanager
    var placeholderString = [[CPAttributedString alloc] initWithString:aNativeField.innerHTML attributes:attributes];
    [self insertText:placeholderString];

    var caretOrigin = [_layoutManager boundingRectForGlyphRange:CPMakeRange(MAX(0, _selectionRange.location - 1), 1) inTextContainer:_textContainer].origin;
    caretOrigin.y += [_layoutManager _characterOffsetAtLocation:MAX(0, _selectionRange.location - 1)];
    caretOrigin.x += 2; // two pixel offset to the LHS character
    var cumulativeOffset = [self _cumulativeOffset];


#if PLATFORM(DOM)
    aNativeField.style.left = (caretOrigin.x + cumulativeOffset.x) + "px";
    aNativeField.style.top = (caretOrigin.y + cumulativeOffset.y) + "px";
    aNativeField.style.font = [[_typingAttributes objectForKey:CPFontAttributeName] cssString];
    aNativeField.style.color = [[_typingAttributes objectForKey:CPForegroundColorAttributeName] cssString];
#endif

    [_caret setVisibility:NO];  // hide our caret because now the system caret takes over
}

- (CPArray)selectedRanges
{
    return [_selectionRange];
}

#pragma mark -
#pragma mark Keyboard events

- (void)keyDown:(CPEvent)event
{

    [[_window platformWindow] _propagateCurrentDOMEvent:YES];  // for the _CPNativeInputManager (necessary at least on FF and chrome)

    if (![_CPNativeInputManager isNativeInputFieldActive] && [event charactersIgnoringModifiers].charCodeAt(0) != 229) // filter out 229 because this would be inserted in chrome on each deadkey
        [self interpretKeyEvents:[event]];

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

#pragma mark -
#pragma mark Mouse Events

- (void)mouseDown:(CPEvent)event
{
    if (![self isSelectable])
        return;

    [_CPNativeInputManager cancelCurrentInputSessionIfNeeded];
    [_caret setVisibility:NO];
    
    _startTrackingLocation = [self _characterIndexFromEvent:event];
    
    var granularities = [CPNotFound, CPSelectByCharacter, CPSelectByWord, CPSelectByParagraph];
    [self setSelectionGranularity:granularities[[event clickCount]]];

    // dragging the selection
    if ([self selectionGranularity] == CPSelectByCharacter && CPLocationInRange(_startTrackingLocation, _selectionRange))
    {
        var lineBeginningIndex = [_layoutManager _firstLineFragmentForLineFromLocation:_selectionRange.location]._range.location,
            placeholderRange = _MakeRangeFromAbs(lineBeginningIndex, CPMaxRange(_selectionRange)),
            placeholderString = [_textStorage attributedSubstringFromRange:placeholderRange],
            placeholderFrame = CGRectIntersection([_layoutManager boundingRectForGlyphRange:placeholderRange inTextContainer:_textContainer], _frame),
            rangeToHide = CPMakeRange(0, _selectionRange.location - lineBeginningIndex),
            dragPlaceholder;
        
        // hide the left part of the first line of the selection that is not included
        [placeholderString addAttribute:CPForegroundColorAttributeName
                                  value:[CPColor colorWithRed:1 green:1 blue:1 alpha:0]
                                  range:rangeToHide];
        
        _movingSelection = CPMakeRange(_startTrackingLocation, 0);
        
        dragPlaceholder = [[CPTextView alloc] initWithFrame:placeholderFrame];
        [dragPlaceholder._textStorage replaceCharactersInRange:CPMakeRange(0, 0) withAttributedString:placeholderString];

        [dragPlaceholder setBackgroundColor:[CPColor colorWithRed:1 green:1 blue:1 alpha:0]];
        [dragPlaceholder setAlphaValue:0.5];
        
        var stringForPasting = [_textStorage attributedSubstringFromRange:CPMakeRangeCopy(_selectionRange)],
            richData = [_CPRTFProducer produceRTF:stringForPasting documentAttributes:@{}],
            draggingPasteboard = [CPPasteboard pasteboardWithName:CPDragPboard];
        [draggingPasteboard declareTypes:[CPRTFPboardType, CPStringPboardType] owner:nil];
        [draggingPasteboard setString:richData forType:CPRTFPboardType];
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

    [self setSelectedRange:setRange affinity:0 stillSelecting:YES];
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

- (unsigned)_calculateMoveSelectionFromRange:(CPRange)aRange intoDirection:(integer)move granularity:(CPSelectionGranularity)granularity
{
    var inWord = [self _isCharacterAtIndex:(move > 0 ? CPMaxRange(aRange) : aRange.location) + move granularity:granularity],
        aSel = [self selectionRangeForProposedRange:CPMakeRange((move > 0 ? CPMaxRange(aRange) : aRange.location) + move, 0) granularity:granularity],
        bSel = [self selectionRangeForProposedRange:CPMakeRange((move > 0 ? CPMaxRange(aSel) : aSel.location) + move, 0) granularity:granularity];

    return move > 0 ? CPMaxRange(inWord? aSel:bSel) : (inWord? aSel:bSel).location;
}

- (void)_moveSelectionIntoDirection:(integer)move granularity:(CPSelectionGranularity)granularity
{
    var pos = [self _calculateMoveSelectionFromRange:_selectionRange intoDirection:move granularity:granularity];

    [self _performSelectionFixupForRange:CPMakeRange(pos, 0)];
    _startTrackingLocation = _selectionRange.location;
}

- (void)_extendSelectionIntoDirection:(integer)move granularity:(CPSelectionGranularity)granularity
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
        [self _moveSelectionIntoDirection:-1 granularity:CPSelectByWord]
}

- (void)moveRight:(id)sender
{
    if ([self isSelectable])
        [self _establishSelection:CPMakeRange(CPMaxRange(_selectionRange) + (_selectionRange.length ? 0 : 1), 0) byExtending:NO];
}

- (void)_deleteForRange:(CPRange)changedRange
{
    if (![self shouldChangeTextInRange:changedRange replacementString:@""])
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
    _stickyXLocation = _caret._rect.origin.x;
}

- (void)cancelOperation:(id)sender
{
    [_CPNativeInputManager cancelCurrentInputSessionIfNeeded];  // handle ESC during native input
}

- (void)deleteBackward:(id)sender ignoreSmart:(BOOL)ignoreFlag
{
    var changedRange;

    if (CPEmptyRange(_selectionRange) && _selectionRange.location > 0)
        changedRange = CPMakeRange(_selectionRange.location - 1, 1);
    else
        changedRange = _selectionRange;

    // smart delete
    if (!ignoreFlag && _copySelectionGranularity > 0 &&
        changedRange.location > 0 && _isWhitespaceCharacter([[_textStorage string] characterAtIndex:_selectionRange.location - 1]) &&
        changedRange.location < [[self string] length] && _isWhitespaceCharacter([[_textStorage string] characterAtIndex:CPMaxRange(changedRange)]))
        changedRange.length++;

    [self _deleteForRange:changedRange];
    _startTrackingLocation = _selectionRange.location;
}

- (void)deleteBackward:(id)sender
{
    _copySelectionGranularity = _previousSelectionGranularity; // smart delete
    [self deleteBackward:self ignoreSmart:_selectionRange.length > 0? NO:YES];
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
    var selectedRange = [self selectedRange];

    if (selectedRange.length < 1)
        return;

    [self copy:sender];
    [self deleteBackward:sender ignoreSmart:NO];
}

- (void)insertLineBreak:(id)sender
{
    [self insertText:@"\n"];
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

    [[CPNotificationCenter defaultCenter] postNotificationName:CPTextViewDidChangeTypingAttributesNotification
                                                        object:self];

    if (_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_didChangeTypingAttributes)
        [_delegate textViewDidChangeTypingAttributes:[[CPNotification alloc] initWithName:CPTextViewDidChangeTypingAttributesNotification object:self userInfo:nil]];
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
            [_typingAttributes setObject:[sender selectedFont] forKey:CPFontAttributeName];
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

- (void)underline:(id)sender
{
    if (![self shouldChangeTextInRange:_selectionRange replacementString:nil])
        return;

    if (!CPEmptyRange(_selectionRange))
    {
        var attrib = [_textStorage attributesAtIndex:_selectionRange.location effectiveRange:nil];

        if ([attrib containsKey:CPUnderlineStyleAttributeName] && [[attrib objectForKey:CPUnderlineStyleAttributeName] intValue])
            [_textStorage removeAttribute:CPUnderlineStyleAttributeName range:_selectionRange];
        else
            [_textStorage addAttribute:CPUnderlineStyleAttributeName value:[CPNumber numberWithInt:1] range:CPMakeRangeCopy(_selectionRange)];
    }
    else
    {
        if ([_typingAttributes containsKey:CPUnderlineStyleAttributeName] && [[_typingAttributes  objectForKey:CPUnderlineStyleAttributeName] intValue])
            [_typingAttributes setObject:[CPNumber numberWithInt:0] forKey:CPUnderlineStyleAttributeName];
        else
            [_typingAttributes setObject:[CPNumber numberWithInt:1] forKey:CPUnderlineStyleAttributeName];
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
    var minSize = [self minSize],
        maxSize = [self maxSize],
        desiredSize = CGSizeCreateCopy(aSize),
        rect = CGRectUnion([_layoutManager boundingRectForGlyphRange:CPMakeRange(0, 1) inTextContainer:_textContainer],
                           [_layoutManager boundingRectForGlyphRange:CPMakeRange(MAX(0, [_layoutManager numberOfCharacters] - 2), 1) inTextContainer:_textContainer]),
        myClipviewSize = nil;

    if ([[self superview] isKindOfClass:[CPClipView class]])
        myClipviewSize = [[self superview] frame].size;

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

    if (myClipviewSize)
    {
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
    return (_selectionRange.length === 0 && [self _isFocused]);
}

- (void)updateInsertionPointStateAndRestartTimer:(BOOL)flag
{
    var caretRect,
        numberOfGlyphs = [_layoutManager numberOfCharacters];

    if (_selectionRange.length)
        [_caret setVisibility:NO];

    if (_selectionRange.location >= numberOfGlyphs)    // cursor is "behind" the last chacacter
    {
        caretRect = [_layoutManager boundingRectForGlyphRange:CPMakeRange(MAX(0,_selectionRange.location - 1), 1) inTextContainer:_textContainer];

        if (!numberOfGlyphs)
        {
            var font = [_typingAttributes objectForKey:CPFontAttributeName] || [self font];

            caretRect.size.height = [font size];
            caretRect.origin.y = ([font ascender] - [font descender]) * 0.5 + _textContainerOrigin.y;
        }

        caretRect.origin.x += caretRect.size.width;

        if (_selectionRange.location > 0 && [[_textStorage string] characterAtIndex:_selectionRange.location - 1] === '\n')
        {
            caretRect.origin.y += caretRect.size.height;
            caretRect.origin.x = 0;
        }
    }
    else
        caretRect = [_layoutManager boundingRectForGlyphRange:CPMakeRange(_selectionRange.location, 1) inTextContainer:_textContainer];

    var loc = (_selectionRange.location === numberOfGlyphs && numberOfGlyphs > 0) ? _selectionRange.location - 1 : _selectionRange.location,
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

    caretRect.origin.x += _textContainerOrigin.x;
    caretRect.origin.y += _textContainerOrigin.y;
    caretRect.size.width = 1;

    [_caret setRect:caretRect];

    if (flag)
        [_caret startBlinking];
}

- (void)draggingUpdated:(CPDraggingInfo)info
{
    var point = [info draggingLocation],
        location = [self _characterIndexFromRawPoint:CGPointCreateCopy(point)];
        
    _movingSelection = CPMakeRange(location, 0);
    [_caret _drawCaretAtLocation:_movingSelection.location];
    [_caret setVisibility:YES];
}

#pragma mark -
#pragma mark Dragging operation

- (void)performDragOperation:(CPDraggingInfo)aSender
{
    var location = [self convertPoint:[aSender draggingLocation] fromView:nil],
        pasteboard = [aSender draggingPasteboard];
        
    if ([pasteboard availableTypeFromArray:[CPRTFPboardType, CPStringPboardType]])
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

        var dataForPasting = [pasteboard stringForType:CPRTFPboardType] || [pasteboard stringForType:CPStringPboardType];

        //  setTimeout is to a work around a transaction issue with the undomanager
        setTimeout(function(){

            if ([dataForPasting hasPrefix:"{\\rtf"])
                [self insertText:[[_CPRTFParser new] parseRTF:dataForPasting]];
            else
                [self insertText:dataForPasting];
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

- (BOOL)_sendDelegateShouldChangeTextInRange:(CPRange)aRange replacementString:(CPString)aString
{
    if (!(_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_shouldChangeTextInRange_replacementString))
        return YES;

    return [_delegate textView:self shouldChangeTextInRange:aRange replacementString:aString];
}

- (CPDictionary)_sendDelegateShouldChangeTypingAttributes:(CPDictionary)typingAttributes toAttributes:(CPDictionary)attributes
{
    if (!(_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_doCommandBySelector))
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
    CPTextViewDelegateKey = @"CPTextViewDelegateKey";

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
            [_typingAttributes setObject:[CPColor blackColor] forKey:CPForegroundColorAttributeName];

        _textColor = [_typingAttributes valueForKey:CPForegroundColorAttributeName];
        [self setFont:[_typingAttributes valueForKey:CPFontAttributeName]];

        [self setString:[_textStorage string]];
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
}

@end


@implementation _CPSelectionBox : CPObject
{
    DOMElement  _selectionBoxDOM;
    CGRect      _rect;
    CPColor     _color
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

- (void)isBlinking
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
		rect.origin.x = CGRectGetMaxX(rect)

    [self setRect:rect];
}

@end


var _CPNativeInputField,
    _CPNativeInputFieldKeyDownCalled,
    _CPNativeInputFieldKeyUpCalled,
    _CPNativeInputFieldKeyPressedCalled,
    _CPNativeInputFieldActive;

var _CPCopyPlaceholder = '-';

@implementation _CPNativeInputManager : CPObject

+ (BOOL)isNativeInputFieldActive
{
    return _CPNativeInputFieldActive;
}

+ (void)cancelCurrentNativeInputSession
{

#if PLATFORM(DOM)
    _CPNativeInputField.innerHTML = '';
#endif

    [self _endInputSessionWithString:_CPNativeInputField.innerHTML];
}

+ (void)cancelCurrentInputSessionIfNeeded
{
    if (!_CPNativeInputFieldActive)
        return;

    [self cancelCurrentNativeInputSession];
}

+ (void)_endInputSessionWithString:(CPString)aStr
{
    _CPNativeInputFieldActive = NO;

    var currentFirstResponder = [[CPApp keyWindow] firstResponder],
        placeholderRange = CPMakeRange([currentFirstResponder selectedRange].location - 1, 1);

    [currentFirstResponder setSelectedRange:placeholderRange];
    [currentFirstResponder insertText:aStr];
    _CPNativeInputField.innerHTML = '';


    [self hideInputElement];
    [currentFirstResponder updateInsertionPointStateAndRestartTimer:YES];
}

+ (void)initialize
{
#if PLATFORM(DOM)
    _CPNativeInputField = document.createElement("div");
    _CPNativeInputField.contentEditable = YES;
    _CPNativeInputField.style.width = "64px";
    _CPNativeInputField.style.zIndex = 10000;
    _CPNativeInputField.style.position = "absolute";
    _CPNativeInputField.style.visibility = "visible";
    _CPNativeInputField.style.padding = "0px";
    _CPNativeInputField.style.margin = "0px";
    _CPNativeInputField.style.whiteSpace = "pre";
    _CPNativeInputField.style.outline = "0px solid transparent";

    document.body.appendChild(_CPNativeInputField);

    _CPNativeInputField.addEventListener("keyup", function(e)
    {
        _CPNativeInputFieldKeyUpCalled = YES;

        // filter out the shift-up, cursor keys and friends used to access the deadkeys
        // fixme: e.which is depreciated(?) -> find a better way to identify the modifier-keyups
        if (e.which < 27 || e.which == 91 || e.which == 93) // include apple command keys
        {
            if (e.which == 13)
                _CPNativeInputField.innerHTML = '';

            if (_CPNativeInputField.innerHTML.length == 0 || _CPNativeInputField.innerHTML.length > 2) // backspace
                [self cancelCurrentInputSessionIfNeeded];

            return false; // prevent the default behaviour
        }

        var currentFirstResponder = [[CPApp keyWindow] firstResponder];

        if (![currentFirstResponder respondsToSelector:@selector(_activateNativeInputElement:)])
            return false; // prevent the default behaviour

        var charCode = _CPNativeInputField.innerHTML.charCodeAt(0);

        // å and Å need to be filtered out in keyDown: due to chrome inserting 229 on a deadkey
        if (charCode == 229 || charCode == 197)
        {
            [currentFirstResponder insertText:_CPNativeInputField.innerHTML];
            _CPNativeInputField.innerHTML = '';
            return;
        }

        // chrome-trigger: keypressed is omitted for deadkeys
        if (!_CPNativeInputFieldActive && _CPNativeInputFieldKeyPressedCalled == NO && _CPNativeInputField.innerHTML.length && _CPNativeInputField.innerHTML != _CPCopyPlaceholder && _CPNativeInputField.innerHTML.length < 3)
        {
            _CPNativeInputFieldActive = YES;
            [currentFirstResponder _activateNativeInputElement:_CPNativeInputField];
        }
        else
        {
            if (_CPNativeInputFieldActive)
                [self _endInputSessionWithString:_CPNativeInputField.innerHTML];

            // prevent the copy placeholder beeing removed by cursor keys
            if (_CPNativeInputFieldKeyPressedCalled)
               _CPNativeInputField.innerHTML = '';
        }

        _CPNativeInputFieldKeyDownCalled = NO;

        return false; // prevent the default behaviour
    }, true);

    _CPNativeInputField.addEventListener("keydown", function(e)
    {
        // this protects from heavy typing and the shift key
        if (_CPNativeInputFieldKeyDownCalled)
            return true;

        _CPNativeInputFieldKeyDownCalled = YES;
        _CPNativeInputFieldKeyUpCalled = NO;
        _CPNativeInputFieldKeyPressedCalled = NO;
        var currentFirstResponder = [[CPApp keyWindow] firstResponder];

        // webkit-browsers: cursor keys do not emit keypressed and would otherwise activate deadkey mode
        if (!CPBrowserIsEngine(CPGeckoBrowserEngine) && e.which >= 37 && e.which <= 40)
            _CPNativeInputFieldKeyPressedCalled = YES;

        if (![currentFirstResponder respondsToSelector:@selector(_activateNativeInputElement:)])
            return;

        // FF-trigger: here the best way to detect a dead key is the missing keyup event
        if (CPBrowserIsEngine(CPGeckoBrowserEngine))
            setTimeout(function(){
                _CPNativeInputFieldKeyDownCalled = NO;

                if (!_CPNativeInputFieldActive && _CPNativeInputFieldKeyUpCalled == NO && _CPNativeInputField.innerHTML.length && _CPNativeInputField.innerHTML != _CPCopyPlaceholder && _CPNativeInputField.innerHTML.length < 3 && !e.repeat)
                {
                    _CPNativeInputFieldActive = YES;
                    [currentFirstResponder _activateNativeInputElement:_CPNativeInputField];
                }
                else if (!_CPNativeInputFieldActive)
                    [self hideInputElement];
            }, 200);

        return false;
    }, true); // capture mode

    _CPNativeInputField.addEventListener("keypress", function(e)
    {
        _CPNativeInputFieldKeyUpCalled = YES;
        _CPNativeInputFieldKeyPressedCalled = YES;
        return false;

    }, true); // capture mode

    _CPNativeInputField.onpaste = function(e)
    {
        var nativeClipboard = (e.originalEvent || e).clipboardData,
            richtext,
            pasteboard = [CPPasteboard generalPasteboard],
            currentFirstResponder = [[CPApp keyWindow] firstResponder],
            isPlain = NO;

        if ([currentFirstResponder respondsToSelector:@selector(isRichText)] && ![currentFirstResponder isRichText])
            isPlain = YES;

        // this is the rich chrome / FF codepath (where we can use RTF directly)
        if ((richtext = nativeClipboard.getData('text/rtf')) && !(!!window.event.shiftKey) && !isPlain)
        {
            e.preventDefault();

            // setTimeout to prevent flickering in FF
            setTimeout(function(){
                [currentFirstResponder insertText:[[_CPRTFParser new] parseRTF:richtext]]
            }, 20);

            return false;
        }

        // plain is the same in all browsers...

        var data = e.clipboardData.getData('text/plain'),
            cappString = [pasteboard stringForType:CPStringPboardType];

        if (cappString != data)
        {
            [pasteboard declareTypes:[CPStringPboardType] owner:nil];
            [pasteboard setString:data forType:CPStringPboardType];
        }

        setTimeout(function(){   // prevent dom-flickering (only needed for FF)
            [currentFirstResponder paste:self];
        }, 20);

        return false;
    }

    if (CPBrowserIsEngine(CPGeckoBrowserEngine))
    {
        _CPNativeInputField.oncopy = function(e)
        {
            var pasteboard = [CPPasteboard generalPasteboard],
                string,
                currentFirstResponder = [[CPApp keyWindow] firstResponder];

            [currentFirstResponder copy:self];

            var stringForPasting = [pasteboard stringForType:CPStringPboardType];
            e.clipboardData.setData('text/plain', stringForPasting);

            return false;
        }

        _CPNativeInputField.oncut = function(e)
        {
            var pasteboard = [CPPasteboard generalPasteboard],
                string,
                currentFirstResponder = [[CPApp keyWindow] firstResponder];

            // prevent dom-flickering
            setTimeout(function(){
                [currentFirstResponder cut:self];
            }, 20);

            // this is necessary because cut will only execute in the future
            [currentFirstResponder copy:self];

            var stringForPasting = [pasteboard stringForType:CPStringPboardType];

            e.clipboardData.setData('text/plain', stringForPasting);

            return false;
        }
    }
#endif
}

+ (void)focusForTextView:(CPTextView)currentFirstResponder
{
    if (![currentFirstResponder respondsToSelector:@selector(_activateNativeInputElement:)])
        return;

    [self hideInputElement];

#if PLATFORM(DOM)
    _CPNativeInputField.focus();
#endif

}

+ (void)focusForClipboardOfTextView:(CPTextView)textview
{

#if PLATFORM(DOM)
    if (!_CPNativeInputFieldActive && _CPNativeInputField.innerHTML.length == 0)
        _CPNativeInputField.innerHTML = _CPCopyPlaceholder;  // make sure we have a selection to allow the native pasteboard work in safari

    [self focusForTextView:textview];

    // select all in the contenteditable div (http://stackoverflow.com/questions/12243898/how-to-select-all-text-in-contenteditable-div)
    if (document.body.createTextRange)
    {
        var range = document.body.createTextRange();

        range.moveToElementText(_CPNativeInputField);
        range.select();
    }
    else if (window.getSelection)
    {
        var selection = window.getSelection(),
            range = document.createRange();

        range.selectNodeContents(_CPNativeInputField);
        selection.removeAllRanges();
        selection.addRange(range);
    }
#endif

}

+ (void)hideInputElement
{

#if PLATFORM(DOM)
    _CPNativeInputField.style.top = "-10000px";
    _CPNativeInputField.style.left = "-10000px";
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
    if (aValue === nil || (aValue.isa && [aValue isMemberOfClass:CPNull]))
        [_source _setPlaceholderString:[self _placeholderForMarker:CPNullMarker]];
    else
        [_source _setPlaceholderString:nil];

    [_source setObjectValue:aValue];
}

@end


                              
