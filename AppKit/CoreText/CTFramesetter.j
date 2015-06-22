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

- (double)adjustWidth:(double)width atYOffset:(double)y ofBounds:(CGRect)bounds inPath:(CGPath)path
{
    return width;    
}

- (CPFrame)createFrameWithRange: (CPRange)range path: (CGPath)path frameAttributes: (CPDictionary)frameAttributes
{
    var frame = [[CPFrame alloc] initWithRange: range path: path attributes: frameAttributes];
        
    var startIndex = range.location;

    // Keeping it super simple initially    
    var bounds = CGPathGetBoundingBox(path);
    var origin = bounds.origin;
    var maxWidth = CGRectGetWidth(bounds);
    
    var alignment = kCTCenterTextAlignment;
    
    // Now break the range down into lines and add them to the frame
    var endIndex = 0;
    
    while (endIndex < CPMaxRange(range) && endIndex > -1) {
        var width = [self adjustWidth: maxWidth atYOffset: origin.y ofBounds: bounds inPath: path];
        endIndex = [_typesetter suggestLineBreakAfterIndex: startIndex width: width offset: 0];
        if (endIndex > -1) {

            // Create the line
            var lineRange = CPMakeRange(startIndex, endIndex - startIndex);
            var line = [_typesetter createLineWithRange: lineRange offset: 0];
            origin.y += [line height];
            var lineOrigin = CGPointMakeCopy(origin);
            switch (alignment)
            {
                case kCTRightTextAlignment:
                    lineOrigin.x += width - [line width];
                break;
                
                case kCTCenterTextAlignment:
                    lineOrigin.x += (width - [line width]) / 2;
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