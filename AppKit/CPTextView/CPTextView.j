/*
 *  CPTextView.j
 *  AppKit
 *
 *  Created by Daniel Boehringer on 27/12/2013.
 *  All modifications copyright Daniel Boehringer 2013.
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

@class _CPRTFProducer;
@class _CPRTFParser;
@class CPClipView;

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

_characterTripletFromStringAtIndex=function(string, index)
{
    if([string isKindOfClass:CPAttributedString])
        string = string._string;

    var tripletRange = _MakeRangeFromAbs(MAX(0, index - 1), MIN(string.length, index + 2));
    return [string substringWithRange:tripletRange];
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

@implementation _CPCaret : CPObject
{
    DOMElement  _caretDOM;
    CGRect      _rect;
    CPTextView  _textView;
    BOOL        _drawCaret;
    CPTimer     _caretTimer;
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

- (id)initForTextView:(CPTextView)aView
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

- (void)setVisibility:(BOOL)flag
{
#if PLATFORM(DOM)
    _textView._caretDOM.style.visibility = flag ? "visible" : "hidden";
#endif
    if (!flag)
        [self stopBlinking];
}

- (void)_blinkCaret:(CPTimer)aTimer
{
    _drawCaret = !_drawCaret;
    [_textView setNeedsDisplayInRect:_rect];
}

- (void)startBlinking
{
    _drawCaret = YES;
    _caretTimer = [CPTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_blinkCaret:) userInfo:nil repeats:YES];
}

- (void)isBlinking
{
    return [_caretTimer isValid];
}

- (void)stopBlinking
{
    _drawCaret=NO;
    if (_caretTimer)
    {
        [_caretTimer invalidate];
        _caretTimer = nil;
    }
}

@end

/*!
    @ingroup appkit
    @class CPTextView
*/
@implementation CPTextView : CPText
{
    BOOL                        _allowsUndo                   @accessors(property=allowsUndo);
    BOOL                        _isHorizontallyResizable      @accessors(getter=isHorizontallyResizable, setter=setHorinzontallyResizable:);
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
    CPFont                      _font                         @accessors(property=font);
    CPLayoutManager             _layoutManager                @accessors(getter=layoutManager);
    CPRange                     _selectionRange               @accessors(getter=selectedRange);
    CPSelectionGranularity      _selectionGranularity         @accessors(property=selectionGranularity);

    CPSelectionGranularity      _previousSelectionGranularity;  // private
    CPSelectionGranularity      _copySelectionGranularity;       // private

    CPTextContainer             _textContainer                @accessors(property=textContainer);
    CPTextStorage               _textStorage                  @accessors(getter=textStorage);
    id <CPTextViewDelegate>     _delegate                     @accessors(property=delegate);

    unsigned                    _delegateRespondsToSelectorMask;

    int                         _startTrackingLocation;

    _CPCaret                    _caret;
    CPTimer                     _scrollingTimer;

    BOOL                        _scrollingDownward;

    int                         _stickyXLocation;

    CPArray                     _selectionSpans;
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
    }

    [self registerForDraggedTypes:[CPColorDragType]];

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

    [self setEditable:YES];
    [self setSelectable:YES];

    _delegate = nil;
    _delegateRespondsToSelectorMask = 0;

    _selectionGranularity = CPSelectByCharacter;
    _selectedTextAttributes = [CPDictionary dictionaryWithObject:[CPColor selectedTextBackgroundColor]
                                            forKey:CPBackgroundColorAttributeName];

    _insertionPointColor = [CPColor blackColor];
    _textColor = [CPColor blackColor];
    _font = [CPFont systemFontOfSize:12.0];
    [self setFont:_font];
    [self setBackgroundColor:[CPColor whiteColor]];

    _typingAttributes = [[CPDictionary alloc] initWithObjects:[_font, _textColor] forKeys:[CPFontAttributeName, CPForegroundColorAttributeName]];

    _minSize = CGSizeCreateCopy(_frame.size);
    _maxSize = CGSizeMake(_frame.size.width, 1e7);

    [self setRichText:NO];
    _usesFontPanel = YES;
    _allowsUndo = YES;
    _isVerticallyResizable = YES;
    _isHorizontallyResizable = NO;

    _caret = [[_CPCaret alloc] initForTextView:self];
    [_caret setRect:CGRectMake(0, 0, 1, 11)]
}

#pragma mark -
#pragma mark Copy and past methods

- (void)copy:(id)sender
{
   _copySelectionGranularity = _previousSelectionGranularity;
   [super copy:sender];
}

- (void)paste:(id)sender
{
    if (_copySelectionGranularity > 0)
    {
        if (![self _isCharacterAtIndex:MAX(0, _selectionRange.location - 1) granularity:_copySelectionGranularity])
            [self insertText:" "];
    }
    [super paste:sender];

    if (_copySelectionGranularity > 0)
    {
        if (![self _isCharacterAtIndex:CPMaxRange(_selectionRange) granularity:_copySelectionGranularity])
            [self insertText:" "];
    }
}

#pragma mark -
#pragma mark Responders method

- (BOOL)acceptsFirstResponder
{
    return [self isSelectable]; // editable textviews are automatically selectable
}

- (BOOL)becomeFirstResponder
{
    [self updateInsertionPointStateAndRestartTimer:YES];
    [[CPFontManager sharedFontManager] setSelectedFont:[self font] isMultiple:NO];
    [self setNeedsDisplay:YES];

    return YES;
}

- (BOOL)resignFirstResponder
{
    [_caret stopBlinking];
    [self setNeedsDisplay:YES];

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

    var notificationCenter = [CPNotificationCenter defaultCenter];

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

- (BOOL) _isFirstResponder
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

// fixme: rich text should return attributed string, shouldn't it?
- (CPString)objectValue
{
    return [self stringValue];
}

- (void)setString:(CPString)aString
{
    [_textStorage replaceCharactersInRange:CPMakeRange(0, [_layoutManager numberOfCharacters]) withString:aString];
    [self didChangeText];
    [_layoutManager _validateLayoutAndGlyphs];
    [self sizeToFit];
    [self setNeedsDisplay:YES];
}

- (CPString)string
{
    return [_textStorage string];
}

// KVO support
- (void)setValue:(CPString)aValue
{
    [self setString:[aValue description]];
}

- (id)value
{
    [self string];
}

- (void)setTextContainer:(CPTextContainer)aContainer
{
    _textContainer = aContainer;
    _layoutManager = [_textContainer layoutManager];
    _textStorage = [_layoutManager textStorage];
    [_textStorage setFont:_font];
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
- (void)_replaceCharactersInRange:aRange withAttributedString:(CPString)aString
{
    [[[[self window] undoManager] prepareWithInvocationTarget:self]
                _replaceCharactersInRange:CPMakeRange(aRange.location, [aString length])
                withAttributedString:[_textStorage attributedSubstringFromRange:CPMakeRangeCopy(aRange)]];

    [_textStorage replaceCharactersInRange:aRange withAttributedString:aString];
    [self _fixupReplaceForRange:CPMakeRange(aRange.location, [aString length])];
}
- (void)_replaceCharactersInRange:(CPRange)aRange withString:(CPString)aString
{
    [[[[self window] undoManager] prepareWithInvocationTarget:self]
                _replaceCharactersInRange:CPMakeRange(aRange.location, [aString length])
                withString:[[self string] substringWithRange:CPMakeRangeCopy(aRange)]];

    [_textStorage replaceCharactersInRange:CPMakeRangeCopy(aRange) withString:aString];
    [self _fixupReplaceForRange:CPMakeRange(aRange.location, [aString length])];
}

- (void)insertText:(CPString)aString
{
    var isAttributed = [aString isKindOfClass:CPAttributedString],
        string = isAttributed ? [aString string]:aString;

    if (![self shouldChangeTextInRange:CPMakeRangeCopy(_selectionRange) replacementString:string])
        return;

    var undoManager = [[self window] undoManager];

    if (isAttributed)
    {
        [[undoManager prepareWithInvocationTarget:self]
                _replaceCharactersInRange:CPMakeRange(_selectionRange.location, [aString length])
                withAttributedString:[_textStorage attributedSubstringFromRange:CPMakeRangeCopy(_selectionRange)]];

        [undoManager setActionName:@"Replace rich text"];
        [_textStorage replaceCharactersInRange:CPMakeRangeCopy(_selectionRange) withAttributedString:aString];
    }
    else
    {
        [undoManager setActionName:@"Replace plain text"];

        if ([self isRichText])
        {
            aString = [[CPAttributedString alloc] initWithString:aString attributes:_typingAttributes];
            [[undoManager prepareWithInvocationTarget:self]
                _replaceCharactersInRange:CPMakeRange(_selectionRange.location, [aString length])
                withAttributedString:[_textStorage attributedSubstringFromRange:CPMakeRangeCopy(_selectionRange)]];

            [_textStorage replaceCharactersInRange:CPMakeRangeCopy(_selectionRange) withAttributedString:aString];
        }
        else
        {
            [[undoManager prepareWithInvocationTarget:self] _replaceCharactersInRange:CPMakeRange(_selectionRange.location, [aString length]) withString:[[self string] substringWithRange:CPMakeRangeCopy(_selectionRange)]];
            [_textStorage replaceCharactersInRange:CPMakeRangeCopy(_selectionRange) withString:aString];
        }
    }

    [self setSelectedRange:CPMakeRange(_selectionRange.location + [string length], 0)];
    [self didChangeText];
    [_layoutManager _validateLayoutAndGlyphs];
    [self sizeToFit];
    [self scrollRangeToVisible:_selectionRange];
    _stickyXLocation = _caret._rect.origin.x;
}

#pragma mark -
#pragma mark Drawing methods

- (void)drawInsertionPointInRect:(CGRect)aRect color:(CPColor)aColor turnedOn:(BOOL)flag
{
    [_caret setRect:aRect];
    [_caret setVisibility:flag];
}

- (id) _createSelectionSpanForRect:(CPRect)aRect andColor:(CPColor)aColor
{
#if PLATFORM(DOM)
    var ret = document.createElement("span");
    ret.style.position = "absolute";
    ret.style.visibility = "visible";
    ret.style.padding = "0px";
    ret.style.margin = "0px";
    ret.style.whiteSpace = "pre";
    ret.style.backgroundColor = [aColor cssString];

    ret.style.width = (aRect.size.width)+"px";
    ret.style.left = (aRect.origin.x) + "px";
    ret.style.top = (aRect.origin.y) + "px";
    ret.style.height = (aRect.size.height) + "px";
    ret.style.zIndex = -1000;
    ret.oncontextmenu = ret.onmousedown = ret.onselectstart = function () { return false; };
    return ret;
#else
    return nil;
#endif
}

- (void)drawRect:(CGRect)aRect
{
#if PLATFORM(DOM)
    var range = [_layoutManager glyphRangeForBoundingRect:aRect inTextContainer:_textContainer];

    if (_selectionSpans)
    {
        for (var i = 0; i < _selectionSpans.length; i++)
        {
            _DOMElement.removeChild(_selectionSpans[i]);
        }
    }
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

            var newSpan = [self _createSelectionSpanForRect:rects[i] andColor:effectiveSelectionColor];
            _selectionSpans.push(newSpan);
            _DOMElement.appendChild(newSpan);
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
    [self setSelectedRange:range affinity:0 stillSelecting:NO];
}

- (void)setSelectedRange:(CPRange)range affinity:(CPSelectionAffinity /* unused */ )affinity stillSelecting:(BOOL)selecting
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

        var peekLoc = MAX(0, range.location - 1);

        if (_isNewlineCharacter([[_textStorage string] characterAtIndex:peekLoc]))
            peekLoc++;

        [self setTypingAttributes:[_textStorage attributesAtIndex:peekLoc effectiveRange:nil]];

        [[CPNotificationCenter defaultCenter] postNotificationName:CPTextViewDidChangeSelectionNotification object:self];
        if (_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_didChangeSelection)
            [_delegate textViewDidChangeSelection:[[CPNotification alloc] initWithName:CPTextViewDidChangeSelectionNotification object:self userInfo:nil]];

    }
}

- (CPArray)selectedRanges
{
    return [_selectionRange];
}

- (CPRange)selectionRangeForProposedRange:(CPRange)proposedRange granularity:(CPSelectionGranularity)granularity
{
    var textStorageLength = [_layoutManager numberOfCharacters];

    if (textStorageLength == 0)
        return CPMakeRange(0, 0);

    if (proposedRange.location >= textStorageLength)
        return CPMakeRange(textStorageLength, 0);

    if (CPMaxRange(proposedRange) > textStorageLength)
        proposedRange.length = textStorageLength - proposedRange.location;

    var string = [_textStorage string];

    switch (granularity)
    {
        case CPSelectByWord:
            var wordRange = [self _characterRangeForIndex:proposedRange.location inRange:proposedRange asDefinedByRegex:[[self class] _wordBoundaryRegex] skip:YES];

            if (proposedRange.length)
                wordRange = CPUnionRange(wordRange, [self _characterRangeForIndex:CPMaxRange(proposedRange) inRange:proposedRange asDefinedByRegex:[[self class] _wordBoundaryRegex] skip:NO]);

            return wordRange;

        case CPSelectByParagraph:
            var parRange = [self _characterRangeForIndex:proposedRange.location inRange:proposedRange asDefinedByRegex:[[self class] _paragraphBoundaryRegex] skip:YES];

            if (proposedRange.length)
                parRange = CPUnionRange(parRange, [self _characterRangeForIndex:CPMaxRange(proposedRange)
                                                                        inRange:proposedRange
                                                               asDefinedByRegex:[[self class] _paragraphBoundaryRegex]
                                                                           skip:NO]);

            if (parRange.length > 0 && [self _isCharacterAtIndex:CPMaxRange(parRange) granularity:CPSelectByParagraph])
                parRange.length++;

            return parRange;

        default:
            return proposedRange;
    }
}

#pragma mark -
#pragma mark Keyboard events

- (void)keyDown:(CPEvent)event
{
    [self interpretKeyEvents:[event]];
}


#pragma mark -
#pragma mark Mouse Events

- (void)mouseDown:(CPEvent)event
{
    var fraction = [],
        point = [self convertPoint:[event locationInWindow] fromView:nil],
        granularities = [-1, CPSelectByCharacter, CPSelectByWord, CPSelectByParagraph];

    [_caret setVisibility:NO];

    // convert to container coordinate
    point.x -= _textContainerOrigin.x;
    point.y -= _textContainerOrigin.y;

    _startTrackingLocation = [_layoutManager glyphIndexForPoint:point inTextContainer:_textContainer fractionOfDistanceThroughGlyph:fraction];

    if (_startTrackingLocation === CPNotFound)
        _startTrackingLocation = [_layoutManager numberOfCharacters];

    if (fraction[0] > 0.5)
        _startTrackingLocation++;

    [self setSelectionGranularity:granularities[[event clickCount]]];

    var setRange = CPMakeRange(_startTrackingLocation, 0);

    if ([event modifierFlags] & CPShiftKeyMask)
    {
        setRange = _MakeRangeFromAbs(_startTrackingLocation < _MidRange(_selectionRange)?
                                     CPMaxRange(_selectionRange) : _selectionRange.location,
                                     _startTrackingLocation);
    }

    [self setSelectedRange:setRange affinity:0 stillSelecting:YES];

    _scrollingTimer = [CPTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_supportScrolling:) userInfo:nil repeats:YES];  // fixme: only start if we are in the scrolling areas
}

- (void)_supportScrolling:(CPTimer)aTimer
{
    [self mouseDragged:[CPApp currentEvent]];
}

- (void)_clearRange:(CPRange)range
{
    var rects = [_layoutManager rectArrayForCharacterRange:nil withinSelectedCharacterRange:range
                                 inTextContainer:_textContainer
                                 rectCount:nil],
        l = rects.length;

    for (var i = 0; i < l; i++)
    {
        rects[i].origin.x += _textContainerOrigin.x;
        rects[i].origin.y += _textContainerOrigin.y;
        [self setNeedsDisplayInRect:rects[i]];
    }
}

- (void)mouseDragged:(CPEvent)event
{
    var fraction = [],
        point = [self convertPoint:[event locationInWindow] fromView:nil];

    // convert to container coordinate
    point.x -= _textContainerOrigin.x;
    point.y -= _textContainerOrigin.y;

    var oldRange = [self selectedRange],
        index = [_layoutManager glyphIndexForPoint:point
                                inTextContainer:_textContainer
                                fractionOfDistanceThroughGlyph:fraction];

    if (index === CPNotFound)
        index = _scrollingDownward ? CPMaxRange(oldRange) : oldRange.location;

    if (fraction[0] > 0.5)
        index++;

    if (index > oldRange.location)
    {
        [self _clearRange:_MakeRangeFromAbs(oldRange.location,index)];
        _scrollingDownward = YES;
    }

    if (index < CPMaxRange(oldRange))
    {
        [self _clearRange:_MakeRangeFromAbs(index, CPMaxRange(oldRange))];
        _scrollingDownward = NO;
    }

    if (index < _startTrackingLocation)
        [self setSelectedRange:CPMakeRange(index, _startTrackingLocation - index)
              affinity:0
              stillSelecting:YES];
    else
        [self setSelectedRange:CPMakeRange(_startTrackingLocation, index - _startTrackingLocation)
              affinity:0
              stillSelecting:YES];

    [self scrollRangeToVisible:CPMakeRange(index, 0)];
}

// handle all the other methods from CPKeyBinding.j

- (void)mouseUp:(CPEvent)event
{
    /* will post CPTextViewDidChangeSelectionNotification */
    _previousSelectionGranularity = [self selectionGranularity];
    [self setSelectionGranularity:CPSelectByCharacter];
    [self setSelectedRange:[self selectedRange] affinity:0 stillSelecting:NO];

    var point = [_layoutManager locationForGlyphAtIndex:[self selectedRange].location];
    _stickyXLocation = point.x;
    _startTrackingLocation = _selectionRange.location;

    if (_scrollingTimer)
    {   [_scrollingTimer invalidate];
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

    if (point.y >= rectEnd.origin.y)
        return;

    if (_stickyXLocation)
        point.x = _stickyXLocation;

    // <!> FIXME: Define constants for this magic number
    point.y += 2 + rectSource.size.height;
    point.x += 2;

    var dindex= [_layoutManager glyphIndexForPoint:point inTextContainer:_textContainer fractionOfDistanceThroughGlyph:fraction],
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

    var fraction = [],
        sindex = [self selectedRange].location,
        rectSource = [_layoutManager boundingRectForGlyphRange:CPMakeRange(sindex, 1) inTextContainer:_textContainer],
        point = rectSource.origin;

    if (point.y <= 0)
        return;

    if (_stickyXLocation)
        point.x = _stickyXLocation;

    point.y -= 2;    // FIXME <!> these should not be constants
    point.x += 2;

    var dindex = [_layoutManager glyphIndexForPoint:point inTextContainer:_textContainer fractionOfDistanceThroughGlyph:fraction],
        oldStickyLoc = _stickyXLocation;

    if (fraction[0] > 0.5)
        dindex++;

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
    var inWord = ![self _isCharacterAtIndex:(move > 0 ? CPMaxRange(aRange) : aRange.location) + move granularity:granularity],
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
    {
        aSel = CPMakeRange((aSel.location < _startTrackingLocation? aSel.location : CPMaxRange(aSel)) + move, 0);
    }

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
        [self _establishSelection:CPMakeRange(_selectionRange.location - 1, 0) byExtending:NO];
}

- (void)moveToEndOfParagraph:(id)sender
{
    if ([self isSelectable])
       [self _moveSelectionIntoDirection:1 granularity:CPSelectByParagraph];
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
    if ([self isSelectable])
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

    var fragment = [_layoutManager _lineFragmentForLocation:_selectionRange.location];

    if (!fragment && _selectionRange.location > 0)
        fragment = [_layoutManager _lineFragmentForLocation:_selectionRange.location - 1];

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

    var fragment = [_layoutManager _lineFragmentForLocation:_selectionRange.location];

    if (!fragment)
        return;

    var loc = CPMaxRange(fragment._range);

    if (loc > 0 && loc < [_layoutManager numberOfCharacters])
        loc = MAX(0, loc - 1);

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
        [self _establishSelection:CPMakeRange(CPMaxRange(_selectionRange) + 1, 0) byExtending:NO];
}

- (void)_deleteForRange:(CPRange)changedRange
{
    if (![self shouldChangeTextInRange:changedRange replacementString:@""])
        return;

    changedRange = CPIntersectionRange(CPMakeRange(0, [_layoutManager numberOfCharacters]), changedRange);

    [[[[self window] undoManager] prepareWithInvocationTarget:self] _replaceCharactersInRange:CPMakeRange(_selectionRange.location, 0) withAttributedString:[_textStorage attributedSubstringFromRange:CPMakeRangeCopy(changedRange)]];
    [_textStorage deleteCharactersInRange:CPMakeRangeCopy(changedRange)];

    [self setSelectedRange:CPMakeRange(changedRange.location, 0)];
    [self didChangeText];
    [_layoutManager _validateLayoutAndGlyphs];
    [self sizeToFit];
    _stickyXLocation = _caret._rect.origin.x;
}

- (void)deleteBackward:(id)sender
{
    var changedRange;

    if (CPEmptyRange(_selectionRange) && _selectionRange.location > 0)
        changedRange = CPMakeRange(_selectionRange.location - 1, 1);
    else
        changedRange = _selectionRange;

    if (_previousSelectionGranularity > 0 &&
        changedRange.location > 0 && [self _isCharacterAtIndex:(changedRange.location - 1) granularity:_previousSelectionGranularity] &&
        changedRange.location < [[self string] length] && [self _isCharacterAtIndex:CPMaxRange(changedRange) granularity:_previousSelectionGranularity])
    {
        changedRange.length++;
    }

    [self _deleteForRange:changedRange];
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
    [self deleteBackward:sender];
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

        /* check that new attributes contains essentials one's */
        if (![_typingAttributes containsKey:CPFontAttributeName])
            [_typingAttributes setObject:[self font] forKey:CPFontAttributeName];

        if (![_typingAttributes containsKey:CPForegroundColorAttributeName])
            [_typingAttributes setObject:[self textColor] forKey:CPForegroundColorAttributeName];
    }

    [[CPNotificationCenter defaultCenter] postNotificationName:CPTextViewDidChangeTypingAttributesNotification
                                                        object:self];

     if (_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_didChangeTypingAttributes)
        [_delegate textViewDidChangeTypingAttributes:[[CPNotification alloc] initWithName:CPTextViewDidChangeTypingAttributesNotification object:self userInfo:nil]];
}

- (void)delete:(id)sender
{
    [self deleteBackward:sender];
}


#pragma mark -
#pragma mark Font methods

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

    [_textStorage addAttribute:CPFontAttributeName value:font range:CPMakeRangeCopy(range)];
    [_layoutManager _validateLayoutAndGlyphs];
    [self scrollRangeToVisible:CPMakeRange(CPMaxRange(range), 0)];
}

- (void)changeFont:(id)sender
{
    var currRange = CPMakeRange(_selectionRange.location, 0),
        oldFont,
        attributes,
        scrollRange = CPMakeRange(CPMaxRange(_selectionRange), 0);

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
    _textColor = aColor;

    if (_textColor)
        [_textStorage addAttribute:CPForegroundColorAttributeName value:_textColor range:CPMakeRange(0, [_layoutManager numberOfCharacters])];
    else
        [_textStorage removeAttribute:CPForegroundColorAttributeName range:CPMakeRange(0, [_layoutManager numberOfCharacters])];

    [_layoutManager _validateLayoutAndGlyphs];
    [self scrollRangeToVisible:CPMakeRange([_layoutManager numberOfCharacters], 0)];
}

- (void)setTextColor:(CPColor)aColor range:(CPRange)range
{
    if (![self isRichText])
        return;

    if (!CPEmptyRange(_selectionRange))
    {
        if (aColor)
            [_textStorage addAttribute:CPForegroundColorAttributeName value:aColor range:CPMakeRangeCopy(range)];
        else
            [_textStorage removeAttribute:CPForegroundColorAttributeName range:CPMakeRangeCopy(range)];
    }
    else
    {
        [_typingAttributes setObject:aColor forKey:CPForegroundColorAttributeName];
    }

    [_layoutManager _validateLayoutAndGlyphs];
    [self setNeedsDisplay:YES];
    [self scrollRangeToVisible:CPMakeRange(CPMaxRange(range), 0)];
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
        desiredSize = aSize,
        rect = [_layoutManager boundingRectForGlyphRange:CPMakeRange(0, MAX(0, [_layoutManager numberOfCharacters] - 1)) inTextContainer:_textContainer],
        myClipviewSize = nil;

    if ([[self superview] isKindOfClass:[CPClipView class]])
        myClipviewSize = [[self superview] frame].size;


    if ([_layoutManager extraLineFragmentTextContainer] === _textContainer)
        rect = CGRectUnion(rect, [_layoutManager extraLineFragmentRect]);

    if (_isHorizontallyResizable)
    {
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

    return characterSet.exec(_characterTripletFromStringAtIndex([_textStorage string], index)) !== null;
}

+ (CPArray)_wordBoundaryRegex
{
    return /^(.|[\r\n])\W/m;
}
+ (CPArray)_paragraphBoundaryRegex
{
    return /^(.|[\r\n])[\n\r]/m;
}

- (CPRange)_characterRangeForIndex:(unsigned)index inRange:(CPRange) aRange asDefinedByRegex:(JSObject)regex skip:(BOOL)flag
{
    var wordRange = CPMakeRange(index, 0),
        numberOfCharacters = [_layoutManager numberOfCharacters],
        string = [_textStorage string];

    // do we start on a boundary character?
    if (flag && regex.exec(_characterTripletFromStringAtIndex([_textStorage string], index))  !== null)
    {
        // -> extend to the left
        for (var searchIndex = index - 1; searchIndex > 0 && regex.exec(_characterTripletFromStringAtIndex(string, searchIndex)) !== null; searchIndex--)
        {
            wordRange.location = searchIndex;
        }
        // -> extend to the right
        searchIndex = index + 1;
        while (searchIndex < numberOfCharacters && regex.exec(_characterTripletFromStringAtIndex(string, searchIndex)) !== null)
        {
            searchIndex++;
        }
        return _MakeRangeFromAbs(wordRange.location, MIN(MAX(0, numberOfCharacters - 1), searchIndex));
    }
    // -> extend to the left
    for (var searchIndex = index - 1; searchIndex >= 0 && regex.exec(_characterTripletFromStringAtIndex(string, searchIndex)) === null; searchIndex--)
    {
        wordRange.location = searchIndex;
    }
    // -> extend to the right
    index++;
    while (index < numberOfCharacters && regex.exec(_characterTripletFromStringAtIndex(string, index))  === null)
    {
        index++;
    }
    return _MakeRangeFromAbs(wordRange.location, MIN(MAX(0, numberOfCharacters), index));
}

- (CPRange)selectionRangeForProposedRange:(CPRange)proposedRange granularity:(CPSelectionGranularity)granularity
{
    var textStorageLength = [_layoutManager numberOfCharacters];

    if (textStorageLength == 0)
        return CPMakeRange(0, 0);

    if (proposedRange.location >= textStorageLength)
        return CPMakeRange(textStorageLength, 0);

    if (CPMaxRange(proposedRange) > textStorageLength)
        proposedRange.length = textStorageLength - proposedRange.location;

    var string = [_textStorage string];

    switch (granularity)
    {
        case CPSelectByWord:
            var wordRange = [self _characterRangeForIndex:proposedRange.location inRange:proposedRange asDefinedByRegex:[[self class] _wordBoundaryRegex] skip:YES];

            if (proposedRange.length)
                wordRange = CPUnionRange(wordRange, [self _characterRangeForIndex:CPMaxRange(proposedRange) inRange:proposedRange asDefinedByRegex:[[self class] _wordBoundaryRegex] skip:NO]);

            return wordRange;

        case CPSelectByParagraph:
            var parRange = [self _characterRangeForIndex:proposedRange.location inRange:proposedRange asDefinedByRegex:[[self class] _paragraphBoundaryRegex] skip:YES];

            if (proposedRange.length)
                parRange = CPUnionRange(parRange, [self _characterRangeForIndex:CPMaxRange(proposedRange)
                                                                        inRange:proposedRange
                                                               asDefinedByRegex:[[self class] _paragraphBoundaryRegex]
                                                                           skip:NO]);

            if (parRange.length > 0 && [self _isCharacterAtIndex:CPMaxRange(parRange) granularity:CPSelectByParagraph])
                parRange.length++;

            return parRange;

        default:
            return proposedRange;
    }
}

- (BOOL)shouldDrawInsertionPoint
{
    return (_selectionRange.length === 0 && [self _isFocused]);
}

- (void)updateInsertionPointStateAndRestartTimer:(BOOL)flag
{
    var caretRect;
 
    if (_selectionRange.length)
        [_caret setVisibility:NO];

    if (_selectionRange.location >= [_layoutManager numberOfCharacters])    // cursor is "behind" the last chacacter
    {
        caretRect = [_layoutManager boundingRectForGlyphRange:CPMakeRange(MAX(0,_selectionRange.location - 1), 1) inTextContainer:_textContainer];
        caretRect.origin.x += caretRect.size.width;

        if (_selectionRange.location > 0 && [[_textStorage string] characterAtIndex:_selectionRange.location - 1] === '\n')
        {
            caretRect.origin.y += caretRect.size.height;
            caretRect.origin.x = 0;
        }
    }
    else
    {
        caretRect = [_layoutManager boundingRectForGlyphRange:CPMakeRange(_selectionRange.location, 1) inTextContainer:_textContainer];
    }

    caretRect.origin.x += _textContainerOrigin.x;
    caretRect.origin.y += _textContainerOrigin.y;
    caretRect.size.width = 1;
    [_caret setRect:caretRect];

    if (flag)
        [_caret startBlinking];
}


#pragma mark -
#pragma mark Dragging operation

- (void)performDragOperation:(CPDraggingInfo)aSender
{
    var location = [self convertPoint:[aSender draggingLocation] fromView:nil],
        pasteboard = [aSender draggingPasteboard];

    if (![pasteboard availableTypeFromArray:[CPColorDragType]])
        return NO;

   [self setTextColor:[CPKeyedUnarchiver unarchiveObjectWithData:[pasteboard dataForType:CPColorDragType]] range:_selectionRange];
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


var CPTextViewContainerKey = @"CPTextViewContainerKey",
    CPTextViewLayoutManagerKey = @"CPTextViewLayoutManagerKey";
    CPTextViewTextStorageKey = @"CPTextViewTextStorageKey",
    CPTextViewInsertionPointColorKey = @"CPTextViewInsertionPointColorKey",
    CPTextViewSelectedTextAttributesKey = @"CPTextViewSelectedTextAttributesKey";

@implementation CPTextView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        [self _init];

        var container = [aCoder decodeObjectForKey:CPTextViewContainerKey];
        [container setTextView:self];

        [self setInsertionPointColor:[aCoder decodeObjectForKey:CPTextViewInsertionPointColorKey]];
        [self setString:[_textStorage string]];

        var selectedTextAttributes = [aCoder decodeObjectForKey:CPTextViewSelectedTextAttributesKey],
            enumerator = [selectedTextAttributes keyEnumerator],
            key;

        while (key = [enumerator nextObject])
            [_selectedTextAttributes setObject:[selectedTextAttributes valueForKey:key] forKey:key];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_textContainer forKey:CPTextViewContainerKey];
    [aCoder encodeObject:_insertionPointColor forKey:CPTextViewInsertionPointColorKey];
    [aCoder encodeObject:_selectedTextAttributes forKey:CPTextViewSelectedTextAttributesKey];
}

@end
