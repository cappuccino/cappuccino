
/*
 *  CPTypesetter.j
 *  AppKit
 *
 *  Created by Daniel Boehringer on 27/12/2013.
 *  All modifications copyright Daniel Boehringer 2013.
 *  Based on original work by
 *  Emmanuel Maillard on 27/02/2010.
 *  Copyright Emmanuel Maillard 2010.
 *
 *  FIXME: paragraphStyle indent information is currently not properly respected
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

@import <Foundation/CPObject.j>
@import "CPTextStorage.j"
@import "CPParagraphStyle.j"

/*
    CPTypesetterControlCharacterAction
*/
CPTypesetterZeroAdvancementAction = (1 << 0);
CPTypesetterWhitespaceAction      = (1 << 1);
CPSTypesetterHorizontalTabAction  = (1 << 2);
CPTypesetterLineBreakAction       = (1 << 3);
CPTypesetterParagraphBreakAction  = (1 << 4);
CPTypesetterContainerBreakAction  = (1 << 5);


var _measuringContext;
var _measuringContextFont;
var _isCanvasSizingInvalid = 0;
var _didTestCanvasSizingValid;
function _widthOfStringForFont(aString, aFont)
{
    if (!_measuringContext)
        _measuringContext = CGBitmapGraphicsContextCreate();
    if (!_didTestCanvasSizingValid && CPFeatureIsCompatible(CPHTMLCanvasFeature))
    {
        var teststring = "0123456879abcdefghiklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ,.-()";
        _didTestCanvasSizingValid = YES;
        _measuringContext.font = [aFont cssString];
        _isCanvasSizingInvalid = [teststring sizeWithFont:aFont].width != _measuringContext.measureText(teststring).width;
    }
    if (!CPFeatureIsCompatible(CPHTMLCanvasFeature) || _isCanvasSizingInvalid)  // measuring with canvas is _much_ faster on chrome
        return [aString sizeWithFont:aFont];
    if (_measuringContextFont !== aFont)
    {
        _measuringContextFont = aFont
        _measuringContext.font = [aFont cssString];
    }
    return _measuringContext.measureText(aString);
}

var CPSystemTypesetterFactory = Nil;

@implementation CPTypesetter : CPObject
{
}

+ (id)sharedSystemTypesetter
{
    return [CPSystemTypesetterFactory sharedInstance];
}

+ (void)_setSystemTypesetterFactory:(Class)aClass
{
    CPSystemTypesetterFactory = aClass;
}

+ (void)initialize
{
    [CPTypesetter _setSystemTypesetterFactory:[CPSimpleTypesetter class]];
}

- (CPTypesetterControlCharacterAction)actionForControlCharacterAtIndex:(unsigned)charIndex
{
    return CPTypesetterZeroAdvancementAction;
}

- (CPLayoutManager)layoutManager
{
    return nil;
}

- (CPTextContainer)currentTextContainer
{
    return nil;
}

- (CPArray)textContainers
{
    return nil;
}

- (void)layoutGlyphsInLayoutManager:(CPLayoutManager)layoutManager
        startingAtGlyphIndex:(unsigned)startGlyphIndex
        maxNumberOfLineFragments:(unsigned)maxNumLines
        nextGlyphIndex:(UIntegerPointer)nextGlyph
{
   CPLog.error(@"-[CPTypesetter subclass responsibility");
}

@end

var _sharedSimpleTypesetter = nil;

@implementation CPSimpleTypesetter:CPTypesetter
{
    CPLayoutManager     _layoutManager;
    CPTextContainer     _currentTextContainer;
    CPTextStorage       _textStorage;

    CPRange             _attributesRange;
    CPDictionary        _currentAttributes;
    CPFont              _currentFont;
    CPParagraphStyle    _currentParagraph;

    float               _lineHeight;
    float               _lineBase;
    float               _lineWidth;

    unsigned            _indexOfCurrentContainer;
}

+ (id)sharedInstance
{
    if (_sharedSimpleTypesetter === nil)
        _sharedSimpleTypesetter = [[CPSimpleTypesetter alloc] init];

    return _sharedSimpleTypesetter;
}

- (CPLayoutManager)layoutManager
{
    return _layoutManager;
}

- (CPTextContainer)currentTextContainer
{
    return _currentTextContainer;
}

- (CPArray)textContainers
{
    return [_layoutManager textContainers];
}

- (CPTextTab)textTabForWidth:(double)aWidth writingDirection:(CPWritingDirection)direction
{
    var tabStops = [_currentParagraph tabStops];

    if (!tabStops)
        tabStops = [CPParagraphStyle _defaultTabStops];

    var i,
        l = tabStops.length;

    if (aWidth > tabStops[l-1]._location)
        return nil;

    for (i = l-1; i >= 0; i--)
    {
        if (aWidth > tabStops[i]._location)
        {
            if (i + 1 < l)
                return tabStops[i + 1];
        }
    }
    return nil;
}

- (BOOL)_flushRange:(CPRange)lineRange
        lineOrigin:(CPPoint)lineOrigin
        currentContainerSize:(CPSize)containerSize
        advancements:(CPArray)advancements
        lineCount:(unsigned)lineCount
{
    [_layoutManager setTextContainer:_currentTextContainer forGlyphRange:lineRange];  // creates a new lineFragment
    var rect = CPRectMake(lineOrigin.x, lineOrigin.y, _lineWidth, _lineHeight);
    [_layoutManager setLineFragmentRect: rect forGlyphRange:lineRange usedRect:rect];
    var myX = 0;

    switch ([_currentParagraph alignment])
    {
        case CPLeftTextAlignment:
            myX = 0;
            break;

        case CPCenterTextAlignment:
            myX = (containerSize.width - _lineWidth) / 2;
            break;

        case CPRightTextAlignment:
            myX = containerSize.width - _lineWidth;
            break;
    }

    [_layoutManager setLocation:CPMakePoint(myX, _lineBase) forStartOfGlyphRange:lineRange];
    [_layoutManager _setAdvancements:advancements forGlyphRange:lineRange];

    if (!lineCount)
        return NO;

    return ([_layoutManager _rescuingInvalidFragmentsWasPossibleForGlyphRange:lineRange]);
}

- (void)layoutGlyphsInLayoutManager:(CPLayoutManager)layoutManager
        startingAtGlyphIndex:(unsigned)glyphIndex
        maxNumberOfLineFragments:(unsigned)maxNumLines
        nextGlyphIndex:(UIntegerReference)nextGlyph
{
    _layoutManager = layoutManager;
    _textStorage = [_layoutManager textStorage];
    _indexOfCurrentContainer = MAX(0, [[_layoutManager textContainers]
                                   indexOfObject:[_layoutManager textContainerForGlyphAtIndex:glyphIndex effectiveRange:nil withoutAdditionalLayout:YES]
                                   inRange:CPMakeRange(0, [[_layoutManager textContainers] count])]);
    _currentTextContainer = [[_layoutManager textContainers] objectAtIndex:_indexOfCurrentContainer];
    _attributesRange = CPMakeRange(0, 0);
    _lineHeight = 0;
    _lineBase = 0;
    _lineWidth = 0;

    var containerSize = [_currentTextContainer containerSize],
        lineRange = CPMakeRange(glyphIndex, 0),
        wrapRange = CPMakeRange(0, 0),
        wrapWidth = 0,
        isNewline = NO,
        isTabStop = NO,
        isWordWrapped = NO,
        numberOfGlyphs= [_textStorage length],
        leading;

    var numLines = 0,
        theString = [_textStorage string],
        lineOrigin,
        ascent, descent;

    var advancements = [],
        prevRangeWidth = 0,
        measuringRange = CPMakeRange(glyphIndex, 0),
        currentAnchor = 0,
        _previousFont = nil;

    if (glyphIndex > 0)
        lineOrigin = CPPointCreateCopy([_layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:nil].origin);
    else if ([_layoutManager extraLineFragmentTextContainer])
         lineOrigin = CPPointMake(0, [_layoutManager extraLineFragmentUsedRect].origin.y);
    else
        lineOrigin = CPPointMake(0, 0);

    [_layoutManager _removeInvalidLineFragments];

    if (![_textStorage length])
        return;

    for (; numLines != maxNumLines && glyphIndex < numberOfGlyphs; glyphIndex++)
    {
            if (!CPLocationInRange(glyphIndex, _attributesRange))
            {
                _currentAttributes = [_textStorage attributesAtIndex:glyphIndex effectiveRange:_attributesRange];
                _currentFont = [_currentAttributes objectForKey:CPFontAttributeName];
                _currentParagraph = [_currentAttributes objectForKey:CPParagraphStyleAttributeName] || [CPParagraphStyle defaultParagraphStyle];

                if (!_currentFont)
                    _currentFont = [_textStorage font];

                ascent = ["x" sizeWithFont:_currentFont].height; //FIXME
                descent = 0;    //FIXME
                leading = (ascent - descent) * 0.2; // FAKE leading
            }

            if (_previousFont !== _currentFont)
            {
                measuringRange = CPMakeRange(glyphIndex, 0);
                currentAnchor = prevRangeWidth;
                _previousFont = _currentFont;
            }

            lineRange.length++;
            measuringRange.length++;

            var currentChar = theString[glyphIndex],  // use pure javascript methods for performance reasons
                rangeWidth = _widthOfStringForFont(theString.substr(measuringRange.location, measuringRange.length), _currentFont).width  + currentAnchor;

            switch (currentChar)    // faster than sending actionForControlCharacterAtIndex: called for each char.
            {
                case '\n':
                    isNewline = YES;
                break;
                case '\t':
                {
                    isTabStop = YES;
                    var nextTab = [self textTabForWidth:rangeWidth + lineOrigin.x writingDirection:0];
                    if (nextTab)
                    {
                        rangeWidth = nextTab._location - lineOrigin.x;
                    }
                    else
                        rangeWidth += 28;   //FIXME
                }  // fallthrough intentional
                case  ' ':
                    wrapRange = CPMakeRangeCopy(lineRange);
                    wrapWidth = rangeWidth;
                break;
            }

            advancements.push(rangeWidth - prevRangeWidth);
            prevRangeWidth = _lineWidth = rangeWidth;

            if (lineOrigin.x + rangeWidth > containerSize.width)
            {
                if (wrapWidth)
                {
                    lineRange = wrapRange;
                   _lineWidth = wrapWidth;
                }

                isNewline = YES;
                isWordWrapped = YES;
                glyphIndex = CPMaxRange(lineRange) - 1;
            }

            _lineHeight = MAX(_lineHeight, ascent - descent + leading);
            _lineBase = MAX(_lineBase, ascent);

            if (isNewline || isTabStop)
            {
                if ([self _flushRange:lineRange lineOrigin:lineOrigin currentContainerSize:containerSize advancements:advancements lineCount:numLines])
                    return;

                if (isTabStop)
                {
                   lineOrigin.x += rangeWidth;
                   isTabStop = NO;
                }
                if (isNewline)
                {
                    if ([_currentParagraph minimumLineHeight])
                        _lineHeight = MAX(_lineHeight, [_currentParagraph minimumLineHeight]);
                    if ([_currentParagraph maximumLineHeight])
                        _lineHeight = MIN(_lineHeight, [_currentParagraph maximumLineHeight]);
                    lineOrigin.y += _lineHeight;
                    if ([_currentParagraph lineSpacing])
                        lineOrigin.y += [_currentParagraph lineSpacing];
                    if (lineOrigin.y > [_currentTextContainer containerSize].height)
                    {
                        _currentTextContainer = [[_layoutManager textContainers] objectAtIndex: ++_indexOfCurrentContainer];
                    }
                    lineOrigin.x = 0;
                    numLines++;
                    isNewline = NO;
                }
               _lineWidth      = 0;
                advancements   = [];
                prevRangeWidth = 0;
                currentAnchor  = 0;
               _lineHeight     = 0;
               _lineBase       = 0;
               _previousFont   = nil;
                lineRange      = CPMakeRange(glyphIndex + 1, 0);
                wrapRange      = CPMakeRange(0, 0);
                wrapWidth      = 0;
                isWordWrapped  = NO;
            }
    }

    // this is to "flush" the remaining characters
    if (lineRange.length)
        [self _flushRange:lineRange lineOrigin:lineOrigin currentContainerSize:containerSize advancements:advancements lineCount:numLines];

    if ([theString.charAt(theString.length - 1) ==="\n"])
    {
        var rect = CPRectMake(0, lineOrigin.y, containerSize.width, [_layoutManager._lineFragments lastObject]._usedRect.size.height);   // fixme: row-height is crudely hacked
        [_layoutManager setExtraLineFragmentRect:rect usedRect:rect textContainer:_currentTextContainer];
    }
}

@end
