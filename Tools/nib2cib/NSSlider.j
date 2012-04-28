/*
 * NSSlider.j
 * nib2cib
 *
 * Created by Francisco Tolmasky.
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

@import <AppKit/CPSlider.j>

@implementation CPSlider (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var cell = [aCoder decodeObjectForKey:@"NSCell"];

    // We need to do these first or setObjectValue: will 0 anything we put in it.
    _minValue = [cell minValue];
    _maxValue = [cell maxValue];

    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        _altIncrementValue  = [cell altIncrementValue];

        [self setSliderType:[cell sliderType]];

        if ([self sliderType] === CPCircularSlider)
        {
            var frame = [self frame];

            [self setFrameSize:CGSizeMake(frame.size.width + 4.0, frame.size.height + 2.0)];
        }
    }

    return self;
}

@end

@implementation NSSlider : CPSlider
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPSlider class];
}

@end

@implementation NSSliderCell : NSCell
{
    double  _minValue           @accessors(readonly, getter=minValue);
    double  _maxValue           @accessors(readonly, getter=maxValue);
    double  _altIncrementValue  @accessors(readonly, getter=altIncrementValue);
    BOOL    _vertical           @accessors(readonly, getter=isVertical);
    int     _sliderType         @accessors(readonly, getter=sliderType);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _objectValue        = [aCoder decodeDoubleForKey:@"NSValue"];

        _minValue           = [aCoder decodeDoubleForKey:@"NSMinValue"];
        _maxValue           = [aCoder decodeDoubleForKey:@"NSMaxValue"];
        _altIncrementValue  = [aCoder decodeDoubleForKey:@"NSAltIncValue"];
        _isVertical         = [aCoder decodeBoolForKey:@"NSVertical"];

        _sliderType         = [aCoder decodeIntForKey:@"NSSliderType"];
    }

    return self;
}

@end
