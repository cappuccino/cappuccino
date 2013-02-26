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

/*!
    @class CPURLRequest
    @ingroup foundation
    @brief Contains data obtained during a request made with CPURLConnection.

    A helper object for CPURLConnection, that contains
    data obtained during the life of a request.
*/
@implementation CPURLRequest : CPObject
{
    CPURL       _URL;

    // FIXME: this should be CPData
    CPString        _HTTPBody;
    CPString        _HTTPMethod;
    CPDictionary    _HTTPHeaderFields;
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
    Equal to `[receiver initWithURL:nil]`.
*/
- (id)init
{
    return [self initWithURL:nil];
}

/*!
    Initializes the request with a URL. This is the designated initializer.

    @param aURL the url to set
    @return the initialized CPURLRequest
*/
- (id)initWithURL:(CPURL)aURL
{
    self = [super init];

    if (self)
    {
        [self setURL:aURL];

        _HTTPBody = @"";
        _HTTPMethod = @"GET";
        _HTTPHeaderFields = @{};

        [self setValue:"Thu, 01 Jan 1970 00:00:00 GMT" forHTTPHeaderField:"If-Modified-Since"];
        [self setValue:"no-cache" forHTTPHeaderField:"Cache-Control"];
        [self setValue:"XMLHttpRequest" forHTTPHeaderField:"X-Requested-With"];
    }

    return self;
}

/*!
    Returns the request URL
*/
- (CPURL)URL
{
    return _URL;
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
    Sets the HTTP body for this request
    @param anHTTPBody the new HTTP body
*/
- (void)setHTTPBody:(CPString)anHTTPBody
{
    _HTTPBody = anHTTPBody;
}

/*!
    Returns the request's http body.
*/
- (CPString)HTTPBody
{
    return _HTTPBody;
}

/*!
    Sets the request's http method.
    @param anHTPPMethod the new http method
*/
- (void)setHTTPMethod:(CPString)anHTTPMethod
{
    _HTTPMethod = anHTTPMethod;
}

/*!
    Returns the request's http method
*/
- (CPString)HTTPMethod
{
    return _HTTPMethod;
}

/*!
    Returns a dictionary of the http header fields
*/
- (CPDictionary)allHTTPHeaderFields
{
    return _HTTPHeaderFields;
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

@end
