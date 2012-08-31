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

@implementation CPStepper (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        var cell = [aCoder decodeObjectForKey:@"NSCell"];

        _minValue = [cell minValue];
        _maxValue = [cell maxValue];
        _increment  = [cell increment];
        _valueWraps = [cell valueWraps];
        _autorepeat = [cell autorepeat];
        _objectValue = [cell objectValue];

        // Convert Cocoa normal size to Cappuccino normal size.
        _frame.origin.y += 2;
        _frame.size.height -= 2;
        _bounds.size.height -= 2;
    }

    return self;
}

@end

@implementation NSStepper : CPStepper
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
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
