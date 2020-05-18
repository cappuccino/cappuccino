/*
 * CTTypesetter.j
 * AppKit
 *
 * Created by Robert Grant.
 * Copyright 2015, plasq LLC.
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

kCTTypesetterOptionDisableBidiProcessing = "CTTypesetterOptionDisableBidiProcessing";
kCTTypesetterOptionForcedEmbeddingLevel = "CTTypesetterOptionForcedEmbeddingLevel";

@import <Foundation/Foundation.j>

@import "CGContext.j"

@import "CTDefaultAttributes.j"
@import "CTLine.j"

@import "CPGraphicsContext.j"

var CPTypesetterSVGTextElement = nil;

@implementation CPTypesetter : CPObject
{
    CPAttributedString _string;
    int _lineBreakMode;
}

- (id)initWithAttributedString:(CPAttributedString)string options:(CPDictionary)options
{
    self = [super init];
    if (self)
    {
        if (CPTypesetterSVGTextElement === nil) {
            var svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
            // Place it offscreen
            CPDOMDisplayServerSetStyleLeftTop(svg, NULL, -1000, -1000);
        
            CPTypesetterSVGTextElement = document.createElementNS("http://www.w3.org/2000/svg", "text");
            svg.style.display = "hidden";
            svg.appendChild(CPTypesetterSVGTextElement);
            var elements = document.getElementsByTagName("body");
            elements[0].appendChild(svg)
        }
            
        var attributes = CTGetDefaultAttributes();
        var paragraphStyle = [attributes objectForKey: kCTParagraphStyleAttributeName];
        _lineBreakMode = [CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierLineBreakMode) intValue];
        
        var font = [attributes objectForKey: kCTFontAttributeName];
        var style = new Array();
        style.push("font-family: " +  CTFontCopyFullName(font));
        style.push("font-size: " + CTFontGetSize(font));
        CPTypesetterSVGTextElement.setAttribute("style", style.join(";"));

        _string = [string copy];
        
        // options are ignored
    }
    return self;
}

- (CPLine)createLineWithRange:(CPRange)range offset:(CGFloat)offset
{
    var string = [_string attributedSubstringFromRange: range];
    
    var width = [self computeLengthOfString: string];
    
    var line = CTLineCreateWithAttributedString(string);
    [line setHeight: 15];
    [line setWidth: width];
    
    return line;
}

- (void)clearTextElement
{
    while (CPTypesetterSVGTextElement.hasChildNodes())
    {
        CPTypesetterSVGTextElement.removeChild(CPTypesetterSVGTextElement.lastChild);
    }
}

- (double)computeLengthOfString:(CPAttributedString)string
{
    [self clearTextElement];
    
    var range = CPMakeRange(0, [string length]);
    var attributeRange = CPMakeRange(0, 0);
    while (CPMaxRange(attributeRange) < CPMaxRange(range))
    {
        var index = CPMaxRange(attributeRange);
        var attributes = [string attributesAtIndex: index effectiveRange:
         attributeRange];
         
         var tspan = document.createElementNS("http://www.w3.org/2000/svg", "tspan");
         
         tspan.textContent = [[string string] substringWithRange: attributeRange];
         
         var font = [attributes objectForKey: kCTFontAttributeName];
         if (font !== nil)
         {
            var style = new Array();
            style.push("font-family: " +  CTFontCopyFullName(font));
            style.push("font-size: " + CTFontGetSize(font));
            tspan.setAttribute("style", style.join(";"));
         }
         CPTypesetterSVGTextElement.appendChild(tspan);
    }
    var length = CPTypesetterSVGTextElement.getComputedTextLength();

    [self clearTextElement];
    
    return length;
}

function isWhiteSpace(ch)
{
    return " \t\n\r\v".indexOf(ch) != -1;
}

- (int)suggestLineBreakAfterIndex:(int)startIndex width:(double)width offset: (double)offset
{
    if (startIndex >= [_string length] -1)
    {
        return -1;
    }
    
    var tooWide = NO;
    var range = CPMakeRange(startIndex, 1);
    var charBreakIndex = -1;
    var lastWordBreakIndex = -1;
    
    width -= offset;
    
    var rawString = [_string string];
    
    while (tooWide == NO && CPMaxRange(range) < [_string length])
    {
        var string = [_string attributedSubstringFromRange: range];
        var length = [self computeLengthOfString: string];
        if (length < width)
        {
            charBreakIndex = CPMaxRange(range);
            if (isWhiteSpace([rawString characterAtIndex: charBreakIndex]))
            {
                lastWordBreakIndex = charBreakIndex;
            }
            range.length += 1;
        }
        else
        {
            tooWide = YES;
        }
    }
    
    if (tooWide == NO)
    {
        // The range fits so just set the word break to the char break.
        lastWordBreakIndex = charBreakIndex;
    }
    
    switch(_lineBreakMode)
    {
        case kCTLineBreakByWordWrapping:
            if (lastWordBreakIndex != -1)
            {
                return lastWordBreakIndex;
            }
        default:
            return charBreakIndex;
    }
    
    return charBreakIndex;
}

- (int)suggestClusterBreakAfterIndex:(int)startIndex width:(double)width offset: (double)offset
{
    CPLog.warn("- [CTTypesetter suggestClusterBreakAfterIndex:width:offset:] not implemented");
    return -1;
}

@end

function CTTypesetterCreateWithAttributedString(anAttributedString)
{
    return CTTypesetterCreateWithAttributedStringAndOptions(anAttributedString, nil);
}


function CTTypesetterCreateWithAttributedStringAndOptions(anAttributedString, options)
{
    return [[CPTypesetter alloc] initWithAttributedString: anAttributedString options: options];
}

function CTTypesetterCreateLine(aTypesetter, aRange)
{
    return CTTypesetterCreateLineWithOffset(aTypesetter, aRange, 0.0);
}

function CTTypesetterCreateLineWithOffset(aTypesetter, aRange, offset)
{
    [aTypesetter createLineWithRange: aRange offset: offset];
}

function CTTypesetterSuggestLineBreak(aTypesetter, startIndex, width)
{
    CTTypesetterSuggestLineBreakWithOffset(aTypesetter, startIndex, width, 0.0);
}

function CTTypesetterSuggestLineBreakWithOffset(aTypesetter, startIndex, width, offset)
{
    [aTypesetter suggestLineBreakAfterIndex: startIndex width: width offset: offset];
}

function CTTypesetterSuggestClusterBreak(aTypesetter, startIndex, width)
{
    CTTypesetterSuggestClusterBreakWithOffset(aTypesetter, startIndex, width, 0.0);
}

function CTTypesetterSuggestClusterBreakWithOffset(aTypesetter, startIndex, width, offset)
{
    [aTypesetter suggestClusterBreakAfterIndex: startIndex width: width offset: offset];
}