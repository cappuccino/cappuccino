/*
 * NSStepper.j
 * nib2cib
 *
 * Created by cacaodev.
 * Copyright 2012.
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

@import <AppKit/CPStepper.j>

@import "NSCell.j"


@implementation CPStepper (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    return [super NS_initWithCoder:aCoder];
}

- (void)NS_initWithCell:(NSCell)cell
{
    [super NS_initWithCell:cell];

    self._minValue = [cell minValue];
    self._maxValue = [cell maxValue];
    self._increment  = [cell increment];
    self._valueWraps = [cell valueWraps];
    self._autorepeat = [cell autorepeat];
    self._objectValue = [cell objectValue];

    // Convert Cocoa normal size to Cappuccino normal size.
    self._frame.origin.y += 2;
    self._frame.size.height -= 2;
    self._bounds.size.height -= 2;
}

@end

@implementation NSStepper : CPStepper

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
    return [CPStepper class];
}

@end

@implementation NSStepperCell : NSCell
{
    double  _minValue           @accessors(readonly, getter=minValue);
    double  _maxValue           @accessors(readonly, getter=maxValue);
    double  _increment          @accessors(readonly, getter=increment);
    BOOL    _valueWraps         @accessors(readonly, getter=valueWraps);
    BOOL    _autorepeat         @accessors(readonly, getter=autorepeat);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _objectValue        = [aCoder decodeDoubleForKey:@"NSValue"];

        _minValue           = [aCoder decodeDoubleForKey:@"NSMinValue"];
        _maxValue           = [aCoder decodeDoubleForKey:@"NSMaxValue"];
        _increment          = [aCoder decodeDoubleForKey:@"NSIncrement"];
        _valueWraps         = [aCoder decodeBoolForKey:@"NSValueWraps"];
        _autorepeat         = [aCoder decodeBoolForKey:@"NSAutorepeat"];
    }

    return self;
}

@end
