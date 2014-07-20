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

/*
    CPSelectionGranularity
*/
CPSelectByCharacter = 0;
CPSelectByWord      = 1;
CPSelectByParagraph = 2;

var kDelegateRespondsTo_textShouldBeginEditing                                          = 0x0001,
    kDelegateRespondsTo_textView_doCommandBySelector                                    = 0x0002,
    kDelegateRespondsTo_textView_willChangeSelectionFromCharacterRange_toCharacterRange = 0x0004,
    kDelegateRespondsTo_textView_shouldChangeTextInRange_replacementString              = 0x0008,
    kDelegateRespondsTo_textView_shouldChangeTypingAttributes_toAttributes              = 0x0010;

/*!
    @ingroup appkit
    @class CPTextView
*/
@implementation CPTextView : CPText
{
    BOOL                        _allowsUndo                 @accessors(property=allowsUndo);
    BOOL                        _isEditable                 @accessors(getter=isEditable, setter=setEditable:);
    BOOL                        _isHorizontallyResizable    @accessors(getter=isHorizontallyResizable, setter=setHorinzontallyResizable);
    BOOL                        _isRichText                 @accessors(getter=isRichText, setter=setRichText);
    BOOL                        _isSelectable               @accessors(getter=isSelectable, setter=setSelectable:);
    BOOL                        _isVerticallyResizable      @accessors(getter=isVerticallyResizable, setter=setVerticallyResizable);
    BOOL                        _usesFontPanel              @accessors(property=usesFontPanel);
    CGPoint                     _textContainerOrigin        @accessors(getter=textContainerOrigin);
    CGSize                      _minSize                    @accessors(property=minSize);
    CGSize                      _maxSize                    @accessors(property=maxSize);
    CGSize                      _textContainerInset         @accessors(property=textContainerInset);
    CPColor                     _insertionPointColor        @accessors(property=insertionPointColor);
    CPColor                     _textColor                  @accessors(property=textColor);
    CPDictionary                _selectedTextAttributes     @accessors(property=selectedTextAttributes);
    CPDictionary                _typingAttributes           @accessors(property=typingAttributes);
    CPFont                      _font                       @accessors(property=font);
    CPLayoutManager             _layoutManager              @accessors(getter=layoutManager);
    CPRange                     _selectionRange             @accessors(getter=selecionRange);
    CPSelectionGranularity      _selectionGranularity       @accessors(property=selectionGranularity);
    CPTextContainer             _textContainer              @accessors(property=textContainer);
    CPTextStorage               _textStorage                @accessors(getter=textStorage);
    id <CPTextViewDelegate>     _delegate                   @accessors(property=delegate);

    unsigned                    _delegateRespondsToSelectorMask;

    int                         _startTrackingLocation;

    BOOL                        _isFirstResponder;

    BOOL                        _drawCaret;
    CPTimer                     _caretTimer;
    CPTimer                     _scollingTimer;
    CGRect                      _caretRect;

    BOOL                        _scrollingDownward;

    var                         _caretDOM;
    int                         _stickyXLocation;
}


#pragma mark -
#pragma mark Class methods

/* <!> FIXME
    just a testing characterSet
    all of this depend of the current language.
    Need some CPLocale support and maybe even a FSM...
 */
+ (CPArray)_wordBoundaryCharacterArray
{
    return ['\n','\r', ' ', '\t', ',', ';', '.', '!', '?', '\'', '"', '-', ':'];
}

+ (CPArray)_paragraphBoundaryCharacterArray
{
    return ['\n','\r'];
}


#pragma mark -
#pragma mark Init methodes

- (id)initWithFrame:(CGRect)aFrame textContainer:(CPTextContainer)aContainer
{
    if (self = [super initWithFrame:aFrame])
    {
#if PLATFORM(DOM)
        self._DOMElement.style.cursor = "text";
#endif
        _textContainerInset = CGSizeMake(2,0);
        _textContainerOrigin = CGPointMake(_bounds.origin.x, _bounds.origin.y);
        [aContainer setTextView:self];
        _isEditable = YES;
        _isSelectable = YES;

        _isFirstResponder = NO;
        _delegate = nil;
        _delegateRespondsToSelectorMask = 0;
        _selectionRange = CPMakeRange(0, 0);

        _selectionGranularity = CPSelectByCharacter;
        _selectedTextAttributes = [CPDictionary dictionaryWithObject:[CPColor selectedTextBackgroundColor]
                                                forKey:CPBackgroundColorAttributeName];

        _insertionPointColor = [CPColor blackColor];
        _textColor = [CPColor blackColor];
        _font = [CPFont systemFontOfSize:12.0];
        [self setFont:_font];
        [self setBackgroundColor:[CPColor whiteColor]];


        _typingAttributes = [[CPDictionary alloc] initWithObjects:[_font, _textColor] forKeys:[CPFontAttributeName, CPForegroundColorAttributeName]];

        _minSize = CGSizeCreateCopy(aFrame.size);
        _maxSize = CGSizeMake(aFrame.size.width, 1e7);

        _isRichText = NO;
        _usesFontPanel = YES;
        _allowsUndo = YES;
        _isVerticallyResizable = YES;
        _isHorizontallyResizable = NO;

        _caretRect = CGRectMake(0, 0, 1, 11);
    }

    [self registerForDraggedTypes:[CPColorDragType]];

    return self;
}

- (id)initWithFrame:(CGRect)aFrame
{
    var layoutManager = [[CPLayoutManager alloc] init],
        textStorage = [[CPTextStorage alloc] init],
        container = [[CPTextContainer alloc] initWithContainerSize:CGSizeMake(aFrame.size.width, 1e7)];

    [textStorage addLayoutManager:layoutManager];
    [layoutManager addTextContainer:container];

    return [self initWithFrame:aFrame textContainer:container];
}


#pragma mark -
#pragma mark Responders method

- (BOOL)acceptsFirstResponder
{
    if (_isSelectable)
        return YES;

    return NO;
}

- (BOOL)becomeFirstResponder
{
    _isFirstResponder = YES;
    [self updateInsertionPointStateAndRestartTimer:YES];
    [[CPFontManager sharedFontManager] setSelectedFont:[self font] isMultiple:NO];
    [self setNeedsDisplay:YES];

    return YES;
}

- (BOOL)resignFirstResponder
{
    [_caretTimer invalidate];
    _caretTimer = nil;
    _isFirstResponder = NO;
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

    if (_delegate)
    {
        [notificationCenter removeObserver:_delegate name:CPTextDidChangeNotification object:self];
        [notificationCenter removeObserver:_delegate name:CPTextViewDidChangeSelectionNotification object:self];
        [notificationCenter removeObserver:_delegate name:CPTextViewDidChangeTypingAttributesNotification object:self];
    }

    _delegate = aDelegate;

    if (_delegate)
    {
        if ([_delegate respondsToSelector:@selector(textDidChange:)])
            [notificationCenter addObserver:_delegate selector:@selector(textDidChange:) name:CPTextDidChangeNotification object:self];

        if ([_delegate respondsToSelector:@selector(textViewDidChangeSelection:)])
            [notificationCenter addObserver:_delegate selector:@selector(textViewDidChangeSelection:) name:CPTextViewDidChangeSelectionNotification object:self];

        if ([_delegate respondsToSelector:@selector(textViewDidChangeTypingAttributes:)])
            [notificationCenter addObserver:_delegate selector:@selector(textViewDidChangeTypingAttributes:) name:CPTextViewDidChangeTypingAttributesNotification object:self];

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

- (BOOL)_isFocused
{
   return [[self window] isKeyWindow] && _isFirstResponder;
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

- (void)setEditable:(BOOL)flag
{
    _isEditable = flag;

    if (flag)
        _isSelectable = flag;
}

- (void)setSelectable:(BOOL)flag
{
    _isSelectable = flag;

    if (flag)
        _isEditable = flag;
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

- (BOOL)shouldChangeTextInRange:(CPRange)aRange replacementString:(CPString)aString
{
    if (!_isEditable)
        return NO;

    return [self _sendDelegateTextShouldBeginEditing] && [self _sendDelegateShouldChangeTextInRange:aRange replacementString:aString];
}


#pragma mark -
#pragma mark Insert characters methods

- (void)_replaceCharactersInRange:aRange withAttributedString:(CPString)aString
{
    [_textStorage replaceCharactersInRange:aRange withAttributedString:aString];
    [self setSelectedRange:CPMakeRange(aRange.location, [aString length])];
    [_layoutManager _validateLayoutAndGlyphs];
    [self sizeToFit];
    [self scrollRangeToVisible:_selectionRange];
    [self setNeedsDisplay:YES];

}
- (void)_replaceCharactersInRange:(CPRange)aRange withString:(CPString)aString
{
    [_textStorage replaceCharactersInRange:CPMakeRangeCopy(aRange) withString:aString];
    [self setSelectedRange:CPMakeRange(aRange.location, aString.length)];
    [_layoutManager _validateLayoutAndGlyphs];
    [self sizeToFit];
    [self scrollRangeToVisible:_selectionRange];
    [self setNeedsDisplay:YES];
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

        if (_isRichText)
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
    _stickyXLocation = _caretRect.origin.x;
}

- (void)_blinkCaret:(CPTimer)aTimer
{
    _drawCaret = !_drawCaret;
    [self setNeedsDisplayInRect:_caretRect];
}


#pragma mark -
#pragma mark Drawing methods

- (void)drawInsertionPointInRect:(CGRect)aRect color:(CPColor)aColor turnedOn:(BOOL)flag
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
        self._DOMElement.appendChild(_caretDOM);
    }

    _caretDOM.style.left = (aRect.origin.x) + "px";
    _caretDOM.style.top = (aRect.origin.y) + "px";
    _caretDOM.style.height = (aRect.size.height) + "px";
    _caretDOM.style.visibility = flag ? "visible" : "hidden";
#endif
}

- (void)drawRect:(CGRect)aRect
{
    var ctx = [[CPGraphicsContext currentContext] graphicsPort],
        range = [_layoutManager glyphRangeForBoundingRect:aRect inTextContainer:_textContainer];

    if (_selectionRange.length)
    {
        var rects = [_layoutManager rectArrayForCharacterRange:_selectionRange
                                    withinSelectedCharacterRange:_selectionRange
                                    inTextContainer:_textContainer
                                    rectCount:nil],
            effectiveSelectionColor = [self _isFocused] ? [_selectedTextAttributes objectForKey:CPBackgroundColorAttributeName] : [CPColor _selectedTextBackgroundColorUnfocussed],
            lenghtRect = rects.length;

        CGContextSaveGState(ctx);
        CGContextSetFillColor(ctx, effectiveSelectionColor);

        for (var i = 0; i < lenghtRect; i++)
        {
            rects[i].origin.x += _textContainerOrigin.x;
            rects[i].origin.y += _textContainerOrigin.y;

            CGContextFillRect(ctx, rects[i]);
        }

        CGContextRestoreGState(ctx);
    }

    if (range.length)
        [_layoutManager drawGlyphsForGlyphRange:range atPoint:_textContainerOrigin];

    if ([self shouldDrawInsertionPoint])
    {
        [self updateInsertionPointStateAndRestartTimer:NO];
        [self drawInsertionPointInRect:_caretRect color:_insertionPointColor turnedOn:_drawCaret];
    }
    else // <!> FIXME: breaks DOM abstraction, but i did get it working otherwise
    {
        if (_caretDOM)
            _caretDOM.style.visibility = "hidden";
    }
}


#pragma mark -
#pragma mark Select methods

- (void)selectAll:(id)sender
{
    if (_isSelectable)
    {
        if (_caretTimer)
        {
            [_caretTimer invalidate];
            _caretTimer = nil;
        }

        [self setSelectedRange:CPMakeRange(0, [_layoutManager numberOfCharacters])];
    }
}

- (void)setSelectedRange:(CPRange)range
{
    [self setSelectedRange:range affinity:0 stillSelecting:NO];
    [self setTypingAttributes:[_textStorage attributesAtIndex:MAX(0, range.location -1) effectiveRange:nil]];
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
        if (_isFirstResponder)
            [self updateInsertionPointStateAndRestartTimer:((_selectionRange.length === 0) && ![_caretTimer isValid])];

        [self setTypingAttributes:[_textStorage attributesAtIndex:MAX(0, range.location -1) effectiveRange:nil]];

        [[CPNotificationCenter defaultCenter] postNotificationName:CPTextViewDidChangeSelectionNotification object:self];
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
            var wordRange = [self _characterRangeForUnitAtIndex:proposedRange.location asDefinedByCharArray:[[self class] _wordBoundaryCharacterArray] skip:YES];

            if (proposedRange.length)
                wordRange = CPUnionRange(wordRange, [self _characterRangeForUnitAtIndex:CPMaxRange(proposedRange) asDefinedByCharArray:[[self class] _wordBoundaryCharacterArray] skip:NO]);

            return wordRange;

        case CPSelectByParagraph:
            var parRange = [self _characterRangeForUnitAtIndex:proposedRange.location asDefinedByCharArray:[[self class] _paragraphBoundaryCharacterArray] skip:NO];

            if (proposedRange.length)
                parRange = CPUnionRange(parRange, [self _characterRangeForUnitAtIndex:CPMaxRange(proposedRange) asDefinedByCharArray: [[self class] _paragraphBoundaryCharacterArray] skip:NO]);

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

    /* stop _caretTimer */
    [_caretTimer invalidate];
    _caretTimer = nil;
    [self _hideCaret];

    // convert to container coordinate
    point.x -= _textContainerOrigin.x;
    point.y -= _textContainerOrigin.y;

    _startTrackingLocation = [_layoutManager glyphIndexForPoint:point inTextContainer:_textContainer fractionOfDistanceThroughGlyph:fraction];

    if (_startTrackingLocation === CPNotFound)
        _startTrackingLocation = [_layoutManager numberOfCharacters];

    [self setSelectionGranularity:granularities[[event clickCount]]];

    var setRange = CPMakeRange(_startTrackingLocation, 0);

    if ([event modifierFlags] & CPShiftKeyMask)
    {
        setRange = _MakeRangeFromAbs(_startTrackingLocation < _MidRange(_selectionRange)?
                                     CPMaxRange(_selectionRange) : _selectionRange.location,
                                     _startTrackingLocation);
    }

    [self setSelectedRange:setRange affinity:0 stillSelecting:YES];
}

- (void)_clearRange:(CPRange)range
{
    var rects = [_layoutManager rectArrayForCharacterRange:nil withinSelectedCharacterRange:range
                                 inTextContainer:_textContainer
                                 rectCount:nil],
        l = rects.length;

    for (var i = 0; i < l ; i++)
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

    if (index == CPNotFound)
        index = _scrollingDownward ? CPMaxRange(oldRange) : oldRange.location;

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
}

- (void)moveDown:(id)sender
{
    if (!isSelectable)
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

    [self _establishSelection:CPMakeRange(dindex, 0) byExtending:NO];
    _stickyXLocation = oldStickyLoc;
    [self scrollRangeToVisible:CPMakeRange(dindex, 0)]

}

- (void)moveDownAndModifySelection:(id)sender
{
    if (!_isSelectable)
        return;

    var oldStartTrackingLocation = _startTrackingLocation;

    [self _performSelectionFixupForRange:CPMakeRange(_selectionRange.location < _startTrackingLocation ? _selectionRange.location : CPMaxRange(_selectionRange), 0)];
    [self moveDown:sender];
    _startTrackingLocation = oldStartTrackingLocation;
    [self _performSelectionFixupForRange:_MakeRangeFromAbs(_startTrackingLocation, (_selectionRange.location < _startTrackingLocation ? _selectionRange.location : CPMaxRange(_selectionRange)))];
}

- (void)moveUp:(id)sender
{
    if (!_isSelectable)
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

    var dindex= [_layoutManager glyphIndexForPoint:point inTextContainer:_textContainer fractionOfDistanceThroughGlyph:fraction],
        oldStickyLoc = _stickyXLocation;

    [self _establishSelection:CPMakeRange(dindex,0) byExtending:NO];
    _stickyXLocation = oldStickyLoc;
    [self scrollRangeToVisible:CPMakeRange(dindex, 0)];
}

- (void)moveUpAndModifySelection:(id)sender
{
    if (!_isSelectable)
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
                                           intoDirection:move granularity:granularity];
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
    if (_isSelectable)
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
    if (_isSelectable)
       [self _extendSelectionIntoDirection:1 granularity:CPSelectByCharacter];
}

- (void)moveLeft:(id)sender
{
    if (_isSelectable)
        [self _establishSelection:CPMakeRange(_selectionRange.location - 1, 0) byExtending:NO];
}

- (void)moveToEndOfParagraph:(id)sender
{
    if (_isSelectable)
       [self _moveSelectionIntoDirection:1 granularity:CPSelectByParagraph];
}

- (void)moveToEndOfParagraphAndModifySelection:(id)sender
{
    if (_isSelectable)
       [self _extendSelectionIntoDirection:1 granularity:CPSelectByParagraph];
}

- (void)moveParagraphForwardAndModifySelection:(id)sender
{
    if (_isSelectable)
       [self _extendSelectionIntoDirection:1 granularity:CPSelectByParagraph];
}

- (void)moveParagraphForward:(id)sender
{
    if (_isSelectable)
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
    if (_isSelectable)
         [self _establishSelection:CPMakeRange(0, 0) byExtending:NO];
}

- (void)moveToBeginningOfDocumentAndModifySelection:(id)sender
{
    if (_isSelectable)
         [self _establishSelection:CPMakeRange(0, 0) byExtending:YES];
}

- (void)moveToEndOfDocument:(id)sender
{
    if (_isSelectable)
         [self _establishSelection:CPMakeRange([_layoutManager numberOfCharacters], 0) byExtending:NO];
}

- (void)moveToEndOfDocumentAndModifySelection:(id)sender
{
    if (_isSelectable)
         [self _establishSelection:CPMakeRange([_layoutManager numberOfCharacters], 0) byExtending:YES];
}

- (void)moveWordRight:(id)sender
{
    if (_isSelectable)
        [self _moveSelectionIntoDirection:1 granularity:CPSelectByWord];
}

- (void)moveToBeginningOfParagraph:(id)sender
{
    if (_isSelectable)
        [self _moveSelectionIntoDirection:-1 granularity:CPSelectByParagraph];
}

- (void)moveToBeginningOfParagraphAndModifySelection:(id)sender
{
    if (_isSelectable)
       [self _extendSelectionIntoDirection:-1 granularity:CPSelectByParagraph];
}

- (void)moveParagraphBackward:(id)sender
{
    if (_isSelectable)
        [self _moveSelectionIntoDirection:-1 granularity:CPSelectByParagraph];
}

- (void)moveParagraphBackwardAndModifySelection:(id)sender
{
    if (_isSelectable)
       [self _extendSelectionIntoDirection:-1 granularity:CPSelectByParagraph];
}

- (void)moveWordRightAndModifySelection:(id)sender
{
    if (_isSelectable)
         [self _extendSelectionIntoDirection:+1 granularity:CPSelectByWord];
}

- (void)deleteToEndOfParagraph:(id)sender
{
    if (!_isSelectable || !_isEditable)
        return;

    [self moveToEndOfParagraphAndModifySelection:self];
    [self delete:self];
}

- (void)deleteToBeginningOfParagraph:(id)sender
{
    if (!_isSelectable || !_isEditable)
        return;

    [self moveToBeginningOfParagraphAndModifySelection:self];
    [self delete:self];
}

- (void)deleteToBeginningOfLine:(id)sender
{
    if (!_isSelectable || !_isEditable)
        return;

    [self moveToLeftEndOfLineAndModifySelection:self];
    [self delete:self];
}

- (void)deleteToEndOfLine:(id)sender
{
    if (!_isSelectable || !_isEditable)
        return;

    [self moveToRightEndOfLineAndModifySelection:self];
    [self delete:self];
}

- (void)deleteWordBackward:(id)sender
{
    if (!_isSelectable || !_isEditable)
        return;

    [self moveWordLeftAndModifySelection:self];
    [self delete:self];
}

- (void)deleteWordForward:(id)sender
{
    if (!_isSelectable || !_isEditable)
        return;

    [self moveWordRightAndModifySelection:self];
    [self delete:self];
}

- (void)moveToLeftEndOfLine:(id)sender byExtending:(BOOL)flag
{
    if (!_isSelectable)
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
    if (!_isSelectable)
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
    if (_isSelectable)
        [self _extendSelectionIntoDirection:-1 granularity:CPSelectByWord];
}

- (void)moveWordLeft:(id)sender
{
    if (_isSelectable)
        [self _moveSelectionIntoDirection:-1 granularity:CPSelectByWord]
}

- (void)moveRight:(id)sender
{
    if (_isSelectable)
        [self _establishSelection:CPMakeRange(CPMaxRange(_selectionRange) + 1, 0) byExtending:NO];
}

- (void)_deleteForRange:(CPRange)changedRange
{
    if (![self shouldChangeTextInRange:changedRange replacementString:@""])
        return;

    [[[[self window] undoManager] prepareWithInvocationTarget:self] _replaceCharactersInRange:CPMakeRange(_selectionRange.location, 0) withAttributedString:[_textStorage attributedSubstringFromRange:CPMakeRangeCopy(changedRange)]];
    [_textStorage deleteCharactersInRange:CPMakeRangeCopy(changedRange)];

    [self setSelectedRange:CPMakeRange(changedRange.location, 0)];
    [self didChangeText];
    [_layoutManager _validateLayoutAndGlyphs];
    [self sizeToFit];
    _stickyXLocation = _caretRect.origin.x;
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
        changedRange.length++;

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

    [[CPNotificationCenter defaultCenter] postNotificationName:CPTextViewDidChangeTypingAttributesNotification object:self];
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
    if (!_isRichText)
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

    if (_isRichText)
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
    if (!_isRichText)  // FIXME
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
        rect = [_layoutManager boundingRectForGlyphRange:CPMakeRange(0, MAX(0, [_layoutManager numberOfCharacters] - 1)) inTextContainer:_textContainer];

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
            characterSet = [[self class] _wordBoundaryCharacterArray];
            break;

        case CPSelectByParagraph:
            characterSet = [[self class] _paragraphBoundaryCharacterArray];
            break;
    }

    // FIXME if (!characterSet) croak!
    return characterSet.join("").indexOf([self string].charAt(index)) !== CPNotFound;
}

- (CPRange)_characterRangeForUnitAtIndex:(unsigned)index asDefinedByCharArray:(CPArray)characterSet skip:(BOOL)flag
{
    var wordRange = CPMakeRange(0, 0),
        lastIndex = CPNotFound,
        setString = characterSet.join(""),
        string = [_textStorage string],
        searchIndex;

    // do we start on a boundary character?
    if (flag && string.charAt(index) && setString.indexOf(string.charAt(index)) !== CPNotFound)
    {
        // -> extend to the left
        wordRange = CPMakeRange(index, 1);

        while (setString.indexOf(string.charAt(--index)) !== CPNotFound && index > -1)
        {
             wordRange = CPMakeRange(index, 1);
        }
        // -> extend to the right
        for (index = wordRange.location; setString.indexOf(string.charAt(++index)) !== CPNotFound && index < string.length;)
        {
             wordRange = _MakeRangeFromAbs(wordRange.location, MIN(MAX(0, string.length - 1), index + 1));
        }

        return wordRange;
    }

    for (searchIndex = 0; searchIndex < characterSet.length; searchIndex++)
    {
        var peek = string.lastIndexOf(characterSet[searchIndex], index);

        if (peek !== CPNotFound)
        {
            if (lastIndex === CPNotFound)
                lastIndex = peek;
            else
                lastIndex = MAX(lastIndex, peek);
        }
    }

    if (lastIndex !== CPNotFound)
        wordRange.location = lastIndex + 1;

    lastIndex = CPNotFound;

    for (searchIndex = 0 ; searchIndex < characterSet.length; searchIndex++)
    {
        var peek = string.indexOf(characterSet[searchIndex], index);

        if (peek !== CPNotFound)
        {
            if (lastIndex === CPNotFound)
                lastIndex = peek;
            else
                lastIndex = MIN(lastIndex, peek);
        }

    }

    if (lastIndex != CPNotFound)
        wordRange.length = lastIndex - wordRange.location;
    else
        wordRange.length = string.length - wordRange.location;

    return wordRange;
}

- (BOOL)shouldDrawInsertionPoint
{
    return (_selectionRange.length === 0 && [self _isFocused]);
}

- (void)_hideCaret
{
#if PLATFORM(DOM)
    if (_caretDOM)
        _caretDOM.style.visibility = "hidden";
#endif
}

- (void)updateInsertionPointStateAndRestartTimer:(BOOL)flag
{
    if (_selectionRange.length)
        [self _hideCaret];

    if (_selectionRange.location >= [_layoutManager numberOfCharacters])    // cursor is "behind" the last chacacter
    {
        _caretRect = [_layoutManager boundingRectForGlyphRange:CPMakeRange(MAX(0,_selectionRange.location - 1), 1) inTextContainer:_textContainer];
        _caretRect.origin.x += _caretRect.size.width;

        if (_selectionRange.location > 0 && [[_textStorage string] characterAtIndex:_selectionRange.location - 1] === '\n')
        {
            _caretRect.origin.y += _caretRect.size.height;
            _caretRect.origin.x = 0;
        }
    }
    else
    {
        _caretRect = [_layoutManager boundingRectForGlyphRange:CPMakeRange(_selectionRange.location, 1) inTextContainer:_textContainer];
    }

    _caretRect.origin.x += _textContainerOrigin.x;
    _caretRect.origin.y += _textContainerOrigin.y;
    _caretRect.size.width = 1;

    if (flag)
    {
        _drawCaret = flag;
        _caretTimer = [CPTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_blinkCaret:) userInfo:nil repeats:YES];
    }
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
