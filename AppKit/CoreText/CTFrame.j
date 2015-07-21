/*
 * CTFrame.j
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

@import <Foundation/Foundation.j>

@import "CGContext.j"

@import "CTDefaultAttributes.j"

@import "CTLine.j"

@implementation CPFrame : CPObject
{
    CPRange _range;
    CPArray _lines;
    CGPath  _path;
    CPDictionary _attributes;
}

- (id)initWithRange:(CPRange)range path:(CGPath)aPath attributes:(CPDictonary)attributes
{
    self = [super init];
    if (self)
    {
        _range = CPMakeRangeCopy(range);
        _path = aPath; // CGPathCreateCopy(aPath);
        _attributes = [attributes copy];
        
        _lines = [[CPArray alloc] init];
    }
    return self;
}

- (CPRange)textRange
{
    // Todo: FIXME
    CPLog.warn("- [CTFrame textRange] not implemented yet");
    return CPMakeRange(0, 0);
}

- (CPRange)visibleTextRange
{
    // Todo: FIXME
    CPLog.warn("- [CTFrame visibleTextRange] not implemented yet");
    return CPMakeRange(0, 0);
}

- (CGRect)visibleTextBounds
{
    var minX = Number.MAX_VALUE,
        minY = Number.MAX_VALUE,
        maxX = Number.MIN_VALUE,
        maxY = Number.MIN_VALUE;
        
    var enumerator = [_lines objectEnumerator];
    var line = nil;
    while ((line = [enumerator nextObject]) != nil )
    {
        var origin = [line origin];
        if (origin.x < minX)
        {
            minX = origin.x;
        }
        if (origin.y - [line height] < minY)
        {
            minY = origin.y - [line height];
        }
        if (origin.x + [line width] > maxX)
        {
            maxX = origin.x + [line width];
        }
        if (origin.y > maxY)
        {
            maxY = origin.y;
        }
    }
    return CGRectMake(minX, minY, maxX-minX, maxY-minY);
}

- (CGPath)path
{
    return _path;
}

- (CPDictionary)attributes
{
    return _attributes;
}

- (CPArray)lines
{
    return _lines;
}

- (void)addLine:(CPLine)line
{
    [_lines addObject: line];
}

- (void)draw:(CGContext)context
{
    // Set the initial attributes based on the first line
    var line = [_lines firstObject];
    var run = [line._runs firstObject];
    CTApplyAttributes(context, CTGetDefaultAttributes());

    var enumerator = [_lines objectEnumerator];
    var line = nil;
    while ((line = [enumerator nextObject]) != nil ) {
        [line draw: context];
    }
}

- (CPString)description
{
    return [CPString stringWithFormat: "CPFrame: range: %s, line count: %d, path: %s, attributes: %s",
                    CPStringFromRange(_range), [_lines count],
                    CGStringFromRect(CGPathGetBoundingBox(_path)), [_attributes description]];
}

@end

@typedef CTFrameRef

function CTFrameGetTextRange(aFrame)
{
    return [aFrame textRange];
}

function CTFrameGetVisibleTextRange(aFrame)
{
    return [aFrame visibleTextRange];
}

function CTFrameGetPath(aFrame)
{
    return [aFrame path];
}

function CTFrameGetAttributes(aFrame)
{
    return [aFrame attributes];
}

function CTFrameGetLines(aFrame)
{
    return [aFrame lines];
}

/*!
    Copies a range of line origins for a frame.
    @param aFrame The frame whose line origin array is copied.
    @param aRange The range of line origins you wish to copy. If the length of the range is 0, then the copy operation continues from the start index of the range to the last line origin.
    @param origins The buffer to which the origins are copied. The buffer must have at least as many elements as specified by range's length. Each CGPoint in this array is the origin of the corresponding line in the array of lines returned by CTFrameGetLines relative to the origin of the path's bounding box, which can be obtained from CGPathGetPathBoundingBox.
    @return void
*/

function CTFrameGetLineOrigins(aFrame, aRange, origins)
{
    CPLog.warn("CTFrameGetLineOrigins() not implemented yet");
}

function CTFrameDraw(aFrame, aContext)
{
    [aFrame draw: aContext];
}


