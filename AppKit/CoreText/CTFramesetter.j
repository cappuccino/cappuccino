/*
 * CTFramesetter.j
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

@import "CTFrame.j"
@import "CTTypesetter.j"


/*!
    Creates a typesetter with a given CPAttributedString
*/
function CTFramesetterCreateWithAttributedString(/* CPAttributedString */ aString)
{
    return {
        string: aString,
        typesetter: CTTypesetterCreateWithAttributedString(aString)
    };
}

CTFramesetterCreateWithAttributedString.displayName = @"CTFramesetterCreateWithAttributedString";

/*!
    Creates a CTFrame with a given typesetter, range, path, and attributes
*/
function CTFramesetterCreateFrame(/* CTFramesetter */ aFramesetter, /* CPRange */ aRange, /* CGPath */ aPath, /* CPDictionary */ frameAttributes)
{
    if (aFramesetter._cachedFrame && [aFramesetter._cachedAttributes isEqual:frameAttributes])
        return aFramesetter._cachedFrame;
    
    var attributedString = aRange ? [aFramesetter.string attributedSubstringFromRange:aRange] : aFramesetter.string,
        nonattributedString = [attributedString string],
        splitLines = nonattributedString.split(/\n|\r/g),
        lines = [];
    
    var index = 0;
    for (var i = -1, count = splitLines.length; ++i < count;)
    {
        var length = splitLines[i].length;
        if (i !== count - 1)
            ++length;
        
        var range = CPMakeRange(index, length),
            line = CTLineCreateWithAttributedString([attributedString attributedSubstringFromRange:range]);
        
        line.range = range; // FIXME: a couple hacks to make managing lines in CPTextView easier
        line.prevLine = lastLine;
        
        if (lastLine)
            lastLine.nextLine = line;
        
        lines.push(line);
        index += length;
        
        var lastLine = line;
    }
    
    return aFramesetter._cachedFrame = _CTFrameCreate(aPath, frameAttributes, lines);
}

CTFramesetterCreateFrame.displayName = @"CTFramesetterCreateFrame";

/*!
    Returns a CTTypesetter
*/
function CTFramesetterGetTypesetter(/* CTFramesetter */ aFramesetter)
{
    return aFramesetter.typesetter;
}

CTFramesetterGetTypesetter.displayName = @"CTFramesetterGetTypesetter";

/*!
    Returns a CGSize object with the suggested size for a given frame.
*/
function CTFramesetterSuggestFrameSizeWithConstraints(/* CTFramesetter */ aFramesetter, /* CPRange */ aRange, /* CPDictionary */ frameAttributes, /* CGSize */ constraints, /* {CPRange} */ fitRange)
{
    var frame = CTFramesetterCreateFrame(aFramesetter, aRange, null, frameAttributes),
        lines = CTFrameGetLines(frame),
        width = 0.0,
        height = 0.0;
    
    for (var i = -1, count = lines.length; ++i < count;)
    {
        var bounds = CTLineGetTypographicBounds(lines[i]);
        // var bounds = CTLineGetImageBounds(lines[i], [[CPGraphicsContext currentContext] graphicsPort]).size;
        width = MAX(width, bounds.width);
        height += bounds.lineHeight;
        // height += bounds.height;
    }
    
    return CGSizeMake(width, height);
}

CTFramesetterSuggestFrameSizeWithConstraints.displayName = @"CTFramesetterSuggestFrameSizeWithConstraints";

/*!
    Returns the CPAttributedString for a given framesetter
*/
function CTFramesetterGetAttributedString(/* CTFramesetter */ aFramesetter)
{
    return aFramesetter.string;
}

CTFramesetterGetAttributedString.displayName = @"CTFramesetterGetAttributedString";
