/*
 * _CPSubqueryExpression.j
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

@import "CPArray.j"
@import "CPDictionary.j"
@import "_CPExpression.j"
@import "_CPPredicate.j"

@implementation _CPSubqueryExpression : CPExpression
{
    CPExpression _collection;
    CPExpression _variableExpression;
    CPPredicate  _subpredicate;
}

- (id)initWithExpression:(CPExpression)collection usingIteratorVariable:(CPString)variable predicate:(CPPredicate)subpredicate
{
    var variableExpression = [CPExpression expressionForVariable:variable];
    return [self initWithExpression:collection usingIteratorExpression:variableExpression predicate:subpredicate];
}

- (id)initWithExpression:(CPExpression)collection usingIteratorExpression:(CPExpression)variableExpression predicate:(CPPredicate)subpredicate
{
    self = [super initWithExpressionType:CPSubqueryExpressionType];

    if (self)
    {
        _subpredicate = subpredicate;
        _collection = collection;
        _variableExpression = variableExpression;
    }
    return self;
}

- (id)expressionValueWithObject:(id)object context:(id)context
{
    var collection = [_collection expressionValueWithObject:object context:context],
        count = [collection count],
        result = [CPArray array],
        bindings = @{ [self variable]: [CPExpression expressionForEvaluatedObject] },
        i = 0;

    for (; i < count; i++)
    {
        var item = [collection objectAtIndex:i];
        if ([_subpredicate evaluateWithObject:item substitutionVariables:bindings])
            [result addObject:item];
    }

    return result;
}

- (BOOL)isEqual:(id)object;
{
    if (self === object)
        return YES;

    if (object.isa !== self.isa || ![_collection isEqual:[object collection]] || ![_variableExpression isEqual:[object variableExpression]] || ![_subpredicate isEqual:[object predicate]])
        return NO;

    return YES;
}

- (CPExpression)collection
{
    return _collection;
}

- (id)copy
{
    return [[_CPSubqueryExpression alloc] initWithExpression:[_collection copy] usingIteratorExpression:[_variableExpression copy] predicate:[_subpredicate copy]];
}

- (CPPredicate)predicate
{
    return _subpredicate;
}

- (CPString)description
{
    return [self predicateFormat];
}

- (CPString)predicateFormat
{
    return @"SUBQUERY(" + [_collection description] + ", " + [_variableExpression description] + ", " + [_subpredicate predicateFormat] + ")";
}

- (CPString)variable
{
    return [_variableExpression variable];
}

- (CPExpression)variableExpression
{
    return _variableExpression;
}

@end

var CPExpressionKey     = @"CPExpression",
    CPSubpredicateKey   = @"CPSubpredicate",
    CPVariableKey       = @"CPVariable";

@implementation _CPSubqueryExpression (CPCoding)

- (id)initWithCoder:(CPCoder)coder
{
    var collection = [coder decodeObjectForKey:CPExpressionKey],
        subpredicate = [coder decodeObjectForKey:CPSubpredicateKey],
        variableExpression = [coder decodeObjectForKey:CPVariableKey];

    return [self initWithExpression:collection usingIteratorExpression:variableExpression predicate:subpredicate];
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:_collection forKey:CPExpressionKey];
    [coder encodeObject:_subpredicate forKey:CPSubpredicateKey];
    [coder encodeObject:_variableExpression forKey:CPVariableKey];
}

@end
