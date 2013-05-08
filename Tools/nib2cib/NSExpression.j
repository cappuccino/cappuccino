/*
 * NSExpression.j
 * nib2cib
 *
 * Created by Klaas Pieter Annema.
 * Copyright 2011.
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

@import <Foundation/CPExpression.j>
@import <Foundation/_CPKeyPathExpression.j>
@import <Foundation/_CPSetExpression.j>
@import <Foundation/_CPSelfExpression.j>
@import <Foundation/_CPConstantValueExpression.j>
@import <Foundation/_CPFunctionExpression.j>
@import <Foundation/_CPVariableExpression.j>
@import <Foundation/_CPAggregateExpression.j>

@implementation NSKeyPathExpression : _CPKeyPathExpression
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPKeyPathExpression class];
}

@end

@implementation _CPKeyPathSpecifierExpression : _CPConstantValueExpression
{
}

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var keyPath = [aCoder decodeObjectForKey:@"NSKeyPath"];
    self = [super initWithValue:keyPath];
    return self;
}

@end

@implementation NSKeyPathSpecifierExpression : _CPKeyPathSpecifierExpression
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPConstantValueExpression class];
}

@end

@implementation _CPConstantValueExpression (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var value = [aCoder decodeObjectForKey:@"NSConstantValue"];
    return [self initWithValue:value];
}

@end

@implementation NSConstantValueExpression : _CPConstantValueExpression
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPConstantValueExpression class];
}

@end

@implementation _CPFunctionExpression (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var type = [aCoder decodeIntForKey:@"NSExpressionType"],
        operand = [aCoder decodeObjectForKey:@"NSOperand"],
        selector = CPSelectorFromString([aCoder decodeObjectForKey:@"NSSelectorName"]),
        args = [aCoder decodeObjectForKey:@"NSArguments"];

    return [self initWithTarget:operand selector:selector arguments:args type:type];
}

@end

@implementation NSFunctionExpression : _CPFunctionExpression
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPFunctionExpression class];
}

@end

@implementation _CPSetExpression (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var type = [aCoder decodeIntForKey:@"NSExpressionType"],
        left = [aCoder decodeObjectForKey:@"NSLeftExpression"],
        right = [aCoder decodeObjectForKey:@"NSRightExpression"];

    return [self initWithType:type left:left right:right];
}

@end

@implementation NSSetExpression : _CPSetExpression
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPSetExpression class];
}

@end

@implementation NSSelfExpression : _CPSelfExpression
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [super init];
}

- (Class)classForKeyedArchiver
{
    return [_CPSelfExpression class];
}

@end

@implementation _CPVariableExpression (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var variable = [aCoder decodeObjectForKey:@"NSVariable"];
    return [self initWithVariable:variable];
}

@end

@implementation NSVariableExpression : _CPVariableExpression
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPVariableExpression class];
}

@end

@implementation _CPAggregateExpression (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var collection = [aCoder decodeObjectForKey:@"NSCollection"];
    return [self initWithAggregate:collection];
}

@end

@implementation NSAggregateExpression : _CPAggregateExpression
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPAggregateExpression class];
}

@end
