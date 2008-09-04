/*
 * CPException.j
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

import "CPCoder.j"
import "CPObject.j"
import "CPString.j"


CPInvalidArgumentException  = @"CPInvalidArgumentException";

@implementation CPException : CPObject
{
}

+ (id)alloc
{
    return new objj_exception();
}

+ (void)raise:(CPString)aName reason:(CPString)aReason
{
    [[self exceptionWithName:aName reason:aReason userInfo:nil] raise];
}

+ (id)exceptionWithName:(CPString)aName reason:(CPString)aReason userInfo:(id)aUserInfo
{
    return [[self alloc] initWithName:aName reason:aReason userInfo:aUserInfo];
}

- (id)initWithName:(CPString)aName reason:(CPString)aReason userInfo:(id)aUserInfo
{
    self = [super init];

    if (self)
    {
        name = aName;
        reason = aReason;
        userInfo = aUserInfo;
    }
    
    return self;
}

- (CPString)name
{
    return name;
}

- (CPString)reason
{
    return reason;
}

- (id)userInfo
{
    return userInfo;
}

- (CPString)description
{
    return reason;
}

- (void)raise
{
    objj_exception_throw(self);
}

@end

@implementation CPException (CPCopying)

- (id)copy
{
    return [[self class] exceptionWithName:name reason:reason userInfo:userInfo];
}

@end

@implementation CPException (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        name = [aCoder decodeObjectForKey:CPExceptionNameKey];
        reason = [aCoder decodeObjectForKey:CPExceptionReasonKey];
        userInfo = [aCoer decodeObjectForKey:CPExceptionUserInfoKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:name forKey:CPExceptionNameKey];
    [aCoder encodeObject:reason forKey:CPExceptionReasonKey];
    [aCoder encodeObject:userInfo forKey:CPExceptionUserInfoKey];
}

@end

objj_exception.prototype.isa = CPException;
[CPException initialize];

function _CPRaiseInvalidAbstractInvocation(anObject, aSelector)
{
    [CPException raise:CPInvalidArgumentException reason:@"*** -" + sel_getName(aSelector) + @" cannot be sent to an abstract object of class " + [anObject className] + @": Create a concrete instance!"];
}
