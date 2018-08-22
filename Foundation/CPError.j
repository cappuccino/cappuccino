/*
 * CPError.j
 * Foundation
 *
 * Created by Alexander Ljungberg.
 * Copyright 2013, SlevenBits Ltd.
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

@import "CPDictionary.j"
@import "CPObject.j"
@import "CPString.j"

CPCappuccinoErrorDomain                 = kCFErrorDomainCappuccino;
CPCocoaErrorDomain                      = kCFErrorDomainCappuccino; // compat

CPUnderlyingErrorKey                    = kCFErrorUnderlyingErrorKey;

CPLocalizedDescriptionKey               = kCFErrorLocalizedDescriptionKey;
CPLocalizedFailureReasonErrorKey        = kCFErrorLocalizedFailureReasonKey;
CPLocalizedRecoverySuggestionErrorKey   = kCFErrorLocalizedRecoverySuggestionKey;
CPLocalizedRecoveryOptionsErrorKey      = @"CPLocalizedRecoveryOptionsErrorKey";
CPRecoveryAttempterErrorKey             = @"CPRecoveryAttempterErrorKey";
CPHelpAnchorErrorKey                    = @"CPHelpAnchorErrorKey";

CPStringEncodingErrorKey                = @"CPStringEncodingErrorKey";
CPURLErrorKey                           = kCFErrorURLKey;
CPFilePathErrorKey                      = kCFErrorFilePathKey;

/*!
    @class CPError
    @ingroup foundation
    @brief Used for encapsulating, presenting, and recovery from errors.

    CPError is toll-free bridged with CFError() methods.

    An example of initializing a CPError:
<pre>

var userInfo = @{CPLocalizedDescriptionKey: @"A localized error description",
                 CPLocalizedFailureReasonErrorKey: @"A localized failure reason",
                 CPUnderlyingErrorKey: @"An underlying error message"},

    err = [CPError errorWithDomain:CPCappuccinoErrorDomain code:-10 userInfo:userInfo];
</pre>
 */
@implementation CPError : CPObject
{
}

+ (id)alloc
{
    var obj = new CFError();
    obj.isa = [self class];

    return obj;
}


+ (id)errorWithDomain:(CPString)aDomain code:(CPInteger)aCode userInfo:(CPDictionary)aDict
{
    return [[CPError alloc] initWithDomain:aDomain code:aCode userInfo:aDict];
}

- (id)initWithDomain:(CPString)aDomain code:(CPInteger)aCode userInfo:(CPDictionary)aDict
{
    var result = new CFError(aDomain, aCode, aDict);
    result.isa = [self class];
    return result;
}

- (CPInteger)code
{
    return self.code();
}

- (CPString)userInfo
{
    return self.userInfo();
}

- (CPString)domain
{
    return self.domain();
}

/*!
    By default this method returns the object in the user info dictionary for the key
    CPLocalizedDescriptionKey. If the user info dictionary doesn’t contain a value for
    CPLocalizedDescriptionKey, a default string is constructed from the domain and code.
 */
- (CPString)localizedDescription
{
    return self.description();
}

- (CPString)localizedFailureReason
{
   return self.failureReason();
}

- (CPArray)localizedRecoveryOptions
{
    var userInfo = self.userInfo(),
        recoveryOptions = userInfo.valueForKey(CPLocalizedRecoveryOptionsErrorKey);

    return recoveryOptions;
}

- (CPString)localizedRecoverySuggestion
{
    return self.recoverySuggestion();
}

- (id)recoveryAttempter
{
    var userInfo = self.userInfo(),
        recoveryAttempter = userInfo.valueForKey(CPRecoveryAttempterErrorKey);

    return recoveryAttempter;
}

- (CPString)description
{
    return [CPString stringWithFormat:@"Error Domain=%@ Code=%d \"%@\" UserInfo=%@", self.domain(), self.code(), self.description(), self.userInfo()];
}

@end

var CPErrorCodeKey = @"CPErrorCodeKey",
    CPErrorDomainKey = @"CPErrorDomainKey",
    CPErrorUserInfoKey = @"CPErrorUserInfoKey";

@implementation CPError (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    var code = [aCoder decodeIntForKey:CPErrorCodeKey],
        domain = [aCoder decodeObjectForKey:CPErrorDomainKey],
        userInfo = [aCoder decodeObjectForKey:CPErrorUserInfoKey];

    return [self initWithDomain:domain
                           code:code
                       userInfo:userInfo];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:self.domain() forKey:CPErrorDomainKey];
    [aCoder encodeObject:self.code() forKey:CPErrorCodeKey];
    [aCoder encodeObject:self.userInfo() forKey:CPErrorUserInfoKey];
}

@end

CFError.prototype.isa = CPError;

