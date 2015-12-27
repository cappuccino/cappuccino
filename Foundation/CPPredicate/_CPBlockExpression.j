/*
 * _CPBlockExpression.j
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

@import "_CPExpression.j"

@implementation _CPBlockExpression :  CPExpression
{
    Function _block;
    CPArray  _arguments;
}

- (id)initWithBlock:(Function)aBlock arguments:(CPArray)arguments
{
    self = [super initWithExpressionType:CPBlockExpressionType];

    if (self)
    {
        _block = aBlock;
        _arguments = arguments;
    }

    return self;
}

- (BOOL)isEqual:(id)object
{
    if (self === object)
        return YES;

    if (object === nil || object.isa !== self.isa || [object expressionBlock] !== _block || ![[object arguments] isEqual:_arguments])
        return NO;

    return YES;
}

- (Function)expressionBlock
{
    return _block;
}

- (CPArray)arguments
{
    return _arguments;
}

- (id)expressionValueWithObject:(id)object context:(CPDictionary)context
{
    var args = [];

    if (_arguments !== nil)
    {
        args = _arguments.map(function(expression){
            return [expression expressionValueWithObject:object context:context];
        });
    }

    return _block(object, args, context);
}

- (CPString)description
{
    return [CPString stringWithFormat:@"Block(0x%@)", [CPString stringWithHash:[self UID]]];
}

@end