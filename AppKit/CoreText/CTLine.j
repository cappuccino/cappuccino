/*
 * CTLine.j
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

@import "CTRun.j"

@implementation CPLine : CPObject
{
    CPArray _runs;
    CGPoint _origin;
    double  _height;
    double  _width;
}

- (id)initWithAttributedString:(CPAttributedString)string
{
    self = [super init];
    if (self)
    {
        _runs = [[CPArray alloc] init];
        _origin = CGPointMakeZero;
        _height = 0;
        var positions = [[CPArray alloc] init];
        [positions addObject: CGPointMake(0, 0)];
        
        // Break the string up into attribute runs
        var index = 0;
        var length = [string length];
        while (index < length)
        {
            var longestRange = CPMakeRange(0,0);
            var rangeLimit = CPMakeRange(index, length-index);
            var attributes = [string attributesAtIndex: index longestEffectiveRange: longestRange inRange: rangeLimit];
            var run = CTRunCreate([[string string] substringWithRange: longestRange], positions, attributes);
            [_runs addObject: run];
            index = CPMaxRange(longestRange);        
        }
    }
    return self;
}

- (CGPoint)origin
{
    return _origin;
}

- (void)setOrigin:(CGPoint)origin
{
    _origin = CGPointMakeCopy(origin);
}

- (double)height
{
    return _height;
}

- (void)setHeight:(double)height
{
    _height = height;
}

- (double)width
{
    return _width;
}

- (void)setWidth:(double)width
{
    _width = width;
}

- (int)getCharCount
{
    var count = 0;
    var run = nil;
    var enumerator = [_runs objectEnumerator];
    while ((run = [enumerator nextObject]) != nil)
    {
        count += CTRunGetCharCount(run);
    }
    return count;
}

- (void)draw:(CGContextRef)context
{
    CGContextSetTextPosition(context, _origin.x, _origin.y);
    
    CGContextBeginText(context);

    var range = CPMakeRange(0, 0);
    var run = nil;
    var enumerator = [_runs objectEnumerator];
    while ((run = [enumerator nextObject]) != nil)
    {
        CTRunDraw(run, context, range);
    }
    
    CGContextEndText(context);
}

- (CPString)description
{
    return [CPString stringWithFormat: @"CTLine: _runs: %d, origin: %s, height: %f", [_runs count], CGStringFromPoint(_origin), _height];
    
}
@end

function CTLineCreateWithAttributedString(anAttributedString)
{
    return [[CPLine alloc] initWithAttributedString: anAttributedString];
}

function CTLineGetCharCount(aLine)
{
    return [aLine getCharCount];
}

function CTLineDraw(aLine, aContext)
{
    [aLine draw: aContext];
}
