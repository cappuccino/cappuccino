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

CPCappuccinoErrorDomain = CPCocoaErrorDomain = @"CPCappuccinoErrorDomain";
// CPPOSIXErrorDomain      = @"CPPOSIXErrorDomain";
// CPOSStatusErrorDomain   = @"CPOSStatusErrorDomain";

CPUnderlyingErrorKey                    = @"CPUnderlyingErrorKey";

CPLocalizedDescriptionKey               = @"CPLocalizedDescriptionKey";
CPLocalizedFailureReasonErrorKey        = @"CPLocalizedFailureReasonErrorKey";
CPLocalizedRecoverySuggestionErrorKey   = @"CPLocalizedRecoverySuggestionErrorKey";
CPLocalizedRecoveryOptionsErrorKey      = @"CPLocalizedRecoveryOptionsErrorKey";
CPRecoveryAttempterErrorKey             = @"CPRecoveryAttempterErrorKey";
CPHelpAnchorErrorKey                    = @"CPHelpAnchorErrorKey";

CPStringEncodingErrorKey                = @"CPStringEncodingErrorKey";
CPURLErrorKey                           = @"CPURLErrorKey";
CPFilePathErrorKey                      = @"CPFilePathErrorKey";


@implementation CPError : CPObject
{
    CPInteger       _code @accessors(property=code, readonly);
    CPString        _domain @accessors(property=domain, readonly);
    CPDictionary    _userInfo @accessors(property=userInfo, readonly);
}

+ (id)errorWithDomain:(CPString)aDomain code:(CPInteger)aCode userInfo:(CPDictionary)aDict
{
    return [[CPError alloc] initWithDomain:aDomain code:aCode userInfo:aDict];
}

- (id)initWithDomain:(CPString)aDomain code:(CPInteger)aCode userInfo:(CPDictionary)aDict
{
    if (self = [super init])
    {
        _domain = aDomain;
        _code = aCode;
        _userInfo = aDict;
    }

    return self;
}

- (CPString)localizedDescription
{
   return [_userInfo objectForKey:CPLocalizedDescriptionKey];
}

- (CPString)localizedFailureReason
{
   return [_userInfo objectForKey:CPLocalizedFailureReasonErrorKey];
}

- (CPArray)localizedRecoveryOptions
{
   return [_userInfo objectForKey:CPLocalizedRecoveryOptionsErrorKey];
}

- (CPString)localizedRecoverySuggestion
{
   return [_userInfo objectForKey:CPLocalizedRecoverySuggestionErrorKey];
}

- (id)recoveryAttempter
{
   return [_userInfo objectForKey:CPRecoveryAttempterErrorKey];
}

- (id)description
{
   return [CPString stringWithFormat:@"Error Domain=%@ Code=%d UserInfo=%p %@", _domain, _code, _userInfo, [self localizedDescription]];
}

@end
