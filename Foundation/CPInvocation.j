/*
 * CPInvocation.j
 * Foundation
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

import "CPObject.j"

@implementation CPInvocation : CPObject
{
    id                  _returnValue;
    CPMutableArray      _arguments;
    CPMethodSignature   _methodSignature;
}

// Creating CPInvocation Objects

+ (id)invocationWithMethodSignature:(CPMethodSignature)aMethodSignature
{
    return [[self alloc] initWithMethodSignature:aMethodSignature];
}

- (id)initWithMethodSignature:(CPMethodSignature)aMethodSignature
{
    self = [super init];
    
    if (self)
    {
        _arguments = [];
        _methodSignature = aMethodSignature;
    }
    
    return self;
}

// Configuring an Invocation Object

- (void)setSelector:(SEL)aSelector
{
    _arguments[1] = aSelector;
}

- (SEL)selector
{
    return _arguments[1];
}

- (void)setTarget:(id)aTarget
{
    _arguments[0] = aTarget;
}

- (id)target
{
    return _arguments[0];
}

- (void)setArgument:(id)anArgument atIndex:(unsigned)anIndex
{
    _arguments[anIndex] = anArgument;
}

- (id)argumentAtIndex:(unsigned)anIndex
{
    return _arguments[anIndex];
}

- (void)setReturnValue:(id)aReturnValue
{
    _returnValue = aReturnValue;
}

- (id)returnValue
{
    return _returnValue;
}

// Dispatching an Invocation

- (void)invoke
{
    _returnValue = objj_msgSend.apply(objj_msgSend, _arguments);
}

- (void)invokeWithTarget:(id)aTarget
{
    _arguments[0] = aTarget;
    _returnValue = objj_msgSend.apply(objj_msgSend, _arguments);
}

@end

var CPInvocationArguments   = @"CPInvocationArguments",
    CPInvocationReturnValue = @"CPInvocationReturnValue";

@implementation CPInvocation (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _returnValue = [aCoder decodeObjectForKey:CPInvocationReturnValue];
        _arguments = [aCoder decodeObjectForKey:CPInvocationArguments];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_returnValue forKey:CPInvocationReturnValue];
    [aCoder encodeObject:_arguments forKey:CPInvocationArguments];
}

@end
