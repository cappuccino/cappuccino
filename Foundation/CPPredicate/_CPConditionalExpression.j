/*
 * _CPConditionalExpression.j
 *
 * Created by cacaodev.
 * Copyright 2015.
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
@import "_CPPredicate.j"
@import "_CPExpression.j"

@implementation _CPConditionalExpression :  CPExpression
{
    CPPredicate   _predicate @accessors(getter=predicate);
    CPExpression  _trueExpression @accessors(getter=trueExpression);
    CPExpression  _falseExpression @accessors(getter=falseExpression);
}

- (id)initWithPredicate:(CPPredicate)aPredicate trueExpression:(CPExpression)trueExpression falseExpression:(CPExpression)falseExpression
{
    self = [super initWithExpressionType:CPConditionalExpressionType];

    if (self)
    {
        _predicate = aPredicate;
        _trueExpression = trueExpression;
        _falseExpression = falseExpression;
    }

    return self;
}

- (BOOL)isEqual:(id)object
{
    if (self === object)
        return YES;

    if (object === nil || object.isa !== self.isa || ![[object predicate] isEqual:_predicate] || ![[object trueExpression] isEqual:_trueExpression] || ![[object falseExpression] isEqual:_falseExpression])
        return NO;

    return YES;
}

- (id)expressionValueWithObject:(id)object context:(CPDictionary)context
{
    var eval = [_predicate evaluateWithObject:object substitutionVariables:context],
        exp = eval ? _trueExpression : _falseExpression;

    return [exp expressionValueWithObject:object context:context];
}

- (CPExpression)_expressionWithSubstitutionVariables:(CPDictionary)bindings
{
    var predicate = [_predicate predicateWithSubstitutionVariables:bindings],
        trueExp = [_trueExpression _expressionWithSubstitutionVariables:bindings],
        falseExp = [_falseExpression _expressionWithSubstitutionVariables:bindings];

    return [[_CPConditionalExpression alloc] initWithPredicate:predicate trueExpression:trueExp falseExpression:falseExp];
}

- (CPString)description
{
    return [CPString stringWithFormat:@"TERNARY(%@,%@,%@)", [_predicate predicateFormat], [_trueExpression description], [_falseExpression description]];
}

@end