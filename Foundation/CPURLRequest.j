/*
 * CPURLRequest.j
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

@import "CPDictionary.j"
@import "CPObject.j"
@import "CPString.j"
@import "CPURL.j"

@typedef CPURLRequestCachePolicy
CPURLRequestUseProtocolCachePolicy = 0;
CPURLRequestReloadIgnoringLocalCacheData = 1;
CPURLRequestReturnCacheDataElseLoad = 2;
CPURLRequestReturnCacheDataDontLoad = 3;

/*!
    @class CPURLRequest
    @ingroup foundation
    @brief Contains data obtained during a request made with CPURLConnection.

    A helper object for CPURLConnection, that contains
    data obtained during the life of a request.
*/
@implementation CPURLRequest : CPObject
{
    CPURL                       _URL                @accessors(property=URL);

    // FIXME: this should be CPData
    CPString                    _HTTPBody           @accessors(property=HTTPBody);
    CPString                    _HTTPMethod         @accessors(property=HTTPMethod);
    BOOL                        _withCredentials    @accessors(property=withCredentials);

    CPDictionary                _HTTPHeaderFields   @accessors(readonly, getter=allHTTPHeaderFields);
    CPTimeInterval              _timeoutInterval    @accessors(readonly, getter=timeoutInterval);
    CPURLRequestCachePolicy     _cachePolicy        @accessors(readonly, getter=cachePolicy);
}

/*!
    Creates a request with a specified URL.
    @param aURL the URL of the request
    @return a CPURLRequest
*/
+ (id)requestWithURL:(CPURL)aURL
{
    return [[CPURLRequest alloc] initWithURL:aURL];
}

/*!
    Creates a request with a specified URL, cachePolicy and timeoutInterval
    @param aURL the URL of the request
    @param aCachePolicy the cache policy of the request
    @param aTimeoutInterval the timeoutInterval of the request
    @return a CPURLRequest
*/
+ (id)requestWithURL:(CPURL)anURL cachePolicy:(CPURLRequestCachePolicy)aCachePolicy timeoutInterval:(CPTimeInterval)aTimeoutInterval
{
    return [[CPURLRequest alloc] initWithURL:anURL cachePolicy:aCachePolicy timeoutInterval:aTimeoutInterval];
}

/*!
    Equal to `[receiver initWithURL:nil]`.
*/
- (id)init
{
    return [self initWithURL:nil];
}

/*!
    Initializes the request with a URL. This is the designated initializer.

    @param aURL the url to set
    @param aCachePolicy the cache policy of the request
    @param aTimeoutInterval the timeoutInterval of the request
    @return the initialized CPURLRequest
*/
- (id)initWithURL:(CPURL)anURL cachePolicy:(CPURLRequestCachePolicy)aCachePolicy timeoutInterval:(CPTimeInterval)aTimeoutInterval
{
    if (self = [self initWithURL:anURL])
    {
        _cachePolicy = aCachePolicy;
        _timeoutInterval = aTimeoutInterval;
        
        [self _updateCacheControlHeader];
    }

    return self;
}

/*!
    Initializes the request with a URL. This is the designated initializer.

    @param aURL the url to set
    @return the initialized CPURLRequest
*/
- (id)initWithURL:(CPURL)aURL
{
    if (self = [super init])
    {
        [self setURL:aURL];

        _HTTPBody = @"";
        _HTTPMethod = @"GET";
        _HTTPHeaderFields = @{};
        _withCredentials = NO;
        _timeoutInterval = 60.0;
        _cachePolicy = CPURLRequestUseProtocolCachePolicy;

        [self setValue:"Thu, 01 Jan 1970 00:00:00 GMT" forHTTPHeaderField:"If-Modified-Since"];
        [self setValue:"XMLHttpRequest" forHTTPHeaderField:"X-Requested-With"];
        [self _updateCacheControlHeader];
    }

    return self;
}

/*!
    Sets the URL for this request.
    @param aURL the new URL
*/
- (void)setURL:(CPURL)aURL
{
    // Lenient and accept strings.
    _URL = new CFURL(aURL);
}

/*!
    Returns the value for the specified header field.
    @param aField the header field to obtain a value for
*/
- (CPString)valueForHTTPHeaderField:(CPString)aField
{
    return [_HTTPHeaderFields objectForKey:aField];
}

/*!
    Sets the value for the specified header field.
    @param aValue the value for the header field
    @param aField the header field
*/
- (void)setValue:(CPString)aValue forHTTPHeaderField:(CPString)aField
{
    [_HTTPHeaderFields setObject:aValue forKey:aField];
}

/*
  @ignore
*/
- (void)_updateCacheControlHeader
{
    switch (_cachePolicy)
    {
      case CPURLRequestUseProtocolCachePolicy:
          // TODO: implement everything about cache...
          [self setValue:"no-cache" forHTTPHeaderField:"Cache-Control"];
          break;

      case CPURLRequestReturnCacheDataElseLoad:
          [self setValue:"max-stale=31536000" forHTTPHeaderField:"Cache-Control"];
          break;

      case CPURLRequestReturnCacheDataDontLoad:
          [self setValue:"only-if-cached" forHTTPHeaderField:"Cache-Control"];
          break;

      case CPURLRequestReloadIgnoringLocalCacheData:
          [self setValue:"no-cache" forHTTPHeaderField:"Cache-Control"];
          break;

      default:
          [self setValue:"no-cache" forHTTPHeaderField:"Cache-Control"];
    }
}

@end

/*
    Implements the CPCopying Protocol for a CPURLRequest to provide deep copying for CPURLRequests
*/
@implementation CPURLRequest (CPCopying)
{
}

- (id)copy
{
    var request = [[CPURLRequest alloc] initWithURL:[self URL]];
    [request setHTTPBody:[self HTTPBody]];
    [request setHTTPMethod:[self HTTPMethod]];
    [request setWithCredentials:[self withCredentials]];
    request._HTTPHeaderFields = [self allHTTPHeaderFields];

    return request;
}

@end
