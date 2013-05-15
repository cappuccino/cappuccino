/*
 * _CPVariableExpression.j
 *
 * Portions based on NSExpression_variable.m in Cocotron (http://www.cocotron.org/)
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
@import "CPException.j"
@import "CPString.j"
@import "_CPExpression.j"

@implementation _CPVariableExpression :  CPExpression
{
    CPString _variable;
}

- (id)initWithVariable:(CPString)variable
{
    self = [super initWithExpressionType:CPVariableExpressionType];

    if (self)
    {
        _variable = [variable copy];
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if (self === object)
        return YES;

    if (object === nil || object.isa !== self.isa || ![[object variable] isEqual:_variable])
        return NO;

    return YES;
}

- (CPString)variable
{
    return _variable;
}

- (id)expressionValueWithObject:object context:(CPDictionary)context
{
    var expression = [self _expressionWithSubstitutionVariables:context];

    return [expression expressionValueWithObject:object context:context];
}

- (CPString)description
{
    return [CPString stringWithFormat:@"$%s", _variable];
}

- (CPExpression)_expressionWithSubstitutionVariables:(CPDictionary)variables
{
    var value = [variables objectForKey:_variable];
    if (value == nil)
        [CPException raise:CPInvalidArgumentException reason:@"Can't get value for '" + _variable + "' in bindings" + variables];

    if ([value isKindOfClass:[CPExpression class]])
        return value;

    return [CPExpression expressionForConstantValue:value];
}

@end

var CPVariableKey = @"CPVariable";

@implementation _CPVariableExpression (CPCoding)

- (id)initWithCoder:(CPCoder)coder
{
    var variable = [coder decodeObjectForKey:CPVariableKey];
    return [self initWithVariable:variable];
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:_variable forKey:CPVariableKey];
}

@end
