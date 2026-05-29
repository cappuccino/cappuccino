/*
 *  CPTypesetter.j
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

@import <Foundation/CPObject.j>

@import "CPParagraphStyle.j"
@import "CPTextStorage.j"
@import "CPFont.j"

// forward declare these classes for type matching
@class CPLayoutManager
@class CPTextContainer
@class CPTextView

/*
    CPTypesetterControlCharacterAction
*/
CPTypesetterZeroAdvancementAction = 1 << 0;
CPTypesetterWhitespaceAction      = 1 << 1;
CPSTypesetterHorizontalTabAction  = 1 << 2;
CPTypesetterLineBreakAction       = 1 << 3;
CPTypesetterParagraphBreakAction  = 1 << 4;
CPTypesetterContainerBreakAction  = 1 << 5;

var CPSystemTypesetterFactory,
    _sharedSimpleTypesetter;

@implementation CPTypesetter : CPObject


#pragma mark -
#pragma mark Class methods

+ (void)initialize
{
    [CPTypesetter _setSystemTypesetterFactory:[CPSimpleTypesetter class]];
}

+ (id)sharedSystemTypesetter
{
    return [CPSystemTypesetterFactory sharedInstance];
}

+ (void)_setSystemTypesetterFactory:(Class)aClass
{
    CPSystemTypesetterFactory = aClass;
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
        nextGlyphIndex:(UIntegerReference)nextGlyph
{
   _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

@end

@implementation CPSimpleTypesetter : CPTypesetter
{
    CPLayoutManager     _layoutManager          @accessors(property=layoutManager);
    CPTextContainer     _currentTextContainer   @accessors(property=currentTextContainer);
    CPTextStorage       _textStorage;

    CPRange             _attributesRange;
    CPDictionary        _currentAttributes;
    CPParagraphStyle    _currentParagraph;

    float               _lineHeight;
    float               _lineBase;
    float               _lineWidth;

    unsigned            _indexOfCurrentContainer;

    CPArray             _lineFragments;
}


#pragma mark -
#pragma mark Class methods

+ (id)sharedInstance
{
    if (!_sharedSimpleTypesetter)
        _sharedSimpleTypesetter = [[CPSimpleTypesetter alloc] init];

    return _sharedSimpleTypesetter;
}

- (CPArray)textContainers
{
    return [_layoutManager textContainers];
}

// Retrieves correct CPTextTab stop accounting for CPArray properties
- (CPTextTab)textTabForWidth:(double)aWidth writingDirection:(CPWritingDirection)direction
{
    var tabStops = [_currentParagraph tabStops];

    if (!tabStops)
        tabStops = [[CPParagraphStyle defaultParagraphStyle] tabStops];

    var l = [tabStops count];

    if (l === 0)
        return nil;

    // Find the first tab stop that is strictly greater than the current width
    for (var i = 0; i < l; i++)
    {
        var tab = [tabStops objectAtIndex:i];

        if ([tab location] > aWidth)
            return tab;
    }

    // If aWidth exceeds the last tab stop, dynamically calculate the next 
    // tab location using the default tab interval.
    var defaultInterval = [_currentParagraph defaultTabInterval] || 28.0;
    var nextLocation = CEIL((aWidth + 1.0) / defaultInterval) * defaultInterval;

    return [[CPTextTab alloc] initWithType:CPLeftTextAlignment location:nextLocation];
}

- (BOOL)_flushRange:(CPRange)lineRange
         lineOrigin:(CGPoint)lineOrigin
   currentContainer:(CPTextContainer)aContainer
       advancements:(CPArray)advancements
          lineCount:(unsigned)lineCount
           sameLine:(BOOL)sameLine
{
    var myX = 0,
        rect = CGRectMake(lineOrigin.x, lineOrigin.y, _lineWidth, _lineHeight),
        containerSize = aContainer._size;

    [_layoutManager _appendNewLineFragmentInTextContainer:_currentTextContainer forGlyphRange:lineRange];

    var fragment = [_layoutManager._lineFragments lastObject];
    fragment._isLast = !sameLine;
    _lineFragments.push(fragment);

    [_layoutManager setLineFragmentRect:rect forGlyphRange:lineRange usedRect:rect];

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

    [_layoutManager setLocation:CGPointMake(myX, _lineBase) forStartOfGlyphRange:lineRange];
    [_layoutManager _setAdvancements:advancements forGlyphRange:lineRange];

    //fix the _lineFragments when fontsizes differ
    var l = _lineFragments.length;

    for (var i = 0 ; i < l ; i++)
        [_lineFragments[i] _adjustForHeight:_lineHeight];

    if (!lineCount)  // do not rescue on first line
        return NO;

    if (aContainer._inResizing)
        return NO;

    return ([_layoutManager _rescuingInvalidFragmentsWasPossibleForGlyphRange:lineRange]);
}

- (void)layoutGlyphsInLayoutManager:(CPLayoutManager)layoutManager
        startingAtGlyphIndex:(unsigned)glyphIndex
        maxNumberOfLineFragments:(unsigned)maxNumLines
        nextGlyphIndex:(UIntegerReference)nextGlyph
{
    var textContainers = [layoutManager textContainers],
        textContainersCount = [textContainers count];

    _layoutManager = layoutManager;
    _textStorage = [_layoutManager textStorage];
    _indexOfCurrentContainer = MAX(0, [textContainers
                                   indexOfObject:[_layoutManager textContainerForGlyphAtIndex:glyphIndex effectiveRange:nil withoutAdditionalLayout:YES]
                                         inRange:CPMakeRange(0, textContainersCount)]);

    _currentTextContainer = textContainers[_indexOfCurrentContainer];

    _attributesRange = CPMakeRange(0, 0);
    _lineHeight = 0;
    _lineBase = 0;
    _lineWidth = 0;

    var containerSize = [_currentTextContainer containerSize],
        containerSizeWidth = containerSize.width,
        containerSizeHeight = containerSize.height,
        lineRange = CPMakeRange(glyphIndex, 0),
        wrapRange = CPMakeRange(0, 0),
        wrapWidth = 0,
        isNewline = NO,
        isTabStop = NO,
        isAttachment = NO,
        isWordWrapped = NO,
        numberOfGlyphs= [_textStorage length],
        leading,
        numLines = 0,
        theString = [_textStorage string],
        lineOrigin,
        ascent,
        descent,
        advancements = [],
        prevRangeWidth = 0,
        measuringRange = CPMakeRange(glyphIndex, 0),
        currentAnchor = 0,
        currentFont,
        currentFontLineHeight,
        previousFont,
        currentParagraphMinimumLineHeight,
        currentParagraphMaximumLineHeight,
        currentParagraphLineSpacing;

    // Track physical line starts to prevent overwriting lineOrigin.x in tab segments
    var isStartOfPhysicalLine = YES;

    // Track paragraph indents and margins
    var isFirstLineOfLayout = YES,
        isFirstLineOfParagraph = YES,
        rightMargin = containerSizeWidth;

    if (glyphIndex > 0)
        lineOrigin = CGPointCreateCopy([_layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:nil].origin);
    else if ([_layoutManager extraLineFragmentTextContainer])
        lineOrigin = CGPointMake(0, [_layoutManager extraLineFragmentUsedRect].origin.y);
    else
        lineOrigin = CGPointMake(0, 0);

    [_layoutManager _removeInvalidLineFragments];

    if (![_textStorage length])
        return;

    _lineFragments = [];

    for (; numLines != maxNumLines && glyphIndex < numberOfGlyphs; glyphIndex++)
    {
        // check whether there any change in the attributes from here on
        if (!CPLocationInRange(glyphIndex, _attributesRange))
        {
            _currentAttributes = [_textStorage attributesAtIndex:glyphIndex effectiveRange:_attributesRange];
            currentFont = [_currentAttributes objectForKey:CPFontAttributeName];
            _currentParagraph = [_currentAttributes objectForKey:CPParagraphStyleAttributeName] || [CPParagraphStyle defaultParagraphStyle];
            currentParagraphMinimumLineHeight = [_currentParagraph minimumLineHeight];
            currentParagraphMaximumLineHeight = [_currentParagraph maximumLineHeight];
            currentParagraphLineSpacing = [_currentParagraph lineSpacing];

            // Recalculate right margin on paragraph style change
            var tailIndent = [_currentParagraph tailIndent];
            if (tailIndent > 0.0)
                rightMargin = tailIndent;
            else if (tailIndent < 0.0)
                rightMargin = containerSizeWidth + tailIndent;
            else
                rightMargin = containerSizeWidth;

            // If we are at the start of a physical line, we update lineOrigin.x
            if (isStartOfPhysicalLine)
            {
                if (glyphIndex > 0)
                {
                    var prevChar = theString.charCodeAt(glyphIndex - 1);
                    isFirstLineOfParagraph = (prevChar === 10 || prevChar === 13);
                }
                else
                {
                    isFirstLineOfParagraph = YES;
                }
                lineOrigin.x = isFirstLineOfParagraph ? [_currentParagraph firstLineHeadIndent] : [_currentParagraph headIndent];
                isFirstLineOfLayout = NO;
            }
        
            // Calculate the right wrapping margin based on tail indent
            var tailIndent = [_currentParagraph tailIndent];
            if (tailIndent > 0.0)
                rightMargin = tailIndent;
            else if (tailIndent < 0.0)
                rightMargin = containerSizeWidth + tailIndent;
            else
                rightMargin = containerSizeWidth;

            // Handle the layout's very first line indentation
            if (isFirstLineOfLayout)
            {
                if (glyphIndex > 0)
                {
                    var prevChar = theString.charCodeAt(glyphIndex - 1);
                    isFirstLineOfParagraph = (prevChar === 10 || prevChar === 13);
                }
                else
                {
                    isFirstLineOfParagraph = YES;
                }
                lineOrigin.x = isFirstLineOfParagraph ? [_currentParagraph firstLineHeadIndent] : [_currentParagraph headIndent];
                isFirstLineOfLayout = NO;
            }

            if (!currentFont)
                currentFont = [_textStorage font] || [CPFont systemFontOfSize:12.0];

            ascent = [currentFont ascender];
            descent = [currentFont descender];
            leading = (ascent - descent) * 0.2; // FAKE leading

            currentFontLineHeight = ascent - descent + leading;

            if (previousFont !== currentFont)
            {
                measuringRange = CPMakeRange(glyphIndex, 0);
                currentAnchor = prevRangeWidth;
                previousFont = currentFont;
            }

        }

        if (currentFontLineHeight > _lineHeight)
            _lineHeight = currentFontLineHeight;

        if (ascent > _lineBase)
            _lineBase = ascent;

        lineRange.length++;
        measuringRange.length++;

        // We are processing characters, so we are no longer at the start of a physical line
        isStartOfPhysicalLine = NO;

        var currentCharCode = theString.charCodeAt(glyphIndex),  // use pure javascript methods for performance reasons
            rangeWidth = [theString.substr(measuringRange.location, measuringRange.length) sizeWithFont:currentFont inWidth:NULL].width + currentAnchor;

        switch (currentCharCode)    // faster than sending actionForControlCharacterAtIndex: called for each char.
        {
            case CPAttachmentCharacter:
            {
                var attributes = [_textStorage attributesAtIndex:glyphIndex effectiveRange:nil],
                    view = [attributes objectForKey:_CPAttachmentView],
                    viewSize = view ? view._frame.size : CGSizeMake(0, 0);

                rangeWidth = prevRangeWidth + viewSize.width; // undo sizing of dummy character

                isAttachment = YES;
                wrapRange = CPMakeRange(lineRange.location, lineRange.length - 1); // wrap before image

                // prevent crash when image is larger than text container
                if (viewSize.width > containerSizeWidth)
                    wrapRange.length++;

                wrapWidth = rangeWidth;
                wrapRange._height = _lineHeight;
                wrapRange._base = _lineBase;

                if (viewSize.height > _lineBase)
                    _lineBase = viewSize.height;

                if (viewSize.height > _lineHeight)
                    _lineHeight = viewSize.height - descent + leading;

                ascent = viewSize.height;
                break;
            }
            case 9: // '\t'
            {
                var nextTab = [self textTabForWidth:rangeWidth + lineOrigin.x writingDirection:0];

                isTabStop = YES;

                if (nextTab)
                {
                    // Look-ahead to measure the width of the incoming text segment for alignment
                    var nextSegmentWidth = 0.0,
                        tempIndex = glyphIndex + 1,
                        segmentString = "";

                    while (tempIndex < numberOfGlyphs)
                    {
                        var nextCharCode = theString.charCodeAt(tempIndex);
                        if (nextCharCode === 9 || nextCharCode === 10 || nextCharCode === 13)
                            break;
                        segmentString += theString.charAt(tempIndex);
                        tempIndex++;
                    }

                    if (segmentString.length > 0)
                        nextSegmentWidth = [segmentString sizeWithFont:currentFont inWidth:NULL].width;

                    var tabLocation = [nextTab location],
                        tabAlignment = [nextTab alignment];

                    // Mathematically offset the tab character's right boundary
                    if (tabAlignment === CPCenterTextAlignment)
                    {
                        rangeWidth = (tabLocation - nextSegmentWidth / 2.0) - lineOrigin.x;
                    }
                    else if (tabAlignment === CPRightTextAlignment)
                    {
                        rangeWidth = (tabLocation - nextSegmentWidth) - lineOrigin.x;
                    }
                    else // Left align tab stop
                    {
                        rangeWidth = tabLocation - lineOrigin.x;
                    }

                    // Enforce a minimum safety spacer width to avoid character overlapping
                    var minRangeWidth = prevRangeWidth + 5.0;
                    if (rangeWidth < minRangeWidth)
                        rangeWidth = minRangeWidth;
                }
                else
                {
                    rangeWidth += 28.0; // standard fallback spacer
                }
                break;
            }
            case 32: // ' '
                wrapRange = CPMakeRangeCopy(lineRange);
                wrapWidth = rangeWidth;
                wrapRange._height = _lineHeight;
                wrapRange._base = _lineBase;
                
                // Optimization: Start measuring from the next character to avoid O(n^2) 
                // string width calculation within a line since spaces do not carry ligatures or kerning.
                // Only reset the measuring range if the next character is NOT another space.
                // This prevents compounded subpixel rounding errors with contiguous spaces.
                if (theString.charCodeAt(glyphIndex + 1) !== 32)
                {
                    currentAnchor = rangeWidth;
                    measuringRange = CPMakeRange(glyphIndex + 1, 0);
                }
                
                break;

            case 10:
            case 13:
                isNewline = YES;
        }

        advancements.push({width: rangeWidth - prevRangeWidth, height: ascent, descent: descent});
        prevRangeWidth = _lineWidth = rangeWidth;

        // Wrap lines against the tail indent (rightMargin) instead of container boundaries
        if (lineOrigin.x + rangeWidth > rightMargin)
        {
            if (wrapWidth)
            {
                lineRange   = wrapRange;
               _lineWidth   = wrapWidth;
               _lineHeight  = wrapRange._height;
               _lineBase    = wrapRange._base;
            }

            isNewline = YES;
            isWordWrapped = YES;
            glyphIndex = CPMaxRange(lineRange) - 1;  // start the line starts directly at current character
        }

        if (isNewline || isTabStop || isAttachment)
        {
            if ([self _flushRange:lineRange lineOrigin:lineOrigin currentContainer:_currentTextContainer advancements:advancements lineCount:numLines sameLine:!isNewline])
                return;

            if (isTabStop || isAttachment)
               lineOrigin.x += rangeWidth;

            if (isNewline)
            {
                if (currentParagraphMinimumLineHeight && currentParagraphMinimumLineHeight > _lineHeight)
                    _lineHeight = currentParagraphMinimumLineHeight;

                if (currentParagraphMaximumLineHeight && currentParagraphMaximumLineHeight < _lineHeight)
                    _lineHeight = currentParagraphMaximumLineHeight;

                lineOrigin.y += _lineHeight;

                if (currentParagraphLineSpacing)
                    lineOrigin.y += currentParagraphLineSpacing;

                if (lineOrigin.y > containerSizeHeight && _indexOfCurrentContainer < textContainersCount - 1)
                {
                    _currentTextContainer = textContainers[++_indexOfCurrentContainer];
                    containerSize = [_currentTextContainer containerSize];
                    containerSizeWidth = containerSize.width;
                    containerSizeHeight = containerSize.height;
                }

                // If this is a soft wrap (isWordWrapped), next line gets headIndent. 
                // If it was a paragraph return, it gets firstLineHeadIndent.
                isFirstLineOfParagraph = !isWordWrapped;
                lineOrigin.x = isFirstLineOfParagraph ? [_currentParagraph firstLineHeadIndent] : [_currentParagraph headIndent];

                numLines++;
                isNewline = NO;
                _lineFragments = [];
                _lineHeight    = 0;
                _lineBase      = ascent;
                isStartOfPhysicalLine = YES;
            }

            isTabStop       = NO;
            isAttachment    = NO;
            isWordWrapped   = NO;
            _lineWidth      = 0;
            advancements    = [];
            currentAnchor   = 0;
            prevRangeWidth  = 0;
            lineRange       = CPMakeRange(glyphIndex + 1, 0);
            measuringRange  = CPMakeRange(glyphIndex + 1, 0);
            wrapRange       = CPMakeRange(0, 0);
            wrapWidth       = 0;
        }
    }

    // this is to "flush" the remaining characters
    if (lineRange.length)
        [self _flushRange:lineRange lineOrigin:lineOrigin currentContainer:_currentTextContainer advancements:advancements lineCount:numLines sameLine:NO];

    var rect = CGRectMake(1, lineOrigin.y - descent, containerSizeWidth, currentFontLineHeight);
    [_layoutManager setExtraLineFragmentRect:rect usedRect:rect textContainer:_currentTextContainer];

    var fragment = [_layoutManager._lineFragments lastObject];

    if (fragment)
        fragment._isLast = YES;
}

@end
