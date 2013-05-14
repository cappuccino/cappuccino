/*
 * _CPKeyPathExpression.j
 *
 * Portions based on NSExpression_keypath.m in Cocotron (http://www.cocotron.org/)
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

@import "CPKeyValueCoding.j"
@import "CPString.j"
@import "_CPExpression.j"
@import "_CPFunctionExpression.j"
@import "_CPConstantValueExpression.j"

@implementation _CPKeyPathExpression : _CPFunctionExpression
{
}

- (id)initWithKeyPath:(CPString)keyPath
{
    return [self initWithOperand:[CPExpression expressionForEvaluatedObject] andKeyPath:keyPath];
}

- (id)initWithOperand:(CPExpression)operand andKeyPath:(CPString)keyPath
{
    var arg = [CPExpression expressionForConstantValue:keyPath];
    // Cocoa: if it's a direct path selector use valueForKey:
    self = [super initWithTarget:operand selector:@selector(valueForKeyPath:) arguments:[arg] type:CPKeyPathExpressionType];

    return self;
}

- (BOOL)isEqual:(id)object
{
    if (object === self)
        return YES;

    if (object === nil || object.isa !== self.isa || ![[object keyPath] isEqualToString:[self keyPath]])
        return NO;

    return YES;
}

- (CPExpression)pathExpression
{
    return [[self arguments] objectAtIndex:0];
}

- (CPString)keyPath
{
    return [[self pathExpression] keyPath];
}

- (CPString)description
{
    var result = "";
    if ([_operand expressionType] != CPEvaluatedObjectExpressionType)
        result += [_operand description] + ".";
    result += [self keyPath];

    return result;
}

@end

@implementation _CPConstantValueExpression (KeyPath)

- (CPString)keyPath
{
    return [self constantValue];
}

@end
