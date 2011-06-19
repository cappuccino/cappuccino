/*
 * CTFrame.j
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

@import "CTLine.j"


kCTFrameProgressionTopToBottom = 0;
kCTFrameProgressionRightToLeft = 1;

kCTFrameProgressionAttributeName = @"kCTFrameProgressionAttributeName";

function _CTFrameCreate(aPath, attributes, lines, attributedString)
{
    return {
        path: aPath,
        attributes: attributes,
        lines: lines,
        string: attributedString
    };
}

_CTFrameCreate.displayName = @"_CTFrameCreate";

/*!
    Returns the range of the frame based on the original string
    FIX ME: This implementation is wrong
*/
function CTFrameGetStringRange(/* CTFrame */ aFrame)
{
    return CPMakeRange();
}

CTFrameGetStringRange.displayName = @"CTFrameGetStringRange";

/*!
    Returns a range object with the visisble characters
    FIX ME: THis implementation is wrong
*/
function CTFrameGetVisibleStringRange(/* CTFrame */ aFrame)
{
    return CPMakeRange();
}

CTFrameGetVisibleStringRange.displayName = @"CTFrameGetVisibleStringRange";

/*!
    Returns the path for the frame.
*/
function CTFrameGetPath(/* CTFrame */ aFrame)
{
    return aFrame.path;
}

CTFrameGetPath.displayName = @"CTFrameGetPath";

/*!
    Returns a dictionary of attributes for the frame.
*/
function CTFrameGetFrameAttributes(/* CTFrame */ aFrame)
{
    return aFrame.frameAttributes;
}

CTFrameGetFrameAttributes.displayName = @"CTFrameGetFrameAttributes";

/*!
    Returns the array containing CTLines that make up the frame
*/
function CTFrameGetLines(/* CTFrame */ aFrame)
{
    return aFrame.lines;
}

CTFrameGetLines.displayName = @"CTFrameGetLines";

/*!
    Returns an array of CGPoints for the origin of each CTLine in the frame
*/
function CTFrameGetLineOrigins(/* CTFrame */ aFrame, /* CPRange */ aRange)
{
    var results = [],
        lines = aRange ? CTFrameGetLinesForRange(aFrame, aRange) : aFrame.lines;
    
    for (var i = -1, count = lines.length; ++i < count;)
        results.push(lines[i].origin);
    
    return results;
}

CTFrameGetLineOrigins.displayName = @"CTFrameGetLineOrigins";

/*!
    Returns an array of CTLines for a given range.
    Divergent from Cocoa and expensive.
*/
function CTFrameGetLinesForRange(/* CTFrame */ aFrame, /* CPRange */ lhs)
{
    var lines = aFrame.lines, results = [];
    for (var i = -1, count = lines.length; ++i < count;)
    {
        var line = lines[i],
            rhs = CTLineGetStringRange(line);
        
        if ((CPMaxRange(lhs) < rhs.location || CPMaxRange(rhs) < lhs.location) && result.length)
            break;
        
        if (lhs.location >= rhs.location && rhs.location <= CPMaxRange(lhs) && CPMaxRange(rhs) > lhs.location)
            results.push(line);
    }
    
    return results;
}

CTFrameGetLinesForRange.displayName = @"CTFrameGetLinesForRange";

/*!
    Returns a CPRange
    This is divergent from Cocoa. It's a convenience method used in CPTextView.
*/
function CTFrameGetRangeForPoint(/* CTFrame */ aFrame, /* CGPoint */ aPoint)
{
    var lines = aFrame.lines, y = aPoint.y;
    for (var i = -1, count = lines.length; ++i < count;)
    {
        var line = lines[i],
            bounds = CTLineGetImageBounds(line),
            lineY = line._startPosition.y;
        
        if (y >= lineY && y < bounds.size.height + lineY)
        {
            // FIXME: we seem to be doing stuff like this with some frequency;
            // Maybe it should be normalized at an earlier point.
            var index = CTLineGetStringIndexForPosition(line, aPoint),
                range = CTLineGetStringRange(line);
            
            range.location += index;
            range.length = 0;
            return range;
        }
    }
}

CTFrameGetRangeForPoint.displayName = @"CTFrameGetRangeForPoint";

/*!
    Draws the frame to the graphics context.
*/
function CTFrameDraw(/* CTFrame */ aFrame, /* CGContext */ aContext)
{
    var origin = aFrame.path.start,
        lines = aFrame.lines;
    
    CGContextSetTextPosition(aContext, origin.x, origin.y);
    
    for (var i = -1, count = lines.length; ++i < count;)
    {
        var line = lines[i],
            alignment = [line.string attribute:@"alignment" atIndex:0 effectiveRange:CPMakeRange(0, 0)],
            position = CGContextGetTextPosition(aContext);
        
        if (alignment === CPRightTextAlignment)
            line.origin = CGPointMake((aFrame.path.elements[1].x - origin.x * 2) - CTLineGetTypographicBounds(line).width, position.y);
        else if (alignment === CPCenterTextAlignment)
            line.origin = CGPointMake(((aFrame.path.elements[1].x - origin.x) / 2) - CTLineGetTypographicBounds(line).width / 2, position.y);
        else
            line.origin = CGPointMake(origin.x, position.y);
        
        CGContextSetTextPosition(aContext, line.origin.x, line.origin.y);
        CTLineDraw(line, aContext);
    }
}

CTFrameDraw.displayName = @"CTFrameDraw";
