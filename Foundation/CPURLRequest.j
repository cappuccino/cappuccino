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

import "CPObject.j"

@implementation CPURLRequest : CPObject
{
    CPURL       _URL;
    
    // FIXME: this should be CPData
    CPString        _HTTPBody;
    CPString        _HTTPMethod;
    CPDictionary    _HTTPHeaderFields;
}

+ (id)requestWithURL:(CPURL)aURL
{
    return [[CPURLRequest alloc] initWithURL:aURL];
}

- (id)initWithURL:(CPURL)aURL
{
    self = [super init];
    
    if (self)
    {
        _URL = aURL;
        _HTTPBody = @"";
        _HTTPMethod = @"GET";
        _HTTPHeaderFields = [CPDictionary dictionary];
        
        [self setValue:"Thu, 1 Jan 1970 00:00:00 GMT" forHTTPHeaderField:"If-Modified-Since"];
        [self setValue:"no-cache" forHTTPHeaderField:"Cache-Control"];
    }
    
    return self;
}

- (CPURL)URL
{
    return _URL;
}

- (void)setURL:(CPURL)aURL
{
    _URL = aURL;
}

- (void)setHTTPBody:(CPString)anHTTPBody
{
    _HTTPBody = anHTTPBody;
}

- (CPString)HTTPBody
{
    return _HTTPBody;
}

- (void)setHTTPMethod:(CPString)anHTTPMethod
{
    _HTTPMethod = anHTTPMethod;
}

- (CPString)HTTPMethod
{
    return _HTTPMethod;
}

- (CPDictionary)allHTTPHeaderFields
{
    return _HTTPHeaderFields;
}

- (CPString)valueForHTTPHeaderField:(CPString)aField
{
    return [_HTTPHeaderFields objectForKey:aField];
}

- (void)setValue:(CPString)aValue forHTTPHeaderField:(CPString)aField
{
    [_HTTPHeaderFields setObject:aValue forKey:aField];
}

@end
