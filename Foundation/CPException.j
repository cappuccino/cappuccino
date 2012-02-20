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

@import "CPCoder.j"
@import "CPObject.j"
@import "CPString.j"


CPInvalidArgumentException          = "CPInvalidArgumentException";
CPUnsupportedMethodException        = "CPUnsupportedMethodException";
CPRangeException                    = "CPRangeException";
CPInternalInconsistencyException    = "CPInternalInconsistencyException";

/*!
    @class CPException
    @ingroup foundation
    @brief Used to implement exception handling (creating & raising).

    An example of throwing an exception in Objective-J:
<pre>
// some code here...
if (input == nil)
    [CPException raise:"MyException" reason:"You didn't do something right."];

// code that gets executed if no exception was raised
</pre>
*/
@implementation CPException : CPObject
{
    id          _userInfo;
}

/*
    @ignore
*/
+ (id)alloc
{
    return new Error();
}

/*!
    Raises an exception with a name and reason.
    @param aName the name of the exception to raise
    @param aReason the reason for the exception
*/
+ (void)raise:(CPString)aName reason:(CPString)aReason
{
    [[self exceptionWithName:aName reason:aReason userInfo:nil] raise];
}

/*!
    Creates an exception with a name, reason and user info.
    @param aName the name of the exception
    @param aReason the reason the exception occurred
    @param aUserInfo a dictionary containing information about the exception
    @return the new exception
*/
+ (CPException)exceptionWithName:(CPString)aName reason:(CPString)aReason userInfo:(CPDictionary)aUserInfo
{
    return [[self alloc] initWithName:aName reason:aReason userInfo:aUserInfo];
}

/*!
    Initializes the exception.
    @param aName the name of the exception
    @param aReason the reason for the exception
    @param aUserInfo a dictionary containing information about the exception
    @return the initialized exception
*/
- (id)initWithName:(CPString)aName reason:(CPString)aReason userInfo:(CPDictionary)aUserInfo
{
    self = [super init];

    if (self)
    {
        name = aName;
        message = aReason;
        _userInfo = aUserInfo;
    }

    return self;
}

/*!
    Returns the name of the exception.
*/
- (CPString)name
{
    return name;
}

/*!
    Returns the reason for the exception.
*/
- (CPString)reason
{
    return message;
}

/*!
    Returns data containing info about the receiver.
*/
- (CPDictionary)userInfo
{
    return _userInfo;
}

/*!
    Returns the exception's reason.
*/
- (CPString)description
{
    return message;
}

/*!
    Raises the exception and causes the program to go to the exception handler.
*/
- (void)raise
{
    throw self;
}

@end

@implementation CPException (CPCopying)

- (id)copy
{
    return [[self class] exceptionWithName:name reason:message userInfo:_userInfo];
}

@end

var CPExceptionNameKey = "CPExceptionNameKey",
    CPExceptionReasonKey = "CPExceptionReasonKey",
    CPExceptionUserInfoKey = "CPExceptionUserInfoKey";

@implementation CPException (CPCoding)

/*!
    Initializes the exception with data from a coder.
    @param aCoder the coder from which to read the exception data
    @return the initialized exception
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        name = [aCoder decodeObjectForKey:CPExceptionNameKey];
        message = [aCoder decodeObjectForKey:CPExceptionReasonKey];
        _userInfo = [aCoder decodeObjectForKey:CPExceptionUserInfoKey];
    }

    return self;
}

/*!
    Encodes the exception's data into a coder.
    @param aCoder the coder to which the data will be written
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:name forKey:CPExceptionNameKey];
    [aCoder encodeObject:message forKey:CPExceptionReasonKey];
    [aCoder encodeObject:_userInfo forKey:CPExceptionUserInfoKey];
}

@end

// toll-free bridge Error to CPException
// [CPException alloc] uses an objj_exception, which is a subclass of Error
Error.prototype.isa = CPException;
Error.prototype._userInfo = NULL;

[CPException initialize];

function _CPRaiseInvalidAbstractInvocation(anObject, aSelector)
{
    [CPException raise:CPInvalidArgumentException reason:@"*** -" + sel_getName(aSelector) + @" cannot be sent to an abstract object of class " + [anObject className] + @": Create a concrete instance!"];
}

function _CPReportLenientDeprecation(/*Class*/ aClass, /*SEL*/ oldSelector, /*SEL*/ newSelector)
{
    CPLog.warn("[" + CPStringFromClass(aClass) + " " + CPStringFromSelector(oldSelector) + "] is deprecated, using " + CPStringFromSelector(newSelector) + " instead.");
}
