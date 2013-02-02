/*
 * _CPConstantValueExpression.j
 *
 * Portions based on NSExpression_constant.m in Cocotron (http://www.cocotron.org/)
 * Copyright (c) 2006-2007 Christopher J. W. Lloyd
 *
 * Created by cacaodev.
 * Copyright 2010.
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

@import "CPDictionary.j"
@import "_CPExpression.j"

@implementation _CPConstantValueExpression : CPExpression
{
    id _value;
}

- (id)initWithValue:(id)value
{
    self = [super initWithExpressionType:CPConstantValueExpressionType];

    if (self)
        _value = value;

    return self;
}

- (BOOL)isEqual:(id)object
{
    if (self === object)
        return YES;

    if (object.isa !== self.isa || ![[object constantValue] isEqual:_value])
        return NO;

    return YES;
}

- (id)constantValue
{
    return _value;
}

- (id)expressionValueWithObject:(id)object context:(CPDictionary)context
{
    return _value;
}

- (CPString)description
{
    if ([_value isKindOfClass:[CPString class]])
        return @"\"" + _value + @"\"";

    return [_value description];
}

@end

var CPConstantValueKey = @"CPConstantValue";

@implementation _CPConstantValueExpression (CPCoding)

- (id)initWithCoder:(CPCoder)coder
{
    var value = [coder decodeObjectForKey:CPConstantValueKey];
    return [self initWithValue:value];
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:_value forKey:CPConstantValueKey];
}

@end
