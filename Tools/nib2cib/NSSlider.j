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

@import "NSSlider.j"


@implementation CPSlider (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];
    
    if (self)
    {
        var cell = [aCoder decodeObjectForKey:@"NSCell"];
        
        _minValue           = [cell minValue];
        _maxValue           = [cell maxValue];
        _altIncrementValue  = [cell altIncrementValue];
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
    }
    
    return self;
}

@end
