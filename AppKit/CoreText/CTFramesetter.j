/*
 * CTFramesetter.j
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

@import "CTFrame.j"
@import "CTTypesetter.j"

kCTFramesetterVerticalTopAlignment       = 0;
kCTFramesetterVerticalMiddleAlignment    = 1;
kCTFramesetterVerticalBottomAlignment    = 2;

kCTFramesetterVerticalAlignment              = "CTFramesetterVerticalAlignment";


@implementation CPFramesetter : CPObject
{
    CPTypesetter       _typesetter;
}

- (id)initWithAttributedString:(CPAttributedString)string
{
    self = [super init];
    if (self)
    {
        _typesetter = [[CPTypesetter alloc] initWithAttributedString: string options: nil];
    }
    return self;
}

- (CPTypesetter)typesetter
{
    return _typesetter;
}

- (double)_adjustWidth:(double)width atYOffset:(double)y ofBounds:(CGRect)bounds inPath:(CGPath)path edges:(CPMutableDictionary)edges
{
    var leftPoint = CGPointMake(CGRectGetMinX(bounds)-10, y);
    var rightPoint = CGPointMake(CGRectGetMaxX(bounds)+10, y);
    
    var line = CGPathCreateMutable();
    CGPathMoveToPoint(line, NULL, leftPoint.x, leftPoint.y);
    CGPathAddLineToPoint(line, NULL, rightPoint.x, rightPoint.y);

    var intersections = CGPathGetAllIntersectionsWithPath(path, line);
    if ([intersections count] == 2)
    {
        var firstPoint = [intersections objectAtIndex: 0];
        var lastPoint = [intersections objectAtIndex: 1];
        var leftEdge = MIN(firstPoint.x, lastPoint.x);
        var rightEdge = MAX(firstPoint.x, lastPoint.x);
        width = rightEdge - leftEdge;
        [edges setObject: [CPNumber numberWithFloat: leftEdge] forKey: "leftEdge"];
        [edges setObject: [CPNumber numberWithFloat: rightEdge] forKey: "rightEdge"];
    }
    return width;    
}

- (CPFrame)_doCreateFrameWithRange: (CPRange)range path: (CGPath)path frameAttributes: (CPDictionary)frameAttributes yOffset:(double)yOffset
{
//    CPLog.trace("- [CTFramesetter _doCreateFrameWithRange: string: %@", _typesetter._string)
    var frame = [[CPFrame alloc] initWithRange: range path: path attributes: frameAttributes];

    var startIndex = range.location;

    // Keeping it super simple initially    
    var bounds = CGPathGetBoundingBox(path);
    var origin = bounds.origin;

    // Offset from the top edge
    origin.y += yOffset;

    var maxWidth = CGRectGetWidth(bounds);
    
    var alignment = kCTLeftTextAlignment;
    
    // Now break the range down into lines and add them to the frame
    var endIndex = 0;

    var edges = [CPMutableDictionary dictionary];
        
    while (endIndex <= CPMaxRange(range) && endIndex > -1) {
        [edges removeAllObjects];
        var width = [self _adjustWidth: maxWidth atYOffset: origin.y ofBounds: bounds inPath: path edges: edges];
        endIndex = [_typesetter suggestLineBreakAfterIndex: startIndex width: width offset: 0];
        if (endIndex > -1) {

            // Create the line
            var lineRange = CPMakeRange(startIndex, endIndex - startIndex);
            var line = [_typesetter createLineWithRange: lineRange offset: 0];
            origin.y += [line height];
            var lineOrigin = CGPointMakeCopy(origin);
            var leftEdge = CGRectGetMinX(bounds);
            var rightEdge = CGRectGetMaxX(bounds);
            if ([edges count] == 2) {
                leftEdge = [[edges objectForKey: "leftEdge"] doubleValue];
                rightEdge = [[edges objectForKey: "rightEdge"] doubleValue];
            }
            switch (alignment)
            {
                case kCTLeftTextAlignment:
                    lineOrigin.x = leftEdge;
                break;
                case kCTRightTextAlignment:
                    lineOrigin.x = rightEdge - [line width];
                break;
                
                case kCTCenterTextAlignment:
                    lineOrigin.x = ((rightEdge - leftEdge)/2 + leftEdge) - [line width] / 2;
                break;
                
                case kCTJustifiedTextAlignment:
                default:
                break;
            }
            [line setOrigin: lineOrigin];
            [frame addLine: line];            
            // Move to the next line
            startIndex = endIndex;
        }
    }
    return frame;
}

- (CPFrame)createFrameWithRange: (CPRange)range path: (CGPath)path frameAttributes: (CPDictionary)frameAttributes
{
    var verticalAlignment = kCTFramesetterVerticalTopAlignment;
    if ([frameAttributes objectForKey: kCTFramesetterVerticalAlignment] != nil)
    {
        verticalAlignment = [[frameAttributes objectForKey: kCTFramesetterVerticalAlignment] intValue];
    }
    
    var yOffset = 2; // From visual inspection
    
    var finalFrame = nil;
    if (verticalAlignment == kCTFramesetterVerticalTopAlignment)
    {
        finalFrame = [self _doCreateFrameWithRange: range path: path frameAttributes: frameAttributes yOffset: yOffset];
    }
    else if (verticalAlignment == kCTFramesetterVerticalBottomAlignment)
    {
        var pathBounds = CGPathGetBoundingBox(path);
        var frame = [self _doCreateFrameWithRange: range path: path frameAttributes: frameAttributes yOffset: yOffset];
        var usedBounds = [frame visibleTextBounds];
        yOffset = CGRectGetMaxY(pathBounds) - CGRectGetMaxY(usedBounds);
        var tries = 0;
        while (tries < 4 && Math.abs(CGRectGetMaxY(usedBounds) - CGRectGetMaxY(pathBounds)) > 2)
        { 
            yOffset += CGRectGetMaxY(pathBounds) - CGRectGetMaxY(usedBounds) > 0 ? 4 : -4;
            tries++;
            frame = [self _doCreateFrameWithRange: range path: path frameAttributes: frameAttributes yOffset: yOffset];           
            usedBounds = [frame visibleTextBounds];
        }
        finalFrame = frame;
    }
    else if (verticalAlignment == kCTFramesetterVerticalMiddleAlignment)
    {
        var pathBounds = CGPathGetBoundingBox(path);
        var frame = [self _doCreateFrameWithRange: range path: path frameAttributes: frameAttributes yOffset: yOffset];
        var usedBounds = [frame visibleTextBounds];
        yOffset = (CGRectGetMaxY(pathBounds) - CGRectGetMaxY(usedBounds))/2;
        var tries = 0;
        while (tries < 4 && Math.abs(CGRectGetMidY(pathBounds) - CGRectGetMidY(usedBounds)) > 2)
        {
            yOffset += CGRectGetMidY(pathBounds) - CGRectGetMidY(usedBounds) > 0 ? 4 : -4;
            tries++;
            frame = [self _doCreateFrameWithRange: range path: path frameAttributes: frameAttributes yOffset: yOffset];
            usedBounds = [frame visibleTextBounds];
        }
        finalFrame = frame;           
    }
    return finalFrame;
}

@end

function CTFramesetterCreateWithAttributedString(anAttributedString)
{
    return [[CPFramesetter alloc] initWithAttributedString: anAttributedString];
}

function CTFramesetterCreateFrame(aFramesetter, aRange, aPath, frameAttributes)
{
    return [aFramesetter createFrameWithRange: aRange path: aPath frameAttributes: frameAttributes];
}

function CTFramesetterGetTypesetter(aFramesetter)
{
    return [aFramesetter typesetter];
}

function CTFramesetterSuggestFrameSizeWithConstraints(aFramesetter, aRange, frameAttributes, constraints, fitRange)
{
}