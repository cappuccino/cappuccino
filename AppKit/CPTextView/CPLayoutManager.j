/*
 *  CPLayoutManager.j
 *  AppKit
 *
 *  FIXME remove from DOM when scrolled out of visible area? (as done in CPTableView)
 *
 *
 *  Created by Daniel Boehringer on 27/12/2013.
 *  All modifications copyright Daniel Boehringer 2013.
 *  Based on original work by
 *  Emmanuel Maillard on 27/02/2010.
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
@import "CPTextContainer.j"
@import "CGContext.j"
@import "CPTypesetter.j"

@global _MakeRangeFromAbs

function _isNewlineCharacter(chr)
{
    return (chr === '\n' || chr === '\r');
}

function _RectEqualToRectHorizontally(lhsRect, rhsRect)
{
    return (lhsRect.origin.x == rhsRect.origin.x &&
            lhsRect.size.width == rhsRect.size.width &&
            lhsRect.size.height == rhsRect.size.height);
}

_oncontextmenuhandler = function () { return false; };

@implementation CPArray (SortedSearching)

- (unsigned)_indexOfObject:(id)anObject sortedByFunction:(Function)aFunction context:(id)aContext
{
    var length= [self count];

    if (!aFunction)
        return CPNotFound;

    if (length === 0)
        return -1;

    var mid,
        c,
        first = 0,
        last = length - 1;

    while (first <= last)
    {
        mid = FLOOR((first + last) / 2);
        c = aFunction(anObject, self[mid], aContext);

        if (c > 0)
        {
            first = mid + 1;
        }
        else if (c < 0)
        {
            last = mid - 1;
        }
        else
        {
            while (mid < length - 1 && aFunction(anObject, self[mid + 1], aContext) == CPOrderedSame)
                mid++;

            return mid;
        }
    }

    var result = -first - 1;

    return result >= 0 ? result : CPNotFound;
}

@end

var _sortRange = function(location, anObject)
{
    if (CPLocationInRange(location, anObject._range))
        return CPOrderedSame;
    else if (CPMaxRange(anObject._range) <= location)
        return CPOrderedDescending;
    else
        return CPOrderedAscending;
}

var _objectWithLocationInRange = function(aList, aLocation)
{
    var index = [aList _indexOfObject: aLocation sortedByFunction:_sortRange context:nil];

    if (index != CPNotFound)
        return aList[index];

    return nil;
}

var _objectsInRange = function(aList, aRange)
{
    var list = [],
        c = aList.length,
        location = aRange.location;

    for (var i = 0; i < c; i++)
    {
        if (CPLocationInRange(location, aList[i]._range))
        {
            list.push(aList[i]);

            if (CPMaxRange(aList[i]._range) <= CPMaxRange(aRange))
                location = CPMaxRange(aList[i]._range);
            else
                break;
        }
        else if (CPLocationInRange(CPMaxRange(aRange), aList[i]._range))
        {
            list.push(aList[i]);
            break;
        }
        else if (CPRangeInRange(aRange, aList[i]._range))
        {
            list.push(aList[i]);
        }
    }

    return list;
}

@implementation _CPLineFragment : CPObject
{
    CPArray         _glyphsFrames @accessors(getter=glyphFrames);

    BOOL            _isInvalid;
    CGRect          _fragmentRect;
    CGRect          _usedRect;
    CGPoint         _location;
    CPRange         _range;
    CPTextContainer _textContainer;
    CPMutableArray  _runs;
}

#pragma mark -
#pragma mark Init methods

- (id)createDOMElementWithText:(CPString)aString andFont:(CPFont)aFont andColor:(CPColor)aColor
{
#if PLATFORM(DOM)
    var style,
        span = document.createElement("span");

    span.oncontextmenu = span.onmousedown = span.onselectstart = _oncontextmenuhandler;
    // span.contentEditable = true;   // this unfortunately does not work to make native pasting work on safari

    style = span.style;
    style.position = "absolute";
    style.visibility = "visible";
    style.padding = "0px";
    style.margin = "0px";
    style.whiteSpace = "pre";
    style.backgroundColor = "transparent";
    style.font = [aFont cssString];

    if (aColor)
        style.color = [aColor cssString];

    if (CPFeatureIsCompatible(CPJavaScriptInnerTextFeature))
        span.innerText = aString;
    else if (CPFeatureIsCompatible(CPJavaScriptTextContentFeature))
        span.textContent = aString;

    //<!> FIXME aString.replace(/&/g,'&amp;')
    return span;
#else
    return nil;
#endif
}

- (id)initWithRange:(CPRange)aRange textContainer:(CPTextContainer)aContainer textStorage:(CPTextStorage)textStorage
{
    if (self = [super init])
    {
        var effectiveRange = CPMakeRange(0,0),
            location;

        _fragmentRect = CGRectMakeZero();
        _usedRect = CGRectMakeZero();
        _location = CGPointMakeZero();
        _range = CPMakeRangeCopy(aRange);
        _textContainer = aContainer;
        _isInvalid = NO;
        _runs = [[CPMutableArray alloc] init];

        for (location = aRange.location; location < CPMaxRange(aRange); location = CPMaxRange(effectiveRange))
        {
            var attributes = [textStorage attributesAtIndex:location effectiveRange:effectiveRange];

            effectiveRange = attributes ? CPIntersectionRange(aRange, effectiveRange) : aRange;

            var string = [textStorage._string substringWithRange:effectiveRange],
                font = [textStorage font] || [CPFont systemFontOfSize:12.0];

            if ([attributes containsKey:CPFontAttributeName])
                 font = [attributes objectForKey:CPFontAttributeName];

            var color = [attributes objectForKey:CPForegroundColorAttributeName],
                elem = [self createDOMElementWithText:string andFont:font andColor:color],
                run = {_range:CPMakeRangeCopy(effectiveRange), elem:elem, string:string};

            _runs.push(run);
        }
    }

    return self;
}

- (void)setAdvancements:(CPArray)someAdvancements
{
    var count = someAdvancements.length,
        origin = CGPointMake(_fragmentRect.origin.x + _location.x, _fragmentRect.origin.y);

    _glyphsFrames = new Array(count);

    for (var i = 0; i < count; i++)
    {
        _glyphsFrames[i] = CGRectMake(origin.x, origin.y, someAdvancements[i], _usedRect.size.height);
        origin.x += someAdvancements[i];
    }
}

- (CPString)description
{
    return [super description] +
        "\n\t_fragmentRect="+CPStringFromRect(_fragmentRect) +
        "\n\t_usedRect="+CPStringFromRect(_usedRect) +
        "\n\t_location="+CPStringFromPoint(_location) +
        "\n\t_range="+CPStringFromRange(_range);
}

- (void)drawUnderlineForGlyphRange:(CPRange)glyphRange
                     underlineType:(int)underlineVal
                    baselineOffset:(float)baselineOffset
                   containerOrigin:(CGPoint)containerOrigin
{
// <!> FIXME
}

- (void)invalidate
{
    _isInvalid = YES;
}

- (void)_deinvalidate
{
    _isInvalid = NO;
}

- (void)_removeFromDOM
{
    var l = _runs.length;

    for (var i = 0; i < l; i++)
    {
        if (_runs[i].elem && _runs[i].DOMactive)
            _textContainer._textView._DOMElement.removeChild(_runs[i].elem);

        _runs[i].elem = nil;
        _runs[i].DOMactive = NO;
    }
}

- (void)drawInContext:(CGContext)context atPoint:(CGPoint)aPoint forRange:(CPRange)aRange
{
    var runs = _objectsInRange(_runs, aRange),
        c = runs.length,
        orig = CGPointMake(_fragmentRect.origin.x, _fragmentRect.origin.y);

    orig.y += aPoint.y;

    for (var i = 0; i < c; i++)
    {
        var run = runs[i];

        if (run.DOMactive && !run.DOMpatched || !run.elem)
            continue;

        orig.x = _glyphsFrames[run._range.location - _runs[0]._range.location].origin.x + aPoint.x;

        run.elem.style.left = (orig.x) + "px";
        run.elem.style.top = (orig.y) + "px";

        if (!run.DOMactive)
            _textContainer._textView._DOMElement.appendChild(run.elem);

        run.DOMactive = YES;
        run.DOMpatched = NO;

        if (run.underline)
        {
            // <!> FIXME
        }
    }
}

- (void)backgroundColorForGlyphAtIndex:(unsigned)index
{
    var run = _objectWithLocationInRange(_runs, index);

    if (run)
        return run.backgroundColor;

    return [CPColor clearColor];
}

- (BOOL)isVisuallyIdenticalToFragment:(_CPLineFragment)newLineFragment
{
    var newFragmentRuns= newLineFragment._runs,
        oldFragmentRuns= _runs;

    if (!oldFragmentRuns || !newFragmentRuns || oldFragmentRuns.length !== newFragmentRuns.length)
        return NO;

    var l = oldFragmentRuns.length;

    for (var i = 0; i < l; i++)
    {
        // FIXME <!>  newFragmentRuns[i].elem.style.left !== oldFragmentRuns[i].elem.style.left && compare CSS-strings
        if (newFragmentRuns[i].string !== oldFragmentRuns[i].string ||
            !_RectEqualToRectHorizontally(newLineFragment._fragmentRect, _fragmentRect))
        {
            return NO;
        }
    }

    return YES;
}

- (void)_relocateVerticallyByY:(double)verticalOffset rangeOffset:(unsigned)rangeOffset
{
    var l = _runs.length;

    _range.location += rangeOffset;

    for (var i = 0; i < l; i++)
    {
        _runs[i]._range.location += rangeOffset;

        if (verticalOffset)
        {
            _runs[i].elem.top = (_runs[i].elem.top + verticalOffset) + 'px';
            _runs[i].DOMpatched = YES;
        }
    }

    if (!verticalOffset)
        return NO;

    _fragmentRect.origin.y += verticalOffset;
    _usedRect.origin.y += verticalOffset;

    var l = _glyphsFrames.length;

    for (var i = 0; i < l ; i++)
    {
        _glyphsFrames[i].origin.y += verticalOffset;
    }
}

@end

@implementation _CPTemporaryAttributes : CPObject
{
    CPDictionary _attributes;
    CPRange      _range;
}

- (id)initWithRange:(CPRange)aRange attributes:(CPDictionary)attributes
{
    if (self = [super init])
    {
        _attributes = attributes;
        _range = CPMakeRangeCopy(aRange);
    }

    return self;
}

- (CPString)description
{
    return [super description] +
        "\n\t_range="+CPStringFromRange(_range) +
        "\n\t_attributes="+[_attributes description];
}

@end

/*!
    @ingroup appkit
    @class CPLayoutManager
*/
@implementation CPLayoutManager : CPObject
{
    Class           _lineFragmentFactory    @accessors(setter=setLineFragmentFactory:);
    CPMutableArray  _textContainers         @accessors(getter=textContainers);
    CPTextStorage   _textStorage            @accessors(property=textStorage);
    CPTypesetter    _typesetter             @accessors(property=typesetter);

    CPMutableArray  _lineFragments;
    CPMutableArray  _lineFragmentsForRescue;
    id              _extraLineFragment;

    CPMutableArray  _temporaryAttributes;

    BOOL            _isValidatingLayoutAndGlyphs;
    CPRange         _removeInvalidLineFragmentsRange;
}


#pragma mark -
#pragma mark Init methods

- (id)init
{
    if (self = [super init])
    {
        _textContainers                 = [[CPMutableArray alloc] init];
        _lineFragments                  = [[CPMutableArray alloc] init];
        _typesetter                     = [CPTypesetter sharedSystemTypesetter];
        _isValidatingLayoutAndGlyphs    = NO;
        _lineFragmentFactory            = [_CPLineFragment class];
    }

    return self;
}


#pragma mark -
#pragma mark Text containes method

- (void)insertTextContainer:(CPTextContainer)aContainer atIndex:(int)index
{
    [_textContainers insertObject:aContainer atIndex:index];
    [aContainer setLayoutManager:self];
}

- (void)addTextContainer:(CPTextContainer)aContainer
{
    [_textContainers addObject:aContainer];
    [aContainer setLayoutManager:self];
}

- (void)removeTextContainerAtIndex:(int)index
{
    var container = [_textContainers objectAtIndex:index];
    [container setLayoutManager:nil];
    [_textContainers removeObjectAtIndex:index];
}

// <!> fixme
- (int)numberOfGlyphs
{
    return [_textStorage length];
}
- (int)numberOfCharacters
{
    return [_textStorage length];
}

- (CPTextView)firstTextView
{
    return [_textContainers[0] textView];
}

// from cocoa (?)
- (CPTextView)textViewForBeginningOfSelection
{
   return [[_textContainers objectAtIndex:0] textView];
}

- (BOOL)layoutManagerOwnsFirstResponderInWindow:(CPWindow)aWindow
{
    var firstResponder = [aWindow firstResponder],
        c = [_textContainers count];

    for (var i = 0; i < c; i++)
    {
        if ([_textContainers[i] textView] === firstResponder)
            return YES;
    }

    return NO;
}

- (CGRect)boundingRectForGlyphRange:(CGRange)aRange inTextContainer:(CPTextContainer)container
{
    if (![self numberOfGlyphs])
        return CGRectMake(0, 0, 1, 12);    // crude hack to give a cursor in an empty doc.

    if (CPMaxRange(aRange) >= [self numberOfGlyphs])
        aRange = CPMakeRange([self numberOfGlyphs] - 1, 1);

    var fragments = _objectsInRange(_lineFragments, aRange),
        rect = nil,
        c = [fragments count];

    for (var i = 0; i < c; i++)
    {
        var fragment = fragments[i];

        if (fragment._textContainer === container)
        {
            var frames = [fragment glyphFrames],
                l = frames.length;

            for (var j = 0; j < l; j++)
            {
                if (CPLocationInRange(fragment._range.location + j, aRange))
                {
                    if (!rect)
                        rect = CGRectCreateCopy(frames[j]);
                    else
                        rect = CGRectUnion(rect, frames[j]);
                }
            }
        }
    }

    return rect ? rect : CGRectMakeZero();
}

- (CPRange)glyphRangeForTextContainer:(CPTextContainer)aTextContainer
{
    var range = nil,
        c = [_lineFragments count];

    for (var i = 0; i < c; i++)
    {
        var fragment = _lineFragments[i];

        if (fragment._textContainer === aTextContainer)
        {
            if (!range)
                range = CPMakeRangeCopy(fragment._range);
            else
                range = CPUnionRange(range, fragment._range);
        }
    }

    return range ? range : CPMakeRange(CPNotFound, 0);
}

- (void)_removeInvalidLineFragments
{
    _lineFragmentsForRescue = [_lineFragments copy];
    [_lineFragmentsForRescue makeObjectsPerformSelector:@selector(_deinvalidate)];

    if (_removeInvalidLineFragmentsRange && _removeInvalidLineFragmentsRange.length && _lineFragments.length)
    {
        // [[_lineFragments subarrayWithRange:_removeInvalidLineFragmentsRange] makeObjectsPerformSelector:@selector(invalidate)];
        [_lineFragments removeObjectsInRange:_removeInvalidLineFragmentsRange];
        [[_lineFragmentsForRescue subarrayWithRange:_removeInvalidLineFragmentsRange] makeObjectsPerformSelector:@selector(invalidate)];
    }

}

- (void)_cleanUpDOM
{
    var l = _lineFragmentsForRescue? _lineFragmentsForRescue.length : 0;

    for (var i = 0; i < l; i++)
    {
        if (_lineFragmentsForRescue[i]._isInvalid)
            [_lineFragmentsForRescue[i] _removeFromDOM];
    }
}

- (void)_validateLayoutAndGlyphs
{
    if (_isValidatingLayoutAndGlyphs)
        return;

    _isValidatingLayoutAndGlyphs = YES;

    var startIndex = CPNotFound,
        removeRange = CPMakeRange(0, 0),
        l = _lineFragments.length;

    if (l)
    {
        for (var i = 0; i < l; i++)
        {
            if (_lineFragments[i]._isInvalid)
            {
                startIndex = _lineFragments[i]._range.location;
                removeRange.location = i;
                removeRange.length = l - i;
                break;
            }
        }

        // start one line above current line to make sure that a word can jump up
        if (startIndex == CPNotFound && CPMaxRange (_lineFragments[l - 1]._range) < [_textStorage length])
            startIndex =  CPMaxRange(_lineFragments[l - 1]._range);
    }
    else
    {
        startIndex = 0;
    }

    /* nothing to validate and layout */
    if (startIndex == CPNotFound)
    {
        _isValidatingLayoutAndGlyphs = NO;
        return;
    }

    if (removeRange.length)
        _removeInvalidLineFragmentsRange = CPMakeRangeCopy(removeRange);

    // We erased all lines
    if (!startIndex)
        [self setExtraLineFragmentRect:CGRectMake(0, 0) usedRect:CGRectMake(0, 0) textContainer:nil];

    // document.title=startIndex;
    [_typesetter layoutGlyphsInLayoutManager:self startingAtGlyphIndex:startIndex maxNumberOfLineFragments:-1 nextGlyphIndex:nil];
    [self _cleanUpDOM];
    _isValidatingLayoutAndGlyphs = NO;
}

- (BOOL)_rescuingInvalidFragmentsWasPossibleForGlyphRange:(CPRange)aRange
{
    var l = _lineFragments.length,
        location = aRange.location,
        found = NO,
        targetLine = 0;

   // try to find the first linefragment of the desired range
    for (; targetLine < l; targetLine++)
    {
        if (CPLocationInRange(location, _lineFragments[targetLine]._range))
        {
            found = YES;
            break;
        }
    }

    if (!found)
        return NO;

    if (!_lineFragmentsForRescue[targetLine])
        return NO;

    var startLineForDOMRemoval = targetLine,
        isIdentical = YES,
        newLineFragment= _lineFragments[targetLine],
        oldLineFragment = _lineFragmentsForRescue[targetLine],
        oldLength = CPMaxRange([_lineFragmentsForRescue lastObject]._range),
        newLength = [[_textStorage string].length],
        removalSkip = 1;

  //  if (ABS(newLength - oldLength) > 1)
  //      return NO;

    if (![oldLineFragment isVisuallyIdenticalToFragment:newLineFragment])
    {
        isIdentical = NO;

        // deleting newline in its own line-> move up instead of re.layouting
        if (newLength < oldLength && oldLineFragment._range.length == 1 && newLineFragment._range.length > 1 && newLineFragment._range.location === oldLineFragment._range.location)
        {
            isIdentical = YES;
            targetLine--;
            removalSkip++;
        }

        // newline entered in its own line-> move down instead of re.layouting
        if (newLength > oldLength && newLineFragment._range.length == 1 && oldLineFragment._range.length > 1 && newLineFragment._range.location === oldLineFragment._range.location)
        {
            isIdentical = YES;
            startLineForDOMRemoval--;
        }
    }

    // patch the linefragments instead of re-layoutung
    if (isIdentical)
    {
        var rangeOffset = CPMaxRange(_lineFragments[targetLine]._range) - CPMaxRange(_lineFragmentsForRescue[startLineForDOMRemoval]._range);

        if (ABS(rangeOffset) !== ABS(newLength - oldLength))
            return NO;

        var verticalOffset = _lineFragments[targetLine]._fragmentRect.origin.y - _lineFragmentsForRescue[startLineForDOMRemoval]._fragmentRect.origin.y,
            l = _lineFragmentsForRescue.length,
            newTargetLine = startLineForDOMRemoval + removalSkip;

        for (; newTargetLine < l; newTargetLine++)
        {
            _lineFragmentsForRescue[newTargetLine]._isInvalid = NO;    // protect them from final removal
            [_lineFragmentsForRescue[newTargetLine] _relocateVerticallyByY:verticalOffset rangeOffset:rangeOffset];
            _lineFragments.push(_lineFragmentsForRescue[newTargetLine]);
        }
    }

    return isIdentical;
}

- (void)invalidateDisplayForGlyphRange:(CPRange)range
{
    var lineFragments = _objectsInRange(_lineFragments, range);

    for (var i = 0; i < lineFragments.length; i++)
        [[lineFragments[i]._textContainer textView] setNeedsDisplayInRect:lineFragments[i]._fragmentRect];
}

- (void)invalidateLayoutForCharacterRange:(CPRange)aRange isSoft:(BOOL)flag actualCharacterRange:(CPRangePointer)actualCharRange
{
    var firstFragmentIndex = _lineFragments.length ? [_lineFragments _indexOfObject: aRange.location sortedByFunction:_sortRange context:nil] : CPNotFound;

    if (firstFragmentIndex == CPNotFound)
    {
        if (_lineFragments.length)
        {
            firstFragmentIndex = _lineFragments.length - 1;
        }
        else
        {
            if (actualCharRange)
            {
                actualCharRange.length = aRange.length;
                actualCharRange.location = 0;
            }

            return;
        }
    }
    else
    {
        firstFragmentIndex = firstFragmentIndex + (firstFragmentIndex ? -1 : 0);
    }

    var fragment = _lineFragments[firstFragmentIndex],
        range = CPMakeRangeCopy(fragment._range);

    fragment._isInvalid = YES;

    /* invalidated all fragments that follow */
    for (var i = firstFragmentIndex + 1; i < _lineFragments.length; i++)
    {
        _lineFragments[i]._isInvalid = YES;
        range = CPUnionRange(range, _lineFragments[i]._range);
    }

    if (CPMaxRange(range) < CPMaxRange(aRange))
        range = CPUnionRange(range, aRange);

    if (actualCharRange)
    {
        actualCharRange.length = range.length;
        actualCharRange.location = range.location;
    }
}

- (void)textStorage:(CPTextStorage)textStorage edited:(unsigned)mask range:(CPRange)charRange changeInLength:(int)delta invalidatedRange:(CPRange)invalidatedRange
{
    var actualRange = CPMakeRange(CPNotFound,0);
    [self invalidateLayoutForCharacterRange: invalidatedRange isSoft:NO actualCharacterRange:actualRange];
    [self invalidateDisplayForGlyphRange: actualRange];
}

- (CPRange)glyphRangeForBoundingRect:(CGRect)aRect inTextContainer:(CPTextContainer)container
{
    var c = [_lineFragments count],
        range;

    for (var i = 0; i < c; i++)
    {
        var fragment = _lineFragments[i];

        if (fragment._textContainer === container)
        {
            if (CGRectContainsRect(aRect, fragment._fragmentRect))
            {
                if (!range)
                    range = CPMakeRangeCopy(fragment._range);
                else
                    range = CPUnionRange(range, fragment._range);
            }
            else
            {
                var glyphRange = CPMakeRange(CPNotFound, 0),
                    frames = [fragment glyphFrames];

                for (var j = 0; j < frames.length; j++)
                {
                    if (CGRectIntersectsRect(aRect, frames[j]))
                    {
                        if (glyphRange.location == CPNotFound)
                            glyphRange.location = fragment._range.location + j;
                        else
                            glyphRange.length++;
                    }
                }
                if (glyphRange.location != CPNotFound)
                {
                    if (!range)
                        range = CPMakeRangeCopy(glyphRange);
                    else
                        range = CPUnionRange(range, glyphRange);
                }
            }
        }
    }

    return range ? range : CPMakeRange(0,0);
}

- (void)drawBackgroundForGlyphRange:(CPRange)aRange atPoint:(CGPoint)aPoint
{

}

- (void)drawUnderlineForGlyphRange:(CPRange)glyphRange
                    underlineType:(int)underlineVal
                    baselineOffset:(float)baselineOffset
                    lineFragmentRect:(CGRect)lineFragmentRect
                    lineFragmentGlyphRange:(CPRange)lineGlyphRange
                    containerOrigin:(CGPoint)containerOrigin
{
// FIXME
}

- (void)drawGlyphsForGlyphRange:(CPRange)aRange atPoint:(CGPoint)aPoint
{
    var lineFragments = _objectsInRange(_lineFragments, aRange);

    if (!lineFragments.length)
        return;

    var paintedRange = CPMakeRangeCopy(aRange),
        l = lineFragments.length,
        lineFragmentIndex,
        ctx;

    for (lineFragmentIndex = 0; lineFragmentIndex < l; lineFragmentIndex++)
    {
        var currentFragment = lineFragments[lineFragmentIndex];
        [currentFragment drawInContext:ctx atPoint:aPoint forRange:paintedRange];
    }
}

- (unsigned)glyphIndexForPoint:(CGPoint)point inTextContainer:(CPTextContainer)container fractionOfDistanceThroughGlyph:(FloatArray)partialFraction
{
    var c = [_lineFragments count];

    for (var i = 0; i < c; i++)
    {
        var fragment = _lineFragments[i];

        if (fragment._textContainer === container)
        {
            var frames = [fragment glyphFrames],
                len = fragment._range.length;

            for (var j = 0; j < len; j++)
            {
                if (CGRectContainsPoint(frames[j], point))
                {
                    if (partialFraction)
                        partialFraction[0] = (point.x - frames[j].origin.x) / frames[j].size.width;

                    return fragment._range.location + j;
                }
            }
        }
    }

    // Not found, maybe a point left to the last character was clicked -> search again with broader constraints
    if ([[_textStorage string] length])
    {
        for (var i = 0; i < c; i++)
        {
            var fragment = _lineFragments[i];

            if (fragment._textContainer === container)
            {
                    // Within the horizontal territory of the current (not-empty) line?
                    if (fragment._range.length > 0 && point.y > fragment._fragmentRect.origin.y &&
                        point.y <= fragment._fragmentRect.origin.y + fragment._fragmentRect.size.height)
                    {
                        var nlLoc = CPMaxRange(fragment._range) - 1,
                            lastFrame = [fragment glyphFrames][fragment._range.length - 1],
                            firstFrame = [fragment glyphFrames][0];

                        // Skip tabs and move on the last fragment in this line
                        if (i < c - 1 && _lineFragments[i + 1]._fragmentRect.origin.y === fragment._fragmentRect.origin.y)
                           continue;

                        // Clicked right to the last character
                        if (point.x > CGRectGetMaxX(lastFrame) + 10)
                        {
                            // This allows clicking before and after empty lines (return characters)
                            if (_isNewlineCharacter([[_textStorage string] characterAtIndex: nlLoc]))
                            {
                                return nlLoc + 1;
                            }
                        }
                        // Clicked left to the last character
                        else if (point.x <= CGRectGetMinX(firstFrame))
                            return fragment._range.location;
                        else
                            return nlLoc;
                }
            }
        }
    }

    return CPNotFound;
}

- (unsigned)glyphIndexForPoint:(CGPoint)point inTextContainer:(CPTextContainer)container
{
    return [self glyphIndexForPoint:point inTextContainer:container fractionOfDistanceThroughGlyph:nil];
}

- (void)_setAttributes:(CPDictionary)attributes toTemporaryAttributes:(_CPTemporaryAttributes)tempAttributes
{
    tempAttributes._attributes = attributes;
}

- (void)_addAttributes:(CPDictionary)attributes toTemporaryAttributes:(_CPTemporaryAttributes)tempAttributes
{
    [tempAttributes._attributes addEntriesFromDictionary:attributes];
}

- (void)_handleTemporaryAttributes:(CPDictionary)attributes forCharacterRange:(CPRange)charRange withSelector:(SEL)attributesOperation
{
    // FIXME
}

- (void)setTemporaryAttributes:(CPDictionary)attributes forCharacterRange:(CPRange)charRange
{
    [self _handleTemporaryAttributes:attributes forCharacterRange:charRange withSelector:@selector(_setAttributes:toTemporaryAttributes:)];
}

- (void)addTemporaryAttributes:(CPDictionary)attributes forCharacterRange:(CPRange)charRange
{
    [self _handleTemporaryAttributes:attributes forCharacterRange:charRange withSelector:@selector(_addAttributes:toTemporaryAttributes:)];
}

- (void)removeTemporaryAttribute:(CPString)attributeName forCharacterRange:(CPRange)charRange
{
    // FIXME
}

- (CPDictionary)temporaryAttributesAtCharacterIndex:(unsigned)index effectiveRange:(CPRangePointer)effectiveRange
{
    // FIXME
}

- (void)textContainerChangedTextView:(CPTextContainer)aContainer
{
    // FIXME
}

- (void)setTextContainer:(CPTextContainer)aTextContainer forGlyphRange:(CPRange)glyphRange
{
    var fragments = _objectsInRange(_lineFragments, glyphRange),
        l = fragments.length;

    for (var i = 0; i < l; i++)
    {
        [fragments[i] invalidate];
    }

    var lineFragment = [[_lineFragmentFactory alloc] initWithRange:glyphRange textContainer:aTextContainer textStorage:_textStorage];

    _lineFragments.push(lineFragment);
}

- (id)_lineFragmentForLocation:(unsigned) aLoc
{
    var fragments = _objectsInRange(_lineFragments, CPMakeRange(aLoc, 0)),
        l = fragments.length;

    if (l > 0)
        return fragments[0];

    return nil;
}

- (void)setLineFragmentRect:(CGRect)fragmentRect forGlyphRange:(CPRange)glyphRange usedRect:(CGRect)usedRect
{
    var lineFragment = _objectWithLocationInRange(_lineFragments, glyphRange.location);

    if (lineFragment)
    {
        lineFragment._fragmentRect = CGRectCreateCopy(fragmentRect);
        lineFragment._usedRect = CGRectCreateCopy(usedRect);
    }
}

- (void)_setAdvancements:(CPArray)someAdvancements forGlyphRange:(CPRange)glyphRange
{
    var lineFragment = _objectWithLocationInRange(_lineFragments, glyphRange.location);

    if (lineFragment)
        [lineFragment setAdvancements: someAdvancements];
}

- (void)setLocation:(CGPoint)aPoint forStartOfGlyphRange:(CPRange)glyphRange
{
    var lineFragment = _objectWithLocationInRange(_lineFragments, glyphRange.location);

    if (lineFragment)
        lineFragment._location = CGPointCreateCopy(aPoint);
}

- (CGRect)extraLineFragmentRect
{
    if (_extraLineFragment)
        return CGRectCreateCopy(_extraLineFragment._fragmentRect);

    return CGRectMakeZero();
}

- (CPTextContainer)extraLineFragmentTextContainer
{
    if (_extraLineFragment)
        return _extraLineFragment._textContainer;

    return nil;
}

- (CGRect)extraLineFragmentUsedRect
{
    if (_extraLineFragment)
        return CGRectCreateCopy(_extraLineFragment._usedRect);

    return CGRectMakeZero();
}

- (void)setExtraLineFragmentRect:(CGRect)rect usedRect:(CGRect)usedRect textContainer:(CPTextContainer)textContainer
{
    if (textContainer)
    {
        _extraLineFragment = {};
        _extraLineFragment._fragmentRect = CGRectCreateCopy(rect);
        _extraLineFragment._usedRect = CGRectCreateCopy(usedRect);
        _extraLineFragment._textContainer = textContainer;
    }
    else
    {
        _extraLineFragment = nil;
    }
}

- (CGRect)usedRectForTextContainer:(CPTextContainer)textContainer
{
    var rect,
        l = _lineFragments.length;

    for (var i = 0; i < l; i++)
    {
        if (_lineFragments[i]._textContainer === textContainer)
        {
            if (rect)
                rect = CGRectUnion(rect, _lineFragments[i]._usedRect);
            else
                rect = CGRectCreateCopy(_lineFragments[i]._usedRect);
        }
    }

    return rect ? rect : CGRectMakeZero();
}

- (CGRect)lineFragmentRectForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(CPRangePointer)effectiveGlyphRange
{
    var lineFragment = _objectWithLocationInRange(_lineFragments, glyphIndex);

    if (!lineFragment)
        return CGRectMakeZero();

    if (effectiveGlyphRange)
    {
        effectiveGlyphRange.location = lineFragment._range.location;
        effectiveGlyphRange.length = lineFragment._range.length;
    }

    return CGRectCreateCopy(lineFragment._fragmentRect);
}

- (CGRect)lineFragmentUsedRectForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(CPRangePointer)effectiveGlyphRange
{
    var lineFragment = _objectWithLocationInRange(_lineFragments, glyphIndex);

    if (!lineFragment)
        return CGRectMakeZero();

    if (effectiveGlyphRange)
    {
        effectiveGlyphRange.location = lineFragment._range.location;
        effectiveGlyphRange.length = lineFragment._range.length;
    }

    return CGRectCreateCopy(lineFragment._usedRect);
}

- (CGPoint)locationForGlyphAtIndex:(unsigned)index
{
    if (_lineFragments.length > 0 && index >= [self numberOfGlyphs] - 1)
    {
        var lineFragment= _lineFragments[_lineFragments.length - 1],
            glyphFrames = [lineFragment glyphFrames];

        if (glyphFrames.length > 0)
            return CGPointCreateCopy(glyphFrames[glyphFrames.length - 1].origin);
    }

    var lineFragment = _objectWithLocationInRange(_lineFragments, index);

    if (lineFragment)
    {
        if (index == lineFragment._range.location)
            return CGPointCreateCopy(lineFragment._location);

        var glyphFrames = [lineFragment glyphFrames];

        return CGPointCreateCopy(glyphFrames[index - lineFragment._range.location].origin);
    }

    return CGPointMakeZero();
}

- (CPTextContainer)textContainerForGlyphAtIndex:(unsigned)index effectiveRange:(CPRangePointer)effectiveGlyphRange withoutAdditionalLayout:(BOOL)flag
{
    var lineFragment = _objectWithLocationInRange(_lineFragments, index);

    if (lineFragment)
    {
        if (effectiveGlyphRange)
        {
            effectiveGlyphRange.location = lineFragment._range.location;
            effectiveGlyphRange.length = lineFragment._range.length;
        }

        return lineFragment._textContainer;
    }

    return [_textContainers lastObject];
}

- (CPTextContainer)textContainerForGlyphAtIndex:(unsigned)index effectiveRange:(CPRangePointer)effectiveGlyphRange
{
    return [self textContainerForGlyphAtIndex:index effectiveRange:effectiveGlyphRange withoutAdditionalLayout:NO];
}

- (CPRange)characterRangeForGlyphRange:(CPRange)aRange actualGlyphRange:(CPRangePointer)actualRange
{
    return _MakeRangeFromAbs([self characterIndexForGlyphAtIndex:aRange.location],
                             [self characterIndexForGlyphAtIndex:CPMaxRange(aRange)]);
}

- (unsigned)characterIndexForGlyphAtIndex:(unsigned)index
{
    /* FIXME: stub */
    return index;
}

- (CPArray)rectArrayForCharacterRange:(CPRange)charRange
         withinSelectedCharacterRange:(CPRange)selectedCharRange
                      inTextContainer:(CPTextContainer)container
                            rectCount:(CGRectPointer)rectCount
{

    var rectArray = [],
        lineFragments = _objectsInRange(_lineFragments, selectedCharRange);

    if (!lineFragments.length)
        return rectArray;

    var containerSize = [container containerSize];

    for (var i = 0; i < lineFragments.length; i++)
    {
        var fragment = lineFragments[i];

        if (fragment._textContainer === container)
        {
            var frames = [fragment glyphFrames],
                rect = nil,
                len = fragment._range.length;

            for (var j = 0; j < len; j++)
            {
                if (CPLocationInRange(fragment._range.location + j, selectedCharRange))
                {
                    if (!rect)
                        rect = CGRectCreateCopy(frames[j]);
                    else
                        rect = CGRectUnion(rect, frames[j]);

                    if (_isNewlineCharacter([[_textStorage string] characterAtIndex:MAX(0, CPMaxRange(selectedCharRange) - 1)]))
                    {
                         rect.size.width = containerSize.width - rect.origin.x;
                    }
                }
            }

            if (rect)
                rectArray.push(rect);
        }
    }

    var len = rectArray.length;

    for (var i = 0; i < len - 1; i++) // extend the width of all but the last one
    {
        if (rectArray[i].origin.y == rectArray[i + 1].origin.y)
            continue;

        rectArray[i].size.width = containerSize.width - rectArray[i].origin.x;
    }

    return rectArray;
}
@end
