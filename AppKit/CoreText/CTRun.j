/*
 * CTRun.j
 * CoreText
 *
 * Created by Nicholas Small.
 * Copyright 2011, 280 North, Inc.
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

kCTRunStatusNoStatus = 0;
kCTRunStatusRightToLeft = 1 << 0;
kCTRunStatusNonMonotonic = 1 << 1;
kCTRunStatusNonIdentityMatrix = 1 << 2;

/*!
    A CTRun represents a span of characters with common attribtues.
*/

function _CTRunCreate(glyphs, attributes)
{
    return {
        glyphs: glyphs,
        attributes: attributes,
        status: kCTRunStatusNoStatus
    };
}

_CTRunCreate.displayName = @"_CTRunCreate";

/*!
    Returns the number of glyphs in the run.
*/
function CTRunGetGlyphCount(/* CTRun */ aRun)
{
    return aRun.glyphs.length;
}

CTRunGetGlyphCount.displayName = @"CTRunGetGlyphCount";

/*!
    Returns a CPDictionary of attributes for the CTRun
*/
function CTRunGetAttributes(/* CTRun */ aRun)
{
    return aRun.attributes;
}

CTRunGetAttributes.displayName = @"CTRunGetAttributes";

/*!
    Returns a CTRunStatus
    CTRuns have status that can be used to speed up certain operations.

    Possible values:

    @code
    kCTRunStatusNoStatus
    kCTRunStatusRightToLeft
    kCTRunStatusNonMonotonic
    kCTRunStatusNonIdentityMatrix
    @endcode
*/
function CTRunGetStatus(/* CTRun */ aRun)
{
    return aRun.status || kCTRunStatusNoStatus;
}

CTRunGetStatus.displayName = @"CTRunGetStatus";

/*!
    Returns an array of CGGlyphs
    FIX ME: Not implemented correctly
*/
function CTRunGetGlyphs(/* CTRun */ aRun, /* CPRange */ aRange)
{
    if (!aRun.glyphs)
        aRun.glyphs = [];
    
    return aRun.glyphs;
}

CTRunGetGlyphs.displayName = @"CTRunGetGlyphs";

/*!
    Returns an array of CGPoints
    FIX ME: Not implemented correctly
*/
function CTRunGetPositions(/* CTRun */ aRun, /* CPRange */ aRange)
{
    if (!aRun.positions)
        aRun.positions = [];
    
    return aRun.positions;
}

CTRunGetPositions.displayName = @"CTRunGetPositions";

/*!
    Returns an array of CGSizes
    FIX ME: Not implemented correctly
*/
function CTRunGetAdvances(/* CTRun */ aRun, /* CPRange */ aRange)
{
    if (!aRun.advances)
        aRun.advances = [];
    
    return aRun.advances;
}

CTRunGetAdvances.displayName = @"CTRunGetAdvances";

/*!
    Returns an array of indexes.
    FIX ME: Not implemented correctly
*/
function CTRunGetStringIndices(/* CTRun */ aRun, /* CPRange */ aRange)
{
    if (!aRun.stringIndices)
        aRun.stringIndices = [];
    
    return aRun.stringIndices;
}

CTRunGetStringIndices.displayName = @"CTRunGetStringIndices";

/*!
    Returns a CPRange containing the location of the run in the parent string
*/
function CTRunGetStringRange(/* CTRun */ aRun)
{
    return aRun.range;
}

CTRunGetStringRange.displayName = @"CTRunGetStringRange";

/*!
    Returns a JSObject: {width: float, ascender: float, descender: float, lineHeight: float}
    More expensive
*/
function CTRunGetTypographicBounds(/* CTRun */ aRun, /* CPRange */ aRange)
{
    if (aRun._typographicBounds)
        return aRun._typographicBounds;
    
    var attributes = aRun.attributes,
        font = [attributes valueForKey:@"font"],
        string = _CTRunStringForRange(aRun, aRange);
    
    return aRun._typographicBounds = {
        width: [string sizeWithFont:font].width, // FIXME: account for tabs
        ascender: [font ascender],
        descender: [font descender],
        lineHeight: [font defaultLineHeightForFont]
    };
}

CTRunGetTypographicBounds.displayName = @"CTRunGetTypographicBounds";

/*!
    Returns a CGRect
    Cheap
*/
function CTRunGetImageBounds(/* CTRun */ aRun, /* CGContext */ aContext, /* CPRange */ aRange)
{
    if (aRun._imageBounds)
        return aRun._imageBounds;
    
    _CTRunPrepareDraw(aRun, aContext);
    
    var string = _CTRunStringForRange(aRun, aRange),
        width = aContext.measureText(string).width,
        height = [CGContextGetFont(aContext) defaultLineHeightForFont];
    
    _CTRunUnprepareDraw(aRun, aContext);
    
    return aRun._imageBounds = CGRectMake(0.0, 0.0, width, height);
}

CTRunGetImageBounds.displayName = @"CTRunGetImageBounds";

// CGAffineTransform
function CTRunGetTextMatrix(/* CTRun */ aRun)
{
    
}

CTRunGetTextMatrix.displayName = @"CTRunGetTextMatrix";

/*!
    Draws the run to the context
*/
function CTRunDraw(/* CTRun */ aRun, /* CGContext */ aContext, /* CPRange */ aRange)
{
    _CTRunPrepareDraw(aRun, aContext);
    
    var string = aRange ? [aRun.glyphs substringWithRange:aRange] : aRun.glyphs;
    _CTRunDrawShadow(aRun, aContext, string);
    
    var origins = aRun.glyphOrigins = [];
    for (var i = -1, count = string.length; ++i < count;)
    {
        var glyph = string[i];
        origins[i] = CGContextGetTextPosition(aContext);
        
        CGContextShowText(aContext, glyph);
    }
    
    _CTRunUnprepareDraw(aRun, aContext);
}

CTRunDraw.displayName = @"CTRunDraw";

function _CTRunDrawShadow(aRun, aContext, aString)
{
    var attributes = aRun.attributes,
        textShadowColor = [attributes valueForKey:@"text-shadow-color"],
        textShadowOffset = [attributes valueForKey:@"text-shadow-offset"];
    
    if (textShadowColor && textShadowOffset)
    {
        var color = CGContextGetFillColor(aContext),
            position = CGContextGetTextPosition(aContext);
        
        CGContextSetFillColor(aContext, textShadowColor);
        CGContextShowTextAtPoint(aContext, position.x + textShadowOffset.width, position.y + textShadowOffset.height, aString);
        
        CGContextSetFillColor(aContext, color);
        CGContextSetTextPosition(aContext, position.x, position.y);
    }
}

_CTRunDrawShadow.displayName = @"_CTRunDrawShadow";

function _CTRunPrepareDraw(aRun, aContext)
{
    var attributes = aRun.attributes,
        font = [attributes valueForKey:@"font"],
        color = [attributes valueForKey:@"color"];
    
    if (font)
    {
        CGContextSelectFont(aContext, font);
        aRun._cachedFont = CGContextGetFont(aContext);
    }
    
    if (color)
    {
        CGContextSetFillColor(aContext, color);
        aRun._cachedColor = CGContextGetFillColor(aContext);
    }
}

_CTRunPrepareDraw.displayName = @"_CTRunPrepareDraw";

function _CTRunUnprepareDraw(aRun, aContext)
{
    if (aRun._cachedFont)
    {
        CGContextSelectFont(aContext, aRun._cachedFont);
        aRun._cachedFont = nil;
    }
    
    if (aRun._cachedColor)
    {
        CGContextSetFillColor(aContext, aRun._cachedColor);
        aRun._cachedColor = nil;
    }
}

_CTRunUnprepareDraw.displayName = @"_CTRunUnprepareDraw";

function _CTRunStringForRange(aRun, aRange)
{
    return (!aRange || aRange.length === 0) ? aRun.glyphs : [aRun.glyphs substringWithRange:aRange];
}

_CTRunStringForRange.displayName = @"_CTRunStringForRange";