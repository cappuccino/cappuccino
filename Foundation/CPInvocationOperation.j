/*
 * CPInvocationOperation.j
 *
 * Created by Johannes Fahrenkrug.
 * Copyright 2009, Springenwerk.
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

@import <Foundation/CPObject.j>
@import <Foundation/CPInvocation.j>
@import "CPOperation.j"


/*! 
    @class CPInvocationOperation
    @brief Represents an operation using an invocation that can be run in an CPOperationQueue
*/
@implementation CPInvocationOperation : CPOperation 
{
    CPInvocation _invocation;
}


- (void)main 
{
    if (_invocation) 
    {
        [_invocation invoke];
    }
}

- (id)init 
{
    if (self = [super init]) 
    {
        _invocation = nil;
    }
    return self;
}

/*!
    Returns a CPInvocationOperation object initialized with the specified invocation object.
    @param inv the invocation
*/
- (id)initWithInvocation:(CPInvocation)inv 
{
    if (self = [self init]) 
    {
        _invocation = inv;
    }
    
    return self;
}

/*!
    Returns an NSInvocationOperation object initialized with the specified target and selector.
    @param target the target
    @param sel the selector that should be called on the target
    @param arg the arguments
*/
- (id)initWithTarget:(id)target selector:(SEL)sel object:(id)arg 
{
    var inv = [[CPInvocation alloc] initWithMethodSignature:nil];
    [inv setTarget:target];
    [inv setSelector:sel];
    [inv setArgument:arg atIndex:2];
    
    return [self initWithInvocation:inv];
}

/*!
    Returns the receiver’s invocation object.
*/
- (CPInvocation)invocation 
{
    return _invocation;
}

/*!
    Returns the result of the invocation or method.
*/
- (id)result 
{
    if ([self isFinished] && _invocation) 
    {
        return [_invocation returnValue];
    }
    
    return nil;
}



@end