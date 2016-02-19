/*
 * _CPAggregateExpression.j
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
@import "CPString.j"
@import "_CPExpression.j"

@implementation _CPAggregateExpression : CPExpression
{
    CPArray _aggregate @accessors(getter=collection);
}

- (id)initWithAggregate:(CPArray)collection
{
    self = [super initWithExpressionType:CPAggregateExpressionType];

    if (self)
        _aggregate = collection;

    return self;
}

- (BOOL)isEqual:(id)object
{
    if (self === object)
        return YES;

    if (object === nil || object.isa !== self.isa || ![[object collection] isEqual:_aggregate])
        return NO;

    return YES;
}

- (id)expressionValueWithObject:(id)object context:(CPDictionary)context
{
    return [_aggregate arrayByApplyingBlock:function(exp)
    {
        return [exp expressionValueWithObject:object context:context];
    }];
}

- (CPString)description
{    
    var descriptions = [_aggregate arrayByApplyingBlock:function(exp)
    {
        return [exp description];
    }];

    return "{" + [descriptions componentsJoinedByString:","] + "}" ;
}

- (CPExpression)_expressionWithSubstitutionVariables:(CPDictionary)variables
{
    var subst_array = [_aggregate arrayByApplyingBlock:function(exp)
    {
        return [exp _expressionWithSubstitutionVariables:variables];
    }];

    return [CPExpression expressionForAggregate:subst_array];
}

@end

var CPCollectionKey = @"CPCollection";

@implementation _CPAggregateExpression (CPCoding)

- (id)initWithCoder:(CPCoder)coder
{
    var collection = [coder decodeObjectForKey:CPCollectionKey];
    return [self initWithAggregate:collection];
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:_aggregate forKey:CPCollectionKey];
}

@end
