/*
 * CPExpression_aggregate.j
 * Foundation
 *
 * Copyright 2009, 280 North, Inc.
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
@import "CPExpression.j"
@import "CPString.j"

@implementation CPExpression_aggregate : CPExpression
{
    CPArray _aggregate;
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
    if (self == object)
        return YES;

    if (object.isa != self.isa || [object expressionType] != [self expressionType] || ![[object collection] isEqual:[self collection]])
        return NO;

    return YES;
}

- (id)collection
{
    return _aggregate;
}

- (id)expressionValueWithObject:(id)object context:(CPDictionary)context
{
    var eval_array = [CPArray array],
        collection  = [_aggregate objectEnumerator],
        exp;

    while (exp = [collection nextObject])
    {
        var eval = [exp expressionValueWithObject:object context:context];
        [eval_array addObject:eval];
    }

    return eval_array;
}

- (CPString)description
{
    var i = 0,
        count = [_aggregate count],
        result = "{";

    for (; i < count; i++)
        result = result + [CPString stringWithFormat:@"%s%s", [[_aggregate objectAtIndex:i] description], (i + 1 < count) ? @", " : @""];

    result = result + "}";

    return result;
}

- (CPExpression)_expressionWithSubstitutionVariables:(CPDictionary)variables
{
    var subst_array = [CPArray array],
        count = [_aggregate count],
        i = 0;

    for (; i < count; i++)
        [subst_array addObject:[[_aggregate objectAtIndex:i] _expressionWithSubstitutionVariables:variables]];

    return [CPExpression expressionForAggregate:subst_array];
}

@end

var CPCollectionKey = @"CPCollection";

@implementation CPExpression_aggregate (CPCoding)

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
