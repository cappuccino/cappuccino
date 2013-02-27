/*
 * NSScroller.j
 * nib2cib
 *
 * Created by Thomas Robinson.
 * Copyright 2008, 280 North, Inc.
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

@import <AppKit/CPScroller.j>


@implementation CPScroller (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self = [super NS_initWithCoder:aCoder])
    {
        //"NSArrowsLoc"

        _controlSize = CPRegularControlSize;

        //if ([aCoder containsValueForKey:CPScrollerControlSizeKey])
        //    _controlSize = [aCoder decodeIntForKey:CPScrollerControlSizeKey];

        _knobProportion = 1.0;

        if ([aCoder containsValueForKey:@"NSPercent"])
            _knobProportion = [aCoder decodeFloatForKey:@"NSPercent"];

        _value = 0.0;

        // Cocoa uses NSCurValue instead of NSControl's NSContents
        if ([aCoder containsValueForKey:@"NSCurValue"])
            _value = [aCoder decodeFloatForKey:@"NSCurValue"];

        // Horizontal scrollers have an int key NSsFlags === 1
        _isVertical = [aCoder decodeIntForKey:@"NSsFlags"] !== 1;

        if (CPStringFromSelector([self action]) === @"_doScroller:")
            if (_isVertical)
                [self setAction:@selector(_verticalScrollerDidScroll:)];
            else
                [self setAction:@selector(_horizontalScrollerDidScroll:)];

        _partRects = [];

        // FIXME:SIZE
        if (_isVertical)
            [self setFrameSize:CGSizeMake(15.0, CGRectGetHeight([self frame]))];
        else
            [self setFrameSize:CGSizeMake(CGRectGetWidth([self frame]), 15.0)];
    }

    return self;
}

@end

@implementation NSScroller : CPScroller
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [self NS_initWithCoder:aCoder];

    if (self)
    {
        var cell = [aCoder decodeObjectForKey:@"NSCell"];
        [self NS_initWithCell:cell];
    }

    return self;
}

- (Class)classForKeyedArchiver
{
    return [CPScroller class];
}

@end
