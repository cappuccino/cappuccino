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


@implementation CPProgressIndicator (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        var NS_flags    = [aCoder decodeIntForKey:@"NSpiFlags"];

        _minValue       = [aCoder decodeDoubleForKey:@"NSMinValue"] || 0;
        _maxValue       = [aCoder decodeDoubleForKey:@"NSMaxValue"];

        _style = (NS_flags & CPProgressIndicatorSpinningStyle) ? CPProgressIndicatorSpinningStyle : CPProgressIndicatorBarStyle;
        _isIndeterminate = (NS_flags & 2) ? YES : NO;
        _isDisplayedWhenStopped = (NS_flags & 8192) ? NO : YES;
        _controlSize = CPRegularControlSize;

        // There is a bug in Xcode. the currentValue is not stored.
        // Let's set it to 0.0 for now.
        _doubleValue = 0.0;

        // Readjust the height of the control to the correct size.
        var currentFrameSize = [self frameSize];
        currentFrameSize.height = 15.0;
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
