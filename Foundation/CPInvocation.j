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

@import "CPObject.j"
@import "CPException.j"


/*! 
    @class CPInvocation
    @ingroup foundation
    @brief An object representation of a message.

    A CPInvocation is an object representation of a message sent to an object.
*/
@implementation CPInvocation : CPObject
{
    id                  _returnValue;
    CPMutableArray      _arguments;
    CPMethodSignature   _methodSignature;
}

// Creating CPInvocation Objects
/*!
    Returns a new CPInvocation that represents a message to a method.
    @param aMethodSignature the signature of the method to message
    @return the new invocation
*/
+ (id)invocationWithMethodSignature:(CPMethodSignature)aMethodSignature
{
    return [[self alloc] initWithMethodSignature:aMethodSignature];
}

/*!
    Initializes the invocation with a provided method signature
    @param aMethodSignature the signature of the method to message
    @return the initialized invocation
*/
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
/*!
    Sets the invocation's selector.
    @param the invocation selector
*/
- (void)setSelector:(SEL)aSelector
{
    _arguments[1] = aSelector;
}

/*!
    Returns the invocation's selector
*/
- (SEL)selector
{
    return _arguments[1];
}

/*!
    Sets the invocation's target
    @param aTarget the invocation target
*/
- (void)setTarget:(id)aTarget
{
    _arguments[0] = aTarget;
}

/*!
    Returns the invocation's target
*/
- (id)target
{
    return _arguments[0];
}

/*!
    Sets a method argument for the invocation. Arguments 0 and 1 are <code>self</code> and <code>_cmd</code>.
    @param anArgument the argument to add
    @param anIndex the index of the argument in the method
*/
- (void)setArgument:(id)anArgument atIndex:(unsigned)anIndex
{
    _arguments[anIndex] = anArgument;
}

/*!
    Returns the argument at the specified index. Arguments 0 and 1 are
    <code>self</code> and <code>_cmd</code> respectively. Thus, method arguments start at 2.
    @param anIndex the index of the argument to return
    @throws CPInvalidArgumentException if anIndex is greater than or equal to the invocation's number of arguments.
*/
- (id)argumentAtIndex:(unsigned)anIndex
{
    return _arguments[anIndex];
}

/*!
    Sets the invocation's return value
    @param the invocation return value
*/
- (void)setReturnValue:(id)aReturnValue
{
    _returnValue = aReturnValue;
}

/*!
    Returns the invocation's return value
*/
- (id)returnValue
{
    return _returnValue;
}

// Dispatching an Invocation
/*!
    Sends the encapsulated message to the stored target.
*/
- (void)invoke
{
    _returnValue = objj_msgSend.apply(objj_msgSend, _arguments);
}

/*!
    Sends the encapsulated message to the specified target.
    @param the target to which the message will be sent
*/
- (void)invokeWithTarget:(id)aTarget
{
    _arguments[0] = aTarget;
    _returnValue = objj_msgSend.apply(objj_msgSend, _arguments);
}

@end

var CPInvocationArguments   = @"CPInvocationArguments",
    CPInvocationReturnValue = @"CPInvocationReturnValue";

@implementation CPInvocation (CPCoding)

/*!
    Initializes the invocation with data from a coder.
    @param aCoder the coder from which to obtain initialization data
    @return the initialized invocation
*/
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

/*!
    Writes out the invocation's data to the provided coder.
    @param aCoder the coder to which the data will be written
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_returnValue forKey:CPInvocationReturnValue];
    [aCoder encodeObject:_arguments forKey:CPInvocationArguments];
}

@end
