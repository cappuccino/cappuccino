/*
 * NSProgressIndicator.j
 * nib2cib
 *
 * Created by Antoine Mercadal.
 * Copyright 2011 Antoine Mercadal.
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

@import <AppKit/CPProgressIndicator.j>

@class Nib2Cib

var NSProgressIndicatorSpinningFlag = 1 << 12;

@implementation CPProgressIndicator (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        var NS_flags    = [aCoder decodeIntForKey:@"NSpiFlags"];

        _minValue       = [aCoder decodeDoubleForKey:@"NSMinValue"];
        _maxValue       = [aCoder decodeDoubleForKey:@"NSMaxValue"];

        _style = (NS_flags & NSProgressIndicatorSpinningFlag) ? CPProgressIndicatorSpinningStyle : CPProgressIndicatorBarStyle;
        _indeterminate = (NS_flags & 2) ? YES : NO;
        _isDisplayedWhenStopped = (NS_flags & 8192) ? NO : YES;
        _controlSize = (NS_flags & 256) ? CPSmallControlSize : CPRegularControlSize;

        if (_style === CPProgressIndicatorSpinningStyle)
        {
            // For whatever reason, our 'regular' size is larger than any Cocoa size, our 'small' size is Cocoa's regular and
            // our 'mini' size is Cocoa's small.
            _controlSize = _controlSize == CPRegularControlSize ? CPSmallControlSize : CPMiniControlSize;
        }

        // There is a bug in Xcode. the currentValue is not stored.
        // Let's set it to 0.0 for now.
        _doubleValue = 0.0;

        var currentFrameSize = [self frameSize];

        if (_style !== CPProgressIndicatorSpinningStyle)
        {
            var theme = [Nib2Cib defaultTheme],
                height = [theme valueForAttributeWithName:@"default-height" forClass:CPProgressIndicator];

            currentFrameSize.height = height;
        }

        [self setFrameSize:currentFrameSize];

        // update graphics
        [self updateBackgroundColor];
        [self drawBar];
    }

    return self;
}

@end

@implementation NSProgressIndicator : CPProgressIndicator

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPProgressIndicator class];
}

@end
