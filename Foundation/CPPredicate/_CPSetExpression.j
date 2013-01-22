/*
 * _CPSetExpression.j
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

@import "CPException.j"
@import "CPSet.j"
@import "_CPExpression.j"

@implementation _CPSetExpression : CPExpression
{
    CPExpression _left;
    CPExpression _right;
}

- (id)initWithType:(int)type left:(CPExpression)left right:(CPExpression)right
{
    self = [super initWithExpressionType:type];

    if (self)
    {
        _left = left;
        _right = right;
    }

    return self;
}

- (BOOL)isEqual:(id)object
{
    if (self === object)
        return YES;

    if (object.isa !== self.isa || ![[object leftExpression] isEqual:_left] || ![[object rightExpression] isEqual:_right])
        return NO;

    return YES;
}

- (id)expressionValueWithObject:object context:(CPDictionary)context
{
    var right = [_right expressionValueWithObject:object context:context];
    if ([right isKindOfClass:[CPArray class]])
        right = [CPSet setWithArray:right];
    else if ([right isKindOfClass:[CPDictionary class]])
        right = [CPSet setWithArray:[right allValues]];
    else if (![right isKindOfClass:[CPSet class]])
        [CPException raise:CPInvalidArgumentException reason:@"The right expression for a CP*SetExpressionType expression must evaluate to a CPArray, CPDictionary or CPSet"];

    var left = [_left expressionValueWithObject:object context:context];
    if (![left isKindOfClass:[CPSet class]])
        [CPException raise:CPInvalidArgumentException reason:@"The left expression for a CP*SetExpressionType expression must evaluate to a CPSet"];

    var result = [left copy];
    switch (_type)
    {
        case CPIntersectSetExpressionType : [result intersectSet:right];
                                            break;
        case CPUnionSetExpressionType     : [result unionSet:right];
                                            break;
        case CPMinusSetExpressionType     : [result minusSet:right];
                                            break;
        default:
    }

    return result;
}

- (CPExpression )_expressionWithSubstitutionVariables:(CPDictionary )variables
{
    // UNIMPLEMENTED
    return self;
}

- (CPExpression)leftExpression
{
    return _left;
}

- (CPExpression)rightExpression
{
    return _right;
}

- (CPString)description
{
    var desc;
    switch (_type)
    {
        case CPIntersectSetExpressionType : desc = @" INTERSECT ";
                                            break;
        case CPUnionSetExpressionType :     desc = @" UNION ";
                                            break;
        case CPMinusSetExpressionType :     desc = @" MINUS ";
                                            break;
        default:
    }

    return [_left description] + desc + [_right description];
}

@end

var CPLeftExpressionKey     = @"CPLeftExpression",
    CPRightExpressionKey    = @"CPRightExpression",
    CPExpressionType        = @"CPExpressionType";

@implementation _CPSetExpression (CPCoding)

- (id)initWithCoder:(CPCoder)coder
{
    var left = [coder decodeObjectForKey:CPLeftExpressionKey],
        right = [coder decodeObjectForKey:CPRightExpressionKey],
        type = [coder decodeIntForKey:CPExpressionType];

    return [self initWithType:type left:left right:right];
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:_left forKey:CPLeftExpressionKey];
    [coder encodeObject:_right forKey:CPRightExpressionKey];
    [coder encodeInt:_type forKey:CPExpressionType];
}

@end
